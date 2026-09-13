# RELAY · GH-592 implementation QA — express provenance receipt
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
6. **Commit only the relay file** (`relay(gh592-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (implementation commit 8b18fe2a on branch fix-gh592-express-receipt): `utils/py/express.py`, `test/gh267-express-skill.sh`, `test/gh425-gate-provenance-pr.sh`, `skills/express/SKILL.md`, `TESTS-RESULTS/2026-09-13+GH-592/provenance.jsonl`, `TESTS-RESULTS/2026-09-13+GH-592/SUMMARY.md`, `CHANGELOG.md`. Plan: `PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md` (approved-in-substance after 4 Codex rounds in `relay-system/2026-09-12/gh592-plan-qa.md`). Consumer (unchanged): `utils/py/wave_reconcile.py` `check_provenance_receipts` ~L415, `fetch_commit_metadata` ~L362.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-12
- Definition of Done: the implementation matches the reviewed plan items 1–8, no parallel writer or allowlist widening slipped in, the red controls actually falsify the new behavior, and the tests substantiate the CHANGELOG/plan claims. You may run `bash test/gh267-express-skill.sh` and `bash test/gh425-gate-provenance-pr.sh` (un-sandboxed); do not edit any artifact.

## Questions to adjudicate (answer each, cite file:line)

1. **Plan fidelity.** Does `closeout()` call `write_receipt` strictly after the clean-development check and reachability check and before the ship `persist_closeout`? Is `state["suite_rc"]` the real Step-7 exit status (not a default) on the normal `run`/`land` path? Where could `state.get("suite_rc", 0)` default to 0 without the suite having run — is that reachable?
2. **Exact-path grant.** Does `persist_closeout(..., extra_paths=)` grant only the returned receipt path, and is every other dirty `TESTS-RESULTS/**` path still refused? Is control (i) in gh267 actually exercising the post-clean-check window (the releases-stub `STUB_INJECT_PATH` fires during `manifest ship`, which runs before the ship persist)?
3. **Shared predicate.** Is `valid_express_receipt` the single predicate used by both `find_receipt` (dedup in `write_receipt`) and `cmd_resume`? Any path where resume proceeds with an invalid or missing record? Does the `--suite` normalization (`strip()`) match what the landing wrote (`receipt_command`)?
4. **Resume ordering.** Is the evidence gate (4b) now before issue close (step 4) and ship (step 5)? Does the pending-receipt persist in resume commit exactly the receipt? Can resume ever write a receipt?
5. **Red controls.** In gh425 `test_cli_commit_landing_gate_express_receipt`: does (a) reach the matcher (exit 6 with its message) rather than an earlier exit, does (c) declare B in the offline manifest so exit 4 is impossible, and does (b) pass through the real `check_provenance_receipts` (not a mock)? In gh267 control (ii): does the mutation return the expected path without writing and reach the stubbed gate's missing-receipt exit, so a `None` plumbing error could not impersonate it?
6. **Stub fidelity.** Does the gh267 stub `wave_reconcile.py` check `--gate` and receipt presence after its cleanliness check, mirroring the real matcher's identity semantics? Anything the stub accepts that the real gate would reject (or vice versa) in these tests?
7. **Overclaims.** Do the docstring, Step-7 comment, scaffold Status/Acceptance lines, ship-evidence string, recovery hint, and SKILL.md now state only what runs? Any remaining "green in the gate" / "duplicate hook" / "every oracle" wording?
8. **Evidence.** Do `TESTS-RESULTS/2026-09-13+GH-592/provenance.jsonl` and `SUMMARY.md` accurately reflect what the tests assert (89/0, 14 tests), and are they attributable (will the PR-path gate find them once `pr` is added)?
9. **Duplicate systems.** Any second JSONL writer, second allowlist, or copy of matcher logic that should have reused existing code?
10. **Rating.** `rated 55/45/50/70` still grounded after implementation?

Grade each finding (blocker / should / nit). End with `VERDICT: PASS`, `FAIL`, or `PARKED` and a non-empty `Basis:` line; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
