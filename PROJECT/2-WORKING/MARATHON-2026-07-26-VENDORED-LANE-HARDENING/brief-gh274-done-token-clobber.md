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
