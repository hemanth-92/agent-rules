# Repository instructions

## Scope

This repository is the source of truth for portable coding-agent configuration,
reusable skills, and durable AI development workflow docs. Root `AGENTS.md`
follows the AGENTS.md convention for tools that load it automatically.

## Operating principles

- Working code only. Plausibility is not correctness; verify before reporting
  done.
- Never fabricate file paths, APIs, commit hashes, command output, or test
  results. Read the file, run the command, or say what is unknown.
- Say when a premise appears wrong before implementing around it.
- Ask before proceeding only when a request has multiple plausible
  interpretations and the choice materially affects the result.
- Touch only what the task requires. Avoid drive-by refactors, formatting, or
  cleanup.
- Keep communication direct and concise. Skip flattery, filler, ceremonial
  openings, and emoji.

## Command execution

- Use `rtk` when command output is likely to be large or repetitive and a
  filtered summary is sufficient (tests, builds, linters, logs, broad searches,
  dependency listings, infrastructure status).
- Use raw commands when output should be short, exact or complete output
  matters, or the command inspects a specific file or narrowly scoped result.
- In command chains, apply `rtk` only to segments that benefit from filtering.
- If RTK hides needed detail or complicates debugging, rerun the command raw.
- Prefer running code, tests, linters, and type checks over guessing.
- Read complete errors, logs, and stack traces before fixing them.

## Before editing

- State the plan or success criteria before editing. For non-trivial work,
  include the verification you expect to run.
- Read the files you will touch and the nearby callers, consumers, or docs that
  define their behavior.
- Match existing project patterns, naming, layout, and style.
- Resolve ambiguity by reading code or running commands when practical; surface
  assumptions when they affect the result.

## Editing

- Use simple ASCII punctuation unless a file format requires otherwise.
- Keep credentials, tokens, sessions, history, caches, logs, and runtime
  databases out of this repository.
- Put reusable workflows in `.agents/skills/<name>/SKILL.md`.
- Put portable Codex configuration in `codex-home/`.
- Put portable Claude instructions in `claude-home/`.
- Put project doc templates in `templates/project-docs/`.
- Put project maintenance instructions in this file.
- Do not assume files in `docs/` are loaded automatically.
- Use the minimum change that solves the stated problem.
- Do not add speculative features, abstractions, or hooks.
- Clean up orphans created by your own change.
- Do not delete pre-existing dead code unless asked.

## Documentation routing

Read only the documents needed for the task:

- `SPEC.md` for product requirements, boundaries, and acceptance criteria.
- `ROADMAP.md` for ordered outcomes, risks, and phase exit criteria.
- `TASKS.md` for the current phase, validation status, and remaining work.
- `docs/LAYOUT.md` for discovery and installation boundaries.
- `docs/SKILLS.md` when creating or changing skills.
- `docs/WORKFLOW.md` when changing the development workflow.

## Verification

- Run the smallest meaningful verification during iteration and the requested or
  relevant final verification before reporting done.
- If verification fails, fix the cause instead of weakening the check.
- Run `./scripts/validate.sh` after changing configuration, skills, install
  scripts, or repository layout.
- Run `./scripts/test-install.sh` when diagnosing installer behavior.

## Maintenance

- Keep this file short enough to follow. Add rules only when they prevent a real
  repeat mistake or document durable project behavior.
- When the user corrects an approach, tighten the relevant rule instead of
  appending a vague warning.
