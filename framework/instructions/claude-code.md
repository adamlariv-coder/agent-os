# Claude Code Conventions

Conventions specific to Claude Code sessions in this workspace.
Global rules: `framework/instructions/global.md` (always read first).

---

## Session startup

Startup context is injected automatically by the **SessionStart hook** (`framework/agent/scripts/session-start.sh`):
identity, the rules digest (`framework/instructions/boot-digest.md`), and the routing entry point — **no Read calls needed**.
Per-prompt routing hints come from the **UserPromptSubmit hook** (`framework/agent/scripts/prompt-route.sh`).

Do not re-read `startup.md`, `identity.md`, this file, or `global.md` at startup — the digest covers the essentials.
Load the full files only when a task needs detail beyond the digest. If `personal/` is missing, the hook flags
first-time setup (see `framework/knowledge/setup-guide.md`).

Fallback if hooks aren't installed (no injected boot context): read in order — `personal/agent/startup.md` →
`personal/memory/core/identity.md` → this file.

---

## Tool preferences

- Prefer `Read`, `Edit`, `Write` over Bash for file operations
- Use Bash for shell-only operations (git, find, grep, running scripts)
- Before editing a file, always `Read` it first — the Edit tool requires it
- For broad searches, spawn an `Explore` subagent rather than chaining greps

---

## Skill routing priority

Framework skills (`framework/skills/`) take priority over `anthropic-skills:*` when both cover the same domain. The routing hook surfaces the framework skill first.

- Load the framework skill and follow its instructions — it delegates to `anthropic-skills:*` where appropriate.
- Never invoke `anthropic-skills:X` directly when a framework skill for that domain exists.
- Exception: if the user explicitly invokes `/skill anthropic-skills:X`, honor it — that's intentional direct access to the base skill.

---

## File editing rules

- Never create documentation files unless explicitly requested
- Prefer editing existing files over creating new ones
- No comments unless the WHY is non-obvious
- No trailing summaries in responses — the user can read the diff

---

## Git in this workspace

- Run `git status` before any destructive operation — never lose uncommitted work
- If uncommitted content exists before a destructive op, commit it first or warn explicitly
- Use `setup.sh` to install hooks: `./setup.sh` — hooks live in `.workspace/hooks/`
- The `commit-msg` hook enforces `[CONFIRM MEMORY UPDATE]` for protected zones
- **Framework repo** (`framework/`) has branch protection and requires PR-based workflow:
  - Create feature branches for any framework change (`feature/<name>`)
  - Commit to the feature branch
  - Push the feature branch, open a PR to `main`, **never push directly to `main`**
  - After PR merges, clean up the local branch
- **Personal repo** (`personal/`) pushes directly to `main` — no feature branches needed
- Before starting new framework work, check `git branch -r` in the framework repo for in-flight PRs. Don't stack multiple feature branches; aim for one at a time.

### Push cadence — framework repo

**Framework repo**: feature branches and PRs are now the standard. Push the feature branch, open a PR to `main`:

- Create a feature branch off `main`: `git checkout -b feature/<name>`
- Commit to the feature branch
- Push the feature branch: `git push origin feature/<name>`
- Open a PR on GitHub
- After PR review and merge, clean up locally: `git branch -d feature/<name>`
- Do **not** push directly to `main` — branch protection blocks it

**Personal repo**: push `main` directly.

- At session end, check for unpushed commits: `git -C personal log origin/main..main --oneline`
- If any, push: `git -C personal push origin main`

**General discipline:**
- Don't leave feature branches unpushed for more than a session — they create confusion about what's "in flight"
- Before starting new framework work, check existing feature branches: `git -C <framework-root> branch -r`
- Keep only one active feature branch at a time in the framework repo
- Confirm before opening a PR if it touches shared framework state (skills, instructions, indexes)

---

## Memory discipline

- **All memory goes in `personal/memory/` — never in `.claude/` folders.**
- `.claude/projects/*/memory/` is auto-memory managed by the Claude Code harness. Do not write to it intentionally. It is not source-controlled, not portable across machines, and not the source of truth.
- When saving a fact, reference, preference, or project context: write it to the appropriate file under `personal/memory/` and commit with `[CONFIRM MEMORY UPDATE]`.

---

## Context management

- `personal/agent/scratch/` is your temp space — gitignored, write freely
- When context runs long: dump to `personal/agent/scratch/context-dump.md`, tell the user
- Do not repeat what you just did at the end of responses

---

## MCP server setup protocol

When the user asks to add an MCP server, set up credentials for one, or you diagnose that MCP tools failed to load due to missing env vars — follow this protocol.

### Step 1 — Ask where credentials should live

The user has three options. Use `AskUserQuestion` to surface them. Reference `framework/mcp/INDEX.md` for the full trade-off table; the short version:

| Option | When it fits |
|---|---|
| **`~/.zshenv` + zsh-wrapped MCP command** | Robust default — works whether Claude Code is launched from Dock, Spotlight, or terminal |
| **`~/.zshrc` (or `~/.bashrc`)** | Only if the user reliably launches Claude Code from a terminal where their rc file is sourced |
| **`env` block in `~/.claude.json`** | Last resort; secrets sit in plain text on disk |

If they don't know, recommend the first. Confirm with `ps -p $PPID -o command=` whether Claude Code is currently running as a GUI app (`claude.app/...`) or from a terminal — that's the deciding signal.

### Step 2 — Never collect secret values yourself

This rule is absolute:

- **Do not ask the user to type a token in chat.** Anything they type enters the model context, conversation logs, and possibly memory summaries.
- **Do not echo, log, `cat`, or `grep` a token value.** Even from a file the user already wrote.
- **Do not use Bash `echo`, `sed`, or `cat <<EOF` to write a token into a file.** That puts the value in tool-call arguments, which are logged.

The correct pattern is to let the user edit the file themselves in their own editor:

```bash
open ~/.zshenv          # macOS — opens in the user's default editor
open ~/.claude.json     # same
```

After the user saves and closes, do NOT read the file back to verify content. Verify *function* instead

To check whether a variable is set in *some* process's env without revealing its value:

```bash
zsh -c 'source ~/.zshenv 2>/dev/null; [ -n "$WIKI_MCP_TOKEN" ] && echo "set (len=${#WIKI_MCP_TOKEN})" || echo "NOT SET"'
```

Length and existence are safe to log. The value itself is never.

### Step 3 — Register the server

Use `framework/agent/scripts/mcp-setup.sh --install <name> -y` to add a server to `~/.claude.json` non-interactively. The script never collects credentials — only registers the command.

If you chose Option 1 (zsh wrapper), edit `~/.claude.json` after registration to wrap the command:

```json
"wiki": {
  "command": "zsh",
  "args": ["-c", "exec node /absolute/path/to/dist/index.js"]
}
```

### Step 4 — Tell the user to restart Claude Code

MCP server tool lists are computed at session start. After they restart, run a smoke test (the scratch harness, or `ToolSearch` for the new `mcp__<server>__*` tools) to confirm tools loaded.

---

## Workspace-specific tool use

```bash
# Run workspace inventory
bash framework/agent/scripts/inventory.sh

# Find content by keyword
bash framework/agent/scripts/find-content.sh <keyword>
bash framework/agent/scripts/find-content.sh <keyword> --skills
bash framework/agent/scripts/find-content.sh <keyword> --knowledge
bash framework/agent/scripts/find-content.sh <keyword> --memory

# Find a skill
bash framework/agent/scripts/find-skill.sh <keyword>

# Review knowledge freshness
bash framework/agent/scripts/review-knowledge.sh
```
