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
**Verdict:** Changes requested

1. **Diagnosis is incorrect:** The builder's isolated worktree IS in fact cut from the target root, not the harness clone. `relay-drive.py` exports `RELAY_TARGET_ROOT="$TARGET_ROOT"` (line 120 / 254). `relay-turn-lib.sh`'s `rtl_init` explicitly overrides `$1` with this variable: `RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"`. Then `rtl_worktree_begin` runs `git -C "$RTL_ROOT" worktree add ...`, which correctly cuts the worktree from the target repo. The real cause of the silent failure is likely that `utils/py/agy-turn.py` (and `agy-turn.sh`) resolves its internal `root` variable to the harness clone (because `AGY_TURN_ROOT` is not exported by `marathon-drive.sh`), which causes it to pass an absolute `f_rel` path to the agent. The agent then likely resolves the relative artifact paths against the absolute relay file's directory (`TARGET_ROOT/marathon-system/...`) rather than its `wt` CWD, finding nothing.

2. **Unimplementable preflight:** Plan item 1 is unimplementable as described. The builder's effective working directory is a throwaway worktree created dynamically inside the turn by `rtl_worktree_begin` (using `mktemp -d .../rtl-wt.XXXXXX`). It does not exist at preflight time before dispatch, so you cannot resolve it "the same way the turn shim will".

3. **Wrong assertion:** "Artifact paths must exist" will produce false refusals for any phase designed to create new files. The correct assertion would be that the artifact path's parent directory exists and is writable, or simply that the path resides within the bounds of the target repository.

4. **Unsafe escalation:** Escalating after two consecutive no-op builder turns is unsafe. A builder might legitimately produce no tracked changes if it is asking a clarifying question, reporting findings without writing code, or if the lane is already satisfied but the reviewer hasn't approved it yet.

5. **Insufficient block counting:** Counting builder blocks is a poor proxy for "the builder could not act." A builder can append a block (e.g., "I couldn't find the file") without making tracked changes, or it could fail to append a block due to formatting errors even when it did act.

6. **Cosmetic churn:** Splitting the "preflight" label (plan item 4) is cosmetic churn. "Preflight" is an appropriate umbrella term for all checks running prior to dispatch; renaming them adds no operational value.

7. **Missing context:** The plan completely overlooks the `f_rel` path resolution in `agy-turn.py`. Because `rtl.root` is the harness clone, `f_rel` becomes absolute, breaking the target-root abstraction for the prompt. It also overlooks the `RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"` assignment which invalidates the foundational claim of the plan.
