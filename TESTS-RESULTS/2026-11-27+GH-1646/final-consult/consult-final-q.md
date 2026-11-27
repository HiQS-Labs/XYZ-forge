Consult tie-break at the 4-round FINAL-QA cap (XYZ-forge GH-1646). Advisory, read-only.

Read, in this repo:
- `git diff 52813e56f..HEAD -- utils/py/swarm_preflight.py test/gh400-acceptance-fidelity.sh` (the implementation)
- PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md (approved plan; plan QA was Consult-Adjudicated)
- relay-system/2026-11-27/gh1646-final-qa.md (4 Codex final-QA rounds and dispositions)
- TESTS-RESULTS/2026-11-27+GH-1646/ (red/green receipts, mypy before/after, SMOKE.md, provenance.jsonl)

Operational envelope: local developer CLI; preflight acceptance-fidelity comparison of a GitHub issue's
`## Acceptance` list vs a capture doc's copy. Smallest change in the existing parser; no new suites (GH-831).
Commensurate complexity governs: grade against the issue's requirements, not every conceivable Markdown edge.

Every round-4 finding was fixed (mypy strict-optional narrowing; before exit 1, after exit 0). Deferred and filed:
#1665 (pre-existing deviation splitter), #1666 (shared splitlines line model). Known, documented limits: a
literal heading/rule inside an issue fence still ends the section (pre-existing, identical before/after);
archived #792 capture replays as stale deviations (historical record, not edited).

Questions (1-3 sentences each, cite file:line where you disagree):
1. Does the diff satisfy #1646: plain `-`/`*` issue bullets count; checkbox parsing, the deviations heading,
   nested bullets, HRs and None-vs-[] unbroken; capture side and packet inliner unchanged?
2. Do the receipts prove red-then-green at the real `check_acceptance_fidelity` seam (not mocked)?
3. Any defect INTRODUCED by this diff that should block a ready PR? Give a concrete input if so.
4. Verdict: APPROVE or BLOCK, one line.
