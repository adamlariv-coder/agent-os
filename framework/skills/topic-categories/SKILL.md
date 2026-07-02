---
name: topic-categories
model: haiku
description: >
  Organize, browse, and route personal/knowledge/topics/ by category. Use when adding
  or recategorizing topics, listing topics in a domain (ECP, Scoper, Rockbound, finance),
  fixing missing Category fields, or when the topics directory is getting large and you
  need scoped loading instead of scanning everything.
triggers:
  - topic categories
  - topic category
  - categorize topic
  - recategorize topics
  - list topics
  - topics by category
  - knowledge categories
  - which topics are ecp
  - browse topics
needs:
  - framework/knowledge/topic-categories.json (canonical category definitions)
  - framework/agent/scripts/build-index.sh (regenerates indexes after category changes)
  - framework/agent/scripts/list-topics.sh (list/filter by category)
  - personal/agent/topics-index.json (generated category index)
  - personal/knowledge/INDEX.md (generated category navigation)
last_updated: 2026-06-29
author: AgentOS
protected: false
dependencies: []
version: 1.0.0
---

# topic-categories Skill

Keep `personal/knowledge/topics/` navigable as it grows. Categories are **primary domain buckets**; tags remain for fine-grained routing.

## Quick Reference

| Task | Command / action |
|------|------------------|
| List all categories | Read `framework/knowledge/topic-categories.json` |
| List topics in a category | `bash framework/agent/scripts/list-topics.sh --category ecp` |
| List all topics (grouped) | `bash framework/agent/scripts/list-topics.sh` |
| Route by domain query | `bash framework/agent/scripts/route.sh "scoper delivery"` |
| Browse by category (human) | Read `personal/knowledge/INDEX.md` (generated) |
| After any category edit | `bash framework/agent/scripts/build-index.sh` |

---

## Critical Rules

1. **Every active topic file must have `**Category**:`** — one primary category slug from `topic-categories.json`.
2. **Tags are secondary** — use for search/routing keywords; category is the domain bucket.
3. **Filename prefixes should match category** when possible (`ecp-*`, `scoper-*`, `rockbound-*`, `ecp-design-intelligence-*`, `personal-finance`, `personal-context-*`).
4. **Never hand-edit** `topics-index.json`, `routing-manifest.json`, or `personal/knowledge/INDEX.md` — run `build-index.sh`.
5. **New category** → add to `topic-categories.json` first, then recategorize affected topics, then rebuild.

---

## Topic file header (required)

```markdown
> status: active | created: YYYY-MM-DD | updated: YYYY-MM-DD

**Category**: ecp
**Tags**: ecp, workflow, automation

# Topic Title

One-line summary (first body paragraph — used by build-index for routing summaries).

**Related topics**: `other-topic.md`
```

Order: status line → **Category** → **Tags** → `#` title → summary → related topics.

---

## Current categories

| Slug | Label | Typical files |
|------|-------|---------------|
| `ecp` | ECP | `ecp-overview.md`, `ecp-architecture.md`, … |
| `ecp-design-intelligence` | ECP Design Intelligence | `ecp-design-intelligence-*.md` |
| `personal-finance` | Personal Finance | `personal-finance.md` |
| `rockbound-digital` | Rockbound Digital | `rockbound-*.md` |
| `scoper` | Scoper | `scoper-*.md` |
| `personal` | Personal | `personal-context-brief.md` |

Full definitions and routing aliases: `framework/knowledge/topic-categories.json`.

---

## Workflows

### Add a new topic

1. Pick category from `topic-categories.json` (or propose a new one).
2. Create `personal/knowledge/topics/<category>/<kebab-name>.md` with header above (folder name must match **Category** slug).
3. Add **Related topics** cross-links to siblings in the same category.
4. Run `build-index.sh` + `validate-indexes.sh`.

### Recategorize existing topics

1. Update `**Category**:` in each affected file.
2. Adjust **Tags** if domain keywords changed.
3. Rebuild indexes; confirm with `list-topics.sh --category <slug>`.

### Load scoped context for a task

Prefer category-scoped loading over reading all of `topics/`:

```bash
bash framework/agent/scripts/list-topics.sh --category scoper
bash framework/agent/scripts/route.sh "scoper scope risk brief"
```

Load the overview topic first, then siblings only if the task needs depth.

---

## Sub-References

| File | When to load |
|------|-------------|
| `assigning.md` | Adding categories, prefix rules, or bulk recategorization |
