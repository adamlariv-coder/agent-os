# AgentOS — Agent Workspace

A personal AI workspace. Structured so any compliant agent (Claude Code, Cursor, MCP-connected tools) can orient itself within seconds, load only what it needs, and contribute back without breaking anything.

## Two-layer design

| Layer | Directory | Visibility | Purpose |
|-------|-----------|------------|---------|
| Framework | `framework/` | Public / shareable | Skills, instructions, structural knowledge |
| Personal | `personal/` | Private git repo | Memory, derived knowledge, agent routing |

`personal/` lives inside this directory but is excluded from this repo's git history — managed as its own private repository.

---

## Quickstart

**Open Claude Code with this repo, and say hello. The framework handles the rest.**

```bash
git clone <this-repo-url> AgentOS && cd AgentOS && claude
```

Then type `hello`. Claude reads `CLAUDE.md`, runs `./setup.sh` for you if it hasn't been run, walks you through creating your `personal/` workspace, and is ready to go.

**You only need**: `git` and the [Claude Code CLI](https://docs.anthropic.com/claude-code) installed locally. Everything else — Python, Node via `nvm`, git hooks, indexes, personal scaffolding, MCP server setup — is initiated by Claude on first session.

---

## What Claude sets up (first session)

1. Creates `personal/` — either as a private git repo or uncommitted (your choice)
2. Copies templates from `framework/scaffold/` — routing, scripts, memory files
3. Builds search indexes (`topics-index.json`, `routing-manifest.json`)
4. Runs an identity interview — saves context used in every future session
5. Optionally commits and prompts you to add a remote

After setup, your `personal/` is ready to track knowledge, memory, and routing across sessions.

---

## Framework structure

| Directory | Purpose | Protected? |
|-----------|---------|------------|
| `framework/instructions/` | Agent behavior rules per tool | Yes |
| `framework/skills/` | Capability packages — what agents know how to do | No |
| `framework/knowledge/` | Navigation indexes and workspace documentation | No |
| `framework/mcp/` | Local MCP servers and utility scripts | No |
| `framework/scaffold/` | Templates copied to `personal/` during first-time setup | No |

## Personal structure (private repo)

| Directory | Purpose | Protected? |
|-----------|---------|------------|
| `personal/agent/` | Routing table, search indexes, scripts | No |
| `personal/memory/` | Long-term context about you and active projects | Yes |
| `personal/knowledge/` | Derived knowledge from conversations and resources | No |
