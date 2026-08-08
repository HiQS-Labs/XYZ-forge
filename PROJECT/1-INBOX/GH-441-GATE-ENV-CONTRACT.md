---
gh_issue: 441
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441
title: "GH-441 — validate.sh is the default pre-advance gate but is corrupted by the marathon environment it inherits"
status: "Phase 1 SHIPPED 2026-08-07 — the blocker is cleared: `validate.sh` now exits 0 as a pre-advance gate with the flag SET and the lock HELD (acceptance 4 + 5). Phase 2, the env contract that stops this recurring with a DIFFERENT variable (acceptance 1-3), is not started."
created: 2026-08-07
updated: 2026-08-07
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the class, and this release's theme. A gate that cannot fail honestly is not evidence."
  - "#407 — pre-advance-failed reported where the gate never ran. Same reporting surface: both make a gate result mean something it does not."
  - "#401 — --dry-run mutates the tracked tree. The other gate/driver boundary defect in this release."
  - "#375 — also observed live on the same marathon run; unrelated mechanism, same 'the check could not fail' shape."
non_goals:
  - "Scrubbing RELAY_DRIVER_LOCKED GLOBALLY in validate.sh. Measured and reverted: no single value is correct for all ~40 driver-spawning suites, because nested drivers need it set and lock assertions need it unset. Phase 1 scrubs it per-suite instead, inside the two suites whose lock root is already isolated."
  - "Skip lists. Phase 1 is not one: no suite is excluded from the gate, and the two unsets live inside the suites themselves — where the reason is local and documented — not in a list the gate maintains. Replacing a gate-level skip list with a contract is still the Phase 2 goal."
  - "Changing marathon-drive's re-entrancy guard. RELAY_DRIVER_LOCKED is correct for its own purpose."
  - "Fixing the --help ordering defect found alongside this (lock block at marathon-drive.sh:189, --help parsed at :664, so --help refuses to print while a driver is active). Real, but it is a driver change needing Bash+Python twin parity per GH-308; filed separately rather than folded into a test-only fix."
goal: >
  validate.sh is marathon-drive's DEFAULT --pre-advance-cmd, so it routinely runs as a child of a
  live marathon and inherits its environment. RELAY_DRIVER_LOCKED=1 and ALLOW_PATHS each silently
  flip suite verdicts, so the gate reports failures belonging to its parent rather than to the
  change under review. Phase 1 (SHIPPED) cleared the blocker per-suite and validate.sh now exits 0
  in a real gate's environment. Phase 2 is the part that lasts: nothing yet states which variables
  a gate may inherit, so the next export added to marathon-drive can reintroduce this silently.
---

# GH-441 · the gate inherits the state it is supposed to judge

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 — the blocker.** `validate.sh` exits **0** as a pre-advance gate with `RELAY_DRIVER_LOCKED=1` AND the driver lock held (full run 2026-08-07, 0 failing assertions). The fix is two `unset RELAY_DRIVER_LOCKED` lines *inside* `gh284-runlog-heartbeat.sh` and `gh331-cost-summary.sh` — the idiom `test/driver-lock.sh:11` already used for this exact reason. Both suites drive against their own throwaway `$A`, so unsetting per-suite cannot collide with a real lock, which is why this succeeds where the reverted global scrub could not. No suite skipped, nothing scrubbed globally. | **Phase 2 — the contract** (acceptance 1-3). Nothing yet states which variables a gate may inherit, `_gate_env()` is still not the enforcement point, and a custom `--pre-advance-cmd` still has nothing to source. Phase 1 fixed the two variables that are biting *today*; it does not stop the next export from doing the same thing. Not started. |

## The defect

| suite | standalone | with `RELAY_DRIVER_LOCKED=1` |
|---|---|---|
| `test/gh284-runlog-heartbeat.sh` | 20 pass, 0 fail | **15 pass, 5 fail** |
| `test/gh331-cost-summary.sh` | 8 pass, 0 fail | **5 pass, 3 fail** |

`RELAY_DRIVER_LOCKED=1` is exported by `relay-automation/marathon-drive.sh:245` so a nested driver
does not deadlock on the lock its parent already holds — correct for its purpose. Inherited into the
gate, it tells every driver a test spawns that the lock is already held, and the tests asserting
real lock-acquisition behaviour measure the parent instead of themselves.

