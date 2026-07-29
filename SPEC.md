# agent-rules specification

## Problem

Coding agents need consistent global rules and reusable skills across machines
and projects. Without a portable kit, every new repository starts from scratch
and agents reinvent workflows.

## Users

- Primary: the repository owner using Codex, Claude Code, and/or Grok on Linux.
- Secondary: any collaborator who clones this kit and runs the installer.

## Required behavior

- Install portable Codex configuration, rules, and skills with a dry-run mode.
- Optionally install the same skills into Claude and Grok skill directories.
- Discover Git worktrees under `~/coding` and `~/github` for Codex trust.
- Bootstrap `AGENTS.md`, `SPEC.md`, `ROADMAP.md`, and `TASKS.md` into projects
  without overwriting existing files by default.
- Validate repository layout, skill front matter, scripts, and installer
  behavior with `./scripts/validate.sh`.
- Keep credentials, sessions, history, and caches out of the repository.

## Non-goals

- Shipping vendor-specific product skills (homelab, Hugo, Forgejo, etc.).
- Managing secrets or API keys.
- Replacing project-specific architecture docs.

## Acceptance criteria

- `./scripts/install.sh --dry-run` prints planned actions and exits 0.
- `./scripts/test-install.sh` passes in an isolated temporary home.
- `./scripts/bootstrap-project.sh` creates planning docs in an empty directory.
- `./scripts/validate.sh` passes.
- Skills under `.agents/skills/*/SKILL.md` have valid YAML front matter and
  names matching their directories.
