RUN-RECORD-VERSION: 1
LANDING_CLONE: ~/flywheel-runA-run

# Flywheel Run A run record — ledger #1658 — accounting, admission, resume and landing (OL-13/10/15/16/17)

<!-- derived from build_queue.py (GH-1527) --daily-goals 1658 as of 2026-11-27; edited by the run owner to the actual Run A authority and order -->

- UTC launch: 2026-11-27T22:54:17Z (launch step: four unchecked task lines added to the #1658 body; operator launch authority 2026-11-27, parent brief)
- Window: 5 h = 2026-11-27T22:54:17Z to 2026-11-28T03:54:17Z. Dispatch deadline 2026-11-28T03:24:17Z (epoch 1795836257); evidence/handback reserve 03:24:17Z to 03:54:17Z (epoch end 1795838057).
- Base: origin/development d73ecb0e620aa35fdbdee4974aaa713119c1d7ec (includes #1668, #1669, #1670, #1672, #1675)
- Roles: builder codex, reviewer agy (capacity: one bounded real request each at 22:56Z, both answered); one execution owner = this run-owner session; parent = observer/recovery agent
- Resume owner and version (OL-15 record): owner = run-owner session; version = this record's latest checkpoint commit on branch flywheel/runA-run-record-2026-11-27, plus the Jog queue state in the coordinator clone

## Roots
- Coordinator and Jog writer (pinned by clone-local config only): ~/flywheel-runA-run
- Execution clone: ~/flywheel-runA-exec
- Checkpoint publication clone: ~/flywheel-runA-ckpt
- Scratch and logs: ~/flywheel-runA-scratch

## Authority granted (one grant, covers the whole run)
- Dispatch and PR publication for the four declared inputs only (#1666, #1423, #1638, #1480), through the existing Jog -> Preflight -> Marathon path, in that queue order.
- IN-RUN LANDING IS NOT AUTHORIZED (OL-16). The run opens PRs, posts exact heads on #1658 and stops for the operator's exact-head approval; the parent then runs merge-cleanup with those pins.
- Merge, deploy, installed-skill update, issue closing, ledger rewrites outside the owner writers: NOT granted.
- Decision defaults (KS-11, fail-closed) apply as written in the Kickstart skill; at most 4 review rounds, then the consult tie-break; a Consult-Adjudicated result is never recorded as approved and never auto-merged.
- One repair sub-session at a time within the 30 min incidental reserve, recorded as assisted.
- Hard rules: no manufactured stall, no re-pend of GH-1315 / GH-1171 (exhausted), no task rename to dodge an attempt budget, no --no-verify, servers read-only, never write to ~/Documents/GH Repos/XYZ-forge, never touch #1400/#1418 except reading.
- Status: NO MERGE GRANT. Dispatch authority: operator, via the parent's launch brief of 2026-11-27.

## Queue (execution order)
1. #1666 swarm_preflight: acceptance readers split lines on Unicode separators (Conveyor-prepared packet, round_cap 9, prepared_commit 6142128d9c43).
2. #1423 relay-drive: attest-publish-failed when the relay file is under a gitignored path (same preparation).
3. #1638 relay turn worktree seeding nests an existing allowlisted directory (same preparation). The issue had been auto-closed by the prep PR #1675 merge; reopened by the run owner at launch (see I-1).
4. #1480 merge-cleanup decomposition: HELD on open #1475; expected to be refused before the lease with the hold reason (OL-10 held witness). Last in order so the refusal does not end the wake early.

## Needs the operator (the run parks these and keeps going)
- Kickstart's classifier lists #1423 and #1666 as "unclassified; operator picks scope". The operator's #1658 plan and the parent's launch brief name them, so they are dispatched through Jog under that decision.
- Not queued, never selected: GH-1315 and GH-1171 (exhausted rows; stay parked/failed).

## Handback checkpoint 1 (2026-11-27, item boundary after GH-1666 and GH-1423)

State at the deliberate handback, to be re-verified by a fresh observer (this section is a claim, not proof):
- Wake 1 command (finished, exit 0, host background task): jog run --target-root ~/flywheel-runA-exec --builder codex --reviewer agy --max-tasks 2 --supervise-until 1795836257; log ~/flywheel-runA-scratch/wake1.log; UTC 22:57:32Z to 23:53:59Z.
- GH-1666: execution gh1666-exec1, one codex turn and one agy review (Approved on f800470df, first review), pre-advance gate bash test/gh400-acceptance-fidelity.sh green, PR #1676 head bf0f48ef23fdb10748c7559604d4271a3c778adf (receipt commit), published with NO manual gate-attempt reservation.
- GH-1423: execution gh1423-exec1, several codex/agy rounds, agy attested Approved on 3142e3524, pre-advance gate bash test/gh505-* green, PR #1677 head cade2393d5a0371e62c08c53b9545f81db37d40b (receipt commit), published with NO manual reservation.
- Both Jog rows parked awaiting-landing, attempt 1 of 3 each. Next eligible action: GH-1638 (pending, 0 attempts), then GH-1480 (pending, expected hold refusal). GH-1315 and GH-1171 must not be selected.
- Authority, deadline and attempts unchanged: dispatch deadline epoch 1795836257 (2026-11-28T03:24:17Z); no merge grant.
- Roots: coordinator and Jog writer ~/flywheel-runA-run; execution ~/flywheel-runA-exec; checkpoint ~/flywheel-runA-ckpt.
- Wake 2 (the resume), exactly: jog run --target-root ~/flywheel-runA-exec --builder codex --reviewer agy --max-tasks 2 --supervise-until 1795836257

## Events
BASELINE: origin/development d73ecb0e6; Jog queue at launch empty (history only); hosted sweep after the engineering batch clean (parent record: run 46074422792 on 6d135c95b, 408/408)
INTERVENTION: I-1 2026-11-27T22:55:00Z #1638 had been closed by the prep PR #1675 merge while its bug is still present on development (relay-turn-lib.sh:784); build_queue.py --daily-goals 1658 therefore omitted it; run owner reopened #1638 with an explanatory comment. Finding for the handback.
APPLIED: I-1 → applied #1638 reopened 2026-11-27T22:55Z, queue regenerated with #1638 first in the generated order
INTERVENTION: I-2 2026-11-27T22:56:03Z jog run --dry-run (target-aware, max-tasks 4): GH-1666, GH-1423, GH-1638 preflight ready (exit 0); GH-1480 reported unreviewed-probe-contract in dry-run, because the dry-run path evaluates the inbox probe lint and does not call hold_refusal; the live run calls hold_refusal before the lease. Finding, not an assist.
APPLIED: I-2 → applied recorded; the live `jog run` is the OL-10 held witness, the dry-run is not
GATE: GH-1666 head bf0f48ef23fdb10748c7559604d4271a3c778adf full green (duration not recorded)
GATE: GH-1423 head cade2393d5a0371e62c08c53b9545f81db37d40b full green (duration not recorded)
BASELINE: wake 1 22:57:32Z to 23:53:59Z delivered PR 1676 (GH-1666) and PR 1677 (GH-1423) with zero manual receipt reservations (OL-13 live); GH-1638 and GH-1480 pending; item boundary reached 2026-11-27T23:54Z
INTERVENTION: I-3 2026-11-27T23:55:00Z run_record checkpoint --push needs one manual gate attempt reservation (#1673 known assist), booked in the run clone accounting root, task GH-1658-runA-run-record
APPLIED: I-3 → applied booking made and finished around the checkpoint push; checkpoint branch flywheel/runA-run-record-2026-11-27
INTERVENTION: I-4 2026-11-28T00:00:00Z the first checkpoint push booked its reservation while the checkpoint clone was still on development, so the gate refused (pushed task ref differs from the reserved branch); rebooked on the checkpoint branch and the push succeeded (2 bookings for checkpoint 1; both assists, both consequences of #1673)
APPLIED: I-4 → applied checkpoint 6ac46614b pushed 2026-11-27T23:56:48Z; both reservations finished
GATE: GH-1638 head 97b0d40c60bd508343db18d7c4c3b3bfd54480db full green (duration not recorded)
BASELINE: wake 2 (the resume, host background task) 2026-11-27T23:57:35Z to 2026-11-28T00:22:08Z: GH-1638 delivered as PR 1678 (head 97b0d40c60bd508343db18d7c4c3b3bfd54480db), one codex turn and one agy review, zero manual reservations; GH-1480 refused before the lease with 'hold: capture body HELD: marker', attempt count 0; GH-1666, GH-1423, GH-1315, GH-1171 not re-selected, attempt counts unchanged (1, 1, 0, 2)
BASELINE: disposable-clone control at d73ecb0e6 (clone ~/flywheel-runA-control) 00:22:51Z to 00:26:21Z: gh280 suite 262 pass 0 fail incl. G4-neg (unreserved push refused) and G9-G13; labelled replay control.txt CASE_KIND=stale-evidence: refusal before lease (attempts 1 to 1), refresh admitted on the same row id (no reset); replay and suite are REHEARSAL, not live witnesses
PARENT_NOTE: PN-1 2026-11-28T00:30:00Z queue exhausted: all four rows terminal for this wake; operator approval of exact PR heads (1676, 1677, 1678) is the next gate; no further qualified item and none invented
APPLIED: PN-1 → applied PR heads posted on 1658 and the run stops for the operator's exact-head approval
