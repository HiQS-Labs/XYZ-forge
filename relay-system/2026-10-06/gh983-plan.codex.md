# RELAY · GH-983 workhorse continuation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh-983-workhorse-continuation-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review questions and envelope

Read PROJECT/2-WORKING/GH-983-CODEX-CONTINUATION.md and skills/2-daily/workhorse/{SKILL.md,stop-hook.sh,install.sh}. Text-only local instruction correction, no enterprise machinery or new tests/gates. All seven scenarios and operational regression in GH-983 are required. Does the plan cover same-turn continuation, semantic completion evidence, scope preservation, external-blocker handling and authorization/window boundaries? Does it truthfully separate instructions from Goals/configured trusted hooks? Are bounded decision fixtures and a base red control adequate for the limited claim? Is deployment from an unmerged revision clearly labelled rather than called landed development? Review only; no tests or code edits.

## Setup
- Artifact under review: **GH-983-CODEX-CONTINUATION.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-06

### Artifact — GH-983-CODEX-CONTINUATION.md
```
---
gh_issue: 983
source: https://github.com/HiQS-Labs/XYZ-forge/issues/983
title: Workhorse Codex outcome continuation
status: active
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Continue authorized work until its requested outcome is verified or externally blocked  [Unverified — no citation]
---

# Workhorse Codex outcome continuation

## Status

| What was just completed | What's next |
|---|---|
| Refreshed development, inspected skill consumers and local Codex capabilities, registered and rated GH-983 | Plan relay QA, focused instructions, bounded scenario validation, final QA and reviewed PR, authorized Skills Army update |

## Recon and bet

Base: development `8ec99b6066c997a00c40761c9efb9f9caaff8b8f`. The three skill files match the installed collection. Graph Verify-tier coverage for these paths reports freshness not_tracked (generation 2026-09-01); direct source reads used. Rung 0 stops on checklist exhaustion; Rung 6 permits parked/held items to end a batch. The Claude Stop hook checks open lines only, fails open, and cannot validate outcomes. install.sh is legacy link deployment; managed links must use Skills Army.

Installed codex-cli 0.159.1 exposes stable hooks and Goals. Current official sources: [hooks](https://learn.chatgpt.com/docs/hooks), [Goals](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex), [skills](https://learn.chatgpt.com/docs/build-skills). Hooks require configuration and trust; a configured Stop block can cause a continuation prompt. Goals provide budgeted idle continuation but require explicit activation and evidence-based completion. This session exposes create_goal, whose contract requires an explicit Goal request; do not infer one from ordinary execution authorization. Skill frontmatter is not a Codex hook installation.

Smallest bet: edit existing SKILL.md decision rules; no scripts, hook configuration, new tests, gates, dependencies, global configuration or new deployment targets. Easy to reverse through a Git revision and manager update; ripple is workhorse consumers interpreting completion. Main failure mode is treating instruction compliance as guaranteed runtime enforcement. Disclose that limit. A new Stop adapter is inappropriate under GH-831's no-new-gate rail and still could not infer semantic acceptance. Preserve Claude frontmatter and script bytes; clarify limits.

Ratings: pri 80 (explicit operator request and recurring interruption), sev 75 (unfinished operational gates, no evidenced data loss), appeal 50 (neutral), effort 90 (focused text correction and existing tooling). Recurrence is the supplied session observation, not a measured incident count.

## Ordered execution and acceptance

1. Commit this plan and run shipped Codex plan relay QA (three-round cap); adjudicate findings before implementation. -> Approved receipt.
2. Admit exact GH-983 ledger row, then update Rung 0 and Rung 6 plus a short Codex continuation/enforcement section. -> Required findings remain active; each done item carries evidence; reconcile original request, steering and acceptance before ending. Subtask completion, status answers, restored auth and handoffs trigger the next authorized action in the same turn. Stop only for verified completion, user pause/cancellation, or concrete external blocker after independent work; preserve permissions and deployment windows. Runtime/system limits leave truthful unfinished state.  [Unverified — no citation]
3. Use quick_validate and bounded read-only Codex decision fixtures recorded under TESTS-RESULTS/2026-10-06+GH-983/ with provenance. -> Seven scenarios: subtask advances, status resumes, authentication retry, checked boxes with unmet acceptance stay unfinished, handoff cannot replace execution, real blocker accurate, future window holds deploy. Operational regression requires active-job inventory and service baseline; running sync/analysis/worker findings prevent the gate from passing. Compare old and new instructions on an unmet-acceptance red control. No new test suites, runners or registry changes; fixtures measure model decisions, not guaranteed multi-turn behavior.
4. Commit evidence and run deterministic PDDA/ledger checks in a disposable full clone with repository identity bracket; final Codex relay QA on committed scope/evidence. -> Approved; inspect warnings and record dispositions, no blanket exit-zero claim.
5. Push via classified pre-push gate from disposable full clone, open development PR, inspect base/head/scope and actual hosted checks. -> Reviewed PR awaiting merge, truthful active doc. Do not merge without authorization.
6. User requested deployment through Skills Army: preview/apply named workhorse update from reviewed canonical task revision, preserving existing target links and unrelated skills; verify every installed payload byte and both link read-throughs. -> Record exact revision and deployment status; disclose awaiting development landing. If deployment requires landed development, retain pending state and obtain that authorization only after reviewable result.

## Validation limits

Bounded model decision fixtures and review can show instruction interpretation, not ensure future agent compliance. Goals/hooks are supported separate runtime mechanisms, not enabled by this edit. No deployment-window override, permission expansion, trust bypass or gate bypass.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded instruction-correction plan, not implementation, runtime enforcement, deployment or merge readiness. The review envelope and ordered acceptance steps supply the criteria despite the scaffold's empty Definition of Done field.
swept file: yes

- [Pass] Same-turn continuation, semantic completion and scope preservation are explicit in the complete plan: `PROJECT/2-WORKING/GH-983-CODEX-CONTINUATION.md:33` requires “each done item carries evidence,” reconciliation of “original request, steering and acceptance,” and next authorized action after subtasks/status/auth/handoffs. It retains concrete external blockers, independent work, user pause/cancellation and permission/window boundaries. Preserve these clauses in implementation.
- [Pass] Minimal scope and enforcement limits are truthful: plan line 26 says “no scripts, hook configuration, new tests, gates, dependencies, global configuration or new deployment targets”; line 41 limits fixtures to instruction interpretation. Official [hooks documentation](https://learn.chatgpt.com/docs/hooks) describes definition-specific trust and Stop continuation (sections “Review and trust hooks” and “Stop”); official [Goals documentation](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex) describes idle, active, budgeted continuation and evidence-based completion. The session's create_goal contract independently requires an explicit request. Keep Goals/hook activation separate from this text edit; the installed CLI version is not independently measured in this turn.
- [Pass] Plan line 34 enumerates all seven required scenarios, active-job/service-baseline operational regression, an old/new unmet-acceptance red control, committed provenance and the model-decision limitation. This is adequate planned evidence for the limited claim. At execution, retain exact fixture inputs, expected decisions, full outputs, instruction revision/model identity and an actually observed base failure; if the base passes, report that rather than claiming a demonstrated fix. No new suite or gate is needed.
- [Pass] Review and publication boundaries remain explicit: plan lines 35–37 require committed evidence, final independent QA, a development PR with actual hosted checks, no unauthorized merge, and deployment from an exact reviewed task revision “awaiting development landing.” Keep deployment status distinct from landed development.
- [Pass] Full supporting-file sweep matches the recon: SKILL.md Rung 0 says “Stop only when no `- [ ]` line remains”; Rung 6 permits “all remaining items are parked/held.” stop-hook.sh selects only lines starting `- [ ]` and otherwise fails open; install.sh refuses replacement of an existing live foreign/managed link. These pre-existing limitations are addressed or deliberately preserved by the plan. No additional actionable pre-existing defect was identified in these four reviewed files within this instruction-only scope.
- [Nit] The relay scaffold still says `Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_`. On future scaffolds, populate it or point to the review envelope/ordered acceptance; it does not prevent grading this plan.
- [Unverified — needs clone run] No scenario fixture, quick_validate, PDDA/ledger gate, pre-push gate or operational regression was executed here. They remain execution acceptance requirements, not passing results. No git command, executable fixture or artifact edit was performed.

Evidence scope: Verify-tier graph project XYZ-forge is a different checkout; generation `2026-09-01T15:54:30Z`. Coverage reports the plan missing and all three skill files not_tracked. Exact current source reads of all four complete files supplied the review evidence; no fresh graph completeness claim is made.

Relay closed (Approved), no further review turn needed. Producer may proceed to implementation and the required evidence/final QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
