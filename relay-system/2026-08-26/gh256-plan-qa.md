---
Goal: QA the GH-256 remediation plan
Date: 2026-08-26
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the remediation plan in `PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md`
against the code it proposes to change. Plan review only — do not edit any file except this
relay thread.

Read in full:
- `PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md` (the plan)
- `relay-automation/marathon-drive.sh` — `preflight_pre_advance_gate()` (~line 703) and the
  surrounding dispatch path
- `relay-automation/relay-turn-lib.sh` — how the turn shim resolves its working directory and
  worktree
- `relay-automation/agy-turn.sh` — where "produced no tracked changes (token-only move?)" is
  emitted

Background, observed on a real 4-phase run with `--target-root <repo>` plus
`--phases-dir <repo>/marathon-system`, builder agy, reviewer codex: the builder's isolated
worktree was cut from the HARNESS clone, where the phase's relative artifact paths
(`src/rebalance/ingest/_http.py`, `tests/test_http_client.py`) do not exist. Four builder turns
produced no tracked changes and appended no builder block. The reviewer, given absolute paths,
read the correct files and filed accurate findings — so the transcript looks like a working
review loop. The phase ran to its round cap and escalated `cap-stalled` after 29 minutes with
zero lines of code written.

Questions:

1. **Is the diagnosis right?** Is the builder's worktree in fact cut from the harness root rather
   than the target root under `--target-root`? Cite the resolution site. If the real cause is
   something else, say so — the plan is built on this claim.

2. **Is the proposed preflight implementable as described?** Can the builder's effective working
   directory be resolved at preflight time, before dispatch, the same way the turn shim will
   resolve it? Or is the resolution only knowable inside the turn, which would make plan item 1
   unimplementable where it is proposed?

3. **Is "artifact paths must exist" the right assertion?** A phase may legitimately CREATE a file
   that does not exist yet. Would this check produce false refusals for a create-new-file phase,
   and if so what is the correct assertion instead?

4. **Is plan item 2 (escalate after two consecutive no-op builder turns) safe?** Is there a
   legitimate case where a builder produces no tracked changes twice and the phase should still
   continue — for example a lane already satisfied, or a builder that only needed to hand back?

5. **Is plan item 3 (record builder-block count in ESCALATION.md) sufficient to distinguish the
   two failures?** Or is counting blocks the wrong proxy for "the builder could not act"?

6. **Is plan item 4 (split the overloaded "preflight" name) worth doing, or is it churn?** Be
   blunt if it is cosmetic.

7. **What is missing?** Any other silent-no-op path in the dispatch chain the plan does not cover,
   or an interaction with worktree isolation the plan overlooks.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
file:line where you disagree with a specific claim. Do not soften a real objection.

Write your verdict below. Set `STATUS: Approved` if sound as written, or leave it Open with
`**Verdict:** Changes requested` and say exactly what must change.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
