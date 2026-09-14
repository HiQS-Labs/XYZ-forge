# Final GH605 lane verification — 2026-09-14

## Source and integration

The operator-authorized last two corrections are complete: mock seed-ID regression
fixed and independent full-file review Approved. Review input 96261ab2, attestation
94665101, driver exit 0, 19 files / 17,729 lines; focused Python tests 79/79.
Removing the one-line seed fix fails the distinct-ID assertion; restoring it gives
51/51 board tests. The work-state suite passes 28/28.

Final implementation candidate: `85cf25cca187eb6cf45ace571260c3db51ef8666`.
Development `4ee561ed0339777bdf8e7ef9f38de64ed55348c3` is integrated; canonical
ledger generation 648. Kanban production and GH605 tests are byte-identical to the
approved review input. Upstream GH615 test-only wrapping correction was authored
by Sol High and independently reviewed by Astra: GH615 8/8, GH616 7/7, GH617 9/9,
GH365 16/16.

## Final normal push gate

`git push origin HEAD:refs/heads/fix/work-state-projection` exited 0, no bypass.
**381/381 passed in 795 seconds** (378 registered suites plus gate invariants).
Separate full verification clone retained a clean worktree and unchanged identity:
canonical origin, core.bare=false, expected user email, HEAD=85cf25cc.

Log: `forge-gh605-verify-20260913/temp/gh605-validation/settled-final-prepush.log`.
SHA256: `3f989e3f79daee6faad358d5d5d4b0a2be66c7bee48931390ef529afe0d08a01`.

The earlier partial ef231262 gate was deliberately interrupted (exit 143) before
publication to integrate the incoming GH617 ledger conflict. It is not a pass or
a test failure. Its separate `approved-final-prepush.log` is retained.

PR607 was made ready for review, then returned to draft after the live acceptance
probe exposed the JSON-boundary defect below. Base development, mergeable, not merged. Hosted smoke
and CodeRabbit passed on 85cf25cc; macOS promotion and Ubuntu canary were skipped,
not claimed as executed promotion.

## Local policy and live application

Local settings are saved in `~/.xyz/device_config.json`. The policy metadata now
reports `available_manual`; automatic `work_connectors.github_board.enabled`
remains false. Scope is noelsaw1/project4, XYZ Forge only, Ready top10, Done7days,
activity3days. No automatic rollout or primary-checkout deployment is included.

The first final apply refused source-digest drift before creating an audit or
writing to the board. The refreshed preview had identical changes and board;
only updated_at on PR607/618 changed. The second apply refused unresolved drift,
again before audit creation or writes. Local replay proved decisions identical,
but fresh unresolved identities were tuples while saved JSON contains lists;
JSON-normalizing the fresh unresolved list made it exactly equal to the saved list.

Sol High corrected one producer output expression and extended the existing real
integration fixture with a missing-ledger OPEN issue. Witnessed red before fix;
51/51 board tests green after. The fixture asserts JSON round-trip equality,
successful apply with nonempty unresolved evidence, preservation of the unknown
issue, and refusal of genuine unresolved tampering. No drift comparison is relaxed.
This real acceptance defect requires bounded fresh review and gate verification;
the earlier 381/381 result belongs to 85cf25cc, not the corrected candidate.
