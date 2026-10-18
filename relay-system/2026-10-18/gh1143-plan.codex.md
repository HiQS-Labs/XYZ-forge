# RELAY · GH1143 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1143-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-1143-DEFECT-CAMPAIGN.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: operator
- Started: 2026-10-18

### Artifact — GH-1143-DEFECT-CAMPAIGN.md
```
---
gh_issue: 1143
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1143
title: Radar-to-campaign documentation skill
status: Planning — awaiting plan QA
updated: 2026-10-18
owner: Codex
goal: Connect Radar recommendations to bounded approved discovery using existing assets
created: 2026-10-18
doc_type: feedback
---

# GH-1143 — Defect campaign

Implement a thin instruction skill connecting Radar recommendations to existing campaign,
ATE, fuzz, oracle and minimization assets. Documentation only; no execution or remediation.

## Status

| What was just completed | What's next |
|---|---|
| Source recon and docs-route inspection; intake rated 55/40/50/85 | Independent plan QA before implementation |

## Recon and smallest viable bet

Base: `e93214feb45dc95f32ee2d9080c1d4f6f3b8ab69` (`origin/development`).
PR #946 landed as `e888594fd3e3670a6be2eecdaecc4b20af549c1b`; Radar's existing
verification-asset handoff is the entry seam. ATE's older automatic issue filing is unsafe
for discovery; gen4_campaign's parser defaults to suite mode and synthesis ON. Use explicit
run mode and no-synth only after approval, with model/healing/filing options absent.
`adaptive_ate.generate_pairwise`, `fuzz_engine.fuzz`, `domain_oracles` and
`repro_builder` already provide the building blocks; no new engine is justified.

Outcome: turn selected recommendations into reviewable bounded specifications and accountable
counterexample dispositions. Add `skills/4-occasional/defect-campaign/SKILL.md`, one index row,
and minimal Radar/ATE pointers. Existing Radar alone lacks the approval/evidence contract;
expanding the campaign engine is unnecessary. Revert these docs to roll back.

## Ownership and limits

Live inspection 2026-10-18: primary tick projection has GH1140 final-review handoffs;
its separate clone has dirty merge-cleanup and gh436 files. GH1136 is open and excluded;
GH1133 remains paused. No competing pilot or writes in peer clones. No existing GH1143
intake or open PR found. Fresh standalone full clone and docs task branch follow GH970.
Local claims are clone-local; recheck tracker, claims, locks, processes and peer checkout
state before any future campaign, never infer clearance from an empty new clone.

Proposed rating: 55/40/50/85 (priority/severity/appeal/cheapness), neutral appeal, no override.
This is a missing workflow connection, not an observed runtime defect. #945/#946 are prior
art, not another incident. Recurrence trend unknown: no comprehensive distinct-incident
count for Oct 4–18 versus Sep 20–Oct 4; do not claim growth or zero incidents.

## Ordered plan and acceptance

1. Register/rate this issue via RELEASES CLI, promote this doc per SOP. Classifier inspection:
   Markdown, PROJECT, TESTS-RESULTS, relay-system and releases DB/SQL/generated HTML are
   supported docs surfaces. Inspect the actual final diff including deleted paths; stop if
   any path requires a broader gate. Do not change routing or shared policies.
2. Codex plan QA, cap three rounds; after approval, admit exact owned row via accepted-start.
3. Write the skill and three pointers. Explicit suitability, hypotheses/oracles, known-failing
   and clean controls, concrete budgets/stops, isolated effects, reproducible replay using the
   same predicate, duplicate classes, severity and separately authorized remediation.
   Require individual approval for every new CI test/case/assertion/parametrization.
   Preserve #1131 and prohibit automatic fixes/push/merge/deploy/schedules.
4. Include a source-grounded HELD pilot for #1138 stale batch state: #1140/#1136 excluded;
   structured adapter missing, future separately approved work. No invented argv semantics.
5. Existing skill quick_validate, manual source/link and consumer-path review, deterministic
   PDDA gate, final independent Codex QA (three-round cap). Record evidence under
   TESTS-RESULTS; no new tests, cases, fixtures, scripts, registries or runtime changes.
6. Push through installed docs hook; open DRAFT PR to development and verify remote SHA and
   exact-head hosted statuses. Distinguish smoke/skipped/full qualification. No full suite,
   merge, installation, deployment, campaign execution or clone cleanup.

## Review questions

Check every issue requirement for an equivalent in this plan (omission diff); distinguish
this documentation implementation from future campaign approval. Are tool fit and missing
semantic adapters honest? Are synthesis/healing/autofiling disabled, effects/budgets bounded,
and per-case approval plus ownership boundaries explicit? Are the docs-only gate and existing
writers reused without bypass or speculative machinery? Grade only this local documentation
scope and commensurate complexity. No new tests or enterprise abstractions.
```
- Definition of Done: All issue requirements below have an equivalent in the embedded documentation-only plan, within the operator-authorized exclusions.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PARKED
Basis: The bounded documentation plan is reasonable on its stated scope, but the requested issue-to-plan omission review cannot be completed: the issue body is not seeded and both remote retrieval paths failed. This is an evidence limitation, not an observed runtime defect. Approval here would leave an explicit review question unanswered.
swept file: yes

