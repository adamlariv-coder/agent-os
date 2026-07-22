# Rules

Hard rules that apply in all sessions. These override defaults.

---

## Non-negotiable

- Never lose uncommitted content — always run `git status` before any destructive git operation. If uncommitted work exists, commit it first or warn explicitly.
- No `[CONFIRM MEMORY UPDATE]` = no write to `personal/memory/` or `framework/instructions/`
- Never push to `main` — always use `dev` or a feature branch
- Worktree cleanup — when a worktree's branch is fully merged: `git worktree remove <path>` then `git branch -d <branch>`. Run `git worktree list` to audit.

## Worktree awareness

`personal/` lives at the main repo root, not inside a linked worktree. Always resolve it as:
```bash
MAIN_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
```
Never use `git rev-parse --show-toplevel` to locate `personal/`. In a worktree it returns the worktree path — `personal/` won't be there, and startup will incorrectly trigger first-time setup.

## Framework vs personal — placement rule

Before adding any file, directory, or configuration, ask: does this belong in `framework/` (generic, shareable, no personal data) or `personal/` (user-specific)?

- **Framework**: skills, instructions, agent scripts, structural tools — safe to make public
- **Personal**: memory, derived knowledge, routing content, project context — private

If it could go either way, it goes in **personal**. When unsure, ask before creating it.

## Agent index maintenance

After adding ANY topic file to `personal/knowledge/topics/`:
1. Add `> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD` as the first line
2. Run `bash framework/agent/scripts/build-index.sh`
3. Run `bash framework/agent/scripts/validate-indexes.sh` — resolve all warnings before committing

## Resources and files

- Resource files (anything listed in `personal/knowledge/resources.md` or shared for parsing) are **read-only** — parse and extract knowledge, never modify the source.
- When making changes to any of the user's working files, always work on a **copy** and present the result for them to apply manually. Never overwrite the original.

## Content

- No emojis unless explicitly requested
- No multi-paragraph docstrings or comment blocks
- Don't explain what the code does — well-named identifiers do that
- Don't add features beyond what was asked

## Communication

- Terse over verbose — one sentence updates, not paragraphs
- State results and decisions directly
- Ask when context is needed, don't assume
