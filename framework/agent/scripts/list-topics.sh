#!/bin/bash
# List knowledge topics, optionally filtered by category.
# Usage:
#   list-topics.sh                    # all topics grouped by category
#   list-topics.sh --category ecp     # topics in one category
#   list-topics.sh --json             # machine-readable output

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
TOPICS_INDEX="$REPO_ROOT/personal/agent/topics-index.json"
CATEGORIES="$REPO_ROOT/framework/knowledge/topic-categories.json"

CATEGORY=""
JSON=0

while [ $# -gt 0 ]; do
  case "$1" in
    --category) CATEGORY="$2"; shift 2 ;;
    --json)     JSON=1; shift ;;
    -h|--help)
      echo "Usage: list-topics.sh [--category SLUG] [--json]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ ! -f "$TOPICS_INDEX" ]; then
  echo "topics-index.json missing — run: bash framework/agent/scripts/build-index.sh"
  exit 1
fi

python3 - "$TOPICS_INDEX" "$CATEGORIES" "$CATEGORY" "$JSON" << 'PYEOF'
import json, sys, os

index_path, categories_path, filter_cat, as_json = sys.argv[1:5]
as_json = as_json == "1"

with open(index_path) as f:
    topics = json.load(f)["topics"]

labels = {}
if os.path.exists(categories_path):
    with open(categories_path) as f:
        labels = {k: v.get("label", k) for k, v in json.load(f).get("categories", {}).items()}

grouped = {}
for key, meta in sorted(topics.items()):
    if meta.get("status") == "archived":
        continue
    cat = meta.get("category") or "uncategorized"
    grouped.setdefault(cat, []).append((key, meta))

if filter_cat:
    grouped = {filter_cat: grouped.get(filter_cat, [])}

if as_json:
    out = {}
    for cat, items in grouped.items():
        out[cat] = [{"key": k, **m} for k, m in items]
    print(json.dumps(out, indent=2))
    sys.exit(0)

if not grouped:
    print("No topics found.")
    sys.exit(0)

for cat in sorted(grouped.keys(), key=lambda c: (c == "uncategorized", labels.get(c, c))):
    label = labels.get(cat, cat)
    print(f"## {label} ({cat})")
    print()
    for key, meta in grouped[cat]:
        title = meta.get("title", key)
        updated = meta.get("updated") or "—"
        summary = (meta.get("summary") or "")[:80]
        print(f"  {key}")
        print(f"    {title} | updated {updated}")
        if summary:
            print(f"    {summary}")
        print()
PYEOF
