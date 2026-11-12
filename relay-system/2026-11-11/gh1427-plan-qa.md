# RELAY · GH-1427 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
6. **Commit only the relay file** (`relay(gh1427-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1427-CLAUDE-TURN-BUILDER-CEILING.md`, specifically the
  `## Phase 1 — Plan (start-task)` section and its `### Phase 0 findings` table. This is a plan review: no code has changed yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-11
- Operational envelope: a local developer CLI harness (single operator, local repos). Grade against the issue's
  acceptance and commensurate complexity. Do not apply multi-tenant or enterprise threat models. The repo forbids
  new test suites (`AGENTS.md` "No new tests", GH-831): do not ask for one. Verification is existing suites plus
  manual checks under `TESTS-RESULTS/`.
- Definition of Done: the plan is grounded in the actual code paths, covers every acceptance item of
  https://github.com/HiQS-Labs/XYZ-forge/issues/1427, extends existing subsystems and writers without a parallel
  path, and has falsifiable checks with red controls.

### Step A — paraphrase first (GH-1414)
Before you open any source file or the issue, read **only the plan document** above. Start your block with 2–5 sentences
under **What this proposes**, 2–5 under **How the existing system works, per this document**, and a short
**What it's not**. Label inference as inference. Record your input boundary (which files you read for this step).

### Step B — source-backed validation
Then read the issue (`gh issue view 1427 --repo HiQS-Labs/XYZ-forge` if available, else the plan's copied acceptance),
plus these sources: `utils/py/claude-turn.py`, `utils/py/claude_cli.py`, `utils/py/rtl.py` (`is_reviewer_turn`,
`rtl_default_log`, `enforce`), `relay-automation/relay-turn-lib.sh` (`rtl_is_reviewer_turn` ~L63, `rtl_check`
~L1295-1333, `rtl_enforce` ~L1476 and its final GH-161 sweep ~L1734-1760, header comment ~L195-210),
`utils/py/relay_drive.py` (`prepare_turn_log` ~L146, `RELAY_ROLE` ~L856), `utils/py/marathon_drive.py` (GH-379
`builder_diag` ~L2198-2263, cost summary ~L1850), `.gitignore`, `test/gh642-consumer-fruit.sh`,
`test/gh379-claude-builder-diagnosis.sh`, and `AGENTS.md` (frozen twins, no new tests). Label this part **source-backed**.

Questions:
1. Is finding F5 (the transcript is deleted by `rtl_enforce`'s GH-161 leftover sweep or the `rtl_check` exact match when the
   host repo does not gitignore `relay-system/logs/`) correct per the code? Is the proposed exemption (keep a log under
   `<transcript root>/logs/`) the right scope, and does it break any invariant that GH-161 or GH-261 established (for example, a
   clean tree after the turn, the commit step picking the file up, or worktree-isolation copy-back)?
2. Is `rtl.is_reviewer_turn(me)` a sound role source for the ceiling under Marathon/Jog (`RELAY_ROLE` +
   `RELAY_DRIVER_LOCKED`) and for hand-run turns? Is there any Claude reviewer turn that would wrongly get builder defaults?
3. Are the builder defaults (3.00 / 40) with reviewer 0.50 / 12 and a global env override a reasonable, minimal design? Is it
   correct not to add per-role env knobs or Jog/Marathon plumbing?
4. Step 2c moves `tick cost` before the failure exit. Any double-count or exit-code risk? Does the usage JSON of an
   `error_max_budget_usd` result carry usage?
5. Is keeping ESCALATION `reason:` as the category token and putting the cause in the existing `builder-diagnostic:` line
   (adding `errors`) an acceptable reading of the acceptance item "Marathon carries it into ESCALATION.md `reason`"?
6. Are the verification plan (existing suites named, manual checks M1/M2, red control on base `0f21b761a`, bounded live smoke)
   and the rollback sufficient? Is anything missing, duplicated, or over-built?
7. Are the ratings (80/80/50/60) and the recurrence claim grounded? Appeal is neutral at 50.

Write your verdict and change STATUS to Approved if it passes; otherwise leave it Open with graded findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
