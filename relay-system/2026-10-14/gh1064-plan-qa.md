# RELAY · GH-1064 plan QA — script-owned merge-batch issue + recorded post-merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
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
6. **Commit only the relay file** (`relay(gh1064-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1064-MERGE-BATCH-ISSUE-QA.md`, the **plan** (no code written yet).
- Requirements: GitHub issue #1064 body, **as scoped by the operator decisions in the plan** (script
  records, agent runs the suite; exit 4 = landed, QA pending; threshold 2+).
- Read the source the plan cites, not just the plan:
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`main`, `land_prs`, `execute_pr_merge`)
  - `skills/2-daily/merge-cleanup/scripts/toposort_prs.py`, `attempt_record.py`, `scan_clones.py` (`_gh`, `post_issue_marker`)
  - `skills/2-daily/merge-cleanup/SKILL.md` ("Batch issue protocol (GH-944)", "Done rule", "Capability table", Drive loop)
  - `test/gh534_phase_b_tests.py` (`GH_STUB`), `test/gh534_phase_c_tests.py` (parity guard, `TestGh623DriveLoopDocContract`)
  - `utils/py/wave_reconcile.py` `select_qualification_gate`
  - `AGENTS.md` "No new tests (GH-831)"
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- **Operational envelope:** a local, operator-driven CLI that lands a handful of PRs per run in one repo.
  Grade against the stated requirements and commensurate complexity. Do **not** ask for enterprise
  fail-safes, distributed locking, new suites, guards or runners (GH-831 forbids the last three).
- **Definition of Done — answer each question with file:line evidence:**
  1. Are the plan's recon claims (line numbers, data available at each hook point, what `toposort_prs` keeps, what `execute_pr_merge` returns) accurate against the code?
  2. Is the "before the first merge" hook point right, so the issue exists before any `gh pr merge`, including on `--resume` and when the first PR is skipped or deferred?
  3. Does the plan extend existing writers and helpers (`attempt_record` lock/save, `scan_clones._gh`, `select_qualification_gate`) rather than creating a parallel subsystem? Is a new `batch_record.py` justified, or should it live in an existing module?
  4. Is the exit code 4 precedence (2 > 3 > 4 > 0) and the `--record-sweep` standalone mode sound? Any caller or doc-contract test that breaks?
  5. Does the plan stay inside GH-831, given that adding test methods to the existing gh534 files is argued as required by the parity guard? Is the red-control plan falsifiable?
  6. Is anything in #1064's operator-scoped requirements missing, or anything built that is not required?
  7. Pre-existing defects in the touched code paths that would make this plan wrong.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
