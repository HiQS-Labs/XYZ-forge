---
gh_issue: 426
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426
title: "GH-426 — worktree isolation leaks an off-lane creation into the harness repo; the turn correctly exits 6 and the file is still there"
status: "BUILT 2026-08-11 as a lane of release 0.3.0 Nightwatch. The reported cause — worktree teardown — is FALSIFIED by measurement; the real one is the GH-375 auth pre-flight running with the caller's CWD, outside containment. Fixed, regression-tested in BOTH repos, and gh410's leak-cleanup block deleted (its absence is the proof). Controls recorded in test/baselines/GH-426-negative-control.md."
created: 2026-08-05
updated: 2026-08-11
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 3
risk: 3
effort: 3
phases: 2
ratings_provisional: true
related:
  - "#419 — the class. The exit code says contained, the filesystem says otherwise, and the obvious regression test reported clean because it checked the repo the file was NOT in."
  - "#417 — plausibly the same root: the Python shim and the Bash lib disagreeing about which repo is the target. Read before designing the fix; do NOT run as a concurrent lane."
  - "#410 — where this was found, and deliberately scoped out of. GH-410 narrowed the prose scan and did not touch worktree begin/end; this defect predates it and reproduces independently."
  - "#315 / #319 / #351 — the observation-layer family this belongs to."
non_goals:
  - "Weakening or removing the exit-6 containment verdict. It is behaving correctly; the leak is separate."
  - "Folding this into #410, which is merged and narrows a different mechanism."
  - "Removing test/gh410-containment-advisory.sh's cleanup before the leak is fixed. It is what stops the suite littering a live repo meanwhile, and it must be removed only as part of the fix."
goal: >
  Under RELAY_WORKTREE_ISOLATION=1, a file created by the agent inside the throwaway worktree also
  appears in the real harness repo after the turn ends. Worktree isolation exists precisely to stop
  creations and renames from reaching the real tree, where the path-allowlist's tracked-file revert
  cannot help. That is the case failing, and the exit code is reassuring and wrong.
---

# GH-426 · contained, and the file is in the repo anyway

## CRITICAL REVIEWER CONSTRAINTS (WAVE 4)
When handing off to the builder, give it exactly ONE micro-task and cite ONLY the single most critical file needed for that task. Do not provide broad context.

## Status

| What was just completed | What's next |
|---|---|
| **Built 2026-08-11 — and the suspected area was wrong.** Measured with a per-invocation log of the agent binary: the harness copy comes from the **GH-375 auth pre-flight**, which ran with the caller's CWD (the harness clone) and is the one execution of the agent binary that happens outside the turn's containment. Worktree teardown is exonerated. `agy_auth_preflight` now runs in a throwaway directory; `test/gh426-worktree-leak.sh` 7/0 asserts absence in **both** repos and pins the probe's CWD; gh410's leak-cleanup block is **deleted**. | Close #426 against the acceptance block below — all four criteria met, with criterion 3 satisfied by measurement rather than by change. |

## What the measurement actually showed

The reproduction in this doc is accurate and reproduces exactly as written. The **diagnosis attached
to it is not**, and the doc's own wording anticipated that: *"Stated as the place to look first, not
as a diagnosis — a builder that treats this as the answer will produce a fix shaped like the guess
rather than like the defect."*

A factorial control settled it. Same fixture, one variable at a time:

| case | stub writes off-lane? | isolation | harness leak? |
|---|---|---|---|
| A | yes | ON | **yes** |
| B | **no** | ON | no |
| C | yes | **OFF** | **yes** |

C is the one that breaks the stated theory: the leak happens with worktree isolation **off**, so it
cannot be a worktree-teardown defect. Logging every invocation of the agent binary then showed why —
there are **two** per turn:

```text
INVOCATION cwd=<harness>            argv=whoami            <-- GH-375 auth pre-flight
INVOCATION cwd=<isolation worktree> argv=... -p <prompt>   <-- the turn itself
```

The pre-flight ran with the caller's CWD. The reproducing stub — like `test/gh410-containment-advisory.sh`'s —
writes on **every** invocation, so the pre-flight invocation is what reached the harness root. The
turn's own copy was always discarded correctly, `worktree_end` always fired, and the worktree's
`git-common-dir` always resolved to `AGY_TURN_ROOT`.

**So criterion 3 was already true** and needed no change — only proof, which the test now supplies
from inside the turn (an earlier draft asserted it after teardown had already removed the worktree,
and reported "could not resolve", which is not a verdict).

**The fix is still worth making, for a different reason than the one filed.** Real `agy whoami` does
not write to its CWD — but "the binary we shell out to happens not to write" is a claim about someone
else's program, not a property this harness enforces. It is also precisely the assumption that made a
test stub indistinguishable from a containment failure for a week. The probe now runs in a throwaway
directory and reports, rather than silently discards, anything the binary leaves there.

## Acceptance — outcome

1. **Met.** `test/gh426-worktree-leak.sh` asserts the created file is absent from the target *and*
   the harness, and that the harness's `git status` is unchanged by the turn.
2. **Met.** Both repos are named in separate assertions, so a future edit cannot quietly drop the
   harness half — which is the shape of the miss this criterion exists for.
3. **Met by measurement.** The worktree's base repo *is* `AGY_TURN_ROOT`; asserted from the turn
   invocation's own `git-common-dir`, recorded while the worktree still exists.
