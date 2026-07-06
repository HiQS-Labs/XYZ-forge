---
title: GH-71 · Code Structure & Implementation Upgrade
gh_issue: 71
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/71
status: Phases 1-2 shipped, 3-4 deferred
created: 2026-06-30
updated: 2026-07-01
owner: noelsaw
roadmap_exempt: false
---

# GH-71: Code Structure & Implementation Upgrade

> **Issue-number history:** captured 2026-06-30 as `GH-63-UPGRADE-CODE-STRUCTURE.md`, but GitHub #63
> is the signal-triage stage. Correct issue of record is **[#71](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/71)** (opened 2026-07-01); file renamed accordingly.

## Problem
The current codebase architecture relies heavily on Bash for complex process supervision (`relay-drive.sh`, `poll.sh`) while the core kernel (`tick`) is cleanly written in Node.js. Although this fits a UNIX-philosophy design, process supervision and state machines in Bash become brittle and hard to maintain as the system scales. Additionally, the root directory is heavy with markdown documents, increasing cognitive load for new operators.

## Objective
Upgrade the code structure and implementation maturity from a B+ to a solid A by tightening directory boundaries and the JS-kernel API surface first, and — only if a concrete maintenance trigger justifies it — later migrating orchestration to Node.js.

## Scope & Sequencing
- **Initial (queue now):** Phase 1 + Phase 2 — both low-risk, reversible, independently valuable, and require no rewrite of the load-bearing Bash supervisor.
- **Deferred (revisit later):** Phase 3 + Phase 4 — the `poll.sh`/`relay-drive.sh` → Node ports. These rewrite the most safety-critical, best-dogfooded components and are justified today only by a subjective grade. Hold them behind a concrete trigger (an actual maintenance incident, or a specific bug class Bash caused), not a letter grade. A port must also keep the old `.sh` runnable behind a flag until the Node version survives N clean marathon runs.

## Step-by-Step Actionable Plan

### Phase 1 (Initial): Clean the Root Directory (Quick Win)
- **Goal**: Reduce root-level cognitive load without breaking the `ROUTER.md` contract.
- **Action**: 
  1. Move secondary/audit documentation (e.g., `4X4.md`, `FRONTDOOR.md`, `snapshot.md`, `CODEX.md`) to `docs/` or `PROJECT/4-MISC/`.
  2. Update `ROUTER.md` and any broken relative links to point to the new locations.
  3. Ensure `README.md`, `ROUTER.md`, `AGENTS.md`, `ROADMAP.md`, and `CHANGELOG.md` remain at the root as the canonical front door.

### Phase 2 (Initial): Stricter Module Boundaries for JS Kernel
- **Goal**: Increase confidence in the `tick` projection engine.
- **Action**:
  1. Add JSDoc type annotations to the core `.js` files in `src/` to explicitly define the API surface between the event log and the projection.
  2. Wire up the Tier 1 CI (`node --check` or `tsc --allowJs --checkJs`) proposed in GH-61 to enforce these boundaries deterministically.

### Phase 3 (Deferred): Port the Decision Engine (`poll.sh` -> `poll.js`)
- **Goal**: Move the purely logical decision loop to a safer, more testable language.
- **Action**:
  1. Rewrite `poll.sh` logic in a dependency-free Node.js script (`src/poll.js`).
  2. Map the existing CLI flags (`--turn-source`, `--emit-delay`, etc.) to Node equivalents.
  3. Ensure the output shape and exit codes exactly match the Bash version.
  4. Swap `relay-loop.sh` to call `node src/poll.js` instead of `poll.sh`.
  5. Validate against `test/poll-driver.sh`.

### Phase 4 (Deferred): Port the Supervisor Loop (`relay-drive.sh` -> `relay-drive.js`)
- **Goal**: Harden process supervision (watchdogs, lock files, exit code propagation).
- **Action**:
  1. Rewrite `relay-drive.sh` in Node.js (`src/relay-drive.js`), utilizing `child_process.spawn` for better signal handling and detached execution.
  2. Keep `relay-turn-lib.sh` and the agent shims (`codex-turn.sh`, `agy-turn.sh`) in Bash for now—they are the lowest-level execution wrappers where Bash excels at environment manipulation and Git isolation.
  3. Ensure the driver-lock logic (reclaiming stale PIDs via `kill -0`) is reliably ported.
  4. Run a full marathon dogfood to prove containment holds under the new supervisor.

## QA & Verification
- All phases must independently pass `./validate.sh` (currently 70/70).
- Phase 4 (deferred) requires a successful cross-model marathon run (`codex builder + agy reviewer`) with no containment breaches.
