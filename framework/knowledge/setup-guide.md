# Setup Guide — Full Rebuild Reference

How to replicate or rebuild this workspace from scratch.
Quick reference: `framework/knowledge/taxonomy.md` | Decisions: `framework/knowledge/decisions-log.md`

---

## Prerequisites

- Git
- Python 3 (for registry scripts)
- Node.js (optional; only needed for Node-based skills)
- Claude Code CLI

**Windows:** install [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install) (Ubuntu). Clone or open the repo on the Windows filesystem (`C:\...`) and run every bash command from WSL:

```bash
wsl -e bash -lc "cd /mnt/c/path/to/agent-os && ./setup.sh"
```

Do not run `./setup.sh` or `framework/agent/scripts/*.sh` from PowerShell or Git Bash — hooks, line endings, and path resolution expect Linux.

On Ubuntu/Debian WSL without `pip3`, `setup.sh` bootstraps a repo-local `.venv/` and installs `framework/requirements.txt` there. Activate with `source .venv/bin/activate` when running Python tools directly.

---

## Step 1 — Clone or init the framework repo

```bash
# Option A: clone an existing framework
git clone <framework-repo-url> AgentOS
cd AgentOS

# Option B: init fresh
mkdir AgentOS && cd AgentOS
git init
```

---

## Step 2 — Run setup

```bash
./setup.sh
```

This installs git hooks from `.workspace/hooks/` into `.git/hooks/`. Run `./setup.sh --dry-run` to preview.

---

## Step 3 — Initialize personal/

```bash
git init personal/
```

On first session start, Claude Code runs this automatically when `personal/` is missing (the SessionStart hook flags it). The canonical flow:

1. Greet the user; explain the `framework/` (shareable) vs `personal/` (private) split.
2. Run `./setup.sh` if `.git/hooks/commit-msg` is absent — installs deps, git hooks, and the Claude Code hook wiring (`.claude/settings.json`).
3. Ask whether `personal/` should be its own private git repo (`git init personal/`, recommended) or uncommitted (`mkdir personal/`).
4. Copy the scaffold: `cp -r framework/scaffold/. personal/`.
5. Run the identity interview; write to `personal/memory/core/identity.md` (requires `[CONFIRM MEMORY UPDATE]`).
6. Build indexes: `bash framework/agent/scripts/build-index.sh`.
7. If using git: `cd personal && git add . && git commit -m "init: personal workspace scaffold"`, then add a private remote when ready.

The resulting structure (to scaffold manually):

```
personal/
├── agent/
│   ├── startup.md             ← routing guide + session startup sequence
│   ├── framework-routes.json  ← static routing for framework/memory/resource files
│   └── scripts/               ← copied from framework/scaffold/agent/scripts/
├── memory/
│   └── core/
│       ├── identity.md    ← fill in: who you are, your role, what's pending
│       ├── preferences.md ← fill as preferences emerge
│       └── rules.md       ← start from framework/instructions/global.md defaults
└── knowledge/
    ├── topics/            ← empty, populated through use
    └── resources.md       ← empty, add external links as you go
```

---

## Step 4 — Connect remotes (when ready)

```bash
# Framework (public)
git remote add origin <framework-repo-url>
git push -u origin main

# Personal (private)
cd personal
git remote add origin <personal-private-repo-url>
git push -u origin main
cd ..
```

---

## Directory specs

### framework/skills/SKILL.md frontmatter

```yaml
---
name: skill-name
description: >
  When to trigger this skill. Be explicit about trigger phrases.
version: 1.0.0
author: your-name
protected: false
dependencies: []
last_updated: YYYY-MM-DD
---
```

### framework/skills/registry.json schema

```json
{
  "skills": {
    "skill-name": {
      "path": "framework/skills/skill-name/SKILL.md",
      "source": "local",
      "version": "1.0.0",
      "installed": "YYYY-MM-DD",
      "model": "sonnet",
      "needs": "deps / MCP servers / files this skill requires",
      "description": "one-line description",
      "triggers": ["keyword1", "keyword2"]
    }
  }
}
```

### personal/knowledge/topics/ file header

Every topic file must start with:
```
> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD
```

---

## Adding a new skill

```bash
.workspace/scripts/add-skill.sh <skill-name>
```

This scaffolds `framework/skills/<skill-name>/SKILL.md` and a registry stub in `framework/skills/registry.json` (the single source of truth). Then:
1. Fill in `SKILL.md` content and the registry entry (`model`, `needs`, `description`, `triggers`)
2. Run `bash framework/agent/scripts/build-index.sh` — regenerates `framework/skills/INDEX.md` + routing-manifest
3. Commit

---

## Adding a new project memory

Create `personal/memory/projects/<project-name>/CONTEXT.md` manually (or have Claude do it). Commit with `[CONFIRM MEMORY UPDATE]` in the message.

---

## Adding a new MCP server

```bash
bash framework/agent/scripts/mcp-setup.sh --list                  # browse catalog
bash framework/agent/scripts/mcp-setup.sh --install <name> -y     # install
```

Then update `framework/mcp/INDEX.md` and `framework/knowledge/mcp-index.md`.
Full credential guidance is in `framework/mcp/INDEX.md`.

---

## Naming conventions

- Skill directories: `kebab-case`
- Knowledge topic files: `kebab-case.md`
- Memory files: `identity.md`, `preferences.md`, `rules.md` (fixed names)
- Decisions log entries: date + short title
