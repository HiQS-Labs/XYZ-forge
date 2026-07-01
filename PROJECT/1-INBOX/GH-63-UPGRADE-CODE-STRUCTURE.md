---
title: GH-63 · Code Structure & Implementation Upgrade
status: Captured
created: 2026-06-30
owner: noelsaw
roadmap_exempt: false
---

# GH-63: Code Structure & Implementation Upgrade

## Problem
The current codebase architecture relies heavily on Bash for complex process supervision (`relay-drive.sh`, `poll.sh`) while the core kernel (`tick`) is cleanly written in Node.js. Although this fits a UNIX-philosophy design, process supervision and state machines in Bash become brittle and hard to maintain as the system scales. Additionally, the root directory is heavy with markdown documents, increasing cognitive load for new operators.

## Objective
Upgrade the code structure and implementation maturity from a B+ to a solid A by migrating orchestration to Node.js and enforcing stricter directory boundaries.

## Step-by-Step Actionable Plan

### Phase 1: Clean the Root Directory (Quick Win)
- **Goal**: Reduce root-level cognitive load without breaking the `ROUTER.md` contract.
- **Action**: 
  1. Move secondary/audit documentation (e.g., `4X4.md`, `FRONTDOOR.md`, `snapshot.md`, `CODEX.md`) to `docs/` or `PROJECT/4-MISC/`.
  2. Update `ROUTER.md` and any broken relative links to point to the new locations.
  3. Ensure `README.md`, `ROUTER.md`, `AGENTS.md`, `ROADMAP.md`, and `CHANGELOG.md` remain at the root as the canonical front door.

### Phase 2: Port the Decision Engine (`poll.sh` -> `poll.js`)
- **Goal**: Move the purely logical decision loop to a safer, more testable language.
- **Action**:
  1. Rewrite `poll.sh` logic in a dependency-free Node.js script (`src/poll.js`).
  2. Map the existing CLI flags (`--turn-source`, `--emit-delay`, etc.) to Node equivalents.
  3. Ensure the output shape and exit codes exactly match the Bash version.
  4. Swap `relay-loop.sh` to call `node src/poll.js` instead of `poll.sh`.
  5. Validate against `test/poll-driver.sh`.

### Phase 3: Port the Supervisor Loop (`relay-drive.sh` -> `relay-drive.js`)
- **Goal**: Harden process supervision (watchdogs, lock files, exit code propagation).
- **Action**:
  1. Rewrite `relay-drive.sh` in Node.js (`src/relay-drive.js`), utilizing `child_process.spawn` for better signal handling and detached execution.
  2. Keep `relay-turn-lib.sh` and the agent shims (`codex-turn.sh`, `agy-turn.sh`) in Bash for now—they are the lowest-level execution wrappers where Bash excels at environment manipulation and Git isolation.
  3. Ensure the driver-lock logic (reclaiming stale PIDs via `kill -0`) is reliably ported.
  4. Run a full marathon dogfood to prove containment holds under the new supervisor.

### Phase 4: Stricter Module Boundaries for JS Kernel
- **Goal**: Increase confidence in the `tick` projection engine.
- **Action**:
  1. Add JSDoc type annotations to the core `.js` files in `src/` to explicitly define the API surface between the event log and the projection.
  2. Wire up the Tier 1 CI (`node --check` or `tsc --allowJs --checkJs`) proposed in GH-61 to enforce these boundaries deterministically.

## QA & Verification
- All phases must independently pass `./validate.sh` (currently 70/70).
- Phase 3 requires a successful cross-model marathon run (`codex builder + agy reviewer`) with no containment breaches.
