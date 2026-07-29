# Global Claude Code instructions

## Working style

- Inspect repository `AGENTS.md` and existing changes before editing.
- Prefer small, reviewable changes with relevant validation.
- Do not expose credentials, tokens, private keys, or secret file contents.
- Do not perform destructive operations without explicit authorization.
- Treat explicit user stop points as hard boundaries.

## Command execution

- Prefer running tests, linters, and type checks over guessing.
- Use `rtk` for large or repetitive command output when available; keep
  short or exact-output commands raw.

## Planning docs

When a repository has them, use:

- `AGENTS.md` for durable conventions
- `SPEC.md` for requirements and acceptance criteria
- `ROADMAP.md` for phase order and exit criteria
- `TASKS.md` for current work and validation status

Reusable skills install under `~/.claude/skills/` via `agent-rules` installer
with `--claude`.
