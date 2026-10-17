---
gh_issue: 1108
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1108#issuecomment-6231071222
title: "Jog one-writer execution, receipts and landing hook (delivery 1 of 2)"
status: Active
created: 2026-10-17
updated: 2026-10-17
owner: noelsaw1
goal: "Jog writes and publishes ledger transitions only in the primary; disposable execution clones deliver committed receipts for primary landing."
doc_type: fix
effort: 4
complexity: 4
risk: 4
phases: 1
---
## Status

| What was just completed | What's next |
|---|---|
| Delivery1 source and scoped controls recorded; final QA found a canonical-reader mismatch; diagnostic gate405/409 | Codex Round4 Approved/attested; qualifying push gate, primary historical recovery, then PR1 and dependent draft PR2 |

# GH-1108: one writer, durable receipts

## Authority and history

The operator's design frame (issue comment 6231071222) superseded the original symptom-only plan before any production edits. Original plan snapshot: `TESTS-RESULTS/2026-10-17+GH-1108/original-symptom-plan.txt`. The first relay declared PASS but its close attestation was refused (`close-mismatch`); it is not a qualified approval for implementation. The roadmap admission was recorded prematurely after the review content; no production work followed. The revised one-writer plan was Approved in round 2 before implementation; its valid attestation is `TESTS-RESULTS/2026-10-17+GH-1108/plan-attestation.json`.

## Recon Map

Base: `b26c9edb73f61587a71287f68cb4338409188042`. Task clone/branch follow the issue's `jog-land-receipts` slug; primary is the operator's existing development checkout. Graph project XYZ-forge generation 2026-09-01T15:54:30Z is stale. Search/coverage supplied leads, not current proof: changed metadata in `jog_run.py`, `releases_app.py`, `marathon_drive.py`; merge-cleanup scripts not tracked in the graph. Current source was read for material paths; two read-only recon lanes traced publication and execution independently.

| Entry / state | Current behavior / existing seam | Required change |
|---|---|---|
| `releases_app.py:4490–4941` Jog queue mutations | All converge on `perform_write`; closures capture row identity and mutable event lists | Guard every mutating entry, publish each transition in primary, retry fresh command intent |
| `perform_write:1657–1773` | Writer lock, journal, canonical transaction/receipts, SQL dump and adopted preview; connector dispatch after unlock | Reuse writer, extend its publication envelope for Jog; defer connectors until accepted publication |
| `jog_run_main:1641–1757` | One root controls queue, promotion, preflight, execution | Primary supervisor plus explicit disposable target root; no primary source dispatch |
| `run_marathon_phase:528–641` | Cache/preflight root same; structured invocation argv/env from #1104 | Keep primary cache, clone-rooted preflight/harness/target; queue projection stays primary |
| `promote_contract_to_working:1210–1300` | Moves doc and invokes roadmap repoint in same root | Move task doc in clone; repoint via primary roadmap writer and publish ledger there |
| `marathon_drive:2786,3672` | Opens lane PR before terminal result is emitted in finalizer | After subprocess exit, publish exact evidence bundle to lane before outcome projection |
| `jog_land:897–1071` | Requires local cache, same source path, exact head, local-base reachability; marker precedes queue transition | Read committed bundles from merged primary tree; verified tail proof; origin integration reachability; idempotent primary completion |
| `merge_cleanup.py:621–722,1233–1252` | Wait hosted reconcile / local fallback, ff primary, then commit post-merge writes | Positively map Jog rows and call land in post-merge sequence; share final durability step |
| `ledger_merge.py:35–39,496` | Canonical B1 set plus CHANGELOG | Reuse this exact six-path policy, no parallel wider allowlist |

No saved primary resolver exists: merge-cleanup requires explicit `--primary`. No safe meaningful-primary publish retry exists: hosted publisher resets/checks out on rejected push and must not run on primary. B1 replay handles roadmap verbs, not Jog transitions. The plan must extend these seams honestly rather than calling existing behavior sufficient.

Existing `gh280-jog-marathon-adapter.sh` passes 223/223 on base in a separate full clone, with origin/config/HEAD unchanged (`TESTS-RESULTS/2026-10-17+GH-1108/gh280-base.log.gz`). Base red controls reproduce exact-head refusal and unsupported source-ledger argument; these remain historical symptom evidence, not the new acceptance contract.

## Five-point requirements

