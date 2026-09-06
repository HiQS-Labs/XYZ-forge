---
gh_issue: 471
source: https://github.com/HiQS-Labs/XYZ-forge/issues/471
title: "feat(skill): add a preservation gate to workhorse for irreversible operations"
status: Complete
created: 2026-09-06
updated: 2026-09-06
owner: Codex
goal: make workhorse fail closed on destructive operations until target-specific evidence proves every relevant state carrier is preserved
doc_type: feedback
effort: 1
complexity: 2
risk: 3
phases: 1
---

# GH-471: Workhorse Preservation Gate

## Status

| What was just completed | What's next |
|---|---|
| Six-rung workhorse implemented with preservation proof, bounded per-target recon, and destructive fast-track refusal; two-model behavioral check blocked all four unsafe scenarios | Land the explicitly authorized hotfix directly on `development`, then close GH-471 after remote verification |

## Problem

`/workhorse` classifies fast-track work by mechanical simplicity but has no separate gate for
irreversible actions. Its diagnostics inspect why something fails, while its final rung verifies a
change after execution; neither asks what pre-mutation evidence would prove that deleting or
retiring state loses nothing.

The abandoned-clone triage exposed five concrete misses:

- inventory stopped at the checked-out branch instead of covering every state carrier;
- ambiguous stale clone folders were not routed through a bounded `/recon` per candidate;
- a commit not being an ancestor of the destination was treated as evidence its content was absent;
- patch comparison stood in for the artifact even though line provenance was the relevant proof;
- a simple deletion could use the trivial-work fast track despite being unrecoverable.

## Design

Turn the five-rung ladder into six by inserting a **Preservation & Irreversibility Gate** immediately
before execution. Complexity and reversibility are independent axes. Every operation gets a
reversibility classification; Easy work records one line, while Costly and One-way-door operations
must pass the full gate.

For a set of stale folders, inventory each candidate separately. If a candidate's origin, purpose,
or relationship to the canonical destination is not already proven, run a bounded `/recon` for that
candidate and retain its map as part of the preservation record. For repository retirement, the
inventory includes dirty, untracked, and relevant ignored files; every ref namespace and reflog;
stashes and unreachable objects; worktree registrations; nested repositories/submodules and
local-only object stores where applicable; remotes and PR state; hooks/config; and active processes
or sessions. `checked`, `not applicable`, and `unknown` are explicit outcomes; any unknown blocks
mutation.

The preservation invariant must decide which question matters:

- ancestry proves graph reachability;
- patch equivalence proves change-set similarity;
- content or semantic evidence proves bytes or behavior;
- provenance evidence proves origin and attribution.

None substitutes for another unless it answers the invariant. Evidence is bound to the resolved
target and current state, then rerun immediately before mutation. A change in target identity, refs,
worktrees, processes, or evidence invalidates the proof.

Costly operations require a tested rollback. A true one-way door has none: before it may proceed,
state the exact permanent loss, residual uncertainty, and resolved target, then obtain fresh,
operation-specific operator confirmation. A general unattended-work authorization is not enough.
Specialized handoffs such as `/merge-cleanup` supply domain procedures, but workhorse must reject a
handoff report that omits a declared carrier or preservation claim.

## Consult reconciliation

- **Agreement:** both advisors accepted the diagnosis and the fast-track change.
- **Disagreement:** Codex supported a distinct rung; Agy preferred folding the invariant into
  governance. Keep the rung: the observed run already passed generic governance, and preservation
  needs its own pre-mutation deliverable.
- **Adopted:** target/evidence freshness, explicit claim/evidence vocabulary, proportional rigor,
  complete handoff reports, and behavioral red controls.
- **Declined:** a general unattended-automation bypass. It conflicts with the repository's explicit
  confirmation rule for one-way doors; prior authorization counts only when it names the exact
  target and permanent consequence.

## Acceptance criteria

1. Add a dedicated preservation/irreversibility rung before execution.
2. Permit fast-track only when work is both trivial/mechanical and Easy to reverse.
3. Require bounded `/recon` per ambiguous stale clone/folder before disposition.
4. Require target-bound, fresh inventory and claim-matched preservation evidence.
5. Name the non-ancestry and diff-versus-provenance traps explicitly.
6. Require tested rollback for Costly actions and fresh target-specific confirmation for one-way doors.
7. Include preservation proof in the completion report.
8. Record the real pre-change failure as the red control and evaluate post-change behavior against:
   trivial/Easy versus trivial/one-way fast-track prompts; a clean `HEAD` with a hidden local ref or
   stash; a cherry-picked/non-ancestor commit with equivalent content; and evidence invalidated by a
   last-minute ref change.
9. Pass the skill validator and relevant PDDA checks.

## Verification results

- `quick_validate.py skills/workhorse`: valid.
- PDDA frontmatter, status-table, and roadmap-coverage checks: zero errors.
- `releases_app.py check`: passed.
- `git diff --check`: passed.
- Codex+Agy post-change behavior check: both refused mutation in all four scenarios and cited the
  controlling lines. Transcript: `relay-system/2026-09-06/gh471-behavior-160132/`.
- Witnessed red control: the operator's 2026-09-06 abandoned-clone workhorse session required
  follow-up research after checking incomplete state and reasoning from ancestry/diff evidence.

## Lessons Learned

1. Mechanical simplicity cannot lower the reversibility floor; the axes must be classified
   independently.
2. Stale folders are individual historical systems. When their relationship to canonical state is
   ambiguous, `/recon` is the default investigation, not an optional escalation after a weak guess.
3. Preservation is a claim/evidence problem: ancestry, patches, content, and provenance answer
   different questions.
4. A cleanup skill can own mechanics without owning the outer proof. Workhorse remains responsible
   for rejecting incomplete evidence before an irreversible operation.
