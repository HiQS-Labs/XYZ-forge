---
title: "Phase brief: GH-278 gh278-timeout-drift (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-26
updated: 2026-07-26
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh278-timeout-drift phase of
  MARATHON-2026-07-26-VENDORED-LANE-HARDENING — not itself an active-doc capture; the canonical
  capture doc is GH-278-AIDER-TURN-TIMEOUT-DRIFT.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Phase fired; relay Approved by agy, but the turn failed containment (exit 6) — the fixture leaked into the caller cwd. Root-caused and fixed in 7d1a341. | Phase still shows escalated; the underlying defect is fixed but the phase was not re-driven. |

# Phase gh278 — one per-turn timeout, and no credit for empty artifacts

Issue: #278 · Capture doc: `PROJECT/2-WORKING/GH-278-AIDER-TURN-TIMEOUT-DRIFT.md`

## The defect
`RELAY_TURN_TIMEOUT_S` has three different defaults: `utils/py/aider-turn.py` 300s (**the one that
runs** — Python is default per GH-264), `relay-automation/aider-turn.sh` 600s, and
`skills/relay-xyz/SKILL.md` documents 900s. A thinking-heavy builder was killed at 300s; aider had
pre-created its nine `--file` targets as empty stubs, and the harness **committed nine 0-byte
files** and reported "declared artifact(s) appeared".

## Do
1. Pick ONE default and state the choice explicitly in the change. 900s (the documented value) is
   the least surprising.
2. Apply it to both shims AND the skill doc in the same change.
3. Add `test/gh278-turn-timeout-parity.sh` asserting shim ↔ shim ↔ doc agreement, and
   **register it in `validate.sh`'s `TESTS=()` array**.
4. Classify a declared artifact that is zero-byte or unchanged after a **killed** turn as
   no-progress, not "artifacts appeared".

## Do NOT
- Add per-turn artifact-count guidance / auto-fan (issue finding 1) — real, but out of scope here.
- Weaken the hung-CLI kill path: raising the cap must still leave exit 7 firing on a genuine hang.

## Acceptance
- Parity test fails before the fix, passes after (verify with `git stash`).
- A simulated killed turn leaving 0-byte artifacts reports no-progress.
- `bash validate.sh` green, with the new test actually executing.