1. Primary is the only writer of every ledger row touched by Jog. Mutating subcommands and low-level entry points refuse task clones before any cache/schema/doc/queue write and name the primary. Primary invokes execution in a disposable clone through existing preflight and Marathon argv/env plumbing; no new executor/scheduler.
2. Each queue transition becomes an explicit ledger-only commit and normal fast-forward push on development immediately. On non-ff, bounded fetch/rebuild/retry through fresh canonical writer invocation; never merge DB blobs, hand-edit SQL, or use reset/checkout on primary. Success requires remote verification and clean primary. Failed/unknown publication stops dispatch/advance.
3. Approved result, portable copied gate evidence and provenance travel in the lane under `TESTS-RESULTS/<date>+GH-<n>/jog/<execution-id>/`. Cache is restart convenience only; landing discovers committed bundles without `.tick`.
4. Primary lands after ff, checks GitHub state/repo/base/head identity, approved gate evidence, fetched origin integration reachability, and mechanically justified approval-preserving tail. No receipt path binding to retired clone. `releases check` must be clean and hosted reconcile green. Record original approval and actual delivery head separately.
5. Merge-cleanup invokes land for positively mapped Jog PRs after successful merge/reconcile and ff. Reuse post-merge publication, avoiding second scheduler/writer or duplicate lifecycle work.

## Mechanical tail proof (operator-directed)

Require approved head ancestor of reported PR head. Walk first-parent tail back to the approved head; an ordinary tail commit may touch only the six B1 paths. A two-parent upstream merge is allowed only if its second parent is reachable from freshly fetched `origin/<integration>`. Strip the six paths from both input trees and the recorded merge tree; recompute their merge with `git merge-tree --write-tree`, preserving merge-base history. Require conflict-free recomputation and exact tree equality, including modes, missing paths and extra blobs. Octopus merges, Git failures, unreachable parent, remaining conflict or mismatch refuse; no manual override. Record both stripped input tree IDs, recomputed tree ID, recorded stripped tree ID and excluded list in landing evidence. This proves nonledger content only, so clean RELEASES check and green hosted reconciliation remain required.

Historic #1102: direct recomputation of `974d98db` exits 1 only for releases.db/sql; operator approved excluding those paths before recomputation. Original receipt remains `6f521bc5`; do not relabel it as approval of `974d98db`. First-parent `b3811f0a` is a ledger-only transition. Historic #1101 approved receipt is `088f5cd9`. Both original execution/gate evidence sets are available in the operator-named verify clone and will be re-emitted, retaining original bytes/provenance and source identity. GH-942's missing base/PR metadata must be bound explicitly from verified GitHub truth, not guessed or rewritten into old approval.

## Two-PR boundary (operator decision)

Delivery 1 (this task branch): Jog primary guard, clone execution routing, committed portable receipts, mechanical landing verification, merge-cleanup post-merge hook. Queue/lifecycle mutations still use existing primary writer and merge-cleanup's existing post-merge commit/push step. No immediate transition-push or NFF replay path is added in this PR. It must be possible to revert delivery 2 while keeping this behavior.

Delivery 2 (separate dependent PR): immediate ledger-only transition commit/push and bounded NFF fresh-intent replay. Keep requirements 2 and its publication/connector/lock hazards as the follow-up contract. No claim that primary run transitions are remotely durable before delivery 2. Interim operator checkpoint before merge-cleanup: inspect primary Git status/diff/index and existing local supervisor commits; refuse unrelated changes or divergence, commit only the owned Jog ledger/view paths with an explicit path list, and normally push existing integration commits. Confirm a clean primary with no unpublished commits and ff readiness before invoking merge-cleanup. A rejected push preserves local state and stops for operator reconciliation; delivery 1 never automatically resets/replays it. Do not weaken Phase 0. No merge is authorized. Prepare the dependent implementation only after delivery 1 lands unless the operator authorizes stacking.

## Delivery 1 implementation design

