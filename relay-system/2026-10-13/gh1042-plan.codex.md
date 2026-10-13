# RELAY · GH1042 + GH1045 repair plan
NEXT: —
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

## Round 1 · Reviewer · codex

Verdict: Approved
Basis: textual plan QA against the seeded plan, recon, retained baseline JSON/provenance, and direct source; this approves implementation of the plan, not runtime correctness or merge readiness.
Swept file: yes — entire canonical plan, including per-issue acceptance, authority, rollback, implementation order, verification and ratings.
Commit: none.

### Graded findings

- [Pass — plan] GH1042's proposed ordering and bounded token family address both observed causes: force allocation currently replaces the base identity before satisfaction (utils/py/marathon_drive.py:1416), while completed_relay_task accepts only numeric derivatives (utils/py/marathon_drive.py:2791). Plan steps 1 and 6 preserve explicit retry and require base/numeric/force coverage; moving allocation must keep result, heartbeat and seed identities consistent with the selected token.
- [Pass — plan] GH1045 needs a completion fact distinct from current merge eligibility. The optional protected field, validated against the existing loaded approval and historical candidate, is a proportionate extension of relay_attest.write/load/candidate_ok (utils/py/relay_attest.py:197,216,301). Plan lines 55–64 require ancestry, phase/lane identity, malformed-record refusal, strict missing-field fallback and no stamp refresh. This deliberately cannot rescue an already-diverged legacy run without an explicit rebuild; the limitation is honest and avoids trusting workspace results.
- [Pass — plan] Skipping requires-test and post-approve is justified only for validated completed recovery: current complete_phase_success reruns both and binds the candidate again after post-approve (utils/py/marathon_drive.py:2668). Plan steps 3–4 place the initial stamp after those obligations and retain current acceptance/gate checks plus recovery-drift refusal. Failed or unstamped completion must retain the strict path, as specified.
- [Pass — plan] Historical reviewed_candidate and observational head_sha must remain distinct, with no newly fabricated review/QA receipt (plan step 5). Jog already compares the PR head to expected_candidate and then calls unchanged candidate_ok before SHA-bound merge (utils/py/jog_run.py:1430); preserving this prevents a historical completion from authorizing an unreviewed successor. Existing result receipt lookup at utils/py/marathon_drive.py:200 must also remain truthful when implementing step 5.
- [Unverified — needs clone run] No implementation, gate, fixture or runtime probe was executed in this reviewer turn. Retained baseline-results.json reports force dispatch exit 7, historical refusal exit 4, and explicit-retry dispatch exit 7; these are producer evidence, not an independently repeated run. Plan line 70 provides the necessary refusal, recovery and two-phase traversal controls; final QA must inspect their committed provenance and exact candidate revision.
- [Informational — evidence limit] Ratings arithmetic is consistent (275 and 260), and the stated severity matches recoverable rebuild/halt consequences rather than data loss (plan line 76). Live issue status, duplicate-search exhaustiveness and RELEASES read-back were not independently re-queried; this review does not attest those external/current-state claims.
- [Informational — graph limit] list_projects returned no index for this relay worktree. The queried XYZ-forge index belongs to the primary checkout, generation 2026-09-01T15:54:30Z; coverage reports changed metadata for marathon_drive/jog_run and not-tracked relay_attest, with a partial shell range at line 351. Graph search returned no relay_attest symbols. Accordingly, source conclusions above use direct current-worktree reads of the relevant complete helpers, success/recovery closures, Jog merge consumer, and shell traversal, including the flagged shell range; no completeness claim rests on that stale graph.

No blocking plan finding. Production implementation and its disposable-clone verification remain pending.

### System · relay-drive — 2026-10-13T15:32:46Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