4. **Met.** `test/baselines/GH-426-negative-control.md` — 2 red in this suite and 1 red in gh410's
   C4c against the pre-fix `agy-turn.py`, 0 after.

The first non-goal holds: exit 6 still fires, asserted first in the suite.

Captured 2026-08-05 as a lane of release **0.2.0 Litmus**. Not fired.

Found 2026-08-04 while writing GH-410's counter-pin; filed separately rather than absorbed.

## The reproduction

Deterministic on `development` @ `faf50e0` plus the GH-410 branch. A stub agent whose only actions
are to append to `./offlane.md` and write a relay block, driven through
`relay-automation/agy-turn.sh` with isolation on and `ALLOW_PATHS="relay.md"`, against a **throwaway
fixture repo** in `$TMPDIR`:

```text
shim rc=6
STUB CWD was: STUB-CWD=/private/var/folders/.../T/rtl-wt.3FV3IO
live-repo offlane.md: offlane.md
```

Three facts confirmed in one run:

1. **The agent really did run in the worktree** — its CWD is `rtl-wt.3FV3IO`, not the repo.
2. **Containment fired correctly** — `exit 6`, off-lane edits discarded.
3. **The file is in the harness repo root anyway** — a repo the fixture had nothing to do with. The
   fixture repo (`AGY_TURN_ROOT`) is clean; the *harness* is not.

The shim logs `CROSS-REPO mode (AGY_TURN_ROOT=<fixture> != CWD git root=<harness>)`, so the Python
layer knows the target is the fixture. The worktree that gets created, and the tree the file lands
in, disagree with that.

## Why this is worse than the exit code suggests

**The exit code is reassuring and wrong.** A run reports containment worked; an operator inspecting
it has no reason to look further, and the repo now holds an untracked file the agent created.

**It is invisible to the obvious test.** GH-410's regression test asserted the file had not reached
the target repo — and passed, because it checked `AGY_TURN_ROOT`, which is where the file *wasn't*.
Any test that checks only the declared target will keep reporting clean. That is why criterion 2
names both repos: the shape of the missed assertion is the finding, not an incidental detail.

## Suspected area

`rtl_worktree_end` in `relay-automation/relay-turn-lib.sh`, and how the worktree's base repo is
resolved relative to `AGY_TURN_ROOT` versus the CWD git root. **Stated as the place to look first,
not as a diagnosis** — a builder that treats this as the answer will produce a fix shaped like the
guess rather than like the defect.

## Acceptance

*Copied verbatim from [issue #426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426)
(`## Acceptance`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] A file created by an isolated turn inside the worktree does not exist in any repo on disk after the turn ends — neither the declared target nor the harness.
- [ ] A regression test asserts the absence in **both** the target repo and the harness repo, because checking only the declared target is what allowed this to pass unnoticed.
- [ ] The worktree's base repo is shown to match `AGY_TURN_ROOT` when the two differ, or the divergence is explained and documented.
- [ ] The test is proven to fail against current code before the fix, and the observed pre-fix result is recorded, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The failing test, first. A regression case asserting the created file is absent from **both** the declared target and the harness repo, **observed failing against current code** with the pre-fix result recorded per #419. This phase ships a red test and nothing else. | `test/gh426-worktree-leak.sh`, `validate.sh` | 2/1/2 |
| 2 | The fix. Resolve the worktree's base repo so it matches `AGY_TURN_ROOT` when the two differ — or document why the divergence is correct — and remove `test/gh410-containment-advisory.sh`'s leak cleanup, whose removal is itself the proof. | `relay-automation/relay-turn-lib.sh`, `utils/py/rtl.py`, `test/gh410-containment-advisory.sh` | 3/3/3 |

**Phase 1 must land red.** This lane's whole subject is a test that passed for the wrong reason;
writing the fix and the test together reproduces exactly that. The pre-fix observation is criterion
4 and is not optional here.

## Litmus tests

- **The cleanup block is the tell.** `test/gh410-containment-advisory.sh` currently removes a leaked
  `offlane.md` from the harness root and prints a NOTE. If that block can be deleted and the suite
  stays green, the leak is fixed. If the lane ships with the block still needed, it did not.
- **Asserting the target repo alone is the known-bad assertion.** A suite that checks only
  `AGY_TURN_ROOT` reproduces the miss and must be treated as a failed lane, not a passing one.
- **Exit 6 must still fire.** A "fix" that contains the file by weakening the verdict inverts the
  issue's first non-goal.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh426-worktree-leak.sh" },
    { "type": "grep_present", "path": "test/gh410-containment-advisory.sh", "pattern": "leaked into the harness root" }
  ],
  "artifacts":     [ "relay-automation/relay-turn-lib.sh", "utils/py/rtl.py", "test/gh426-worktree-leak.sh", "test/gh410-containment-advisory.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh426-worktree-leak.sh" ],
  "remediation":   { "source": "issue#426", "criteria": "worktree teardown must not leave a created file in any repo, asserted in both — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_present` reports `landed` when the pattern is **no longer found**. The second
probe is the leak-cleanup block itself — present today (verified 2026-08-05), and it flips to
`landed` exactly when the fix makes it unnecessary. **That is the probe worth having**, because it
tracks the defect rather than the deliverable.

## Method note

The reproduction is carried from the issue, recorded from a live run on 2026-08-04. The presence of
the cleanup block in `test/gh410-containment-advisory.sh` was re-verified 2026-08-05 against
`development` @ `2c95a56`, after #410 merged via PR #427.
