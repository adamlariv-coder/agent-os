# MCP Index

Operational reference: `framework/mcp/INDEX.md`

---

## Credential security

Never paste API tokens or secrets into a chat. Credentials live in a shell env file (`~/.zshenv` recommended, `~/.zshrc` if you only launch Claude Code from a terminal). The user edits these files themselves via `open <file>` — Claude never sees the values. Full guidance and the GUI-launcher caveat: `framework/mcp/INDEX.md`.

---

## Overview

MCP servers extend Claude Code with live tool access (APIs, databases, internal systems).
They run as local subprocesses started on demand — no manual startup required.

Setup: `bash framework/agent/scripts/mcp-setup.sh`

The script clones any MCP server collection by git URL into `framework/mcp/servers/`
(gitignored), reads the repo's catalog, and lets you select and install servers either
interactively or via CLI flags (`--list`, `--install <name> -y`). The script never collects
credential values — only registers the command in `~/.claude.json`.

---

## Server types

| Type | How it runs | Setup |
|------|------------|-------|
| Local/stdio | `node dist/index.js` or `python3 main.py` | Build from source, register command |
| Docker | `docker run` | Build image manually, add docker entry |
| Remote/SSE | HTTPS endpoint | Add `sseUrl` entry directly to `~/.claude.json` |

---

## Known server collections

| Name | Git URL (SSH) | Catalog |
|------|--------------|---------|


---

## Installed servers

Check `~/.claude.json` → `mcpServers` for what's currently active.
