# Skills

Reusable agent skills live under `.agents/skills/<name>/SKILL.md`.

## Skill format

Each skill directory must contain `SKILL.md` with YAML front matter:

```markdown
---
name: example-skill
description: One or two sentences describing when to use the skill.
category: systems
---

# example-skill

## Workflow
...
```

Rules:

- `name` must match the directory name.
- `description` must state when the skill should activate.
- `category` must be exactly one name from `skill-categories.txt`.
- Keep skills reusable; put project-specific knowledge in project docs.
- Optional `agents/openai.yaml` helps Codex skill discovery.

## Categories

Categories are defined in `skill-categories.txt` at the repository root. Each
skill belongs to exactly one, and the installer can select skills by category.

| Category | Scope |
| --- | --- |
| `ai-engineering` | LLM and AI application development |
| `data-engineering` | Data pipelines, ingestion, and transformation |
| `systems` | Shell, Linux operations, and systems-level tooling |
| `workflow` | Project planning, documentation, and review workflow |

## Repository skills

- `ai-project-manager` - workflow
- `bash-scripting` - systems
- `data-pipeline-bdd` - data-engineering
- `incremental-data-load` - data-engineering
- `linux-sysadmin` - systems
- `pr-readiness` - workflow
- `project-bootstrap` - workflow
- `python-ai` - ai-engineering
- `readonly-database-access` - data-engineering
- `rust-cli` - systems
- `session-handoff` - workflow

## Selective install

```bash
./scripts/install.sh --list-categories
./scripts/install.sh --list-skills

# One category into Claude Code
./scripts/install.sh --claude --category data-engineering

# Several categories plus one extra skill
./scripts/install.sh --claude --category data-engineering \
  --category ai-engineering --skill bash-scripting
```

With no `--category` or `--skill`, every skill is installed. Selection is
additive by default: the installer does not remove skills that a previous run
linked, so narrowing a selection does not uninstall the earlier ones.

Add `--prune` to make the selection exact:

```bash
./scripts/install.sh --claude --category data-engineering --prune
```

Pruning removes only symbolic links that point into this repository's
`.agents/skills/`; unmanaged files and directories in the target are untouched.

## Adding a skill

1. Create `.agents/skills/<name>/SKILL.md` with valid front matter, including
   a `category` from `skill-categories.txt`.
2. Add the skill name and its category to the list above (sorted).
3. Run `./scripts/validate.sh`.
4. Document any new install or bootstrap behavior if required.

## Adding a category

1. Add `<name>: <description>` to `skill-categories.txt`.
2. Add the row to the category table above.
3. Assign at least one skill to it and run `./scripts/validate.sh`.
