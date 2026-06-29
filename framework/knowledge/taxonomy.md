# Workspace Taxonomy & Guidelines — Quick Reference

Single-file summary. Load this when asked about structure, guidelines, or how this workspace is organized.
Full detail: `framework/knowledge/setup-guide.md` | Decisions behind it: `framework/knowledge/decisions-log.md`

---

## Directory map

```
AgentOS/
│
├── CLAUDE.md              ← Claude Code auto-loaded; first-time setup + session startup
├── AGENTS.md              ← all-agent onboarding; read first regardless of tool
├── README.md              ← human entry point
├── setup.sh               ← installs deps (Homebrew/nvm/pip/npm), git hooks, validates framework
├── .nvmrc                 ← pinned Node major version; nvm install reads this
├── .gitignore             ← personal/ excluded here; managed as separate private repo
│
├── framework/             ← SHAREABLE — safe to make public; no personal data
│   ├── requirements.txt   ← Python deps (markitdown, python-pptx); pip3 install -r
│   ├── package.json       ← Node deps (pptxgenjs, react, sharp); npm install --prefix framework
│   │
│   ├── instructions/      ← PROTECTED — [CONFIRM MEMORY UPDATE] required
│   │   ├── global.md      ← rules for ALL agents, always load
│   │   ├── claude-code.md ← Claude Code-specific conventions
│   │   ├── cursor.md      ← Cursor-specific (stub until Cursor is active)
│   │   ├── claude-chat.md ← Claude.ai chat conventions
│   │   └── mcp-agents.md  ← MCP agent conventions
│   │
│   ├── skills/            ← CLAUDE WRITES — no confirmation needed
│   │   ├── registry.json  ← NPM-style manifest: name, source, version, triggers
│   │   ├── install.sh     ← install from git-URL, local path, or future @registry
│   │   ├── INDEX.md       ← fast lookup
│   │   ├── pptx/          ← SKILL.md + editing.md, design.md, pptxgenjs.md, qa.md
│   │   └── splunk-spl/    ← SKILL.md + optimization.md, visualizations.md, query-building.md
│   │
│   ├── knowledge/         ← CLAUDE WRITES — structural docs only; no personal data
│   │   ├── INDEX.md       ← human-facing navigation map
│   │   ├── taxonomy.md    ← this file
│   │   ├── setup-guide.md ← full rebuild guide
│   │   ├── skill-authoring.md ← how to write SKILL.md files
│   │   ├── mcp-index.md       ← MCP servers and utilities
│   │   ├── decisions-log.md   ← append-only; major architectural decisions
│   │   └── changelog.md       ← append-only; structural workspace changes
│   │
│   ├── mcp/               ← CLAUDE WRITES — no confirmation needed
│   │   ├── INDEX.md        ← operational: start/stop reference
│   │   ├── servers/        ← local MCP server implementations
│   │   ├── utilities/      ← standalone scripts
│   │   └── bundles/        ← skill + server packaged together
│   │
│   ├── agent/             ← CLAUDE WRITES — shared agent utilities
│   │   └── scripts/       ← build-index.sh, route.sh, find-content.sh, find-skill.sh, inventory.sh, review-knowledge.sh, validate-indexes.sh
│   │
│   └── scaffold/          ← first-time setup templates; cp -r framework/scaffold/. personal/
│       ├── agent/         ← startup.md, framework-routes.json
│       ├── memory/core/   ← identity, preferences, rules templates
│       └── knowledge/     ← topics + resources drop zone
│
└── personal/              ← PRIVATE — gitignored here; own private git repo
    │
    ├── agent/             ← CLAUDE WRITES FREELY — no confirmation needed
    │   ├── startup.md             ← routing guide and session startup sequence
    │   ├── framework-routes.json  ← static routing for framework/memory/resource files
    │   ├── topics-index.json      ← generated: all active topics (run build-index.sh)
    │   ├── routing-manifest.json  ← generated: all routes (topics + skills + framework)
    │   └── scratch/               ← gitignored temp space
    │
    ├── memory/            ← PROTECTED — [CONFIRM MEMORY UPDATE] required
    │   ├── core/          ← always loaded: identity.md, preferences.md, rules.md
    │   ├── projects/      ← one dir per active project
    │   └── archive/       ← closed projects, not auto-loaded
    │
    └── knowledge/         ← CLAUDE WRITES — personal derived knowledge
        ├── INDEX.md       ← personal knowledge navigation
        ├── memory-index.md← what memory exists and when to load it
        ├── resources.md   ← saved external links; Claude fetches and processes on refresh
        ├── topics/        ← active conversation-derived knowledge (timestamped)
        └── archive/       ← archived topics; not routed, kept for historical reference
```

---

## Write permission model

| Who owns it | Directory | Confirmation required |
|---|---|---|
| User | `personal/memory/` | Yes — `[CONFIRM MEMORY UPDATE]` in commit message |
| User | `framework/instructions/` | Yes — `[CONFIRM MEMORY UPDATE]` in commit message |
| Claude | `personal/agent/` | No |
| Claude | `framework/agent/` | No |
| Claude | `framework/knowledge/` | No |
| Claude | `framework/skills/` | No |
| Claude | `framework/mcp/` | No |
| Claude | `personal/knowledge/` | No |

The `commit-msg` hook enforces this. Protected commits are rejected without the token.

---

## Skills vs instructions — the key distinction

| | `framework/instructions/` | `framework/skills/` |
|---|---|---|
| Load timing | Always, session start | On demand, task-triggered only |
| Size | Small | Can be large |
| Owner | User (protected) | Claude (writable) |
| Purpose | How to behave | How to do a specific task |

Never pre-load skills. Use `bash framework/agent/scripts/route.sh "QUERY"` to find the right one.

---

## Agent entry-point pattern

Each agent gets a thin, native config file that auto-loads. The file does NOT contain rules — it points to `framework/instructions/`.

| Agent | Native entry point | Points to |
|---|---|---|
| Claude Code | `CLAUDE.md` | `personal/agent/startup.md` → `framework/instructions/claude-code.md` |
| Cursor | `.cursorrules` | `framework/instructions/global.md` → `framework/instructions/cursor.md` |
| Claude.ai chat | Manual attachment | `framework/instructions/global.md` → `framework/instructions/claude-chat.md` |
| Any new agent | Whatever it reads | `AGENTS.md` → `framework/instructions/global.md` |

---

## Skill installation

```bash
framework/skills/install.sh <git-url>              # from git
framework/skills/install.sh <local/path>           # from local
```

All installs write to `framework/skills/registry.json`. After install: run `bash framework/agent/scripts/build-index.sh`.

---

## Knowledge lifecycle

Every `personal/knowledge/topics/` file carries: `> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD`
Review script: `bash framework/agent/scripts/review-knowledge.sh`
Stale threshold: 60 days | Archive threshold: 90 days
