---
title: Medium-level write-ops logging of agent disk-write commands
status: Proposed (1-INBOX — not yet active)
created: 2026-08-27
updated: 2026-08-27
owner: noel
gh_issue: 275
source: https://github.com/HiQS-Labs/XYZ-forge/issues/275
doc_type: feature
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Full exec auditing (Endpoint Security / eslogger tier) — re-entry trigger documented in the issue.
  - Capturing commands the turn-taker CLIs run internally — bounded by ALLOW_PATHS containment, not watched.
  - Log rotation — records are size-capped; revisit past ~10MB.
related:
  - GH-260 (improvement-opportunities parent; observability weakness this retires)
---

# GH-275 — Medium-level write-ops logging of agent disk-write commands

Durable JSONL receipts for the destructive disk-writes agents execute — worktree
teardowns, clone deletions, `rm -rf`/`rm -f`, destructive git — across Claude Code
and every harness turn-taker, so "what deleted that?" has a timestamped answer.

The issue body carries the consult-sharpened **plan v2** (codex + agy, two-model
verified) with 4 checkboxes plus 5 agy amendments: user-level PreToolUse hook
`write-ops-log.sh`; instrumentation of `rtl_worktree_end()`
(`relay-automation/relay-turn-lib.sh:873-875`), the confirmed `rm -rf` in
`xyz-sync.sh delete_rows`, and the `consult.py`/`review_xyz.py` removal sites;
a tested-superset pattern family over gh527's; one registered test file. Central
default-on log at `~/.local/state/xyz/write-ops.jsonl` (atomic `0600`,
`O_APPEND`, size-capped, swallow-errors).

Source of truth for scope: https://github.com/HiQS-Labs/XYZ-forge/issues/275
(sections "Consult-sharpened plan v2" + "Agy second opinion"). Est. 2-3 hours.

## Status

| Field | Value |
| --- | --- |
| Stage | 1-INBOX capture; plan two-model verified; implementation not started |
