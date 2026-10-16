---
title: 'GH-1080: Allow documentation text and images through express'
status: Active
created: 2026-10-15
updated: 2026-10-15
owner: Codex
gh_issue: 1080
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1080
doc_type: feature
goal: Allow small documentation text and image updates through explicit express admission
effort: 2
complexity: 2
risk: 3
phases: 1
---

# GH-1080 — Express documentation updates

## Status

| What was just completed | What's next |
|---|---|
| Intake and source trace complete | Merge PR #1082 after final-head checks; hosted reconcile completes the task records |

The operator authorizes changing express admission so ordinary documentation text and images do not need a critical-hotfix rationale or a behavior-covering runtime suite. Extend the existing driver and skill together, preserve safe landing and receipts, and leave the README diagram for a subsequent request.

Acceptance: README plus image qualifies with docs verification; mixed code/config and consequential policy changes retain normal admission; hotfix and recovery evidence remain accurate. No new suites or gate machinery.


## Plan and acceptance

Assumption: ordinary documentation can use the existing deterministic PDDA suite; that suite does not establish prose accuracy or image rendering. Tradeoff: a small path predicate keeps runtime/config and executable policy outside this lighter lane. Failure mode: mistaking a text extension for harmless documentation. See [Recon Map](recon-gh1080-express-docs.md).

1. Add explicit `--docs-only` selection to the existing express driver with fixed registered `test/pdda-repo-contract.sh`, allowed ordinary documentation/image paths, preserved file/text bounds, and accurate labels. Include rename source paths and reject executable/symlink inputs. -> expect README plus image admission, mixed/runtime/policy refusals and unchanged hotfix behavior.
2. Update the canonical express skill and SOP authorization wording. -> expect docs updates need no critical-hotfix rationale or runtime behavior suite; agent still checks prose, rendering and links; no deployment copy edits.
3. Verify in a disposable full clone with the existing express suite and manual docs admission/negative controls, then the classified normal publication gate. Run independent native relay QA before publishing the PR against development. -> expect committed attributable evidence, exact-head checks and safe published-clone closeout.

## Scope and rollback

Changes cover the express driver, its skill, SOP and task evidence. No new suite, registry entry, runner, receipt schema, background process or dependency. The pending README diagram is excluded. This admission policy is Costly because it controls direct landings: revert the driver/skill/SOP commit together to restore hotfix-only admission. Existing suite receipts remain readable.

## Verification

Existing express regression: 113 pass at d741ae2a; Codex prerequisite: 43 pass. Final candidate manual docs controls: 11 pass at 1984ef66, including README+PNG acceptance, mixed code, policy, executable, symlink and code-to-text rename refusals, permission-change identity, truthful docs scaffold, parser defaults and exact receipt matching. Focused clone identity unchanged. Evidence: `TESTS-RESULTS/2026-10-15+GH-1080/`. Independent native Codex QA approved Round 2 with mechanical attestation at reviewed head b8ce0544efb13e40de8a41d89157282bd0a56823; the 16-control corrected paperwork falsifier is retained separately. The reviewer's optional stale-dashboard filename nit was removed. Normal full publication gate passed 409/409 in 929 seconds at 824c9288; publication identity unchanged. [PR #1082](https://github.com/HiQS-Labs/XYZ-forge/pull/1082) targets development; retained receipt publication and final-head checks finish before readiness. No separate pre-implementation plan relay claimed; final independent QA will inspect both the chosen rule and implementation.

## Lessons Learned (For Future Agents)

The existing registered PDDA repository contract suite runs the actual docs gate and can be reused without inventing a runtime coverage claim.


## Bounded replan — corrected revision review

The driver recorded two fires for `RELAY-GH1080-FINAL-20261015`: first a missing fresh-clone tick initialization refusal (no reviewer ran), then the completed Round 1 review requesting the paperwork eligibility correction. Round 2 was refused before dispatch by the two-attempt lane cap. Original logs are retained under the local task `temp/gh1080/`; the attempt ledger is not edited or reset.

Under AGENTS.md's explicit replan-note alternative to the parked-lane rule, permit exactly one additional driver fire for the implemented and manually verified df896f4f correction. Use the same token, same thread, original cumulative 3-round cap and same artifact allowlist; `--force` is the driver's mechanical admission for this recorded replan, not an assertion of a new operator override. If this review does not approve, retain the unfinished PR work and report the next action; no additional forced fire, new token, increased cap or machinery repair is authorized by this note.


## Authorized merge continuation — 2026-10-15

Noel released PR #1082 to this merge coordinator. PR #1053 is merged and hosted-qualified 409/409 at d48aa774; its durable development checkpoint is `ded6208053d5a714fb6aac8a98744a6237d4dd95`. One bounded caller repair reconciles the current ledger/changelog through the existing canonical B1 resolver, preserves every incoming non-generation row and all four original product blobs, and completes the mandatory Costly-bet record by appending a dated checkpoint and decision index. The original changelog entry is unchanged. The pinned repair slot is 1/2; no reset.

Original native final round 2/3 and its mechanical attestation remain historical. Current-base independent native final round 3/3 is pending, followed by existing checks and normal publication/merge gates. No additional forced driver fire or mechanical-attestation claim is authorized. The original 16 manual controls may be repeated without additions. No tests, assertions, parameters, runner, live express landing, skills installation, settings change or main promotion is added. Batch #1086 owns the actual landing/qualification record.
