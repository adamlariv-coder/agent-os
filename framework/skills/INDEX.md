# Skills Index — Fast Lookup

Generated from `framework/skills/registry.json` by `build-index.sh` — **do not edit by hand**.
Authoring guide: `framework/knowledge/skill-authoring.md`

---

## agentignore
**Path**: `framework/skills/agentignore/SKILL.md`
**Model**: haiku
**Triggers**: agentignore, .agentignore, context blocklist, personal context blocklist, block this term, add to blocklist, add to agentignore, update blocklist, audit blocklist, audit context, check context, what's in the blocklist, new customer, track this customer
**Does**: Manages personal/.agentignore — the gitignore-style blocklist that powers the pre-commit personal-context check. The hook blocks any commit that would introduce a flagged term (customer names, personal identifiers, internal product codes) into a non-exempt framework/ file. This skill adds entries, exempts paths, runs on-demand audits, and is cued by upstream skills when a new customer appears.
**Needs**: framework/agent/scripts/check-context.sh (the scanner the pre-commit hook uses); git access to personal repo
**Last updated**: 2026-06-08
