---
gh_issue: 343
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343
title: "GH-343 — a target-relative gate program is checked against cwd/PATH instead of target_root, so a ready contract reports NOT-READY"
status: "Intake (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go."
created: 2026-08-06
updated: 2026-08-06
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 1
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the class. A verdict that depends on the operator's working directory is not a property of the contract, and nothing in the output says which root was searched."
  - "#344 — the same class in the /10days skill: a root resolved from the wrong place, silently."
  - "#308 — removed the old bash/node/npm/python3 PATH exemptions (correctly). It did not introduce this and did not fix it."
non_goals:
  - "Reinstating GH-308's removed PATH exemptions. An absent npm passing as ready was a real defect; this is a different one."
  - "Changing how marathon-drive executes the gate. It already runs with cwd at the target root, which is why a target-relative program path is correct at execution time — only the readiness check disagrees."
  - "Editing utils/swarm-preflight.sh. Frozen under GH-308; the fix lands in utils/py/swarm_preflight.py."
goal: >
  `swarm-preflight` rejects a contract whose gate names a program by a target-relative path, because
  the check resolves it against the process's working directory rather than `target_root` — while
  the `bash`/`sh` branch immediately above resolves against `target_root`. The verdict depends on
  where the operator happened to be standing, and `/10days` Step 6 treats any non-zero exit as a
  reason to drop the issue from the fire list.
---

# GH-343 · the verdict depends on where you were standing

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which caught that "the two branches agree" was satisfiable by making the correct branch wrong. | Operator go. Then Phase 1 (resolve a separator-containing gate program against `target_root`, plus the executability check) and Phase 2 (the cwd-independence regression with its recorded baseline). |

## The defect

The two branches disagree about what a gate path is relative to. The `bash`/`sh` branch joins the
script onto `target_root`; the program branch calls `shutil.which()`, which — for a string
containing a path separator — tests that path against the **process's** working directory.

Consequence: run from the target repo, `ready (exit 0)`. Run the identical contract from the harness
clone, `NOT-READY (exit 5)` with *"command not found in PATH"*.

**Not a GH-308 regression.** Before GH-308 the Python lane exempted `bash`/`node`/`npm`/`python3`
from the PATH check, and a target-relative interpreter was never in that list, so it failed
identically. GH-308 removed the exemptions — correctly, an absent `npm` was passing as ready — and
did not touch this case.

## Why it matters

- **A false NOT-READY silently drops an issue from a sweep.** `/10days` Step 6 treats any non-zero
  exit as a reason to drop, and exit 5 reads as *"not marathon-ready"* — indistinguishable from a
  real verdict.
- **The gate command is meant to run in the target.** `marathon-drive` executes the pre-advance gate
  with cwd at the target root, so a target-relative program path is correct at execution time. Only
  the readiness *check* disagrees.
- **The message misdirects.** *"not found in PATH"* is accurate for a bare command and wrong for a
  path, so the failure reads as a missing tool rather than a resolution bug.

## Acceptance

