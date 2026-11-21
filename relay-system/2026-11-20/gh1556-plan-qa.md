# Plan QA Relay — GH-1556 (KS-11: Fail-Closed Decision Defaults)

- **Issue:** #1556 (parent arc #1541, milestone KS-11)
- **Task Doc:** `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md`
- **Roadmap ID:** `rmi-01M7VQW02KMDKEVC6SAXN6TQRN`
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Submitted grounded plan in `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md` codifying KS-11(a)/(b)/(c) fail-closed decision defaults in `kickstart/SKILL.md` aligned with `build_queue.py:54-64`, with paired #1519 round-cap red/green replay against real `utils/ci-route.sh`.

Please review for Plan QA.

## Turn 2 — Reviewer (Codex)

STATUS: Changes requested

Reviewed the seeded plan against `build_queue.py` AUTHORITY, kickstart SKILL.md, and `utils/ci-route.sh`. No implementation or gate approval is implied. Graph tools were unavailable; targeted source reads were used. No suites or git commands were run.

### F1 — Major: `full_required` is not a complete protected-surface detector

The Grounded Recon and step 1(a) equate gate/hook/containment/schema/kernel/Costly surfaces with `ci-route.sh full_required`. That flag does not cover every such surface. Narrow read-only probe: `printf "%s\n" githooks/pre-push | bash utils/ci-route.sh pull_request` exited **0**, returning `docs_only=false`, `pdda_needed=false`, `full_required=false`, `route=fast`, `tier=3`, and `tier_reason=unmapped path: githooks/pre-push`. The hook can therefore evade a procedure that treats false as permission to defer. Costly is also a change-level assessment, not a classifier output.

Revise the plan to use the existing classifier conservatively without claiming its flag proves absence of protected surfaces: inspect the actual changed surfaces and reversibility assessment, deny deferral on any named protected surface, and park if that assessment is unknown. Preserve the prohibition even when `full_required=false`. Add the real hook counterexample to the manual matrix alongside the existing positive docs case. No classifier change or new registry is needed for this task.

### F2 — Major: make the red/green replay discriminating and reproducible

Step 3 says to “evaluate” LAND/PARK and “verify” conflict/owner outcomes but identifies no command or recorded manual procedure that produces those decisions. `ci-route.sh` only classifies paths; it cannot establish approval freshness, accepted deferral, owner identity, applicability, or supersession. Both seeded artifacts already contain KS-11 summaries, so “pre-KS-11 had no rule” also needs a pinned historical source rather than treating the present seed as that baseline.

Specify a bounded manual replay using the actual policy text (no new policy engine/suite): pin the #1519 historical input and baseline artifact, retain reviewer wording/head identifiers and path inputs, walk each policy predicate, and record the resulting action/disclosure. Distinguish historical absence from candidate behavioral sensitivity. Include a same-owner but inapplicable decision, a valid current owner release as positive control, and the non-owner/superseded negatives. Record commands or exact manual steps, exit statuses where applicable, nonempty input checks, decisive outputs, and provenance. Any mutation-heavy gate belongs in a disposable full clone. The baseline and candidate must yield distinguishable observations rather than hardcoded expected labels.

The intended two-file implementation scope is appropriately small. Revise the plan for these two issues before implementation; no additional subsystem or test suite is requested.

**NEXT: Producer (Antigravity)**

## Turn 3 — Producer (Antigravity)

Folded both Plan QA R1 blockers into `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md` (and fixed the `roadmap_id` header to `rmi-01M7W49MQWX5WDGFH04176P39V`):
1. **[F1 — Protected-surface inspection beyond `full_required`]:** revised step 1(a) and step 2 (`build_queue.py` `AUTHORITY`) so direct inspection of changed files and reversibility assessment independently blocks Minor/nit deferral on gate, hook, containment, schema, kernel, Costly, or unknown surfaces even when `ci-route.sh` reports `full_required=false`; added the real `githooks/pre-push` counterexample to the probe and manual matrix.
2. **[F2 — Reproducible, truthfully labeled replay]:** pinned historical pre-KS-03 commit `0edbab45d6` as the red baseline for #1519, retained real `utils/ci-route.sh` outputs separately from the bounded manual policy walkthrough, and added all required KS-11(c) controls (valid current owner positive control, same-owner inapplicable negative, non-owner negative, superseded negative).

Please review Round 2 for Plan QA approval.

**NEXT: Reviewer (Codex)**

## Turn 4 — Reviewer (Codex)

STATUS: Changes requested

Plan QA R2: **F1 resolved; F2 partially resolved and remains blocking.** The implementation remains appropriately bounded to the two existing policy surfaces. The independent protected-surface/reversibility check, hook counterexample, and added owner controls address the substantive policy gaps.

### F2 — Major: finish the discriminating replay procedure

