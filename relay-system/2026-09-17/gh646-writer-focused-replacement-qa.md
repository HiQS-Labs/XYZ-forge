# RELAY · GH-646 writer focused replacement QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh646-writer-focused-replacement-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/releases_app.py`, `utils/py/express.py`, `utils/py/wave_reconcile.py`, `utils/py/work_connectors/__init__.py`, `utils/py/work_connectors/github_labels.py`, `utils/ci-route.sh`, `validate.sh`, `releases.sql`, `RELEASES-DB-FAQS.md`, `PROJECT/2-WORKING/GH-646-STATUS-LABEL.md`, and their changed focused tests/receipts in this branch.
- Reviewer: codex-gh646-review2   ·   Producer: terra-gh646-writer
- Started: 2026-09-17
- Definition of Done: The operator authorized a focused changed-function-and-callers review of the 23-file GH-646 candidate rather than an unrelated whole-repository sweep. Review every changed runtime function and its direct callers relevant to: schema/dump compatibility; qualified accepted start; only-literal-label local/opt-in remote projection; exact repository/native issue-versus-PR identity; direct confirmed closure; Express and wave exact-row routing; connector failure/replay; and CI routing. Treat a concrete reachable in-scope defect as a finding. Do not require reader/Flight Deck/Daily changes, a generic label system, service, scheduler, new database, live migration, connector enablement, live GitHub label write, or deployment. The prior capped relay is historical evidence only; this is its replacement. Approval is valid only when this exact reviewer turn is attested by the Python driver; final qualification remains a separate gate.

### Focused-review waiver and evidence boundary

The operator explicitly authorized this focused review on 2026-09-17 after the prior automated reviewer failed before producing a Round 3 verdict. This limits the review to the candidate's changed runtime seams, relevant direct callers, schema/dump and test/receipt boundaries. It does **not** waive source review, approval attestation, the final disposable-clone qualification gate, or normal PR review. A reviewer must state `swept file: yes` only for the listed scope files it actually reads; it must list any unreviewed changed file as an unknown.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
