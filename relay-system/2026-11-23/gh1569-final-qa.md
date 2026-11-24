# RELAY · GH-1569 final QA (build_queue daily-goals checklist-only)
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
6. **Manual relay: commit only the relay file** (`relay(gh1569-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/kickstart/scripts/build_queue.py` (`CHECKBOX`, `parse_daily_goals_refs`), the committed
  implementation vs `origin/development` (base `2ac998d130d9b6940ab00884c4248f4672b2dabb`), together with
  `skills/1-hourly/kickstart/SKILL.md` (daily-goals bullet), the plan `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md`
  (plan QA APPROVED round 2: `relay-system/2026-11-23/gh1569-plan-qa.md`), and the evidence `TESTS-RESULTS/2026-11-23+GH-1569/`
  (`manual-check.md`, `outputs/controls-green.txt`, `outputs/smoke.txt`, `provenance.jsonl`). `releases.db`/`releases.sql` changes are
  the roadmap row + rating written through `releases_app.py` (not hand edits).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Operational envelope: a ~540-line local developer CLI, read-only. Grade against the stated requirements and commensurate
  complexity. This repo forbids new test suites (AGENTS.md "No new tests", GH-831): a new `test/` file, `validate.sh` entry or gate
  machinery in the diff is a finding; `outputs/controls-probe-source.txt` is a retained evidence copy of a manual probe, not a suite.
- Requirements (issue #1569): with a task list in the daily-goals body, admit only numbers on unchecked `- [ ]` lines; a checked
  `- [x]` line and prose are not admitted; ONE lead number per checklist line (the FIRST `#N`; later ones are references);
  a body with no task list behaves exactly as today OR fails closed (smaller one chosen and proven: unchanged behaviour); handle the
  parser's other readers of that body; no new suite; red = #1568's ORIGINAL body (recovered via GraphQL userContentEdits): #1480/#1483
  queued and #1537 in Needs-the-operator on base, green = not; #1568's current body still yields 7 items; nested `(GH-…)` / `after #N`
  on checklist lines behave as stated.
- Rating persisted (read back via `releases_app.py roadmap list --json`): pri 60 / sev 45 / appeal 50 (neutral, no operator preference) / effort 90.

## Definition of Done (for THIS review)

STEP 1 — paraphrase first, from the plan only: **What this proposes**, **How the existing system works, per this document**, short **What it's not** (2-5 sentences each). State the input boundary.
STEP 2 — then read the diff (`git diff origin/development...HEAD -- skills/`), the source and the evidence; label that part "source-backed".

Questions (cite file:line):
1. Is each requirement of #1569 satisfied by the diff and observed evidence (not merely by a successful CLI exit)?
2. What prevents an unchanged, unfixed `build_queue.py` from being reported as delivered, and where is the observed rejection? Check `controls-green.txt` discriminator rows and the red/green CLI outputs; you may run narrow read-only probes (no `test/*`, no validate.sh).
3. Does the code match the plan (lead-ref rule: first `ATOMIC_REF` match consumed even when foreign/self/seen; unchecked no-ref line contributes nothing; no-task-list path unchanged)? Name any divergence or edge-case bug with a concrete input (Observed input / Affected scope / Falsifier).
4. Did a duplicate subsystem or writer slip in (second parser, new flag, new test/suite, hand-edited ledger)?
5. Is the persisted rating consistent with the evidence, and are the provenance receipts truthful (hashes match, synthetic fixture labelled, accounting-root deviation disclosed)?
6. Is the SKILL.md text accurate and its safety promise preserved? Is the diff free of accidental files (the relay-system threads and TESTS-RESULTS are intended)?

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
