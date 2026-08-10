# Skills

Reusable agent skills live under `.agents/skills/<name>/SKILL.md`.

## Skill format

Each skill directory must contain `SKILL.md` with YAML front matter:

```markdown
---
name: example-skill
description: One or two sentences describing when to use the skill.
---

# example-skill

## Workflow
...
```

Rules:

- `name` must match the directory name.
- `description` must state when the skill should activate.
- Keep skills reusable; put project-specific knowledge in project docs.
- Optional `agents/openai.yaml` helps Codex skill discovery.

## Repository skills

- `ai-project-manager`
- `bash-scripting`
- `data-pipeline-bdd`
- `linux-sysadmin`
- `pr-readiness`
- `project-bootstrap`
- `python-ai`
- `rust-cli`

## Adding a skill

1. Create `.agents/skills/<name>/SKILL.md` with valid front matter.
2. Add the skill name to the list above (sorted).
3. Run `./scripts/validate.sh`.
4. Document any new install or bootstrap behavior if required.
