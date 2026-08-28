---
gh_issue: 280
source: https://github.com/HiQS-Labs/XYZ-forge/issues/280
title: "Recalibrate Jog as a serial supervisor over Marathon execution"
status: "Active — plan ready for implementation"
created: 2026-08-27
updated: 2026-08-27
owner: noel
doc_type: project
branch: feat/gh280-jog-marathon-recalibration
reviewed: "Agy relay QA approved 2026-08-27"
effort: 4
complexity: 4
risk: 3
phases: 5
ratings_provisional: false
related:
  - GH-279
  - GH-259
  - PROJECT/2-WORKING/recon-jog-marathon-recalibration.md
fix_probes:
  - bash test/gh280-jog-marathon-adapter.sh
  - bash test/jog-queue.sh
  - bash test/swarm-preflight.sh
  - bash test/marathon-drive.sh
  - bash test/wave-reconcile.sh
goal: >
  Keep Jog's serial queue authority while delegating per-task execution to Marathon's reviewed,
  gated, retry-safe, branch-safe one-phase driver through additive structured contracts.
---

# GH-280 · Jog ↔ Marathon recalibration

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 complete (2026-08-28): `marathon-invocation@1` (swarm_preflight, additive), `marathon-drive/result@1` (`--result-file`/`--execution-id`, single terminal writer via `_ON_EXIT`), Jog-side contract loaders, and `test/gh280-jog-marathon-adapter.sh` — 80 pass / 0 fail in a disposable full clone; swarm-preflight 100/0, marathon-drive 152/0, jog-queue 34/0 unchanged. | Phase 2: the opt-in `releases jog run --executor marathon --reviewer <agent>` adapter with cold-start projection, legacy relay default preserved. |

### Phase status

| Phase | State | Evidence |
|---|---|---|
| 1 — Pin the boundary and add machine contracts | Complete | `bash test/gh280-jog-marathon-adapter.sh` → 80 pass, 0 fail (root + vendored fixtures, stubbed agents/GitHub, no `--simulate`); `test/swarm-preflight.sh` 100/0, `test/marathon-drive.sh` 152/0, `test/jog-queue.sh` 34/0 in a separate disposable full clone; clone identity verified before/after. |
| 2 — Opt-in Marathon executor | Pending | — |
| 3 — Resume, retry, landing semantics | Pending | — |
| 4 — Dogfood root and vendored runs | Pending | — |
| 5 — Default flip + retire duplication | Pending | — |

## Table of contents