- [Should] Supply the actual #1143 requirements in this relay (a dated issue-body snapshot is enough) and replace the Setup placeholder `Definition of Done: All issue requirements below have an equivalent in the embedded documentation-only plan, within the operator-authorized exclusions.` with those criteria or an explicit mapping to the embedded plan. The entire embedded artifact and its matching `PROJECT/2-WORKING/GH-1143-DEFECT-CAMPAIGN.md` were read; neither contains the issue body. This asks for review evidence, not runtime behavior or additional machinery. Probe: `gh issue view 1143 --repo HiQS-Labs/XYZ-forge --json title,body,comments` → exit 1, decisive output `error connecting to api.github.com`. Independent web open of `https://github.com/HiQS-Labs/XYZ-forge/issues/1143` also returned `Failed to fetch ... Cache miss` (tool error; no process exit status). Repeat review once the source requirements are available.
- [Pass] Existing seams support the small documentation approach: `skills/3-weekly/radar/SKILL.md:786` names the verification-asset handoff and says `Radar recommends and never executes`; `skills/4-occasional/ate/SKILL.md` explicitly says `--gh-repo is what turns on the automatic issue filing at the end — omit it`. The plan correctly keeps discovery approval separate and excludes automatic filing. Preserve Radar’s existing prohibition on reciprocal pointers when adding the proposed pointers.
- [Pass] The parser caution is grounded: `utils/py/gen4_campaign.py:365` defaults `--mode` to `suite`; lines 376–378 declare `--no-synth`, `--tier2-cmd`, and `--heal-generator-cmd`; line 399 passes `not a.no_synth`. The plan’s explicit run/no-synth and absent model/healing options fit those interfaces. This source check does not prove campaign safety or semantic-oracle coverage.
- [Pass] The documentation boundary and staged verification are explicit in ordered steps 3–6: `same predicate`, `Require individual approval for every new CI test/case/assertion/parametrization`, `structured adapter missing`, `final independent Codex QA`, and `No full suite, merge, installation, deployment, campaign execution or clone cleanup`. Reversibility: Easy, because the proposed deliverable is instructions and pointers with a stated docs revert. No pre-existing blocker found in the full plan sweep; the historical peer-state and #1138 pilot claims remain source assertions pending final source review, not independently confirmed facts.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixture, campaign, or gate was run in this worktree. Implementation checks and exact-head gate/status evidence remain future work under steps 5–6; this turn makes no implementation-success claim.

Handing off to Producer (operator): seed #1143’s source requirements and the review criteria, then take the next turn. No artifact/source change is requested by this review.


## Producer round 2 — evidence supplied

