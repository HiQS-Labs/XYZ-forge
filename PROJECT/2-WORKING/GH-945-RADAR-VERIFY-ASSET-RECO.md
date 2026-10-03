---
gh_issue: 945
source: https://github.com/HiQS-Labs/XYZ-forge/issues/945
title: "radar: recommend the repo's own verification assets (harness/fuzzer) for recurring-defect clusters"
status: In Progress
created: 2026-10-02
updated: 2026-10-02
owner: operator
goal: "Radar's coaching names the verification asset a recurring cluster deserves — conditionally, cited, recommendation-only."
complexity: 1
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Implementation committed (12d9a9c1); codex Round-1 review: one [Should] (doc lifecycle) accepted and fixed — promoted to 2-WORKING, ledger repointed. | Codex Round-2 re-review; push + PR against development. |

## Plan (surgical)

Body-only addition to `skills/3-weekly/radar/SKILL.md`, inserted after the existing
"Sibling: sanity-check for a disputed blocker" section and before `## Boundaries`: a
sibling-style section — detect the repo's automated verification assets (fuzzers,
property-based suites, dedicated fuzz/soak targets, registered gate entry points) when Lens 2
produces a mechanically-checkable recurring cluster or regression target; add a **Verify with**
line recommending run-or-extend; cite the detection (`Cite or drop`); silent when no target or
no asset; never executes; no reciprocal pointer.

- **Non-goals:** no frontmatter change (PR #943 owns radar's description trim; body-only keeps
  the PRs conflict-free), no new tests (GH-831), no harness execution or gating, no PAGES change
  (self-heals via hosted pages build).
- **Verification:** gh779 pinned strings intact (grep); frontmatter byte-identical to base
  (`git diff` confined to body); independent relay QA approves (Step 8).
- **Rollback:** revert the single commit.

## Rating rationale (2026-10-02)

`rated 55/35/50/85` — pri 55: operator-requested coaching improvement, no deadline pressure;
sev 35: enhancement with no observed defect (a missed recommendation, not a failure); appeal 50:
neutral default, no explicit user score; effort 85: doc-only quick win. No recurrence window
applies (new capability, not an incident class). No operator `ovr`.

## QA ladder decision

Plan QA (Step 6) skipped as a **simple change**: obvious, local, single-file, reversible,
design already adjudicated with the operator in-session (constraints recorded above). Final
relay QA (Step 8) still applies before the PR.

## Deployment note

Do NOT re-vendor radar from this clone while PR #943 is unmerged — this base still carries the
pre-trim 1336-char description. Deployed copy catches up after #943 lands (then re-vendor from
a tree containing both).
