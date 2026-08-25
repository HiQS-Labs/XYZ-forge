---
title: "GH-233: AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter"
status: Active
created: 2026-08-25
updated: 2026-08-25
owner: orchestrator (Claude Code)
goal: implement Phase 2 lifecycle verbs, operator-mediated invite, atomic supersession, watch invalidation, concurrency stress testing, and citation verification linter
gh_issue: 233
source: https://github.com/HiQS-Labs/XYZ-forge/issues/233
branch: feat/gh233-agent-chorus-phase2
doc_type: feature
effort: 3
complexity: 3
risk: 2
release: 0.7.4 Linux-RC (dialed in 2026-08-25, mfi-01M0X6J8GK1YCV40594Z4VCT25)
related:
  - "#193 — AgentChorus Gen 2 umbrella"
  - "#200 — Phase 1 telemetry & registry baseline"
---

# GH-233 — AgentChorus Gen 2 Phase 2

## Status

| What was just completed | What's next |
|---|---|
| Issue #233 filed; dialed into 0.7.4 Linux-RC | Implement lifecycle verbs, watch invalidation, concurrency suite, and verify-citations linter |

## Scope & Deliverables

1. **Roster-Guardrail Reconciliation (`invite --agent N`)**:
   - Operator-mediated roster widening recorded as a scope extension.
   - Atomically updates relay state and `AGENTS:` header.
   - Disallowed after discussion close or supersession.
   - Amend `skills/agent-chorus/SKILL.md` invariant rule in the same commit.

2. **Atomic Supersession Verbs (`start --supersedes <old_id>`)**:
   - Closes old discussion atomically with successor pointer before new discussion accepts its first turn.
   - `join` and `watch` on superseded IDs return `DECISION: closed` + successor pointer.

3. **Watch & Doorbell Invalidation**:
   - Terminal signals / invalidation for old watches (`runtime/*.watch`) on supersession or roster change.
   - Guarantees no orphaned process can ever write into a superseded discussion.

4. **Dedicated Concurrency & Race-Condition Suite**:
   - Multi-agent stress testing: start 2 seats -> widen to 3; assert exactly one `NEXT:` owner; zero forked transcripts; old watches never fire; supersession ordering under racing joins.
   - Fuzzing `conversation.md` turn grammar and `runtime/discussion.lock` mutex under concurrent write contention.

5. **Citation Verification Linter (`verify-citations`)**:
   - Read-only linter with git ref-pinning (`{sha, resolvable}`).
   - Distinguishes drift from hallucinations, broken down by agent.

## Acceptance Criteria

- [ ] Dedicated concurrency suite passing green in gate.
- [ ] Live supersession exercised cleanly with zero orphaned doorbells or forked transcripts.
- [ ] `verify-citations` baseline recorded over pilot corpus.
- [ ] `skills/agent-chorus/SKILL.md` rules reconciled.
- [ ] Full gate pass.
