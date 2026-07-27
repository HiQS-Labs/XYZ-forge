---
title: "Phase brief: GH-294 gh294-preflight-isolation (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-26
updated: 2026-07-26
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh294-preflight-isolation phase of
  MARATHON-2026-07-26-VENDORED-LANE-HARDENING — not itself an active-doc capture; the canonical
  capture doc is GH-294-PREFLIGHT-ISOLATION-FLAG.md one level up.
roadmap_exempt: true
---

# Phase gh294 — preflight must emit `RELAY_WORKTREE_ISOLATION=1`

Issue: #294 · Capture doc: `PROJECT/2-WORKING/GH-294-PREFLIGHT-ISOLATION-FLAG.md`

## The defect
`utils/swarm-preflight.sh`'s `INVOCATION` template (~lines 819-825) and its Python twin
`utils/py/swarm_preflight.py` both emit a suggested `marathon-drive.sh` command with **no**
`RELAY_WORKTREE_ISOLATION=1`. That flag defaults OFF. `--require-clean` checks the tree is clean
*before* the run and gives zero isolation *during* it, so an operator copying the packet's own
suggested command runs every turn directly against ROOT with no per-turn containment.

Reproduced today: `relay-system/preflight/2026-07-27/gh-292-worktree-vendored-discovery/marathon-invocation.txt`
contains no `RELAY_WORKTREE_ISOLATION`.

## Do
1. Add `RELAY_WORKTREE_ISOLATION=1` to the invocation template so it appears in BOTH
   `marathon-invocation.txt` and `packet.md`.
2. Make the identical change in `utils/py/swarm_preflight.py`. **Do not fix one twin only** —
   py/sh drift is the exact bug class phase gh278 exists to remove.
3. Extend `test/swarm-preflight.sh`: assert the happy-path packet's invocation contains the flag,
   and assert the Bash and Python twins emit byte-identical invocations.

## Do NOT
- Change `RELAY_WORKTREE_ISOLATION`'s own default in the shims. Fix what the packet EMITS.
- Touch the orchestrator's branch management — explicitly out of scope on the capture doc.

## Acceptance
- Regenerating any packet yields an invocation containing `RELAY_WORKTREE_ISOLATION=1`.
- py/sh invocation parity asserted by a test, not assumed.
- `bash validate.sh` green.
