# Layout and discovery

## Managed Codex paths

| Source | Target | Method |
| --- | --- | --- |
| `codex-home/AGENTS.md` | `~/.codex/AGENTS.md` | symlink |
| `codex-home/config.toml` | `~/.codex/config.toml` | rendered copy with trusted projects |
| `codex-home/rules/` | `~/.codex/rules` | symlink |
| `codex-home/*.config.toml` | `~/.codex/*.config.toml` | symlink |
| `.agents/skills/*` | `~/.agents/skills/*` | symlink |

## Optional multi-agent targets

| Flag / Agent | Source | Target |
| --- | --- | --- |
| `--claude` | `claude-home/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `--claude` | `.agents/skills/*` | `~/.claude/skills/*` |
| `--grok` | `.agents/skills/*` | `~/.grok/skills/*` |
| `--cursor` | `.agents/skills/*` | `~/.cursor/skills/*` |
| Antigravity | `.agents/skills/*` | `~/.agents/skills/*` (or `~/.gemini/config/skills/*`) |

## Project discovery roots

The installer scans these roots for Git worktrees (when present):

- `$HOME/coding`
- `$HOME/github`

Common dependency and build directories are pruned during discovery:
`node_modules`, `.venv`, `venv`, `target`, `build`, `dist`.

## Project bootstrap

`scripts/bootstrap-project.sh` copies files from `templates/project-docs/` into
a target directory. Existing files are preserved unless `--force` is set.

## Boundaries

- Never install credentials, session DBs, or history into this repository.
- Do not treat `docs/` as auto-loaded agent instructions.
- Rerun the installer after cloning new repositories so trust entries update.
