# AGENTS.md — Agent Onboarding

You are operating inside an agent workspace owned by its user.
Read this file completely before doing anything else.

This workspace has two layers:
- `framework/` — shareable skills, instructions, structural knowledge
- `personal/` — private memory, derived knowledge, agent routing (separate git repo)

**Windows:** run all bash scripts via WSL (`wsl -e bash -lc "cd /mnt/c/.../agent-os && …"`). See `CLAUDE.md` § Windows (WSL).

## Your first steps

1. Check if `personal/` exists
   - **No** → Run first-time setup (see `CLAUDE.md` for the full procedure)
   - **Yes** → Read `personal/agent/startup.md` — your routing guide to everything
2. Read `framework/instructions/global.md` — rules you must follow without exception
3. Load the relevant skill from `framework/skills/` before starting any task

## Protected zones

NEVER modify these without the user saying `[CONFIRM MEMORY UPDATE]`:
- `personal/memory/`
- `framework/instructions/`

Violations will be caught by the pre-commit hook and rejected.

## How to find things

| I need... | Go to |
|-----------|-------|
| A skill | `personal/agent/startup.md` → `framework/skills/` |
| User memory or project context | `personal/agent/startup.md` → `personal/memory/` |
| An MCP utility | `framework/mcp/INDEX.md` |
| Workspace structure/guidelines | `framework/knowledge/taxonomy.md` |
| Everything else | `personal/agent/startup.md` |

## How to add things

- **New skill** → follow `framework/knowledge/skill-authoring.md`: edit `framework/skills/registry.json` (single source), then run `bash framework/agent/scripts/build-index.sh` (regenerates `framework/skills/INDEX.md` + routing)
- **New project memory** → create `personal/memory/projects/<name>/CONTEXT.md`, commit with `[CONFIRM MEMORY UPDATE]`
- **New MCP server** → `bash framework/agent/scripts/mcp-setup.sh --install <name> -y`; update `framework/mcp/INDEX.md` + `framework/knowledge/mcp-index.md`

## Proposing changes to protected zones

To propose a memory or instruction update, output exactly this block and wait:

```
[CONFIRM MEMORY UPDATE]
File: personal/memory/core/preferences.md
Change: [description of what would change]
Reason: [why this should be updated]
```

Do not write to `personal/memory/` or `framework/instructions/` until the user replies with explicit approval.
