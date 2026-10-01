---
status: proposed
gh_issue: 909
updated: 2026-10-01
effort: medium
complexity: medium
risk: high
phases: 1
---
# GH-909 — completion lock loses successful records

## Status
| Phase | Status | Notes |
|---|---|---|
| Recon and red control | Complete | Three successful writers produce two records in controlled handoff |
| Plan QA | Pending | Codex independent relay |
| Implementation and verification | Pending | No production changes |
| Final QA and PR | Pending | Ready PR, no merge implied |

## Problem and source of truth
Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/909; parent #854/#853 remain open. Base development 57bd97af4a0e8d456927e20b49d64b232d95f36d. xyz-completion pooled failure observed16 exits0 but15 records. Controlled replay proves stale waiter deletes a live successor lock and loses one of three successful records; exact historical interleaving unknown. Recon below and committed manual receipt distinguish proof from inference.

## Triangulate
Irreversible x crossing -> full floor: shared stored telemetry consumed by relay/marathon; locking representation is also mirrored by fixtures. Runtime code rollback easy, already lost telemetry cannot be recovered; treat change Costly. No new source of truth, writer or data schema. Falsifier: controlled A/W/B handoff preserves successor ownership and all records on corrected mechanism. Proven red: original removes B lock, exits0 for A/W/B, final B/A missing W.

## Scope and smallest design
Use Python stdlib fcntl.flock in the existing writer's Python transaction. Stable sidecar regular file, never unlink it on release; OS owns lifetime, no PID-based stale deletion. Preserve JSON path overrides, arguments, record schema, atomic replacement, malformed-file recovery and newest-first order. Keep default XYZ_LOCK_WAIT_S=30 and XYZ_LOCK_TOTAL_MAX_S default4x. Preserve moving-queue progress by writing a per-acquisition token to the sidecar under ownership and rearming when observed token changes; monotonic deadlines, nonblocking flock, exit75 on exhaustion; other lock errors fail closed. A retained unlocked file is not leaked ownership. macOS/Linux local filesystem envelope; unsupported platform fails clearly. No Windows or network-FS claims.

## Blast radius and rollback
Shared relay_drive, marathon_drive and marathon.sh emit best-effort telemetry through this writer. No caller behavior change; suppressed-error observability remains out of scope. Existing xyz-completion, gh123-lock-progress-bound and gh358-lock-instrumentation fixtures must use actual OS lock holders and expect stable unlocked sidecar, not removed mkdir. Existing installed same-version writers share the inode. Mixed old/new writers differ in protocol: fail closed if old .lock directory exists; no deleting active old holders. No automatic migration or cleanup. Rollback writer and fixture changes together after quiescing emitters; retain telemetry and sidecars. No data-shape migration.

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
