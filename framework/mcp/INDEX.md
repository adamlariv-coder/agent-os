# MCP Index — Operational Reference

MCP servers extend Claude Code with live tool access. Claude Code starts them on demand —
no manual startup needed. They are registered in `~/.claude.json` (global, all sessions).

---

## Credential security — read this first

**Never paste API tokens or secrets into a chat with an AI assistant.** When you type a credential into a conversation it enters the model's context window, gets written to conversation logs, and may be retained in memory summaries. Even if the assistant never commits it to disk, you have no visibility into where that string travels.

**Always edit secret-bearing files yourself, in your own editor.** Claude will open the file for you via `open <file>` — type the values there, save, close. Claude never sees the value.

### The launcher problem you need to know about

Claude Code, when launched from the Dock or Spotlight on macOS, inherits its environment from `launchd` — **not** from your shell. So secrets you put in `~/.zshrc` will not reach MCP servers spawned by that Claude Code process. `~/.zshrc` is sourced by *interactive* shells only.

You have three places to put MCP credentials. Pick one that matches how you launch Claude Code:

| # | Location | Reaches MCP children when Claude is launched from… | Trade-off |
|---|---|---|---|
| 1 | **`~/.zshenv`** + zsh-wrapped MCP command in `~/.claude.json` | Anywhere (Dock, Spotlight, terminal) — most robust | One small command-wrapper edit per MCP entry |
| 2 | **`~/.zshrc`** + Claude launched from a zsh terminal | Terminal only | Easy to forget; GUI launches silently break |
| 3 | **`env` block inside `~/.claude.json`** | Anywhere | Secrets live in plain text on disk — discouraged unless no alternative |

### Option 1 — `~/.zshenv` + zsh-wrapped command (recommended)

`~/.zshenv` is sourced by *every* zsh invocation — interactive, non-interactive, login, subshell, all of them. Combined with wrapping the MCP command in `zsh -c '…'`, this works no matter how Claude Code was launched.

1. **Edit `~/.zshenv` yourself** (Claude runs `open ~/.zshenv` for you):
   ```bash
   export WIKI_MCP_TOKEN="..."
   export JIRA_EMAIL="you@example.com"
   export JIRA_PERSONAL_ACCESS_TOKEN="..."
   ```
2. **Register MCP servers with a zsh wrapper** in `~/.claude.json`:
   ```json
   "wiki": {
     "command": "zsh",
     "args": ["-c", "exec node /absolute/path/to/dist/index.js"]
   }
   ```
   `zsh -c` triggers `~/.zshenv` to load → secrets land in env → `exec` replaces zsh with `node`, which inherits the env. ~50ms overhead per server start, negligible.

### Option 2 — `~/.zshrc` + terminal launch

If you reliably launch Claude Code by running `claude` from a zsh terminal, plain shell exports work and no wrapper is needed:

```json
"wiki": {
  "command": "node",
  "args": ["/absolute/path/to/dist/index.js"]
}
```

But if you ever launch Claude Code from the Dock or Spotlight, this silently fails (no tools appear, no error message).

### Option 3 — `env` block in `~/.claude.json` (discouraged)

```json
"wiki": {
  "command": "node",
  "args": ["..."],
  "env": { "WIKI_MCP_TOKEN": "..." }
}
```

This works regardless of launcher, but the value sits in plain text in a file that gets backed up, synced, and screenshotted. Avoid unless Options 1 and 2 are both unavailable.

### Diagnosing "MCP tools didn't load"

```bash
# What does Claude Code's process actually see?
ps -p $PPID -o command=          # is it claude.app (GUI) or claude (terminal)?
echo "${WIKI_MCP_TOKEN:+set}"    # 'set' or empty
```

If the parent is `claude.app/Contents/MacOS/claude`, Claude Code was launched as a GUI app — Options 2 won't work; use Option 1 or 3.

`framework/agent/scripts/mcp-setup.sh` follows the file-edit pattern: it prints the variable names you need to set, then registers the server without touching credentials. Use `--list` and `--install <name>` to drive it non-interactively.

### Diagnosing "unable to get local issuer certificate"

When an MCP call against an **internal corporate endpoint** (e.g., `wiki`, `jira`) fails with:

```
Error: unable to get local issuer certificate
```

…this almost always means the **VPN is disconnected**, not a real cert problem. The corporate TLS chain is only reachable through the VPN; without it, the system trust store can't validate the leaf cert and the request dies at handshake.

What to do:
- **Do not retry.** The error will persist for every internal endpoint until VPN is back. Looping on the same tool just burns time and tokens.
- **Surface it to the user immediately** with a clear line like: *"wiki / jira just returned a cert error — that's usually the VPN being down. Reconnect and I'll retry."*
- Once they confirm reconnection, retry the original call as-is. No tool config changes needed.

This signal is **specific to corp-internal MCPs**. Public endpoints (GitHub, Slack, public wikis) won't fail this way from a VPN drop — if you see the same error there, treat it as a real cert problem.

---

## Setup

Interactive:

```bash
bash framework/agent/scripts/mcp-setup.sh
```

Non-interactive (CLI-driven — useful when an agent is driving it):

```bash
bash framework/agent/scripts/mcp-setup.sh --list                       # list all catalog servers
bash framework/agent/scripts/mcp-setup.sh --list --filter wiki         # filter
bash framework/agent/scripts/mcp-setup.sh --install wiki -y      # install one
bash framework/agent/scripts/mcp-setup.sh --install wiki jira -y
```

What the script does:
1. Detects (or clones, on first run) an MCP server collection in `framework/mcp/servers/`
2. Reads the catalog (`docs/mcp-server-list.json`) for env-var metadata
3. Builds each selected server from source (Node `npm install && npm run build`, or Python `requirements.txt`)
4. Prints required env-var names (never collects values — you set them in `~/.zshenv` yourself)
5. Registers an entry in `~/.claude.json`

The script never reads, displays, or stores credential values. Pair it with the Option 1 pattern above.

---

## Server collections

Cloned server repos live in `framework/mcp/servers/` and are gitignored.
Each user clones their own — the framework tracks only the tooling, not the servers.

To see what's installed: check `~/.claude.json` → `mcpServers`.

---

## Adding a server collection

Any git repo that contains either:
- `docs/mcp-server-list.json` — structured catalog with env var metadata (preferred)
- `src/` directory — scanned as fallback

Pass the git URL when prompted by `mcp-setup.sh`.
