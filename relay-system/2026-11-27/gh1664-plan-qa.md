# RELAY · GH-1664 plan QA: stale-evidence admission refusal
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1664-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1664-STALE-EVIDENCE-ADMISSION.md` (the plan; sections "Plan", "Verification", "Non-goals", "Alternatives rejected", "Risks and rollback", "Rating"). This is PLAN QA: no production code exists yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: the plan, as written, would satisfy every box of the doc's `## Acceptance` (copied verbatim from issue #1664), extends the existing owners (`hold_refusal` pre-lease points in `utils/py/jog_run.py`, the capture's Swarm Preflight Contract, Conveyor refresh, `jog retry`) with no new queue/schema/daemon/suite, and its checks would actually detect the failure.

### Operational envelope
Local developer CLI (Jog supervisor over a local SQLite queue) in a single repo. Grade against the stated Acceptance, commensurate complexity, and this repo's AGENTS.md (notably *No new tests*, GH-831: editing an existing suite is allowed, a new suite file or `validate.sh` entry is a finding). Challenge over-building. Reviewer writes only this relay file.

### Step 1 — paraphrase first (GH-1414), before reading any source file
Read ONLY the plan doc first. Write 2–5 sentences under **What this proposes**, 2–5 under **How the existing system works, per this document**, and a short **What it's not**. Label inference. Then continue to step 2.

