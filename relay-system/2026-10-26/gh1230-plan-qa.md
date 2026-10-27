# RELAY · GH-1230 plan QA: task-sync Desktop titles go stale
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1230-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md` (the PLAN; no code yet). Requirements are its Scope table, from https://github.com/HiQS-Labs/XYZ-forge/issues/1230.
- Source it changes (read in full): skills/3-weekly/task-sync/scripts/adapters/claude.py (ClaudeDesktopAdapter), skills/3-weekly/task-sync/SKILL.md ("Claude Desktop (GH-1191)" section), skills/3-weekly/task-sync/scripts/task_sync.py. Prior work: PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md, PROJECT/3-COMPLETED/GH-1196-TASK-SYNC-DESKTOP-PINS.md, TESTS-RESULTS/2026-10-24+GH-1191/, TESTS-RESULTS/2026-10-24+GH-1196/.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-26
- Operational envelope: a local single-operator read-only planner; the Desktop app's `set_session_title` is the only title writer, driven by an agent following SKILL.md from a scheduled task. Grade against the Scope table and commensurate complexity. No new `test/` suites or gate machinery (AGENTS.md, GH-831); manual probes + a live check under TESTS-RESULTS/.
- Operator constraint: zero manual steps and no approval queue (operator, 2026-10-26).
- Native facts (observed on one device, recorded in the plan's Evidence table): scheduled-task runs decline overwriting a user-set title even in bypass mode; an open interactive bypass session's timer wake renamed one; renaming a running session persisted. Whether a scheduled run can hand a rename to an open session is unproven, which is the plan's step 0.
- Definition of Done:
  1. R1–R5 each map to a plan step with a falsifiable check.
  2. Changes stay within the existing loop, procedure and scheduler; no second planner or writer; archiving is limited to the task's own runs.
  3. Removing the window and the running skip is sound: the fail-closed rules are kept, and the GH-1191 probe deltas are stated.
  4. The step 0 gate and the 3a/3b fork are well-defined, and a failed probe stops for the operator.
  5. Rating `rated 70/40/45/60` is grounded.

Questions:
1. Is dropping the title window and the running skip correct and complete (planner + recheck)? What breaks?
2. Is the step 0 probe the right decider for R1, and is 3a's forwarding contract specified enough (sweeper identity, recheck, failure reporting)?
3. Is step 4 (archiving the task's own old runs) safe and necessary for R4, or is the limit bump enough?
4. Are the probes and live checks enough, and not too many?
5. Anything over-engineered, under-specified or out of scope? Cite file:line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
