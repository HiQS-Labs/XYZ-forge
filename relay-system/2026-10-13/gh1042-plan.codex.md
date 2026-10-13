# RELAY · GH1042 + GH1045 repair plan
NEXT: codex (Reviewer)
STATUS: Open
ROUND: 1 / 3

## Setup
Producer: Codex outer session. Reviewer: independent Codex CLI via shipped relay.
Artifact: PROJECT/2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md
Recon: PROJECT/2-WORKING/recon-phase-recovery.md
Evidence: TESTS-RESULTS/2026-10-13+GH-1042/baseline-results.json and provenance.jsonl
Task: RELAY-GH1042-PLAN-20261013
Operational envelope: local single-user harness; preserve GH505 isolation/approval and strict Jog merge checks. No enterprise threat model, new suites, registry, controllers or migration framework. Grade actual requirements and commensurate complexity. Reviewer edits ONLY this relay thread, no production edits, commits, pushes, gates or test/*.sh in this valued clone. Reading source/manual evidence is allowed. Plan-only approval basis is textual; no runtime claim.

## Round 1 · Producer
Did: traced current lifecycle, recorded real baseline failures, separated historical completion from merge approval and documented conservative legacy fallback.
Verification: shipped driver manual replay in disposable clone reproduced force dispatch and historical halt; raw records retained. Production unchanged.
Open questions: Is optional protected completion metadata sufficient? Does gating historical recovery without re-running postapprove/requires-test preserve required semantics? Is legacy fallback appropriate without unsafe inference? Are result/receipt identities kept honest? Check each issue's acceptance and ratings against source. Identify missing necessary safety cases, avoiding speculative expansion.

## ▶ TAKE YOUR TURN — codex
Read the plan, recon and relevant source (utils/py/marathon_drive.py, relay_attest.py, jog_run.py) directly. Review the whole relevant functions. Append a Reviewer block with Verdict Approved / Changes requested / Blocked, Basis, swept file: yes/no, graded cited findings, and Commit: none. On Approved set STATUS: Approved and NEXT: —; on Changes requested leave STATUS: Open and set NEXT: producer. Do not edit earlier text except header NEXT/STATUS/ROUND. Edit only this thread. Do not run git yourself; shim commits.
