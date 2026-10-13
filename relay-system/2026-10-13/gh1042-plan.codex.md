# RELAY · GH1042 + GH1045 repair plan
NEXT: —
STATUS: Approved
ROUND: 3 / 3

## Setup
Producer: Codex outer session. Reviewer: independent Codex CLI via shipped relay.
Artifact: PROJECT/2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md
Recon: PROJECT/2-WORKING/recon-phase-recovery.md
Evidence: TESTS-RESULTS/2026-10-13+GH-1042/baseline-results.json and provenance.jsonl
Task: RELAY-GH1042-PLAN-20261013
Operational envelope: local single-user harness; preserve GH505 isolation/approval and strict Jog merge checks. No enterprise threat model, new suites, registry, controllers or migration framework. Grade actual requirements and commensurate complexity. Reviewer edits ONLY this relay thread, no production edits, commits, pushes, gates or test/*.sh in this valued clone. Reading source/manual evidence is allowed. Plan-only approval basis is textual; no runtime claim.

## Log

### Round 1 · Producer
Did: traced current lifecycle, recorded real baseline failures, separated historical completion from merge approval and documented conservative legacy fallback.
Verification: shipped driver manual replay in disposable clone reproduced force dispatch and historical halt; raw records retained. Production unchanged.
Open questions: Is optional protected completion metadata sufficient? Does gating historical recovery without re-running postapprove/requires-test preserve required semantics? Is legacy fallback appropriate without unsafe inference? Are result/receipt identities kept honest? Check each issue's acceptance and ratings against source. Identify missing necessary safety cases, avoiding speculative expansion.

## ▶ TAKE YOUR TURN — codex
Read the plan, recon and relevant source (utils/py/marathon_drive.py, relay_attest.py, jog_run.py) directly. Review the whole relevant functions. Append a Reviewer block with Verdict Approved / Changes requested / Blocked, Basis, swept file: yes/no, graded cited findings, and Commit: none. On Approved set STATUS: Approved and NEXT: codex (Reviewer); on Changes requested leave STATUS: Open and set NEXT: producer. Do not edit earlier text except header NEXT/STATUS/ROUND. Edit only this thread. Do not run git yourself; shim commits.

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

### Round 2 · Producer
Scaffold correction: original reviewer output was substantively Approved but shim exit8 rejected missing ## Log. That turn does not qualify plan QA. No production changes.
Verification: baseline replay unchanged; source tree unchanged.

## ▶ TAKE YOUR TURN — codex (round 2)
Review the same committed plan and source again. Append `### Round 2 · Reviewer · <timestamp>` under this Log, with `**Verdict:** Approved / Changes requested`, `**Basis:** textual only`, `swept file: yes/no`, cited findings and `**Commit:** none`. Set STATUS and NEXT as appropriate and mark tick token done on approval. Edit only this thread; no git or tests. Prior verdict was rejected by harness, not accepted QA.

### Round 2 · Reviewer · 2026-10-13T15:35:09Z

**Verdict:** Approved
**Basis:** textual only
swept file: yes — the entire canonical plan and recon, with direct reads of the relevant attestation, completion/recovery, force allocation, result and Jog merge paths.
**Commit:** none

- [Pass — plan] The two defects require both token ordering and a distinct historical completion fact. Force allocation currently changes the default token before satisfaction (utils/py/marathon_drive.py:1416); completed_relay_task accepts only numeric derivatives (utils/py/marathon_drive.py:2791). Plan steps 1–2 address both without relaxing explicit retry. Preserve one selected identity across heartbeat, seed and result when moving allocation.
- [Pass — plan] Protected optional completion metadata reuses the existing atomic publication and validated approval reader (utils/py/relay_attest.py:197,216). The plan requires phase/lane and review binding, ancestry, unchanged candidate_ok at the historical candidate, malformed-record refusal, strict missing-field fallback and replacement on fresh approval. This is sufficient for the stated local trust model; legacy completion already followed by source drift deliberately still requires explicit rebuild.
- [Pass — plan] Completion must be stamped only after required-test and post-approve checks. The current success closure reruns these and binds the candidate again after post-approve (utils/py/marathon_drive.py:2668). Plan steps 3–4 correctly distinguish completed historical recovery from merely approved or failed completion, keep current acceptance/gate checks, reject recovery-induced source drift and never advance the old stamp. The mid-relay already-satisfied path (utils/py/marathon_drive.py:3401) must retain initial-completion obligations unless a validated stamp actually exists; a shared success_mode label alone is insufficient.
- [Pass — plan] Result and receipt honesty is explicitly required in step 5. Historical reviewed_candidate must stay distinct from observational head_sha, including the existing receipt-path lookup (utils/py/marathon_drive.py:200). Jog loads the attestation and passes reviewed_candidate to the merge boundary (utils/py/jog_run.py:414); that boundary compares actual PR head and applies unchanged candidate_ok before SHA-bound merge (utils/py/jog_run.py:1430). Thus historical phase satisfaction does not authorize merging an unreviewed successor.
- [Unverified — needs clone run] No runtime probe, suite, executable fixture or gate was run in this turn. Producer baseline-results.json records force dispatch exit 7, historical refusal exit 4, and explicit-retry dispatch exit 7; provenance.jsonl attributes its manual replay to b9f07ea5b8d95bac62a3ed9f886770fee883030f. These are retained producer observations, not independently repeated evidence. Plan step 6 and its control list remain required, including failed completion, two-phase traversal, identity and mutation refusals, plus final independent QA and exact-revision gate.
- [Informational — evidence limits] Verify-tier graph inventory was fully paginated (84 projects); this worktree is not indexed. XYZ-forge coverage is generation 2026-09-01T15:54:30Z in the primary checkout, with changed marathon_drive/jog_run metadata, untracked relay_attest, and partial shell line 351. Conclusions use current-worktree source instead, including that shell range and traversal at relay-automation/marathon.sh:583. No exhaustive graph or live GitHub/RELEASES-state claim is made. Ratings sums 275 and 260 are internally consistent; external read-back remains producer evidence.

No blocking plan finding. Approval authorizes the stated implementation plan only; runtime correctness and merge readiness remain pending.

### System · relay-drive — 2026-10-13T15:35:16Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted

### Round 3 · Producer
The second textual approval also failed structural validation: the deployed runtime requires a literal machine verdict PASS/FAIL/PARKED, while the skill template asks Approved/Changes requested. Both failures are retained, neither is accepted QA. No production change. This is the final plan-QA round (3/3).
Verification: read bin/validate-relay-block: ## Log plus a last `VERDICT: PASS` (or FAIL/PARKED) and nonempty Basis are mandatory.

## ▶ TAKE YOUR TURN — codex (round 3, authoritative current instructions)
Review the same actual plan and source with prior textual findings as leads. Append a Round 3 Reviewer block. To approve, set header STATUS: Approved and NEXT: —, and write EXACTLY `VERDICT: PASS` plus `Basis: textual only — <actual source checked>` in your new block. Use literal `VERDICT: FAIL` for Changes requested, or `VERDICT: PARKED` for blocked. Do NOT write any subsequent verdict line with value Approved; that spelling fails the machine parser. State swept file: yes/no and cited findings. Include Commit: none. Only edit this relay thread; no git, suites or production edits. Mark token done if Approved. Three-round budget is binding.

### Round 3 · Reviewer · codex

VERDICT: PASS
Basis: textual only — entire canonical GH1042/GH1045 plan and recon; current relay_attest.py including write/load/candidate_ok; marathon_drive.py force allocation, completion, startup and mid-relay recovery; Jog attestation consumer and complete _merge_reviewed_pr; shell phase traversal; retained baseline JSON/provenance.
swept file: yes
Commit: none

- [Pass — plan] Steps 1–2 address distinct defects: force allocation precedes satisfaction (utils/py/marathon_drive.py:1416), and completed_relay_task currently accepts only numeric derivatives (utils/py/marathon_drive.py:2791). Resolve against the original family before allocation, retain explicit retry, and propagate the selected token consistently into result/heartbeat/seed. Shell traversal already limits explicit retry to its target (relay-automation/marathon.sh:608).
- [Pass — plan] The protected optional completion field extends existing atomic publication and validated approval loading (utils/py/relay_attest.py:197,216), without changing candidate_ok (utils/py/relay_attest.py:301). Plan steps 2–3 require historical candidate validation, ancestry, phase/lane and review binding, plus successful initial obligations before stamping. Missing-field strict fallback, malformed refusal, replacement on fresh approval and inert rollback are proportionate to the stated local trust boundary.
- [Pass — plan] Step 4 must distinguish a validated completion stamp from an already-satisfied mode label: the mid-relay path can obtain its first approval (utils/py/marathon_drive.py:3401). The plan correctly permits skipping required-test/post-approve only after actual completed history, retains current acceptance/gate checks, rejects recovery-induced source drift and never refreshes the historical stamp. Initial completion must still satisfy the full closure at utils/py/marathon_drive.py:2668.
- [Pass — plan] Step 5 preserves the distinction between historical reviewed_candidate and observational head_sha. Review implementation of both receipt publication and existing receipt lookup (utils/py/marathon_drive.py:200,2742) against that requirement. Jog loads the approval at utils/py/jog_run.py:414 and its merge function at utils/py/jog_run.py:1430 requires actual PR-head equality, unchanged candidate_ok and SHA-bound merge. Historical phase recovery therefore need not weaken merge eligibility.
- [Unverified — needs clone run] No runtime probe, suite, fixture or gate was executed. Retained baseline-results.json reports force dispatch exit 7, historical refusal exit 4, force-family dispatch exit 7 and explicit-retry dispatch exit 7; provenance.jsonl attributes these producer observations to b9f07ea5b8d95bac62a3ed9f886770fee883030f. These are not independently repeated measurements. Plan step 6 and its refusal/mutation/two-phase controls, exact-revision gate and final independent implementation QA remain required.
- [Informational — evidence limits] Verify-tier inventory returned all 84 projects with no index for this worktree. XYZ-forge coverage reports generation 2026-09-01T15:54:30Z, changed marathon_drive/jog_run metadata, untracked relay_attest and partial marathon.sh line 351; relay_attest graph search returned zero symbols. Current source was read directly, including the flagged shell range. No completeness claim relies on the stale graph. Ratings sums 275/260 are consistent; live issue/duplicate/RELEASES assertions remain producer evidence.

No blocking textual plan finding. This approval covers the implementation plan only; implementation correctness and merge readiness remain pending.
