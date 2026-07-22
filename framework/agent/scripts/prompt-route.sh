#!/bin/bash
# UserPromptSubmit hook — auto-route the prompt to relevant knowledge/skill files.
# Reads the hook's JSON payload on stdin, scores the prompt against routing-manifest.json,
# and injects the top matches as paths only. The 21KB manifest never enters context —
# only the matched path lines do. Emits nothing on no-match (keeps cost ~0 on trivial turns).
set -euo pipefail

ROOT="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
[ -z "${ROOT:-}" ] && ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MANIFEST="$ROOT/personal/agent/routing-manifest.json"
[ -f "$MANIFEST" ] || exit 0

# The heredoc below is Python's stdin, so capture the hook payload first and pass it as argv.
PAYLOAD="$(cat)"

python3 - "$MANIFEST" "$PAYLOAD" <<'PYEOF'
import sys, json

manifest_path = sys.argv[1]
raw = sys.argv[2] if len(sys.argv) > 2 else ""
try:
    prompt = (json.loads(raw).get("prompt") or "").lower()
except Exception:
    prompt = raw.lower()
if not prompt.strip():
    sys.exit(0)

with open(manifest_path) as f:
    data = json.load(f)

scored = []
for route in data.get("routes", []):
    # Direction that matters: a trigger phrase appears in the prompt.
    score = sum(1 for t in route.get("triggers", []) if t and t.lower() in prompt)
    if score:
        scored.append((score, route))
scored.sort(key=lambda x: -x[0])
if not scored:
    sys.exit(0)

lines, seen = [], set()
for _, route in scored[:3]:
    load = route["load"]
    if load in seen:
        continue
    seen.add(load)
    desc = route.get("description", "")
    lines.append(f"- `{load}`" + (f" — {desc}" if desc else ""))
    for extra in route.get("also", []):
        if extra not in seen:
            seen.add(extra)
            lines.append(f"  - also: `{extra}`")

ctx = ("Routing hint (not a directive) — workspace files that may be relevant; "
       "load only if useful:\n" + "\n".join(lines))
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ctx,
    }
}))
PYEOF
