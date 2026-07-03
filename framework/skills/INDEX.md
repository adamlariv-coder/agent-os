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

---

## resume-evaluation
**Path**: `framework/skills/resume-evaluation/SKILL.md`
**Model**: opus
**Triggers**: evaluate resume, score resume, grade my resume, rate my resume, resume evaluation, ats check, ats score, resume vs job description, match resume to job, resume keyword match, resume gap analysis, screen my resume, how would a recruiter score this, tailor resume to role, is my resume competitive
**Does**: Evaluate a resume against a specific job description the way a modern ATS + LLM screening stack would. Accepts the JD as text, URL, or document; runs a two-stage evaluation (binary ATS keyword match, then a 7-dimension weighted holistic score); returns a 1–10 composite with per-dimension sub-scores, an ATS match table, and ranked, truthful improvement suggestions across role fit, keywords, seniority, and quantified impact.
**Needs**: WebFetch (URL JDs); Read + pdf/docx skills (document JDs/resumes); scoring-rubric.md; jd-parsing.md
**Sub-refs**: jd-parsing.md · scoring-rubric.md
**Last updated**: 2026-07-02

---

## topic-categories
**Path**: `framework/skills/topic-categories/SKILL.md`
**Model**: haiku
**Triggers**: topic categories, topic category, categorize topic, recategorize topics, list topics, topics by category, knowledge categories, browse topics, which topics are ecp
**Does**: Organize and browse personal/knowledge/topics/ by domain category (ECP, Scoper, Rockbound, finance, etc.). Assign Category fields, list topics by bucket, and keep routing scoped as the topics directory grows.
**Needs**: framework/knowledge/topic-categories.json; framework/agent/scripts/list-topics.sh; personal/agent/topics-index.json
**Sub-refs**: assigning.md
**Last updated**: 2026-06-29
