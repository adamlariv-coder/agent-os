# Global Rules — All Agents

These rules apply regardless of tool. No exceptions.

---

## Protected zones

Never modify these files without explicit user confirmation (`[CONFIRM MEMORY UPDATE]` in the commit message):
- `personal/memory/` — user identity, preferences, project context
- `framework/instructions/` — these rules and tool-specific conventions

To propose a change, output:
```
[CONFIRM MEMORY UPDATE]
File: personal/memory/core/preferences.md
Change: [what would change]
Reason: [why]
```
Then wait. Do not write until the user explicitly approves.

---

## Framework vs personal — placement rule

Before adding any file, directory, or configuration to this workspace, ask:

- **Framework** (`framework/`): generic, shareable, contains no personal data. Safe to make public. Skills, instructions, structural tools, agent scripts.
- **Personal** (`personal/`): user-specific. Memory, derived knowledge, routing content, project context.

If something could belong to either, it belongs in **personal**. When unsure, ask the user before creating it.

This rule is non-negotiable. Violations put personal data at risk of being committed to the public repo.

---

## Navigation protocol

1. Read `personal/agent/startup.md` first — it routes you everywhere
2. Never scan the full repo cold — always use an index
3. Load skills on demand only — never pre-load speculatively
4. Two reads maximum to find anything: startup.md → target file

**Worktree awareness**: `personal/` lives at the main repo root, not inside a linked worktree. Always resolve paths using:
```bash
MAIN_ROOT="$(git worktree list --porcelain | awk '/^worktree/{print $2; exit}')"
```
Never use `git rev-parse --show-toplevel` to locate `personal/` — it returns the worktree path in linked worktrees.

---

## Content safety

- Never commit secrets, credentials, or API keys
- `.workspace/config/*.env` is gitignored — use `.env.example` for templates
- If you find credentials in a file, flag them before continuing

---

## Index discipline

When you add or change anything structural:
- New skill → edit `framework/skills/registry.json` (single source), then run `bash framework/agent/scripts/build-index.sh` — it regenerates `framework/skills/INDEX.md` + routing
- New MCP server → update `framework/mcp/INDEX.md` + `framework/knowledge/mcp-index.md`
- New routing pattern → update `personal/agent/framework-routes.json` then run `build-index.sh`
- Architectural decision → append to `framework/knowledge/decisions-log.md`
- Structural change → append to `framework/knowledge/changelog.md`

---

## Context optimization

When context is running long, before starting a new major task:
1. Summarize the session's decisions and outputs into `personal/agent/scratch/context-dump.md`
2. Note which files were created or modified
3. Note what's next
4. Tell the user you've done this

Do not start a context dump mid-task. Finish the current task first.

---

## Knowledge lifecycle

Topic files in `personal/knowledge/topics/` must start with:
```
> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD
```

Staleness thresholds (run `bash framework/agent/scripts/review-knowledge.sh`):
- 60+ days since update → stale (flag for review)
- 90+ days since update → archive candidate

To archive: set `status: archived`, add `archived: YYYY-MM-DD`, move to `personal/knowledge/archive/`, then run `build-index.sh`.

---

## Commit conventions

- **Always work on `main`** — both the framework repo and `personal/`. Never create `dev`, `feat/`, `skill/`, or worktree branches (see `CLAUDE.md` § Branch). On a non-`main` branch is the bug: fast-forward `main` to it and delete the branch.
- Protected commits require the `[CONFIRM MEMORY UPDATE]` token in the message
- Commit messages: imperative present tense ("add X", "fix Y", not "added X")
