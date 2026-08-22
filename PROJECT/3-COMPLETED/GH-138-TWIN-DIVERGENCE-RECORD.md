---
gh_issue: 138
source: https://github.com/HiQS-Suite/XYZ-forge/issues/138
title: "relay-drive Bash/Python twin divergence (post-#129) — record it before it generates false bug reports"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
goal: >
  Record the deliberate post-#129 divergence at the divergence site in relay_drive.py, in the
  marathon_drive.py GH-414 style, so a XYZ_PYTHON=0 run is not misread as a regression.
---

# GH-138: the twin-divergence record

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — `relay_drive.py`'s post-lock block now carries a `BASH/PYTHON DIVERGENCE, deliberate and pinned` note: the frozen twin has no self-resolution and its not-found diagnostic still reads "token missing"; teaching it this fix needs a `Frozen-twin-exception:` trailer. | Land with the GH-135..140 PR. |

## Why

Undocumented twin divergences generate false bug reports against the dead half (#379/#380); the
repo's convention is to pin them at the divergence site (see `marathon_drive.py`'s GH-414 note).

## Verification

Comment-only change; `test/gh376-relay-drive-lock-parity.sh` 21/0 (the parity contract the note
references still holds).
