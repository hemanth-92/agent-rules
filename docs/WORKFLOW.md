# AI development workflow

## Project file roles

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Durable instructions the coding agent loads automatically |
| `SPEC.md` | Product and technical requirements and acceptance criteria |
| `ROADMAP.md` | Ordered outcomes, dependencies, risks, and exit criteria |
| `TASKS.md` | Current actionable work and validated status |
| `.agents/skills/` | Reusable workflows agents can invoke |
| `docs/` | Reference material loaded only when requested or linked |

## Complete lifecycle

1. Install this repository's global instructions, configuration, rules, and
   reusable skills.
2. Bootstrap planning docs into the target project when missing.
3. Inspect the real repository, branch, worktree, architecture, and validation.
4. Put durable project conventions and boundaries in `AGENTS.md`.
5. Define observable requirements, non-goals, and acceptance criteria in
   `SPEC.md`.
6. Order outcomes, risks, exit criteria, and validation in `ROADMAP.md`.
7. Break the current phase into reviewable work in `TASKS.md`.
8. Use `$ai-project-manager` to produce a requirement-linked plan with automated
   and manual validation.
9. Stop for plan approval when the user reserved that checkpoint.
10. Implement one approved phase, run focused checks, and inspect the diff.
11. Run the complete local gate and update task status only after it passes.
12. Use `$pr-readiness` for final review, optional CodeRabbit, CI, and merge
    readiness.
13. Commit, push, and open a draft PR only when authorized.
14. Merge only after the final diff, planning documents, CI, reviews, threads,
    and manual tests are clean.

## Session and context management

- **Keep tasks simple and self-contained**: Scope each unit of work to have low
  dependencies on other tasks or components.
- **One task per session**: Limit each agent session to a single task or
  milestone to avoid overwhelming the agent and prevent rapid token expense
  rate growth as context expands.
- **Milestone planning in markdown**: When a task is too complex for one
  session, write a milestone-based plan to a markdown file (`TASKS.md` or a
  dedicated planning document).
- **Context handoff via plan and Git history**: For subsequent milestones, open
  a fresh session and provide the markdown plan file plus Git commit history as
  context instead of carrying over unbounded conversational history.

## Security baseline

Establish the security checks that apply to the repository:

- Enable secret scanning and push protection where available.
- Keep dependencies updated and review dependency changes when manifests change.
- Document accepted exceptions with a reason, owner, and review date.

## Documentation rule

Do not rely on a coding agent discovering arbitrary documents by filename.
Reference supporting documents from `AGENTS.md`, a selected skill, or the task
prompt. Keep the specification, roadmap, tasks, and implementation synchronized
when requirements or architecture change.
