---
title: Run 4 — meta-exercise brief (swarm builds the relay-automation slice)
status: Ready to launch (on operator go)
created: 2026-06-14
repo: Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm
serves: [Project 1 — xyz Run 4 load-balance, Project 2 — relay-automation Phase 1]
timebox: 60 min (hard)
---

# Run 4 — the meta-exercise

**One bounded swarm session that advances both projects.** Two agents build the
relay-automation's first slice (Project 2, Phase 1 + skeletons) in balanced,
non-overlapping lanes — and the act of building it **is** Run 4 for Project 1
(it answers "does a balanced fixture beat Run 3's 40% and clear ≥50%?"). The
balanced-fixture choice resolves Run 4's open load-balance fork *by construction*
(no separate tuning project).

## Why this fixture is balanced (and Run 3 wasn't)
Run 3 split HTTP (3 tasks) vs store (3 tasks); HTTP drained first → the fast
agent idled → 40%. Here the two halves are deliberately comparable in effort
(a fiddly code change + its test ≈ two real skeletons), so neither agent runs dry.

## Balanced lane split (4 tasks · 2 halves · disjoint paths)

| Task | Half / lane | Path scope (claim globs) | Pri | What it builds |
|---|---|---|---|---|
| TASK-A1 | **Enforcement** | `src/claim.js,src/take.js` ∪ half-scope `src/**,test/**,validate.sh` | 10 | `tick` rejects `claim`/`take` of a task whose `handoff_to` is set and ≠ caller; **zero events on rejection** (Phase-1 core change) |
| TASK-A2 | **Enforcement** | same half-scope | 8 | `test/handoff-exclusive.sh` + wire into `validate.sh` (proves the rule; suite still green) |
| TASK-B1 | **Automation** | `relay-automation/**` | 10 | `relay-automation/runner.sh` **skeleton** — claimability guard (open+handoff_to=me → claim; claimed+claimer=me → resume; else poll), artifact-scoped clean-tree gate, verdict grep, round cap (stubs OK) |
| TASK-B2 | **Automation** | `relay-automation/**` | 8 | `relay-automation/watchdog.sh` **skeleton** — `tick analyze` → parked detection → escalate-to-human (reap behind an authority flag; stub) |

**Mechanics:** tasks *within* a half share the half-scope, so they overlap → an
agent works them **sequentially** (take A1 → done → take A2), holding ≤1 active
claim at a time. The two halves are **disjoint** (`src`/`test`/`validate.sh` vs
`relay-automation/`), so the two agents run **concurrently** and never collide.
Whichever agent claims an A-task owns the Enforcement half; the other owns
Automation. Balance, not assignment, is what matters.

## Coordinator setup (paths are repo-root-relative)
```bash
TICK=./bin/tick
$TICK init   # after archiving any prior .tick/events to .tick/archive/run-4/
$TICK log task.created TASK-A1 --agent dispatcher --priority 10 --paths "src/claim.js,src/take.js,src/**,test/**,validate.sh"
$TICK log task.created TASK-A2 --agent dispatcher --priority 8  --paths "src/claim.js,src/take.js,src/**,test/**,validate.sh"
$TICK log task.created TASK-B1 --agent dispatcher --priority 10 --paths "relay-automation/**"
$TICK log task.created TASK-B2 --agent dispatcher --priority 8  --paths "relay-automation/**"
mkdir -p relay-automation   # lane B's empty home so the first commit has somewhere to land
```
Then paste the standard `xyz` agent loop (mantra → `tick take` → work → `tick ping` → file-scoped `git add` + tagged commit → `tick done` → repeat) into **two** windows, same session, shared tree.

## Dual acceptance (both cheap to measure at wrap-up)
- **Project 2 (relay automation):** TASK-A1+A2 → `validate.sh` green **incl. the new `handoff-exclusive.sh`** (≥ 13/13); the `tick` rule provably rejects a wrong-`handoff_to` claim with zero events. TASK-B1+B2 → both skeletons exist and parse/lint clean with documented stubs.
- **Project 1 (Run 4 concurrency):** from `.tick/events/`, the **work-bounded** concurrent-claim time (first `claimed` → last `done`) — record the %. Pass target ≥ 50%; **any number is a valid datapoint** vs Run 3's 40%. Both agents ≥ 2 done; parked-suspects = none; no serial double-claim.

## Rabbit-hole guards (non-negotiable)
1. **One slice only** — Phase 1 core + two *skeletons*. Do **not** flesh out Phases 2–5 (watchdog policy depth, full runner, /loop wiring) in this session.
2. **Hard 60-min box** — box expires → stop and measure, whatever the state.
3. **Sub-50% is a result, not a retry trigger** — record it; do **not** re-tune lanes or re-run in-session.
4. **Lanes are pre-split here** — agents don't renegotiate scope mid-run.
5. **Wrong-window guard active** — the updated `/relay` identity rule + one-window-at-a-time apply; coordinator nudges one window at a time.

## Wrap-up (coordinator)
`tick analyze` (parked check) → compute work-bounded % by hand from `.tick/events/` → run `validate.sh` → record both acceptance results + the concurrency datapoint in `REAL-AGENT-OBSERVATIONS.md` (Run 4 section) and `RECAP.md`. Then stop — decide graduate/iterate from the data, out of session.
