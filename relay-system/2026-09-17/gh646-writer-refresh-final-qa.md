# RELAY · GH-646 refreshed writer final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-646-refreshed-writer-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-646-STATUS-LABEL.md`, `utils/py/releases_app.py`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `utils/py/work_connectors/__init__.py`, `utils/py/work_connectors/github_labels.py`, and the GH-646-focused tests.
- Reviewer: codex-gh646-review   ·   Producer: terra-gh646-writer
- Started: 2026-09-17
- Definition of Done: Review only the refreshed GH-646 producer. Confirm that explicit accepted starts set one exact owned `in-progress` value through the existing writer; remote projection is opt-in and exact-identity-bound; confirmed closure clears only that label; old schema/dump paths remain compatible; Express and reconciliation cannot borrow a same-number foreign issue. The review must reject an added writer, service, scheduler, generic label layer, inferred start, Flight Deck/Daily change, live migration, connector enablement, or deployment. Focused evidence is 38 `test/gh646_status_label.py` cases plus existing related suites; final qualification is still pending and cannot be called green by this review.

## Questions for this bounded final review

1. Does every status mutation reuse the existing locked roadmap writer and durable receipt boundary, including accepted starts and terminal cleanup?
2. Can a same-number foreign repository, malformed URL, or pull request ever supply identity or closure authority to an owned issue? Cite the relevant guard and test.
3. Does the GitHub connector preserve local durability across remote failures, write only the literal label, and avoid treating metadata, stale activity, merged PRs, or reopen as authority?
4. Are schema migration, old/new dump, existing marker/event compatibility, and reader behavior correctly bounded? Reader SQLite sidecar policy is already approved separately and is not a request to change reader code here.
5. Is the diff surgical relative to the plan, with no unrelated dashboard, Daily, generated-view, or harness changes? Flag a real omission or safety issue with file:line evidence; do not demand speculative infrastructure.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
