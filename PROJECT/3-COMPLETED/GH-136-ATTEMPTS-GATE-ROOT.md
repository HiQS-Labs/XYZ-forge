---
gh_issue: 136
source: https://github.com/HiQS-Suite/XYZ-forge/issues/136
title: "relay-drive: lane-attempt gate reads TICK_REPO_ROOT before #129's self-resolution"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 2
risk: 3
goal: >
  Resolve TICK_REPO_ROOT once, silently, BEFORE the lane-attempt gate so attempt counting and
  token state live in one repo; the self-resolution NOTE still prints after the driver lock
  (gh376 twin-parity requires the lock refusal to stay the first printable line).
---

# GH-136: attempts counted in a different repo than the token

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — `relay_drive.py` now computes `tick_repo_root` (and exports it to children) ahead of `lane_attempt_gate`, which consumes the resolved value directly; only the NOTE's `eprint` remains after the lock block, where gh376's parity pin demands it. Pinned by `test/synthetic/gh129-relay-tick-root.sh` case 5: an un-env'd drive from a fixture repo counts its attempt in THAT repo's `.tick/attempts/` and leaks nothing into the harness clone's. | Land with the GH-135..140 PR. |

## The defect

#129 (PR #134) placed self-resolution after the driver lock — correct for parity, but the
lane-attempt gate above it still defaulted to the harness root, so a vendored-`.xyz` drive with
the env unset counted attempts in one repo while the token lived in another: `LANE_MAX_ATTEMPTS`
(GH-45) enforcement fragmented, and re-fires from different shells under-counted. Marathon-driven
lanes were unaffected (marathon exports `TICK_REPO_ROOT`).

## Verification

`bash test/synthetic/gh129-relay-tick-root.sh` — 17/0 including case 5's three assertions;
`test/gh376-relay-drive-lock-parity.sh` still 21/0 (parity preserved), full gate green.
