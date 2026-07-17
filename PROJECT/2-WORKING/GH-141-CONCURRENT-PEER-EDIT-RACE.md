---
gh_issue: 141
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141
title: "Containment: rtl_enforce's pre-turn dirty snapshot can't see a concurrent peer session's edit that lands mid-turn, reverting it as off-lane"
status: Active (2-WORKING) — promoted 2026-07-17 by /10days (11-14 day sweep); confirmed still unfixed via fix-probe polarity check (RTL_BEFORE porcelain-snapshot mechanism unchanged), distinct from the separately-shipped GH-13/GH-140 concurrent-commit hardening
created: 2026-07-05
updated: 2026-07-17
owner: noel
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
non_goals:
  - Not a fix for GH-140 (non-atomic worktree copyback corrupting a live-executing script) -- a
    different mechanism, already shipped separately.
  - Not a redesign of the containment model -- this is a genuine multi-session concurrency hazard,
    not a logic bug in rtl_before/rtl_was_dirty_before (which do exactly what they're documented to
    do: protect PRE-EXISTING ambient WIP, a case test/agy-turn.sh already covers and still passes).
related:
  - relay-automation/relay-turn-lib.sh
  - test/agy-turn.sh
  - PROJECT/3-COMPLETED/GH-140-CONTAINMENT-ATOMIC-COPYBACK.md
goal: >
  Determine whether rtl_enforce's off-lane revert can be made safe for a concurrent peer session's
  mid-turn edit without weakening its documented GH-22 self-escape backstop, and if not, hand off
  the two viable non-detection mitigations for an operator decision.
---

# GH-141 — concurrent peer-session edit reverted as off-lane

## Status

| What was just completed | What's next |
|---|---|
| **Investigated 2026-07-17 by `/10days` Wave 2 — no fix shipped, and that's the correct outcome** (see Definition of done below): no code-only signal in this codebase can distinguish a peer session's concurrent edit from the agent's own off-lane self-escape (both produce byte-identical porcelain diffs), and a naive fix would silently disable `rtl_enforce`'s documented backstop against the already-exploited GH-22 self-escape vector. | Still open, still not marathon-ready. Two non-detection follow-ups recorded for an operator decision: a recoverable backup-before-revert, and documenting the don't-hand-edit-a-live-clone constraint. |

## Bug

`rtl_before()` snapshots `git -C "$RTL_ROOT" status --porcelain` **once, at turn start**, into
`RTL_BEFORE`, so `rtl_enforce`'s later off-lane scan can exempt "pre-existing ambient WIP" via
`rtl_was_dirty_before()` (exact porcelain-entry string match). This correctly protects WIP that
already existed *before* the turn began (covered by `test/agy-turn.sh` case (8), `ambient.md`).

It does **not** cover a second, independent session's edit that lands **during** the turn's
execution window (a worktree-isolated turn can run for tens of seconds to minutes): the path was
clean at snapshot time, becomes dirty while the turn is still running, and `rtl_enforce`'s final
scan sees a porcelain entry with no match in `RTL_BEFORE` — indistinguishable, by this mechanism,
from an off-lane edit the agent itself made. `rtl_check()` then reverts it directly in `$RTL_ROOT`
via `git checkout --` (or `rm -rf` for an untracked path).

## Evidence (2026-07-05)

Live incident: drove a review-only agy turn (`ALLOW_PATHS=""`) via `relay-drive.sh --review-once`
while a second, independent Claude Code session was concurrently hand-editing
`PROJECT/1-INBOX/PEER-RESEARCH.md` (a tracked file, committed empty, with an uncommitted single-line
URL written into it) directly in the same working directory. The turn's containment enforcement
reverted that file back to its committed-empty state in the real `$RTL_ROOT` — not just an isolated
worktree copy — destroying the peer session's in-progress edit. Recovered by hand in the same
session (the exact byte content was still visible in recent scrollback via `git diff`); not
recoverable in general, since nothing else captures a reverted peer edit before `rtl_check` discards
it.

## Scope / severity

