TITLE: merge-cleanup: a `jog land` refusal in the Jog hook leaves the post-merge reconcile writes uncommitted in the primary

## Observed (GH-1175 Phase 0, PR #1225, 2026-10-27)
After merge + local `wave_reconcile --pr 1225` passed, the Jog hook's `jog land` refused (GH-1208) and merge-cleanup stopped (exit 2) **before** its post-merge commit/push. The primary was left with modified `releases.db/.sql`, `LEADERBOARD.md`, the doc move to 3-COMPLETED, and an untracked generated MARATHON-PLAN file. A concurrent session (#1217) could not land until these were committed by hand (`5265cfad`).

## Proposed remedy (for review)
Treat a Jog-hook refusal as "row stays parked" rather than a landing failure: commit/push the reconcile writes, report the refusal, exit non-zero after the durable step. Or document the manual commit as the recovery. GH-1208 removes the common trigger but not the class.