*Copied verbatim from [issue #343](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343)
(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*

- [ ] A `gate` naming a program by a target-relative path resolves against `target_root`, not the process's working directory, so the identical contract yields the identical verdict from any cwd.
- [ ] From two different working directories, a shell-script gate and a target-relative executable program both resolve against `target_root` and report READY; deleting either file from the target reports NOT-READY. Making the two branches merely **agree** — by resolving both against the working directory — fails this criterion rather than satisfying it.
- [ ] A gate script or program that exists but is **not executable** sets NOT-READY, rather than passing readiness and failing at execution time.
- [ ] A NOT-READY message names which root was searched. "not found in PATH" is accurate for a bare command and misleading for a path, and that wording is what made this undiagnosable in one read.
- [ ] The frozen Bash twin `utils/swarm-preflight.sh` is byte-unchanged (GH-308).
- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.

## Acceptance — deviations from the issue

**RESOLVED 2026-08-08 — criterion 3 was narrowed ON THE ISSUE, operator-approved, so the block above
is again a verbatim copy and this is no longer a deviation.** The lane is buildable. What follows is
the evidence that produced the amendment, retained because the wrong version is the more instructive
one.

Criterion 3 originally read:

> A gate script or program that exists but is **not executable** sets NOT-READY, rather than passing
> readiness and failing at execution time.

Its premise is false for the `bash`/`sh` branch. `bash foo.sh` executes a mode-644 file perfectly
well — the interpreter reads the script, it is never `exec`'d — so a non-executable *gate script* does
**not** fail at execution time and must not be reported NOT-READY.

**Measured, twice, by two independent codex builds** (`ee56842` and the earlier reverted attempt).
Both implemented the criterion literally, adding `os.access(script_path, os.X_OK)` to the `bash`/`sh`
branch, and both produced the identical regression in the lane's own gate:

| | pass | fail |
|---|---|---|
| `test/swarm-preflight.sh` before | **98** | 0 |
| after either build | 91 | **7** |

The failures are `T15`, `T33`, `T36`, all `expected exit 0, got 5`. `T15`'s fixture gate is
`"bash -x src/a.js"` with a mode-644 `src/a.js`; the criterion forces it to NOT-READY.

**Satisfying the criterion by `chmod +x`-ing the fixtures would be worse, not better.** It would ship
the rule "an interpreter-invoked gate script must carry the executable bit", which makes
`"gate": "bash validate.sh"` report NOT-READY against any target repo whose `validate.sh` is mode 644
— while that gate would in fact run correctly. That is a **new false NOT-READY**, which is the precise
defect class this issue exists to remove and this release exists to make impossible. The lane would
have shipped the bug it was written to fix.

**The narrowing, now live on the issue** — keeps the criterion where its premise holds, drops it
where it does not:

> A gate program that is **executed directly** (a bare command, or a separator-containing path) and
> exists but is not executable sets NOT-READY. A gate *script* passed to an interpreter (`bash x.sh`)
> is **not** required to be executable, because the interpreter reads it; requiring the bit there
> would itself be a false NOT-READY.

This preserves criteria 1, 2, 4, 5 and 6 unchanged, and keeps the useful half of 3 — the
directly-executed case, where a missing bit genuinely does fail at execution time.

`brief-gh343-gate-program-target-root.md` carried the same false premise at its `## What to build`
bullet ("Executability, not existence … fails at execution time") and has been corrected to match, so
a rebuild is not steered back into the same wall. **This was a plan defect, not a builder defect** —
codex implemented what it was given, both times.

---

The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
after an adversarial review by codex and agy. Both independently found that the original wording,
*"the two branches agree,"* was satisfiable by changing the **correct** branch to resolve against the
working directory — a criterion whose plain reading permitted making the defect worse. It now states
the direction. Criterion 3's false premise survived that review; the thing that caught it was
**building the lane and running its gate**, which is the argument the #419 evidence standard makes.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Resolution. A separator-containing gate program resolves against `target_root` before any PATH fallback, and a gate script or program that exists but is not executable sets NOT-READY. The failure message names the root that was searched. | `utils/py/swarm_preflight.py` | 2/1/2 |
| 2 | The cwd-independence pin. Preflight the same contract from two different working directories and assert one verdict, with the pre-fix divergence observed and recorded as a durable baseline artifact. | `test/gh343-gate-program-target-root.sh`, `validate.sh` | 2/1/2 |

## Litmus tests

- **Agreement is not the goal; correctness is.** A build that resolves *both* branches against the
  working directory makes them agree and is a failed lane. Phase 2's assertion must be that both
  resolve against the target.
- **The executability check must be observed rejecting something.** The `bash`/`sh` branch checks
  existence, not executability, so a non-executable gate script passes readiness and fails at
  execution — a second instance of the same "green on a question never asked" shape.
- **The baseline must be an artifact, not a sentence.** The review's cross-cutting finding: a claim
  that a negative control was observed is not the control. Record the reproducer, the revision, and
  both results.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh343-gate-program-target-root.sh" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "not executable at target" }
  ],
  "artifacts":     [ "utils/py/swarm_preflight.py", "test/gh343-gate-program-target-root.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh343-gate-program-target-root.sh" ],
  "remediation":   { "source": "issue#343", "criteria": "resolve a target-relative gate program against target_root — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
`not executable at target` occurs **0 times** in `utils/py/swarm_preflight.py`, and the test path
does not exist — so neither probe can read `landed` before the work ships.

## Method note

The two-branch asymmetry, the reproduction from two working directories, and the "not a GH-308
regression" finding are carried from the issue. The probe markers' absence was verified 2026-08-06
against `development` @ `3b37072`. No open PR or branch touches this issue — checked before
authoring, after two Litmus lanes (#416, #344) turned out to have work already in flight.