`test/oracle-guard.sh` fails the same way on an inherited `ALLOW_PATHS` (`marathon-drive.sh:828`):
its "missing `--allow` → usage (exit 2)" assertion finds an ambient path and the guard exits 0.
Measured: ambient → 10/1; unset → 11/0.

## Why it matters

Every affected suite passes standalone, every time. That is the expensive part: a gate failure that
cannot be reproduced by running the same command by hand. On 2026-08-07 this halted the Litmus
marathon twice; `oracle-guard` was re-run 3× standalone (11/0 each) and written off as a load flake
before the variable was found. The first remedy attempted was skipping the affected suites in the
gate — narrowing a gate to make a marathon pass, in the release whose entire theme is that a check
which cannot fail is not evidence.

## The measurement that settles it

`RELAY_DRIVER_LOCKED` is load-bearing in two contradictory directions, so no assignment of it is
correct:

| state | gh284 | gh331 | gh322 | gh268 |
|---|---|---|---|---|
| clean — no flag, no lock | 20/0 | 8/0 | 20/0 | 34/0 |
| flag SET + lock HELD — **what a real marathon produces** | **15/5** | **5/3** | 20/0 | 34/0 |
| flag UNSET + lock HELD — the attempted scrub | fails | — | **17/3** | **31/3** |

**Set**, a nested driver correctly skips a lock its parent holds, but every test asserting real
lock-acquisition measures the parent. **Unset**, those assertions become honest and every nested
driver collides with the held lock instead (`marathon-drive` exits 1). The two requirements are in
direct opposition.

So the statement of the defect is stronger than "some variables leak" — but note carefully what it
rules out. It rules out a **global** assignment: no single value of `RELAY_DRIVER_LOCKED`, applied to
the whole gate, is correct. It does **not** rule out a per-suite one, which is what Phase 1 did.

## Phase 1 — how the blocker was actually cleared

The reverted attempt scrubbed the variable in `validate.sh`, i.e. for all ~40 driver-spawning suites
at once, which is why it broke the ones that need it set. But only **two** suites were ever wrong:
`gh284-runlog-heartbeat` and `gh331-cost-summary`. Both drive against their own throwaway repo (`$A`
from `test/_setup.sh`), so the lock they would acquire is theirs, not the ambient repo's — meaning
they can safely clear the flag *for themselves* while every other suite keeps inheriting it.

