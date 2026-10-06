---
gh_issue: 983
source: https://github.com/HiQS-Labs/XYZ-forge/issues/983
title: Workhorse Codex outcome continuation
status: active
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Continue authorized work until its requested outcome is verified or externally blocked
---

# Workhorse Codex outcome continuation

## Status

| What was just completed | What's next |
|---|---|
| Independent plan and final QA Approved; bounded fixtures and governance evidence retained | Publish reviewed PR through exact-head push gate; canonical landing and Skills Army deployment await authorization |

## Recon and bet

Base: development `8ec99b6066c997a00c40761c9efb9f9caaff8b8f`. The three skill files match the installed collection. Graph Verify-tier coverage for these paths reports freshness not_tracked (generation 2026-09-01); direct source reads used. Rung 0 stops on checklist exhaustion; Rung 6 permits parked/held items to end a batch. The Claude Stop hook checks open lines only, fails open, and cannot validate outcomes. install.sh is legacy link deployment; managed links must use Skills Army.

Installed codex-cli 0.159.1 exposes stable hooks and Goals. Current official sources: [hooks](https://learn.chatgpt.com/docs/hooks), [Goals](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex), [skills](https://learn.chatgpt.com/docs/build-skills). Hooks require configuration and trust; a configured Stop block can cause a continuation prompt. Goals provide budgeted idle continuation but require explicit activation and evidence-based completion. This session exposes create_goal, whose contract requires an explicit Goal request; do not infer one from ordinary execution authorization. Skill frontmatter is not a Codex hook installation.

Smallest bet: edit existing SKILL.md decision rules; no scripts, hook configuration, new tests, gates, dependencies, global configuration or new deployment targets. Easy to reverse through a Git revision and manager update; ripple is workhorse consumers interpreting completion. Main failure mode is treating instruction compliance as guaranteed runtime enforcement. Disclose that limit. A new Stop adapter is inappropriate under GH-831's no-new-gate rail and still could not infer semantic acceptance. Preserve Claude frontmatter and script bytes; clarify limits.

Ratings: pri 80 (explicit operator request and recurring interruption), sev 75 (unfinished operational gates, no evidenced data loss), appeal 50 (neutral), effort 90 (focused text correction and existing tooling). Recurrence is the supplied session observation, not a measured incident count.

## Ordered execution and acceptance

1. Commit this plan and run shipped Codex plan relay QA (three-round cap); adjudicate findings before implementation. -> Approved receipt.
2. Admit exact GH-983 ledger row, then update Rung 0 and Rung 6 plus a short Codex continuation/enforcement section. -> Required findings remain active; each done item carries evidence; reconcile original request, steering and acceptance before ending. Subtask completion, status answers, restored auth and handoffs trigger the next authorized action in the same turn. Stop only for verified completion, user pause/cancellation, or concrete external blocker after independent work; preserve permissions and deployment windows. Runtime/system limits leave truthful unfinished state.
3. Use quick_validate and bounded read-only Codex decision fixtures recorded under TESTS-RESULTS/2026-10-06+GH-983/ with provenance. -> Seven scenarios: subtask advances, status resumes, authentication retry, checked boxes with unmet acceptance stay unfinished, handoff cannot replace execution, real blocker accurate, future window holds deploy. Operational regression requires active-job inventory and service baseline; running sync/analysis/worker findings prevent the gate from passing. Compare old and new instructions on an unmet-acceptance red control. No new test suites, runners or registry changes; fixtures measure model decisions, not guaranteed multi-turn behavior.
4. Commit evidence and run deterministic PDDA/ledger checks in a disposable full clone with repository identity bracket; final Codex relay QA on committed scope/evidence. -> Approved; inspect warnings and record dispositions, no blanket exit-zero claim.
5. Push via classified pre-push gate from disposable full clone, open development PR, inspect base/head/scope and actual hosted checks. -> Reviewed PR awaiting merge, truthful active doc. Do not merge without authorization.
6. User requested deployment through Skills Army: preview/apply named workhorse update from reviewed canonical task revision, preserving existing target links and unrelated skills; verify every installed payload byte and both link read-throughs. -> Record exact revision and deployment status; disclose awaiting development landing. If deployment requires landed development, retain pending state and obtain that authorization only after reviewable result.

## Validation limits

Bounded model decision fixtures and review can show instruction interpretation, not ensure future agent compliance. Goals/hooks are supported separate runtime mechanisms, not enabled by this edit. No deployment-window override, permission expansion, trust bypass or gate bypass.

## Plan QA disposition

Approved in relay-system/2026-10-06/gh983-plan.codex.md (reviewed da9ca8b2). Nit: final relay will fill Definition of Done. Fixtures will disclose any base pass rather than claiming causal proof. Raw quick_validate rejects existing Claude hooks frontmatter; retain it and validate a scratch projection without that field separately.

## Execution evidence

TESTS-RESULTS/2026-10-06+GH-983/ contains non-empty base/candidate decision outputs, source hashes, commands, provenance, validator compatibility result, PDDA/ledger output and identity bracket. Base also passes: no causal reliability claim. Complete/incomplete evidence mutation changes completion true to false. Raw quick_validate rejects pre-existing Claude hooks; projection passes. Deterministic checks: zero errors/failures, PDDA 31 and ledger 9 warnings on unrelated unchanged state. Final readiness is subject to independent QA and the exact-head push gate. Required merge/deployment work is pending, not parked or completed.

## Final QA disposition

Approved Round 2 in relay-system/2026-10-06/gh983-final.codex.md (reviewed 5b6994aa). Round 1 review-input blocker resolved by correcting the declared artifact path and furnishing comparison.json; no source change was needed. Final reviewer confirmed contract, source diff, byte preservation and evidence limits. Skills Army named update preview changes workhorse only; installed payload and both app links remain unchanged. Merge/deployment remain required unfinished work pending authorization, not incidental parked work.
