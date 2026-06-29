#!/bin/bash
# Install a skill from a git URL or local path.
# Usage:
#   install.sh <git-url>       # from git remote
#   install.sh <local/path>    # from local directory

set -e

SOURCE="$1"
REPO_ROOT="$(git rev-parse --show-toplevel)"
REGISTRY="$REPO_ROOT/framework/skills/registry.json"
TODAY="$(date +%Y-%m-%d)"

if [ -z "$SOURCE" ]; then
  echo "Usage: install.sh <git-url|local-path>"
  exit 1
fi

# Determine skill name and source type
if [ -d "$SOURCE" ]; then
  SOURCE_TYPE="local"
  SKILL_NAME="$(basename "$SOURCE")"
  SKILL_SRC="$SOURCE"
elif echo "$SOURCE" | grep -qE '^https?://|^git@'; then
  SOURCE_TYPE="git"
  SKILL_NAME="$(basename "$SOURCE" .git)"
  SKILL_SRC="$REPO_ROOT/framework/skills/$SKILL_NAME"
  echo "Cloning $SOURCE..."
  git clone "$SOURCE" "$SKILL_SRC"
else
  echo "Error: source must be a local path or git URL"
  exit 1
fi

SKILL_DEST="$REPO_ROOT/framework/skills/$SKILL_NAME"

# Copy if local
if [ "$SOURCE_TYPE" = "local" ] && [ "$SKILL_SRC" != "$SKILL_DEST" ]; then
  cp -r "$SKILL_SRC" "$SKILL_DEST"
fi

# Verify SKILL.md exists
if [ ! -f "$SKILL_DEST/SKILL.md" ]; then
  echo "Error: no SKILL.md found in $SKILL_DEST"
  exit 1
fi

# Update registry
python3 - "$REGISTRY" "$SKILL_NAME" "$TODAY" "$SOURCE_TYPE" "$SOURCE" << 'PYEOF'
import sys, json
registry_path, name, date, source_type, source_url = sys.argv[1:]
with open(registry_path) as f:
    registry = json.load(f)
if name not in registry["skills"]:
    registry["skills"][name] = {
        "path": f"framework/skills/{name}/SKILL.md",
        "source": source_url,
        "version": "1.0.0",
        "installed": date,
        "description": "TODO — read SKILL.md and update",
        "triggers": []
    }
    with open(registry_path, "w") as f:
        json.dump(registry, f, indent=2)
    print(f"Registry updated: {name}")
else:
    print(f"Skill '{name}' already in registry — skipped.")
PYEOF

echo ""
echo "✓ Skill '$SKILL_NAME' installed at framework/skills/$SKILL_NAME"
echo ""
echo "Next steps:"
echo "  1. Update triggers in framework/skills/registry.json"
echo "  2. Add the skill entry to framework/skills/registry.json (INDEX.md is generated)"
echo "  3. Run: bash framework/agent/scripts/build-index.sh"
