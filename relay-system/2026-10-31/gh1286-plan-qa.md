---
Goal: Plan QA for GH-1286 (ceremony-audit skill)
Date: 2026-10-31
---

NEXT: claude
STATUS: Changes requested

# Context

Review the plan in PROJECT/2-WORKING/GH-1286-CEREMONY-AUDIT.md before any skill text is written. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1286. Prompting case: https://github.com/HiQS-Labs/XYZ-forge/issues/1279.

Operational envelope: one Markdown skill of 120 lines or fewer, no scripts, no new tests (AGENTS.md "No new tests", GH-831). Grade against the stated requirements and commensurate complexity. Do not ask for scoring rubrics, helper scripts, test suites or enterprise fail-safes. This is review only: edit nothing except this relay file. No network calls are needed.

Read the plan and the skills it compares:
- skills/1-hourly/ponytail/SKILL.md
- skills/1-hourly/sanity-check/SKILL.md (especially the decision ladder, step 5)
- skills/1-hourly/triangulate/SKILL.md (Step 0a/0b)
- skills/3-weekly/worth-it/SKILL.md (Continuation mode, step 4)
- ARCHITECTURE.md lines 45-70 (skills index)
- AGENTS.md "No new tests"

Questions:

1. Is the Step 1 gap sentence true? Does any of the in-repo skills above already ask, per planned step, "does this change goal state or answer the open question, versus re-prove what is known"? If a short section in sanity-check, ponytail or worth-it would honestly cover it, say so plainly: that is an acceptable verdict.
2. Is the plan's scope minimal and complete for the issue's Step 2 requirements (goal + open question, four labels with the deletion test, real run over proxy, short output, composition by link, triggers)? Anything over- or under-built?
3. Are the acceptance checks falsifiable? Does running a fresh subagent with only the draft skill and the live #1279 text, without the expected answer, fairly test it? Is the red control (a lean merged one-file fix) a real control?
4. Is the gate route right (docs route via utils/ci-route.sh plus test/gh620* and test/gh589* for a new file under skills/)? Any registry besides ARCHITECTURE.md that a new skill folder must update?
5. Is the persisted rating (60/35/50/80) consistent with the evidence in the plan's Ratings section?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the plan can proceed as written (minor notes allowed). Otherwise hand back with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


## Codex plan QA — 2026-10-31

**Ship with conditions — changes requested.** The bounded per-step audit is a reasonable new skill; no scripts, new suites, scoring framework or sibling rewrites are needed. Correct the verification plan and narrow the gap rationale before writing the skill.

### Findings

[Should] Correct the assertion that sanity-check only fires at a failure.
Observed input: `PROJECT/2-WORKING/GH-1286-CEREMONY-AUDIT.md:42` and `:53-56` justify rejecting an extension because sanity-check would only fire at a blocker. Its actual description explicitly also activates when asked whether a feature, CI test or other machinery is necessary (`skills/1-hourly/sanity-check/SKILL.md:4-9`), and step 5 tests duplicate verification and what changes when machinery is absent (`:103-113`).
Affected scope: Gap justification only. The exact gap sentence at plan `:49-51` holds for the four inspected skills: none prescribes a whole-plan, per-step progress/proof/safety/ceremony pass. A short section in sanity-check could honestly cover this if its activation and unit were extended; a separate skill is defensible for the dedicated whole-plan trigger and output, not because failure-free necessity review is unavailable today. Retain that narrower rationale; ponytail and worth-it need no changes.
Falsifier: Quote an existing instruction that confines sanity-check activation to failures, or revise the table and section rationale to acknowledge its existing necessity trigger while explaining the distinct per-step workflow.

[Should] Make the two acceptance runs valid retained evidence; distinguish the lean counter-example from a red control.
Observed input: Plan `:81-89` specifies Markdown receipts, but omits `provenance.jsonl`, required for manual evidence by `AGENTS.md:114-116` and `:161-164`. An empty cut list on a lean plan tests false positives; both a working auditor and an auditor that always cuts nothing pass it. It does not witness the check rejecting a broken result (`AGENTS.md:118-121`).
Affected scope: Acceptance steps 3–4 only. Keep the blind fresh-agent run and the preselected lean example. Call the latter a negative/counter-example control. Record provenance alongside prompt, exact supplied issue/comments snapshot or revision, draft revision, model and output. For sensitivity, manually apply the stated acceptance rule to a deliberately wrong output (e.g. one that keeps every #1279 proxy) and record its rejection. No script or new suite is needed. Supply no expected answer to the agent; inspect the live comments before treating this as blind, since comments containing the desired diagnosis would make it a guided case study. Such a case study is useful, but should be described accurately.
Falsifier: The revised plan names committed provenance and a witnessed rejected output, and records whether the supplied issue/comments expose the expected diagnosis. The lean case still independently requires no unnecessary cuts.

[Should] Drop publisher smoke runs that cannot exercise this skill.
Observed input: Plan `:90-92` adds gh620 and every gh589 suite because a file is added under a “published skill folder.” `test/gh620-skills-army-mini-sync.sh:61-68` tests the skills-army-hq child projection; `test/gh589-consult-no-tick.sh:2-3` tests exported consult; `test/gh589-xyz-mini-sync.sh:128-130` explicitly asserts an unlisted skill never ships. This plan does not add ceremony-audit to those publisher manifests. In contrast `test/gh589-skill-viewer.sh:17-25` actually inventories every Forge skill.
Affected scope: Gate step 5. Keep classifier-selected docs checks and, if desired, the existing gh589-skill-viewer smoke in the disposable full clone. Remove the unrelated publisher/consult runs unless a concrete touched contract is identified. Do not expand publishing scope to justify them.
Falsifier: Show that one of the proposed publisher suites reads or exports the new ceremony-audit file under the unchanged manifests; otherwise narrow the explicit gate list.

### Answers and minor notes

- **Scope:** Plan `:71-79` covers goal/open question, four labels, deletion test, real run versus proxy, short output, composition and triggers within the 120-line envelope. Preserve genuine safety and required gates when applying the deletion test. No additional subsystem is warranted.
- **Acceptance:** Observable cut/keep decisions make the worked example falsifiable. A fresh agent without the answer is a fair bounded smoke check, not proof of general reliability. The live #1279 text and comments were not fetched in this offline turn, so the factual expected decisions and absence of answer leakage remain unverified.
- **Routing/registration:** Docs routing is supported by `utils/ci-route.sh:54-68`; actual gate execution remains **[Unverified — needs clone run]**. `skills/README.md:23-24` requires the Skills Index row; no additional registry is required by that add-skill contract. Deployment through Skills Army HQ after merge is correctly separate. Use portable canonical links per `skills/README.md:33-34`.
- **Index count:** `ARCHITECTURE.md:49` says 15 but `:55-70` already lists 16 rows. Count the resulting rows rather than applying the planned 15 → 16 mechanically; adding this skill makes 17.
- **Ratings:** 60/35/50/80 is internally consistent with the plan's modest operational harm, live priority, neutral appeal and cheap document-only effort (`:98-102`). The claimed time saving remains an estimate grounded in one reported case, not a measured recurring benefit. This review did not independently query the persisted ledger.

Verification: static source review only; no git commands, network calls, suites, fixtures or subagents ran. Graph tools were unavailable in this session; inspected the exact supplied Markdown and shell sources. No artifact was changed by the reviewer.
