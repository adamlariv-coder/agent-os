# Workspace Boot Digest

Injected every session by the SessionStart hook. These are the load-bearing essentials;
the full rules live in `framework/instructions/{global,claude-code}.md` — load on demand.

## Structure
- `framework/` = shareable, public-safe. `personal/` = private (its own git repo; gitignored here).
- Placement: if a new file could go either way, it goes in `personal/`. Never put personal data in `framework/`.

## Protected zones — need `[CONFIRM MEMORY UPDATE]` in the commit message
- `personal/memory/` and `framework/instructions/`. The `commit-msg` hook rejects commits without the token.
- To change one: propose the diff, wait for explicit approval, then write.

## Git
- Always work on `main` — both repos. No `dev`/`feat/`/`skill/`/worktree branches. On a non-main branch is the bug: fast-forward `main` to it, delete the branch.
- Commit and push only when asked. Confirm before pushing shared framework state. Push at session end, not per commit.
- `git status` before any destructive op; never lose uncommitted work.

## Files & memory
- Memory goes in `personal/memory/` only — never in `.claude/`.
- Edits to the user's working files → produce a copy for him to apply manually; never overwrite the original. Resource source files are read-only.
- Don't create docs unless asked; prefer editing existing files; no trailing summaries.

## Navigation
- Per-prompt routing hints are injected automatically. For more: `bash framework/agent/scripts/route.sh "QUERY"`.
- Never scan the repo cold — always via an index. Load skills on demand only; never pre-load.

## Models
- Session default: **Sonnet**. Skills pin their own model via frontmatter (Opus for `hiring`/`prd`, Haiku for `agentignore`, Sonnet for the rest).
- Escalate the main thread to Opus only for genuinely high-reasoning work; simple lookups can stay on Sonnet/Haiku.
