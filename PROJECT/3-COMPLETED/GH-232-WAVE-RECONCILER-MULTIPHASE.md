---
title: "GH-232: wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs"
status: Complete
created: 2026-08-25
updated: 2026-08-26
owner: orchestrator (Claude Code)
goal: prevent premature promotion of active docs from PROJECT/2-WORKING/ to PROJECT/3-COMPLETED/ when linked GitHub issues remain open across multi-phase PR merges
gh_issue: 232
source: https://github.com/HiQS-Labs/XYZ-forge/issues/232
branch: feat/gh232-wave-reconcile-multiphase
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
release: 0.7.4 Linux-RC (dialed in 2026-08-25, mfi-01M0X6J84NNPGVS9EF26X3QQZ7)
related:
  - "#193 — AgentChorus Gen 2 umbrella (surfaced premature promotion friction during Phase 1 merge)"
  - "#202 — wave_reconciler state handling hotfix"
---

# GH-232 — Wave Reconciler Multi-Phase Issue Honor

## Status

| What was just completed | What's next |
|---|---|
| Issue #232 filed; dialed into 0.7.4 Linux-RC | Implement issue state inspection in wave_reconcile.py; add regression tests |

## Context & Problem Statement

When a PR merging a single phase of a multi-phase umbrella issue lands (e.g. PR #200 for Phase 1 of GH-193), `utils/py/wave_reconcile.py` automatically moves the corresponding active document from `PROJECT/2-WORKING/` to `PROJECT/3-COMPLETED/`. This is premature because subsequent phases (e.g. Phase 2, Phase 3) are still in progress under the same issue.

## Proposed Changes

1. **Issue State Inspection**: `wave_reconcile.py` checks linked GitHub issue state before executing doc promotion.
2. **Multi-Phase Active Preservation**: If the linked issue is still `OPEN`, keep the doc in `PROJECT/2-WORKING/`, append merged PR evidence into `## Merge evidence`, and log that doc promotion was deferred pending issue closure.
3. **Explicit Override**: Support `--force-promote` or honor frontmatter sentinels (`status: Active`, `umbrella: true`).

## Acceptance Criteria

- [ ] `wave_reconcile.py` does not move active docs whose linked GitHub issue is `OPEN`.
- [ ] Merge evidence is appended to the active doc in `PROJECT/2-WORKING/` without file relocation.
- [ ] Automated regression tests verify multi-phase umbrella preservation and closed-issue promotion.
- [ ] Full gate pass.

## Lessons Learned (For Future Agents)

- **Merge evidence is not completion evidence.** Phase 1 of an umbrella (#193) merged while the linked issue stayed OPEN, and promotion on merge evidence alone left PROJECT/ and the issue tracker disagreeing about whether the work was done. Promotion now requires the linked issue to be positively CLOSED.
- **A failed fact-check aborts; it never defaults to promote.** A transient `gh` failure (network, rate limit) during reconcile exits 6 instead of silently promoting — one bad network day must not mis-promote a whole wave of open issues (GH-202 review, Agy round-1 blocker).
- **Linked-issue extraction is mention-greedy.** Reconciling PR #247 (2026-08-26) failed live because prose citations to a foreign tracker (GH-368/375/492/551 — not issues in this repo) were extracted as linked issues. Sanctioned workaround: `--offline` with an `issues[]` manifest — unlisted numbers read as unknown (promote as before); only positively-OPEN suppresses promotion. Follow-up worth filing: distinguish closing keywords ("Closes/Resolves #N") from incidental mentions.
