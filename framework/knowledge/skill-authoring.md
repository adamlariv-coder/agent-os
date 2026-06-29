# Skill Authoring Guide

How to write SKILL.md files for this workspace.

---

## Skill types — choose before writing anything

| Type | Location | Audience | Registry |
|------|----------|----------|----------|
| **Framework** | `framework/skills/<name>/` | Anyone running AgentOS | `framework/skills/registry.json` |
| **Personal** | `personal/skills/<name>/` | You only — never shared | `personal/skills/registry.json` |
| **Distributable** | Separate git repo | Any team member | None — installed via `npx skills add` |

Use the **skill-creator** skill to scaffold any of these paths interactively.

---

## What a skill is

A skill is a self-contained capability package. It tells an agent:
- **When** to load it (trigger keywords)
- **What** it knows how to do (procedures, patterns, critical rules)
- **What else** to load if needed (sub-references)

Skills are loaded on demand — never at session start. Keep SKILL.md as the fast-load entry point and push detail into sub-reference files.

---

## SKILL.md structure

```markdown
---
name: skill-name
description: >
  One paragraph describing WHEN to trigger this skill. Be explicit about
  keywords and contexts. If in doubt, the agent should load it.
version: 1.0.0
author: your-name
protected: false
dependencies: []
last_updated: YYYY-MM-DD
---

# SKILL-NAME Skill

## Quick Reference

| Task | Approach |
|------|----------|
| Common task 1 | How to do it |
| Common task 2 | How to do it |

---

## Critical Rules

Things that cause failures if ignored. Keep this short and scannable.

---

## Sub-References

| File | When to load |
|------|-------------|
| editing.md | When making content edits |
| design.md | When adjusting layout or visual design |

---

## Dependencies

\`\`\`bash
# Install commands if any
\`\`\`
```

---

## Sub-reference files

Sub-references hold the detail that doesn't fit in SKILL.md without bloating it. Load them only when the task specifically needs them.

Name them descriptively: `editing.md`, `design.md`, `optimization.md`, `query-building.md`.

Each sub-reference should start with a one-line summary of what it covers and when to load it.

---

## Frontmatter fields

| Field | Required | Notes |
|---|---|---|
| `name` | Yes | kebab-case, matches directory name |
| `description` | Yes | Trigger condition — be explicit |
| `version` | Yes | semver |
| `author` | Yes | Real name for **distributable** skills (public repo — attribution matters) and **personal** skills (exempt, never shared). For **framework** skills committed inside the AgentOS repo, use a non-personal value like `AgentOS` — agentignore blocks personal names in `framework/`. |
| `protected` | Yes | `false` unless this is a core system skill |
| `dependencies` | Yes | Array of package names, or `[]` |
| `last_updated` | Yes | YYYY-MM-DD |
| `model` | No | Pin a model for this skill's turn: `opus` (high reasoning), `sonnet` (default), `haiku` (trivial). Omit to inherit the session model. |

---

## After authoring

**Framework skill**: `framework/skills/registry.json` is the source of truth; `framework/skills/INDEX.md` is generated — never hand-edit it.

1. Add the skill to `framework/skills/registry.json` — `path`, `type: "framework"`, `model`, `needs`, `description`, `triggers`
2. Run `bash framework/agent/scripts/build-index.sh` — regenerates both `INDEX.md` files and the routing manifest
3. Commit: `git add framework/skills/<name> framework/skills/registry.json framework/skills/INDEX.md personal/agent/`

**Personal skill**: same flow but against `personal/skills/registry.json`. Commit to personal repo only — never stage `personal/skills/` in the framework repo.

**Distributable skill**: push to the team skills repo; no registry update needed.

---

## Quality checklist

- [ ] `description` field clearly states trigger keywords and conditions
- [ ] Quick Reference table covers the 3-5 most common tasks
- [ ] Critical Rules section exists (even if short)
- [ ] Sub-references listed with clear load conditions
- [ ] Entry added to registry.json with accurate `triggers` array
- [ ] `build-index.sh` run — routing-manifest updated
