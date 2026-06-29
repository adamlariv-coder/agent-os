#!/bin/bash
# Route a query to the right file(s) to load.
# Usage: bash framework/agent/scripts/route.sh "QUERY"
# Output: one path per line, primary load first

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{print $2; exit}')"
MANIFEST="$REPO_ROOT/personal/agent/routing-manifest.json"

if [ -z "$1" ]; then
  echo "Usage: route.sh \"QUERY\""
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "routing-manifest.json missing — run: bash framework/agent/scripts/build-index.sh"
  exit 1
fi

python3 - "$MANIFEST" "$1" << 'PYEOF'
import sys, json

manifest_path = sys.argv[1]
query = sys.argv[2].lower()

with open(manifest_path) as f:
    data = json.load(f)

matches = []
for route in data["routes"]:
    score = sum(1 for t in route["triggers"] if t.lower() in query or query in t.lower())
    if score > 0:
        matches.append((score, route))

matches.sort(key=lambda x: -x[0])

if not matches:
    print("no match — try: bash framework/agent/scripts/find-content.sh \"QUERY\" --knowledge")
    sys.exit(0)

for _, route in matches[:3]:
    print(route["load"])
    for extra in route.get("also", []):
        print(f"  also: {extra}")
PYEOF