### Step 2 — source-backed validation
Read: issue text (in the doc's Acceptance), `utils/py/jog_run.py` (`hold_refusal` ~1663, `_jog_retry_build_locked` ~1098, the run loop ~3060–3090, `contract_probes_from_doc` ~1755), `utils/py/swarm_preflight.py` (`contract_shape_error` ~61, `extract_contract` ~96), `utils/swarm-preflight.sh` (~160–220 contract validation, ~623–640 ref resolution), `utils/py/releases_app.py` (`cmd_jog_retry` ~4938, `jog add` reset ~4755–4773, `jog_acquire_lease` ~5073, `jog_set_status` ~5106), `skills/1-hourly/conveyor/SKILL.md` (Steps 1, 3, 6), `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md` (line 32; build record ~486; R1/R2 ~217–320 for what is deliberately NOT adopted), `test/gh280-jog-marathon-adapter.sh` (fixture ~157–196, `prepare_execution_target` ~543, G section ~560–726), `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt`.

### Questions
1. Is every claim in "Observed problem" grounded at the cited `file:line`? In particular: does either contract validator (Python and the shell one in `swarm-preflight.sh`) reject an unknown top-level key like `prepared_commit`?
2. Is the "warn and admit when no `prepared_commit` is recorded" decision justified, or does it leave Acceptance 1 unprovable / let an unchanged, unfixed candidate be reported delivered? What prevents a stale packet that DOES record `prepared_commit` from being dispatched — where is the planned observed rejection (G9 / replay)?
3. Is `target.ref` (resolved in the execution target) the right "current integration ref" to diff against, consistent with what preflight evaluates right after the lease? Any case where the check and preflight would read different commits/docs (e.g. `find_issue_doc` vs preflight's first 2-WORKING match; 1-INBOX capture before promotion)?
4. Is the cited-path set (artifacts + artifacts_new + non-command probe paths) sufficient and not over-broad? Is `git diff --name-only <prepared> <ref_commit> -- <paths>` (tree diff) correct for squash/merge landings and globbed probe paths?
5. Refusal semantics: parking with the reason (same as `hold_refusal`) keeps `attempt_count`; refresh then `jog retry` + `jog run` (or `jog retry-build`) re-admits the same row with no `jog add`/reset. Is that the correct reading of "row stays pending/held … attempt count unchanged" and "same row admits … no duplicate row … attempt budget unchanged"?
6. Test honesty: would G9–G11 fail on the base `jog_run.py` (red) and pass after (green) for the right reason? Does moving fixture `main` (the contract's `target.ref`) and restoring it leak state into later sections given `cleanup_root_fixture`? Is adding a case kind to the Day 1 replay `control.txt` acceptable reuse, or a problem?
7. Surface-triggered: TOCTOU between the check (pre-lease) and preflight (post-lease) — is a commit landing between them a real gap worth addressing at this scale, or acceptable? Any native git capability being reinvented?
8. Is anything over-built or missing (DRY, no parallel writer, no new subsystem)? Is the rating 70/55/50/65 grounded?

Output: graded findings with `file:line` citations, the paraphrase sections, `swept file: yes|no`, VERDICT + Basis, and STATUS Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 (codex) — transcribed by the Producer

> Provenance: codex's round-1 review turn ran to completion, but the harness refused to commit it:
> `rtl_enforce: VALIDATION_FAILED exit=8` because the block had no `VERDICT:` line (stop receipt
> `turn-error`). The text below is copied verbatim from the codex transcript (sha256 prefix
> `7e32a10637c0f13f`). The Producer records the implied verdict as FAIL; the reviewer stated
> "Acceptance 1 and 2 unproven as written". This is not a Producer-authored review.

swept file: yes

**What this proposes.** Conveyor records the commit used to prepare the packet. Jog compares cited paths before leasing and parks stale packets for refresh and retry on the same row.

**How the existing system works, per the plan.** Jog runs hold checks before taking a lease, and `jog retry` preserves the attempt count. Preflight runs after the lease and can report the fix already landed. My inference was that both checks needed to use the same capture and evaluated commit.

**What it’s not.** The proposal leaves queue ownership, schema, and review attestation with their existing owners.

- **[Blocker] Use the capture that Preflight will consume.** **Observed input:** The Day 1 replay already creates two `2-WORKING` captures for GH-901 (`control.txt:212–219`). With two equally preferred candidates and no ledger tie-break, `find_issue_doc` returns `None` (`wave_reconcile.py:1129–1144`), so the proposed check skips (`GH-1664-STALE-EVIDENCE-ADMISSION.md:71–77`). Preflight still takes the first filename match (`swarm_preflight.py:1439–1446`), and existing hold handling explicitly documents the mismatch (`jog_run.py:1687–1698`). **Affected scope:** Multiple working captures, or an inbox capture whose promotion changes what Preflight selects. **Falsifier:** Give both working captures `prepared_commit=A` and the same cited file changed at B. Neither enumeration order may lease or dispatch the row. Reuse a shared selector, pass the selected document through, or park ambiguous candidates before leasing.
- **[Blocker] Check the revision Preflight actually evaluates.** **Observed input:** The plan resolves the locally visible ref before leasing (`GH-1664-STALE-EVIDENCE-ADMISSION.md:85–94`). Python Preflight fetches and *then* resolves the ref (`swarm_preflight.py:1519–1521,1560–1584`). For `target.ref=origin/development`, a local tracking ref at A can pass the check while Preflight’s own fetch advances it to B. This requires no simultaneous landing. Python Preflight also uses the execution root supplied by Jog, while the plan joins it with `target.repo` (`jog_run.py:644–647`, `swarm_preflight.py:1408–1418`). **Affected scope:** Fetchable tracking refs and contracts whose `target.repo` differs from `.`. **Falsifier:** In the existing fixture, put `origin/development` at A in the execution clone and B in its local fixture remote before invoking Jog. A cited change at B must park with zero attempts and zero worker calls. Specify how admission and Preflight share the repository root and resolved revision.
- **[Blocker] Prove dispatch after refresh.** **Observed input:** G10 accepts attempt count 1, one execution, and any reason outside `stale-evidence` (`GH-1664-STALE-EVIDENCE-ADMISSION.md:122–125`). Jog writes the execution before calling Preflight and retains it on refusal (`jog_run.py:624–659`). A Preflight refusal can satisfy those predicates. **Affected scope:** G10 and the same-row recovery witness. **Falsifier:** Remove the runnable capture after retry. The recovery assertion must fail even though a lease and execution record exist. Assert the same `global_id`, exactly one worker call or an equivalent positive G4 receipt, and the expected attempt transition.
- **[Should] Keep the fixture and replay evidence discriminating.** Prepare A/B on the primary fixture before cloning it, or invoke Jog directly after preparing the target. `jog_run_root` recreates the execution clone, and primary cleanup resets `development` while leaving an advanced `main` ref in place (`test/gh280-jog-marathon-adapter.sh:230–236,543–556,610–614`). Explicitly restore any primary `main` movement and prove the base run reaches the worker in G9/G11. For replay reuse, propagate assertion failure as nonzero and count the refresh calls. The old control prints `FAIL` without exiting there, and its refresh line only checks that the call log exists (`control.txt:303–328`). The existing suite plus retained provenance can provide the proof without a second wrapper.
- **[Should] Define cited paths using the consumer’s semantics.** The planned Git pathspec expansion contradicts Python Preflight’s literal path handling (`GH-1664-STALE-EVIDENCE-ADMISSION.md:90–94`, `swarm_preflight.py:257–282`). For example, `grep_present` on `src/*.js` checks a literal filename in Preflight while Git can match ordinary `.js` files. Use normalized literal paths for those probes, and handle `artifacts_new` as the existing subset of `artifacts` (`swarm_preflight.py:167–176`). A tree diff is appropriate for comparing cited content across squash and merge histories.
- **[Pass]** Both validators accept an unknown `prepared_commit` key (`swarm_preflight.py:61–93`, `swarm-preflight.sh:165–194`). Parking and `jog retry` preserve the row and attempt count, while the lease increments it and `jog add` can reset it (`releases_app.py:4770–4773,4967–4969,5096–5099,5124–5128`). The missing-key warning is a reasonable compatibility choice if the plan explicitly limits the freshness guarantee to packets recording a SHA. Preflight’s already-landed probe verdict is separate from evidence freshness (`jog_run.py:648–651`).

**Basis:** The static contradictions above leave Acceptance 1 and 2 unproven as written. The source sweep also found the pre-existing capture-selection mismatch described above. Suite and replay behavior remain **[Unverified — needs clone run]**. With the plan corrected, Producer `claude-a` should return it for Reviewer QA.

VERDICT: FAIL (recorded by the Producer from the reviewer's Basis; the reviewer's block omitted the line)

### Producer · Round 1 (claude-a)

Dispositions (plan revised in `PROJECT/1-INBOX/GH-1664-STALE-EVIDENCE-ADMISSION.md`; each change is tagged R1):
- **B1 capture selection — Implemented.** Verified: `swarm_preflight.py:1439–1446` takes the first 2-WORKING glob match, and `hold_refusal` already enumerates the union (`jog_run.py:1687–1698`). The plan now extracts that enumeration into `_admission_captures` (a pure extract; hold behaviour unchanged) and refuses if ANY capture is stale or unavailable.
- **B2 root/revision parity — Implemented.** Verified: Preflight fetches (`swarm_preflight.py:1519–1521`), then resolves `target.ref` in the execution root (`:1560–1561`), and ignores `target.repo` (`:1412–1418`; Jog passes `SWARM_PREFLIGHT_ROOT=target` at `jog_run.py:644–647`). The plan now uses `target` only and runs the same tolerant fetch first, but only for captures recording `prepared_commit`. New case G12 (`target.ref=origin/main`, B only on the fixture remote, no re-clone) is your falsifier.
- **B3 positive dispatch — Implemented.** G10 now asserts the same `global_id`, one row, attempt 1, exactly one execution with `outcome=="approved"`, the row `awaiting-landing (PR #42` as in G4, and the builder's artifact present. The replay counts refresh worker calls from the append-only log and asserts exactly 1.
- **S1 fixture discipline — Implemented.** A/B commits are made in `$FR` before the re-clone; `main` is restored after each case; the red run proves base reaches the worker. The replay exits nonzero on failure for this case kind; the wrapper script is dropped (provenance records the commands).
- **S2 literal cited paths — Implemented.** `:(literal)` pathspecs; `artifacts` already contains the `artifacts_new` subset (`swarm_preflight.py:167–176`).

Reviewer: please re-review the revised plan (round 2). **Your block must include a literal `VERDICT: PASS|FAIL|PARKED` line and a `Basis:` line**, or the harness refuses it again (exit 8).

### Reviewer · Round 2 (codex)

swept file: yes

**What this proposes.** Conveyor records the integration commit used to prepare a packet. Jog checks the contract’s cited paths against its target ref before acquiring a lease and parks the row if the evidence changed. Refreshing through Conveyor lets the operator retry the same row.

**How the existing system works, per this document.** Jog already parks held rows before leasing, and retry preserves their attempt count. Preflight evaluates the contract after the lease and can report that a fix has already landed. I infer that comparing the same capture and ref Preflight evaluates is necessary for the admission check to be meaningful.

**What it’s not.** The scope is a pre-lease check for contract paths and a documented Conveyor refresh.

- **[Blocker] Make failed fetches a pre-lease refusal.** **Observed input:** `GH-1664-STALE-EVIDENCE-ADMISSION.md:94–103` both tolerates a failed fetch and promises to refuse if Git fails. For a stamped contract with `prepared_commit=A`, cached `origin/main=A`, and remote `main=B`, a nonzero fetch can leave a resolvable A and an empty diff. Preflight catches the fetch exception to report it, then explicitly classifies the candidate BLOCKED, exit 6 (`swarm_preflight.py:1519–1521,1639–1641,1940–1943`). That is already after the lease and execution write (`jog_run.py:3081–3083,3113–3118,624–647`). **Affected scope:** Stamped packets whose admission fetch fails while the target ref still resolves. **Falsifier:** Adapt G12 to make the existing Git shim return nonzero on the admission fetch while the clone still sees A. Expect `stale-check-unavailable: fetch …`, zero leases and no Preflight execution. Restore the shim and rerun to expect `stale-evidence:` at B. State the nonzero-fetch rule explicitly. This case can be forced by the local stub without a live outage or competing processes.
- **[Blocker] Compare the artifact path Preflight reads.** **Observed input:** Given `artifacts: [" utils/py/jog_run.py "]` and a non-command probe on another unchanged file, the validator accepts the nonempty string and Preflight strips it before its existence check (`swarm_preflight.py:80–85,1586–1593`). The plan passes the raw string to `:(literal)` (`GH-1664-STALE-EVIDENCE-ADMISSION.md:104–109`), so the pathspec can miss a change to `utils/py/jog_run.py`. Read-only worktree probe `python3 -c 'from pathlib import Path; a=" utils/py/jog_run.py "; print(Path(a.strip()).is_file(), Path(a).is_file()); assert Path(a.strip()).is_file() and not Path(a).is_file()'` exited 0 with `True False`. **Affected scope:** Stamped contracts with padded artifact strings whose trimmed paths changed. **Falsifier:** In G9, pad the artifact string, keep the probe on a different unchanged path, and change only the unpadded artifact. Expect the same named-path refusal and zero attempts. Mirror the artifact normalization and keep probe paths literal as Preflight does. Update the conflicting broad-glob note at plan lines 206–207.
- **[Should] Make recovery evidence detect an attempt reset.** **Observed input:** G10 and the replay start from attempt 0 (`GH-1664-STALE-EVIDENCE-ADMISSION.md:140–152,167–175`). The existing `jog add` path for a parked row updates that same row in place and resets `attempt_count` to zero (`releases_app.py:4755–4773`), so same ID, one row, one dispatch and final attempt 1 can all pass after the forbidden reset. **Affected scope:** The Acceptance 2 claim about preserving the spent attempt budget. **Falsifier:** Seed one prior attempt in one existing proof, assert 1 on refusal and immediately after retry, then 2 after the worker call. Substituting `jog add` in that proof must fail the count assertion.
- **[Should] Give the refreshed capture an explicit path into the execution clone.** **Observed input:** The documented sequence is publication followed by `jog retry N` or `jog retry-build N` (`GH-1664-STALE-EVIDENCE-ADMISSION.md:120–123`). Conveyor publishes to integration (`skills/1-hourly/conveyor/SKILL.md:105–109`), `jog retry` only updates the queue row (`releases_app.py:4963–4974`), and retry-build reads the supplied clone before the lease without aligning its checkout (`jog_run.py:1083–1093,1114–1124`). A clone retaining the A-stamped capture can refuse again after publication of the B-stamped capture. **Affected scope:** Same-row recovery with an execution clone created before refresh publication, especially retry-build. **Falsifier:** Keep that clone at the old capture while the local fixture remote publishes the refresh. Expect the stale refusal to remain there and the same row to dispatch when pointed at a fresh clone with the published capture. Document that handoff and attach the positive proof to the updated clone.
- **[Should] Preserve the archived replay receipt.** The plan edits the Day 1 control in place (`GH-1664-STALE-EVIDENCE-ADMISSION.md:167–175,237`). Its historical receipt pins SHA-256 `6dcaf91b6f4b526dfd20acebfc844ba857e014c4bd43f1f69a001d27562d5745` (`TESTS-RESULTS/2026-11-25+GH-1476-day1/provenance.jsonl:1`), but `shasum -a 256 TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt` already exits 0 with `104e552ee829ab9647dcffdc7a5fc8a8fc41c481e730a2c9428a5f9f4d03c33a`. Keep the new proof reproducible under GH-1664 provenance. The existing suite can supply the stale and recovery witness, or adapt the replay in the disposable clone and retain that exact input with the new receipt.
- **[Pass]** The capture union covers the previously missed first working match and an inbox document before Jog promotes it (`GH-1664-STALE-EVIDENCE-ADMISSION.md:73–83`, `jog_run.py:1687–1705,3091–3103`, `swarm_preflight.py:1439–1446`). Make the missing-key skip local to each capture so a legacy sibling cannot end the scan. Both contract validators tolerate the optional key (`swarm_preflight.py:61–93,132–153`, `swarm-preflight.sh:165–194`). This compatibility choice scopes the new guarantee to stamped packets.
- **[Pass]** G12 can use the fixture's existing fetch routing to `$FR` (`test/gh280-jog-marathon-adapter.sh:83–99,543–556`). Explicit `main` restoration covers the cleanup asymmetry (`:230–236`). G10's approved receipt and artifact assertion follow G4 and exclude Preflight-only parks (`:630–649`, `jog_run.py:624–659`). A tree comparison fits cited content across squash or merge histories. Comparing before the lease leaves the documented window between two successful fetches (`GH-1664-STALE-EVIDENCE-ADMISSION.md:94–99`), a bounded tradeoff for this plan. The plan uses existing owners, and the rating records the impact, priority, neutral appeal and uncertainty. Update the effort rationale at lines 214–219 to reflect four proposed suite cases and the replay.

VERDICT: FAIL
Basis: The revised plan resolves the capture-selection and positive-dispatch findings, but a failed fetch can still spend an attempt, and the proposed literal artifact comparison can miss a cited change. The budget witness, refresh handoff and replay provenance also need correction. The sweep found the pre-existing Day 1 receipt mismatch. Runtime suite and replay results are [Unverified — needs clone run]. Producer claude-a should revise the plan and return it for Reviewer QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
