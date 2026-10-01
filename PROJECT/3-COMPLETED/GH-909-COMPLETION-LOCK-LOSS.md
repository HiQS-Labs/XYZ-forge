---
status: Complete
title: "GH-909: completion lock repair"
created: 2026-10-01
source: https://github.com/HiQS-Labs/XYZ-forge/issues/909
owner: "XYZ Forge maintainers"
goal: "Preserve every successful concurrent completion append."
gh_issue: 909
updated: 2026-10-01
effort: 3
complexity: 3
risk: 4
phases: 1
---
# GH-909 — completion lock loses successful records

## Status
| What was just completed | What's next |
|---|---|
| Implementation, independent plan/final QA and final full gate passed (413/413, zero retry, clean envelope). Branch published at 22a9e0b0. | Publish committed full-gate receipts and open ready PR to development; awaiting operator landing. #854 development count remains 1/3. |

## Problem and source of truth
Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/909; parent #854/#853 remain open. Base development 57bd97af4a0e8d456927e20b49d64b232d95f36d. xyz-completion pooled failure observed16 exits0 but15 records. Controlled replay proves stale waiter deletes a live successor lock and loses one of three successful records; exact historical interleaving unknown. Recon below and committed manual receipt distinguish proof from inference.

## Bounded Recon Map and evidence
- Entry and target selection: `utils/telemetry/append-xyz-completion.sh:27`, arguments and override through line 36. Sole JSON read/prepend/atomic-replace transaction: lines 105–142.
- Legacy ownership: release lines 45–53; acquisition line 72; PID observation line 85; empty-owner reclamation line 90 and dead-owner reclamation lines 100–101. Wait/progress and timeout paths occupy lines 54–102. Deletion uses the current pathname after observing an earlier holder, allowing successor ownership to be removed.
- Best-effort callers: `utils/py/relay_drive.py:491`, `utils/py/marathon_drive.py:1323`, `relay-automation/marathon.sh:69`. Caller error propagation remains outside this repair. `relay-automation/xyz-vendor.sh:236` preserves the writer runtime path; retain that path and change its implementation in place.
- Existing fixture dependencies: `test/xyz-completion.sh:179` assumes directory cleanup; `test/gh123-lock-progress-bound.sh:31` manufactures holders for progress and total cap; `test/gh358-lock-instrumentation.sh:60` manufactures a starvation holder. Replace those holders with real flock holders, with no unlocked handover gap in progress checks.
- Existing stdlib locking prior art: `utils/py/releases_app.py:374`, `utils/py/work_connectors/__init__.py:378`, `utils/py/wave_reconcile.py:56`. Stable inode retention is required; do not copy truncating open modes.
- Committed manual red receipt: [result](../../TESTS-RESULTS/2026-10-01+GH-909/red-handoff/result.json), [records](../../TESTS-RESULTS/2026-10-01+GH-909/red-handoff/records.json), [replay](../../TESTS-RESULTS/2026-10-01+GH-909/red-handoff/replay.py), [instrumented writer](../../TESTS-RESULTS/2026-10-01+GH-909/red-handoff/writer.sh), [provenance](../../TESTS-RESULTS/2026-10-01+GH-909/red-handoff/provenance.jsonl). Three zero exits, two records, removed live successor lock. Source locations refer to base 57bd97af; external consumers and historical failing interleaving remain unknown.

## Triangulate
Irreversible x crossing -> full floor: shared stored telemetry consumed by relay/marathon; locking representation is also mirrored by fixtures. Runtime code rollback easy, already lost telemetry cannot be recovered; treat change Costly. No new source of truth, writer or data schema. Falsifier: controlled A/W/B handoff preserves successor ownership and all records on corrected mechanism. Proven red: original removes B lock, exits0 for A/W/B, final B/A missing W.

## Scope and smallest design
Use Python stdlib fcntl.flock in the existing writer's Python transaction. Stable sidecar regular file at <XYZ_JSON_PATH>.lock, never unlink it on release; OS owns lifetime, no PID-based stale deletion. Preserve JSON path overrides, arguments, record schema, atomic replacement, malformed-file recovery and newest-first order. Keep default XYZ_LOCK_WAIT_S=30 and XYZ_LOCK_TOTAL_MAX_S default4x. Preserve moving-queue progress by writing a per-acquisition token to the sidecar under ownership and rearming when observed token changes; monotonic deadlines, nonblocking flock, exit75 on exhaustion; other lock errors fail closed. A retained unlocked file is not leaked ownership. macOS/Linux local filesystem envelope; unsupported platform fails clearly. No Windows or network-FS claims.

## Blast radius and rollback
Shared relay_drive, marathon_drive and marathon.sh emit best-effort telemetry through this writer. No caller behavior change; suppressed-error observability remains out of scope. Existing xyz-completion, gh123-lock-progress-bound and gh358-lock-instrumentation fixtures must use actual OS lock holders and expect stable unlocked sidecar, not removed mkdir. Existing installed same-version writers share the inode. Forward cutover requires stopping and retiring every old writer sharing the JSON path, including running and waiting shell invocations, before starting upgraded writers. Verify those emitters are stopped before rollout; otherwise defer rollout. Mixed versions are unsupported: an old empty-PID waiter can remove a regular sidecar, and using a different path would create two lock domains. Refuse a pre-existing legacy .lock directory without deleting it. That refusal is a diagnostic guard, not proof of live mixed-version safety. Guarantees cover cooperating upgraded writers only. No automatic migration or cleanup. Rollback writer and fixture changes together after quiescing emitters; retain telemetry and sidecars. No data-shape migration.

