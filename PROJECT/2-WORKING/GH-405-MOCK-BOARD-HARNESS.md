---
gh_issue: 405
source: https://github.com/HiQS-Labs/XYZ-forge/issues/405
title: "Local debugging mock harness for GitHub Projects V2 API"
status: Active (2-WORKING — plan v1 ratified in issue 405, GLM feedback folded)
created: 2026-09-03
updated: 2026-09-03
owner: noelsaw1
doc_type: feature
effort: 2
complexity: 2
risk: 1
phases: 4
rating: "pri/sev/appeal/effort 65/40/80/30 · calc 215"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/402
fix_probes:
  - test -f utils/py/mock_gh_board.py
  - test -f test/gh402-board-sync.sh
non_goals:
  - Wiring into automated test suites (validate.sh stays offline, hermetic, and independent).
  - General-purpose GitHub API simulation (scoped strictly to Projects V2 GraphQL queries and mutations).
goal: >
  Provide developers with a standalone offline CLI mock executable (mock_gh_board.py) that speaks
  the `gh api graphql` contract and simulates GitHub Projects V2 board operations, paired with an
  execution seam (XYZ_BOARD_SYNC_GH_BIN) in board_sync.py and an offline regression pin.
---

# GH-405: Local debugging mock harness for GitHub Projects V2 API

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 setup: plan v1 ratified with GLM feedback folded, fresh task clone created, git hooks installed. | Phase 0: Add `XYZ_BOARD_SYNC_GH_BIN` seam to `utils/py/board_sync.py` + offline pin in `test/gh402-board-sync.sh`. |

**Plan of record:** Issue [#405](https://github.com/HiQS-Labs/XYZ-forge/issues/405) body + final plan (comment 2).

## Table of contents
- [Phase 0 — Seam & Gate Pin](#phase-0--seam--gate-pin)
- [Phase 1 — mock_gh_board.py Implementation](#phase-1--mock_gh_boardpy-implementation)
- [Phase 2 — Verification & Worked Demos](#phase-2--verification--worked-demos)
- [Phase 3 — DeepSeek v4 Pro Relay QA & PR](#phase-3--deepseek-v4-pro-relay-qa--pr)

---

## Phase 0 — Seam & Gate Pin
- [ ] Add `XYZ_BOARD_SYNC_GH_BIN` environment variable seam to `_gql()` in `utils/py/board_sync.py`.
- [ ] Add offline test assertion in `test/gh402-board-sync.sh` verifying that `XYZ_BOARD_SYNC_GH_BIN` is dispatched.
- **QA Gate 0:** `bash test/gh402-board-sync.sh` passes with the new pin.

## Phase 1 — mock_gh_board.py Implementation
- [ ] Implement `utils/py/mock_gh_board.py` as an executable Python CLI matching `gh api graphql` invocation contract (`-f query=...`, `-F key=val`).
- [ ] Implement in-memory/file-backed state (`--state`, `XYZ_MOCK_BOARD_STATE`) storing Project V2 schema (fields, single-select options, items, multi-repo issue references).
- [ ] Implement query resolvers (`user.projectV2`, `organization.projectV2`, `node.items` with pagination, `repository.issue`).
- [ ] Implement mutation resolvers (`addProjectV2ItemById`, `updateProjectV2ItemFieldValue`, `deleteProjectV2Item`).
- [ ] Implement fault injection modes (`XYZ_MOCK_BOARD_FAULT`, `--fail-mutation`).
- **QA Gate 1:** `mock_gh_board.py` CLI functions directly with `--dump`, `--seed`, `--reset`, and responds correctly to mock `gh api graphql` queries.

## Phase 2 — Verification & Worked Demos
- [ ] Demo 1: Full mutation lifecycle against `mock_gh_board.py` (`board_add` -> `_set_status` -> `read-back` -> `dedupe`).
- [ ] Demo 2: Self-healing retry on simulated stale option ID error.
- **QA Gate 2:** `./validate.sh` remains 100% green.

## Phase 3 — DeepSeek v4 Pro Relay QA & PR
- [ ] Run automated `/relay-xyz` QA with DeepSeek v4 Pro reviewer.
- [ ] Reconcile and apply all findings.
- [ ] Open PR targeting `development`.
