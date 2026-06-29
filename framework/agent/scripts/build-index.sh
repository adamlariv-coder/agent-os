#!/bin/bash
# Rebuild all agent indexes in one pass.
# Run after adding/editing any topic file, skill, or framework route.
# Usage: bash framework/agent/scripts/build-index.sh

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{print $2; exit}')"
TOPICS_DIR="$REPO_ROOT/personal/knowledge/topics"
TOPICS_INDEX="$REPO_ROOT/personal/agent/topics-index.json"
MANIFEST="$REPO_ROOT/personal/agent/routing-manifest.json"
FRAMEWORK_ROUTES="$REPO_ROOT/personal/agent/framework-routes.json"
REGISTRY="$REPO_ROOT/framework/skills/registry.json"
PERSONAL_REGISTRY="$REPO_ROOT/personal/skills/registry.json"

python3 - "$TOPICS_DIR" "$TOPICS_INDEX" "$MANIFEST" "$FRAMEWORK_ROUTES" "$REGISTRY" "$PERSONAL_REGISTRY" << 'PYEOF'
import sys, os, re, json
from datetime import date

topics_dir             = sys.argv[1]
topics_out             = sys.argv[2]
manifest_out           = sys.argv[3]
framework_routes_path  = sys.argv[4]
registry_path          = sys.argv[5]
personal_registry_path = sys.argv[6]

# ── 1. Build topics-index ──────────────────────────────────────────────────
topics = {}
for fname in sorted(os.listdir(topics_dir)):
    if not fname.endswith(".md"):
        continue
    path = os.path.join(topics_dir, fname)
    with open(path) as f:
        raw = f.read()

    status  = "unknown"
    updated = None
    m = re.search(r'> status:\s*(\w[\w-]*)', raw)
    if m: status = m.group(1)
    m = re.search(r'updated:\s*(\d{4}-\d{2}-\d{2})', raw)
    if m: updated = m.group(1)
    if not updated:
        m = re.search(r'Last refreshed:\s*(\d{4}-\d{2}-\d{2})', raw)
        if m: updated = m.group(1)

    title = fname.replace(".md", "")
    m = re.search(r'^#\s+(.+)', raw, re.MULTILINE)
    if m: title = m.group(1).strip()

    tags = []
    m = re.search(r'\*\*Tags\*\*:\s*(.+)', raw)
    if m: tags = [t.strip() for t in m.group(1).split(",")]

    summary = ""
    in_header = True
    for line in raw.splitlines():
        if in_header and (line.startswith(">") or line.startswith("#") or not line.strip()):
            continue
        in_header = False
        if line.strip() and not line.startswith("#") and not line.startswith("|") and not line.startswith("-"):
            summary = line.strip()[:120]
            break

    topics[fname.replace(".md", "")] = {
        "path": "personal/knowledge/topics/" + fname,
        "title": title,
        "status": status,
        "updated": updated,
        "tags": tags,
        "summary": summary
    }

with open(topics_out, "w") as f:
    json.dump({"topics": topics}, f, indent=2)
print(f"topics-index: {len(topics)} topics")

# ── 2. Build routing-manifest ──────────────────────────────────────────────
routes = []

# 2a. Framework routes (static)
with open(framework_routes_path) as f:
    fw = json.load(f)
routes.extend(fw["routes"])

# 2b. Framework skills
framework_skills = {}
if os.path.exists(registry_path):
    with open(registry_path) as f:
        framework_registry = json.load(f)
    framework_skills = framework_registry.get("skills", {})
    for name, meta in framework_skills.items():
        triggers = meta.get("triggers", [name])
        routes.append({
            "triggers": triggers,
            "load": meta["path"],
            "also": [],
            "type": "skill",
            "skill_type": "framework",
            "description": meta.get("description", "")
        })

# 2c. Personal skills
personal_skills = {}
if os.path.exists(personal_registry_path):
    with open(personal_registry_path) as f:
        personal_registry = json.load(f)
    personal_skills = personal_registry.get("skills", {})
    for name, meta in personal_skills.items():
        triggers = meta.get("triggers", [name])
        routes.append({
            "triggers": triggers,
            "load": meta["path"],
            "also": [],
            "type": "skill",
            "skill_type": "personal",
            "description": meta.get("description", "")
        })

