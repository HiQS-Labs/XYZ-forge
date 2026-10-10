---
title: Sharpen SWE governance
gh_issue: 1007
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1007
status: Reviewed — awaiting merge
created: 2026-10-09
updated: 2026-10-09
owner: Codex
goal: Smallest sound changes across planning, implementation, and review without CI proliferation
doc_type: project
branch: feat/gh1007-swe-governance
reversibility: Easy — revert the instruction and catalog edits before deployment
---

# Sharpen SWE governance

## Status

| What was just completed | What's next |
|---|---|
| Both QA relays Approved; PR #1009 published through normal gate | Verify hosted checks; await authorized merge before GH-1008 |

## Requirements and serial handoff

| Issue | Scope and acceptance | Dependency and state |
|---|---|---|
| [GH-1007](https://github.com/HiQS-Labs/XYZ-forge/issues/1007) | Revise SWE in its owning source; planning, implementation, review; four axes; reuse; earned tests; advisory performance; plan and final relay QA | [PR #1009](https://github.com/HiQS-Labs/XYZ-forge/pull/1009); both QA Approved; awaiting checks/merge |
| [GH-1008](https://github.com/HiQS-Labs/XYZ-forge/issues/1008) | Ponytail-first performance measurement skill using existing evidence and task docs | GitHub issue only by explicit request. Start after SWE finishes; no performance implementation here |

/start-task ends at a ready PR. It does not authorize merge or deployment. If SWE is
ready but unmerged, preserve GH-1008 as awaiting its prerequisite rather than merging
for convenience or starting against an unlanded governance contract.

## Recon and current evidence

Base: `ecec5561a200b12c235bec3dd9dc37dd5d8d0d5e` on `origin/development`.
This is an instruction/consumer change, not a runtime refactor.

- `skills/1-hourly/swe/SKILL.md`: frontmatter and opening scope restrict governance to
  build/spec documents; Minimal/Diagnosable/Blast/Proof give useful discipline but
  security and performance are not first-class axes. House invariants impose a
  state-count threshold and SOLID wording, and the scaffold mandates ceremony and
  correlation IDs regardless of change size. Migration advice mandates bidirectional
  synchronization and fallback even when a simpler safe contract fits.
- `ARCHITECTURE.md:63`: discovery row advertises plans only; update alongside scope.
- `skills/1-hourly/recon/SKILL.md:122` and `:128`: consumers refer to SWE's named
  Pillar 0 and Blast sections. Preserve these stable anchors in the revised skill,
  including their current-state-evidence versus proposed-impact distinction.
- `skills/1-hourly/swe/install.sh`: legacy symlink installer; no behavior change needed.
  Current deployment is a Skills Army projection; do not run this installer or edit
  deployed payloads. `skills/3-weekly/skills-army-hq/SKILL.md` owns source-first delivery.
- Existing `skills/1-hourly/start-task/SKILL.md` supplies lifecycle and independent QA;
  SWE should govern decisions without forking that pipeline. `skills/1-hourly/ponytail/SKILL.md`
  minimizes mechanism while retaining explicit requirements.
- Prior-art recon found no duplicate request/PR; GH-325 owns historic canonical-skill
  migration and is not this scope. Related maintenance reports #805/#831/#857 support
  the concern but are not independent incident counts.
- Graph Verify tier: project XYZ-forge, recorded generation 2026-09-01T15:54:30Z;
  candidate Markdown/installer paths have untracked freshness and architecture has
  changed metadata. Read current source directly; no graph completeness claim.

## Bet, alternatives, and radius

Outcome: agents make surgical changes without letting test maintenance become the product.
Smallest bet: one revised SWE entrypoint and its catalog sentence, plus required task
records and evidence. Prefer total lifetime complexity over raw LOC. Safety/security
requirements set floors; maintainability and performance are balanced against real needs.

Keeping the current plan-only skill misses the requested implementation/review domains.
Adding a policy framework or more CI tests would recreate the problem. The proposed
rewrite removes repeated prose and rigid prescriptions while retaining their useful
contracts. No runtime scripts, tests, dependencies, workflows, global app changes, or
performance-skill implementation. No automatic test deletion or security downgrade.

Radius: future agents loading SWE and its catalog entry. Easy to revert in Git; deployed
behavior stays unchanged until a separately authorized source-first deployment. Failure
mode: brevity drops a safety or consumer contract. Plan/final QA and the scenarios below
are the tripwire; revise the text before publication. No runtime shield is warranted.

## Ordered implementation and acceptance

1. Obtain independent Codex plan approval of this plan and the proposed draft seeded
   read-only as `.relay-artifacts/SKILL.md`. The proposal is not production code. Ensure
   the named Pillar 0/Blast anchors are retained when applying it. Three review rounds
   maximum; record dispositions and stop on unresolved blocker or tool failure.
2. Admit the exact owned roadmap row through `--accepted-start`, then update only
   `skills/1-hourly/swe/SKILL.md` and the SWE catalog description. Expect three modes,
   four explicit axes, reuse with a fit exception, separate test/CI admission burdens,
   proportionate ceremony, and advisory performance guidance tied to existing records.
3. Verify with the existing skill format validator and manual behavioral review below.
   Capture command/results, final source digests and provenance under
   `TESTS-RESULTS/2026-10-09+GH-1007/`. An isolated invalid-frontmatter copy supplies
   the validator's red control; no new permanent test script or CI suite.
4. Commit implementation/evidence and run independent final Codex relay QA on the
   full base-to-head diff, scenarios, rating and provenance. Adjudicate evidence-backed
   findings, reject speculative machinery with a stated ponytail disposition, re-review
   up to three rounds. Reviewer can write only the relay thread and run no test suites.
5. Run the actual path classifier and required documentation gate. `releases.db/sql`
   and evidence files follow the classifier's actual route, not a guessed docs exemption.
   Mutation-heavy checks, if required, run in a disposable full clone with identity checks.
   Push through the installed pre-push hook, open PR against development, inspect emitted
   head/base/diff/checks, and retain the clone awaiting authorized landing.

## Manual scenarios and verification limits

Review the revised instructions against these decisions; record reasoning and source
citations, not brittle text-matching assertions:

- Small reversible edit with covering tests: reuse the check; no new suite, framework,
  plan ceremony, performance baseline, or arbitrary four-test batch.
- New authorization boundary with missing coverage: preserve meaningful verification;
  justify the gap and ongoing cost, then independently choose CI placement under repo policy.
- Existing writer fits a feature: extend it; incompatible security responsibilities are
  a reason to separate, not to force reuse or create an unexplained duplicate subsystem.
- Faster overall CI caused by a warm dependency cache: pipeline evidence only; no claim
  that product latency improved. A noisy product sample is inconclusive.
- Slow hot path: record comparable base/candidate workload and environment, summarize
  advisory evidence in existing task records; no new blocking gate or issue per measurement.
- Authorized irreversible action with no stop checkpoint: flag the missing last safe
  intervention point despite authorization. An Easy rename needs no such ceremony.
- Rolling migration: retain mixed-version compatibility, concurrent-write correctness,
  bounded backfill, convergence, rollback window and retirement checks without assuming
  bidirectional sync or safe fallback. Offline migrations may use simpler mechanisms.

Format checks do not prove agent behavior. Manual judgments and independent QA are bounded
instruction review, not a claim of exhaustive multi-model deployment testing. Existing
repository test policy remains binding. No new tests or gate machinery are permitted.

## Rating and recurrence

PRS read-back: **75/55/50/85**, calc 265, no override. Priority follows the user's order;
severity reflects reported maintenance burden, not an invented security/data-loss incident;
appeal is neutral; instructions-only delivery is cheap. Search windows: 2026-09-25–10-09
and 2026-09-11–09-25. Related overlapping CI reports exist; unique incident trend is unknown.
PDDA planning metadata is not a second PRS score. Rating persisted via the canonical CLI.

## QA receipts and dispositions

Plan Round 1: changes requested (S1); Round 2: Approved, driver exit 0. Final: Approved in Round 2, driver exit 0; receipt `relay-system/2026-10-09/gh1007-final.codex.md`. Format green/red, seven manual scenarios and docs gate complete;
classifier docs/tier 1; gate exit 0 with 28 repository warnings. Evidence: `TESTS-RESULTS/2026-10-09+GH-1007/`. Any findings and their accepted/rejected dispositions will
be recorded here with relay links.

S1 disposition: Implemented in the proposed draft before plan Round 2. Restore stop/rollback
signals and last safe intervention points for Costly and One-way changes, including a pre-action
checkpoint and explicit authorization when rollback is impossible. Add the distinction to the
existing manual review scenarios. No machinery or suite added. Proposal now also restores the
Pillar 0/Blast headings and clarifies that the explicitly requested GH-1008 skill is allowed
while reusing SWE governance. Receipt: `relay-system/2026-10-09/gh1007-plan.codex.md`. No approval inferred from format checks alone.

Final QA Round 1: SWE passed all seven textual scenarios; review requested runtime-doc
cleanup and a complete diff packet. F1 disposition: Rejected (Out of Scope / Ponytail).
It is a real pre-existing architecture mismatch, parked at
`PARKED/2026-10-09-architecture-runtime-ownership.md`; the SWE catalog sentence does not
introduce it. No runtime owner changes are required by this task. Missing review input:
Implemented — seed the complete base-to-head textual diff and changed-path manifest;
review binary ledger via the SQL diff and current read-only row. Scope historical
append-only CHANGELOG to the new GH-1007 entry and verify no historic text changed.

## Handoff

Implementation and both independent audits are complete. Source digest is unchanged since
focused verification. Any bookkeeping after final approval records receipts/status only;
publication still requires the installed push gate and live PR/check inspection. GH-1008
remains issue-only pending authorized landing of GH-1007. Retain the task clone until
verified origin landing and safe cleanup. No deployed payload was changed.

Initial publication: normal documentation pre-push gate passed in 68 seconds at
`7dbdb7e8122424d60f9c32e6106e18d358afee16`, no bypass. PR #1009 targets development;
source digest unchanged. Hosted checks must be inspected on the final PR head.
This receipt/status commit does not change the reviewed skill or catalog.
