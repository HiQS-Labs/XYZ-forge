---
gh_issue: 140
source: https://github.com/HiQS-Labs/XYZ-forge/issues/140
title: "chore(marathon): datetime.utcnow() deprecation warnings pollute every driven run's output"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
goal: >
  Replace the three utcnow() call sites with timezone-aware now(timezone.utc) so the
  strftime outputs are byte-identical and the DeprecationWarning stops polluting captured
  driver output — including on the escalation path's record-keeping.
---

# GH-140: utcnow() deprecation swap

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — all three sites swapped to `datetime.now(datetime.timezone.utc)` / `_dt.now(_dt.timezone.utc)` (`marathon_drive.py` save_transcript + write-set probe, `relay_drive.py` consult-verify archive day): strftime output byte-identical, warnings gone. | Land with the GH-135..140 PR. |

## Why

The warning appeared in every captured marathon run's output (observed live in the gh131
Wave-1 runs); the day `utcnow` is removed, those paths raise `AttributeError` mid-phase — one
of them on the escalation path.

## Verification

`./validate.sh` full gate green (transcript-path suites gh314/gh388 among them); no
DeprecationWarning lines in the gh131 suite's captured driver output.
