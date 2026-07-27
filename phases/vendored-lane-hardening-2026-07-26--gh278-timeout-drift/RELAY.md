# Marathon Phase gh278-timeout-drift
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH278-TIMEOUT-DRIFT-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/aider-turn.py,relay-automation/aider-turn.sh,skills/relay-xyz/SKILL.md,test/gh278-turn-timeout-parity.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH278-TIMEOUT-DRIFT-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh278-timeout-drift/RELAY.md,utils/py/aider-turn.py,relay-automation/aider-turn.sh,skills/relay-xyz/SKILL.md,test/gh278-turn-timeout-parity.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH278-TIMEOUT-DRIFT-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH278-TIMEOUT-DRIFT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/vendored-lane-hardening-2026-07-26--gh278-timeout-drift/RELAY.md and utils/py/aider-turn.py,relay-automation/aider-turn.sh,skills/relay-xyz/SKILL.md,test/gh278-turn-timeout-parity.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/aider-turn.py,relay-automation/aider-turn.sh,skills/relay-xyz/SKILL.md,test/gh278-turn-timeout-parity.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH278-TIMEOUT-DRIFT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH278-TIMEOUT-DRIFT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/vendored-lane-hardening-2026-07-26--gh278-timeout-drift/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Set the Aider per-turn default to **900 seconds** in both runtime shims: Python (the default path) and the Bash compatibility path. The Bash inline contract and relay-xyz environment table now make the shared value explicit; a new static parity test guards Python ↔ Bash ↔ skill documentation, and `validate.sh` registers it.

The existing marathon recovery seam already treats zero-byte or unchanged declared artifacts as no-progress (GH-279 coverage in `test/marathon-drive.sh`); this phase's allowlist intentionally does not alter that runner surface.

Verification: `bash -n relay-automation/aider-turn.sh test/gh278-turn-timeout-parity.sh && bash test/gh278-turn-timeout-parity.sh` → 3 pass, 0 fail. The full gate was deliberately not run per the phase instructions.
