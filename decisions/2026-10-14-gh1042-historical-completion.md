# Historical phase completion and current merge approval — GH1042/GH1045

Recorded2026-10-14 for the Costly bet already implemented in PR1054.

The existing attestation owner binds an optional historical completion candidate; strict current-head merge approval stays separate. This preserves later-phase recovery without approving successor source or introducing a second approval writer.

Expected signal: on the next independently authorized multi-phase run, already stamped phases recover after later source commits while unreviewed current heads remain ineligible for merge. Review the available evidence by2026-10-28. If no eligible run occurs, the operational signal remains unverified; do not activate a run to manufacture evidence. Existing deterministic fixture evidence establishes the bounded recovery/refusal behavior only.

Recommendation: iterate. Graduate the operational claim after the authorized run supplies both recovery and strict-merge evidence. Revisit or abandon historical recovery on a false satisfaction, an approval attributed to unreviewed current HEAD, or repeated metadata-write failures.

Rollback: revert the two Python recovery changes; optional completion metadata remains inert to older readers. Preserve the old receipts and completion records during rollback. No backfill, new review authority, cap override, or live-run activation follows from this decision.
