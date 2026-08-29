---
gh_issue: 280
source: https://github.com/HiQS-Labs/XYZ-forge/issues/280
title: "Recalibrate Jog as a serial supervisor over Marathon execution"
status: Complete
created: 2026-08-27
updated: 2026-08-28
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
| Phase 4 root dogfood complete (2026-08-28): queue compiled from the Releases ledger (0.9.0 dialed-in GH-107 + GH-105; 0.7.4 Linux RC excluded per operator; GH-222 excluded — artifact overlaps the executor overlay), agy builder + codex reviewer, REAL turns, PRs #283/#284 merged into development, both issues closed, lifecycle reconciled, cold-start + replay boundaries exercised. Evidence: `relay-system/2026-08-28/gh280-phase4-dogfood/`. | Operator review of Phase 4 findings; the vendored `.xyz` consumer half of Phase 4 remains; named follow-up fixes below before any Phase 5 default flip. |

### Phase status

| Phase | State | Evidence |
|---|---|---|
| 1 — Pin the boundary and add machine contracts | Complete | `bash test/gh280-jog-marathon-adapter.sh` → 80 pass, 0 fail (root + vendored fixtures, stubbed agents/GitHub, no `--simulate`); `test/swarm-preflight.sh` 100/0, `test/marathon-drive.sh` 152/0, `test/jog-queue.sh` 34/0 in a separate disposable full clone; clone identity verified before/after. |
| 2 — Opt-in Marathon executor | Complete | Adapter test sections G/H/I: root + vendored queue runs through real Preflight → Marathon → Relay with deterministic agent stubs (106 pass, 0 fail total); reviewer-policy refusals before lease mutation; cold-start at both boundaries (missing result parks; terminal result re-projects without a second dispatch); foreign-cwd vendored run stays clean (GH-279 #2 fixed for this executor); legacy relay default verified unchanged. |
| 3 — Resume, retry, landing semantics | Complete | Adapter test sections J/K/L (139 pass, 0 fail total): resume re-projects terminal state and parks result-less dispatches without spending a token; retry-gate proves no new task.created and work-head preservation (only Marathon's own transcript commit advances the lane); retry-build runs on a fresh `-2` token with prior Tick history and execution records intact; land fails closed on wrong base/head-SHA/open-PR/unreachable-merge/missing-gate-evidence/foreign-repo, completes + delegates to wave_reconcile on truth, replays idempotently, and resumes at the reconciliation boundary; `test/wave-reconcile.sh` 11/0 unchanged. |
| 4 — Dogfood root and vendored runs | Root half complete; vendored half pending | Real run below — PRs #283/#284 (both MERGED into development), issues #107/#105 CLOSED, gate receipts + receipts + ledgers committed under `relay-system/2026-08-28/gh280-phase4-dogfood/`. Vendored `.xyz` consumer run not yet executed. |
| 5 — Default flip + retire duplication | In progress (flip PR + this surface), 2026-08-28 | Default-flip code change in flight as the parallel flip PR; human-facing surface aligned by the Phase 5 docs lane (`skills/jog/SKILL.md`: marathon default, required `--reviewer`, legacy `--executor relay` window, recovery verbs, receipt-backed landing). Completion evidence due per the Phase 5 QA gate. |

### Phase 4 dogfood record (2026-08-28, agy builder + codex reviewer, operator-authorized)

Queue source: Releases ledger upcoming releases with assigned issues — 0.7.4 "Linux MVP RC"
**excluded per operator instruction** (its whole manifest set: 123/204/249/251/255/256/275);
0.9.0 "Cargo" dialed-in, non-cut issues = 105/107/222; **GH-222 excluded** because its declared
artifact (`utils/py/releases_app.py`) is the executor overlay itself — the isolation worktree
seeds allowlisted artifacts from the working tree, so its lane PR would carry unreviewed GH-280
hunks. Remedy: run GH-222 after PR #281 lands. Tested SHAs: dogfood base `aaa153f9`,
merges `4751d3ce` (PR #283) and `de67142f` (PR #284).

**GH-107 (attempt 1 → containment → retry-build → 2× gate-only retry → landed):**
agy builder + codex reviewer ran real multi-round review (formal Changes-requested round, then
Approved). Attempt 1 escalated exit 6 — the builder wrote probe files to in-tree `scratch/`
against the relay's explicit $TMPDIR instruction; containment reverted, work preserved in
`.tick/orphan-backups/20260828T022003Z-80043`. `jog retry-build` fired attempt 2 on token
`…-TURN-2` (prior history intact); the relay Approved, then the full `validate.sh` gate failed
twice on MY intake-hygiene defects (missing `goal:` key; unparked roadmap row / stale dashboard).
After fixing intake and regenerating the dashboard, `jog retry-gate` approved via the
satisfied-lane path with ZERO further turns. closeout opened PR #283; merged; `jog land`
verified truth and wave_reconcile promoted the doc + closed the issue.

**GH-105 (run → gate-only retry → landed):** one changes-requested round then Approved; the
gate failed once on dashboard drift caused by jog's own promotion repoint; after dashboard
regen, `jog retry-gate` approved with zero further turns. PR #284 merged (issue auto-closed by
GitHub's `Closes #105`), `jog land` verified + completed + reconciled.

**Cold-start + replay boundaries (real receipts):** a row rewound to crashed-running with a
dispatched execution and a live terminal receipt was re-projected by `jog resume` with no
dispatch; `jog land` replay correctly refused to redo durable steps (and exposed the
projection-recorded-but-row-not-completed edge, see finding 6).

### Phase 4 material findings (the dogfood's real deliverable)

1. **Turn containment reverts supervisor-owned tracked state.** During turns, the containment
   pass restored `releases.db`/`releases.sql` (uncommitted jog queue writes), the executor
   overlay files, and the regenerated dashboard to HEAD — the supervisor's own uncommitted
   tracked-file writes are indistinguishable from an agent's off-lane edits. Untracked state
   (`.tick/`, the jog ledger) survives. Consequence: queue rows vanished mid-run (twice),
   requiring a re-add + ledger re-key drill. Durable fix candidates: commit intake/queue
   writes before dispatch, or keep jog queue mutations in untracked space until landing.
2. **Queue identity (global_id) does not survive external DB loss.** Re-adding an issue mints
   a new gid and orphans the execution ledger (absolute gid paths inside `state.json` AND
   `marathon-invocation.json`). Fail-closed loaders caught the stale paths loudly. Fix
   candidate: relative ledger paths + gid lookup by gh_number fallback.
3. **Intake/promotion writes are gate-load-bearing.** A 2-WORKING doc without a `goal:` key or
   a parked roadmap row fails validate.sh's pdda suites; jog's promotion `roadmap repoint`
   stales the committed dashboard (GH-243). Both items' first gates went red on exactly this.
   Fix candidate: the executor regenerates `ROADMAP-DASHBOARD.md` after promotion, before
   dispatch.
4. **Real builders still write probe files in-tree** (attempt 1's `scratch/`), re-confirming
   the GH-279 defect-3 class — but with GH-280 the failure is a receipt + orphan-backup + a
   designed retry, not hand surgery.
5. **`jog retry-gate` recovered both items with zero further agent turns** after operator
   hygiene fixes — the GH-274 satisfied-lane seam works in production and is the correct
   "approved relay, red gate" remedy. Attempt caps were never the limiter; hygiene was.
6. **`jog land` replay does not re-assert the queue projection** when the landing key matches —
   safe for genuine crash replay, but a projection-recorded-yet-unprojected row (fabricated
   here) needs one sanctioned `jog_set_status`. Edge, documented.
7. **GitHub's `Closes #N` auto-close races wave_reconcile's close step** (GH-105): harmless
   here (the reconciler handles already-closed issues), but lane PRs should perhaps not
   auto-close, leaving closure to the reconciler's verified path.
8. **GH-222-class exclusion**: an executor cannot dogfood a lane whose artifacts include the
   executor's own files. Run such items after the executor PR lands.

### Phase 4 open items

- Vendored `.xyz` consumer dogfood (Phase 4's second half) not yet run — needs a consumer repo
  with the GH-280 harness vendored.
- The dogfood clone's working tree still holds uncommitted intake hygiene (goal keys, dashboard
  regen, queue rows) that should land on development as a real intake commit.
- Findings 1–3 above need their durable fixes before Phase 5's default flip.

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

### Phase 2 material discoveries (recorded 2026-08-28)

- **The packet's `--require-clean` is unimplementable for a supervisor.** Acquiring the row lease
  rewrites the tracked `releases.db`/`releases.sql` (perform_write regenerates the dump) between
  lease and dispatch, so Marathon would refuse on Jog's own durable queue state every single run.
  The adapter strips `--require-clean` from the packet argv and says why in the code; Marathon's
  dirty-workspace WARNING still fires, and Jog's outer driver lock remains the serial boundary.
- Marathon's lane key for a Jog execution defaults to the packet slug (phase id), so re-running the
  same issue accumulates `.tick/attempts/<slug>` across executions exactly as the plan intends —
  Marathon's attempt cap is the sole execution cap, and the queue's `attempt_count` stays lease
  history.
- Cold-start semantics in implementation: an orphan-reconciled row whose latest execution is
  `dispatched` is resolved from the durable receipt BEFORE the loop can lease — a valid terminal
  receipt is re-projected idempotently (no turn spent), a missing/invalid receipt parks the row as
  `cold-start` (never a silent refire). Re-dispatch after a cold-start park requires the explicit
  Phase 3 verbs.
- Under the packet's `RELAY_WORKTREE_ISOLATION=1`, relay-drive seeds the relay file (always the
  first `RTL_ALLOW` entry) and the allowlisted artifacts into the isolation worktree and copies
  modified paths back, so the adapter can dispatch the packet env faithfully; no env rewriting is
  needed beyond the reviewer/builder policy overrides and the lock hand-off.

### Phase 3 material discoveries (recorded 2026-08-28)

- **The packet argv carries no `--phase-id`, and Marathon defaults every lane to `p1`** — without
  intervention, two different queue issues would share ONE lane attempt budget. The adapter now
  adopts the packet's suggested per-issue phase id (the candidate slug) on every dispatch path
  (run / retry-gate / retry-build share one argv builder), keeping Marathon's namespaced attempt
  record per-issue as its cap semantics assume.
- **Every Marathon run commits its own transcript, so a receipt's head SHA legitimately advances
  even on a "gate-only" retry.** The head-moved guard therefore runs PRE-DISPATCH in Jog (live
  `rev-parse` vs the prior receipt): it catches operator head movement between runs without
  false-tripping on the retry's own transcript commit — and refuses without spending the gate run.
- A gate-only retry never passes the branch guard (the satisfied-lane short-circuit runs first),
  so its receipt carries no `base_branch`; landing falls back to the newest receipt in the
  execution family that carries base/head — identity is stable across one issue's family, and
  nothing is ever guessed.
- A rebuild that must not be satisfied by the attempt it retries dispatches on a fresh suffixed
  token (`<token>-2`, Marathon's own GH-116 family convention) — the spent base token's history
  stays untouched, which is exactly the append-only behavior the plan demands.
- `wave_reconcile` is handed an offline manifest built from the PR metadata Jog verified seconds
  earlier (`gh pr view` truth), plus `--skip-pull --skip-branch-check --allow-dirty`: Jog's own
  tracked-ledger writes make the tree non-pristine, the pull/branch checks belong to an operator
  context, and the manifest avoids a second network dependency. Its exit is a resumable boundary:
  landing is already persisted, and a re-run resumes at the reconciliation step only.

## Open risks and operator decisions (as of Phase 3)

- **Phase 4 requires operator-supplied resources** the adapter tests deliberately do not fake: a
  real builder/reviewer pair (e.g. `--builder codex --reviewer agy` with live CLIs), a real root
  queue with ≥2 serial items including one controlled failure/retry, a genuinely vendored `.xyz`
  consumer repository, and authorization for external PR/merge activity against real remotes.
  Per the task's boundary rule, implementation stops here and reports the need rather than
  fabricating dogfood evidence.
- **Phase 5 (default flip) stays blocked** on Phase 4 evidence by design; `--executor relay`
  remains the default and the explicit rollback path.
- The queue-level `attempt_count` remains lease history only; Marathon's per-lane cap (default 2)
  is the sole execution cap. A deliberately unlucky sequence can therefore park a lane at the cap
  — the remedy is Marathon's own `--force` convention, which Jog deliberately does NOT expose
  (no Jog-only bypass around attempt limits).

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

Phase 5 progress note (2026-08-28): root + vendored dogfood evidence landed 2026-08-29 (GH-222
dogfood: `relay-system/2026-08-29/gh222-executor-dogfood/` + `relay-system/2026-08-29/gh222-vendored-dogfood/`,
PRs #311/#312) — that is the Phase 4 vendored half closing, which unblocks this phase. Phase 5 is
now in progress as the flip PR (marathon default, `--reviewer` required, `--executor relay`
documented as the legacy rollback window) plus this surface alignment.

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

## Lessons Learned (For Future Agents)

1. **Contract-driven integration over runtime duplication:** Duplicating execution mechanics (Tick tokens, worktree isolation, retry caps) in a supervisor inevitably creates split-brain state and drift. Establishing additive, versioned machine contracts (`marathon-invocation@1` and `marathon-drive/result@1`) provides a stable, machine-verifiable boundary that works seamlessly across both root and vendored `.xyz` layouts.
2. **Supervisor state mutations vs. executor cleanliness checks:** When a supervisor leases a queue row, it legitimately updates database ledger files (`releases.db`/`releases.sql`). Passing strict `--require-clean` flags from preflight packets into the execution driver causes self-inflicted refusals; supervisors must control cleanliness invariants at their own outer boundary.
3. **Idempotent crash-resilient landing:** GitHub PR merges, SQLite queue projections, and PDDA wave reconciliation belong to separate failure domains. Structuring landing workflows around durable keys `(repo identity, queue global ID, execution ID, merged SHA)` guarantees that failures at any step can safely resume at the missing durable step without duplicate turn dispatches or wasted tokens.

## Post-completion follow-up record (2026-08-28, from #291 review)

PR #281 merged and reconciled; development at `00ac4594`. Codex review (#291) accepted with two
corrections and one sequencing constraint (reply posted, signed GLM 5.3 High). The follow-up
workflow now carries, in order:

1. **Durable fixes for the Phase-4 findings** (new issue; see below) — F1 supervisor-state
   commit-before-dispatch, F2 gid-relative ledger paths + gh-number fallback, F3 dashboard
   regen after promotion. These land FIRST: F2 changes what valid ledger/invocation paths look
   like, so the golden-fixture suite below would churn if authored before it.
2. **#291 Scope 1+5** — standalone contract reference for `marathon-invocation@1` and
   `marathon-drive/result@1` (fields, ownership, outcome vocabulary, version negotiation,
   bounded deprecation window). Correction accepted: the outcome vocabulary is
   approved / refused / escalated / parked / interrupted / crashed / lock-contention /
   post-approve-failed (+ reason `already-satisfied`); there is no "already-landed" outcome,
   and preflight already-landed parks at the queue level without a receipt.
3. **#291 Scope 3** — boundary-regression guard pinning that the marathon executor path never
   writes executor-owned truth (Tick attempts/tokens, terminal results, lane branch/PR
   identity). The legacy `--executor relay` path is the declared exception until its Phase-5
   removal.
4. **#291 Scope 2** — conformance suite with golden `@1` fixtures (there is no prior version;
   "prior" is defined forward by the Scope-5 policy) across root and vendored layouts,
   including future-schema refusal with zero queue/Tick mutation.
5. **#291 Scope 4** — refused/escalated projections name execution_id + result_path (the
   awaiting-landing and landed projections already carry PR/merge identity).
6. **#290 (ATE)** — variation grid on the fuzz-stable surfaces (land verification, receipt
   writer) runs as its own parallel lane; full long-run ATE grinds the grid after the fixes
   stabilize the surface.

Phase 5 (default flip + legacy relay removal) remains gated behind items 1–4.

Status 2026-08-28 (later): item 1 landed as PR #296 (GH-292, merged `e6f91eb8`, reconciled); item 6's
first slice landed as PR #297 (GH-290 variation grid, merged `82881f7a`, reconciled). The PR #281
review's remaining findings B1/B2 (+ test-only B5) are fixed as GH-300 ahead of items 2–5: verified
pre-merge auto-merge and supervisor-locked retry verbs are prerequisites for trusting any broader
contract hardening on the same verbs.
