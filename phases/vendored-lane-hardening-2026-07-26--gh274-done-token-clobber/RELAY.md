# Marathon Phase gh274-done-token-clobber
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-274 gh274-done-token-clobber (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-26
updated: 2026-07-26
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh274-done-token-clobber phase of
  MARATHON-2026-07-26-VENDORED-LANE-HARDENING — not itself an active-doc capture; the canonical
  capture doc is GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md one level up.
roadmap_exempt: true
---

# Phase gh274 — a re-invoked phase must not clobber an Approved `RELAY.md`

Issue: #274 · Capture doc: `PROJECT/2-WORKING/GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md`

## The defect
`marathon-drive.sh` and its Python twin have no path that detects "this phase's relay already
reached a terminal Approved state and its tick token is `done` — only re-run the pre-advance gate."
It unconditionally re-renders the phase's `RELAY.md` from the brief on every invocation, destroying
the Approved record. Hit live during GH-273 Phase 0.

## Do
1. Detect the satisfied-lane case: token `done` **and** the relay file already terminal/Approved.
2. In that case, skip re-rendering `RELAY.md` and re-run only the pre-advance gate.
3. Cover it in `test/marathon-drive.sh`: a re-invocation of a satisfied phase preserves the
   Approved record byte-for-byte and still runs the gate.

## Do NOT
- Weaken the normal path: a phase that is genuinely not terminal must still re-render and run.
- Treat a `done` token alone as sufficient — the relay file's terminal state must agree, or a
  stale/misplaced token silently skips real work.

## Acceptance
- Re-invoking an approved phase leaves `RELAY.md` unchanged and re-runs the gate.
- A non-terminal phase is unaffected.
- `bash validate.sh` green.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh274-done-token-clobber/RELAY.md,relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/vendored-lane-hardening-2026-07-26--gh274-done-token-clobber/RELAY.md and relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,test/marathon-drive.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH274-DONE-TOKEN-CLOBBER-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/vendored-lane-hardening-2026-07-26--gh274-done-token-clobber/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
