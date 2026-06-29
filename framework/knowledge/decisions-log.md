# Decisions Log

Append-only. Record major architectural decisions, why they were made, and what was rejected.

---

## 2026-06-11 — hooks for startup + routing; model pinning; single-source skill index

**Decision**: Move session startup and routing from agent-discipline (manual Read/script calls) to deterministic Claude Code hooks. Pin a model per skill via SKILL.md frontmatter with a Sonnet session default. Make `registry.json` the single source for skills and generate `INDEX.md` from it.

**Why (hooks)**: The startup sequence cost ~4.7K tokens + 4 Read round-trips every session and depended on the model *remembering* to read the right files in order. A `SessionStart` hook injects the same essentials (~1.3K tok) deterministically with zero reads. A `UserPromptSubmit` hook makes routing actually happen on every prompt (paths only — the 21KB manifest still never enters context), instead of relying on the model to invoke `route.sh`.

**Why (model pinning)**: Running every turn on Opus is wasteful for mechanical work. Skill frontmatter `model:` applies for that skill's turn then reverts — so high-reasoning skills (hiring, prd) get Opus, trivial ones (agentignore) get Haiku, and the rest run on the Sonnet session default.

**Why (single-source index)**: Skills were cataloged in three hand-maintained places (`registry.json`, `skills/INDEX.md`, `knowledge/skills-index.md`); `add-skill.sh` appended TODO stubs to two of them — a structural drift source. Now `registry.json` is authoritative and `INDEX.md` is generated (sub-refs auto-discovered from the skill dir).

**Rejected**: (a) Putting the full rule files in the SessionStart injection — defeats the token saving; instead a curated `boot-digest.md` holds essentials and full files load on demand. (b) Per-task model switching in the main thread — not supported; skill frontmatter / subagents are the only levers. (c) Generating *both* human catalogs from the registry — simpler to keep one generated view (`INDEX.md`) and delete the duplicate.

**Note**: `.claude/` is gitignored, so hook *wiring* (`settings.json`) is machine-local and provisioned by `setup.sh` from a committed template; the hook *scripts* live in `framework/agent/scripts/` and are shared.

---

## 2026-05-17 — framework/personal split (no submodules)

**Decision**: Split workspace into `framework/` (shareable) and `personal/` (private nested git repo). Rejected git submodules for `personal/`.

**Why**: The goal was to share the workspace setup with others without including personal memory, derived knowledge, or custom routing. The framework is a clean template; personal content is private.

**Why not submodules**: `personal/` changes constantly (daily routing updates, new knowledge topics) — submodule overhead (detached HEAD, pointer commits, `git submodule update`) would create friction on every commit for no deployment benefit. Two independent repos with `personal/` gitignored in the framework repo achieves clean separation without the overhead.

**Result**: Framework repo is public-safe. Personal repo is `git init`'d inside `personal/`, gitignored by the outer repo. No pointer tracking.

---

## 2026-05-17 — agent/ folder moved to personal/

**Decision**: Moved `agent/` (Claude's routing table and scripts) from repo root into `personal/agent/`.

**Why**: The routing table (`lookup.md`) is inherently personal — it contains entries for the user's specific topics, skills, and knowledge shortcuts. A new user of the framework would need to build their own from scratch. Keeping it in `personal/` makes this explicit and prevents personal routing state from leaking into the shareable framework.

---

## 2026-05-14 — agent/ as Claude's operational space

**Decision**: Give Claude a dedicated `agent/` directory it manages freely without `[CONFIRM MEMORY UPDATE]`.

**Why**: Claude needs a place to improve its own navigation without the friction of protected-zone confirmation. The routing table and search scripts are operational tooling, not user memory. Separating them from `memory/` and `instructions/` (which require confirmation) allows Claude to get smarter over time without bothering the user on every routing improvement.

---

## 2026-05-14 — Two-layer knowledge: instructions vs skills

**Decision**: Instructions are always-loaded small files; skills are on-demand larger files.

**Why**: Loading all skill content at session start would bloat context on every interaction. Most tasks only need 1-2 skills. Progressive disclosure: `personal/agent/lookup.md` routes to the right skill, which is only loaded when needed. Instructions (behavior rules) are small and always relevant.

---

## 2026-05-14 — Pre-commit hook enforcement for protected zones

**Decision**: Use a `commit-msg` hook (not `pre-commit`) to enforce the `[CONFIRM MEMORY UPDATE]` token.

**Why**: A `pre-commit` hook runs before the message is written, so it can't check the message content. `commit-msg` receives the message file as `$1` and can grep for the token. This allows agents to commit freely everywhere except protected zones, where the token acts as a forcing function for explicit user approval.
