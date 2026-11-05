---
gh_issue: 1346
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1346
title: "feat(skills): chain close-the-loop and todo-list with non-blocking PARKED/blocker skip ladder"
status: "Working — PR ready; /relay-xyz QA Approved"
created: 2026-11-05
updated: 2026-11-05
owner: Antigravity
goal: "Chain close-the-loop and todo-list with non-blocking skip/PARKED deferral and end-of-sequence reminder"
branch: feat/XYZ-forge-gh1346-close-loop-todo-2026-11-05
doc_type: feature
effort: 1
complexity: 1
risk: 1
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| `/relay-xyz` QA with Claude Code Fable (`claude-fable-5-1`, `--effort low`) Approved in Round 2 (`c3db79ff9bf4`). | Open PR into `development`, merge, and reconcile. |

## Observed problem and bet

Previously, `/close-the-loop` stopped at a read-only report (`skills/2-daily/close-the-loop/SKILL.md:63`), and `/todo-list` halted the entire queue on the first hard blocker (`skills/2-daily/todo-list/SKILL.md:122`). When an operator ran a session sweep before stepping away, a single blocked item stopped all subsequent independent follow-ups from finishing.

**Bet (Easy to reverse):** Chain `close-the-loop` (`--execute`) and `todo-list` (`--close-the-loop`) at their seam while delegating blocker evaluation and deferral to existing skills (`sanity-check`, `workhorse` Rung 0, `unstuck`, and `PARKED/README.md`) with zero duplicate machinery.

## Scope & Implementation

1. `skills/2-daily/close-the-loop/SKILL.md`:
   - Preserve default report-only contract for bare `/close-the-loop`.
   - Add `## Execute mode (--execute / chain into todo-list)` that filters `confirmed pending` items and pipes them into `skills/2-daily/todo-list/SKILL.md`.
2. `skills/2-daily/todo-list/SKILL.md`:
   - Add chained discovery in Section 1 (`--close-the-loop`), plus `[p]` (`parked/deferred to PARKED/`) status alongside `[ ] / [-] / [x] / [!]`.
   - Update Section 2.3 (`handsfree` wake prompt) and Section 3 so blocked or deferrable items are assessed via `sanity-check` and `workhorse` Rung 0, deferred to `<repo-root>/PARKED/YYYY-MM-DD-<scope>.md` (`[p]`) or marked `[!]` when externally blocked, and skipped so remaining independent `[ ]` items finish first.
   - Emit a dedicated **Blocked (`[!]`) & Deferred (`[p]` in `PARKED/`) Reminder** at the end of the sequence.

## Acceptance

- [x] `skills/2-daily/close-the-loop/SKILL.md` and `skills/2-daily/todo-list/SKILL.md` cross-link cleanly and all relative paths resolve.
- [x] `/relay-xyz` QA turn with Claude Code Fable (`claude-fable-5-1`, low effort) passes (`STATUS: Approved`, attested on `c3db79ff9bf4`).
- [ ] PDDA and Small-tier checks pass; PR opened and merged into `development`.

## Lessons Learned (For Future Agents)

- Keep `PARKED/` strictly for incidental/low-risk deferred items (`[p]`) while keeping concrete external blockers on required work visible as `[!]` in the active checklist, preserving `PARKED/README.md` and `AGENTS.md` invariants while still unblocking subsequent independent tasks.
