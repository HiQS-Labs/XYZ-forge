---
title: "GH-172 Bash audit findings"
status: completed
created: 2026-07-17
updated: 2026-07-17
owner: codex
goal: >
  Record the Phase 1 audit of the remaining Bash entry points against GH-172's vendored root
  contract, including the one real fix made in consult.sh and the clean verdicts for the other
  scoped files.
roadmap_exempt: true
---

# GH-172 Bash audit findings

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 audit of the remaining Bash entry points against GH-172's root contract; one real gap found and fixed in `relay-automation/consult.sh`, every other scoped file verified clean. | Phase 2 (Python audit) reads this doc for the Bash reference behavior each Python file is checked against. |

## relay-automation/marathon-drive.sh

Checked: vendored `.xyz` detection, split between harness install root (`_xyz_harness`), target/work
root (`ROOT`), and tick binary (`TICK_BIN`), plus the generated relay brief's absolute env-pinned
tick recipe.

Verdict: clean.

Notes: the script already keeps `_xyz_harness/bin/tick` separate from `ROOT`, preserves a caller-set
`TICK_BIN`, seeds `TICK_REPO_ROOT="$ROOT"` only for coordination, and bakes the absolute tick path
into the relay instructions so a foreign CWD cannot deadlock the handoff.

## relay-automation/relay-drive.sh

Checked: harness-local tool resolution, coordination-root usage for lane attempts, preservation of
`TICK_REPO_ROOT`, and worktree-isolation wiring for driven turns.

Verdict: clean.

Notes: `ROOT_DIR` stays the harness install root, `TICK_BIN` resolves independently from it, lane
attempt state keys off `${TICK_REPO_ROOT:-$ROOT_DIR}`, and the driver exports `RELAY_WORKTREE_ISOLATION`
without re-pointing `.tick` away from the shared coordination root.

## relay-automation/marathon-agent.sh

Checked: whether the dispatcher re-derived any root or tick path while routing between shims.

Verdict: clean.

Notes: this file is pure agent-to-shim dispatch from its own script directory. It does not touch
`TICK_REPO_ROOT`, the tick binary, or target/work-root routing.

## relay-automation/relay-turn-lib.sh

Checked: `rtl_tick_bin`, `rtl_init`, worktree begin/end, and the generated turn prompt's token
instructions.

Verdict: clean.

Notes: the kernel already resolves the tick binary in the right order (`TICK_BIN` override, pinned
coordination root when it actually contains `bin/tick`, then harness-local fallback), keeps
`RELAY_TARGET_ROOT` separate from `TICK_REPO_ROOT`, and explicitly documents that `.tick` stays shared
while isolated worktrees only contain the editable surface.

## relay-automation/aider-turn.sh

Checked: root split between `AIDER_TURN_ROOT`, `TICK_REPO_ROOT`, and the harness-local tick fallback,
plus ownership proof before launch.

Verdict: clean.

Notes: the shim already uses `rtl_tick_bin "$_tickroot"` for claim/info/ping, honors an orchestrator-
provided `TICK_REPO_ROOT`, and proves `claimer == self` before any mutation. Worktree isolation keeps
`.tick` shared via the pinned coordination root.

## relay-automation/consult.sh

Checked: `CONSULT_ROOT` versus the harness install root, and the legacy Gemini JSON cost-capture path
when `TICK_BIN` is unset in a vendored/root-split run.

Verdict: gap found and fixed.

Fix: replaced the stale `${TICK_BIN:-$ROOT/bin/tick}` fallback with a single harness-aware resolution
through `rtl_tick_bin`, anchored by `${TICK_REPO_ROOT:-$ROOT}`. This keeps the consulted repo
(`CONSULT_ROOT`) separate from the coordination root and still falls back to the harness-local
`bin/tick` when the coordination repo does not itself contain the binary.

Verification:
- `bash -n relay-automation/consult.sh`
- `bash test/consult.sh` -> 43 passed, 0 failed
- Targeted vendored/root-split smoke on 2026-07-17: `CONSULT_ROOT` pointed at a foreign git clone,
  `TICK_REPO_ROOT` pointed at a different coordination repo, `TICK_BIN` was unset, and
  `CONSULT_GEMINI_JSON=1` still produced a `cost.tokens` event for `CONSULT-gh172` under the pinned
  coordination repo's `.tick` while the consulted repo did not grow its own `.tick`.

## relay-automation/relay-loop.sh

Checked: whether the loop wrapper re-derived tick or coordination roots instead of delegating to
`poll.sh`.

Verdict: clean.

Notes: this script only resolves sibling `poll.sh` from its own directory and forwards the runtime
flags; it does not own tick-binary selection or coordination-root routing itself.

## relay-automation/watchdog.sh

Checked: separation of harness-local `TICK_BIN` fallback from caller-pinned `TICK_REPO_ROOT`.

Verdict: clean.

Notes: the watchdog is a coordination-only helper. Its default tick path is harness-local, and the
actual event-log root still comes from `TICK_REPO_ROOT` at execution time; it does not infer a target
work root or touch worktree isolation.

## relay-automation/runner.sh

Checked: separation of harness-local `TICK_BIN` fallback from caller-pinned `TICK_REPO_ROOT`, and
whether the runner tries to infer any foreign target root on its own.

Verdict: clean.

Notes: like `watchdog.sh`, this file is a coordination helper. It uses a harness-local default tick
path, leaves the coordination root to `TICK_REPO_ROOT`, and does not re-derive target/work-root state.

## utils/swarm-preflight.sh

Checked: vendored `.xyz` root detection, target-root handling, and marathon-drive invocation
construction.

Verdict: clean.

Notes: the script already distinguishes vendored harness root from target/work root, picks the correct
driver path for each mode, and canonicalizes same-repo root comparisons before deciding whether to emit
`--target-root`. It does not invoke tick directly, so there was no separate tick-binary bug here.
