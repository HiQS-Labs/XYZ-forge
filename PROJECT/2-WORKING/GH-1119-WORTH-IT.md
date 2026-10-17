---
title: "GH-1119: weekly worth-it continuation skill"
status: active
created: 2026-10-17
updated: 2026-10-17
owner: Codex
goal: Vendor a reusable, pinned worth-it checkpoint without replacing weekly planning.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1119
---

## Status

| What was just completed | What's next |
|---|---|
| Verified upstream PR and Forge taxonomy; fresh full clone at a984865eab17456dc8240f68b3206e414e255179. | Independent plan QA, then import and verify. |

## Quad Concepts

- Ongoing experiments need a remaining-value call → reuse upstream worth-it rather than duplicate weekly-planner.
- Vendored prose can drift → pin the exact upstream revision and retain license plus a manual update recipe.
- Findings can disappear → preserve the source's approval-aware results guard.

## Recon and bet

The outcome is a reusable continuation checkpoint available in Forge's weekly category. `skills/README.md` owns tier taxonomy: `skills/3-weekly/` holds cadence reviews. `weekly-planner` owns team planning and shared daily engine; `sanity-check` and `ponytail` supply complementary premise/minimality reasoning. No worth-it implementation exists in the current tree. GitHub title searches and `prior_art_recon.py --query worth-it` found no same-scope import; issue 1118 is a results record, not this implementation.

Source PR https://github.com/Claude-AI-Tools-Ventura-County/giant-brains-claude-skills/pull/15 is OPEN, not merged, at 2e6e1b4a0336fb1badf64d47ae770acd291d2d8d. Source path is `03-improve/worth-it/SKILL.md`. Upstream README declares GPL v2; retain its full LICENSE with this separately licensed skill rather than relabel it under Forge's root AGPL. Existing `ci-suite-audit/NOTICE` is the attribution pattern. No new vendoring framework is warranted.

Smallest bet: one skill bundle plus its required index row and evidence. Rejected alternative: changing weekly-planner would conflate team scheduling with the value lens and duplicate upstream reasoning. Easy rollback: revert the added bundle/index and intake changes; no runtime, schedule or installation changes. Uncertainty: manual instruction review cannot establish live agent compliance.

Rating rationale (2026-10-17): priority 65 (explicit requested import), severity 25 (missing convenience, no known runtime defect), appeal 75 (explicit operator interest), cheapness 80 (bounded prose import and verification). No operator rank override. Recent 14-day versus preceding 14-day recurrence trend unknown: this is a new capability request, not an incident-frequency claim.

## Ordered plan and acceptance

1. Register/rate this intake, promote through existing ledger verbs and commit review inputs; obtain bounded independent Codex plan QA (max three rounds).
2. After approval, admit the owned ledger row with `--accepted-start`. Import the source skill into `skills/3-weekly/worth-it/SKILL.md`; keep initial and continuation modes together, with a same-directory NOTICE and upstream LICENSE. Adapt only provenance and stale helper-folder wording if needed, recording every deviation. Preserve the upstream behavior and callable name; no second implementation.
3. Add one Skills Index row in `ARCHITECTURE.md`; leave all existing weekly skills unchanged. Verify all four calls, sunk-cost exclusion, strongest alternative, maintenance/risk, at most one affordable proof with fixed cap and oracle, stop criteria and Park trigger, meaningful-results lookup, exact authorization, decline/no nag, duplicate avoidance and pending capture truthfulness by manual instruction walkthroughs. Helpers absent must remain disclosed; issue 1118 may only be a contextual example, never a required destination.
4. Record manual findings and `provenance.jsonl` under `TESTS-RESULTS/2026-10-17+GH-1119/`. These are author walkthroughs, not live model behavior evaluations. Run existing diff/frontmatter checks and classifier-selected documentation gate. No new test, parametrized case, suite, harness, gate, registry or security/access changes.
5. Commit, run bounded final Codex relay QA on the diff/evidence (max three rounds), adjudicate actual findings, then push with installed pre-push gate and open a non-draft PR into development. Monitor applicable checks to terminal state, never rerun merely for green. No merge, deployment, live Marathon/Jog, schedules, unrelated feedback or CI optimization.

## Verification and review

Pending. No runtime or live-model evaluation claimed. CHANGELOG entry only if the PDDA consequential-bet threshold is met; this is an Easy isolated prose import. Hosted reconciliation owns routine views and post-merge completion.
