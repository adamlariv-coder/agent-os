#!/bin/bash
# AgentOS Workspace Setup
# Installs prerequisites, Python/Node packages, git hooks, and validates the framework.
# Run after cloning. Personal workspace setup happens inside Claude Code.
# Usage: ./setup.sh [--dry-run]

REPO_ROOT="$(git rev-parse --show-toplevel)"
DRY_RUN=false

# Bash scripts target Linux. On Windows, use WSL — not PowerShell, CMD, or Git Bash/MSYS.
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*)
    echo ""
    echo "ERROR: Run setup from WSL (Ubuntu), not Git Bash/MSYS."
    echo ""
    echo "  wsl -e bash -lc \"cd \\\"$(wslpath -u "$REPO_ROOT" 2>/dev/null || echo "/mnt/c${REPO_ROOT//\\/\/}" | sed 's|^[Cc]:|/mnt/c|')\\\" && ./setup.sh\""
    echo ""
    exit 1
    ;;
esac

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
  esac
done

log()  { echo "  $1"; }
ok()   { echo "  OK: $1"; }
warn() { echo "  MISSING: $1"; }
run() {
  if $DRY_RUN; then
    echo "  [DRY RUN] $*"
  else
    eval "$@"
  fi
}

echo ""
echo "=== AgentOS Workspace Setup ==="
$DRY_RUN && echo "    (dry run — no changes will be made)"
echo ""

# ── 1. Homebrew ──────────────────────────────────────────────────────────────

HAS_BREW=false
MANUAL=false   # true when user declines Homebrew; shows manual steps instead

if command -v brew &>/dev/null; then
  HAS_BREW=true
else
  # Check whether any deps are actually missing before prompting
  NEED_BREW=false
  command -v python3 &>/dev/null || NEED_BREW=true
  (export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm --version &>/dev/null 2>&1) || NEED_BREW=true

  if $NEED_BREW && ! $DRY_RUN; then
    echo "Homebrew"
    echo ""
    echo "  One or more dependencies are missing. Homebrew is the recommended"
    echo "  way to install them automatically on macOS."
    echo ""
    read -r -p "  Install Homebrew? [Y/n] " _brew_resp
    _brew_resp="${_brew_resp:-Y}"
    echo ""
    if [[ "$_brew_resp" =~ ^[Yy] ]]; then
      echo "  Homebrew requires an interactive install. Run this, then re-run setup.sh:"
      echo ""
      echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      echo ""
      echo "  After installing Homebrew: ./setup.sh"
      echo ""
      exit 0
    else
      log "Skipping Homebrew — manual installation steps will be shown."
      MANUAL=true
    fi
    echo ""
  fi
fi

# ── 2. Python ────────────────────────────────────────────────────────────────

echo "Python..."
if command -v python3 &>/dev/null; then
  ok "python3  $(python3 --version)"
elif $HAS_BREW; then
  log "Installing python3 via Homebrew..."
  run "brew install python3"
  ok "python3 installed"
else
  warn "python3 not found"
  echo ""
  echo "  Manual install options:"
  echo "    Homebrew:  brew install python3"
  echo "    Direct:    https://www.python.org/downloads/"
  echo ""
fi
echo ""

# ── 3. nvm + Node ────────────────────────────────────────────────────────────

echo "Node (via nvm)..."

# Source nvm — works for both Homebrew and curl installs
source_nvm() {
  export NVM_DIR="$HOME/.nvm"
  local brew_nvm
  brew_nvm="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  if [ -s "$brew_nvm" ]; then
    . "$brew_nvm"
  elif [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  fi
}
source_nvm

if nvm --version &>/dev/null 2>&1; then
  ok "nvm  $(nvm --version)"
elif $HAS_BREW; then
  log "Installing nvm via Homebrew..."
  run "brew install nvm"
  source_nvm

  # Add nvm to shell profile if not already there
  if ! $DRY_RUN; then
    PROFILE="$HOME/.zshrc"
    [ "$SHELL" = "/bin/bash" ] && PROFILE="$HOME/.bash_profile"
    if ! grep -q "nvm.sh" "$PROFILE" 2>/dev/null; then
      {
        echo ""
        echo "# nvm — added by AgentOS setup"
        echo 'export NVM_DIR="$HOME/.nvm"'
        echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"'
      } >> "$PROFILE"
      log "nvm sourcing added to $PROFILE"
    fi
  fi
  ok "nvm  $(nvm --version 2>/dev/null || echo 'installed')"
else
  warn "nvm not found"
  echo ""
  echo "  Manual install options:"
  echo "    Homebrew:  brew install nvm"
  NVM_VER="0.40.0"
  echo "    curl:      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VER}/install.sh | bash"
  echo "               Then restart your terminal and re-run: ./setup.sh"
  echo ""
fi

# Install and activate the pinned Node version (reads .nvmrc)
if nvm --version &>/dev/null 2>&1; then
  run "nvm install"
  run "nvm use"
  ok "node  $(node --version 2>/dev/null || echo '(restart shell to activate)')"
elif command -v node &>/dev/null; then
  ok "node  $(node --version)  (not via nvm — version pinning inactive)"
else
  warn "node not found — install nvm first, then run: nvm install"
fi
echo ""

# ── 4. Python packages ───────────────────────────────────────────────────────

echo "Python packages..."
VENV="$REPO_ROOT/.venv"
install_python_deps() {
  local pip_cmd="$1"
  if $DRY_RUN; then
    echo "  [DRY RUN] $pip_cmd install -r framework/requirements.txt"
    return 0
  fi
  if ! $pip_cmd install -r "$REPO_ROOT/framework/requirements.txt" --quiet; then
    warn "pip install failed ($pip_cmd)"
    return 1
  fi
  ok "framework/requirements.txt installed ($pip_cmd)"
  return 0
}

if [ -x "$VENV/bin/pip" ]; then
  install_python_deps "$VENV/bin/pip"
elif command -v pip3 &>/dev/null; then
  install_python_deps pip3
elif [ -x "$HOME/.local/bin/pip3" ]; then
  install_python_deps "$HOME/.local/bin/pip3"
elif python3 -m pip --version &>/dev/null 2>&1; then
  install_python_deps "python3 -m pip"
elif command -v python3 &>/dev/null; then
  log "Bootstrapping pip into $VENV (Debian/Ubuntu often ships without pip3)..."
  if [ ! -x "$VENV/bin/python3" ]; then
    run "python3 -m venv '$VENV' --without-pip"
    run "curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py"
    run "'$VENV/bin/python3' /tmp/get-pip.py"
  fi
  if [ -x "$VENV/bin/pip" ]; then
    install_python_deps "$VENV/bin/pip"
    log "Python tools: source '$VENV/bin/activate' or use '$VENV/bin/python3'"
  else
    warn "could not bootstrap pip — try: sudo apt install python3-pip python3-venv"
  fi
else
  warn "python3 not found"
  log "Run manually: pip3 install -r framework/requirements.txt"
fi
echo ""

# ── 5. Node packages ─────────────────────────────────────────────────────────

if command -v npm &>/dev/null; then
  echo "Node packages..."
  run "npm install --prefix '$REPO_ROOT/framework' --silent"
  ok "framework/package.json installed"
  echo ""
fi

# ── 6. Git hooks ─────────────────────────────────────────────────────────────

echo "Git hooks..."
for hook in pre-commit commit-msg post-commit; do
  if [ -f "$REPO_ROOT/.workspace/hooks/$hook" ]; then
    run "cp '$REPO_ROOT/.workspace/hooks/$hook' '$REPO_ROOT/.git/hooks/$hook'"
    run "chmod +x '$REPO_ROOT/.git/hooks/$hook'"
    ok "$hook"
  fi
done

# Personal-context check is invoked by the pre-commit hook.
# Make sure the scanner script is executable.
if [ -f "$REPO_ROOT/framework/agent/scripts/check-context.sh" ]; then
  run "chmod +x '$REPO_ROOT/framework/agent/scripts/check-context.sh'"
fi

# Seed personal/.agentignore from the template if (a) personal/ exists,
# (b) the template exists, and (c) the user hasn't created their own yet.
TEMPLATE="$REPO_ROOT/framework/agent/scripts/agentignore.template"
TARGET="$REPO_ROOT/personal/.agentignore"
if [ -d "$REPO_ROOT/personal" ] && [ -f "$TEMPLATE" ] && [ ! -f "$TARGET" ]; then
  run "cp '$TEMPLATE' '$TARGET'"
  log "seeded personal/.agentignore from template — edit to add your names/customers"
fi
echo ""

# ── 6b. Claude Code hooks (SessionStart + UserPromptSubmit) ──────────────────
# .claude/ is gitignored, so the hook *wiring* is provisioned locally from a
# committed template. The hook *scripts* live in framework/agent/scripts/.
echo "Claude Code hooks..."
HOOK_TMPL="$REPO_ROOT/framework/agent/scripts/hooks.settings.template.json"
HOOK_DEST="$REPO_ROOT/.claude/settings.json"
for s in session-start.sh prompt-route.sh; do
  [ -f "$REPO_ROOT/framework/agent/scripts/$s" ] && run "chmod +x '$REPO_ROOT/framework/agent/scripts/$s'"
done
if [ -f "$HOOK_TMPL" ]; then
  run "mkdir -p '$REPO_ROOT/.claude'"
  if [ ! -f "$HOOK_DEST" ]; then
    run "cp '$HOOK_TMPL' '$HOOK_DEST'"
    ok "wrote .claude/settings.json (model + hooks)"
  elif ! $DRY_RUN; then
    # Merge template's model + hooks into an existing settings.json without clobbering other keys.
    python3 - "$HOOK_DEST" "$HOOK_TMPL" <<'PYEOF'
import json, sys
dest, tmpl = sys.argv[1], sys.argv[2]
with open(dest) as f: d = json.load(f)
with open(tmpl) as f: t = json.load(f)
d.setdefault("model", t["model"])
d.setdefault("hooks", {}).update(t["hooks"])
with open(dest, "w") as f: json.dump(d, f, indent=2)
PYEOF
    ok ".claude/settings.json merged (hooks ensured)"
  fi
fi
echo ""

# ── 7. Submodules ────────────────────────────────────────────────────────────

if [ -f "$REPO_ROOT/.gitmodules" ]; then
  echo "Submodules..."
  run "git submodule update --init --recursive"
  echo ""
fi

# ── 8. Validate ──────────────────────────────────────────────────────────────

echo "Validating framework..."
bash "$REPO_ROOT/.workspace/scripts/validate.sh" || true
echo ""

echo "=== Setup complete ==="
echo ""
echo "Next step: open Claude Code in this directory"
echo ""
echo "  claude"
echo ""
echo "Claude will walk you through creating your personal/ workspace."
echo ""
