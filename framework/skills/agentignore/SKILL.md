---
name: agentignore
model: haiku
description: Manage personal/.agentignore — the personal-context blocklist that prevents customer names, personal identifiers, and internal project codes from leaking into framework/ files. Add new flag-words or exempt paths, audit the current state, view the blocklist, and curate the list over time as new customers/engagements appear.
triggers:
  - agentignore
  - .agentignore
  - context blocklist
  - personal context blocklist
  - block this term
  - add to blocklist
  - add to agentignore
  - update blocklist
  - audit blocklist
  - audit context
  - check context
  - what's in the blocklist
  - new customer
  - track this customer
needs:
  - framework/agent/scripts/check-context.sh (the scanner the hook uses)
  - personal/.agentignore (the active blocklist; user-private)
  - git access to personal repo (for committing blocklist changes)
last_updated: 2026-06-08
---

# agentignore Skill

Curate `personal/.agentignore` — the personal-context blocklist that powers the pre-commit hook in `.workspace/hooks/pre-commit`. The blocklist prevents customer names, personal identifiers (yours), and internal project codes from being committed into `framework/` files.

## When to use

- **"Add Acme Co. to .agentignore"** / **"Block this term"** — new customer just entered the workflow; capture them now so a future framework edit doesn't leak the name
- **"What's in the blocklist?"** — show the current entries
- **"Audit the framework"** / **"Run a context check"** — manual scan across the whole framework tree (same scanner the hook uses, but on demand)
- **"Remove X from the blocklist"** — rare; usually after a name is genericized everywhere
- **"Add an exempt path"** — when a legitimate infrastructure reference triggers false positives

The blocklist is also worth a touch every time a new customer enters a transcript ingest — the `transcript-ingest` skill can cue this skill if a customer slug appears for the first time.

## When **not** to use

- Generic content scanning across all files → that's the pre-commit hook itself, already wired
- Anything that doesn't touch `personal/.agentignore` → just edit the file directly, you don't need a skill

---

## The file: `personal/.agentignore`

**Location**: `personal/.agentignore` (user-private; tracked in the personal repo, never in framework)

**Syntax** (gitignore-aligned):

| Line shape | Meaning |
|---|---|
| `path/` or `*.ext` | **Exempt** — files matching this path are skipped from the scan |
| `!word` | **Flag** — if found in any non-exempt framework/ file, commit is BLOCKED |
| `# comment` | Ignored |
| Blank line | Ignored |

**Inline override** (in the content file, NOT in `.agentignore`):
```
This line has @<flagged-name> in it.  <!-- context-allow:legacy example -->
```

That one line is skipped from the scan. Use sparingly — every override is a permission you're granting yourself to keep a real reference.

**Matching semantics**:
- Flag words match **case-insensitive substring**. `!alice-smith` would match `alice-smith`, `@alice-smith`, `Alice-Smith`, `Alice-smith`, etc.
- Exempt paths match **substring on the file path**. `framework/skills/pptx/` exempts everything under that path.

---

## Workflow

### 1. Add a new flag word (most common)

```bash
# User says: "Add Acme Co. to the blocklist — we have a call next Tuesday"
```

1. **Read** `personal/.agentignore` to see the current state
2. **Categorize** the new term: personal identifier? customer name? speaker name? product code?
3. **Append** to the appropriate section (preserve comments + section structure):

```bash
cat >> personal/.agentignore <<'EOF'
!acme co
!acme corp
EOF
```

   Add **variants** the user is likely to use: short form, full legal form, lowercase. Match is case-insensitive but substring exact, so `!acme co` matches `Acme Co.` but not `AcmeCo`.

4. **Audit immediately** to catch any existing leakage:
   ```bash
   bash framework/agent/scripts/check-context.sh --audit
   ```
   If the audit fails, genericize the leaks in framework/ first, then proceed.

