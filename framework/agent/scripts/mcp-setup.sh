#!/bin/bash
# MCP Server Setup
# Interactively or via CLI flags: clones an MCP server collection, builds
# selected servers, and registers them in ~/.claude.json for global Claude
# Code access.
#
# Interactive usage:
#   bash framework/agent/scripts/mcp-setup.sh
#
# CLI usage:
#   bash framework/agent/scripts/mcp-setup.sh --list
#   bash framework/agent/scripts/mcp-setup.sh --list --filter wiki
#   bash framework/agent/scripts/mcp-setup.sh --install wiki jira --yes
#   bash framework/agent/scripts/mcp-setup.sh --install wiki --name wiki --yes
#   bash framework/agent/scripts/mcp-setup.sh --collection mcp-servers --install wiki --yes
#
# Flags:
#   --list                 Print catalog (name + lifecycle + description) and exit.
#   --filter <term>        Filter catalog by keyword (matches name, description, tags).
#   --install <name>...    Install one or more servers by exact catalog name or src dir name.
#   --collection <name>    Pick a collection when multiple exist under framework/mcp/servers/.
#   --name <key>           Override registration key (only with a single --install target).
#   --yes, -y              Non-interactive: skip "press enter" credential gates.
#   --help, -h             Show this help and exit.

REPO_ROOT="$(git worktree list --porcelain | awk '/^worktree/{sub(/^worktree /,""); print; exit}')"
SERVERS_DIR="$REPO_ROOT/framework/mcp/servers"
CLAUDE_JSON="$HOME/.claude.json"

exec python3 - "$REPO_ROOT" "$SERVERS_DIR" "$CLAUDE_JSON" "$@" << 'PYEOF'
import sys, os, json, subprocess, shutil, re, argparse
from pathlib import Path

repo_root    = sys.argv[1]
servers_dir  = sys.argv[2]
claude_json  = sys.argv[3]
cli_args     = sys.argv[4:]

# ── CLI parsing ───────────────────────────────────────────────────────────────

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("--list", action="store_true", dest="list_only")
parser.add_argument("--filter", dest="filter_term", default=None)
parser.add_argument("--install", nargs="+", dest="install_names", default=None)
parser.add_argument("--collection", dest="collection_name", default=None)
parser.add_argument("--name", dest="override_key", default=None)
parser.add_argument("--yes", "-y", action="store_true", dest="assume_yes")
parser.add_argument("--help", "-h", action="store_true", dest="show_help")

try:
    args = parser.parse_args(cli_args)
except SystemExit:
    args = parser.parse_args([])  # fall back to defaults on parse failure

if args.show_help:
    print(__doc__ if __doc__ else "")
    print("Run with no args for interactive mode, or use --list / --install / --filter.")
    sys.exit(0)

if args.override_key and (not args.install_names or len(args.install_names) != 1):
    print("ERROR: --name only valid with exactly one --install target.")
    sys.exit(1)

CLI_MODE = args.list_only or bool(args.install_names)

# ── Helpers ───────────────────────────────────────────────────────────────────

def ask(prompt, default=None):
    if CLI_MODE:
        return default or ""
    hint = f" [{default}]" if default else ""
    val = input(f"  {prompt}{hint}: ").strip()
    return val or default or ""

def confirm(prompt, default=True):
    if CLI_MODE or args.assume_yes:
        return default
    hint = "Y/n" if default else "y/N"
    val = input(f"  {prompt} [{hint}] ").strip().lower()
    if not val:
        return default
    return val.startswith("y")

def pause(prompt):
    if CLI_MODE or args.assume_yes:
        return
    input(prompt)

def run(cmd, cwd=None, silent=False):
    kwargs = dict(cwd=cwd)
    if silent:
        kwargs["stdout"] = subprocess.DEVNULL
        kwargs["stderr"] = subprocess.DEVNULL
    subprocess.run(cmd, shell=True, check=True, **kwargs)

def load_claude_json():
    if os.path.exists(claude_json):
        with open(claude_json, encoding="utf-8") as f:
            return json.load(f)
    return {}

def save_claude_json(config):
    with open(claude_json, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)

def server_src_name(server):
    """Derive the src dir name for a catalog entry."""
    url = server.get("url", "")
    if "tree/main/" in url:
        return url.split("tree/main/")[-1].split("/")[-1]
    return server.get("name", "").lower().replace(" ", "-")

# ── 1. Find or clone a server collection ─────────────────────────────────────

if not CLI_MODE:
    print()
    print("=== MCP Server Setup ===")
    print()

collections = [d for d in Path(servers_dir).iterdir() if d.is_dir() and d.name != ".gitkeep"]

