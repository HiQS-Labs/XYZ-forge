---
title: "Software Factory: evaluate existing OSS candidates (umbrella)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-29
updated: 2026-10-29
owner: noelsaw1
gh_issue: 1252
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1252
doc_type: research
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Adopting, vendoring, installing or running any candidate
  - Changing Jog, Marathon or admission behaviour
  - Building the factory reconciler (that is GH-1175 Phase 1)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1175
  - https://github.com/HiQS-Labs/XYZ-forge/pull/1225
  - https://github.com/HiQS-Labs/XYZ-forge/issues/522
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1188
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1213
  - https://github.com/noelsaw1/cloudroom-fork/issues/1
goal: >
  For each factory layer (intake, execution, review, landing, remote host), record whether to
  reuse an existing open-source project, borrow its ideas, or build it in XYZ. Base each call on
  candidate evaluations against fixed requirements, and record the operator's decision.
---

## Key concepts

- Requirements first, candidates second
- Jog and Marathon stay the only authorities
- Landing and intake bottlenecks weigh most
- One comment per candidate on the issue

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# GH-1252 — Software Factory: evaluate existing OSS candidates

## Status

| What was just completed | What's next |
|---|---|
| Umbrella issue filed with goals and requirements. First candidate (Cloudroom) evaluated in [this comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1252#issuecomment-6502207320): not a fit as a target, maybe a Phase R host later. Ratings are provisional. | Evaluate at least two more candidates against the requirements, then write a recommendation per layer for operator decision. |

## Idea

The factory flywheel (#1175) needs intake, execution, review, landing and, eventually, a remote host. Some of those may already exist in open-source projects. Evaluate candidates against fixed requirements before building more in XYZ, so we neither rebuild what exists nor adopt something that becomes a second authority over Jog or Marathon.

The requirements, evaluation rubric, candidates table and done criteria are in the issue body: https://github.com/HiQS-Labs/XYZ-forge/issues/1252. That issue is the source of truth; this doc tracks status.

## Why

The Phase 0 spike (#1225) showed that landing stalls first, then intake becomes the bottleneck. A candidate's value depends mostly on whether it helps those two layers, not on how fast it runs agents.

## Candidates so far

| Candidate | Role considered | Verdict |
|---|---|---|
| Cloudroom (`noelsaw1/cloudroom-fork@f97dd137`) | Target or Phase R host | Not a fit as a target. The public repo is a release mirror, issues were off, there's no XYZ governance, and the core tests are Linux-only and need sudo. Maybe a Phase R host later. |

## Done

- At least three candidates evaluated.
- A recommendation per layer: reuse X, borrow ideas from X, or build it in XYZ.
- Operator decision recorded. Follow-up issues filed only once that decision is made.
