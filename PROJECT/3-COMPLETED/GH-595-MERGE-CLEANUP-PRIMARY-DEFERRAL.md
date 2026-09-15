---
gh_issue: 595
source: https://github.com/HiQS-Labs/XYZ-forge/issues/595
title: "merge-cleanup requires operator-owned primary-checkout deferral"
status: Complete
created: 2026-09-12
updated: 2026-09-15
owner: Codex
doc_type: bugfix
goal: >
  Prevent an executing merge-cleanup run from reporting completion while its primary checkout
  remains unready unless the operator explicitly defers that cleanup.
effort: 1
complexity: 1
risk: 2
phases: 1
ratings_provisional: false
---

# GH-595 — merge-cleanup primary-checkout deferral

## Status

| What was just completed | What's next |
|---|---|
| Hoisted the existing readiness refusal into the universal mutation path and pinned zero-PR, teardown-only, explicit-deferral, ready-primary, and reporting-mode controls. The full merge-cleanup suite passes 142/142; PDDA and releases checks have zero errors. | Commit, run the routed pre-push gate, and open the PR. |

## Contract

The primary checkout is part of cleanup. An executing run must refuse before any merge, teardown,
or symlink mutation when the primary is unready, unless the operator explicitly supplies the
existing `--allow-unready-primary` deferral. Dry-run, `--scan-only`, and `--prs-only` remain
reporting modes and do not require the override.

## Evidence and scope

- Current failure: `main()` gates primary readiness only inside the nonempty-PR merge condition.
- Deterministic repro: unready primary + `--execute` + no PRs returns 0 and prints completion.
- Minimal seam: reuse `_primary_blocks`; no new state, dependency, repair routine, or prompt.
- Consult: Codex independently agreed on the shared pre-mutation gate and non-vacuous tests. The
  Agy lane returned an empty transcript and is treated as degraded, not consensus.

## Acceptance

- [x] Zero-PR `--execute` refuses an unready primary before teardown/pruning.
- [x] `--teardown-only --execute` refuses an unready primary before teardown/pruning.
- [x] `--allow-unready-primary` is the explicit operator deferral for both paths.
- [x] Read-only modes and ready-primary execution retain their behavior.
- [x] The source skill and deployed copy are synchronized through Skills Army HQ.
- [ ] Focused tests, PDDA checks, and the repository validation gate pass.

## Lessons Learned (For Future Agents)

- Landed as PR #596 (squash `7059ec32`) after a CHANGELOG + ledger conflict against `development`;
  the ledger row was replayed through the writer rather than merged textually (merge-cleanup Phase C,
  attempt 2/2 for the PR).
- The gate this PR adds refuses an unready primary *before* mutation. The same landing exposed the
  opposite gap: merge-cleanup's own `pr_merged` work-emit dirties a READY primary before its
  fast-forward (#624), so "ready at Phase 0" is not "ready at fast-forward" until that is fixed.
- Hosted wave-reconcile could not land this reconciliation (development's suite red on #619/#625);
  it was run locally with `--force-local-reconcile` after cancelling the in-flight hosted run.