- Bind the primary explicitly, independently of CWD/harness installation. Proposed default: an origin-keyed Git config primary-path pin, read by Jog and validated against merge-cleanup's explicit `--primary`. Unknown or mismatched binding refuses mutating Jog calls; task clone refusal names the pinned primary. Setup is an explicit operator config action, not automatic inference. Read-only list/export/dry-run remain read-only. Guard low-level queue writers and run/retry/land before their cache/schema/Git writes; generic non-Jog PRS writes remain outside this change.
- Add an explicit disposable `--target-root` for execution. Primary keeps queue/cache/driver supervision; preflight CWD, SWARM_PREFLIGHT_ROOT, invocation harness_root/target_root and executor env point to the clone. Reuse #1104 argv/env helpers. Do not export the primary's held-driver-lock bypass into a distinct target clone. Require separate full clone and matching origin before lease. Clone doc promotion must not call its roadmap writer; primary repoint uses the existing writer. Keep clone releases artifacts out of supervisor commits and lane PRs.
- After approved Marathon result exists, publish its exact bundle and copied gate content using explicit paths, validate via existing gate receipt head/zero-exit contract, then push the existing lane. Park on publication failure. Cache remains for run/resume/retry, but landing never depends on cache. Historical imports retain original bytes and provenance, with explicit verified PR/base binding when legacy receipt omitted them.
- Receipt publication cannot embed its own publishing hash. Proposed default: a single mechanically validated evidence-only commit after the approved SHA is permitted, changing only this execution's exact bundle paths and preserving result approval/gate identity. Ordinary source paths remain forbidden. Following tail commits must satisfy B1-only or recomputed upstream proof. Landing validates bundle bytes from committed tree, not arbitrary local files. This necessary publication case is recorded separately from the six-path ledger exception.
- `jog land` finds committed bundles in the primary, validates nonempty provenance/gate/issue/repo/base/head, fresh GitHub merged truth, origin reachability, and mechanical tail proof above. Fetch failures refuse. Require clean `releases check` and hosted reconcile green; no manual override. Destination queue identity must be unique. Local cache markers cannot suppress completion; completed queue is a no-op on replay. Record proof tree IDs and original vs actual heads in committed landing evidence via the existing post-merge publication step.
- Refactor land/reconcile only enough to let merge-cleanup call landing after hosted reconciliation without running a second local reconciliation. Map verified PR issue identity/body/branch to an actionable Jog row (pending/running/failed/parked); archived/dropped/completed rows do not pull unrelated follow-ups into Jog. A mapped actionable row without valid committed evidence still refuses, as required; do not silently skip a missing receipt. Land refusal stops the post-merge sequence. Reuse its final primary commit/push for completion and evidence.
- No --ledger-root fallback, second writer, scheduler, clone cache copying, new suite or new gate machinery.

## Delivery 2 retained design constraints

Extend existing writer/publisher boundary, never the hosted publisher's destructive reset path. Rebuild rejected transitions from fresh high-level Jog intent with reopened DB and freshly resolved identities/event lists. Keep canonical `perform_write` receipts/dump. Retain owned failed commit and intent evidence, restore only owned pre-write ledger bytes with exact HEAD/CAS protection, fetch/ff and retry within fixed budget. Refuse unrelated dirty files/index state. Never force-push or overwrite upstream ledger. Publication success requires fetched remote verification; connectors run only after acceptance, outside writer lock. Unknown remote outcome stops/reconciles rather than blindly replaying. This design requires its own plan/final QA in the second PR.

## Solution fit, blast radius and rollback

Outcome is one canonical durable queue, not two loosened receipt predicates. Alternatives rejected: source-ledger flag still requires untracked clone state and does not prevent clone ledger divergence; arbitrary ancestor acceptance permits unreviewed source; repeating stale DB commits corrupts upstream history/digest chains. Existing executors, preflight, PRS writer, B1 policy and merge-cleanup publication remain authoritative.

Reversibility: Costly across queue, Git publication, execution routing and post-merge integration. Code revert restores old behavior; committed receipts and transition commits stay readable. Preserve recovery refs/intent evidence on failed publication, never undo an already accepted remote transition. No schema migration, new scheduler, new tests/suites/gates, or general publisher redesign. No network tunnel. Historic receipt source clone is read-only and preserved.

## Ordered execution and acceptance (delivery 1)

1. Commit revised plan/recon and ratings, obtain qualified independent Codex plan relay approval before code. Resolve/re-admit the exact roadmap row; preserve original start.
2. Extend primary binding and guard Jog writes; separate supervisor and disposable execution through existing preflight/Marathon plumbing. Manual controls: task clone refuses with named primary before writes; valid primary dispatch leaves target releases.db/sql byte-identical and lane PR without ledger diff; explicit invocation roots visible.
3. Publish committed portable bundles and implement tail/tree proof plus cache-independent primary landing. Controls: missing/empty evidence, source edit, altered merge tree, nonledger conflict and unreachable parent refuse; ledger repair and proven upstream merge pass; receipt evidence-only publication is validated narrowly; stale local integration is checked through fetched origin; record all required tree IDs.
4. Integrate mapped post-merge landing after hosted reconcile and primary ff, before existing final publication. Witness ordinary run completion leaving a dirty/unpublished primary and normal Phase-0 refusal, then apply the documented owned-state checkpoint and require clean/published ff readiness before the post-merge hook; record this end-to-end control. Replays emit no duplicate transitions. Re-emit original GH-1087/#1101 and GH-942/#1102 receipts read-only from the named verify clone; prove both land from primary with clean ledger and hosted evidence. No old approval rewriting, no task PR merge.
5. Run existing covering suites in disposable full clone, adjusting fixtures only for intentional behavior changes. No new suites/registry entries. Record commands/results/provenance under `TESTS-RESULTS/2026-10-17+GH-1108/`. Obtain final independent Codex QA and required gate, open development PR, inspect actual base/head/checks. Retire only safely published task/helper clones; preserve historical receipt source.
6. Track delivery 2 separately and implement its reviewed scope after delivery 1 lands (or explicit stacked authorization). Its acceptance covers per-transition ledger-only commit/push, bounded raced retry preserving upstream work, remote durability and clean primary, plus independent rollback of push path.

