---
name: resume-evaluation
model: opus
description: >
  Evaluate a resume against a specific job description the way a modern ATS + LLM
  screening stack would, and score it 1–10. Trigger when asked to score/grade/evaluate
  a resume, check ATS compatibility, match a resume to a job description or posting,
  simulate applicant screening, run a keyword/gap analysis, assess seniority fit, or
  tailor a resume to a role. Accepts the job description as pasted text, a URL, or a
  document (PDF/DOCX). Produces a weighted 1–10 score, per-dimension sub-scores, a
  simulated ATS keyword match, and a ranked list of concrete improvements.
triggers:
  - evaluate resume
  - score resume
  - grade my resume
  - rate my resume
  - resume evaluation
  - ats check
  - ats score
  - resume vs job description
  - match resume to job
  - resume keyword match
  - resume gap analysis
  - screen my resume
  - how would a recruiter score this
  - tailor resume to role
  - is my resume competitive
needs:
  - WebFetch (to ingest a job description from a URL)
  - Read + the pdf / docx skills (to ingest a job description or resume supplied as a document)
  - scoring-rubric.md (the 7-dimension weighted scoring model)
  - jd-parsing.md (how to extract requirements, keywords, and seniority signals from a JD)
last_updated: 2026-07-02
author: AgentOS
protected: false
dependencies: []
version: 1.0.0
---

# resume-evaluation Skill

Replicate what a modern hiring stack does to a resume — ATS keyword parse **then** LLM holistic score — and return a defensible 1–10 with concrete fixes. The goal is an evaluation the candidate can trust *because* it mirrors the machine that will actually screen them.

## Quick Reference

| Task | Approach |
|------|----------|
| JD supplied as text | Use it directly |
| JD supplied as URL | `WebFetch` the URL; extract title, must-haves, nice-to-haves, seniority, domain |
| JD supplied as PDF/DOCX | Load via the `pdf` / `docx` skill, then parse |
| Resume supplied as document | Load via `pdf` / `docx`; evaluate the **rendered** text an ATS would actually see |
| Produce the score | Run the 7-dimension rubric in `scoring-rubric.md`, weight, and compute the composite |
| Simulate ATS pass | Hard keyword presence/absence check (see `jd-parsing.md`) — binary, unforgiving |
| Simulate LLM screener | Holistic fit, seniority, narrative, credibility — graded, not binary |
| Deliver | 1–10 composite + sub-scores + ATS match table + ranked improvements + gap-to-10 |

---

## The evaluation procedure

1. **Ingest the JD** (text / URL / document). Extract with `jd-parsing.md`:
   - Role title + level, must-have requirements, nice-to-haves, hard keywords, domain, seniority signals.
2. **Ingest the resume** as the *rendered text* — evaluate what an ATS parser extracts, not the visual layout. Flag anything (tables, columns, headers/footers, images, text-in-graphics) likely to be dropped by a parser.
3. **Two-stage scoring** — mirror the real pipeline:
   - **Stage 1 — ATS keyword match (binary):** for each must-have keyword, present or absent. Compute a raw match %. A resume can be excellent yet fail here on a missing literal keyword — report that honestly.
   - **Stage 2 — LLM holistic score (graded):** apply the 7-dimension rubric in `scoring-rubric.md`.
4. **Compute the composite 1–10** from the weighted rubric. Report the ATS match % alongside it — they answer different questions (*will it get parsed/surfaced* vs *how strong is it once read*).
5. **Gap analysis + ranked improvements:** every point below 10 must have a named, actionable cause. Rank fixes by score impact per unit of effort.

---

## Critical Rules

1. **Never invent experience.** Suggest surfacing, reframing, or keyword-aligning what is *truthfully* present. Flag a genuine gap as a gap — do not paper over it with fabricated content. This is the line the skill must not cross.
2. **Keyword alignment ≠ keyword stuffing.** Recommend adding a keyword only where the underlying experience is real. Stuffed keywords are penalized by modern LLM screeners and read as dishonest to humans.
3. **Score against *this* JD, not resumes in general.** A resume is a 9 for one role and a 5 for another. Every score is role-relative; always state the target role.
4. **Evaluate the parsed text, not the pretty version.** If layout risks breaking ATS parsing, that caps the ATS score regardless of content quality.
5. **Separate ATS match % from the holistic 1–10.** Don't average them into one number — a hiring stack applies them in sequence, and so should the report.
6. **Make every deduction defensible.** No vague "could be stronger." Name the dimension, the cause, and the fix. If the candidate asked in an interview "why not a 10?", the answer must already be in the report.
7. **Confidentiality flags are part of the eval.** Named employers/customers/deal figures boost LLM recognition but may carry NDA risk — surface the tradeoff, default to anonymized.

---

## Output format

```
# Resume Evaluation — <Role Title> @ <Company>

## Overall: X.X / 10   |   ATS keyword match: NN%

## ATS keyword match (Stage 1)
| Must-have keyword | Present? | Where / note |
| ... | ✓ / ✗ | ... |

## Rubric sub-scores (Stage 2)
| Dimension | Score /10 | Notes |
| ... | ... | ... |

## Gap analysis
- <dimension>: <cause> → <fix>

## Ranked improvements (highest leverage first)
1. ...
2. ...

## Confirm before sending
- <confidentiality / one-page-fit / claim-defensibility flags>
```

---

## Sub-References

| File | When to load |
|------|-------------|
| `scoring-rubric.md` | Always — the 7-dimension weighted model and what each score band means |
| `jd-parsing.md` | When extracting requirements/keywords/seniority from a JD, especially URL or document JDs |

---

## Notes

- Persist per-candidate evaluations in the **personal** repo (e.g. a `resume-evaluation-*` topic), never in `framework/` — scored outputs contain personal data. This skill itself stays generic and shareable.
- Re-run the full procedure whenever the resume or the target JD changes; scores are only valid for the JD they were computed against.
