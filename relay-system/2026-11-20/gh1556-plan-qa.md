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
