# Plan QA Relay — GH-1555 (KS-10: Merge-Cleanup 3+ PR Batch Wiring)

- **Issue:** #1555 (parent arc #1541, milestone KS-10)
- **Task Doc:** `PROJECT/2-WORKING/GH-1555-ks10-batch-wiring.md`
- **Roadmap ID:** `rmi-01M7VQW02KMDKEVC6SAXN6TQRN`
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Submitted grounded plan in `PROJECT/2-WORKING/GH-1555-ks10-batch-wiring.md` wiring kickstart to merge-cleanup's existing landing forecast (`ledger_merge.py:800-970`), `--landing-plan`/`--landing-reason`, `canary_command`, GH-1066 sequence review, U5 pin revalidation, and fail-closed withheld-forecast hold behavior.

Please review for Plan QA.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

**Verdict: Block — plan revisions required.**
**STATUS: Changes requested**

The docs-only reuse approach is sound and easily reversible. Approval is withheld for two concrete execution/verification gaps:

1. **[Major] The fresh-subset forecast requirement cannot be fulfilled for a 1–2 PR subset through the proposed CLI.** Plan step 1 requires a fresh complete forecast before dispatching a clean subset from a group/conflict-hub batch. However, `merge_cleanup.py:2775-2776` only calls `build_landing_forecast` when `len(listed_order) >= 3`; the canonical skill at lines 285 and 291 also explicitly distinguishes small queues and fresh pass-2 dry runs. A three-PR batch can leave a one- or two-PR clean subset. The proposed instructions would strand that subset or tempt an executor to call a pin-only dry run a complete forecast. Specify an existing supported verification path for small subsets, or explicitly HOLD them with an owner and recovery condition. Preserve the distinction between refreshing pins and obtaining a forecast; do not add unrelated PRs to reach three.

2. **[Major] The paired control does not currently demonstrate the changed decision rule.** Plan step 2 promises to verify a “KS-10 dispatch decision function,” but the implementation scope names only `kickstart/SKILL.md` and identifies no such function. The existing CLI's missing-`--landing-plan` refusal proves its existing argument gate, not that kickstart refuses `recommendation: None` when valid landing arguments are supplied. Source at `merge_cleanup.py:2620-2630` records forecast comparison and warns on stale evidence; it is not the new HOLD decision. Keep this docs-only: define a retained instruction-level scenario walkthrough against the actual revised SKILL text, quote its decisive rules, and label that evidence truthfully. Cover withheld diagnostics/zero dispatch, plain direct, passes, group subset, and changed membership/head/base/order. Run any real CLI/fixture checks in a disposable full clone, retain nonempty provenance, and distinguish those measurements from instruction-level evidence. Do not introduce a production dispatcher or a new test suite to satisfy this wording.

**Required clarification within step 1:** Make the GH-1066 independent sequence review occur when the batch is selected and explicitly reopen affected review on member, order, or integration-base changes (`merge-cleanup/SKILL.md:299,314-320`). “Before the first merge” plus refreshed pins alone is weaker than the existing review contract.

**Evidence and limits:** Verify-tier graph lookup against the available XYZ-forge project (generation `2026-11-18T19:39:07Z`) returned no forecast symbol matches; coverage reported no recorded gaps for the two Python paths, but that index belongs to another checkout. Findings therefore rely on direct reads of this seeded checkout. Read-only command `rg -n 'len\(.*>= 3|landing_forecast\(' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` exited 0; decisive output: `2775: if len(listed_order) >= 3:` followed by `2776: forecast = build_landing_forecast(...)`. Direct source reads confirmed the withheld clean-set-fold branch in `ledger_merge.py:934-936` and the canonical skill contracts cited above. No executable fixtures, gates, git commands, or remote mutations ran. No TAKE YOUR TURN block or phase gate command exists in the supplied relay file; this is plan QA only, not implementation qualification.

**NEXT: Producer (Antigravity)**
