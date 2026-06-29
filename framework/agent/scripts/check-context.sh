#!/bin/bash
# check-context.sh — scan framework/ for personal-context leakage.
#
# Reads personal/.agentignore (gitignore-style syntax) and scans staged
# framework/ files (or, with --audit, the entire framework/ tree) for
# words/identifiers that must not appear.
#
# .agentignore syntax (gitignore-aligned):
#   - Bare entries (no ! prefix)        → PATH patterns; matched paths
#                                          are EXEMPT from scanning
#   - !word entries                     → WORD patterns; if found in a
#                                          non-exempt staged file, the
#                                          commit is BLOCKED
#   - # comments and blank lines        → ignored
#   - Inline override on a content line: `# context-allow:<reason>`
#                                          skips that line in the scan
#
# Usage:
#   check-context.sh           # scan staged framework/ files (pre-commit mode)
#   check-context.sh --audit   # scan the entire framework/ tree
#   check-context.sh --help    # this help

MAIN_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
IGNORE_FILE="$MAIN_ROOT/personal/.agentignore"
MODE="staged"
EXIT_CODE=0

# ── Arg parsing ──────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --audit) MODE="audit" ;;
    --help|-h)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ── Locate .agentignore ──────────────────────────────────────────────────────
if [ ! -f "$IGNORE_FILE" ]; then
  echo "  note: personal/.agentignore not found — skipping personal-context check"
  echo "        (copy framework/agent/scripts/agentignore.template to personal/.agentignore to enable)"
  exit 0
fi

# ── Parse .agentignore ───────────────────────────────────────────────────────
EXEMPT_PATHS=()
FLAG_WORDS=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line#"${line%%[![:space:]]*}"}"
  [ -z "$line" ] && continue
  [[ "$line" == \#* ]] && continue
  if [[ "$line" == !* ]]; then
    FLAG_WORDS+=("${line#!}")
  else
    EXEMPT_PATHS+=("$line")
  fi
done < "$IGNORE_FILE"

if [ ${#FLAG_WORDS[@]} -eq 0 ]; then
  exit 0
fi

# ── Build grep exclude args from EXEMPT_PATHS ────────────────────────────────
# Each bare entry becomes a grep --exclude or --exclude-dir argument.
GREP_EXCLUDES=()
for pattern in "${EXEMPT_PATHS[@]}"; do
  p="${pattern%/}"
  # If pattern ends in / or contains no glob/wildcard chars, treat as dir
  if [[ "$pattern" == */ ]] || [[ ! "$pattern" =~ [\*\?\[] ]]; then
    # Could be a directory or a filename; cover both
    GREP_EXCLUDES+=(--exclude-dir="$(basename "$p")")
    GREP_EXCLUDES+=(--exclude="$(basename "$p")")
  else
    GREP_EXCLUDES+=(--exclude="$p")
  fi
done
# Always-excluded
GREP_EXCLUDES+=(--exclude-dir=node_modules)
GREP_EXCLUDES+=(--exclude-dir=.git)
GREP_EXCLUDES+=(--exclude="*.png" --exclude="*.jpg" --exclude="*.jpeg")
GREP_EXCLUDES+=(--exclude="*.gif" --exclude="*.pdf" --exclude="*.lock")

# ── Scan target ──────────────────────────────────────────────────────────────
VIOLATIONS=""
SCAN_TARGET=""
SCANNED_COUNT=0

if [ "$MODE" = "staged" ]; then
  # Pre-commit mode: scan only staged framework/ files using git grep.
  STAGED=$(git diff --cached --name-only --diff-filter=ACMR | grep '^framework/' || true)
  if [ -z "$STAGED" ]; then
    exit 0
  fi
  SCANNED_COUNT=$(echo "$STAGED" | wc -l | tr -d ' ')
  for word in "${FLAG_WORDS[@]}"; do
    # Search each staged file's INDEX content (not worktree)
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      # Apply path exemptions
      skip=0
      for pattern in "${EXEMPT_PATHS[@]}"; do
        p="${pattern%/}"
        if [[ "$file" == *"$p"* ]]; then
          skip=1
          break
        fi
      done
      [ "$skip" = "1" ] && continue
      # git show :file | grep with line numbers
      matches=$(git show ":$file" 2>/dev/null | grep -inF "$word" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        while IFS= read -r match; do
          [ -z "$match" ] && continue
          # Skip lines with inline override
          [[ "$match" == *"context-allow:"* ]] && continue
          lineno="${match%%:*}"
          linetext="${match#*:}"
          VIOLATIONS+="  $file:$lineno"$'\n'
          VIOLATIONS+="    matched: $word"$'\n'
          VIOLATIONS+="    line:    $(echo "$linetext" | sed 's/^[[:space:]]*//' | cut -c1-100)"$'\n\n'
          EXIT_CODE=1
        done <<< "$matches"
      fi
    done <<< "$STAGED"
  done
else
  # Audit mode: recursive grep across framework/
  SCAN_TARGET="$MAIN_ROOT/framework"
  SCANNED_COUNT=$(find "$SCAN_TARGET" -type f "${GREP_EXCLUDES[@]/--exclude-dir=/-not -path \*/}" 2>/dev/null | wc -l | tr -d ' ' || echo "?")
  for word in "${FLAG_WORDS[@]}"; do
    matches=$(grep -rinF "${GREP_EXCLUDES[@]}" "$word" "$SCAN_TARGET" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        [ -z "$match" ] && continue
        [[ "$match" == *"context-allow:"* ]] && continue
        file="${match%%:*}"
        rest="${match#*:}"
        lineno="${rest%%:*}"
        linetext="${rest#*:}"
        rel="${file#$MAIN_ROOT/}"
        VIOLATIONS+="  $rel:$lineno"$'\n'
        VIOLATIONS+="    matched: $word"$'\n'
        VIOLATIONS+="    line:    $(echo "$linetext" | sed 's/^[[:space:]]*//' | cut -c1-100)"$'\n\n'
        EXIT_CODE=1
      done <<< "$matches"
    fi
  done
fi

# ── Report ───────────────────────────────────────────────────────────────────
if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "┌────────────────────────────────────────────────────────────────┐"
  echo "│  PERSONAL CONTEXT DETECTED — commit blocked                    │"
  echo "└────────────────────────────────────────────────────────────────┘"
  echo ""
  printf "%s" "$VIOLATIONS"
  echo "To resolve:"
  echo "  • Genericize the reference (replace specific names with placeholders)"
  echo "  • OR add inline override: # context-allow:<short reason>"
  echo "  • OR add an exempt path to personal/.agentignore"
  echo "  • OR bypass once (NOT recommended): git commit --no-verify"
  echo ""
  echo "To see the active blocklist: cat personal/.agentignore"
elif [ "$MODE" = "audit" ]; then
  echo "  ✓ framework/ is clean — no personal-context leakage detected"
  echo "    scanned against ${#FLAG_WORDS[@]} flag-word patterns"
fi

exit $EXIT_CODE
