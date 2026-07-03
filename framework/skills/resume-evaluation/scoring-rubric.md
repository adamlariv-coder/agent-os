# Scoring Rubric — 7-dimension weighted model

Load when scoring a resume against a JD. Defines the dimensions, weights, and score bands used to produce the composite 1–10. This is the reusable core of the `resume-evaluation` skill.

---

## Dimensions and weights

| # | Dimension | Weight | Question it answers |
|---|-----------|--------|---------------------|
| 1 | ATS parseability | 15% | Will an automated parser extract every field cleanly? |
| 2 | Keyword match to target role | 20% | Are the JD's must-have terms present, truthfully, near the top? |
| 3 | Quantified impact | 20% | Does every senior claim carry a defensible number tied to an outcome? |
| 4 | Seniority signaling | 15% | Does scope (team, revenue, budget, customers, ownership) read at the target level? |
| 5 | Narrative coherence | 10% | Do the roles form a deliberate arc rather than a list? |
| 6 | Role relevance / prioritization | 15% | Is the most relevant experience the most prominent, and irrelevant depth cut? |
| 7 | Credibility / defensibility | 5% | Would any claim collapse under interview scrutiny? Are attributions precise? |

Composite = Σ (dimension score × weight). Report to one decimal.

Adjust weights per role class when justified, and **state the adjustment**: e.g. a pure-IC engineering role may raise Keyword match and lower Seniority signaling; a VP/Director search may raise Seniority signaling and Narrative coherence. Default to the table above.

---

## Score bands (apply to each dimension)

| Band | Meaning |
|------|---------|
| 9–10 | Best-in-class. Nothing material to improve on this dimension. |
| 7–8 | Strong. Competitive, with one or two specific, nameable gaps. |
| 5–6 | Adequate. Passes, but clearly beatable by a well-prepared competitor. |
| 3–4 | Weak. A likely reason for rejection at this level. |
| 1–2 | Disqualifying on this dimension for the target role. |

Every score below 9 must carry a named cause and a fix — no unexplained deductions.

---

## Per-dimension guidance

**1. ATS parseability.** Single column, standard section headers, no tables/text-boxes/columns/graphics, machine-readable dates, plain-text contact line, common section names ("Experience", "Skills", "Education"). Evaluate the *parsed* text. Any layout that risks dropped content caps this at 6 regardless of writing quality.

**2. Keyword match.** Cross-reference against the JD's must-have and nice-to-have keyword sets (see `jd-parsing.md`). Reward exact-term presence and near-top placement (summary + first role). Distinguish *missing keyword* (fixable, add if truthful) from *missing experience* (a real gap). Penalize stuffing.

**3. Quantified impact.** Look for numbers tied to outcomes: %, $, x-multiples, counts, time deltas, adoption/reliability/growth figures. A 10 has a defensible metric on nearly every senior bullet. Activity verbs with no numbers ("responsible for", "supported", "helped") drag this down.

**4. Seniority signaling.** Team size, revenue/budget owned, customer/user counts, org scope, 0-to-1 ownership, cross-functional leadership. Watch **title vs scope mismatch**: strong scope under a sub-target title (e.g. Principal PM applying to Director) — the numbers must carry the level, and a title-sorting screener is a real risk to name.

**5. Narrative coherence.** Do roles connect into an intentional arc (a through-line of domain, problem, or thesis)? A visible "saw the problem → built the thing → scaled it" progression scores high; a disconnected job list scores mid.

**6. Role relevance / prioritization.** Most relevant + most recent experience gets the most space and the top position. Irrelevant technical depth is trimmed. Off-target roles are condensed to a line. Misallocated space (deep detail on irrelevant work) is the common deduction.

**7. Credibility / defensibility.** Precise attributions ("contributed to", "per <system> attribution") over vague ownership of large numbers. Big claims (major deals, acquisitions, attributed revenue) should be phrased to survive scrutiny and be backed by ready proof points. Anonymized-but-specific claims still invite "which company?" — note it.

---

## Two-stage reporting

Report **ATS keyword match %** (Stage 1, binary) and the **weighted composite 1–10** (Stage 2, graded) as separate numbers. A resume can score 90%+ ATS match and a 6/10 holistic (keywords present but thin/unquantified), or a 9/10 holistic and fail ATS on one missing literal term. Surfacing both is the point of the skill.

---

## Role-specific scoring

For each distinct target role, produce its own score row with a one-line **gap-to-10**. When the same resume targets multiple role classes (e.g. IC PM vs Director), score each separately — the same document legitimately earns different scores by target, and the deltas tell the candidate where to fork a tailored version.
