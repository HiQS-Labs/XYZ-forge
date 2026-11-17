# RELAY · GH1493 final QA (published retirement per-path preservation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
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
6. **Commit only the relay file** (`relay(gh1493-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the completed diff `git diff 9331cec67..HEAD` on branch
  `fix/XYZ-forge-gh1493-retire-published-batch-2026-11-17` (PR #1516). Code:
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`retire_published_checkouts`). Docs:
  `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md`.
  Plan: `PROJECT/2-WORKING/GH-1493-RETIRE-PUBLISHED-BATCH.md` (approved in
  `relay-system/2026-11-17/gh1493-plan-qa.md`). Evidence: `TESTS-RESULTS/2026-11-17+GH-1493/`
  (`SUMMARY.md`, manual red/green batch check, `gate/` ci-local receipt, `smoke/` PR #1516 preview runs,
  `provenance.jsonl`). Ledger: `releases.sql` row GH-1493 (`rated 50/45/50/85`, accepted start).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Operational envelope: local developer CLI called by start-task closeout on one machine. Grade
  against the stated requirements and commensurate complexity; no enterprise fail-safes.
  XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new test file or registry entry
  in the diff is a finding; the manual check is recorded as markdown input plus outputs.
- Definition of Done:
  1. One ineligible `--checkout` path prints `PRESERVED <path>: <reason>`; other paths still reach
     the unchanged inspect/refresh/teardown path; exit 1 if anything was preserved; primary-origin
     failure stays exit 2.
  2. Origin check unchanged in strength; its message names the canonical-origin helper recipe;
     start-task SKILL.md has the one helper sentence.
  3. Controls: different repository and unpublished local commit still preserved.
  4. Evidence substantiates each claim: red control on base `9331cec67`, green on candidate, smoke on
     the main path and a rerun, full gate on the code commit.

Questions:
1. Does the code at `merge_cleanup.py` `retire_published_checkouts` match the plan and DoD 1–2? Any
   path where an exception escapes the per-path `try`, or a refused path still reaches inspection?
2. Is anything weakened: symlink/absolute/protected/safe-root/overlap/origin checks, exit codes,
   classification or teardown? Compare against `git show 9331cec67:skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`.
3. What prevents an unchanged, unfixed candidate from being reported as delivered — cite the observed
   rejection in the evidence (base run output) and say whether the evidence shows it.
4. Does the smoke receipt show the unpublished-commit control reaching classification
   (`PRESERVE_UNPUSHED`) rather than an earlier refusal? Is the `-gate` ACTIVE_PROCESS → SAFE change
   between runs explained adequately?
5. Is the persisted rating consistent with the evidence? Did any duplicate subsystem, writer, or new
   test file slip in? Are the doc sentences accurate (e.g. the merge-cleanup clause lists only the
   pre-inspection refusals)?
6. Note: the origin-mismatch message also shows the helper recipe for an unrelated-repository
   checkout. Is that misleading enough to change, or acceptable?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