- [Decision and risk](#decision-and-risk)
- [Authority and invariants](#authority-and-invariants)
- [Discovery findings](#discovery-findings)
- [Phase 1 — Pin the boundary and add machine contracts](#phase-1--pin-the-boundary-and-add-machine-contracts)
- [Phase 2 — Add the opt-in Marathon executor](#phase-2--add-the-opt-in-marathon-executor)
- [Phase 3 — Make resume, retry, and landing explicit](#phase-3--make-resume-retry-and-landing-explicit)
- [Phase 4 — Dogfood root and vendored runs](#phase-4--dogfood-root-and-vendored-runs)
- [Phase 5 — Flip the default and retire duplication](#phase-5--flip-the-default-and-retire-duplication)
- [Acceptance](#acceptance)
- [Rollback](#rollback)

## Decision and risk

**Decision:** consolidate execution machinery, not product authority. Jog remains the immediate serial
queue and operator surface. Swarm Preflight resolves a runnable candidate. Marathon becomes the only
owner of reviewed execution, attempts, Tick history, acceptance, gates, branches, commits, and PR
delivery. Jog records a receipt-backed projection of Marathon's outcome.

**Reversibility: Costly (risk 3/5).** The change crosses queue state, process contracts, retry identity,
Git delivery, and lifecycle reconciliation. It remains reversible because every contract is additive,
the adapter is opt-in until proven, and the legacy Relay executor stays selectable for one bounded
compatibility window. The main failure mode is dual authority: Jog and Marathon both believing they
own attempts, branches, or completion.

**Blast radius:** `utils/py/releases_app.py`, `utils/py/jog_run.py`,
`utils/py/swarm_preflight.py`, `utils/py/marathon_drive.py`,
`utils/py/wave_reconcile.py`, their tests, root and `.xyz` installs, Tick state, protected branches,
GitHub PRs, and generated Releases/roadmap receipts. Do not edit the frozen Bash twins; Python is
authoritative.

## Authority and invariants

| Concern | Authority after this work | Required invariant |
|---|---|---|
| Serial order, lease, operator pause | Jog / `jog_queue` | One leased row at a time; position survives every retry. |
| Readiness and resolved inputs | Swarm Preflight | A versioned packet is the machine boundary; no fenced-JSON or log parsing. |
| Attempts, review, acceptance, gate | Marathon | One execution policy and one append-only Tick token family. |
| Branch, commit, PR identity | Marathon result receipt | Jog never guesses `feat/gh<N>` or discovers a PR from title alone. |
| Queue status | Jog projection | A queue row records the durable Marathon outcome; it does not redefine it. |
| Merge and project lifecycle | GitHub + `wave_reconcile.py` | Completion requires verified merged/reachable delivery and idempotent reconciliation. |

Non-negotiable rails:

- Preserve current CLI flags, exit codes, and default behavior for existing Marathon and Preflight
  callers until Phase 5.
- Keep Marathon's distinct builder/reviewer requirement. During opt-in, `--reviewer` is required; do
  not invent a cost-bearing or same-agent default.
- Treat the Jog attempt counter as lease history only. Marathon's namespaced attempt record is the
  sole execution retry cap.
- Resume existing durable state before firing a new token. Rebuild uses a fresh token and never
  deletes prior Tick history.
- Adopt an existing PR only when repo, base, head, issue, head SHA, and gate evidence all match the
  current execution receipt.
- Never turn Marathon's best-effort PR publication into a global hard failure. Jog may require a PR
  before its own landing projection advances.
- Run all runtime tests in a disposable **separate full clone**, never a linked worktree (GH-564).

## Discovery findings

Recon is complete; the detailed map is
[Recon Map — Jog ↔ Marathon recalibration](recon-jog-marathon-recalibration.md).

- `releases jog run` currently reaches `relay-drive` directly through `utils/py/jog_run.py` and
  rebuilds Tick seeding, agent environment, terminal interpretation, retry handling, branch creation,
  and PR lookup.
- `utils/py/marathon_drive.py` already owns the reviewed one-phase mechanics Jog duplicated, but it
  lacks a durable machine-readable terminal result for a supervisor.
- Swarm Preflight already emits `run-candidate@1`; the safe seam is an additive structured Marathon
  invocation artifact, not importing Marathon's nested Python closures or parsing its text output.
- Jog's 34-test suite simulates execution, while Marathon's 152-test suite exercises vendoring,
  attempts, recovery, gates, containment, and branch behavior. GH-279 therefore exposed an integration
  coverage gap rather than six unrelated model failures.
- Root and vendored `.xyz` installs resolve paths differently. Every new artifact lookup must derive
  from the resolved harness home or packet path, never the caller's assumed repository root.
- GitHub merge, SQLite projection, and PDDA reconciliation cannot share a transaction. The landing
  path must be replay-safe and monotonic.

These findings settle the architectural direction. Later phases may refine field names, but they may
not reopen the authority split without updating this plan and its risk assessment.

### Phase 1 material discoveries (recorded 2026-08-28)

- `marathon-closeout.sh` refuses `--base main` outright ("'development' is the required WIP base
  branch"), so a redirected green phase only opens a PR when the run started on `development` (or
  the configured integration branch). The adapter test fixture checks out `development` for the
  redirect cases; the Jog adapter must treat a run fired from any other branch as PR-less-but-green
  (receipt `pr: null`), never as a failure.
- `complete_phase_success` RESETS `.tick/attempts/<lane>` on success, so the result receipt records
  the fired attempt count at fire time (`_RESULT["attempt_count"]`) rather than re-reading the file
  at exit — otherwise every approved receipt would report `attempt.count: null`.
- A stubbed `gh` returning the unfiltered `[]` array for a `--jq '.[0]'` query exposed that the
  receipt writer's PR parse only tolerated the object shape; it now accepts object, first-element,
  and empty shapes. Real `gh` applies the jq filter, but the receipt writer must be robust to both.
- A tick-command failure exits with tick's own code, which can collide with the driver's exit-1
  "lock contention" meaning; the receipt now records `tick-command-failed` and maps exit 1 with a
  specific recorded reason to `escalated`, so a supervisor never misreads a broken tick binary as
  lock contention.
- Scope note: the Phase 1 baseline "Jog reaches its executor" is pinned by driving the exact seam
  Jog's Phase 2 adapter uses — Preflight packet → `marathon-invocation@1` argv → marathon-drive →
  real relay-drive → deterministic agent stubs (adapter test section F) — plus jog-queue's
  queue/lease coverage. The full `releases jog run --executor marathon` queue E2E lands in Phase 2
  with the adapter itself, per the plan's Phase 2 QA gate.

## Phase 1 — Pin the boundary and add machine contracts

1. Add `test/gh280-jog-marathon-adapter.sh` with real stubbed root and vendored `.xyz` fixtures. The
   baseline must reproduce the current split path without `--simulate`: Preflight resolves the
   candidate, Jog reaches its executor, and deterministic agent/GitHub shims record what would run.
2. Extend Swarm Preflight additively with a versioned `marathon-invocation@1` JSON artifact. It must
   carry argv as an array, explicit environment entries, harness/target roots, issue, phase/lane,
   artifacts, gate, builder, reviewer, base ref, and packet/result paths. Keep `run-candidate@1`, text
   output, exits, and ordinary callers compatible.
3. Add opt-in `--result-file <path>` support to `utils/py/marathon_drive.py`. Use a single terminal
   writer reached from every exit path to emit `marathon-drive/result@1` atomically. Required fields:
   execution ID, outcome/reason/exit, issue/phase/lane/token, attempt, target repo, base/head, head SHA,
   acceptance/gate receipt, PR number/URL, and timestamps. Unknown/unreached values are explicit nulls.
4. Reject unsupported schema versions and malformed paths before dispatch. Preserve existing stdout,
   CLI behavior, and exit codes when the new options are unused.
5. Pin success, pre-dispatch refusal, builder failure, reviewer refusal, gate failure, timeout/stall,
   recovered terminal state, protected-branch redirect, and PR-publication failure receipts in both
   root and vendored fixtures.

### Phase 1 QA gate

- `bash test/gh280-jog-marathon-adapter.sh` proves both installation shapes and negative controls.
- `bash test/swarm-preflight.sh` and `bash test/marathon-drive.sh` remain green.
- Every Marathon terminal exit produces exactly one valid result when requested; no result option
  leaves byte-for-byte-compatible observable behavior where fixtures pin it.
- No frozen Bash twin changed, and no caller parses shell text or fenced JSON.

## Phase 2 — Add the opt-in Marathon executor

1. Add `releases jog run --executor marathon --reviewer <agent>` while retaining `relay` as the
   default. The initial Marathon path must fail before lease mutation if the reviewer is absent,
   equals the builder, or is unavailable.
2. Have Jog create a deterministic execution directory keyed by queue global ID plus a fresh
   execution ID. Run Preflight into it, validate `marathon-invocation@1`, invoke the supported
   Marathon process boundary, then validate `marathon-drive/result@1`.
3. Keep the Jog driver lock and row lease as the outer serial boundary. Do not seed Tick, render a
   relay, choose a branch, interpret agent output, run a gate, or discover a PR inside the adapter.
4. Project Marathon outcomes through existing `perform_write` and receipt regeneration. Store the
   execution ID and result path needed for cold-start recovery. Queue attempt count remains a
   monotonically increasing lease-history metric and never blocks a Marathon retry.
5. On restart, inspect the recorded result and Marathon terminal state before dispatch. Re-project a
   valid terminal result idempotently; pause on contradictory/missing state; never silently refire.
6. Keep `--executor relay` behavior covered as the explicit rollback path. Do not expand or repair
   that legacy machinery beyond compatibility fixes required by the adapter rollout.

### Phase 2 QA gate

- A root and vendored queue each execute one real stubbed reviewed Marathon phase serially.
- Restart after dispatch, after terminal result, and after queue projection neither duplicates a turn
  nor loses queue position.
- Builder/reviewer separation, driver lock, lease ownership, attempt namespaces, and receipt hashes
  are asserted.
- `bash test/jog-queue.sh`, `bash test/marathon-drive.sh`, and the GH-280 integration suite pass in a
  disposable full clone.

## Phase 3 — Make resume, retry, and landing explicit

1. Replace ambiguous retry intent with three explicit operations:
   - `jog resume <GH>` reconciles existing durable state and spends no token unless Marathon proves a
     new fire is required.
   - `jog retry-gate <GH>` rechecks acceptance and the gate against the same head SHA; it never asks a
     builder to rebuild.
   - `jog retry-build <GH>` creates a fresh Marathon attempt/token while preserving all prior history.
2. Add the smallest Marathon extension needed for those modes at its public process boundary. Do not
   import `main()` closures and do not create a Jog-only bypass around review or attempt limits.
3. Add `jog land <GH>` (with `jog reconcile <GH>` as an idempotent replay entry if clearer in the CLI)
   that validates receipt schema, repo, base, head, head SHA, PR identity, merged state, merge SHA
   reachability, and qualifying gate evidence before marking the queue row complete.
4. Use `(repo identity, queue global ID, execution ID, merged SHA)` as the landing idempotency key.
   Replay in this order: verify GitHub truth → persist landing projection/receipt → invoke
   `wave_reconcile.py --pr <N>` → persist reconciliation evidence. A crash at any boundary resumes at
   the first missing durable step.
5. Delegate issue closure, doc promotion, roadmap completion, and generated-view refresh to
   `wave_reconcile.py`; Jog must not reproduce those lifecycle writes.

### Phase 3 QA gate

- Tests prove resume spends no duplicate token, gate-only retry preserves head SHA, and rebuild uses a
  fresh token without deleting Tick history.
- Wrong repo/base/head/SHA, stale PR, open PR, unmerged SHA, or missing gate evidence fails closed.
- Replaying every crash boundary converges on one completed queue row and one reconciled lifecycle.
- Existing `wave_reconcile.py` tests remain green; GH-280 tests cover its invocation contract rather
  than duplicating its internal assertions.

## Phase 4 — Dogfood root and vendored runs

1. Run an opt-in root queue with at least two serial items: one clean success and one controlled
   failure/retry. Capture committed Preflight packets, Marathon results, Tick attempt evidence, queue
   receipts, gates, and PR identities.
2. Repeat from a genuinely vendored `.xyz` consumer using its target repository as the artifact root.
   Prove no new lookup depends on XYZ-forge being the current working directory.
3. Exercise cold start at the three dangerous boundaries: Marathon terminal before Jog projection,
   PR merge before queue completion, and queue completion before PDDA reconciliation.
4. Compare the same scenarios under the legacy executor only where needed to demonstrate preserved
   queue behavior. Do not treat simulation, a linked worktree, or an uncommitted provenance file as
   evidence.
5. Record findings and any plan correction in this document before passing the phase.

### Phase 4 QA gate

- Both real runs land through reviewed Marathon execution with zero manual Tick, branch, PR, or queue
  surgery.
- Evidence is committed with the implementing PR and names the exact tested SHA.
- Root and vendored path assertions, retry semantics, and idempotent landing all pass.
- The shipping-platform local gate passes in a separate full clone; hosted Ubuntu remains advisory.

## Phase 5 — Flip the default and retire duplication

1. Make Marathon the Jog default only after Phase 4 evidence is reviewed. Keep
   `--executor relay` explicit for one documented compatibility window and state its removal trigger.
2. Update Jog help, skill/docs, examples, and error messages to describe reviewer selection, the three
   recovery operations, result-backed landing, and the temporary rollback flag.
3. Remove duplicated Jog execution code only after all call sites and fallback tests prove it is dead.
   Queue, lease, intake/promotion, and landing policy remain in Jog.
4. After the compatibility window, remove the legacy executor and its exclusive tests in a separate,
   easily reversible commit. Do not combine that deletion with the default flip.

### Phase 5 QA gate

- Default root and vendored runs satisfy the Phase 4 evidence standard.
- `--executor relay` still works during the declared window and is absent only after its separate
  removal commit.
- CLI/docs and `skills/jog/SKILL.md` agree with behavior.
- Full validation passes in a separate full clone, and the PR carries committed receipts/provenance.

## Acceptance

- Jog owns one serial queue and no per-task execution machinery.
- Marathon owns one reviewed execution path, one retry cap, one Tick history, one gate, and one branch/
  PR identity for each execution.
- Preflight and Marathon expose versioned additive machine contracts; existing callers remain
  compatible until the deliberate default flip.
- Resume, gate retry, rebuild, land, and reconcile are distinct, fail-closed, and replay-safe.
- Root and `.xyz` consumers pass real integration tests and dogfood runs without operator surgery.
- GH-279's six interventions have a named prevention test or durable contract.

## Rollback

Before the default flip, omit `--executor marathon`. During the compatibility window, select
`--executor relay`. If a receipt/schema defect is found after the flip, restore the legacy default in
one commit while preserving all queue, Tick, and result artifacts for diagnosis. Never roll back by
resetting shared history, deleting Tick events, rewriting queue receipts, or reusing a spent token.
