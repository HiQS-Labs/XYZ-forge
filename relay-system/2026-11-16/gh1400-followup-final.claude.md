# RELAY · GH1400 follow-up final QA (task-local failure continuation)
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
6. **Commit only the relay file** (`relay(gh1400-follow-up-final-qa-task-local-failure-continuation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/jog_run.py` and the rest of the committed diff from 1d9658c3c63c to HEAD: (`_jog_task_local_failure` and the supervised `failed` branch in
  `jog_run_main`), `skills/2-daily/jog/SKILL.md`, `CHANGELOG.md`, the plan follow-up section of
  `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, and `TESTS-RESULTS/2026-11-16+GH-1400/`
  (`followup.py`, `SUMMARY.md`, `provenance.jsonl`, `smoke/`, `repeat/`, failed attempts).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the implementation matches the approved plan (`relay-system/2026-11-16/gh1400-followup-plan.claude.md`, PASS r2), satisfies the five operator acceptance items with observed evidence on the real entrypoint, adds no new machinery or test suite, and states unproven scope truthfully.

## Review packet

Read `git diff 1d9658c3c63c..HEAD -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md CHANGELOG.md`
first, then the plan follow-up section, then `TESTS-RESULTS/2026-11-16+GH-1400/SUMMARY.md`,
`followup.py`, `smoke/results.json` (and the per-control `smoke/*.log`), `provenance.jsonl` and
the two `attempt*-failed/` runs. Validate against `utils/py/marathon_drive.py:2810-2825`
(gate-killed vs pre-advance-failed), `MACHINE-CONTRACTS.md` Contract B and the existing loop.

Operator acceptance: (1) task-local terminal failure persists reason/receipts/budgets, no
auto-retry/re-entry, independent READY B dispatches in the same invocation; (2) dependent/held not
selected, max-tasks/deadline not reset; (3) saved approved result then supervisor interrupted before
acknowledgement/checkpoint publication: restart adopts exactly once without builder, budgets kept;
inconsistent/missing receipt holds; (4) shared unsafe condition (live/SIGSTOP owner, checkpoint
contradiction) stops all dispatch with B undispatched; classification fails closed; (5) red
controls: unfixed baseline fails continuation; corrupt/missing receipt and refused ownership cannot
look like a pass; synthetic workers; no duplicate workers, no unknown-outcome retry, immutable
runtime identity per control. Readiness must not rest on calls that bypass the entrypoint.

Status: controls 23/23 smoke and repeat at `7f946cd1d`, runtime blob unchanged since `720b9c9a5`;
Jog–Marathon integration 227/227. The classified full gate (route=full, tier 3) has NOT run yet; it
runs once on the approved commit. Grade it as pending, not as a finding.

Questions:
1. Does `_jog_task_local_failure` implement exactly the approved classification, fail closed on
   every exception and non-matching field, and sit only on the supervised path? Cite lines.
2. Can any `failed` path continue wrongly, or any shared-safety check be skipped before B?
3. For each acceptance item, is there an observed record in `smoke/results.json`/logs that would
   fail on the unfixed runtime or a wrongly broadened fix (blanket continue, red-only)? Where?
4. Are the two failed attempts honestly classified as fixture defects with the runtime unchanged
   (compare blobs), and is nothing relabelled as a pass?
5. Any new suite/registry entry, duplicate writer, env leak, retry or scope creep in the diff?
6. Are SUMMARY/CHANGELOG/skill claims accurate and limits truthful?

Do not run suites or modify source. Only this relay file is writable. Read-only probes under
`$TMPDIR` are allowed. Grade the bounded local operator-CLI envelope. Behaviour-change findings need
`Observed input:`, `Affected scope:`, `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
