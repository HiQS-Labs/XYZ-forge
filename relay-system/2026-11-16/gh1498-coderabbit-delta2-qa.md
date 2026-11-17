# RELAY · GH-1498 CodeRabbit second-pass delta QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta2-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review `git diff a4270d2fe..1fee76049`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the delta `a4270d2fe..1fee76049` correctly implements CodeRabbit's second-pass findings on PR #1510, with no regression to approved behaviour.

## Context and questions

**Envelope:** a manual local CLI, one operator, one repo. The repo forbids new tests (GH-831).

Review `git diff a4270d2fe..1fee76049`. It touches `pr_minder.py`, `planner_core.py` (the comments query and the marker exclusion), `releases.sql`/`releases.db`, `SKILL.md` and the manual-check driver.

**Implemented:**
1. **`releases.sql`:** removed my duplicated GH-1476 `roadmap-pickup` receipt, an artifact of my ledger merge, and rebuilt the DB (`check` is clean). One pre-existing `roadmap-repoint` duplicate that also exists on `development` was left untouched.
2. **Update cap:** failed update-branch attempts now count toward the cap.
3. **Comment safety:** `md_safe`/`safe_url` neutralise PR-controlled text in comments. The repair command is omitted if a branch name contains a backtick or newline.
4. **Comment ownership:** a comment is owned only if it carries the marker AND was written by the viewer (REST `user.login`). In the clock and in `has_owned_comment`, a marker comment is excluded only if `viewerDidAuthor`.
5. **Update-branch polling:** the head is polled for up to 5×2s after update-branch, because it is asynchronous.
6. **Failure containment:** each PR is wrapped in try/except, writes a `failed` receipt, and the run continues. The exit code is 1 on any failed, uncertain or aborted write.
7. **Harness:** a crashed bad candidate is now a FAIL, not a rejection. A12 gained a bad candidate. A19a–A19e are added.

Evidence: `manual-check.log` 26/26.

Answer, citing `file:line`:
1. Is each change correct, with no regression? Check especially: the `viewerDidAuthor` default of True when the field is absent, `md_safe`'s escaping, the polling loop when `update-branch` fails, and the exit-code semantics now that an `aborted` safety stop returns 1.
2. Is the `releases.sql` edit limited to removing the one duplicate I introduced?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
