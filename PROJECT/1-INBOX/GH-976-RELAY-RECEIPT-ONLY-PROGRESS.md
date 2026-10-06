---
gh_issue: 976
source: https://github.com/HiQS-Labs/XYZ-forge/issues/976
title: "relay-drive: receipt-only commits count as convergence and extend the round cap"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-05
doc_type: bugfix
---

# GH-976: receipt-only commits are not convergence

Consumer incident: david-nguyen-chaoticdomain/user-sage-backend#75 (GH-70 marathon relay
extended to cap 10 on relay-transcript commits alone, then halted exit 4 `cap-progressing-extended`).

## Ask

The GH-115 progress oracle in `utils/py/relay_drive.py` treats any HEAD movement as convergence.
Relay turns commit their own transcript (`relay(<task>): <agent> turn`, `relay-drive: attest ...`),
so HEAD always moves. Count only commits that touch files outside receipt paths.

## Acceptance

- Receipt-only commits at the cap exit 4 `cap-stalled` at the original cap; no `Extension · System` block.
- A real-file commit at the cap still extends (GH-115 behaviour unchanged).
- `test/gh115-round-cap.sh` and `bash validate.sh --auto` green; link back from user-sage-backend#75.

## Rating rationale (2026-10-05)

`rated 80/75/50/85`. Severity 75: an unattended marathon burns the full 2x cap on empty rounds and
halts with a misleading reason; no data loss, recoverable by restart. Priority 80: same-class
incident observed in two consumers (GH-115 history here, user-sage-backend#75 on 2026-10-05) and it
blocks unattended runs. Appeal 50 (neutral, no user preference). Effort 85: one oracle in one file,
covered by an existing suite.