Disposition: Accepted. Round 1 could not read the private/current GitHub source over its network. Below is the issue body fetched by the supervisor with gh on 2026-10-18; the current operator authorizes documentation implementation through DRAFT PR only, without campaign execution, new code/tests, merge, installation or cleanup. Compare the source requirements against the plan; no new machinery.

## Issue 1143 source snapshot

## Status: proposal only
User requested thoughts, light–medium reconnaissance and an issue. This does **not** authorize implementation, campaign execution, test additions, remediation or activation.

## Recommendation
A thin skill (working name: **defect-campaign**) could turn a selected Radar finding into a bounded, approved experiment and then a remediation handoff. Reuse the existing engines and workflow. Do not build another scheduler or autonomous repair system.

The valuable connection is: **Radar cluster → suitability check → explicit hypothesis/oracle → bounded discovery → reproducible counterexample → severity/ownership decision → separately authorized fix**. Radar alone cannot establish a bug or permission to fix it.

## Recon / prior art
- [#945](https://github.com/HiQS-Labs/XYZ-forge/issues/945) already proposes the verification-asset handoff; [PR #946](https://github.com/HiQS-Labs/XYZ-forge/pull/946) merged that into development as e888594fd3e3670a6be2eecdaecc4b20af549c1b. Extend this recommendation-only seam, do not duplicate it. The issue remaining open does not mean its PR never landed.
- [ATE](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/4-occasional/ate/SKILL.md) means Automated Testing Environment. Existing [adaptive_ate.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/adaptive_ate.py) supplies constraint-aware pairwise grids; [fuzz_engine.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/fuzz_engine.py) supplies seeded argv mutation/replay.
- [domain_oracles.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/domain_oracles.py) covers containment/state/idempotence/crash-recovery predicates; [repro_builder.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/repro_builder.py) supplies argv/environment minimization.
- [gen4_campaign.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/gen4_campaign.py) already orchestrates disposable clones, targets, seeds, bounds, telemetry, clustering and optional healing. **Synthesis defaults on.** Discovery must explicitly disable synthesis and healing/model-command options; omit automatic filing options. Inspect exact current CLI safety before any future execution. Its default targets exclude validate.sh because mutated arguments previously launched a full gate.
- [#435](https://github.com/HiQS-Labs/XYZ-forge/issues/435) provides a campaign precedent using offline stubs and independent clones. [#460](https://github.com/HiQS-Labs/XYZ-forge/issues/460) already describes counterexample-to-disposition flow.
- Older SOP/campaign instructions for automatic new regression tests, full preflight or fixes must not override the current per-case approval moratorium or #1131.

## Matching rule: select the tool by problem class
- CLI grammar/input boundaries: bounded seeded argv fuzzing
- Configuration/environment interactions: constrained ATE/pairwise scenarios
- State transitions, resume and concurrency: structured operation sequences with explicit semantic predicates
- Documentary drift, prioritization or strategy: analysis; do not force these into fuzzing

A report match needs a specific target, falsifiable invariant, safe fixture and useful oracle. Generic containment checks cannot prove correct business behavior. Pairwise coverage does not prove higher-order sequence coverage.

## Proposed campaign contract
1. Capture Radar report/cluster, exact code SHA, live issue/PR ownership, prior results and known counterexamples. Distinguish source revision from tracker timestamps.
2. Specify hypotheses, allowed mutations, expected refusals, semantic oracle/falsifier, known-failing and clean controls, fixture, seed/corpus, commands, dependencies and wall-time/case limits.
3. Obtain approval for that bounded execution and its permitted effects. Use disposable standalone full clones, sanitized environment, offline stubs and owned process-group cleanup. A discovery phase may mutate disposable fixture state only where declared; no production/shared checkout effects.
4. Reuse existing campaign facilities with synthesis/healing and automatic issue filing off. Stop on containment/identity violations, surviving processes, invalid observations, missing dependencies, exhausted budgets or repeated no-new-signal results. Reserve time for replay/minimization/cleanup.
5. Replay and minimize using the **same semantic predicate**. Retain exact inputs, corpus snapshot, code/tool versions, environment, outputs and timing where relevant. A seed alone is insufficient for stateful/concurrent behavior.
6. Dedupe by target + invariant + root cause against issues, PRs and active local owners, not only error-text hashes. Separate new defects, known rediscoveries, expected refusals, flaky/inconclusive observations and faulty oracles.
7. Report severity and real-world impact before remediation. Critical/high findings get prompt review; lower-severity findings remain deferred unless selected. Use existing start-task/review ownership for an explicitly authorized fix.
8. Preserve before/after reproduction evidence and link the disposition back to the Radar tracking context or existing results issue. A clean bounded run does not prove an entire bug class eradicated.

## Pilot candidate and current overlap
[Radars #1138](https://github.com/HiQS-Labs/XYZ-forge/issues/1138) identify merge-batch stale captured state. Relevant seams are batch_record.py extend/landed/qa_pending/continuable and driver selection/sweep-input construction. Known controls include [#1073](https://github.com/HiQS-Labs/XYZ-forge/issues/1073) stale file overlap and [#1084](https://github.com/HiQS-Labs/XYZ-forge/issues/1084) QA bypass/merge-identity loss.

**Do not launch a competing pilot now:** active [#1140](https://github.com/HiQS-Labs/XYZ-forge/issues/1140) work on Mac mini is changing batch persistence/orchestration. First reuse its eventual counterexamples and final implementation, or select another unowned class. [#1136](https://github.com/HiQS-Labs/XYZ-forge/issues/1136) accepted-start repair is also active and excluded.

Candidate hypotheses, after ownership clearance:
- Refreshing an unlanded PR must update overlap inputs without rewriting landed history
- A fresh execution cannot hide matching pending QA
- A failed post-merge refresh cannot discard a verified merge identity  [Unverified — no citation]
- Repeated equivalent read/recompute operations preserve semantics

Existing gh436/gh534 checks are assets to reuse, not permission to add cases. This pilot likely needs a small structured-state adapter/oracle: name and review that gap instead of claiming argv mutation already covers it.

## Guardrails / anti-goals
- No automatic new CI suites, cases, assertions or parametrizations; each requires explicit operator approval
- No repeated full development suite under #1131; preserve current promotion policy
- No automatic fix, push, merge, deployment, issue closure or schedule activation
- No ledger transport redesign: [#923 results](https://github.com/HiQS-Labs/XYZ-forge/issues/923#issuecomment-6252388515) rejected the proposed ordering change on measured benefit/safety
- No new general engine, registry, gate, daemon or model dependency
- No silent adoption of stale SOP permissions
- This issue does not change any existing holds or authorize work on #1133

## Initial design acceptance
- [ ] One source-grounded pilot specification with ownership/duplicate check
- [ ] Tool fit and missing domain oracle/adapter identified
- [ ] Known-failing and clean controls specified before execution
- [ ] Explicit budgets, stop conditions, isolation and reproducibility contract
- [ ] Every counterexample has an accountable disposition and evidence link
- [ ] Honest null result accepted; exercised/excluded/unresolved coverage stated
- [ ] Existing machinery reused with no new CI policy or automatic remediation

The main cost is trustworthy domain predicates, not launching a fuzzer. This is worthwhile if it reduces repeated manual triage and preserves findings; it is not worthwhile if it adds another orchestration layer without better evidence.

— dot

### Reviewer · Round 2

VERDICT: FAIL
Basis: Block approval on one bounded documentation acceptance omission. The supplied issue snapshot resolves Round 1's evidence request; its result-report requirements still have no explicit equivalent in the embedded plan. The fix belongs in the existing skill-writing and manual-review steps, with no new machinery. Reversibility: Easy (documentation revert).
swept file: yes

- [Should] Add the campaign result-report contract to step 3 and its omission check to step 5. Require an accountable disposition and retained evidence link for each counterexample, a link back to the Radar context or existing results issue, and an honest null report stating exercised/excluded/unresolved coverage without claiming class eradication. Also name the retained replay record: exact inputs/corpus, source/tool versions, environment, and relevant outputs/timing; a seed alone is insufficient for the HELD stateful pilot. These are instructions for future approved work, not authorization to execute or publish campaign results now.
  Observed input: The source snapshot's contract item 5 requires `Retain exact inputs, corpus snapshot, code/tool versions, environment, outputs and timing where relevant`; item 8 requires `link the disposition back to the Radar tracking context or existing results issue`. Initial design acceptance explicitly requires `Every counterexample has an accountable disposition and evidence link` and `Honest null result accepted; exercised/excluded/unresolved coverage stated`. In contrast, the full embedded plan's steps 3–5 (this file:120–129) stop at `reproducible replay using the same predicate, duplicate classes, severity and separately authorized remediation` and implementation-check evidence under TESTS-RESULTS. Neither that phrase nor `accountable counterexample dispositions` at lines 94–95 specifies the missing report fields or return link. Read-only probe: `nl -ba relay-system/2026-10-18/gh1143-plan.codex.md | sed -n '90,145p;245,335p'` → exit 0; decisive output at lines 120–129 is the complete existing skill-writing, pilot and verification steps quoted above. No runtime failure is alleged.
  Affected scope: The documentation skill's future campaign replay/result/disposition instructions and the current implementation's manual completeness review, including zero-counterexample runs.
  Falsifier: Point to an equivalent explicit requirement in the embedded plan, or revise steps 3/5 so a manual review rejects (a) a seed-only stateful replay record, (b) a counterexample disposition without evidence/backlink, and (c) a clean report that omits coverage limits or claims eradication. A report preserving the required evidence, dispositions/backlink and bounded null conclusion should satisfy that review. Use the existing manual evidence location; add no tests or fixtures.
- [Pass] Source-to-plan mapping otherwise fits the authorized scope: source `One source-grounded pilot specification with ownership/duplicate check` maps to step 4's `source-grounded HELD pilot` and lines 105–106's live ownership recheck; source `Known-failing and clean controls specified before execution` maps to step 3; `Tool fit and missing domain oracle/adapter identified` maps to the recon's existing assets and step 4's `structured adapter missing, future separately approved work`. HELD is appropriate; this review does not clear #1140/#1136 ownership or authorize an adapter.
- [Pass] Existing entry-seam and safety claims remain grounded by static reads: `skills/3-weekly/radar/SKILL.md`, section `Sibling: recommend the repo's own verification assets`, says `Radar recommends and never executes` and prohibits a reciprocal pointer; `skills/4-occasional/ate/SKILL.md`, Quick start, says `--gh-repo is what turns on the automatic issue filing at the end — omit it`; `utils/py/gen4_campaign.py:365` defaults to suite, lines 376–378 expose no-synth/model/healing options and line 399 passes `not a.no_synth`. Preserve these boundaries in the minimal pointers. No additional pre-existing blocker found in the full embedded-plan sweep.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixture or campaign was run. Steps 5–6 remain future implementation verification. Live historical checkout/issue-state assertions were not independently refreshed and are not ownership clearance; the plan itself requires that recheck before any future campaign.

Handing off to Producer (operator): add the missing result-report acceptance contract and return for Round 3 review. Do not execute a campaign or add machinery.



## Producer round 3 — result contract explicit

Disposition: Accepted round-2 Should. Canonical plan steps 3/5 now explicitly name complete replay metadata, per-counterexample owner/disposition/evidence and backlink, bounded null conclusions and negative manual completeness controls. Read the current committed plan in full; its embedded earlier copy is historical. Grade all supplied issue requirements against the current plan; no campaign execution or new machinery.

### Reviewer · Round 3

VERDICT: PASS
Basis: Approve the current canonical plan for documentation implementation through DRAFT PR only. Producer round 3 explicitly supersedes the earlier embedded artifact; the full current 88-line plan was reviewed against the supplied #1143 snapshot, including every proposed-contract item, guardrail and initial acceptance criterion. Round 2's omission is resolved. No remaining blocker or additional pre-existing defect found in the full plan sweep. Reversibility: Easy, with the docs-revert rollback at plan line 37. This is plan approval, not implementation verification or campaign clearance.
swept file: yes

- [Pass] Round 2 disposition is complete: `PROJECT/2-WORKING/GH-1143-DEFECT-CAMPAIGN.md:63–67` requires exact inputs/corpus, versions, sanitized environment, outputs/timing, owner/disposition/evidence, Radar/results backlink and bounded null coverage. Lines 73–76 require manual rejection of seed-only stateful replay, missing evidence/backlinks and overclaimed clean results, with evidence under TESTS-RESULTS. Read-only probe: `nl -ba PROJECT/2-WORKING/GH-1143-DEFECT-CAMPAIGN.md` → exit 0; decisive output: `a seed alone cannot replay stateful/concurrent behavior`, `return link to Radar tracking context`, and `Manual omission review must reject`. These are planned manual controls; they have not yet been exercised.
- [Pass] The source's workflow and acceptance requirements have plan equivalents: source/prior assets and revision at lines 26–32; ownership/prior-work boundaries and fresh clearance at 41–46; suitability, hypotheses/oracles, controls, budgets/stops, isolation, same-predicate replay, duplicate classes, severity and separate remediation at 60–69; complete replay/disposition/null contract at 63–67; source-grounded HELD pilot and missing structured adapter at 70–71. The skill-writing step must elaborate these headings using the supplied source contract, including problem-class tool selection, explicit permitted effects/stops and root-cause dedupe; this approval does not substitute argv fuzzing or generic containment for stateful semantic coverage.
- [Pass] Existing seams still support the thin instruction approach: `skills/3-weekly/radar/SKILL.md:786` begins `Sibling: recommend the repo's own verification assets`; its closing paragraph says `Radar recommends and never executes` and prohibits reciprocal asset-to-Radar pointers. `skills/4-occasional/ate/SKILL.md:60–61` says omit `--gh-repo` for no GitHub side effect. `utils/py/gen4_campaign.py:365,376–378,399` establishes default suite mode, explicit no-synth/model/healing flags and synthesis inversion. Plan lines 29–30 retain explicit run/no-synth after approval and absent model/healing/filing options. Preserve the existing no-reciprocal-pointer boundary during the consumer-path review at plan line 72.
- [Unverified — no citation] Anti-goals and delivery remain bounded: plan lines 55–58 stop on broader-gate paths and forbid routing/shared-policy changes; 68–79 require per-case approval, preserve #1131, forbid new machinery/runtime changes and automatic consequential actions, and end at a docs-hook DRAFT PR to development with exact-head status distinctions. Lines 42–46 and 70–71 preserve #1133's hold and #1140/#1136 exclusions. No execution, ledger redesign or new adapter is authorized by this plan.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixture, campaign or gate was run. Implementation checks, provenance retention, final independent QA and publication/status verification at plan lines 72–79 remain future work. Historical tracker/peer-state assertions and remote commit ancestry were not refreshed in this turn; they provide no live ownership clearance. The issue snapshot is the producer-supplied review source, not independently fetched remote evidence.

Relay closed (Approved), no further review turn needed. Handing the completed token back to operator; proceed only within the approved documentation scope and its verification steps.

## Operator disposition — procedural override, 2026-10-18

"Yes override procedural stop." Proceed past the exhausted PLAN review procedural failure.
The reviewer recommendation at d555b12f is substantive PASS with no unresolved correctness
finding; relay-drive exit 4 review-body-rewritten remains rejected evidence. No new plan
review turn, cap reset, or successful harness attestation is claimed. Final implementation
review remains separately capped at three rounds. Prior blocks and failure history retained.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
