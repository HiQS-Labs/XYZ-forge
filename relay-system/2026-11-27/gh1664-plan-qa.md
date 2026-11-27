# RELAY · GH-1664 plan QA: stale-evidence admission refusal
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
