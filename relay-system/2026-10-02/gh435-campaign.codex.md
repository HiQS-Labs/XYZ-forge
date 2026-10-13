# GH-435 independent peer review receipt

Reviewer: GPT 6 Luna sub-agent `/root/contracts`, invoked independently through the Codex collaboration tool. Scope: report claims, raw lane evidence, counts, remediation compatibility and limitations; no production implementation or merge approval.

# GH-435 campaign draft — final evidence QA

**Verdict:** The draft is broadly aligned with lane reports and raw evidence. The two earlier concerns about F3 coverage and installer counts are resolved by newer exact artifacts. One installer-mode wording still needs narrowing; the separate teardown-receipt claim remains pending.

## Remaining correction

**Installer strict-mode coverage:** The observe-mode ATE cases include zero-byte, corrupt, missing-schema, and unreadable databases, all preserved with a reported error and rc=0. The raw v5 full-mode controls include only zero-byte, corrupt, and unreadable databases. Phrase full-mode failure as confirmed for those three controls; do not imply a missing-schema strict-mode run.

## Earlier concerns resolved by newer evidence

- **F3 includes both Git config modes.** The newer `discovery/peer-review/worktree_gitfile_probe_fresh.json` explicitly covers linked-worktree common-config mutation with `extensions.worktreeConfig=false` and `git config --local`, then enables `extensions.worktreeConfig=true` and writes via `git config --worktree`. Both are false passes; JSON confirms the respective common config and per-worktree config files contain the probe key. This complements the original standalone-config, linked-config, linked-HEAD and linked-no-op cases. The draft's common/worktree config claim is supported.
- **Installer totals are confirmed by its evidence index.** `install/evidence-index.json` reports 14 valid unique case-mode combinations and 30 accepted raw installer streams. That is 10 valid v4 observe cases (the v4 zero-byte case is explicitly excluded for an invalid oracle), three v5 full-mode controls, and the separate v7 no-Node observe pass. The stream count includes repeated install streams. The v6 missing-Node 18-row invocation is explicitly excluded because its cases failed before setup. The draft's totals are correct; adding “accepted” or a short scope note would make the count method clearer.

## Closeout receipt still needed

The campaign draft says archival and teardown receipts “are recorded separately at campaign close.” At this review, the campaign has `supervisor/prearchive-inventory.json` and `provenance-hash-audit.json`, but no final archive/teardown receipt in the campaign evidence tree. Retain the claim only after the parent adds and links the closeout receipt.

## Claims checked and accepted

- The discovery matrix totals 25 unique cases: 22 expected behavior/refusal passes, two unset-HOME failures, and one deliberate wrong-root red control. GH-912's 50/0 and 49/1 focused suite runs are separate evidence and are not added to the 25-case count.
- GH-290's 162 hostile variations plus two valid controls and 37/37 top-level assertions are distinct metrics. Contracts lane's 43/43 GH-478, 15/15 adaptive suite, six-case pairwise sample, ATE TERM/INT cancellation, and same-group late-writer timeout false-pass match the lane evidence.
- The 14/30 installer totals match `evidence-index.json`; the supplementary no-Node case is included. Observe-mode rc=0 is documented report-only behavior; the draft correctly rejects it as a product defect.
- F1–F8 and K1 match the supervisor finding register and lane evidence. P1/P2 labels are judgment calls; the draft appropriately says they describe practical campaign impact rather than observed production damage.
- The environment, pinned SHA, no-production-edit, no-full-gate, and no-live-model/network claims are consistent with the lane reports and campaign receipts available at review time. I confirmed executable `pre-push` hooks exist in all three clones.

Sources reviewed: campaign `REPORT.md`; `supervisor/RECON.md`, `ATE-OBSERVATIONS.md`, `finding-register.json`, raw oracle results and prearchive inventory; discovery peer-review worktree probe and report; installer `evidence-index.json`, lane report and provenance; contracts `REPORT.md`, `peer-review.md`, raw probes, and provenance. No probes, source files, campaign draft, or other-lane artifacts were changed.


Supervisor reconciliation: full-mode DB claims narrowed to the three exercised states. Latest independent worktree evidence and accepted-count index resolve the earlier scope/count concerns. F9 timestamp evidence is separately preserved in install/timestamp-probe.json and install/ate-timestamp-crosscheck.json. Teardown will be attested only after it happens.
