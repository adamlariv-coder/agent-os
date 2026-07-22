# CLAUDE.md — Claude Code Session Configuration

This workspace has two layers:
- `framework/` — shareable skills, instructions, and structural knowledge. Safe to make public.
- `personal/` — your private memory, derived knowledge, and agent routing. Keep this in a separate private git repo.

---

## Windows (WSL)

Shell scripts here are **bash** and target **Linux**. On Windows, run them inside **WSL** (Ubuntu), not PowerShell or Git Bash.

From PowerShell or a Cursor terminal on Windows:

```bash
wsl -e bash -lc "cd /mnt/c/Workspaces/agent-os && ./setup.sh"
wsl -e bash -lc "cd /mnt/c/Workspaces/agent-os && bash framework/agent/scripts/build-index.sh"
```

Or open a WSL terminal and `cd` to the repo (`/mnt/c/...` for files under `C:\`).

Agents: if `uname -s` is not `Linux`, or a script fails with `$'\r'`, `chmod`, or `bash\r` errors, re-run the same command via `wsl -e bash -lc "cd <repo> && …"`. Resolve `$MAIN_ROOT` and run all `framework/agent/scripts/*.sh` from WSL.

---

## Session start

**First, resolve the main repo root — you may be running inside a git worktree.**

```bash
MAIN_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
```

All paths below are relative to `$MAIN_ROOT`. Never use `git rev-parse --show-toplevel` for locating `personal/` — in a worktree it returns the worktree path, not the main repo root.

**Then check whether `$MAIN_ROOT/personal/` exists.**

### If `personal/` does NOT exist — First-time setup

The SessionStart hook flags this automatically. Follow the canonical first-time flow in
`framework/knowledge/setup-guide.md` § Step 3 (greet → `./setup.sh` → init `personal/` →
copy scaffold → identity interview → `build-index.sh` → commit).

### If `personal/` exists — Normal session startup

The **SessionStart hook injects your boot context automatically** — identity, the rules digest
(`framework/instructions/boot-digest.md`), and the routing entry point — with **zero Read calls**.
Per-prompt routing hints are injected by the **UserPromptSubmit hook**. You do **not** need to read
`startup.md`, `identity.md`, `claude-code.md`, or `global.md` at startup; load the full files only
when a task needs more than the digest.

Fallback (hooks not installed → no injected boot context): read in order
`personal/agent/startup.md` → `personal/memory/core/identity.md` → `framework/instructions/claude-code.md`.

When the user asks about structure, taxonomy, or guidelines → load `framework/knowledge/taxonomy.md`. One file, complete picture.

---

## Your own space

`personal/agent/` is yours. You manage it freely — no `[CONFIRM MEMORY UPDATE]` required.

Run `bash framework/agent/scripts/build-index.sh` whenever topics, skills, or framework routes change — it regenerates all indexes in one pass.

---

## Skills vs instructions

| | `framework/instructions/` | `framework/skills/` |
|---|---|---|
| When loaded | Always, session start | On demand, task-triggered |
| Size | Small | Can be large |
| Purpose | How to behave | How to do a specific task |
| Load protocol | Read at start | Read INDEX first, load SKILL.md frontmatter, then body |

Never pre-load skills speculatively. Use `bash framework/agent/scripts/route.sh "QUERY"` to find the right file.

---

## Protected zones

`personal/memory/` and `framework/instructions/` require `[CONFIRM MEMORY UPDATE]` in the commit message.
The `commit-msg` hook enforces this — the commit will be rejected without it.

---

## Index discipline

When you add or change anything structural:
- New skill → edit `framework/skills/registry.json` (single source), then run `bash framework/agent/scripts/build-index.sh` — it regenerates `framework/skills/INDEX.md` + routing
- New MCP server → update `framework/mcp/INDEX.md` + `framework/knowledge/mcp-index.md`
- New routing pattern → update `personal/agent/framework-routes.json` then run `build-index.sh`
- Architectural decision → append to `framework/knowledge/decisions-log.md`

---

## Branch

**Framework repo** (`framework/`) has branch protection: `main` requires PR-based workflow.

- Create a **feature branch** for any framework change: `feature/<name>` (e.g. `feature/feature-announcement`)
- Commit to the feature branch
- Push the feature branch to `origin`
- Open a PR to `main`; do not push directly to `main`
- After PR is merged, clean up the feature branch locally

**Personal repo** (`personal/`) — `main` is pushable directly. No feature branches needed.

**Session start discipline:**
- Before starting new framework work, check for in-flight feature branches: `git branch -r` (framework repo)
- If competing features are pending, wait for the PR to merge before branching
- Goal: one framework feature branch at a time; don't stack work
- Track active PRs so future sessions know what's pending

**If you find yourself on a non-`main` branch**: that's correct for the framework repo (feature branches are now the norm). For `personal/`, that would be the bug — fast-forward `main` to it, delete the branch, and continue on `main`.
