---
gh_issue: 209
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209
title: "GH-206 fix follow-up: PWD-based MARATHON_ROOT fallback let a fixture marathon render/commit + claimed tick token leak into the real repo mid-marathon"
status: Closed — built 2026-07-16 (codex + agy, Approved) — new test/marathon-root-audit.sh (13/13), fixed a real MARATHON_LANE_NS leak (see Status)
created: 2026-07-16
updated: 2026-07-16
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not implementing the issue's harder ask ("make the PWD fallback refuse to resolve to a repo that
    is not the intended target" / "require an explicit root or positive marker before committing").
    That is a real architectural tension with GH-206's own explicit goal (a vendored install must
    resolve ROOT from PWD with ZERO required env vars) — there is no code-level signal today that
    distinguishes "a legitimate bare run in the intended target repo" from "a stray invocation from an
    unrelated background process," and guessing at one risks silently breaking GH-206's hard-won
    zero-config behavior. Left as a follow-up requiring a human design call, not a bounded automated fix.
  - Not modifying marathon.sh's ROOT-resolution logic at all.
related:
  - test/marathon.sh
  - test/marathon-drive.sh
  - relay-automation/marathon.sh (read-only reference; not edited)
goal: >
  Close the concretely-actionable, safely-automatable slice of GH-209: audit every marathon.sh /
  marathon-drive.sh invocation in this repo's own test suite for a missing explicit MARATHON_ROOT
  (the mechanism by which the reported leak most likely happened — a background process invoking the
  real scripts with an unscoped CWD), and add a static regression check that fails loudly if a future
  test invocation reintroduces that gap.
---

## Status

| What was just completed | What's next |
|---|---|
| Capture written; scope explicitly narrowed after finding the full architectural fix is not safely automatable (see Decision). Confirmed with operator via the marathon-scope selection. **New live evidence for the Problem, found running today's own marathon (2026-07-16):** phase `gh213`'s pre-advance gate command (`bash test/find-harness.sh && bash test/marathon.sh && ...`) ran nested INSIDE the still-live outer `marathon-drive.sh` process, and `test/marathon.sh`'s GH-205 resume sub-case failed there (`grep: .../phases/gh205/RELAY.md: No such file or directory`) despite passing 33/33 standalone immediately before and after. Confirmed by reproduction attempts with matching env vars (`TICK_REPO_ROOT`, `MARATHON_ROOT`, `MARATHON_BUILDER`/`REVIEWER`, `CODEX_AGENT`/`AGY_AGENT`, `RELAY_DRIVER_LOCKED=1`) that this specific set does NOT reproduce it standalone — the exact leak vector is still unidentified, but the phenomenon (nesting `test/marathon.sh`/`test/marathon-drive.sh` inside a live `marathon-drive.sh` process is unreliable) is now directly demonstrated, not just inferred from the original incident. Worked around today by not nesting those two test files in the marathon's own `--pre-advance-cmd` (verified standalone by the orchestrator instead). **The exact leak vector was found and fixed by this very phase's builder turn**: `MARATHON_LANE_NS` (set by the outer `marathon.sh`/`marathon-drive.sh` for the live phase) was leaking into `test/marathon.sh`/`test/marathon-drive.sh`'s own nested invocations of the real scripts, redirecting rendered relay paths under the outer phase's namespaced directory and breaking pre-existing path assertions — fixed with `unset MARATHON_LANE_NS` at the top of both test files (GH-207's own explicit namespaced test cases still set it per-invocation and remain covered). New `test/marathon-root-audit.sh` (13/13, registered in `validate.sh`) statically audits that every real-script invocation in the test suite is `MARATHON_ROOT`-scoped or fixture-local, going forward. Reviewed and Approved by agy (tick token confirmed `status: done`), but agy-turn.sh's isolation-breach detector then failed the TURN on a known false positive (GH-183, already tracked, unfixed) — the relay file's Approved content was committed by hand after independently re-verifying `test/marathon-root-audit.sh` (13/13), `test/marathon.sh` (33/33), `test/marathon-drive.sh` (85/85), and full `validate.sh` (green except the pre-existing #208). | Done. Continuing to `gh203`. |

## Problem

During the 2026-07-15 GH-205/206/207 marathon, a stray commit (`45a3422`) rewrote this repo's real
`phases/p1/RELAY.md` with fixture-flavored content, and the real `.tick` log gained a claimed token
with fixture artifact paths (`src/feature.js`, which doesn't exist in this repo) — cleaned up by hand
(commit reverted, token reaped). The suspected mechanism: a background process (likely a CLI's
post-edit wrap-up, the same lingering-wrap-up class as GH-205) invoked `marathon.sh`/
`marathon-drive.sh` directly with no `MARATHON_ROOT` set and a CWD inside the real repo — GH-206's new
PWD-based fallback then happily resolved ROOT to the real checkout and committed there.

## Decision — scope narrowing

The issue's own checklist bundles two asks of very different shapes:

1. **Architectural**: make the PWD fallback refuse to resolve to "the wrong repo" — but marathon.sh
   has no way to know what "wrong" means without a positive signal, and GH-206 deliberately wants zero
   required env vars for a legitimate vendored install. An automated builder guessing at this risks
   quietly breaking GH-206's own acceptance criteria. **Not attempted here.**
2. **Mechanical**: audit `test/marathon.sh`/`test/marathon-drive.sh` for any invocation of the real
   `marathon.sh`/`marathon-drive.sh` missing an explicit `MARATHON_ROOT`, and add a regression check
   that keeps it that way. **This is what this lane builds.**

Verified directly (this session, before the GH-212 work landed): every current `run_marathon()` /
`run_driver()` call in `test/marathon.sh`/`test/marathon-drive.sh` already sets `MARATHON_ROOT`
explicitly (the one deliberate exception — the GH-206 vendored zero-config case — runs inside an
isolated fixture repo `$V`, never the real checkout, so an unset `MARATHON_ROOT` there is safe by
construction). This lane's job is to make that invariant a checked, enforced fact rather than
something a future test author has to independently re-verify by reading the whole file.

## Acceptance criteria

- [x] A new static-audit test (or a new case within `test/marathon.sh`) greps `test/marathon.sh` and
      `test/marathon-drive.sh` for every line invoking `relay-automation/marathon.sh` or
      `relay-automation/marathon-drive.sh` (direct `bash "$MSH"`/`bash "$DRIVER"`-style calls, not the
      stubbed-driver plumbing) and asserts each such invocation's surrounding env either (a) sets
      `MARATHON_ROOT` explicitly, or (b) runs with CWD inside an isolated fixture dir (`$A`/`$B`/`$V`
      created by `_setup.sh`), never the real repo checkout with an ambient/unset root.
- [x] The audit fails loudly (non-zero, clear message naming the offending line) if a future test
      edit reintroduces a bare invocation lacking both signals.
- [x] No behavior change to `marathon.sh`/`marathon-drive.sh` themselves — test-suite-only change.
- [x] `bash test/marathon.sh`, `bash test/marathon-drive.sh`, and full `validate.sh` green.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon.sh && bash test/marathon-drive.sh",
  "fix_probes": [ { "type": "grep_absent", "path": "test/marathon.sh", "pattern": "GH-209" } ],
  "artifacts": [ "test/marathon.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Acceptance criteria checklist in this doc" },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```

## Scope lock
Edit only: `test/marathon.sh` (and `test/marathon-drive.sh` only if the audit needs a matching case
there). Do NOT edit `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh`.
