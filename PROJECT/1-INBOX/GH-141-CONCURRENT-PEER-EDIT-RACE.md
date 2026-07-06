---
gh_issue: 141
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141
title: "Containment: rtl_enforce's pre-turn dirty snapshot can't see a concurrent peer session's edit that lands mid-turn, reverting it as off-lane"
status: Not yet scoped/started — PDDA 1-INBOX intake
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: bugfix
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
---

# GH-141 — concurrent peer-session edit reverted as off-lane

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

Not yet scoped — no fix direction has been chosen or rated. Whichever direction is picked needs:
- A concrete before/after test in `test/agy-turn.sh` (or a new file) that reproduces this exact race
  deterministically (inject a peer-session-style edit mid-turn, not just pre-turn) and shows it
  survives.
- Confirmation that `test/agy-turn.sh` case (8)'s pre-existing-WIP protection is unaffected.
- `bash validate.sh` green.

## Swarm Preflight Contract

> Fix direction not yet chosen (see Candidate fix directions). Leading candidate encoded below:
> re-snapshot `git status --porcelain` immediately before the final off-lane scan and diff against
> a live re-check. Preflight may report this NOT marathon-ready until the direction is ratified —
> that is the honest state.

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_present","path":"relay-automation/relay-turn-lib.sh","pattern":"RTL_BEFORE"}],"artifacts":["relay-automation/relay-turn-lib.sh","test/agy-turn.sh"],"remediation":{"source":"self#definition-of-done","criteria":"A deterministic before/after test (in test/agy-turn.sh or a new file) injects a peer-session-style edit MID-turn and shows it survives rtl_enforce; case (8) pre-existing-WIP protection still passes; bash validate.sh green."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh"]}}
```
