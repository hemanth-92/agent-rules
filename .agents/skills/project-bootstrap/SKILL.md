---
name: project-bootstrap
description: Scaffold or refresh AI project planning docs (AGENTS.md, SPEC.md, ROADMAP.md, TASKS.md) for a repository using agent-rules templates. Use when starting a new project, adding agent docs to an existing repo, or reconciling missing planning files.
category: workflow
---

# project-bootstrap

## Workflow

1. Inspect the target repository root, existing planning docs, and toolchains.
2. Prefer the local installer script when this kit is available:

   ```bash
   /path/to/agent-rules/scripts/bootstrap-project.sh .
   ```

3. If the script is unavailable, create or adapt files from the skill assets or
   the repository's `templates/project-docs/` copies.
4. Fill in real project purpose, commands, and validation. Remove irrelevant
   sections instead of leaving placeholders.
5. Confirm `AGENTS.md` documentation routing points at the planning files that
   exist.
6. Summarize created vs skipped files and any open product decisions.

## Diagnostics

```bash
git rev-parse --show-toplevel
rg --files -g 'AGENTS.md' -g 'SPEC.md' -g 'ROADMAP.md' -g 'TASKS.md'
ls templates/project-docs 2>/dev/null || true
```

## Safety Rules

- Never overwrite existing planning docs unless the user requests force replace.
- Never invent product requirements; mark unresolved questions instead.
- Keep secrets and environment-specific tokens out of planning docs.
- Prefer project-local commands discovered from the repo over generic guesses.

## Validation

- Required files exist at the repository root (or agreed location).
- `AGENTS.md` routes to SPEC/ROADMAP/TASKS when present.
- Placeholder sections are either filled or removed.
- Final summary lists created, skipped, and adapted files.
