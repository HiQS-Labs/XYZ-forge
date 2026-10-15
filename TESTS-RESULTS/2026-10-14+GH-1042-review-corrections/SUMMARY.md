# PR1054 review corrections — current-base evidence

Source519e9014, refreshed onto development7bc727cb. Existing34 manual outcomes passed in a separate full clone. The two-phase retry intentionally exits7 and dispatches the failing p2 stub; its result is now null rather than the earlier approved p1 object. Original pre-correction receipts are retained under the older date and are superseded only for that result association. No production recovery code was changed by the review corrections, no new CI tests/cases were added and no live provider/run was activated.

Ledger conflicts were proven disjoint and replayed by the installed ledger resolver. The CLI does not expose a positional-update verb; the retained position-repair receipt records a one-time two-GID change through the existing releases_app.perform_write transaction owner. Only positions changed, to127/128; ratings and all other row fields were checked unchanged. GH1045 raw text was corrected through roadmap update. Releases check passed with0 failures and9 historical warnings.

Before/after clone HEAD, origin, bare flag and local config digest match. Absolute disposable-clone paths in published logs are normalized; original local raw output remains in the gate clone. Existing final QA was2/3 and the updated head uses its remaining third review; the cap is unchanged. The normal updated-head publication gate is still required.

## Completed hosted reconciliation refresh

Hosted Wave38649763226 succeeded on2026-10-14 and advanced development to69666c47. Repair2/2 used the existing disjoint-only resolver: keep our higher generation1638, replay only GH1043 repoint/section/marker/raw-text metadata, rebuild and check. The reviewed GH1042/GH1045 rows are exact matches before/after, and all three reviewed recovery/attestation/Jog runtime blobs are byte-identical. Adopted LEADERBOARD.md is retained byte-for-byte from hosted development; this task introduces no routine view delta. Original final QA3/3 remains intact, not reset. This administrative refresh requires fresh normal exact-head publication checks and automated review; it does not claim a new independent core review or promotion qualification.

## Required gate assertion failure

The normal full gate reported gh75-dashboard rc1: its existing has helper uses printf piped to grep-Fq under pipefail, and the release-status check printed a printf Broken pipe. The unchanged existing suite passed8/8 in a separate full diagnostic clone. This establishes an assertion termination problem; it is not dismissed as an unimportant flake or waived gate. The existing validator performs its drained-pool sequential retry; the final gate result is recorded separately. No test/helper/case was changed, and no review/repair cap was reset.

## Normal full publication result

The installed pre-push hook passed409/409,0 failures, on macOS at2fe59019bc331f290ea8b6cfb04c481291e9ed23 in1402seconds and published that exact ref. Clone HEAD, origin, bare flag and local-config digest stayed identical. Two suites required the validator's built-in drained-pool sequential retry: gh75-dashboard and jog-queue; both passed in that retry. The runner labels these contention generically; the dashboard's retained raw evidence specifically shows early-exiting quiet-grep/SIGPIPE, the class already tracked by openGH853. Jog's first-pass refusal delta remains unexplained beyond its isolated/native-retry passes; it is not called harmless or waived. No test/helper/case was edited. This is full local publication evidence, not main promotion qualification. The later reconciliation-only docs/ledger update still goes through its own normal push gate.
