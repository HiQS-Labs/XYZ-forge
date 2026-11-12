---
title: "GH-1092 — reviewer evidence permission and target rules"
status: in-progress
created: 2026-11-12
updated: 2026-11-12
owner: Noel
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1092
goal: Deliver target rules and bounded reviewer measurement permissions through the existing prompt.
risk: 3
---

# GH-1092 — reviewer evidence permission and target rules

## Status

| What was just completed | What's next |
|---|---|
| Live prior-art reconciliation and bounded source trace | PLAN Approved round 2; execute focused checks and delivery smokes |

## Outcome and boundaries

A generic reviewer must receive the intended target's policy and be able to measure a
claim using the existing permitted probe path or an explicitly supplied disposable full
clone. Extend the shared prompt and its existing workflow documentation, not the terminal
approval controller. This is a partial delivery for #1092 and
[LTVera GH981](https://github.com/BinoidCBD/LTVera-Pandas/issues/981); neither closes.

User authorized reuse of merged Forge PR1432/1445 and routine implementation choices.
PR992 in LTVera remains unmerged at 7a5c48fa3808217860a7da0044c5ea5824e275bc with
changes requested; no LTVera writes or dependent implementation. GH999 is separate.

Non-goals: Radar solved semantics, universal safety/draft/no-change verdict policy,
a new controller, gate, runner, suite or registry, deployment, merge, global installation,
and replaying the LTVera browser incident. A reviewer prompt is instruction delivery;
it does not mechanically guarantee compliance or settle owner decisions.

## Recon and prior art

Canonical baseline: ed0a386fac4caa170bd9d6b297da7154717288df, origin/development,
full canonical GitHub clone. Prior baseline 76a53663834193d75e1994c8c6b5e4d3f089584b
is an ancestor. Existing PR1432 provides the GH1428 named marathon gate exception and
conditional refusal; PR1445 supplies defect-sensitive acceptance. Reuse both unchanged.
No existing GH1092 capture/ledger row or task clone was found. Existing #1092 explicitly
requests gh reads, pinned-source checks and orchestrator-supplied disposable-clone execution.
Broad prior-art search found related merged work; those are approved reuse inputs, not
reasons to duplicate it. No open matching implementation PR was returned.

Graph search was attempted first; stale index returned no matching Python function.
Confirmed current source directly: utils/py/codex-turn.py calls RelayTurnLib.turn_prompt;
utils/py/rtl.py:866 delegates to shared rtl_turn_prompt in relay-automation/relay-turn-lib.sh.
Its reviewer note allows seeded-artifact probes but does not name target startup/test
policy or GitHub reads; it directs clone-only claims to Unverified without telling a
reviewer how to use an orchestrator-supplied clone. The GH1428 exception only names a
phase command, not this generic route. new-relay.sh already preserves history and requires
dispositions. relay_drive.py judge_terminal attests provenance and conditionally checks
the named marathon gate; it is not a semantic truth verifier. Do not modify it.

Blast radius: all shared-prompt reviewer workers, including Python/default and Bash callers;
producer clause and containment writers stay unchanged. Reversibility: Easy, revert this
prompt/docs/package change; no schema or persistent state migration.

## Smallest viable bet

Extend the existing role note with explicit target-rule discovery and bounded permission,
and align relay-xyz's existing permission description. An alternative of stronger prose
only in start-task does not reach generic workers. A new execution API/controller would
add machinery where an orchestrator-supplied clone and named commands already suffice.
No runtime exception is inferred: absent a supplied clone/command, retain Unverified.

## Ordered implementation and acceptance

1. Obtain independent Codex plan QA, at most three rounds. Commit this input first.
   Paraphrase plan before reading sources; source-backed review follows in the same turn.
2. Amend only rtl_turn_prompt's reviewer role note: read target ROUTER if present and its
   canonical rules; cite root/revision/rule paths and target test policy; Forge GH831 is
   Forge-only, not a host moratorium. Explicitly allow read-only gh queries and pinned
   source checks. Keep scratch, allowlist, no artifact edits and existing GH1428 exception.
3. Permit only commands explicitly assigned by orchestrator in an already supplied separate
   disposable full clone pinned to the reviewed revision. Require root/HEAD/origin/bare/local
   identity before/after, retain command/exit/decisive output, reject identity drift, no
   operator/protected checkout execution, no clone creation or shared Git mutation by reviewer.
   Missing environment means Unverified; no unqualified claim of runtime verification.
   Mirror in relay-xyz's existing item 5, referencing canonical shared prompt.
4. Rebuild existing relay package. In a sibling disposable full clone, run existing
   gh681-reviewer-probe-rules, gh397 reviewer scope, gh505-relay-attest, codex-turn,
   worktree-isolation and GH1428 covering suites as located in registry. No new suites,
   registry entries or synthetic runners; manual controls live only as receipts.
5. Smoke actual rendered prompt and live Codex reviewer transcript: main target names Forge
   rules and runs one assigned focused check in supplied full clone; adjacent foreign target
   uses its own rule policy and absent clone reports Unverified. Apply the same manual delivery acceptance to baseline and candidate: reject baseline
   explicitly for missing target-rule/supplied-clone delivery (quote missing spans and failed
   verdict); accept candidate only with those rendered clauses AND live transcript/assigned-check
   evidence. Retain both verdicts, commands, revisions, exits and decisive output together under
   TESTS-RESULTS/2026-11-12+GH-1092/ with provenance.jsonl. No speculative baseline browser
   run or new gate. Sandbox/network/DB failure stays Unverified. Preserve containment negative controls
   from existing suites. This proves delivery and execution seam, not LTVera/browser safety.
6. Classify all changed paths (including package/ledger). Run required full qualifying gate
   in disposable full clone with identity bracket and committed provenance. Fresh gate after
   material implementation changes; focused checks only between review rounds.
7. Independent Codex FINAL QA (<=3 rounds), real supervisor exit/attestation. Publish verified
   PR into development, referencing #1092 and full LTVera GH981 URL without closing either.
   Parent performs additional Kimi review afterward; no Kimi run here.

## Requirements continuity and remaining gaps

| GH981 decision | This delivery / remaining predicate |
|---|---|
| Target rules | Explicit shared-prompt delivery and observed transcript; host rule content stays host-owned |
| Finding continuity/safety | Reuse history/disposition contract; safety verdict policy remains owner choice |
| Independent runtime | Supplied-clone permission and measured focused run; actual LTVera browser/failing-before replay remains open |
| Issue-derived DoD | Reuse PR1445; issue acceptance is retained here, not replaced by plan scope |
| Draft safety | Existing draft versus readiness distinction retained; eligible safety findings still owner decision |
| No change | No diagnosis conclusion claimed; ratifier/threshold still owner decision |

Original eight remain open: contextual production logs/test traffic, introducing history and
assertion inversion rationale, contradictory constraints, named finding closure, independent
browser replay, production-relevant timing/branch reachability, host test policy, and conclusions
after measurement. This change addresses a demonstrated shared delivery seam only. No eight-item
closure or measured no-change claim. All historical severity grades remain as the issue records.

## Rating and QA evidence

75/70/50/65, no override: priority follows the explicit task, severity reflects wrong-policy and
unmeasured-claim risk; appeal is neutral; cheapness reflects bounded prompt/docs changes plus
mandatory full gate and two independent reviews. Two incident reports (#1092 and LTVera GH981)
are evidence of scope, not a measured recurrence rate. No complete trend survey claimed.

PLAN R1: FAIL, S1 accepted (baseline rejection lacked explicit verdict); revised step 5.
PLAN R2: Approved, supervisor exit 0; relay-system/2026-11-12/gh1092-plan.codex.md.
Reviewed plan revision 5e990ca71; attestation retained by the existing driver.
FINAL: pending. Focused checks passed; foreign delivery/missing-runtime smoke passed.
Main smoke parked on sandbox fixture-temp denial, not a code/suite pass; see
TESTS-RESULTS/2026-11-12+GH-1092/SUMMARY.md. FINAL reviewer must resolve that predicate
before approval. Classified full gate remains pending. Lessons: NO_ENTRY.
