#!/bin/bash
# Validate generated indexes are fresh and consistent.
# Checks: manifest exists + all paths valid + all active topics indexed + index count matches disk
# Usage: bash framework/agent/scripts/validate-indexes.sh

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{print $2; exit}')"
TOPICS_DIR="$REPO_ROOT/personal/knowledge/topics"
TOPICS_INDEX="$REPO_ROOT/personal/agent/topics-index.json"
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
ondisk=$(ls "$TOPICS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
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
for fname in os.listdir(topics_dir):
    if not fname.endswith(".md"):
        continue
    fpath = os.path.join(topics_dir, fname)
    with open(fpath) as f:
        content = f.read()
    status_m = re.search(r'> status:\s*(\w[\w-]*)', content)
    status = status_m.group(1) if status_m else "unknown"
    if status == "archived":
        continue
    key = fname.replace(".md", "")
    if fname not in manifest_text and key not in manifest_text:
        print(f"  UNROUTED: personal/knowledge/topics/{fname}  (status: {status})")
        missing.append(fname)
sys.exit(len(missing))
PYEOF
unrouted=$?
[ $unrouted -gt 0 ] && warnings=$((warnings + unrouted))

# 5. Manifest generation date
generated=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('generated','unknown'))")
echo ""
echo "  manifest generated: $generated"

echo ""
echo "Done. Errors: $errors | Warnings: $warnings"
[ $errors -gt 0 ] && exit 1
[ $warnings -gt 0 ] && echo "Run: bash framework/agent/scripts/build-index.sh" && exit 1
exit 0
