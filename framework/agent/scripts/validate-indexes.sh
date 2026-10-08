#!/bin/bash
# Validate generated indexes are fresh and consistent.
# Checks: manifest exists + all paths valid + all active topics indexed + index count matches disk
# Usage: bash framework/agent/scripts/validate-indexes.sh

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
TOPICS_DIR="$REPO_ROOT/personal/knowledge/topics"
TOPICS_INDEX="$REPO_ROOT/personal/agent/topics-index.json"
CATEGORIES_PATH="$REPO_ROOT/framework/knowledge/topic-categories.json"
MANIFEST="$REPO_ROOT/personal/agent/routing-manifest.json"

errors=0
warnings=0

echo ""
echo "=== Index Validation ==="
echo ""

# 1. Both index files exist
for f in "$TOPICS_INDEX" "$MANIFEST"; do
  if [ ! -f "$f" ]; then
    echo "  MISSING: ${f#$REPO_ROOT/} — run build-index.sh"
    errors=$((errors + 1))
  fi
done
[ $errors -gt 0 ] && echo "" && echo "Errors: $errors — fix before continuing." && exit 1

# 2. topics-index count matches disk
indexed=$(python3 -c "import json; print(len(json.load(open('$TOPICS_INDEX'))['topics']))")
ondisk=$(python3 -c "
import os
root = '$TOPICS_DIR'
n = 0
for dp, _, fs in os.walk(root):
    n += sum(1 for f in fs if f.endswith('.md'))
print(n)
")
if [ "$indexed" != "$ondisk" ]; then
  echo "  STALE: topics-index has $indexed entries, disk has $ondisk — run build-index.sh"
  warnings=$((warnings + 1))
else
  echo "  ok: topics-index — $indexed topics"
fi

# 3. All paths in manifest exist on disk
echo ""
stale_paths=0
python3 - "$MANIFEST" "$REPO_ROOT" << 'PYEOF'
import json, os, sys
manifest_path = sys.argv[1]
root = sys.argv[2]
with open(manifest_path) as f:
    data = json.load(f)
missing = []
for route in data["routes"]:
    for key in ("load", *route.get("also", [])):
        p = os.path.join(root, route["load"] if key == "load" else key)
        if not os.path.exists(p):
            missing.append(route["load"] if key == "load" else key)
for m in missing:
    print(f"  MISSING PATH: {m}")
sys.exit(len(missing))
PYEOF
stale_paths=$?
[ $stale_paths -gt 0 ] && warnings=$((warnings + stale_paths))

# 4. All active topic files appear in the manifest
echo ""
python3 - "$TOPICS_DIR" "$MANIFEST" << 'PYEOF'
import json, os, sys, re
topics_dir = sys.argv[1]
manifest_path = sys.argv[2]
with open(manifest_path) as f:
    manifest_text = f.read()
missing = []
for dirpath, _, filenames in os.walk(topics_dir):
    for fname in filenames:
        if not fname.endswith(".md"):
            continue
        fpath = os.path.join(dirpath, fname)
        rel = os.path.relpath(fpath, topics_dir).replace("\\", "/")
        with open(fpath) as f:
            content = f.read()
        status_m = re.search(r'> status:\s*(\w[\w-]*)', content)
        status = status_m.group(1) if status_m else "unknown"
        if status == "archived":
            continue
        repo_path = "personal/knowledge/topics/" + rel
        key = fname.replace(".md", "")
        if repo_path not in manifest_text and key not in manifest_text:
            print(f"  UNROUTED: {repo_path}  (status: {status})")
            missing.append(rel)
sys.exit(len(missing))
PYEOF
unrouted=$?
[ $unrouted -gt 0 ] && warnings=$((warnings + unrouted))

# 6. All active topics have a known category
echo ""
python3 - "$TOPICS_INDEX" "$CATEGORIES_PATH" << 'PYEOF'
import json, os, sys
index_path, categories_path = sys.argv[1:3]
with open(index_path) as f:
    topics = json.load(f)["topics"]
known = set()
if os.path.exists(categories_path):
    with open(categories_path) as f:
        known = set(json.load(f).get("categories", {}).keys())
issues = 0
for key, meta in topics.items():
    if meta.get("status") == "archived":
        continue
    cat = meta.get("category")
    if not cat:
        print(f"  NO CATEGORY: {key}")
        issues += 1
    elif known and cat not in known:
        print(f"  UNKNOWN CATEGORY: {key} → {cat}")
        issues += 1
sys.exit(issues)
PYEOF
cat_issues=$?
[ $cat_issues -gt 0 ] && warnings=$((warnings + cat_issues))
[ $cat_issues -eq 0 ] && echo "  ok: topic categories — all active topics categorized"

# 7. Folder layout matches category
echo ""
python3 - "$TOPICS_INDEX" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    topics = json.load(f)["topics"]
issues = 0
for key, meta in topics.items():
    if meta.get("status") == "archived":
        continue
    folder = meta.get("folder") or ""
    cat = meta.get("category") or ""
    path = meta.get("path", "")
    if not folder:
        print(f"  FLAT FILE (not in category folder): {path}")
        issues += 1
    elif folder != cat:
        print(f"  FOLDER MISMATCH: {path} (category={cat}, folder={folder})")
        issues += 1
sys.exit(issues)
PYEOF
folder_issues=$?
[ $folder_issues -gt 0 ] && warnings=$((warnings + folder_issues))
[ $folder_issues -eq 0 ] && echo "  ok: topic folders — category folders match metadata"

# 5. Manifest generation date
generated=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('generated','unknown'))")
echo ""
echo "  manifest generated: $generated"

echo ""
echo "Done. Errors: $errors | Warnings: $warnings"
[ $errors -gt 0 ] && exit 1
[ $warnings -gt 0 ] && echo "Run: bash framework/agent/scripts/build-index.sh" && exit 1
exit 0
