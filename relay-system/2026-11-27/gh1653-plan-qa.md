# RELAY · GH-1653 plan QA - jog books receipt-publication attempt
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
6. **Manual relay: commit only the relay file** (`relay(gh1653-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1653-JOG-RECEIPT-ATTEMPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: the plan's "Requirements" 1-4 (issue #1653 + ledger #1657) are each met by the plan, each with a falsifiable check that rejects the unchanged base.

### Review packet (plan QA, round 1)

**Paraphrase first (GH-1414).** Before reading anything except the plan, write 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not**. Distinguish excluded work, deferred work and unresolved choices; label inference. Record this paraphrase as the first part of your review block, then continue with the source-backed assessment (label it "source-backed").

**Operational envelope.** Local developer/agent CLI (Jog queue supervisor, Python) in a single repo, publishing to the canonical GitHub remote through the repo's own pre-push gate. Grade against the stated requirements, commensurate complexity, and the repo's rules: AGENTS.md "No new tests" (GH-831: no new suites or `validate.sh` registry entries; a focused case added to an existing suite that already covers the path is allowed when nothing covers it), the #1399 attempt-accounting design (`utils/py/rtl.py`, `utils/py/gate_receipt.py`), never weakening the gate, never renaming a task to escape an exhausted budget. Do not ask for speculative machinery (new attempt kinds, locks, journals, schedulers).

**Read:** the plan (`.relay-artifacts/GH-1653-JOG-RECEIPT-ATTEMPT.md`), `utils/py/jog_run.py` (`publish_jog_receipt`, its three callers in the wake ≈L700-730, `jog_resume` ≈L775-830, gate-only retry ≈L1040-1070, `_git`), `utils/py/gate_receipt.py` (`attempt_admission`, `main()` attempt-start/attempt-finish), `utils/py/rtl.py` (`lane_attempt_reserve`, `lane_attempt_row`, `lane_attempt_finish`, `archive_lane_attempts`), `utils/py/relay_attest.py` (`candidate_ok`, `source_matches`), `githooks/install.sh` (`_attempt_guard`), `githooks/pre-push` L60-100, `utils/py/marathon_drive.py` `lane_attempt_gate`, `test/gh280-jog-marathon-adapter.sh` (fixture setup, `prepare_execution_target`, section G4, P2 near L1368).

**Questions (cite file:line):**
1. Is every claim in the plan's Recon table grounded in the actual paths? Is any entry wrong or missing — in particular, is it true that the Marathon lane's attested reservation cannot admit the receipt commit?
2. Will a reservation booked by `lane_attempt_reserve(kind="manual")` on the lane branch before the evidence commit be admitted by `attempt_admission` for the push of that commit (HEAD == sha, start_sha ancestor, branch match), from all three call sites including `jog resume` where the commit may already exist?
3. Retry/restart honesty: does the plan keep consumed attempts across a failed push, a crash between booking and finishing, and a new process (`jog resume`)? Can anything in it reset or rename the budget? Is the fixed key `GH-<n>-jog-publish` the right identity, and is drawing from `LANE_MAX_ATTEMPTS` (default 2) correct?
4. What prevents the unchanged base from being reported as fixed — is the G4 hook (real `gate_receipt.py admit` per pushed ref) a faithful stand-in for the installed gate's admission step, and does the red control on base `52813e56f` actually observe the Day 3 refusal? Is the negative control (plain unreserved push refused) meaningful?
5. Side effects: `rtl.lane_attempt_reserve` sets `os.environ[XYZ_ATTEMPT_CONTEXT]`; is the plan's restore sufficient so the next lane's Marathon dispatch or later Jog pushes do not inherit a stale context? Does Marathon's own push or `_require_gate_wired` interact badly?
6. Does extracting `manual_attempt_start/finish` out of `gate_receipt.main()` keep the CLI byte-for-byte compatible, and is that refactor justified versus Jog shelling out to the CLI?
7. Test honesty: does the G4 hook exercise the real seam (not mock it away)? Does the new booking conflict with gh280 P2 ("jog never ... writes executor attempt state")? Is any proposed assertion unnecessary?
8. Is anything over- or under-built? Flag missing requirements (e.g. should `run_record.py checkpoint --push` be in scope per #1653?) and justify.

Write your verdict below and change STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
