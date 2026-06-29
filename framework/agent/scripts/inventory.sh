#!/bin/bash
# Quick workspace inventory. Run at session start or any time to get current state.
# Usage: inventory.sh

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{print $2; exit}')"

echo ""
echo "=== Workspace Inventory ==="
echo ""

echo "Skills:"
for skill_dir in "$REPO_ROOT"/framework/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  [ ! -f "$skill_dir/SKILL.md" ] && continue
  version=$(grep "^version:" "$skill_dir/SKILL.md" 2>/dev/null | awk '{print $2}' | tr -d '"')
  echo "  $name  v${version:-?}"
done

echo ""
echo "Project memory:"
mounted=0
for proj_dir in "$REPO_ROOT"/personal/memory/projects/*/; do
  [ -d "$proj_dir" ] || continue
  name="$(basename "$proj_dir")"
  [ "$name" = ".gitkeep" ] && continue
  echo "  $name"
  mounted=$((mounted + 1))
done
[ $mounted -eq 0 ] && echo "  (none mounted)"

echo ""
echo "MCP servers:"
server_count=0
for server_dir in "$REPO_ROOT"/framework/mcp/servers/*/; do
  [ -d "$server_dir" ] || continue
  echo "  $(basename "$server_dir")"
  server_count=$((server_count + 1))
done
[ $server_count -eq 0 ] && echo "  (none)"

echo ""
echo "Git:"
echo "  branch: $(git branch --show-current)"
echo "  commits: $(git rev-list --count HEAD)"
echo ""
