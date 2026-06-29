# Claude.ai Chat Conventions

Conventions for Claude.ai chat sessions using this workspace.
Global rules: `framework/instructions/global.md` (always read first).

---

> **Status**: Stub — to be filled when Claude.ai chat is actively configured.

## Usage

Claude.ai chat does not auto-load `CLAUDE.md`. Attach the following files manually at session start:
1. `personal/agent/startup.md`
2. `personal/memory/core/identity.md`
3. `framework/instructions/global.md`
4. This file

---

## Notes

- No git or filesystem access in Claude.ai chat — all file operations are manual
- Protected zones still apply conceptually — do not suggest changes to memory without the confirmation token
