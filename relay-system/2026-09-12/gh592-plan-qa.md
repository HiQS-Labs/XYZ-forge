# RELAY · GH-592 plan QA — express provenance receipt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-12.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh592-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md` (the plan). Read it in full, then the code it cites: `utils/py/express.py` (cmd_land ~L547, closeout ~L621, persist_closeout + CLOSEOUT_ALLOWLIST_* ~L700-730, cmd_resume ~L851), `utils/py/wave_reconcile.py` (fetch_commit_metadata ~L362, check_provenance_receipts ~L415, the require_receipts call ~L1699), `test/gh267-express-skill.sh` (fixture + stubbed wave_reconcile ~L135, happy path ~L310), `test/gh425-gate-provenance-pr.sh`, `TESTS-RESULTS/README.md` and one existing `TESTS-RESULTS/*/provenance.jsonl`. Umbrella context: GitHub issues #591, #592, #546, #584.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-12
- Definition of Done: the plan is grounded, complete for #592, extends the existing express driver with no parallel writer, and its red control can actually fail.

## Questions to adjudicate (answer each, cite file:line)

1. **Grounding.** Are the plan's claims about `express.py` and `wave_reconcile.py` true at HEAD? Specifically: (a) express never writes a `TESTS-RESULTS` receipt; (b) the inline `--commit` reconcile passes no `--gate`; (c) `check_provenance_receipts` already matches a receipt `commit` field against a commit landing's `mergeCommit.oid` so the consumer needs no change; (d) wave_reconcile refuses a dirty tree, so the receipt must be committed before the reconcile call and the existing ship-persist commit is the right slot.
2. **Completeness vs #592.** Does the plan cover every acceptance item in issue #592? Is anything in the issue missing from the plan, or anything in the plan not asked for?
3. **Single writer.** Does `write_receipt` in the express driver extend the existing landing writer, or is it a parallel path? Should it reuse any existing helper (e.g. `write_tick`, an existing JSONL writer) instead of new code?
4. **Red control.** Is the proposed gh425 case (express receipt for commit A → 0; same receipt vs commit B → 6) a real falsification of the new behavior, or does it only re-test the matcher? What is the smallest additional assertion that proves the *express driver* produced the receipt (not the test)?
5. **Allowlist widening.** Is adding `TESTS-RESULTS/` to `CLOSEOUT_ALLOWLIST_PREFIXES` safe given `persist_closeout` runs post-push with `XYZ_SKIP_PREPUSH=1`? Name a concrete way an unrelated dirty `TESTS-RESULTS/` file could ride a closeout commit, or state why it cannot.
6. **Resume path.** Is calling `write_receipt` idempotently in `cmd_resume` before `--gate` correct, or does it let a landing whose suite never ran obtain a receipt? If the latter, what should resume require instead?
7. **Stub knob.** The plan adds `WR_STRIP_RECEIPT=1` to the *test stub* `wave_reconcile.py` for a negative case. Confirm no production code path reads it; propose a simpler negative if one exists.
8. **Rating.** `rated 55/45/50/80` (pri/sev/appeal/effort, higher = better/cheaper). Grounded? Recurrence claim: 3/3 express landings in 14 days with no receipt.
9. **Non-goals.** The plan explicitly does NOT make express run the full gate (GH-267 design). Is that boundary stated honestly in the receipt (`gate: express-suite`) and the fixed comment, or does anything still overclaim?

Grade each finding (blocker / should / nit). End with `VERDICT: PASS`, `FAIL`, or `PARKED` and a non-empty `Basis:` line in your final block; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