Plan step 3 now labels the walkthrough manual and names a historical revision, but still supplies expected labels rather than the reproducible input/procedure requested in R1. It names only the “#1519 round-cap input shape”; no issue/comment/review permalink, verbatim reviewer wording, reviewed/current head identifiers, or retained input location is specified. Nor does it require nonempty extraction checks or record each predicate's supporting policy quotation and observed disposition. Consequently an evidence file consisting of the expected LAND/PARK/HOLD labels could satisfy the current acceptance text without demonstrating sensitivity to the changed policy.

Cheapest correction: add one bounded manual procedure to step 3: retain the sourced #1519 input (identify comment/review and heads; label reconstructed fields explicitly), verify the historical excerpts and input are nonempty, and apply identical recorded inputs to baseline and candidate. Record policy quotation/location, predicate values, resulting action and disclosure separately from the expectation. Keep the pre-KS-03 absence observation labeled historical absence, not a witnessed behavioral failure. For the actual candidate correction, use the hook case with current-head approval and accepted Minor/nit deferral while holding every other predicate constant; remove/replace only the independent protected-surface clause in a scratch copy and show the walkthrough detects the unsafe permission or missing prohibition. Retain the commands/manual steps, exit statuses for commands, decisive observations, candidate revision and provenance. This needs no new suite, engine, or additional scenario collection.

Evidence for this finding is the complete plan step 3 and acceptance criteria, read with `cat PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md` (exit **0**). The decisive wording is “plus the #1519 round-cap input shape” and the matrix entries ending directly in expected actions; the requested source-input and observation protocol is absent from that bounded section. Historical revision contents/ancestry were **not verified** this turn (git is prohibited); retain and check them during implementation rather than treating this review as confirmation.

No gates, suites, executable fixtures, or git commands were run. Graph inventory/status exposed a canonical checkout at a different root; no graph-derived claims about this worktree were used. Review relied on the seeded plan and targeted literal source reads. Approval is withheld only for the remaining evidence-design gap, not pending a presumed later gate.

**NEXT: Producer (Antigravity)**

## Turn 5 — Producer (Antigravity)

Folded the remaining Plan QA R2 blocker (F2) into `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md`:
- Pinned the exact sourced #1519 input from PR #1532 (`https://github.com/HiQS-Labs/XYZ-forge/pull/1532`, comment `#7029123199`, head `2a3601a9009966f7bacd39eebe77f6f9bfbfba47`, full-gate head `eea4c81a0`, verbatim PR body round-cap text, and changed file `validate.sh`) to be retained in `outputs/gh1519-pr1532-input.json`, with nonempty checks and explicit labeling of reconstructed fields for synthetic controls.
- Labeled the `0edbab45d6` pre-KS-03 baseline explicitly as *historical absence* (not a witnessed behavioral failure) and required verifying ancestry + nonempty excerpt extraction at implementation time.
- Added the bounded scratch-copy sensitivity ablation on the `githooks/pre-push` case (holding current-head approval, accepted Minor/nit deferral, and `full_required=false` constant, removing only the independent protected-surface clause in a scratch copy to demonstrate the walkthrough catches the unsafe permission vs candidate PARK).
- Required recording policy quotation + file:line, evaluated predicate values, and observed resulting action/disclosure separately from expectations, alongside candidate revision SHA, command exit codes, and `provenance.jsonl`.

Please review Round 3 for Plan QA approval.

**NEXT: Reviewer (Codex)**

## Turn 6 — Reviewer (Codex)

STATUS: Approved

**Ship — plan approval only. F1 and F2 are resolved in the revised plan.** Step 1 retains independent changed-surface inspection and unknown -> PARK regardless of `full_required=false`. Step 3 now identifies the sourced PR/comment, head identifiers and retained input location; requires nonempty historical/input extraction checks; applies identical recorded inputs to baseline and candidate; and records quoted policy, predicate values, observed action and disclosure separately from expectations. The hook-case scratch ablation holds the other predicates constant and removes only the independent protection, providing a discriminating manual red control without introducing a policy engine or suite. The historical baseline is explicitly labeled absence rather than a witnessed behavioral failure. Owner positive/inapplicable/non-owner/superseded controls remain present.

The two-policy-surface implementation scope is proportionate. Implementation must still produce the planned receipts and pass Final QA; this approval neither attests to historical ancestry/PR contents nor claims the manual replay or gates have passed. In particular, fetch and validate the pinned source material during implementation, label reconstructed fields, and retain actual observations rather than copying expected labels. No approval rests on an assumed later relay gate.

Evidence: read the complete seeded `PROJECT/2-WORKING/GH-1556-ks11-decision-defaults.md` (exit 0), with targeted literal reads of the existing `AUTHORITY` and KS-11 skill summary (exit 0). Used the SWE planning-review rubric. Graph project inventory was fully paginated and contains no matching worktree root; no graph-derived structural or completeness claims were used. No git commands, suites, executable fixtures, or gates were run. Only this relay file was edited.

**NEXT: Producer (Antigravity) — implement the approved plan and retain the specified evidence for Final QA.**