if not collections:
    if CLI_MODE:
        print("ERROR: no MCP server collections found in framework/mcp/servers/.")
        print("Run interactively first to clone one: bash framework/agent/scripts/mcp-setup.sh")
        sys.exit(1)
    print("  No MCP server collections found in framework/mcp/servers/")
    print()
    if not confirm("Clone an MCP server collection now?"):
        print("  Nothing to do — exiting.")
        sys.exit(0)
    print()
    git_url = ask("Git URL of the collection repo")
    if not git_url:
        print("  No URL provided — exiting.")
        sys.exit(1)
    repo_name = re.sub(r"\.git$", "", git_url.rstrip("/").split("/")[-1])
    dest = Path(servers_dir) / repo_name
    print(f"  Cloning {repo_name} into framework/mcp/servers/{repo_name} ...")
    try:
        run(f"git clone {git_url} {dest}")
    except subprocess.CalledProcessError:
        print(f"  ERROR: clone failed. Check the URL and your git auth.")
        sys.exit(1)
    print(f"  ✓ Cloned")
    collections = [dest]

if args.collection_name:
    matches = [c for c in collections if c.name == args.collection_name]
    if not matches:
        print(f"ERROR: collection '{args.collection_name}' not found. Available: {[c.name for c in collections]}")
        sys.exit(1)
    collection = matches[0]
elif len(collections) == 1:
    collection = collections[0]
    if not CLI_MODE:
        print(f"  Using collection: {collection.name}")
else:
    if CLI_MODE:
        print(f"ERROR: multiple collections found, pass --collection. Available: {[c.name for c in collections]}")
        sys.exit(1)
    print("  Available collections:")
    for i, c in enumerate(collections, 1):
        print(f"    {i}) {c.name}")
    choice = ask("Which collection to use", "1")
    collection = collections[int(choice) - 1]

# ── 2. Load server catalog ────────────────────────────────────────────────────

catalog_path = None
for candidate in ["docs/mcp-server-list.json", "mcp-server-list.json", "servers.json"]:
    p = collection / candidate
    if p.exists():
        catalog_path = p
        break

catalog_servers = []
if catalog_path:
    with open(catalog_path) as f:
        catalog_servers = json.load(f)
    if not CLI_MODE:
        print(f"  Loaded {len(catalog_servers)} servers from catalog")
else:
    src_dir = collection / "src"
    if src_dir.exists():
        for d in sorted(src_dir.iterdir()):
            if d.is_dir():
                catalog_servers.append({
                    "name": d.name,
                    "description": "(no catalog — read README.md for details)",
                    "url": f"src/{d.name}",
                    "mode": "Local",
                    "lifecycle": "unknown",
                    "env": {}
                })
        if not CLI_MODE:
            print(f"  No catalog found — found {len(catalog_servers)} servers in src/")

local_servers = [s for s in catalog_servers if s.get("mode") == "Local"]
remote_servers = [s for s in catalog_servers if s.get("mode") == "Remote"]
if remote_servers and not CLI_MODE:
    print(f"  Note: {len(remote_servers)} Remote/SSE servers are not shown (use their SSE URL directly)")

# ── 3a. CLI list mode ─────────────────────────────────────────────────────────

def apply_filter(servers, term):
    if not term:
        return servers
    term = term.lower()
    return [s for s in servers
            if term in s["name"].lower()
            or term in s.get("description", "").lower()
            or term in server_src_name(s).lower()
            or any(term in t.lower() for t in s.get("tags", []))]

if args.list_only:
    filtered = apply_filter(local_servers, args.filter_term)
    for s in filtered:
        lc = s.get("lifecycle", "?")
        src = server_src_name(s)
        env_keys = list(s.get("env", {}).keys())
        env_str = f"  env: {','.join(env_keys)}" if env_keys else ""
        print(f"  {s['name']:<40}  [{lc:<12}]  src={src}{env_str}")
        print(f"    {s.get('description','')[:100]}")
    print()
    print(f"  {len(filtered)} server(s) shown.")
    sys.exit(0)

# ── 3b. Select servers ────────────────────────────────────────────────────────

if args.install_names:
    # Match by catalog name (exact, case-insensitive) OR src dir name
    selected = []
    for want in args.install_names:
        want_lower = want.lower()
        hits = [s for s in local_servers
                if s["name"].lower() == want_lower
                or server_src_name(s).lower() == want_lower]
        if not hits:
            print(f"ERROR: no server matching '{want}'. Use --list to see catalog.")
            sys.exit(1)
        if len(hits) > 1:
            print(f"ERROR: multiple servers match '{want}': {[h['name'] for h in hits]}")
            sys.exit(1)
        selected.append(hits[0])
else:
    # Interactive selection
    print()
    print(f"  {len(local_servers)} local servers available.")
    filter_term = args.filter_term or input("  Filter by keyword (or press Enter to show all): ").strip().lower()
    filtered = apply_filter(local_servers, filter_term)

    if not filtered:
        print(f"  No servers match '{filter_term}'")
        sys.exit(0)

    PAGE = 20
    page = 0
    selected = None
    while True:
        start = page * PAGE
        chunk = filtered[start:start+PAGE]
        print()
        for i, s in enumerate(chunk, start + 1):
            lc = s.get("lifecycle", "?")
            print(f"  {i:>3})  {s['name']:<40}  [{lc}]")
            print(f"         {s.get('description','')[:80]}")
        total_pages = (len(filtered) + PAGE - 1) // PAGE
        print(f"\n  Page {page+1}/{total_pages}  ({len(filtered)} servers total)")

        if page + 1 < total_pages:
            nav = input("  Enter numbers to install, 'n' for next page, or 'q' to quit: ").strip()
        else:
            nav = input("  Enter numbers to install (e.g. 1 3 5) or 'q' to quit: ").strip()

        if nav.lower() == "q":
            sys.exit(0)
        if nav.lower() == "n" and page + 1 < total_pages:
            page += 1
            continue
        if not nav:
            page = 0
            continue

        try:
            selected_indices = [int(x) - 1 for x in nav.split()]
            picked = [filtered[i] for i in selected_indices if 0 <= i < len(filtered)]
            if picked:
                selected = picked
                break
            print("  No valid numbers entered.")
        except ValueError:
            print("  Enter space-separated numbers.")

