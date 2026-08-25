---
title: pre-push gate push double-applies through ref lock — retry reports own success as remote rejection
status: Proposed (1-INBOX — not yet active)
created: 2026-08-24
owner: noel
gh_issue: 223
source: https://github.com/HiQS-Labs/XYZ-forge/issues/223
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
release: 0.9.0 Cargo (dialed in 2026-08-24 — next build after Bulkhead, operator call)
non_goals:
  - Changing gate policy, width, or duration (the long window is a trigger, not the defect)
  - General push-retry infrastructure
goal: >
  A gate-green push either succeeds silently or fails truthfully: the double-send is diagnosed
  (git retry vs hook re-entry) and either eliminated or detected-and-reported as "already landed",
  so no landed push ever presents as a rejection.
---

# GH-223 — pre-push gate push double-applies through ref lock

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward.

## Key concepts
- The rejection message names the pushed commit itself as the ref's current value — the signature
  that the push already applied and a second send is racing it.
- The ~6–10 min gate window between ref snapshot and send is the enabling condition; the redirect
  through the renamed org was ruled out as sole cause (recurred after remote repoint).
- Cheapest acceptable fix may be detection, not prevention: post-rejection, compare
  `origin/<branch>` to HEAD and report "already landed" with exit 0.

## Idea
pre-push gate push double-applies through ref lock — second attempt reports own success as remote rejection

## Why
Two of ~10 gated pushes on 2026-08-24 (d5934cee, f404fd2b) exited 1 with a `cannot lock ref`
rejection after a green gate, while the ref had in fact landed — each one costs a full
re-verification cycle and reads as a failed push in logs and session transcripts. A harness whose
push boundary sometimes lies about success trains operators to distrust real failures.
TODO(operator): confirm whether the driving terminal's git version/credential helper retries
pushes after long-running hooks.

## Phase 0 — Explore & scope
> Discovery phase: its findings are written back into this doc before its QA gate can pass.

### Checklist
- [ ] Ground the idea in the real code/trace it touches (git trace of a gated push; hook path audit)
- [ ] Name the concrete deliverable + its write-set (needed before it can be a marathon lane)
- [ ] Decide the tool shape — reuse an existing command/script before new infrastructure (/ponytail)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires
