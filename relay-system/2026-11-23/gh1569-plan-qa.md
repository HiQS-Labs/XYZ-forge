# RELAY · GH-1569 plan QA (build_queue daily-goals checklist-only)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1569-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md` (the PLAN, no code written yet).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Operational envelope: a ~540-line local developer CLI script (`skills/1-hourly/kickstart/scripts/build_queue.py`),
  read-only, run by an operator at kickstart launch. Grade against the stated requirements and commensurate
  complexity; this repo forbids new test suites (AGENTS.md "No new tests", GH-831), so a request for a new
  `test/` file, `validate.sh` entry or gate machinery is itself out of scope. Verification is by manual
  red/green under `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl`.
- Requirements (the issue, https://github.com/HiQS-Labs/XYZ-forge/issues/1569): when the daily-goals issue body has a
  task list, admit only numbers on unchecked `- [ ]` lines (a checked `- [x]` line and prose are not admitted). ONE lead
  number per checklist line: the FIRST `#N` on the line is the item, later `#N` on that line are references. A body with no
  task list must behave exactly as today OR fail closed (pick the smaller, state it, prove it). Also handle any other
  readers of that body. Red: replay #1568's ORIGINAL body (before its 2026-11-20 edit) through `--daily-goals-json`:
  #1480/#1483 queued and #1537 in Needs-the-operator on base; green: they are not. Also prove #1568's CURRENT body still
  yields its 7 items and that checklist lines carrying nested refs such as `(GH-…)` or `after #N` behave as stated.
- Evidence already in the repo (committed): `TESTS-RESULTS/2026-11-23+GH-1569/` (inputs, `run.sh`, red output on base).

## Definition of Done (for THIS plan review)

STEP 1 — before opening any file other than the plan, write under headings, 2-5 sentences each:
**What this proposes**, **How the existing system works, per this document**, and (short) **What it's not**.
Ground exclusions in the plan's sections; label inference and missing boundaries rather than inventing non-goals.
Quote this paraphrase as the first part of your review block and state its input boundary ("plan only").
STEP 2 — then read the requirements above and the source (`build_queue.py` lines 86-110, 259-279, 435-510; `SKILL.md`
302-308; the red output) and label the rest of your review "source-backed". If your STEP 1 paraphrase mismatches the
plan, say whether the plan failed to explain it or you misread.

Questions (cite `file:line`; findings graded per the protocol above):
1. Is the plan grounded in the actual code? In particular, is `parse_daily_goals_refs` really the ONLY reader of the
   daily-goals body that can admit numbers? Name any other reader the plan missed (check `main()` and `parked_issues`).
2. What prevents an unchanged, unfixed `build_queue.py` from being reported as delivered, and where is the observed
   rejection? Is the red (original-body replay) a real discriminator, and do acceptance rows 3-7 each fail on base?
3. Is the decision for no-task-list bodies (keep today's behaviour rather than fail closed) justified as the smaller
   option, and is the proof (byte-identical replay vs base) sufficient?
4. Edge cases of "task list" detection and the lead-ref rule: indented/nested checkboxes, `+` and `1.` bullets,
   `- [ ]` with no ref, lead ref foreign-repo or self, `- [X]` upper-case, sanitized backtick refs. Does the plan define
   each, or leave a bug? Give a concrete input if you claim a defect.
5. Is the change surgical and DRY (extends `parse_daily_goals_refs`, no second parser, no new flag/test/suite)?
6. Are the risks/rollback and the SKILL.md update adequate? Is anything over- or under-engineered?

Write the verdict (PASS / FAIL) with a Basis; include a literal `swept file: yes|no` line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