# ── 4. Build + register selected servers ─────────────────────────────────────

print()
claude_config = load_claude_json()
claude_config.setdefault("mcpServers", {})
registered = []

for server in selected:
    name = server["name"]
    print(f"  {'─'*50}")
    print(f"  {name}")
    print(f"  {'─'*50}")

    url = server.get("url", "")
    src_rel = url.split("tree/main/")[-1] if "tree/main/" in url else f"src/{server_src_name(server)}"
    server_dir = collection / src_rel

    if not server_dir.exists():
        print(f"  SKIP: source directory not found: {server_dir}")
        continue

    pkg_json = server_dir / "package.json"
    req_txt  = server_dir / "requirements.txt"
    dockerfile = server_dir / "Dockerfile"

    entry_cmd = None

    if pkg_json.exists():
        try:
            with open(pkg_json) as f:
                pkg = json.load(f)
        except Exception:
            pkg = {}

        needs_build = "build" in pkg.get("scripts", {})
        dist_exists = any((server_dir / d / "index.js").exists() for d in ["dist", "build"])

        if not dist_exists:
            print(f"  Building {src_rel}...")
            if not (server_dir / "node_modules").exists():
                run("npm install --silent", cwd=server_dir, silent=True)
                print("    ✓ npm install")
            if needs_build:
                try:
                    run("npm run build", cwd=server_dir, silent=True)
                    print("    ✓ npm run build")
                except subprocess.CalledProcessError:
                    print("    ! build failed — trying to continue anyway")
        else:
            print("  ✓ Already built")

        for candidate in ["dist/index.js", "build/index.js", "index.js"]:
            entry = server_dir / candidate
            if entry.exists():
                entry_cmd = ["node", str(entry)]
                break
        if not entry_cmd and pkg.get("main"):
            main = server_dir / pkg["main"]
            if main.exists():
                entry_cmd = ["node", str(main)]

    elif req_txt.exists():
        entry_options = list(server_dir.glob("main.py")) + list(server_dir.glob("server.py")) + list(server_dir.glob("index.py"))
        if entry_options:
            entry_cmd = ["python3", str(entry_options[0])]

    elif dockerfile.exists():
        print(f"  NOTE: {name} is Docker-only. Build the image manually:")
        print(f"    cd {server_dir} && docker build -t mcp-{src_rel.split('/')[-1]} .")
        print(f"  Then add a 'docker run' entry to ~/.claude.json manually.")
        pause("  Press Enter to continue...")
        continue

    if not entry_cmd:
        print(f"  SKIP: could not determine how to run {name}")
        print(f"  Check the README: {server_dir}/README.md")
        continue

    env_vars_meta = server.get("env", {})
    required = {k: v for k, v in env_vars_meta.items() if not v.get("optional", False)}
    optional  = {k: v for k, v in env_vars_meta.items() if v.get("optional", False)}

    if env_vars_meta:
        print()
        print(f"  ⚠️  Credentials are NEVER collected here.")
        print(f"  Required env vars (add as exports in ~/.zshrc, then restart Claude Code):")
        for var, meta in required.items():
            desc = meta.get("description", "")
            hint = f"  # {desc}" if desc else ""
            print(f"    export {var}=\"your-value-here\"{hint}")
        if optional:
            print(f"  Optional:")
            for var, meta in optional.items():
                desc = meta.get("description", "")
                hint = f"  # {desc}" if desc else ""
                print(f"    export {var}=\"your-value-here\"{hint}")
        print()
        pause("  Press Enter to continue once you've noted the variable names...")

    src_name = src_rel.split("/")[-1]
    default_key = args.override_key if (args.override_key and len(selected) == 1) else src_name
    server_key = default_key if CLI_MODE else ask("Name for this server in Claude Code", default_key)

    entry = {
        "command": entry_cmd[0],
        "args": entry_cmd[1:]
    }

    claude_config["mcpServers"][server_key] = entry
    save_claude_json(claude_config)
    print(f"  ✓ Registered as '{server_key}' in {claude_json}")
    registered.append(server_key)
    print()

# ── 5. Summary ────────────────────────────────────────────────────────────────

print("══════════════════════════════════════════")
print()
if registered:
    print(f"  Registered {len(registered)} server(s):")
    for r in registered:
        print(f"    • {r}")
    print()
    print("  Restart Claude Code to activate.")
else:
    print("  No servers were registered.")
print()
PYEOF
