---
title: "marathon-root-audit.sh is blind to python3-spelled driver invocations (GH-195 class)"
status: Active
created: 2026-08-26
updated: 2026-08-26
owner: orchestrator (Claude Code)
gh_issue: 273
source: https://github.com/HiQS-Labs/XYZ-forge/issues/273
doc_type: bugfix
effort: 2
complexity: 3
risk: 1
phases: 1
related:
  - "GH-195 — the incident this matcher gap enabled (test fixed, matcher left)"
  - "GH-401 — the audit's original fix (filename-scope blind spot)"
goal: >
  The marathon-root audit recognizes python3-spelled driver invocations in program position,
  closing the GH-195 class gap without false positives on read-only spellings.
---

# GH-273 · marathon-root-audit: recognize python-spelled invocations

## Status

| What was just completed | What's next |
|---|---|
| Implementation complete (commit b593b03c): .py alias registration + program-position python3 matching + group-span safety; four gh322 parse probes scoped; gh273 pinning test 9/0; audit 139 invocations, 0 failures | Agy relay QA on the PR diff, then full validate.sh; PR into development |

Spun off from the #260 assessment (improvement item 5), scoped to the known-live instance.
The AGENTS.md rail ("an audit that recognizes only one invocation shape stops covering the same
operation reached a different way", added with GH-195) already covers the review criterion —
this is the mechanical catch-up for the guard GH-195 itself implicated.

`test/marathon-root-audit.sh`'s matcher only recognizes Bash spellings:
`find_invocation_target()` (lines 113-138) matches literal `./.xyz/relay-automation/*.sh`
strings and `bash "$VAR"` for registered aliases; `discover_file_metadata()` (line 105)
registers aliases only for `relay-automation/(marathon|marathon-drive).sh` paths. A test that
invokes `python3 utils/py/marathon_drive.py` directly is invisible — exactly the gap that let
`test/gh115-round-cap.sh` commit a live transcript onto every real clone running `validate.sh`.

Fix:

- register `.py` driver paths (`utils/py/marathon_drive.py`, and the relay-drive pair for
  symmetry) as aliases in `discover_file_metadata()`
- add a `python3 "$VAR"` branch (and direct `python3 <path>` literals) to
  `find_invocation_target()`
- match **program position only**: `python3 - "$ROOT/utils/py/marathon_drive.py" <<'PY'`
  (the test/gh390-gate-guard.sh:112 heredoc-argv shape reads the driver without running it)
  must NOT be flagged; a whole-line keyword regex would false-positive on comments,
  assignments, and echo strings — extend the alias architecture, don't replace it
- pinning test: unscoped `python3` invocation FAILS the audit, `MARATHON_ROOT=`-scoped one
  PASSES, gh390-style negative control stays clean

## Verification

- new pinning test green; `bash test/marathon-root-audit.sh` still green
- Full `./validate.sh` green
