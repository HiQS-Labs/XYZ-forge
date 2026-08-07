---
gh_issue: 441
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441
title: "GH-441 — validate.sh is the default pre-advance gate but is corrupted by the marathon environment it inherits"
status: "Proposed (1-INBOX — not yet active). Nothing is fixed: the attempted scrub was reverted. This doc carries the measurement showing the defect is structural."
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
  - "Scrubbing more variables. Measured and reverted: no assignment of RELAY_DRIVER_LOCKED is correct, because nested drivers and lock assertions need opposite values."
  - "Per-suite skip lists hand-maintained by each gate. That was the first instinct here and it is what this issue exists to replace with a contract."
  - "Changing marathon-drive's re-entrancy guard. RELAY_DRIVER_LOCKED is correct for its own purpose; the problem is the gate running driver tests at all."
goal: >
  validate.sh is marathon-drive's DEFAULT --pre-advance-cmd, so it routinely runs as a child of a
  live marathon and inherits its environment. RELAY_DRIVER_LOCKED=1 and ALLOW_PATHS each silently
  flip suite verdicts, so the gate reports failures belonging to its parent rather than to the
  change under review. Scrubbing does not fix it: nested drivers need RELAY_DRIVER_LOCKED set and
  lock assertions need it unset, so validate.sh cannot pass as a pre-advance gate in EITHER
  configuration. ~a dozen of its suites spawn drivers against a repo whose driver is mid-run.
---

# GH-441 · the gate inherits the state it is supposed to judge

## Status

| What was just completed | What's next |
|---|---|
| Root-caused during the Litmus marathon after it halted the run four times. A scrub of `RELAY_DRIVER_LOCKED` was landed and then **reverted** — it was measured on a clean tree with no parent lock, the one state where the variable is never set, and traded 8 failing assertions for 6. The surviving deliverable is the evidence matrix below, which shows the defect is not fixable by scrubbing. | The contract. `validate.sh` cannot pass as a pre-advance gate in EITHER configuration, so the decision is structural: exclude driver-spawning suites from the gate by construction, isolate those tests' lock root, or change what `--pre-advance-cmd` defaults to. Not started. |

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

So the statement of the defect is stronger than "some variables leak": **`validate.sh` cannot pass
as a marathon's pre-advance gate in either configuration**, because it contains ~a dozen suites that
spawn nested drivers against a repo whose driver is mid-run.

## What is fixed, and what is not

Fixed: nothing in the harness. The scrub was reverted (see Status). The `ALLOW_PATHS` half needs no
fix — `validate.sh` already unsets it; the finding there is that a CUSTOM gate omitting that
prologue is silently wrong, which was observed live.

Not fixed — and the reason this doc exists:

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

1. A pre-advance gate's inherited environment is governed by a stated contract, not by each gate
   remembering to unset names — an allowlist in `_gate_env()`, or an equivalent documented rule.
2. A custom `--pre-advance-cmd` can obtain the same clean environment without copying
   `validate.sh`'s prologue.
3. Adding a new export to `marathon-drive` cannot silently contaminate the gate: something fails
   loudly when an ungoverned variable crosses the boundary.
4. `gh284`, `gh331`, `gh322` and `gh268` all pass with a real marathon's flag AND lock state in
   effect — the matrix above is the baseline, and every cell must read clean.
5. No suite is skipped in the marathon gate to satisfy any of the above, and no variable is scrubbed
   in a way that breaks nested drivers (the reverted attempt is the control).

## Litmus tests

Per GH-419, each must be observed FAILING before it is trusted.

1. Contaminate the gate with a governed-but-unscrubbed variable → the run fails loudly rather than
   producing a wrong verdict. Control: the pre-fix tree reports a false gate failure instead.
2. A custom gate using the shared helper is immune to the same contamination. Control: the same gate
   without the helper reproduces the `oracle-guard` flip (`clean=2 usage, contaminated=0`).
3. `gh284`/`gh331` pass with flag SET + lock HELD. Control: today, 15/5 and 5/3.
4. `gh322`/`gh268` pass with flag UNSET + lock HELD. Control: the reverted scrub, 17/3 and 31/3.
   Criteria 3 and 4 must hold SIMULTANEOUSLY — that is the whole difficulty, and any fix that
   satisfies only one of them is the reverted attempt again.

## Provenance

Found 2026-08-07 while running the Litmus 0.2.0 marathon, not by reading the code. Sequence:
marathon halted on `gh284`+`gh331` → both passed standalone → wrongly attributed to a nested-driver
conflict and skipped → `oracle-guard` then failed under a hand-written gate → root-caused to ambient
`ALLOW_PATHS` → the same reasoning applied to the first two produced `RELAY_DRIVER_LOCKED`. The two
wrong turns are recorded because they are the argument for a contract: each was a plausible reading
of the evidence available at the time.
