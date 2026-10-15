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
| Intake and source trace complete | Implement, verify and independently review the bounded docs mode |

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

Existing express regression: 113 pass at d741ae2a; Codex prerequisite: 43 pass. Final candidate manual docs controls: 11 pass at 1984ef66, including README+PNG acceptance, mixed code, policy, executable, symlink and code-to-text rename refusals, permission-change identity, truthful docs scaffold, parser defaults and exact receipt matching. Focused clone identity unchanged. Evidence: `TESTS-RESULTS/2026-10-15+GH-1080/`. Normal full publication gate and independent review remain pending. No separate pre-implementation plan relay claimed; final independent QA will inspect both the chosen rule and implementation.

## Lessons Learned (For Future Agents)

The existing registered PDDA repository contract suite runs the actual docs gate and can be reused without inventing a runtime coverage claim.
