Consult tie-break at the FINAL-QA round cap (GH-1653, XYZ-forge). Read-only advisory.

Read: relay-system/2026-11-27/gh1653-final-qa.md (4 Codex rounds; rounds 1-3 findings all fixed with before/after probes), PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md, TESTS-RESULTS/2026-11-27+GH-1653/README.md, and the diff `git diff 52813e56f..HEAD -- utils/py/jog_run.py utils/py/gate_receipt.py test/gh280-jog-marathon-adapter.sh`.

Round 4 left one [Should] (Form 2): an unsupervised `jog run` can still reclaim the supervisor lock from a live owner that stalls >10 s between creating the lock directory and writing its PID. The Producer reproduced it with the reviewer's probe and filed it as follow-up issue #1671 (atomic lock creation), because the two-step lock protocol predates GH-1653 and GH-1653 already narrowed it (before: no grace at all; now: 10 s grace for every entry, conservative acquisition for resume/retry-gate/retry-build).

Operational envelope: local agent CLI, single repo; do not weaken the pre-push gate; commensurate complexity; no new tests beyond focused cases in the existing gh280 suite.

Question: Should GH-1653 proceed to exact-commit qualification and a ready PR with #1671 tracked separately? Answer exactly one line first: "DECISION: PROCEED" or "DECISION: HOLD", then up to 6 bullets citing file:line for any remaining defect that (1) is introduced or worsened by this diff and (2) would make the delivered fix wrong or unsafe. No speculative hardening.
