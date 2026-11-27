# RELAY · GH-1664 plan QA: stale-evidence admission refusal
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 4 / 4

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

### Producer · Round 2 (claude-a)

Dispositions (plan revised; tagged R2):
- **B1 failed fetch — Implemented.** Verified that `swarm_preflight.py:1639–1641` makes `fetch_ok == 0` BLOCKED, and that `:1940–1943` maps that to exit 6. The plan now refuses before the lease with `stale-check-unavailable: fetch failed in <target>`. New G13 points the execution clone's existing `gh280.fixtureRemote` at a nonexistent path, so no git-stub change is needed. It expects that refusal with zero executions; restoring the remote then yields `stale-evidence:`.
- **B2 padded artifact — Implemented.** Verified that `swarm_preflight.py:1586–1593` strips artifacts. Artifacts are now `.strip()`ped and blanks dropped, while probe paths stay literal and unstripped. G9 lists `" src/feature.js "` with the probe on the unchanged path. The broad-glob risk note is rewritten.
- **S1 budget witness — Implemented.** G9 and the replay seed `attempt_count = 1`. The expected sequence is 1 at refusal, 1 after `jog retry`, then 2 after dispatch, so a `jog add` substitution (reset to 0) fails.
- **S2 refresh handoff — Implemented as documentation, plus the G10 witness.** Plan step 4 and the Conveyor/Jog skill text say the execution clone must carry the published capture before recovery: supervised runs align automatically, while a hand-supplied `--target-root` clone needs a pull or re-provision. `retry-build` refuses again on a stale clone, with the same reason. G10's positive proof runs on a fresh clone (`jog_run_root` re-provisions it).
- **S3 archived replay — Implemented.** The Day 1 control is not edited. It is copied to `TESTS-RESULTS/2026-11-27+GH-1664/control.txt`, the case kind is added there, and the source and copy sha256 go in the new provenance. The pre-existing Day 1 sha mismatch was already recorded by the GH-1476-holds provenance line, so it is not introduced here.
- **Pass notes — applied.** The missing-key skip is per capture. The effort rationale is updated; the score is unchanged.

Reviewer: round 3 of 4. Please re-review the revised plan, and include literal `VERDICT:` and `Basis:` lines.

### Reviewer · Round 3 (codex)

swept file: yes

**What this proposes.** Conveyor stamps the evaluated integration commit into the existing contract and rewrites it after re-grounding a capture. Jog compares the cited paths against its resolved target before leasing, parks stale rows, and lets a refreshed capture admit on the same queue row.

**How the existing system works, per this document.** Both Jog entry points already park held work before acquiring an attempt-consuming lease. Preflight can report an already-landed fix after leasing, and `jog retry` preserves spent attempts. My inference is that the new check must prove both that it saw the intended revision and that recovery dispatched a worker.

**What it's not.** The plan leaves queue schema, attestation, and command-probe dependencies outside scope.

