TITLE: Jog/Marathon lane runs the full gate twice on the identical tree (pre-advance + lane pre-push)

## Observed (GH-1175 Phase 0, gh416-exec2, 2026-10-26)
Pre-advance `validate.sh --auto development` (tier 3, 409/409, 787 s) on `80a11644`, then the lane PR push's pre-push hook ran the full gate again (634 s) on the same tree. 23m41s of a 28m07s run were gates; agent turns were 2m54s.

## Proposed remedy (for review)
Let the lane push reuse the pre-advance gate receipt for the identical tree/SHA (the receipt already exists at `.xyz/receipts/<sha>.json`), the same way merge-cleanup reuses qualifying runs whose SHA covers the scope. No new gate machinery; measure before/after.
