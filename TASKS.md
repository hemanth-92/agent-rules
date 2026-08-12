# Project tasks

## Current phase

Repository hardening review (2026-08-12):

- [ ] Add `git` prefix rule and drop `pkexec` auto-allow in `codex-home/rules/default.rules`.
- [ ] Sync `ai-project-manager` skill template copies with `templates/project-docs/` and guard against drift in `scripts/validate.sh`.
- [ ] Re-add lean CI workflow (`.github/workflows/validate.yml`) validating on push and pull request.
- [ ] Gate install dry-run messages on actual actions in `scripts/install.sh`.
- [ ] Report skipped validation checks when `python3`/`shellcheck`/`codex` are absent.
- [ ] Document `claude-home/CLAUDE.md` install target in `README.md`.
- [ ] Confirm `./scripts/validate.sh` passes after the changes.

## Completed

- [x] Add `data-pipeline-bdd` skill for AI-driven data pipeline engineering (validated via `./scripts/validate.sh`).
- [x] Initial portable kit foundation and multi-agent install scripts.