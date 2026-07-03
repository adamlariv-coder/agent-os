# JD Parsing — extracting requirements, keywords, and seniority

Load when ingesting a job description (text, URL, or document) to build the requirement and keyword sets the scoring rubric checks against.

---

## Ingest by source type

| Source | How |
|--------|-----|
| Pasted text | Use directly |
| URL | `WebFetch` with a prompt asking for: title, level, responsibilities, required qualifications, nice-to-haves, and company domain/stage. If the URL is auth-gated (e.g. some LinkedIn job pages), ask the user to paste the text. |
| PDF / DOCX | Load via the `pdf` / `docx` skill, then parse the text |

---

## Extract these fields

1. **Role title + level** — IC vs manager vs director/VP; "Senior", "Staff", "Principal", "Lead", "Head of".
2. **Must-have requirements** — the "Requirements" / "You have" / "Minimum qualifications" block. These are the hard gates.
3. **Nice-to-haves** — "Bonus", "Preferred", "Nice to have". Cheap keyword wins if truthful.
4. **Hard keywords** — concrete, checkable terms: technologies, methodologies, named tools, domain nouns, years-of-experience thresholds. These drive the Stage-1 ATS match.
5. **Soft signals** — collaboration, ownership, ambiguity tolerance, communication. Map to narrative/seniority dimensions, not keyword match.
6. **Domain + company stage** — industry, product type, scale (startup vs enterprise), any regulatory/compliance context.

---

## Build the keyword sets

- **Must-have keyword set:** the literal terms from required qualifications. Check each as present/absent in the resume (exact or close variant). This is unforgiving on purpose — ATS keyword filters are.
- **Nice-to-have keyword set:** preferred terms. Reward presence; don't penalize absence heavily.
- **Variant awareness:** count reasonable synonyms/variants as present (e.g. "CI/CD" ≈ "continuous integration/continuous delivery"; "K8s" ≈ "Kubernetes"), but note when only a variant appears — some naive ATS filters match literally.
- **Placement matters:** a keyword in the summary or first role counts more (recency/prominence weighting) than one buried on page two.

---

## Seniority signal extraction

Pull the level cues the JD encodes so the rubric's Seniority dimension is scored against the *role's* bar, not a generic one:

- Years-of-experience thresholds ("5+ years managing…").
- Scope words: "own the roadmap", "lead a team", "define strategy", "cross-functional", "org-wide".
- Management vs IC framing (does it mention direct reports?).
- Budget / revenue / P&L ownership language.

Flag **title/level mismatches** between the JD and the resume up front — e.g. a JD titled mid-senior IC that the candidate wants to pitch at Director level, or vice versa. This shapes the seniority score and the improvement advice (lead with scope, add an impact band, or target a different req).

---

## Common keyword-gap patterns to check

- A named artifact the JD wants that the resume implies but never states literally (e.g. JD says "SDK"; resume shows APIs + console but never writes "SDK").
- A measurement the JD names that the resume demonstrates implicitly (e.g. "developer satisfaction / DX metrics", "platform health") — recommend stating it explicitly if true.
- Ecosystem/tooling nice-to-haves listed by name (frameworks, platforms) — cheap wins to add when truthful.
- Years-of-experience thresholds not obviously satisfied by the visible date range.

For each gap: classify as **fixable keyword** (present in reality, add the term) vs **real experience gap** (absent — report honestly, never fabricate).
