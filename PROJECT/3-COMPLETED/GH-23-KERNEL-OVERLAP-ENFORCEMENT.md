---
title: "GH-23: kernel invariant — enforce path-overlap rejection on direct tick claim and tick scope"
status: active
created: 2026-08-17
updated: 2026-08-18
owner: orchestrator (Claude Code)
goal: enforce collision-free path claims at the kernel boundary by rejecting direct tick claim and tick scope when requested paths overlap active claims
gh_issue: 23
source: https://github.com/HiQS-Suite/XYZ-forge/issues/23
branch: fix/gh-23-kernel-overlap-enforcement
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
---

# GH-23 — Kernel Invariant: Enforce Path-Overlap Rejection on Direct tick claim and tick scope

## Status

| What was just completed | What's next |
|---|---|
| Issue #23 filed; feature branch `fix/gh-23-kernel-overlap-enforcement` cut; `setsOverlap` path overlap validation implemented under `withClaimLock` in `src/claim.js` and `src/scope.js`; `--force` bypass and event log provenance (`force: true`) added in `src/events.js` and `bin/tick`; 13-assertion regression suite `test/gh23-path-overlap-enforcement.sh` green; full `./validate.sh` suite green; dual advisory review relays completed with Codex and Command Code Kimi K3. **2026-08-18: orchestrator-driven Agy code review** (`relay-system/2026-08-17/gh-23-kernel-overlap-enforcement-code-review.md`) found the missing negative control (blocker) and a minor double-fold inefficiency in `scope.js` (nit); both fixed directly — negative control recorded at `test/baselines/GH-23-negative-control.md`, `scope.js` refactored to reuse `assertOwnership`'s folded task map instead of re-reading the event log. PR #24 retargeted from `main` to `development`. | Push, confirm green on `development`, PR ready for merge |

## Bug

The README and architecture promise collision-free path claims so two agents "never edit the same thing". While `tick take` and `tick next` filter out overlapping tasks, lower-level kernel operations bypassed this invariant:
1. `tick claim TASK --paths ...` checked ownership, status, handoff, and per-agent limits, but did NOT compare requested paths with active claims held by other agents.
2. `tick scope TASK --paths ...` allowed owners to replace their path list without checking for overlapping active claims, and was not wrapped under `withClaimLock`.

## Implementation & Hardening

1. **`src/claim.js`**: Under `withClaimLock`, evaluates `setsOverlap(paths, otherClaimedPaths)` across all other active tasks. Rejects with `{ won: false, overlap: true, unavailable: '...' }` (exits 1) unless `opts.force` is passed.
2. **`src/scope.js`**: Wrapped in `withClaimLock`. Evaluates `setsOverlap(paths, otherClaimedPaths)` and throws an error (exits 1) unless `opts.force` is passed.
3. **`src/events.js`**: Added `force` field to `appendEvent` destructuring and event publishing, recording `force: true` in `.tick/events/` for full audit provenance.
4. **`bin/tick`**: Wires `--force` on `claim` and `scope`, formats descriptive error output, and documents `[--force]` in usage. Note: `tick log` remains a low-level raw event append mechanism for test seeding/fixtures below kernel enforcement.
5. **`test/gh23-path-overlap-enforcement.sh`**: 13 checkable assertions covering:
   - Direct claim overlap rejection (exit 1, formatted output).
   - Non-mutation on rejected claim (`TASK-102` remains `open`).
   - Forced claim override (`--force`) and event provenance (`"force":true`).
   - Non-overlapping claim success (`TASK-103`).
   - Scope expansion overlap rejection and non-mutation (`TASK-103` paths unchanged).
   - Forced scope expansion override (`--force`) and event provenance (`"force":true`).
   - Release unblocking (`TASK-104` claimed cleanly after conflicting task completes).
   - Third-party claim rejection against active forced scope (`TASK-106` rejected).
   - Idempotent re-claim by current holder succeeds without self-overlap rejection.

## Multi-Model Relay Reviews

1. **Relay 1 (OpenAI Codex / gpt-5.6-terra)**:
   - Verified that serialization under `withClaimLock` closes TOCTOU race windows.
   - Identified missing `force` provenance in `src/events.js` (now fixed).
   - Recommended non-mutation assertions and release-unblocking tests (now added).
2. **Relay 2 (Command Code / Moonshot AI Kimi K3)**:
   - Confirmed `other.id !== task` guard in `scope.js` is load-bearing for retaining current paths.
   - Confirmed epoch fencing is preserved across forced and unforced transitions.
   - Recommended testing third-party rejection against active forced scope (now added).

## Acceptance Criteria

- [x] Direct `tick claim` with paths overlapping another agent's active claim is rejected (`won: false, overlap: true`, exit 1).
- [x] `tick scope` expanding into another agent's active claim is rejected with an error under `withClaimLock` (exit 1).
- [x] Both commands support `--force` for emergency manual overrides, with `force: true` persisted in event logs.
- [x] Rejected claims and scope changes are proven non-mutating.
- [x] Release unblocking and third-party rejection against forced scopes verified.
- [x] Regression test suite `test/gh23-path-overlap-enforcement.sh` passes (13/13).
- [x] Full validation gate `./validate.sh` passes (215/215).