That is not a new idea. `test/driver-lock.sh:11` already does exactly this, with a comment naming
this failure mode ("if this test runs UNDER a marathon gate, it would inherit that export and skip
the very logic it's testing"). Phase 1 applies that existing idiom to the two suites that need it.

Measured after the fix — **every cell clean, in both states, simultaneously**:

| suite | flag SET + lock HELD | standalone |
|---|---|---|
| `gh284-runlog-heartbeat` | **20/0** (was 15/5) | 20/0 |
| `gh331-cost-summary` | **8/0** (was 5/3) | 8/0 |
| `gh322-runlog-python-lane` | 29/0 | 29/0 |
| `gh268-relay-cue-and-target-checks` | 34/0 | 34/0 |
| `driver-lock` | 4/0 | 4/0 |
| `oracle-guard` | 11/0 | 11/0 |

And end-to-end, which is the assertion that matters and the one the reverted commit never made:
`RELAY_DRIVER_LOCKED=1` with the driver lock held → **`bash validate.sh` exits 0**, zero failing
assertions across the full suite.

**A second, independent defect surfaced while doing this** and was deliberately not folded in.
`marathon-drive`'s lock block runs at `marathon-drive.sh:189` but `--help` is not parsed until
`:664`, so **`--help` refuses to print whenever any driver is active** — it emits the lock-contention
notice instead. That was masking one `gh284` assertion (a help-text grep, which has no business
touching the ambient lock); the assertion was given its own `MARATHON_ROOT` rather than weakened. The
ordering fix belongs in the driver and needs Bash+Python twin parity (GH-308), so it is filed
separately instead of being smuggled into a test-only change.

## What is fixed, and what is not

Fixed (Phase 1): the two variables biting today, per-suite, with the end-to-end gate run above as
evidence. The `ALLOW_PATHS` half needed no code fix — `validate.sh` already unsets it; the finding
there is that a CUSTOM gate omitting that prologue is silently wrong, which was observed live.

Not fixed — and the reason this doc stays open. **Phase 1 fixed two names; it did not make the
boundary governed.** The next export added to `marathon-drive` can do this again:

1. **No contract.** Nothing states which variables a pre-advance gate may inherit. `marathon-drive`
   exports at least `XYZ_ROOT`, `PYTHONPATH`, `RELAY_DRIVER_LOCKED`, `MARATHON_BUILDER`,
   `MARATHON_REVIEWER`, the four `*_AGENT` vars, `ALLOW_PATHS`, `TICK_REPO_ROOT`. `GATE_SCRUBBED_ENV`
   (`utils/py/marathon_drive.py:1043`) scrubs three: `XYZ_HARNESS_CONTEXT`, `XYZ_SESSION_ID`,
   `MARATHON_LANE_NS`.
2. **The scrub is on the wrong side.** `_gate_env()` builds the gate's environment and is the natural
   enforcement point. Instead each gate defends itself, so any custom `--pre-advance-cmd` that omits
   `validate.sh`'s prologue is silently wrong — observed on the same run, where a hand-written gate
   script reproduced the `oracle-guard` failure for exactly that reason.
3. **No shared helper.** A custom gate has nothing to source to get the same clean environment.

## Acceptance

Derived, per the GH-400 contract for an issue authored from a live incident rather than a report.

1. **(Phase 2 — open)** A pre-advance gate's inherited environment is governed by a stated contract,
   not by each gate remembering to unset names — an allowlist in `_gate_env()`, or an equivalent
   documented rule.
2. **(Phase 2 — open)** A custom `--pre-advance-cmd` can obtain the same clean environment without
   copying `validate.sh`'s prologue.
3. **(Phase 2 — open)** Adding a new export to `marathon-drive` cannot silently contaminate the gate:
   something fails loudly when an ungoverned variable crosses the boundary.
4. **(Phase 1 — MET 2026-08-07)** `gh284`, `gh331`, `gh322` and `gh268` all pass with a real
   marathon's flag AND lock state in effect — every cell of the matrix reads clean, and
   `bash validate.sh` itself exits 0 in that state.
5. **(Phase 1 — MET 2026-08-07)** No suite is skipped in the marathon gate to satisfy any of the
   above, and no variable is scrubbed in a way that breaks nested drivers (the reverted attempt is
   the control). Phase 1 scrubs per-suite, inside two suites whose lock root is already isolated;
   `validate.sh` is unchanged and the other ~40 driver-spawning suites still inherit the flag.

## Litmus tests

Per GH-419, each must be observed FAILING before it is trusted.

1. Contaminate the gate with a governed-but-unscrubbed variable → the run fails loudly rather than
   producing a wrong verdict. Control: the pre-fix tree reports a false gate failure instead.
2. A custom gate using the shared helper is immune to the same contamination. Control: the same gate
   without the helper reproduces the `oracle-guard` flip (`clean=2 usage, contaminated=0`).
3. **OBSERVED FAILING, then fixed (2026-08-07).** `gh284`/`gh331` pass with flag SET + lock HELD.
   Control measured immediately before the fix in the same worktree: **15/5 and 5/3**. After: 20/0
   and 8/0.
4. **OBSERVED FAILING, then fixed (2026-08-07).** `gh322`/`gh268` must not regress. Control: the
   reverted global scrub broke them (17/3 and 31/3); under Phase 1 they still inherit the flag and
   read 29/0 and 34/0.
   Criteria 3 and 4 hold SIMULTANEOUSLY under Phase 1 — that was the whole difficulty, and it is why
   a per-suite scrub succeeds where the global one could not. Any future fix that satisfies only one
   of them is the reverted attempt again.
5. The gate as a whole, not just its suites: `RELAY_DRIVER_LOCKED=1` + lock held → `bash validate.sh`
   exits 0. Control: the same command on the pre-Phase-1 tree fails. This is the assertion the
   reverted commit never made, and making it is what would have caught that commit being wrong.

## Provenance

Found 2026-08-07 while running the Litmus 0.2.0 marathon, not by reading the code. Sequence:
marathon halted on `gh284`+`gh331` → both passed standalone → wrongly attributed to a nested-driver
conflict and skipped → `oracle-guard` then failed under a hand-written gate → root-caused to ambient
`ALLOW_PATHS` → the same reasoning applied to the first two produced `RELAY_DRIVER_LOCKED`. The two
wrong turns are recorded because they are the argument for a contract: each was a plausible reading
of the evidence available at the time.
