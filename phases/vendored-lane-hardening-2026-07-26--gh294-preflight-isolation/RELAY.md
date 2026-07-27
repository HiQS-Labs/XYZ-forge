# Marathon Phase gh294-preflight-isolation
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH294-PREFLIGHT-ISOLATION-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh294-preflight-isolation/RELAY.md,utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/vendored-lane-hardening-2026-07-26--gh294-preflight-isolation/RELAY.md and utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/swarm-preflight.sh,utils/py/swarm_preflight.py,test/swarm-preflight.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH294-PREFLIGHT-ISOLATION-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/vendored-lane-hardening-2026-07-26--gh294-preflight-isolation/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Added `RELAY_WORKTREE_ISOLATION=1` to the generated marathon invocation in both runtime twins: `utils/swarm-preflight.sh` and `utils/py/swarm_preflight.py`. Extended `test/swarm-preflight.sh` to confirm the flag appears in both packet renderings and that Bash/Python emit byte-identical invocation files. Verified: `bash test/swarm-preflight.sh` — 98 passed, 0 failed.