Real but narrow: requires two things simultaneously — (a) a driven relay/marathon turn running, AND
(b) a second live session hand-editing an off-allowlist path in the exact same clone during that
turn's wall-clock window. Not self-triggering; the same family of hazard as the already-known
"concurrent commits" race (`rtl_enforce`'s commit-bypass guard), but for uncommitted hand-edits
instead of commits.

## Candidate fix directions (none chosen yet)

- Re-snapshot `git status --porcelain` immediately before the final off-lane scan too, and diff
  against a live re-check rather than trusting only the turn-start snapshot — narrows the race
  window but can't close it (an edit landing in the last few hundred ms is still unprotected).
- A repo-level advisory lock file (beyond the existing `.git/relay-driver.lock`, which only guards
  concurrent *drivers*, not arbitrary hand-edits) that a peer session is expected to respect — a
  usage-convention change, not purely a code fix.
- Document the constraint explicitly (`ROUTER.md` / `relay-xyz` `SKILL.md`): don't hand-edit files
  in a clone while a headless relay/marathon turn is in flight there — same class of guidance as the
  existing "don't commit concurrently" note.

## Definition of done

**Investigated 2026-07-17 by `/10days` Wave 2 — no fix shipped, and that's the correct outcome.**
The "re-snapshot right before the revert" candidate above doesn't actually close the gap:
`rtl_enforce` already reads a live, fresh `git status` immediately before invoking `rtl_check`; the
real gap is the whole turn-execution window between `rtl_before` and `rtl_enforce`, which can't be
narrowed away without re-running the turn. More fundamentally, **no code-only signal in this
codebase can distinguish "a peer session's concurrent edit" from "the agent's own off-lane
self-escape"** — both produce byte-identical porcelain diffs. `rtl_worktree_end`'s own GH-22 comment
and `rtl_turn_prompt`'s residual-gap note explicitly document that a real observed agent (agy) *can*
construct an absolute path back into `RTL_ROOT` and write there directly even while worktree-isolated
— `rtl_enforce`'s off-lane revert (the exact mechanism this bug is about) is the documented backstop
for that self-escape. Any fix of the shape "don't revert a newly-dirty non-allowlisted path" would
silently disable protection against that already-exploited vector — a real containment regression,
not a false-positive fix. Building a genuine attribution signal (PID/process, not a file-content
heuristic) is the "redesign of the containment model" this doc's own non_goals rule out.

**Recommended next steps (not implemented — for an operator decision, not an automated one):**
1. **Recoverability-only mitigation (low risk, additive):** before `rtl_check()` discards an
   off-lane path, back up its pre-revert content to a recoverable side-location, mirroring the
   existing `refs/relay-orphan/<sha>` pattern already used for the moved-HEAD case. This doesn't
   change any revert/preserve decision — it just makes a wrongly-caught peer edit recoverable
   instead of "not recoverable in general" as today.
2. **Documentation, not detection:** state the constraint explicitly in `ROUTER.md` / the
   `relay-xyz` `SKILL.md` — don't hand-edit a clone while a driven relay/marathon turn is in flight
   there. The only approach that prevents the race rather than trying to detect it post-hoc.

Whichever direction is picked needs:
- A concrete before/after test in `test/agy-turn.sh` (or a new file) that reproduces this exact race
  deterministically (inject a peer-session-style edit mid-turn, not just pre-turn) and shows it
  survives.
- Confirmation that `test/agy-turn.sh` case (8)'s pre-existing-WIP protection is unaffected.
- `bash validate.sh` green.

## Swarm Preflight Contract

> **Still not marathon-ready as of 2026-07-17** — investigated, not fixed (see above). No safe
> code-only fix direction exists yet; the two recommended next steps are an operator decision, not
> an automated one. Leave this contract as a placeholder until one is ratified; do not fire this
> issue again without a chosen direction.

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"relay-automation/relay-turn-lib.sh","pattern":"RTL_ORPHAN_BACKUP"}],"artifacts":["relay-automation/relay-turn-lib.sh","test/agy-turn.sh"],"remediation":{"source":"self#recoverability-mitigation","criteria":"NOT YET RATIFIED — placeholder pointing at recommended next step 1 (recoverability-only backup before rtl_check's revert) only. An operator must choose between the two recommended next steps above before this contract is treated as fireable."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh"]}}
```

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_present","path":"relay-automation/relay-turn-lib.sh","pattern":"RTL_BEFORE"}],"artifacts":["relay-automation/relay-turn-lib.sh","test/agy-turn.sh"],"remediation":{"source":"self#definition-of-done","criteria":"A deterministic before/after test (in test/agy-turn.sh or a new file) injects a peer-session-style edit MID-turn and shows it survives rtl_enforce; case (8) pre-existing-WIP protection still passes; bash validate.sh green."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh"]}}
```
