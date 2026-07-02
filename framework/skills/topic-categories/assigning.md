# Topic Category Assignment

When to load: bulk recategorization, adding a new category, or filename/prefix decisions.

## Prefix → category inference

When a topic has no `**Category**:` line, infer from filename using `topic-categories.json` `prefixes` / `exclude_prefixes`:

| Prefix | Category | Notes |
|--------|----------|-------|
| `ecp-design-intelligence-` | `ecp-design-intelligence` | Checked before `ecp-` |
| `ecp-` | `ecp` | Core protocol topics |
| `scoper-` | `scoper` | Product + platform |
| `rockbound-` | `rockbound-digital` | Business / GTM |
| `personal-finance` | `personal-finance` | Finance-specific |
| `personal-context-` | `personal` | Identity / career meta |

If inference fails, ask the user — do not leave category blank.

## Tags vs category

| Field | Purpose | Example |
|-------|---------|---------|
| **Category** | One domain bucket for browsing and scoped load | `ecp-design-intelligence` |
| **Tags** | Search keywords and route triggers | `pixijs, brand, creative document` |

A topic in `ecp-design-intelligence` should still tag `ecp` if ECP context helps routing — category is not duplicated in tags unless useful for search.

## Adding a new category

1. Edit `framework/knowledge/topic-categories.json` — add slug, label, description, aliases, prefixes.
2. Update this table in `assigning.md` and the table in `SKILL.md`.
3. Add registry entry triggers if the category name should route to the skill (optional).
4. Assign topics; run `build-index.sh`.
5. Append decision to `framework/knowledge/decisions-log.md` if structural.

## Bulk recategorization checklist

- [ ] All active `.md` files have `**Category**:` with a known slug
- [ ] Summaries are first real paragraph (not `**Tags**:` line)
- [ ] `build-index.sh` completes without warnings
- [ ] `validate-indexes.sh` passes
- [ ] `list-topics.sh` shows expected grouping
- [ ] `route.sh "<category alias>"` returns a topic from that category
