#!/bin/bash
# SessionStart hook — inject the boot context the agent used to load by hand.
# Replaces the manual "read startup.md + identity.md + claude-code.md + global.md"
# sequence with a single deterministic injection (~400 tok, 0 Read round-trips).
# Emits JSON {hookSpecificOutput:{hookEventName,additionalContext}} on stdout.
set -euo pipefail

ROOT="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree/{print $2; exit}')"
[ -z "${ROOT:-}" ] && ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

python3 - "$ROOT" <<'PYEOF'
import sys, os, json

root = sys.argv[1]
personal      = os.path.join(root, "personal")
digest_path   = os.path.join(root, "framework/instructions/boot-digest.md")
identity_path = os.path.join(personal, "memory/core/identity.md")

parts = []
if not os.path.isdir(personal):
    parts.append(
        "FIRST-TIME SETUP NEEDED: `personal/` does not exist. Follow the first-time "
        "setup flow in `framework/knowledge/setup-guide.md` (also summarized in CLAUDE.md)."
    )
else:
    if os.path.exists(digest_path):
        with open(digest_path) as f:
            parts.append(f.read().strip())
    if os.path.exists(identity_path):
        with open(identity_path) as f:
            parts.append("## Who you're working with\n" + f.read().strip())
    parts.append(
        "## Routing\n"
        "Per-prompt routing hints are injected automatically (UserPromptSubmit hook). "
        "For manual lookup: `bash framework/agent/scripts/route.sh \"QUERY\"`. "
        "Never scan the repo cold; load skills on demand only. "
        "Full rules live in `framework/instructions/{claude-code,global}.md` — "
        "the essentials above are enough for most turns; load the full files only when needed."
    )

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(parts),
    }
}))
PYEOF
