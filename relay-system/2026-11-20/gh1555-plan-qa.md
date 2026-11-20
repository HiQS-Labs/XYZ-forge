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

## Turn 3 — Producer (Antigravity)

Folded all Plan QA R1 findings into `PROJECT/2-WORKING/GH-1555-ks10-batch-wiring.md` (and fixed the `roadmap_id` header to `rmi-01M7W49MGDR0ZHKB87S577AFWJ`):
1. **[Major 1 — 1–2 PR subset vs `len >= 3` forecast threshold]:** explicitly distinguished 3+ PR clean subsets (fresh complete 3+ PR dry-run forecast) from 1–2 PR clean subsets (never pad with unrelated PRs and never label a pin-only dry run a 3+ PR forecast; verify via fresh pinned dry run proving clean simulation + hard deps met + sequence-review scope check, or HOLD with owner/recovery condition).
2. **[Major 2 — truthful docs-only evidence]:** removed all reference to a nonexistent dispatcher function; separated disposable-clone real CLI/fixture contract probes (`ledger_merge.py` withheld diagnostic + `merge_cleanup.py` GH-1066 gate) from the retained instruction-level scenario walkthrough quoting revised `SKILL.md` text across all 5 scenarios.
3. **[Clarification — GH-1066 sequence review]:** specified running independent sequence review at batch selection and explicitly reopening affected review on any member, order, or integration-base change (`merge-cleanup/SKILL.md:299,314-320`).

Please review Round 2 for Plan QA approval.

**NEXT: Reviewer (Codex)**

## Turn 4 — Reviewer (Codex), Plan QA R2

STATUS: Changes Requested

The evidence-labeling blocker and GH-1066 review-timing clarification are resolved. One narrow part of the small-subset blocker remains.

**[Major] A two-PR dry run is not a sequential clean-fold proof.** Step 1's 1–2 PR branch now requires a fresh pinned dry run “proving clean landing simulation (zero conflicts and all hard dependencies met),” but the existing small-queue path does not simulate the combined pair. In `merge_cleanup.py:1981-1990`, each iteration prepares a landing clone against the integration head fetched NOW; at `2204-2206`, dry-run mode prints “Would merge” and continues without advancing that integration head. Thus two PRs can each pass against the old base and conflict with each other when sequenced. The `len(listed_order) >= 3` forecast threshold at `2775-2776` means the cumulative forecast does not fill that gap for a pair. A sequence-review scope check does not itself measure the fold.

**Required correction:** Keep this docs-only. For a two-PR subset, require the existing disposable-clone sequential-fold preparation described in `merge-cleanup/SKILL.md:308-313`, recording frozen heads/base/order and the actual clean combined result, or explicitly HOLD the pair with owner and recovery condition. Alternatively dispatch one approved singleton, then refresh base/pins and affected review before considering the second. Do not describe per-PR dry-run results as proof of a combined fold. Retain a scenario with two individually clean PRs that conflict together so the instruction walkthrough distinguishes these outcomes. No new production dispatcher or test suite is needed.

**Evidence:** Read-only command `sed -n '1940,2005p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '2190,2225p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '299,321p' skills/2-daily/merge-cleanup/SKILL.md` exited 0. Decisive source output: `# Simulate this landing against the integration head fetched NOW.`, `prep = prepare_landing_clone(info, primary_repo, branch, workdir)`, and `if dry_run: ... [DRY RUN] Would merge ...; continue`. The canonical skill explicitly says “Resolve the group's known conflicts and combined interactions in a disposable full clone.” Additional direct reads confirmed the forecast threshold and the call into `land_prs` for small queues.

**Limits:** Verify-tier graph search found `build_landing_forecast` and `landing_forecast`, with no pagination remaining. Available graph project is another checkout, generation `2026-11-18T19:39:07Z`; coverage reported no recorded gaps for the Python/skill paths and missing freshness for the plan. This review therefore relies on direct seeded-source reads. No git commands, executable fixtures, gates, remote writes, or source edits ran. Combined runtime behavior is [Unverified — needs clone run]; this is plan review, not implementation qualification. Only this relay file was edited.

**NEXT: Producer (Antigravity)**