5. **Commit to the personal repo**:
   ```bash
   cd personal
   git add .agentignore
   git commit -m "agentignore: add <customer> flag words"
   git push origin main
   ```

### 2. Add an exempt path

```bash
# User says: "Stop flagging anything under framework/skills/foo — it legitimately references an internal tool"
```

Append a bare path entry (no `!`):
```bash
cat >> personal/.agentignore <<'EOF'

# Exempt: foo skill legitimately references the internal tool name
framework/skills/foo/
EOF
```

Then audit to confirm the exemption took effect. Commit.

### 3. Show the current blocklist

```bash
cat personal/.agentignore
```

Or, for a structured view:
```bash
grep -v '^#' personal/.agentignore | grep -v '^$' | head -50
```

### 4. Run a manual audit

```bash
bash framework/agent/scripts/check-context.sh --audit
```

Output is one of:
- `✓ framework/ is clean — no personal-context leakage detected` → all good
- Block message with file:line:matched-pattern listings → fix and re-audit

### 5. Remove an entry (rare)

Only when the term is genuinely no longer sensitive (e.g., a customer engagement has ended AND every reference is genericized). Confirm with the user before removing — false negatives are expensive.

```bash
# Edit personal/.agentignore directly
# Remove the line
# Audit and commit
```

---

## Categories — keep entries grouped

Convention for keeping `personal/.agentignore` readable:

```
# ─────────────────────────────────────────────────────────────────────────
# EXEMPT PATHS
# ─────────────────────────────────────────────────────────────────────────

<bare path entries — vendor infra, font references, lockfiles>

# ─────────────────────────────────────────────────────────────────────────
# FLAG WORDS
# ─────────────────────────────────────────────────────────────────────────

# Personal identifiers
!<your name>
!<your username>
!@<your username>

# Customer names — add as engagements occur
!<customer>
!<contact-first-name> <contact-last-name>

# Internal product codes / codenames
!<product code>
```

When adding, **insert under the matching section comment**, not at the end of the file. Keeps the list scannable.

---

## Cuing from other skills

`agentignore` should be cued from any skill that introduces a new proper noun into the workspace:

- **`transcript-ingest`** — when a new customer slug appears for the first time. After the synthesis is written, check if the customer name is already in `personal/.agentignore`. If not, prompt: *"This is the first transcript from `<Customer>`. Add to .agentignore?"*
- **`meeting-summary`** — same; when a new customer's recap is being drafted
- **`ingest`** — when a topic file introduces a new product code or named system

The convention is: **propose, don't auto-add.** The user decides what counts as personal context for them.

---

## Edge cases

- **The blocklist itself is sensitive**. `personal/.agentignore` contains a list of every customer name and your personal identifiers. Keep it in `personal/` (private repo), never in `framework/`.
- **Single-word terms with high collision risk** (e.g., `!ace` would match `placeholder`, `interface`, `ace-up-your-sleeve`). Prefer multi-word phrases or distinctive identifiers. If a short term is unavoidable, scope it via an exempt-path strategy.
- **Renamed or misspelled forms aren't caught** (`g.clement`, `g-clement`, `gui clement`). The blocklist is a denylist — be explicit about variants you actually use.
- **Binary files are auto-skipped** by the scanner (png/jpg/pdf/etc). If a new binary asset format needs exemption, add it to the script's exclude list (rare).
- **`--no-verify` bypass**. The hook can be skipped with `git commit --no-verify`. The skill should NOT teach this casually; it exists for emergencies.

---

## Memory bridges

- `framework/agent/scripts/check-context.sh` — the scanner script (called by the pre-commit hook AND directly via this skill)
- `.workspace/hooks/pre-commit` — the hook that invokes the scanner before every commit
- `framework/agent/scripts/agentignore.template` — the example file Claude copies to `personal/.agentignore` on first setup
- See `framework/skills/transcript-ingest/SKILL.md` and `framework/skills/meeting-summary/SKILL.md` for upstream skills that cue this one when new customers appear