- **[Blocker] Give G9–G10 one consistent attempt-count oracle.** **Observed input:** G9 requires `|0` at plan line 154 while lines 157–159 seed one spent attempt and require it to remain 1. G10 requires 1 at line 168 and 2 at line 160. The actual writers preserve 1 on park and retry and increment it to 2 on lease (`utils/py/releases_app.py:4963–4969,5096–5099,5124–5128`). The older expectations can reject a correct implementation and the G10 expectation of 1 can reward a reset. **Affected scope:** The paired G9–G10 proof for Acceptance 1, 2 and 4. **Falsifier:** Seed 1, park with 1 and no new execution, retry with 1, and dispatch with 2 on the same row and an approved receipt. That sequence must pass. Substituting `jog add` on the parked row must fail because it resets the same row to 0 (`utils/py/releases_app.py:4770–4773)). Correct both stale literals and keep G9–G10 on the same queue state while re-provisioning only the execution clone.
- **[Blocker] Make the plan's own contract runnable before its replay exists.** **Observed input:** The plan creates the replay copy during verification (lines 193–196) but lists it as an existing artifact at line 267 with no `artifacts_new` entry. The read-only command `ls -l TESTS-RESULTS/2026-11-27+GH-1664/control.txt` exited 1 with `No such file or directory`. Preflight records missing ordinary artifacts from the evaluated ref and makes a ready candidate NOT-READY (`utils/py/swarm_preflight.py:1586–1593,1727–1728,1940–1945`). Conveyor requires exit 0 before signalling readiness (`skills/1-hourly/conveyor/SKILL.md:103–107`). **Affected scope:** Admission of GH-1664 itself from an integration tree before the replay is created. **Falsifier:** With the implementation still absent and the replay missing, run the existing contract Preflight in the disposable clone. The missing future replay must cease to make it NOT-READY. If the lane writes the replay, use the existing `artifacts_new` subset with its matching `path_absent` probe (`utils/py/swarm_preflight.py:167–176,1554–1558`). If the producer retains it separately as verification evidence, omit it from the lane's build artifacts.
- **[Should] State which ref the manual run must bring current.** **Observed input:** Plan lines 95–104 compare the fetched `target.ref` and lines 129–134 promise a stale refusal from an old clone, but the actual contract at line 255 uses the local branch name `development`. Plain fetch updates the normal remote-tracking ref while the local branch stays put. The manual target check only verifies clone identity and ledger cleanliness (`utils/py/jog_run.py:542–557`); the align step that updates local `development` runs only for supervised dispatch (`:2758–2789,3048–3050`), and retry-build goes straight from its hold check to lease (`:1114–1124`). With local `development=A`, an A-stamped capture and fetched `origin/development=B`, admission and Preflight both evaluate A, and the evidence diff is empty even though B changed a cited path. G12 exercises `origin/main`, a tracking ref (plan lines 176–181). **Affected scope:** Stamped captures on manually supplied targets with a local branch ref that trails the fetched integration branch. **Falsifier:** Use G12's local fixture transport with `target.ref=main` and keep local `main=A` while fetch advances `origin/main=B`. A current-integration guarantee requires a named pre-lease refusal in that configuration. If the intended guarantee is against the declared local ref, explicitly require aligning that ref before both initial admission and retry-build and qualify the old-clone refusal claim. The aligned fixture at B must still refuse the A-stamped capture.
- **[Pass]** The R2 fetch and padding fixes are specified correctly (plan lines 95–114, 162–164, 182–186). G13 can control fetch through the existing clone-local fixture mapping (`test/gh280-jog-marathon-adapter.sh:83–99,543–556`). Both validators accept the optional key (`utils/py/swarm_preflight.py:61–93,132–153`, `utils/swarm-preflight.sh:165–194`). Skipping legacy captures individually preserves compatibility while leaving stamped siblings in scope (plan lines 73–91). Preflight exit 4 is an already-landed probe result (`utils/py/jog_run.py:648–651`); a missing stamp provides no evidence-freshness verdict.
- **[Pass]** A literal tree diff fits the stated contract-path and squash/merge scope (plan lines 109–118, 234–237). The capture union covers the prior selector mismatch and promotion path (`utils/py/jog_run.py:1687–1705,3091–3103`, `utils/py/swarm_preflight.py:1439–1446`). The second successful fetch leaves the explicitly accepted race for tracking refs (plan lines 95–104; `utils/py/swarm_preflight.py:1519–1521,1560–1584`). The plan uses the existing queue writer and does not need an additional lock or schema for the compared-ref guarantee.
- **[Pass]** The G10 receipt and artifact predicates distinguish actual dispatch from a Preflight-only park (`test/gh280-jog-marathon-adapter.sh:630–649`, `utils/py/jog_run.py:624–659`). Explicit `main` restoration covers cleanup's development-only behavior in section G (`test/gh280-jog-marathon-adapter.sh:230–236,543–558`). The replay copy and source/copy hashes resolve the prior archive-edit finding (plan lines 193–204); the historical Day 1 receipt mismatch remains the pre-existing one documented in round 2 and the holds provenance. The rating gives a plausible one-day effort estimate with no observed incident trend (plan lines 244–249).

VERDICT: FAIL
Basis: G9 and G10 still prescribe incompatible attempt counts, and the capture's contract would require its future verification replay before the lane can start. The ref handoff also needs an explicit precondition for manual targets. The whole-plan sweep found those issues alongside the previously recorded Day 1 provenance mismatch. G9–G13 and the replay are [Unverified — needs clone run]. Producer claude-a should revise the plan and return it for round 4 QA.

### Producer · Round 3 (claude-a)

Dispositions (plan revised; tagged R3):
- **B1 attempt-count oracle — Implemented.** G9 now expects `|1`, the seeded spent attempt, unchanged. G10 expects `attempt_count` 2 (seeded 1 plus this lease) and keeps the same queue state; only the execution clone is re-provisioned. G11–G13 start clean, so they explicitly expect their unchanged starting `0`. The sequence 1 → 1 (park) → 1 (retry) → 2 (dispatch) now matches the writers you cited, and a `jog add` reset to 0 fails it.
- **B2 future replay in contract — Implemented.** The replay copy is verification evidence the Producer writes, not a lane build artifact, so it is removed from `artifacts`. Read-back confirms that all six remaining artifacts exist at HEAD.
- **S1 local-branch ref precondition — Implemented as documented precondition.** Plan step 4 states that the check deliberately compares against the ref Preflight evaluates, which is the commit the builder will branch from. For a local-branch `target.ref` on a hand-supplied target, the operator must bring the local branch current first; a supervised run aligns it. Conveyor and the Jog skill will state this. No code change: comparing against a different ref than the one built from would itself be a parity bug, per R1 B2.

Reviewer: round 4 of 4 (final). Please re-review, and include literal `VERDICT:` and `Basis:` lines.

### Reviewer · Round 4 (codex)

swept file: yes

**What this proposes.** Conveyor records the integration commit used to prepare the capture and updates it after re-grounding. Jog compares the cited files before leasing, parks a stale row with the changed paths, and lets the refreshed capture use the same row.

**How the existing system works, per this document.** Jog checks holds before the attempt-consuming lease, and ordinary retry preserves the attempt count. Preflight runs after the lease and can report an already-landed fix. I infer that the recovery verb must be able to consume the refreshed capture in its published location.

**What it's not.** This is a contract-path admission check and refresh handoff. Queue state, review attestation, and command-probe dependencies remain outside its scope.

- **[Blocker] Route refreshed inbox captures through the verb that promotes them.** **Observed input:** The plan promises that either recovery verb re-admits the same row (plan lines 128–135 and 213–215), including packets that its stale refusal leaves in `1-INBOX` (lines 73–82 and 122–125). Conveyor may publish the refreshed canonical capture in `1-INBOX` (`skills/1-hourly/conveyor/SKILL.md:69,103–107`). The existing Day 1 control explicitly provides an inbox-only capture (`TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:229–233`). On that input, `jog retry-build` takes the lease and calls `run_marathon_phase` directly (`utils/py/jog_run.py:1114–1127`), which invokes `--gh-issue` (`:624–647`). Preflight only searches `2-WORKING` in that mode and exits 6 if the capture is missing there (`utils/py/swarm_preflight.py:1433–1446`). Only the normal run loop calls the promotion helper (`utils/py/jog_run.py:3081–3103`). So the advertised direct retry spends an attempt and parks again even with a fresh stamp. **Affected scope:** Same-row recovery for a refreshed capture still in `1-INBOX` with no working copy. **Falsifier:** Reuse the inbox-only fixture shape for the recovery witness. After the stale refusal leaves count 1 and the capture in the inbox, publish and consume the B-stamped inbox capture in a refreshed execution clone. Require `jog retry` plus `jog run` to promote and dispatch once at count 2 on the same row. Limit direct `retry-build` recovery and its positive smoke to captures already in `2-WORKING`.
- **[Should] State exactly what the compared ref establishes.** **Observed input:** Plan lines 135–141 describe the Preflight ref as the commit the builder will branch from. Preflight probes a detached worktree and stores the base ref as invocation metadata, while its Marathon argv has no starting revision (`utils/py/swarm_preflight.py:1229–1265,1560–1584`). Jog forwards that argv with policy overrides and does not add a starting revision (`utils/py/jog_run.py:497–523`). Marathon's protected-branch redirect uses checkout's current HEAD to create a new lane, or switches to the existing lane (`utils/py/marathon_drive.py:3365–3367,3421–3434`). G12 deliberately constructs an execution clone whose checkout can differ from its fetched `origin/main` (plan lines 184–189). **Affected scope:** Manual execution clones with HEAD or an existing lane base distinct from the ref evaluated by Preflight. **Falsifier:** Read the evaluated ref SHA and the actual starting SHA for a fresh lane on a fixture with distinct commits. They coincide only when the execution clone is appropriately aligned. Keep the guarantee tied to the evaluated ref, and document the manual checkout alignment needed to build from it. The supervised alignment cited here updates `development` specifically (`utils/py/jog_run.py:2770–2789`).
- **[Should] Give G13 its own pre-fix expectation.** **Observed input:** G13 requires a failed fetch to spend no attempt or execution (plan lines 190–194), while the explicit red list omits it and describes the red outcome as worker dispatch (lines 197–200). The actual base sequence spends an attempt and writes an execution, then Preflight reports BLOCKED on failed fetch and Jog parks without a worker call (`utils/py/jog_run.py:3081–3083,3113–3118,624–659`, `utils/py/swarm_preflight.py:1519–1521,1639–1641,1940–1943`). **Affected scope:** G13's proof that the fetch-error gate moved before the lease. **Falsifier:** With the fixture fetch unavailable and A still resolvable, the base must fail G13's count, reason, or ledger assertion with count 1 and a Preflight exit 6 record. The change must retain count 0, no execution record and the named admission refusal. Record both outcomes with the other case receipts.
- **[Pass]** R3 fixes the G9/G10 count inconsistency. The paired oracle is 1 on refusal, 1 after retry, and 2 after dispatch, with an approved receipt and an artifact assertion (plan lines 159–179, `utils/py/releases_app.py:4963–4969,5096–5099,5124–5128`, `test/gh280-jog-marathon-adapter.sh:630–649`). R3 also removes the future replay from the build contract (plan lines 201–204 and 268–275). The read-only command `python3 -c 'import json; from pathlib import Path; p=Path("PROJECT/1-INBOX/GH-1664-STALE-EVIDENCE-ADMISSION.md"); paths=json.loads(p.read_text().rsplit(chr(96)*3+"json\n",1)[1].split(chr(96)*3,1)[0])["artifacts"]; missing=[x for x in paths if not Path(x).is_file()]; print("artifacts",len(paths),"missing",missing); assert len(paths)==6 and not missing'` exited 0 with `artifacts 6 missing []`. This verifies worktree presence. The existing Day 1 hash discrepancy remains pre-existing, as recorded in round 2.
- **[Pass]** The capture union, per-capture legacy skip, padded-artifact normalization and fail-closed check address the earlier selector, compatibility and path findings (plan lines 73–118, `utils/py/jog_run.py:1687–1705`, `utils/py/swarm_preflight.py:61–93,257–282,1586–1593`, `utils/swarm-preflight.sh:165–194`). Comparing cited trees via native Git fits the stated scope. The window between successful fetches is explicitly accepted (plan lines 95–104).
- **[Nit]** The inbox status table still points to round 3 (plan lines 23–27). The capture lifecycle puts that table in the working doc (`PROJECT/PDDA.md:287–290`). Record current QA state in the capture frontmatter until promotion.

VERDICT: FAIL
Basis: Round 3's attempt-count and future-artifact blockers are resolved. The whole-plan sweep found a pre-existing difference between the two Jog verbs that makes the proposed inbox recovery fail after spending an attempt. The plan also overstates what branch base Preflight establishes and omits G13's distinct red oracle. The suite and replay remain [Unverified — needs clone run]. Round 4 exhausts the review cap. Producer claude-a should take the escalated handoff and correct the recovery handoff and verification plan before implementation.

### Producer · Round 4 (claude-a) — cap reached

Dispositions (plan revised; tagged R4):
- **B1 inbox recovery via retry-build — Implemented as a scoped recovery verb.** Verified that `jog_run.py:1114–1127` does not promote, while the run loop does (`:3091–3103`), and that Preflight `--gh-issue` only reads `2-WORKING` (`swarm_preflight.py:1433–1446`). The documented and witnessed stale-refusal recovery is now `jog retry N` + `jog run`. `retry-build` re-admits only a capture that is already in `2-WORKING`; that limit is pre-existing and applies to every retry-build, so it is out of scope (not changed).
- **S1 compared-ref claim — Implemented (wording).** The claim is narrowed to "the evidence matches the ref Preflight judged ready". The plan no longer says it is the commit Marathon branches from (`marathon_drive.py:3365–3367,3421–3434`).
- **S2 G13 red oracle — Implemented.** On base, G13 expects lease spent (count 1), an execution record, and `preflight-refused (exit 6)` with no worker call, so its assertions fail on base.
- **Nit status table — Implemented.** The frontmatter status and the table now record the cap state.

The review cap (4/4) is exhausted without Approved. Per the operator's instruction, the tie-break is a `/consult` (Codex + agy) on the amended plan. The relay closes as Escalated; the consult result is recorded in the capture and the closeout.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
