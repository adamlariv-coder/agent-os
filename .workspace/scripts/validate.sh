#!/bin/bash
# Validate framework consistency after setup or skill changes.
# Usage: bash .workspace/scripts/validate.sh

set -euo pipefail

REPO_ROOT="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
[ -z "${REPO_ROOT:-}" ] && REPO_ROOT="$(git rev-parse --show-toplevel)"
REGISTRY="$REPO_ROOT/framework/skills/registry.json"

echo ""
echo "=== Framework Validation ==="
echo ""

if [ ! -f "$REGISTRY" ]; then
  echo "  MISSING: framework/skills/registry.json"
  exit 1
fi

python3 - "$REPO_ROOT" "$REGISTRY" << 'PYEOF'
import json, os, sys
root, registry_path = sys.argv[1], sys.argv[2]
skills_dir = os.path.join(root, "framework/skills")
errors = 0
with open(registry_path) as f:
    registry = json.load(f)
skills = registry.get("skills", {})
for name, meta in skills.items():
    path = os.path.join(root, meta.get("path", ""))
    if not os.path.isfile(path):
        print(f"  MISSING SKILL FILE: {meta.get('path')}")
        errors += 1
    else:
        print(f"  ok: {name}")
on_disk = set()
for entry in os.listdir(skills_dir):
    sd = os.path.join(skills_dir, entry)
    if os.path.isdir(sd) and os.path.isfile(os.path.join(sd, "SKILL.md")):
        on_disk.add(entry)
registered = set(skills.keys())
for orphan in sorted(on_disk - registered):
    print(f"  UNREGISTERED: framework/skills/{orphan}/ (has SKILL.md, not in registry.json)")
    errors += 1
sys.exit(errors)
PYEOF
errors=$?

echo ""
if [ -d "$REPO_ROOT/personal/agent" ]; then
  bash "$REPO_ROOT/framework/agent/scripts/validate-indexes.sh" || errors=$((errors + 1))
else
  echo "  skip: personal/ not scaffolded — index validation deferred"
fi

echo ""
[ $errors -gt 0 ] && echo "Validation failed ($errors issue(s))." && exit 1
echo "Validation passed."
exit 0
