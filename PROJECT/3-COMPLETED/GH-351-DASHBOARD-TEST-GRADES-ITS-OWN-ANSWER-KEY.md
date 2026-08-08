---
gh_issue: 351
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351
title: "GH-351 — the registered dashboard test regenerated the artifact and then validated the copy it had just written, so the drift assertion could never fail"
status: "Shipped: test/roadmap-dashboard.sh rewritten, 4 -> 9 cases, and it no longer writes into $ROOT. Proved by replaying the real 719867f stale-dashboard commit: old test 4 pass / 0 fail (green on a stale artifact), new test 6 pass / 3 fail."
created: 2026-07-30
updated: 2026-07-30
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
related:
  - "#348 — same family: a parity test comparing Python to Python"
  - "#342 — same family: sed-extracting helpers from the Bash file it was validating"
  - "#362 (B) — same family, in the freeze guard"
  - "#369 — same family, found the same day in a test I wrote myself"
  - "#350 / #356 — two of the three PRs that landed a stale dashboard under a green gate"
non_goals:
  - "Changing utils/roadmap-dashboard.sh. The renderer and its --check are CORRECT and were never the defect; --check returned rc=1 on every one of the three stale dashboards when run standalone. Touching it would have been fixing the wrong file."
  - "Adding a pre-commit hook or a CI-side regeneration step. The gate the repo already has works once it stops being lied to; a second mechanism would be a second thing to drift."
  - Auto-regenerating the dashboard from the test. That is precisely the defect.
goal: >
  Make the registered gate able to fail. The dashboard checker was already correct; the test
  wrapped around it destroyed its signal by regenerating the artifact first, and silently mutated
  the working tree while doing it.
---

# GH-351 · a gate that graded its own answer key

## Status
| What was just completed | What's next |
|---|---|
| `test/roadmap-dashboard.sh` rewritten: **4 → 9 cases**, `--check` runs first against the committed artifact, write-mode redirected to a temp path, plus a mutation proof and a no-side-effect assertion. | Merge to `development`, then the held `development` → `main` release. |

## The defect, exactly

```bash
out="$(bash "$RENDERER" 2>&1)"; rc=$?          # line 27 — OVERWRITES $ROOT/ROADMAP-DASHBOARD.md
...
out="$(bash "$RENDERER" --check 2>&1)"; rc=$?   # line 34 — checks the file line 27 just wrote
```

Line 34 could not fail. Its `pass` string even read *"--check passes on the committed artifact"* —
which was false: by then the artifact was whatever line 27 had rendered.

**The renderer was never the problem.** Run standalone, `utils/roadmap-dashboard.sh --check`
returned `rc=1` on all three of the day's stale dashboards. The correct signal existed the whole
time; the registered test overwrote its input before asking.

**A second, quieter fault:** the test wrote into `$ROOT`. So `validate.sh` itself silently
un-staled the dashboard mid-run — a suite that repaired the evidence it was meant to judge, and
left the working tree dirty afterwards.

## Why it kept landing

Three stale dashboards reached `development` on 2026-07-30 alone, from three different authors
(mine on GH-342, then #356, then #350). It fires on essentially every PR that edits `ROADMAP.md`
without regenerating, and the only reason it was ever caught was someone running the standalone
checker by hand afterwards.

## The fix

Two rules, and the case ordering is load-bearing:

1. `--check` runs **first**, against the **committed** artifact, before anything in the file writes.
2. Nothing writes `$ROOT/ROADMAP-DASHBOARD.md`. Write-mode is exercised through
   `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported — no renderer change needed.

| Case | Asserts |
|---|---|
| 1 | `--check` passes on the committed artifact, nothing regenerated first — **the gate** |
| 2 | write-mode still works, to a temp path |
| 3 | a fresh render is byte-identical to the committed artifact (independent of `--check`'s rc) |
| 4 | **`--check` FAILS on a drifted artifact** — the mutation proof |
| 5 | `--check` fails on a missing artifact rather than passing vacuously |
| 6 | `--check` fails when `ROADMAP.md` gains an item the dashboard lacks — the real-world direction |
| 7 | the committed artifact is byte-unchanged: this test writes nothing into `$ROOT` |
| 8–9 | banner + section counts (carried over) |

**Case 4 is what keeps this honest.** Cases 1 and 3 are unfalsifiable on their own — a rewritten
version of the same bug would still pass them. Case 4 plants a canary line in a copy and requires
`--check` to reject it.

## Verification — the real commit, not a synthetic fixture

Replayed `719867f` (the #350 merge, where the dashboard was genuinely stale):

| Test | Result on the stale fixture |
|---|---|
| old, as shipped | **4 passed / 0 failed** — green |
| new | **6 passed / 3 failed** — cases 1, 3, 9 |

Two things that only showed up by running it:

- The old test **left `ROADMAP-DASHBOARD.md` modified** in the fixture worktree afterwards —
  the side effect, observed rather than argued.
- **Case 9 (section counts) was already correct in the old file** and still reported green,
  because line 27 regenerated the artifact before it ran. The bug did not merely add a bad
  assertion; it *disabled a good one*. `roadmap=128 dashboard=127` is exactly what it should have
  been saying all along.

## The pattern this belongs to

Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself*, after
#348, #342, #362(B), #351 itself, and #369 — the last of which was in a test **I wrote earlier the
same day**, where a case probed an issue number absent from both trees and so passed against the
code it existed to catch. The recurring lesson is not "write more tests" but **run the new test
against the old code**; every one of these was caught that way and none by review.
