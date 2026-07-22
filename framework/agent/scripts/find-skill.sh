#!/bin/bash
# Find skills matching a keyword. Checks trigger keywords, descriptions, and names.
# Usage: find-skill.sh <keyword>

KEYWORD="$1"
REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
REGISTRY="$REPO_ROOT/framework/skills/registry.json"

if [ -z "$KEYWORD" ]; then
  echo "Usage: find-skill.sh <keyword>"
  exit 1
fi

echo "Skills matching: $KEYWORD"
echo ""

if command -v python3 &>/dev/null && [ -f "$REGISTRY" ]; then
  python3 - "$KEYWORD" "$REGISTRY" << 'PYEOF'
import sys, json
keyword = sys.argv[1].lower()
with open(sys.argv[2]) as f:
    registry = json.load(f)
for name, meta in registry.get("skills", {}).items():
    desc = meta.get("description", "").lower()
    triggers = ",".join(meta.get("triggers", [])).lower()
    if keyword in name.lower() or keyword in desc or keyword in triggers:
        print(f"  {name:20} {meta.get('path', '')}  [{meta.get('source', 'local')}]")
PYEOF
  echo ""
fi

echo "Full text matches:"
grep -ril "$KEYWORD" "$REPO_ROOT/framework/skills" --include="SKILL.md" 2>/dev/null | \
  while read -r f; do echo "  ${f#$REPO_ROOT/}"; done