## Rating

Initial symptom rating 85/80/50/60 is superseded by broader one-writer scope; proposed 90/85/50/35 (priority/severity/neutral appeal/effort cheapness). The queue's canonical durability and all execution state transitions are affected; this is materially more work and risk. #1093/#1100/#1108 are operator-identified same design-class failures, not three independently proven identical traces. No unsupported 14-day trend multiplier or override.

## Implementation recon refinement

Clone promotion moves/commits only the issue contract in the disposable clone. Its primary roadmap pointer stays at the existing primary doc until that movement lands; hosted wave reconciliation then uses the canonical roadmap writer. Repointing primary immediately would name a doc that exists only in an unmerged clone. The old supervisor-state commit helper is replaced with an explicit execution-contract-only commit; it cannot stage clone ledger files. Primary transition publication remains the manual checkpoint until delivery2.


Native `--auto-merge` dispatch/retry refuses before leasing in delivery1, since the manual primary publication checkpoint must precede merge-cleanup. Legacy simulate mode and exact pre-merge verification helpers remain unchanged. Automatic publication and any automatic advance through that checkpoint belong to delivery2; the flag cannot silently bypass the first delivery's documented boundary.

Final implementation recon also witnessed the global `--root` argument being overwritten by landing/recovery subparser defaults. Those defaults now use `argparse.SUPPRESS`, preserving explicit primary selection from a foreign CWD. GitHub verification/mapping explicitly names the primary origin repository, so ambient `GH_REPO` cannot redirect this proof. Plain/older non-Jog consumers retain merge-cleanup behavior; mapped committed-receipt Jog landing requires the upgraded harness.

Final QA refinement: `--reconcile-pr --execute` uses the same final post-merge publication step as the normal loop; dry-run publishes nothing. Runtime capability is checked beside the exact resolved releases CLI, independently of the skill installation's B1 policy.

## Resumable blocked checkpoint (2026-10-17)

No PR published and no code merged. Primary checkout remains clean at b26c9edb, with original GH1087 running/GH942 failed rows untouched. Final Codex3/3 Escalated: B1 line-parser cannot authoritatively read newline-containing Jog failure reasons; reuse canonical root-bound Jog JSON interface. Opus2/3 requests truthful gh436 publisher mock/assertion. Diagnostic full gate at9ec177d5 (not final source)405/409, identity intact; gh777 inventory corrected later, gh605 and gh290/gh291 fixtures still need primary/committed-receipt updates. All retained in evidence summary/provenance. No new suites.

The exact next action is operator authorization for one additional bounded Codex round, followed by the reader and existing-fixture fixes, focused controls, remaining Opus3 review, approved final-source gate and only then publication/recovery. A stacking question is also pending; delivery2 production work is not started. Existing source is through03fb2fd9, followed only by review/evidence checkpoints. The first Round3 attempt was interrupted without a verdict before incorporating Opus findings; the resumed Round3 produced the concrete reader defect and reached the binding cap. Do not quietly restart or rename the relay to evade it.

## Operator-authorized continuation (2026-10-17)

Round 4 authorized by the operator as an exception to the three-round cap, scoped to the multiline queue-reader defect from round 3.

Resolve that concrete reader defect through the canonical Jog JSON interface and truthfully update existing fixtures; no new test files or registry entries (GH-831). Run exactly one additional Codex final-review round. If Round4 is not Approved, stop and hand off the open finding; no fifth round.

The operator also authorizes a dependent stack: delivery2 opens as a draft against development, with `depends on #<first PR>` in its body. After delivery1 lands, rebase delivery2 onto development so only transition publication is in its diff before any review. No merges authorized.

The bounded reader closure also preserves the observed pre-Jog consumer case (Opus B5): a nonempty qualified dump without a canonical Jog marker/INSERT surface skips the unsupported CLI. When a queue surface exists, canonical JSON extraction remains authoritative and any reader failure refuses. Actual copied-consumer red/green and repeated multiline controls pass at5f223ca3. Opus3 is Escalated; its concrete B5 finding is implemented before the single authorized Codex4, with no fourth Opus turn or fifth Codex turn.

Codex Round4 is Approved/attested at reviewed64c02e8d; no fifth. The final-source qualifying push gate and actual primary recovery now follow. Opus findings through round3 are retained, with its final B5 fixed and covered in the authorized Codex closure. No Opus approval is claimed.