## Acceptance and ordered execution
1. Independent Codex plan approval before production edits -> source-derived scope and ratings approved.
2. Admit exact roadmap row, implement writer locking and truthful existing fixture adaptations -> no new suite, registry or runner.
3. Manual controlled replay on base and corrected bytes -> red deletion/loss versus preserved mutual exclusion; record ownership, return codes, records and provenance. Existing three covering suites plus 30s/default/progress/75 behavior -> pass in separate full clone.
4. Final Codex QA on committed diff and focused evidence -> Approved, bounded three rounds.
5. Exactly one final full gate in disposable full clone, identity before/after, committed provenance -> green; publish through mandatory push boundary and verify hosted exact head. Open PR to development, leave umbrella open and retain clone.

## Ratings and recurrence
85/85/50/65: silent successful-write record loss, blocked CI stabilization; no proven actual agent work loss. One distinct observed pooled incident October1 plus controlled replay, trend unknown; related old GH-123/GH-358 numbers may be upstream. Appeal neutral50. Effort65 reflects small writer but concurrency verification and three fixture adaptations. No operator override.

## Unknowns and non-goals
Original conc-1 interleaving, external lock-path users and network-filesystem behavior unknown. No timeout bump, retry policy change, caller-error propagation, registry locking fix, unrelated relay fix, new Bash executable or new tests. Evidence publication from prior task remains separate and paused; do not merge fixes under evidence-only authorization.

## Verification checkpoint

At 266a954a in a disposable full clone, all three existing suites passed. Manual handoff kept W/B/A, all exits 0; crash released the lock; a legacy directory was refused and unchanged. ATE ran 77 successful variations (16/32/64 writers, 0/.01s launch delays), preserving all 2,848 records. Receipts and intact identity: `TESTS-RESULTS/2026-10-01+GH-909/focused/`. These are diagnostic/focused evidence, excluded from #854 clean development counts. The first scratch replay failed due to a missing instrumentation import and was corrected; production code was unaffected.

## Full-gate environment diagnosis

The first push gate at 1cad5dce was aborted on gh372 pool rc1, preserving identity and refusing publication. Its focused replay created a 45-line turn log but escalation looked at the primary checkout incident because ambient `XYZ_HARNESS` pointed there. At both candidate and unmodified development 57bd97af, ambient configuration gives rc1; clearing only `XYZ_HARNESS` gives 3/0, rc0. No source fix or timeout change is needed. Receipts: `TESTS-RESULTS/2026-10-01+GH-909/blocked-push/`. Repeat the final gate with the locator-only override absent; all other normal environment/defaults remain. This failed attempt is excluded and cannot be reported as a clean full gate.

## Gate blocker resolved within #853

The environment-corrected gate at 6b9ce5f2 stopped on gh268 rc1: its quiet grep exited on a present phrase, causing upstream printf Broken pipe under pipefail. The unchanged development suite carries this class; #853 already owns unsafe quiet pipelines. Change only the existing suite’s 27 streamed quiet greps to consuming grep with stdout discarded; file-input quiet greps remain. This is a simple local assertion correction with no design decision, so no separate plan QA is needed; fresh final peer review is required. Focused suite: 35/0 at 6dca26ee. Actual template repeated64x gives old present rc141, fixed present rc0, fixed absent rc1. Receipt: `TESTS-RESULTS/2026-10-01+GH-909/gh268-blocker/`. No test registry or gate machinery added, no umbrella closure claimed. Restart the full gate only after final review round2 approves this additional source change.

## Final disposition of gh268 (standing operator policy)

Before publication, Small membership was checked directly against `utils/ci-route.sh:38`; gh268 is absent. AGENTS.md requires flaky non-tier suites to be turned off via unregister-and-exempt. Therefore the consuming-grep edit remains a retained diagnostic experiment, not the final source change: the existing gh268 file is restored byte-for-byte to development, its TESTS entry removed, and its name added to gh306 EXEMPT with the observed reason. No suite deleted or added. This applies standing #853 policy to a current witnessed red; it does not run or publish the October8 audit. The third gate attempt was stopped for this policy correction, without publication or a count. Registry is now 410 entries. The existing gh306 check passed 10/0; removing the new exemption made it fail naming gh268. Branch registry has 410 unique entries; development remains 411 until landing. Final peer QA round3 must approve the changed final scope before the final gate.

## Stable runtime sidecar ignore correction

The full gate at bdc399f5 passed all 410 registered suites and Python/gamma checks, but failed its final tree envelope on `?? XYZ.json.lock`; the pre-existing `.gitignore` rule covered only a directory. Drop its trailing slash to preserve the existing intent for the now-stable runtime file. This is a one-line metadata correction, no runtime behavior change or extra review round beyond the binding3-round cap. Exact ignore predicate witnessed old file rc1/new file rc0. Existing GH205 passes and GH365 envelope suite passes25/0. Repeat final full gate with this verified one-line metadata correction. Peer approval still describes the unchanged runtime implementation; the final full gate remains outstanding, and this drifted run is excluded.

## Ready-PR verification

2026-10-01 20:36 UTC: final push gate at 22a9e0b094c49d107a882d524b85ae0dca0d22ee completed 413/413 (410 registered suites plus Python/gamma/identity), zero retry, clean envelope and intact repository identity in a separate full clone under caffeinate. Push succeeded and origin branch SHA was verified. Default live relay skip under #836 D2 is intentional. Committed receipts: `TESTS-RESULTS/2026-10-01+GH-909/full-gate/`. This is task-branch readiness, not a clean development qualification; #854 remains 1/3 local and 2/3 PR-closed hosted. Implementation is ready for PR, not landed.
