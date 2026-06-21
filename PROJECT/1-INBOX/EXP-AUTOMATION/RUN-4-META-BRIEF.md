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
agent works them **sequentially** (the loop holds one claim at a time; the
in-half overlap blocks a 2nd same-half claim). The two halves are **disjoint**
(`src`/`test`/`validate.sh` vs `relay-automation/`), so the two agents run
**concurrently** and never collide.

**Balance is contingent on launch-sync — not automatic (important).** `take`
picks by **global** priority and the own-overlap exclusion only blocks *same-half*
second claims; cross-half claims never overlap. So if one agent finishes A1
*before the other has claimed anything*, its next `take` prefers **B1 (pri 10)
over A2 (pri 8)** and crosses into the Automation half → a 3-1 split that breaks
the "both agents ≥ 2 done" bar (this is exactly Run 3's imbalance). Half-ownership
only locks in when **both** first-claims (A1 *and* B1) land before either calls
`done`. Hence the launch-sync guard (#6). *(Footnote: the thing this run builds —
Phase-1 handoff-exclusive claims — is what would make ownership automatic; until
it ships, launch-sync is the manual stand-in.)*

## Runtime context (for the window that executes this)
Captured 2026-06-14 ~15:15 PDT — verify before launch, these can drift:
- **Repo / branch:** `Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`, `main` @ `a10fcdf` (plus untracked `snapshot.md` — personal recovery file, ignore).
- **`tick` is runnable** at `./bin/tick` (no install); `.tick/` does **not exist yet** → `tick init` only, **no archive needed**. `relay-automation/` confirmed **absent** → `mkdir` it (lane B's home).
- **Baseline:** `validate.sh` = **12 tests** today; acceptance for Project 2 is **≥13** (the new `handoff-exclusive.sh`).
- **Roles in the *run* (not this relay):** the window executing this brief is the **coordinator/observer** (does not claim/code — see `skill/xyz/SKILL.md` §7). The **two build agents are separate windows** (e.g. Codex + Gemini); confirm which two with the operator before pasting prompts.
- **Agent loop to paste:** the `xyz` build loop (mantra → `tick take` → work in-lane → `tick ping` → file-scoped `git add` + `[<agent>] <TASK> …` commit → `tick done` → repeat).
- **Measure at wrap-up:** work-bounded concurrency by hand from `.tick/events/` (first `claimed` → last `done`); `tick analyze` for the parked-suspects line only.

## Coordinator setup (paths are repo-root-relative)
```bash
TICK=./bin/tick
$TICK init   # .tick/ is absent today → just init. (If a prior run ever left events, archive to .tick/archive/run-4/ first.)
$TICK log task.created TASK-A1 --agent dispatcher --priority 10 --paths "src/claim.js,src/take.js,src/**,test/**,validate.sh"
$TICK log task.created TASK-A2 --agent dispatcher --priority 8  --paths "src/claim.js,src/take.js,src/**,test/**,validate.sh"
$TICK log task.created TASK-B1 --agent dispatcher --priority 10 --paths "relay-automation/**"
$TICK log task.created TASK-B2 --agent dispatcher --priority 8  --paths "relay-automation/**"
mkdir -p relay-automation   # lane B's empty home so the first commit has somewhere to land
```
Then paste the standard `xyz` agent loop (mantra → `tick take` → work → `tick ping` → file-scoped `git add` + tagged commit → `tick done` → repeat) into **two** windows, same session, shared tree.

## Dual acceptance (both cheap to measure at wrap-up)
- **Project 2 (relay automation):** TASK-A1+A2 → `validate.sh` green **incl. the new `handoff-exclusive.sh`** (≥ 13/13); the `tick` rule provably rejects a wrong-`handoff_to` claim with zero events. TASK-B1+B2 → both skeletons exist and pass `bash -n relay-automation/runner.sh && bash -n relay-automation/watchdog.sh`, with documented stubs.
- **Project 1 (Run 4 concurrency):** from `.tick/events/`, the **work-bounded** concurrent-claim time (first `claimed` → last `done`) — record the %. Pass target ≥ 50%; **any number is a valid datapoint** vs Run 3's 40%. Both agents ≥ 2 done; parked-suspects = none; no serial double-claim.

## Rabbit-hole guards (non-negotiable)
1. **One slice only** — Phase 1 core + two *skeletons*. Do **not** flesh out Phases 2–5 (watchdog policy depth, full runner, /loop wiring) in this session.
2. **Hard 60-min box** — box expires → stop and measure, whatever the state.
3. **Sub-50% is a result, not a retry trigger** — record it; do **not** re-tune lanes or re-run in-session.
4. **Lanes are pre-split here** — agents don't renegotiate scope mid-run.
5. **Wrong-window guard active** — the updated `/relay` identity rule + one-window-at-a-time apply; coordinator nudges one window at a time.
6. **Launch-sync (forces the balanced split)** — start both build windows together; **before either agent calls its first `tick done`, confirm `tick project` shows both A1 and B1 claimed (one per agent).** If one agent would finish task 1 while the other is still unclaimed, pause it — otherwise the free agent crosses lanes (global-priority `take`) and you get a 3-1 split that fails "both ≥ 2 done." This is the manual stand-in for the not-yet-built handoff-exclusive rule.

## Wrap-up (coordinator)
`tick analyze` (parked check) → compute work-bounded % by hand from `.tick/events/` → run `validate.sh` → record both acceptance results + the concurrency datapoint in `REAL-AGENT-OBSERVATIONS.md` (Run 4 section) and `RECAP.md`. Then stop — decide graduate/iterate from the data, out of session.

> **Running `validate.sh`:** it needs a writable `$TMPDIR` — each test's `test/_setup.sh` does `mktemp -d`. If tmp is blocked you get a spurious **`0/12` with `EPERM mkdir`** and paths collapsing to `/agent-a` etc. — that means the env blocked tmp, **not** a regression. Re-run with a writable `$TMPDIR` (outside the command sandbox if needed) before trusting the count.
