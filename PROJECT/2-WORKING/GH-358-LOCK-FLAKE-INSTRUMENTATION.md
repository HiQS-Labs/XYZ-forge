---
gh_issue: 358
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358
title: "GH-358 — xyz-completion's 16-way concurrent-append assertion flakes on the shared CI runner"
status: "Intake (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go."
created: 2026-08-06
updated: 2026-08-06
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the class, in an unusual form: the test is a decision gate that cannot distinguish a flake from the defect it exists to catch, so neither verdict is evidence."
  - "#232 — the CI step is already named 'minus a documented flaky test', so a second exclusion arriving unnoticed is how a suite drifts into being re-run until green."
non_goals:
  - "Lowering M from 16. It makes the symptom disappear and the safety property untested."
  - "Dropping the distinctness check, for the same reason."
  - "Deciding the disposition before the instrumentation exists. The issue is explicit that instrumenting comes first."
  - "Treating this as an ordinary flake. A flaky LOCK test is the one kind that cannot be waved off."
goal: >
  A 16-way concurrent-append assertion intermittently loses one record on the shared runner. Both
  assertions are correct statements about a real safety property. The problem is that "flaky" and
  "the lock genuinely loses a write under contention" produce an identical symptom, and nothing in
  the output can tell them apart — so the test cannot currently be evidence either way.
---

# GH-358 · a lock test that cannot tell a flake from the bug

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found that every appender's exit status is discarded today and that two different lock bounds are in play. | Operator go. Then Phase 1 (instrument: retain exit status, report the missing record's terminal state, name both bounds) and only then Phase 2 (choose the disposition on that evidence). |

## The defect

`test/xyz-completion.sh`'s lock-under-concurrency case fails intermittently on the shared runner,
losing one of 16 records. The same commit re-run passed; it passes locally. The originating PR's
diff touched neither the test nor the appender.

**Why this is not "just re-run it":**

1. **It is a lock test.** "Flaky" and "the lock genuinely loses a write under contention" produce
   the identical symptom. The failure says a record was clobbered — which is *also* exactly what a
   real lock bug says.
2. **A second flaky exclusion arriving unnoticed** is how a suite drifts into being re-run until
   green. The CI step is already named for one documented exclusion.
3. **A red run on an unrelated PR trains people to re-run rather than read**, which is the habit
   that lets a real regression through.

## What the review added

Two findings from the codex review, both verified against `development` @ `3b37072`:

- **Every appender's exit status is discarded.** The harvest loop is
  `for p in $pids; do wait "$p" 2>/dev/null || true; done`, in two places. So a crashed or killed
  appender is indistinguishable from one that acquired the lock and lost its record — the test
  cannot currently attribute the failure even in principle.
- **Two different bounds are in play.** The test waits on one budget; the writer defaults to
  `XYZ_LOCK_WAIT_S` at another, smaller value. A report that names "the timeout" without saying
  which one was exhausted is not actionable.

## Acceptance

*Copied verbatim from [issue #358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358)
(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*

- [ ] Each of the 16 appenders' exit status is retained and asserted. Today every one is discarded (`wait "$p" 2>/dev/null || true`), so a crashed appender is indistinguishable from a lost record; any non-zero exit must fail the assertion in its own right.
- [ ] On a mismatch the report identifies the missing `sessionId` **and its terminal state**: lock acquired and record lost, lock never acquired, or process failed. Those have opposite priorities and today produce an identical symptom.
- [ ] Both effective lock bounds are named in the failure output — the test's own wait and the writer's `XYZ_LOCK_WAIT_S` default, which differ today — and the report states which one was exhausted.
- [ ] The change ships the instrumentation output from a reproduced failure, and the disposition applied is the one that evidence indicates. A disposition chosen without that output does not satisfy this.
- [ ] `M` is not lowered from 16 and the distinctness check is not dropped. Both make the symptom disappear and leave the safety property untested.
- [ ] If it goes on the CI exclusion list, the workflow states **why**, so a reader does not take the exclusion to mean the property is not worth checking.
- [ ] The instrumentation is demonstrated to distinguish the causes: a deliberately clobbered record and a deliberately starved appender produce visibly different reports. A lock test that cannot tell a flake from a real lost update is not evidence, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
after the codex+agy review. Two changes are worth naming: the exit-status criterion is new and came
from reading the test rather than the issue, and the original *"the disposition is chosen after that
evidence exists"* was replaced — both reviewers correctly said a reviewer cannot verify the temporal
order of someone's decisions. It now requires the instrumentation output to ship with the change.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Instrumentation. Retain and assert each appender's exit status; on mismatch report the missing record's terminal state — lock acquired and record lost, lock never acquired, or process failed — and name both effective bounds with the one that was exhausted. | `test/xyz-completion.sh`, `utils/telemetry/append-xyz-completion.sh`, `test/gh358-lock-instrumentation.sh` | 2/2/2 |
| 2 | Disposition, on that evidence. Raise the bound, retry the assertion, or exclude with a stated reason in the workflow. `M` stays 16 and the distinctness check stays. | `.github/workflows/ci.yml` or `test/xyz-completion.sh` | 1/2/1 |

**Phase 2 must not be pre-committed in the packet.** A builder told which disposition to apply will
produce instrumentation that agrees with the instruction — the same defect as grading against a
model-authored requirement.

## Litmus tests

- **The instrumentation is itself a decision gate**, so it needs its own negative control: a
  deliberately clobbered record and a deliberately starved appender must produce visibly different
  reports. If it cannot tell those apart it has not fixed anything.
- **A green run proves nothing here.** The failure is intermittent; a passing suite after the change
  is consistent with the instrumentation never having been exercised. The controls above are the
  only evidence.
- **If the answer turns out to be a real lock bug, the priority changes completely** and this lane
  should stop and re-file rather than proceed to Phase 2's exclusion option.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh358-lock-instrumentation.sh" },
    { "type": "grep_absent", "path": "test/xyz-completion.sh", "pattern": "terminal state" }
  ],
  "artifacts":     [ "test/xyz-completion.sh", "utils/telemetry/append-xyz-completion.sh", "test/gh358-lock-instrumentation.sh", ".github/workflows/ci.yml", "validate.sh" ],
  "artifacts_new": [ "test/gh358-lock-instrumentation.sh" ],
  "remediation":   { "source": "issue#358", "criteria": "make the lock assertion able to distinguish a flake from a lost update — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
`terminal state` occurs **0 times** in `test/xyz-completion.sh`.

**This lane's artifacts include `test/*.sh` it must edit.** Per the marathon plan's standing note,
those are read-only specs in-turn and the outer harness gate verifies them after the turn, outside
the isolated worktree.

## Method note

The flake evidence and the "do not lower M / do not drop distinctness" constraints are carried from
the issue. The discarded-exit-status finding and the two-bound mismatch came from the codex review
and were verified directly against `development` @ `3b37072` before being written as criteria. No
open PR or branch touches this issue — checked before authoring.
