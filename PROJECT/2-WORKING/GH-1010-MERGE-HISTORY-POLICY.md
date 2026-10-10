---
title: "GH-1010 — Per-project merge history policy"
status: In progress
created: 2026-10-09
updated: 2026-10-10
owner: Codex
goal: Let maintainers preserve original commit history across cleanup workflows.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1010
branch: feat/gh1010-merge-history-policy
reversibility: Easy — disable the policy for future merges; never rewrite prior history.
effort: 2
complexity: 2
risk: 2
phases: 2
---

# GH-1010 — Per-project merge history policy

## Status

| What was just completed | What's next |
|---|---|
| Final QA Approved; full gate 409/409; PR [#1019](https://github.com/HiQS-Labs/XYZ-forge/pull/1019) open | Await merge; retain clone for merge-cleanup handoff |

## Table of contents

- [Phase 1: Policy and consumer implementation](#phase-1-policy-and-consumer-implementation)
- [Phase 2: Verification and ready PR](#phase-2-verification-and-ready-pr)

## Observed behavior and scope

Base `ecec5561`. [Recon map](../1-INBOX/GH-1010-MERGE-HISTORY-RECON.md) records actual entry points.
Cleanup already has `--strategy squash|merge|rebase`, defaults to squash, and one GitHub merge
writer. Deep audit distinguishes ancestry from content but does not carry project policy.
Vendoring installs into an existing directory and has no repository-creation flow. Its skill
owns optional adoption decisions; the shell installer remains noninteractive.

Bet: original commit SHAs/ancestry are valuable to projects that choose this flag. The tradeoff
is noisier Git history and refusal where merge commits are disabled. The setting is not a
promise to preserve commits that builders already rebased before the merge.

## Requirements and decisions

- Maintainer-owned, tracked `<primary>/.merge-cleanup.json`: `{"preserve_commit_history": true}`.
  One strict boolean; missing file or missing key means false. Invalid JSON/type/unreadable file
  refuses rather than silently discarding an intended policy. Unknown keys rejected to catch typos.
- Omitted `--strategy` resolves to merge when opted in, squash otherwise (backward compatibility,
  not automatic inference of GitHub conventions). Explicit squash/rebase refuses when enabled;
  explicit merge works; opted-out projects retain all three explicit choices.
- Keep one reader/resolver in `merge_cleanup.py`. A `--show-merge-policy` read-only JSON mode
  exposes source, boolean, and effective method to deep audit without scanning, fetching or writing.
- Resolve/report before Phase 0 (and instruct callers to check before doc parking); re-resolve at `land_prs` entry and
  `execute_pr_merge`, so direct callers and policy changes after a landing cannot bypass it.
  Preflight GitHub's `mergeCommitAllowed` when enabled before landing work, and recheck at the
  merge writer. Failure/unavailable method stops; never mutate hosting settings or choose fallback.
  Existing GitHub ruleset errors remain ordinary merge refusals.
- Update merge-cleanup instructions/preview to use selected method. Deep skill and its agent
  template use the shared reporter, name original-commit ancestry separately from content, and
  carry policy into PR/teardown handoff. Historical squash remains valid evidence under existing
  checks; missing ancestry alone does not classify old work as missing or a policy violation.
- Vendor-stack offers preservation as a recommendation for a new project's maintainer; existing
  settings are kept, absence never automatically enables it. Write only with maintainer selection.
  XYZ Forge opts in through its own root file. No installer copies that file into target projects.

## Blast radius, rollback and non-goals

Easy: existing cleanup strategy selection, both skill instructions, vendor-stack guidance, Forge
policy input. Shield is explicit per-project opt-in; tripwire is a named policy/method error before
landing. Disable/remove the flag to restore future behavior; history is never rewritten.
No changes to scanner teardown eligibility, legacy squash provenance, reconciliation, PRS schema,
relay kernel, hosting settings, global skill deployment, repository creation, or Git cleanup.
Use debug-mantra if an execution defect needs diagnosis. No new tests, suites, runners, telemetry
stages, generic configuration framework, or speculative enterprise safeguards (current AGENTS).

## Rating rationale (2026-10-09 UTC)

PRS read-back `rated 65/55/50/75`, no operator override. Priority 65: requested audit-fidelity
improvement. Severity 55: loss of commit linkage, not observed source-content loss. Appeal 50:
neutral, no numeric user preference. Cheapness 75: one existing merge seam plus instructions.
Issue search examined 2026-09-25–2026-10-09 vs 2026-09-11–2026-09-24: zero directly reported
no-squash-policy incidents found in either window; #736 and #565 are related ancestry/merge
background, not evidence of the same defect recurring. Search coverage is titles/bodies, not all
comments; trend unknown, not a claimed increasing incident rate.

## Phase 1: Policy and consumer implementation

**Goal:** One per-project policy governs both cleanup workflows.

1. Add strict policy resolution and read-only JSON report to the existing orchestrator; change
   argparse default to None to distinguish omission from explicit squash. → manual fixtures prove
   missing/false/true/invalid input and explicit method combinations.
2. Resolve before mutation, enforce at landing and merge boundaries, preflight enabled merge
   capability, and preserve error propagation. → mocked GitHub calls prove no merge/repair/teardown
   on policy refusal; merge request uses `--merge` and no fallback on hosting refusal.
3. Update cleanup/deep/template/vendor-stack docs and add Forge opt-in. → deep reporter consumes
   the target primary, not the harness source; vendoring no-policy project stays unconfigured.

### Phase 1 QA

- [x] Codex plan review Approved before production edits; `relay-system/2026-10-09/gh1010-plan.codex.md` (exit 0).
- [x] Manual policy matrix and negative-control evidence retained in `TESTS-RESULTS/2026-10-09+GH-1010/`.
- [x] Original provenance and teardown safety unchanged; docs describe legacy default honestly.

## Phase 2: Verification and ready PR

**Goal:** Reviewed implementation with attributable checks and a development PR.

4. Run existing `gh436-merge-cleanup` focused suite plus policy probes in a disposable full clone;
   record nonempty output, exit codes, identity before/after, and a red control removing enforcement
   (restore from a file copy). → existing behavior remains green and weakened enforcement fails.
5. Commit evidence and final implementation; run Codex final relay QA, at most three rounds with
   scoped fixes; then one full final gate in a separate disposable clone. → Approved and green,
   or explicit blocker. No new suite registrations; current no-new-tests policy governs.
6. Push through existing pre-push checks from a disposable clone, open and inspect the PR to
   development, and retain task clone for merge-cleanup handoff. → exact head/base/scope verified;
   no merge or teardown in this task.

### Phase 2 QA

- [x] Focused suite (180 tests), manual probes and red control have committed provenance.
- [x] Final independent Codex review Approved; applicable gates passed on attributable code.
- [x] PR ready, issue still open, clone retained; no claim of shipped before merge.

## Review and integration notes

2026-10-10: Final QA round 1 returned F1 (two stale unconditional squash instructions).
Disposition: Implemented; Phase 5 now names the resolver-owned writer and continuation wording
is method-neutral. Runtime and focused evidence unchanged. Integrated `9a923f3c` development;
only changelog and ledger conflicted. Both changelog entries retained; existing ledger resolver
kept generation 1564 and replayed GH-1010 through roadmap add/rate/update, retaining 65/55/50/75.
No hand-edited SQL. Round 2 reviews these corrections and current-base integration.

Final review: round 2 returned PASS text but exit 4 close-mismatch (reviewer released rather than
closed token); not accepted as approval. Round 3 closed correctly, Approved and attested (exit 0).
Routine generated leaderboard changes excluded per AGENTS. No production code changed after
`aa479b18`; final review includes integrated base and F1 doc corrections. Full gate next.

Publication: [PR #1019](https://github.com/HiQS-Labs/XYZ-forge/pull/1019) targets `development`, non-draft and mergeable at initial inspection. Full pre-push gate on `a0547ec1` passed 409/409 in 909s, without bypass; Git identity unchanged and status clean. One process-group permission error passed the built-in isolated retry; original log retained and cause unconfirmed. Evidence/status-only follow-up commits use the normal documentation gate. Hosted checks are verified separately on the final PR head; this is not promotion evidence.

Retained task clone: `/Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-merge-history-policy`. Retire via `/merge-cleanup` only after landings are verified. Issue remains open; nothing merged, deployed, or removed.
