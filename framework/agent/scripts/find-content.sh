#!/bin/bash
# Full workspace content search. Returns file paths ranked by match density.
# Usage: find-content.sh <keyword> [--skills|--memory|--knowledge|--instructions]

KEYWORD="$1"
SCOPE="$2"
REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"

if [ -z "$KEYWORD" ]; then
  echo "Usage: find-content.sh <keyword> [--skills|--memory|--knowledge|--instructions]"
  exit 1
fi

case "$SCOPE" in
  --skills)       DIRS="$REPO_ROOT/framework/skills" ;;
  --memory)       DIRS="$REPO_ROOT/personal/memory" ;;
  --knowledge)    DIRS="$REPO_ROOT/framework/knowledge $REPO_ROOT/personal/knowledge" ;;
  --instructions) DIRS="$REPO_ROOT/framework/instructions" ;;
  *)              DIRS="$REPO_ROOT/framework/skills $REPO_ROOT/personal/memory $REPO_ROOT/framework/knowledge $REPO_ROOT/personal/knowledge $REPO_ROOT/framework/instructions" ;;
esac

echo "Searching for: $KEYWORD"
echo ""

grep -ril "$KEYWORD" $DIRS --include="*.md" 2>/dev/null | while read -r file; do
  count=$(grep -ci "$KEYWORD" "$file" 2>/dev/null || echo 0)
  printf "%4d  %s\n" "$count" "${file#$REPO_ROOT/}"
done | sort -rn
