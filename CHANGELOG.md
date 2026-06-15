# Changelog

All notable changes to this repo. Newest first. Dates are PDT.

## 2026-06-15

### relay-automation — Phase 4 complete (hands-free poll, Option B: baton + poll)
- **4a** `relay-automation/poll.sh` — per-tick poll driver: two modes (xyz/relay), split guard→dispatch (runner: my-turn+clean · watchdog: parked+designated-authority → no double-escalate), artifact-scoped clean-tree check, cross-model nudge, `--dry-run` + guarded live dispatch. `test/poll-driver.sh` 12/12.
- **4b** `relay-automation/relay-drive.sh` — relay-turn supervisor: loops a `/relay` Producer↔Reviewer thread to termination via the turn-taker (`--agent-cmd` seam), round cap + no-progress escalation (exit 3) + cap escalation (exit 4). `test/poll-relay.sh` 8/8.
- **4c** `relay-automation/README.md` — operator docs: `/loop` invocations, designated-watchdog poller, single-process supervision, cross-model one-line baton nudge, all-Claude boundary.
- `validate.sh`: 15 → **17 tests** (`poll-driver.sh`, `poll-relay.sh` added).
- Execution contract decided **Option B** (headless-CLI spike found no agent CLI present); Option A (unattended) documented as a future upgrade in `PHASE-2-PLAN.md`.
- Phase-4 plan relay-reviewed by Codex (2 Blockers + 1 Should applied): split guard, artifact-scoped clean check, two-mode poll, solo-lane build.

### Process
- Embedded a self-contained `▶ TAKE YOUR TURN` block into relay docs **and** the parent `/relay` skill (giant-brains repo) so cross-model relays are a one-line nudge.
- Graduate-to-Phase-2 decision recorded, then **Decided** after operator accepted the 39% concurrency datapoint (start-skew, not load imbalance — de-gated).
- Added this CHANGELOG; began keeping it + `RECAP.md` current per change.

## 2026-06-14

### Run 5 — Phase-2 build (watchdog ‖ runner), 2-Codex swarm
- `watchdog.sh` real structured JSON escalation; `runner.sh` verdict-gated turn loop with injectable `--agent-cmd`. Both lanes done, `validate.sh` 13 → 15.
- Work-bounded concurrency **39%** (start-skew, not load imbalance); recorded as a valid datapoint.

### Run 4 — meta-exercise (swarm builds relay-automation Phase 1)
- Handoff-exclusive `tick` rule (`src/claim.js`, `src/take.js`) + `test/handoff-exclusive.sh`; `runner.sh`/`watchdog.sh` skeletons. `validate.sh` 12 → 13.
- Work-bounded concurrency **72.2%** (cleared ≥50% bar); both acceptances green.
- Agent feedback folded in: build-prompt "initiative bound" (xyz skill), test-harness `TICK_REPO_ROOT=$A` default.

_Earlier history: see `RECAP.md` (Runs 1–3) and `REAL-AGENT-OBSERVATIONS.md`._
