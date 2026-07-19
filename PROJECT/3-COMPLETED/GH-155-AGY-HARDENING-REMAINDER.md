---
gh_issue: 155
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/155
title: "GH-142 follow-up: agy hardening S2/S5/S8 + controlled S10 repro (keep-gated remainder)"
status: Shipped 2026-07-17 by /10days (5f37954) — S2/S5/S8 regression tests landed; S10 stays open (could not re-trigger on demand per #142)
created: 2026-07-06
updated: 2026-07-17
owner: noel
doc_type: test-hardening
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not attempting S10 (off-prompt-nonempty repro) in this contract's gate — it was explicitly
    "could not re-trigger on demand" in #142 and needs a controlled repro before any assertion is
    added; land S2/S5/S8 now, track S10 as a stretch item, not a blocker.
  - Not changing agy's graduate/keep-gated status — this issue only adds regression coverage; the
    graduate call is a separate operator decision per #142's own text.
related:
  - test/agy-turn.sh
  - relay-automation/agy-turn.sh
  - PROJECT/2-WORKING/GH-142-AGY-RELIABILITY-TESTING.md
goal: >
  Add three regression tests to test/agy-turn.sh, following its existing S<N>: pass/fail label
  convention (see S9 cases): S2 role/model adherence (assert the acting model wrote its assigned
  role's block / flipped NEXT), S5 distraction (clean-workspace precondition + PATH-shadow, agy
  case), and S8 cost-blindness (assert the cost path reports "cost-blind", not a misleading 0).
roadmap_exempt: false
---

# GH-155 · agy hardening remainder — S2/S5/S8 regression tests

## Status

| What was just completed | What's next |
|---|---|
| **SHIPPED 2026-07-17 by `/10days`** (`5f37954`) — 3 new regression cases in `test/agy-turn.sh` (S2 role/model adherence, S5 distraction, S8 cost-blindness), 54/54 own tests (41 pre-existing + 13 new), full `validate.sh` 113/114 (only pre-existing unrelated `acorn-extract.sh` red). | S10 (off-prompt-nonempty repro) stays open per #142's own note that it "could not re-trigger on demand." |

Captured by the `/10days` 11-14 day sweep (2026-07-17). Split from
[GH-142-AGY-RELIABILITY-TESTING.md](GH-142-AGY-RELIABILITY-TESTING.md) at its Phase-3 close: #142
fixed the one confirmed live failure (S9/F8, `dcc1505`) and deferred the remaining characterization-
matrix gaps here as "separate later slices" — the reason agy stays keep-gated rather than graduated
to fully-unattended producer turns.

**Why filed:** confirmed via grep that `test/agy-turn.sh` had zero references to S2/S5/S8/S10 before
this fix — none of the four deferred cases had landed.

## Swarm Preflight Contract

> Scoped to the three concretely-specifiable cases (S2/S5/S8) — each is "add one regression test
> case," well-defined from #142's own characterization matrix. S10 stays a stretch item per the
> non_goals above; it does not gate this contract.

```json
{"target":{"repo":".","ref":"main"},"gate":"bash test/agy-turn.sh && bash validate.sh","fix_probes":[{"type":"grep_absent","path":"test/agy-turn.sh","pattern":"S2:"},{"type":"grep_absent","path":"test/agy-turn.sh","pattern":"S5:"},{"type":"grep_absent","path":"test/agy-turn.sh","pattern":"S8:"}],"artifacts":["test/agy-turn.sh"],"remediation":{"source":"issue#155","criteria":"test/agy-turn.sh gains three new regression cases following the existing pass \"S<N>: ...\" label convention: S2 (assert the acting model wrote its assigned role's block / flipped NEXT), S5 (clean-workspace precondition + PATH-shadow for agy specifically), and S8 (assert the cost path reports agy as cost-blind rather than a misleading exact 0); all existing test/agy-turn.sh cases stay green; validate.sh stays green."},"lanes":{"agy_safe":["test/agy-turn.sh"],"orchestrator_only":[]}}
```

*Contract auto-drafted by /10days from the issue text and #142's characterization matrix —
artifacts/lanes not yet operator-verified.*
