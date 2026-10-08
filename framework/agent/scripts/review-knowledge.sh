#!/bin/bash
# Review personal/knowledge/topics/ for staleness. Surfaces archive candidates.
# Never auto-archives — output is for Claude to evaluate and act on.
# Usage: review-knowledge.sh [--stale-days=N] [--archive-days=N]

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
TOPICS_DIR="$REPO_ROOT/personal/knowledge/topics"
STALE_DAYS=60
ARCHIVE_DAYS=90

for arg in "$@"; do
  case $arg in
    --stale-days=*)   STALE_DAYS="${arg#*=}" ;;
    --archive-days=*) ARCHIVE_DAYS="${arg#*=}" ;;
  esac
done

TODAY=$(date +%s)

parse_date() {
  local d="$1"
  # macOS
  if date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null; then return; fi
  # Linux
  date -d "$d" +%s 2>/dev/null
}

extract_updated() {
  local file="$1"
  # format 1: > status: active | ... | updated: YYYY-MM-DD
  local d
  d=$(grep -m1 "^> status:" "$file" | grep -oE "updated: [0-9]{4}-[0-9]{2}-[0-9]{2}" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
  [ -n "$d" ] && echo "$d" && return
  # format 2: Last refreshed: YYYY-MM-DD
  grep -m1 "Last refreshed:" "$file" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}"
}

echo ""
echo "=== Knowledge Freshness Review ==="
echo "Stale threshold: ${STALE_DAYS}d | Archive threshold: ${ARCHIVE_DAYS}d"
echo ""

active=0; stale=0; archive_candidates=0; no_timestamp=0

while IFS= read -r file; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"
  rel="${file#$TOPICS_DIR/}"
  status=$(grep -m1 "^> status:" "$file" | grep -oE "active|archived|stale|needs-rebuild" | head -1)
  [ "$status" = "archived" ] && continue

  updated=$(extract_updated "$file")

  if [ -z "$updated" ]; then
    echo "  NO TIMESTAMP: $rel"
    no_timestamp=$((no_timestamp + 1)); continue
  fi

  updated_ts=$(parse_date "$updated")
  [ -z "$updated_ts" ] && echo "  UNPARSEABLE DATE ($updated): $rel" && continue

  days_old=$(( (TODAY - updated_ts) / 86400 ))

  if [ "$days_old" -ge "$ARCHIVE_DAYS" ]; then
    echo "  ARCHIVE CANDIDATE ($days_old days): $rel"
    archive_candidates=$((archive_candidates + 1))
  elif [ "$days_old" -ge "$STALE_DAYS" ]; then
    echo "  STALE ($days_old days): $rel"
    stale=$((stale + 1))
  else
    echo "  ok ($days_old days): $rel"
    active=$((active + 1))
  fi
done < <(find "$TOPICS_DIR" -name "*.md" -type f | sort)

echo ""
echo "Summary: $active active | $stale stale | $archive_candidates archive candidates | $no_timestamp missing timestamps"
echo ""

if [ $archive_candidates -gt 0 ] || [ $stale -gt 0 ]; then
  echo "Action: For each flagged file:"
  echo "  1. Update content + bump 'updated:' date if still relevant"
  echo "  2. Archive: set status→archived, move to personal/knowledge/archive/"
  echo "     Then run build-index.sh + validate-indexes.sh"
  echo ""
fi
