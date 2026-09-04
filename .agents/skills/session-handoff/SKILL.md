---
name: session-handoff
description: Maintain a bounded per-project SESSIONS.md so a fresh session starts with full working context instead of resuming a long transcript. Use at the start of a session to load prior context, at the end to record state, when asked to continue previous work, catch up, hand off, or check where things were left, and whenever a decision, dead end, or in-flight state would otherwise be lost when the session ends.
category: workflow
---

# session-handoff

Resuming a transcript replays every token of the old session, including the
exploration that led nowhere. A written handoff replaces that with a bounded
summary, so a fresh session starts cheap and focused.

The trade is real: a handoff is lossy. Anything not written down is gone, and
`--resume` would have kept it. That is the point - most of a finished session is
noise - but it means the value of this skill is entirely in what gets recorded
at the end, not in the mechanism.

Two things carry context between sessions. Use both, and do not duplicate them:

| Source | Holds | Cost to read |
| --- | --- | --- |
| `git log` / diff | what changed, mechanically | cheap, already exists |
| `SESSIONS.md` | why, what failed, what is in flight | bounded by the rules below |

Never write into `SESSIONS.md` what git already records. A file list or a
summary of a diff is waste; the reasoning behind it is not.

## The file

One `SESSIONS.md` at the repository root, committed. Git history then holds
every prior state of the handoff itself, which is what makes aggressive
compaction safe.

```markdown
# Session log

## Current state

Updated: <date> (session <n>)

- Working on: <the one task in flight>
- Status: <what works and what does not, right now>
- Next step: <the exact next action, specific enough to start cold>
- Blocked by: <blocker, or none>
- Do not retry: <approaches already ruled out, and why>

## Decisions

- <date> Chose <X> over <Y> because <reason>. Revisit if <condition>.

## Sessions

### <date> - session <n>
- Goal: <what this session set out to do>
- Outcome: <what actually happened>
- Learned: <non-obvious findings worth keeping>
- Left open: <unfinished threads>

### <date> - session <n-1> (compacted)
<one line>
```

`Current state` is overwritten every session, never appended to. `Do not retry`
is the highest-value field: dead ends are expensive to rediscover and git
records nothing about them.

## Start of session

1. Read `Current state` and `Decisions`. That is roughly 40 lines and is
   normally enough to begin.
2. Run `git log --oneline -15` and check the working tree for uncommitted
   changes. Reconcile against `Next step`.
3. Read individual `Sessions` entries only when the current task needs that
   history. Do not read the whole log by default.
4. Say what you understood the state to be before acting, so a stale handoff is
   caught before it misleads the work.

## End of session

Update the file before the session ends, not after work stops being fresh.

1. Overwrite `Current state` so `Next step` is specific enough to act on cold.
   "Continue the parser" is useless; "add the escape-sequence case to
   `tokenize()` at src/lex.rs:88, test fixture already written" is not.
2. Append one `Sessions` entry, at most about eight lines.
3. Add any decision that constrains future work to `Decisions`.
4. Move anything durable out of the log and into the doc that owns it, then
   delete it from the log:

   | Content | Belongs in |
   | --- | --- |
   | a convention or rule for future work | `AGENTS.md` |
   | a requirement or acceptance criterion | `SPEC.md` |
   | phase order or exit criteria | `ROADMAP.md` |
   | a task and its validation status | `TASKS.md` |

   `SESSIONS.md` is a staging area, not an archive. Content that has a
   permanent home is a bug in the log.

## Keep it bounded

An unbounded journal recreates the problem it was written to solve. Enforce
this every session:

- Keep the last five session entries in full. Compact every older entry to a
  single line, or delete it if its content was promoted.
- Target under about 200 lines total. If it exceeds that, compact rather than
  letting it grow.
- One task in flight at a time. A `Current state` listing four parallel threads
  means the work was not scoped to one session.
- Drop `Do not retry` items once the surrounding code changes enough that the
  approach deserves another look.

## Do not record

- Credentials, tokens, keys, connection strings, or private data.
- Diffs, file inventories, or commit summaries that `git log` already gives.
- Narrated activity ("read three files, ran the tests"). Record conclusions.
- Speculation about future work that has not been decided.

## Anti-patterns

- **Append-only journal.** Nothing is ever compacted; by session twenty the file
  costs more than the transcript did.
- **Writing it at the end of a dead session.** Context is already lost. Update
  `Current state` as decisions land, not only at shutdown.
- **Duplicating `TASKS.md`.** Task status lives there. The log holds why and
  what failed.
- **Vague next step.** If it cannot be started without rereading the code, it
  was not written well enough.

## Checklist

- [ ] `SESSIONS.md` exists at the repo root and is committed.
- [ ] `Current state` was overwritten this session, not appended to.
- [ ] `Next step` is specific enough to start cold.
- [ ] Dead ends recorded under `Do not retry`.
- [ ] Durable content promoted to its owning doc and removed from the log.
- [ ] Entries older than the last five compacted to one line.
- [ ] File is under about 200 lines.
- [ ] No credentials or private data recorded.
