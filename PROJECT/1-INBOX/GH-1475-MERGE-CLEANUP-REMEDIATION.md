---
gh_issue: 1475
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1475
title: "merge-cleanup: 3-phase remediation from a 13-PR batch post-mortem"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-14
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 3
---

# merge-cleanup: 3-phase remediation from a 13-PR batch post-mortem

Capture of https://github.com/HiQS-Labs/XYZ-forge/issues/1475 (the issue body is the canonical,
plan-QA-approved three-phase plan). This task executes **Phase 1 only** (P1.1–P1.6):

- P1.1 fetch + `merge --ff-only origin/<branch>` instead of `git pull` in `utils/py/wave_reconcile.py`, with a bounded ref-lock retry; ref-lock patterns join `merge_cleanup.py` `TRANSIENT_RE`.
- P1.2 line-buffered stdout/stderr in `merge_cleanup.py`.
- P1.3 delete the `merge-cleanup-*` landing workdir on a clean loop return (honor `keep_workdir`); `merge-check-*` stays retained.
- P1.4 `--reconcile-pr` records the recovery in the unfinished batch record; `--record-sweep` names the right recovery per PR.
- P1.5 SKILL.md exit-code contract and the `:476` correction.
- P1.6 read-only `PRE-FLIGHT` warnings in the dry run.

Phases 2–3 stay on the issue as separate future work.
