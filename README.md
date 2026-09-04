# agent-rules

Portable AI coding-agent configuration, rules, and reusable skills.

Inspired by [titus-ai](https://github.com/ChrisTitusTech/titus-ai). Works with
**Antigravity**, **Cursor**, **Codex**, **Claude Code**, and **Grok**, and gives you a consistent
`AGENTS.md` / `SPEC.md` / `ROADMAP.md` / `TASKS.md` workflow you can pull into
every project.

## Quick start

```bash
# Clone once
git clone git@github.com:hemanth-92/agent-rules.git ~/coding/agent-rules
cd ~/coding/agent-rules

# Preview, then install global config + skills
./scripts/install.sh --dry-run
./scripts/install.sh

# Optional: also install into Claude, Grok, and Cursor skill directories
./scripts/install.sh --claude --grok --cursor

# Or install only the skills for one job, e.g. data engineering
./scripts/install.sh --claude --category data-engineering

# Bootstrap planning docs into a project
./scripts/bootstrap-project.sh ~/coding/my-app
```

Restart your coding agent after installation. Existing managed files are backed
up under `~/.codex/backups/` (and under Claude/Grok backup dirs when those
targets are used). Credentials, sessions, history, and caches are left alone.

## What gets installed

| Source | Destination | Purpose |
| --- | --- | --- |
| `codex-home/` | `~/.codex/` | Codex global instructions, config, rules, local-model profiles |
| `claude-home/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code global instructions (`--claude`) |
| `.agents/skills/` | `~/.agents/skills/` | Reusable skills (Codex / multi-agent) |
| `.agents/skills/` | `~/.claude/skills/` | Same skills for Claude Code (`--claude`) |
| `.agents/skills/` | `~/.grok/skills/` | Same skills for Grok (`--grok`) |

### Skill categories

Every skill declares one `category` in its front matter, defined in
`skill-categories.txt`. The installer can install a whole category, individual
skills, or (by default) everything.

| Category | Skills |
| --- | --- |
| `data-engineering` | `data-pipeline-bdd`, `incremental-data-load` |
| `ai-engineering` | `python-ai` |
| `systems` | `bash-scripting`, `linux-sysadmin`, `rust-cli` |
| `workflow` | `ai-project-manager`, `project-bootstrap`, `pr-readiness` |

```bash
./scripts/install.sh --list-categories     # categories and their skills
./scripts/install.sh --list-skills         # skills and their categories

# One category
./scripts/install.sh --claude --category data-engineering

# Several categories plus one extra skill
./scripts/install.sh --claude --category data-engineering \
  --category ai-engineering --skill bash-scripting
```

Both flags are repeatable and combine as a union. Selection is additive across
runs: by default the installer never removes skills a previous run linked, so
narrowing the selection does not uninstall earlier ones.

Add `--prune` to make the selection exact — it removes links this installer
previously created for skills outside the current selection:

```bash
./scripts/install.sh --claude --category data-engineering --prune
```

Pruning only touches symbolic links pointing into this repository's
`.agents/skills/`. Skills you added to the target directory yourself are left
alone.

### Trusted projects

Every Codex install renders `~/.codex/config.toml` with trusted-project entries
for:

- `~/coding` and every Git worktree found under it
- `~/github` and every Git worktree found under it (if present)

Codex trust entries match exact project roots, so rerun the installer after
cloning new repositories.

### Recommended plugins (Codex, opt-in)

```bash
./scripts/install.sh --plugins
```

Plugin IDs live in `codex-plugins.txt`. The default selection is
`superpowers@openai-curated`.

### Optional: RTK

[RTK](https://github.com/rtk-ai/rtk) compresses verbose command output before it
hits the agent context window:

```bash
# Quick install pre-built binary (Linux/macOS)
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Or install from source via Cargo (requires Rust toolchain):
# cargo install --git https://github.com/rtk-ai/rtk

rtk --version
rtk gain
```

## Use in every project

### Global skills (after install)

Start your agent normally. Invoke a skill explicitly when needed:

```text
$ai-project-manager plan the next phase from SPEC.md
$pr-readiness check whether this branch is merge-ready
$rust-cli add a clap subcommand
$python-ai add an Ollama-backed provider
$bash-scripting harden this installer
$data-pipeline-bdd generate a Spark ETL pipeline from Gherkin specs
$incremental-data-load design the extraction and backfill for this pipeline
$linux-sysadmin diagnose this service failure
$project-bootstrap scaffold planning docs for this repo
```

### Per-project bootstrap

Drop the planning template into any repository:

```bash
# From this repo
./scripts/bootstrap-project.sh /path/to/project

# Or after a one-time global install, from any project:
# (if you put scripts on PATH or call the clone path)
~/coding/agent-rules/scripts/bootstrap-project.sh .

# Only the docs a small project needs
./scripts/bootstrap-project.sh --only SPEC,TASKS /path/to/project
```

This copies (without overwriting existing files unless `--force`):

- `CLAUDE.md` — Claude Code entry point; imports `AGENTS.md`
- `AGENTS.md` — durable agent instructions
- `SPEC.md` — requirements and acceptance criteria
- `ROADMAP.md` — ordered phases and exit criteria
- `TASKS.md` — current work and validation status

Each freshly copied doc carries a `> Status: TEMPLATE` line, and the script
reports every doc that still has one. Adapt the templates to the project and
delete that line; remove irrelevant sections instead of leaving placeholders.
An unadapted template reads to an agent as if it were real content.

## AI development workflow

1. **Plan** with `$ai-project-manager` — reconcile `AGENTS.md`, `SPEC.md`,
   `ROADMAP.md`, `TASKS.md`, pause at approval boundaries.
2. **Implement** one reviewable phase at a time with focused validation.
3. **Ship** with `$pr-readiness` — local gates, optional CodeRabbit, CI, and
   independent review before merge.

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for the full lifecycle.

## Local models (Codex)

```bash
# Ollama
ollama pull qwen3-coder
codex --profile ollama

# llama.cpp Responses-compatible endpoint on :8080
llama-server --model /path/to/model.gguf --jinja --port 8080
codex --profile llamacpp
```

## Validate

```bash
./scripts/validate.sh
```

## Repository layout

| Path | Role |
| --- | --- |
| `AGENTS.md` | Instructions for maintaining this repository |
| `SPEC.md` / `ROADMAP.md` / `TASKS.md` | This kit's own planning docs |
| `.agents/skills/` | Reusable skills |
| `codex-home/` | Portable Codex configuration and rules |
| `claude-home/` | Portable Claude Code global instructions |
| `grok-home/` | Portable Grok notes and project instruction hints |
| `templates/project-docs/` | Files copied by `bootstrap-project.sh` |
| `docs/` | Reference docs (loaded only when requested) |
| `scripts/` | Install, bootstrap, and validation |
| `codex-plugins.txt` | Opt-in Codex plugin selectors |
| `skill-categories.txt` | Skill category names and descriptions |

## Pull updates

```bash
cd ~/coding/agent-rules
git pull
./scripts/install.sh
```

Then re-bootstrap a project only if you want template updates (existing project
docs are preserved unless you pass `--force`).
