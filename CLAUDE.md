# Project instructions

Read and follow `AGENTS.md` before planning or changing this repository. Use its
documentation routing to load `SPEC.md`, `ROADMAP.md`, `TASKS.md`, or files
under `docs/` only when the task requires them.

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

Use `rtk` only when command output is likely to be large or repetitive and its
filtered result is sufficient. Typical candidates are test suites, builds,
linters, logs, broad searches, dependency listings, and infrastructure status
commands.

Keep commands raw when their output should be short, exact or complete output
matters, or the command inspects a specific file or narrowly scoped result. In
command chains, apply `rtk` only to segments that benefit from filtering. If
RTK hides needed detail or complicates debugging, rerun the command raw.

Do not use `rtk proxy` merely to add an RTK prefix without filtering.

## High-value RTK commands

```bash
# Build / lint
rtk cargo build
rtk cargo clippy
rtk cargo test
rtk pytest
rtk ruff check .

# Git
rtk git status
rtk git log
rtk git diff

# Meta
rtk gain
rtk summary <cmd>
rtk err <cmd>
```

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->