# 2d. Topics (from topics-index, active only)
for key, topic in topics.items():
    if topic["status"] == "archived":
        continue
    triggers = [key.replace("-", " "), key]
    triggers += topic.get("tags", [])
    # add keywords from title words (lowercased, >3 chars)
    title_words = [w.lower() for w in re.findall(r'\b\w{4,}\b', topic["title"])]
    triggers += title_words
    # deduplicate preserving order
    seen = set()
    unique = []
    for t in triggers:
        if t and t not in seen:
            seen.add(t)
            unique.append(t)
    routes.append({
        "triggers": unique,
        "load": topic["path"],
        "also": [],
        "type": "topic",
        "updated": topic["updated"]
    })

manifest = {
    "generated": date.today().isoformat(),
    "routes": routes
}

with open(manifest_out, "w") as f:
    json.dump(manifest, f, indent=2)
print(f"routing-manifest: {len(routes)} routes ({len(topics)} topics, {len(framework_skills)} framework skills, {len(personal_skills)} personal skills, {len(fw['routes'])} framework routes)")

# ── 3. Generate framework INDEX.md ────────────────────────────────────────
# registry.json is the single source of truth. Sub-refs are auto-discovered from
# each skill dir so they never drift. Never hand-edit INDEX.md.
skills_dir = os.path.dirname(registry_path)
index_out  = os.path.join(skills_dir, "INDEX.md")
lines = [
    "# Skills Index — Fast Lookup",
    "",
    "Generated from `framework/skills/registry.json` by `build-index.sh` — **do not edit by hand**.",
    "Authoring guide: `framework/knowledge/skill-authoring.md`",
    "",
]
for name, meta in sorted(framework_skills.items()):
    skill_path = meta.get("path", "")
    sub = []
    sd = os.path.join(skills_dir, name)
    if os.path.isdir(sd):
        sub = sorted(f for f in os.listdir(sd) if f.endswith(".md") and f != "SKILL.md")
    lines += ["---", "", f"## {name}", f"**Path**: `{skill_path}`"]
    if meta.get("model"):
        lines.append(f"**Model**: {meta['model']}")
    lines.append("**Triggers**: " + ", ".join(meta.get("triggers", [])))
    lines.append(f"**Does**: {meta.get('description','')}")
    if meta.get("needs"):
        lines.append(f"**Needs**: {meta['needs']}")
    if sub:
        lines.append("**Sub-refs**: " + " · ".join(sub))
    lines.append(f"**Last updated**: {meta.get('updated', meta.get('installed','—'))}")
    lines.append("")

with open(index_out, "w") as f:
    f.write("\n".join(lines))
print(f"framework skills INDEX.md: {len(framework_skills)} skills")

# ── 4. Generate personal INDEX.md ─────────────────────────────────────────
personal_skills_dir = os.path.dirname(personal_registry_path)
personal_index_out  = os.path.join(personal_skills_dir, "INDEX.md")
lines = [
    "# Personal Skills Index",
    "",
    "Generated from `personal/skills/registry.json` by `build-index.sh` — **do not edit by hand**.",
    "",
]
for name, meta in sorted(personal_skills.items()):
    skill_path = meta.get("path", "")
    sub = []
    sd = os.path.join(personal_skills_dir, name)
    if os.path.isdir(sd):
        sub = sorted(f for f in os.listdir(sd) if f.endswith(".md") and f != "SKILL.md")
    lines += ["---", "", f"## {name}", f"**Path**: `{skill_path}`"]
    if meta.get("model"):
        lines.append(f"**Model**: {meta['model']}")
    lines.append("**Triggers**: " + ", ".join(meta.get("triggers", [])))
    lines.append(f"**Does**: {meta.get('description','')}")
    if meta.get("needs"):
        lines.append(f"**Needs**: {meta['needs']}")
    if sub:
        lines.append("**Sub-refs**: " + " · ".join(sub))
    lines.append(f"**Last updated**: {meta.get('updated', meta.get('installed','—'))}")
    lines.append("")

if os.path.exists(personal_skills_dir):
    with open(personal_index_out, "w") as f:
        f.write("\n".join(lines))
    print(f"personal skills INDEX.md: {len(personal_skills)} skills")
PYEOF
