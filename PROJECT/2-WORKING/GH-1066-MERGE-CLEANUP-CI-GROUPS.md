---
gh_issue: 1066
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1066
title: "merge-cleanup: CI-heavy landing groups"
status: In Progress
created: 2026-10-14
updated: 2026-10-14
owner: Codex
goal: "Reduce repeated qualification through coherent group preparation without waiving required checks."
doc_type: feature
---

# GH-1066 — CI-heavy landing groups

## Status

| What was just completed | What's next |
|---|---|
| Added caller-owned group planning and explicit gate boundaries. | Documentation gate and PR publication. |

## Scope and decision

Documentation only: Phase4 gains an ordered group preparation, candidate freeze, full qualification,
supported landing and final verification strategy. No runtime, CI, new test or bypass change.
Easy to reverse by reverting this section. Existing Phase5 per-merge reconciliation remains binding.
The CI churn recovery SOP and #854 demonstrate that staging exceptions need their own authorization;
this general skill update does not renew that historical exception or claim automatic savings.

## Verification

Read the skill's Phase4/5 and batch regression-sweep contracts and the existing churn recovery SOP.
Manual review checks supported-path fallback, exact candidate/landed evidence, independent review,
no policy bypass, invalidation after changes and avoidance of duplicate broad runs. No performance
claim or execution of a merge batch is made. No new test required for this prose change.

## Start-task continuation and plan

The operator invoked start-task after the documentation prototype at14e5ceb. This is not a
claim of pre-implementation QA for that earlier draft. Its pending publication gate was
stopped for the expanded review requirement and is not passing evidence. Reuse the existing
fresh independent clone and branch from development5c46c49, created before this invocation;
the pre-existing path/name is retained on resume rather than creating a duplicate task clone.
No remote branch or PR has been published. The main checkout remains outside task ownership.

### Recon and solution fit

Outcome: fewer avoidable repairs/pushes/full qualification cycles during multi-PR landings.
Observed origin: Phase4 sequences dependencies, Phase5 reconciles after each merge, and the batch
protocol already records queues of3+. No instruction currently prepares coherent CI groups or
requires adversarial review of their sequence. The new instruction is caller-owned, feeding the
existing Phase5 consumer; it neither overrides that consumer nor creates an automatic batch mode.

Smallest bet: extend only merge-cleanup guidance and its existing batch record with bounded
cross-model strategy review for3+ authorized PRs. Leave1–2PR ordinary queues without mandatory
extra review (unless risk or repo rules require it). No driver, persisted schema, CI, dependency,
setting, test, gate runner or deployment changes. Revert the added section to roll back (Easy).

Alternatives: (1) reuse existing caller/relay/batch issue (chosen); (2) merely sort PRs, which leaves
qualification timing and cross-PR risk unreviewed; (3) change CI triggers or add an aggregate merge
engine, which is broader than this request and needs separate policy/authorization. Strongest
counterargument: a mandatory review can become more ceremony than saved CI; constrain it to one
batch-level review before first merge, up to3 rounds, and reopen only for material plan changes.

### Ordered work and acceptance

1. Review this plan independently through relay-xyz; approve before changing the prototype further.
   Read the whole skill, existing churn recovery SOP and this issue; reject unnecessary machinery.
2. Admit the exact GH1066 roadmap row with accepted-start, then extend group preparation with an
   adversarial reviewer using a different actual model family from the plan author (CLI brand alone
   is not proof). Record identities, member/base/head SHAs, proposed order/groups, CI checkpoints,
   conflicts and rollback in the existing batch issue/relay artifact. Require specific disposition
   of supported findings; review advises, deterministic gates and operator authority still govern.
3. For3+ PRs, review before first merge; one batch-level loop, cap3 rounds, no per-PR duplicate
   reviews. One/two PRs have no automatic extra review. Invalidate affected approval when membership,
   dependency/order, base or material risk changes; distinguish immaterial record updates. Unknown
   reviewer identity or missing review is recorded neutrally, not a code defect or new blocker issue;
   do not claim cross-model approval or proceed through a required missing review.
4. Verify manually using four retained scenarios: three interacting PRs require review; two routine
   PRs do not; same model behind another CLI does not qualify; changed membership/dependency/risk
   invalidates prior approval. An unsupported batching path retains sequential reconciliation and
   required per-PR CI. Mutation of the threshold or different-model condition must be detected by
   the recorded manual review (not a new persistent test). Keep claim-first counterexamples bounded.
5. Final independent Codex relay QA on the implementation and manual evidence. Then run the
   classified final full gate once in a separate disposable full clone, with identity proof, retain
   provenance, publish one PR to development and verify its actual head/base/checks. Merge/deploy
   stay separate. Retire only this workflow's safely published task/helpers under current repo policy.

### Ratings and unknowns

Persisted65/25/50/85: explicit operator-requested workflow priority; bounded process cost, no observed
product data loss; neutral appeal50; small prose implementation. No numeric override. Recent/prior
14-day distinct incident counts are unknown; no growth claim. No measured CI saving is promised.
The strategy cannot force one/two full runs while a repo independently mandates per-PR full CI.

## Progress

- [x] Plan relay approved.
- [x] Revised skill and retained manual scenarios satisfy the requirements.
- [ ] Final relay approved and classified gate passes at the final revision.
- [ ] Ready PR published; owned safe checkouts retired or preservation reason reported.

Plan QA approved in round1: attestation c6fa142, reviewed315fa63. The reviewer clarified that batch strategy review does not replace required per-PR QA; implemented explicitly. Owned helper: `$(dirname "$PRIMARY_REPO")/XYZ-forge-gh1066-merge-cleanup-ci-groups-2026-10-14-verify`. Seven manual scenarios, two manual red variants and existing codex-turn43/0 retained with limitations. Final QA and final classified gate remain pending.

Final QA approved in round1 at b21dcac (reviewed ee3e803); production skill SHA2568533cb63558432f7e925399ef9334c4c5142333bba64e8569d5e0b5525a5010d. No blocking findings. Invocation nit disposition: future relays must pass artifact-file to seed the advertised alias; the reviewer read and hashed the canonical committed skill, so current approval is valid. No source change required. Final gate uses the owned separate full verify clone; prototype gate remains interrupted/non-passing.

Qualification found a hardcoded local path in this plan (pdda-check-hardcoded-paths); replaced with a portable primary-sibling reference. Skill bytes still match final QA; metadata correction receives the focused portability check before a fresh final gate. The preceding gate is interrupted/non-passing evidence.
