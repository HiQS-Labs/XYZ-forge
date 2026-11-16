# RELAY · GH1400 follow-up plan QA (task-local failure continuation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1400-follow-up-plan-qa-task-local-failure-continuation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, section
  "Follow-up — task-local failure continuation (2026-11-16)" (the plan; no code changed yet).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the plan, if built as written, satisfies the five operator acceptance items
  below with falsifiable controls on the real `releases_app.py jog run` entrypoint, extends the
  existing owner without new machinery, and states unproven scope truthfully.

## Review packet — read in this order

First read only the follow-up section of the plan doc. Before reading source or the requirements
below, write 2–5 sentences each under **What this proposes** and **How the existing system works,
per this document**, plus a short **What it's not**. Record that input boundary; label inference.
Then validate against source: `utils/py/jog_run.py` (`run_marathon_phase` ~603-736,
`jog_project_marathon_outcome` ~393-444, `JogSupervisorLock` ~1524, `JogCheckpoint` ~2130-2450,
`_jog_align_target` ~2518, `_jog_supervise_recover` ~2554, `jog_run_main` ~2609-2972),
`MACHINE-CONTRACTS.md` Contract B (closed outcome vocabulary), `utils/py/marathon_drive.py`
(`write_terminal_result` ~204), `TESTS-RESULTS/2026-11-15+GH-1400/check.py` (fixture reused),
`AGENTS.md` (*No new tests*, GH-831; disposable full clone rule).

Operator acceptance (verbatim intent): (1) a provably task-local known terminal failure persists
reason/receipts/budgets, no auto-retry/re-entry, and an independent READY B dispatches in the same
invocation without parent restart; (2) dependent/held tasks not selected, and max-tasks/deadline
counts not reset; (3) saved valid approved result then supervisor interrupted BEFORE
ack/checkpoint publication: restart validates/adopts exactly once without builder, budgets
retained; inconsistent/missing receipt HOLDS rather than rebuild; (4) a shared unsafe condition
(live or SIGSTOPped ownership conflict, checkpoint contradiction) stops all dispatch, B stays
undispatched; safe classification fails closed; a task failure never licenses skipping global
unsafe state; (5) red controls prove the unfixed baseline fails local continuation and
corrupt/missing receipt/refused ownership cannot look like a pass; synthetic workers only; no
duplicate workers, no unknown-outcome retry, immutable runtime identity per control. Readiness may
not rest on direct function calls that bypass the entrypoint. Scope is supervised real Marathon;
legacy drive behaviour must not be blindly broadened.

Evidence: dogfood wake 1 stopped at GH-1023 whose receipt (local, not in repo) was
`outcome: escalated, reason: pre-advance-failed, exit_code: 5, gate.result: red, pr: null`.

Questions:
1. Is the task-local classification grounded in the actual `failed` paths of `run_marathon_phase`
   and the closed outcome set, and is it fail-closed? Name any `failed` path that would wrongly
   continue, or a task-local one wrongly stopped that the operator's item (1) requires.
2. After a task-local continuation, does every shared-safety check still run before B's dispatch
   (lock/SIGSTOP owner, tracked dirt, detached HEAD, worktrees, ledger change)? Cite lines.
3. Are max-tasks and deadline truly not reset, and is the failed row never reselected/retried?
4. Do the planned controls detect the real defect (baseline red) and would each fail on an unfixed
   or wrongly-fixed candidate (e.g. a blanket `break`→`continue`)? Which control catches that?
5. Is the restart control (worker SIGKILLs the supervisor after writing its receipt) a faithful
   "interrupted before acknowledgement/checkpoint publication" case on the existing recovery path?
6. Is the scope commensurate (one helper + one branch, docs, manual receipts; no new suite)?

Do not run suites or modify source. Only this relay file is writable. Grade the bounded local
operator-CLI envelope; no enterprise fault model or speculative tests. A behaviour-change finding
needs `Observed input:`, `Affected scope:`, `Falsifier:`. Approval is plan approval, not runtime proof.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
