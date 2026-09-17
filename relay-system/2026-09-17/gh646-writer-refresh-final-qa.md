# RELAY · GH-646 refreshed writer final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

### Reviewer · codex-gh646-review · Round 1 · 2026-09-17

swept file: no

Verdict: Changes requested

- [Blocker] Ordinary roadmap updates bypass accepted-start admission. `utils/py/releases_app.py:1642–1645` sets `status_label = "in-progress"` when a target transitions into `in_flight`, even with `accepted_start=False`. The ownership/native-issue/open-state checks at `utils/py/releases_app.py:3929–3941` run only under `if accepted:`. Consequently a queued row with a foreign/malformed URL, a native PR, or a closed issue can receive the authoritative local label through `roadmap update --gid <gid> --section "In progress"` (or a 🚧 marker) without admission. This is a static fail-path finding, not an executed reproduction. Fix: restrict establishment of this new label to the qualified accepted-start path; retain legacy marker/section and event compatibility without letting those alone establish the label. If legacy explicit transitions must establish it, route them through the same qualification and stale-row checks instead. Add focused negative cases for each identity/native-state defect through ordinary update and move, with a valid accepted-start positive control and a mutant that restores the bypass.
- [Pass] The dedicated accepted-start path checks owned identity, native issue state, and stale row identity inside its mutation (`utils/py/releases_app.py:3932–3941`, `utils/py/releases_app.py:3982–4000`); the shared writer places label maintenance inside its transaction before the receipt and commit (`utils/py/releases_app.py:1688–1699`, quoted seam: `_sync_status_labels(conn, before_rows, op, target_gid, accepted_start)`). These protections do not cover the ordinary-update bypass above.
- [Pass] Remote writes name only the literal owned label: `utils/py/work_connectors/github_labels.py`, quoted calls `"--add-label", LABEL` and `"--remove-label", LABEL`, with `LABEL = "in-progress"`; readback checks unrelated labels via `after - {LABEL} != before - {LABEL}`. Native REST identity rejects `"pull_request" in issue` and mismatching `html_url`/number (`utils/py/releases_app.py:5399–5414`). Focused test coverage is present in `test/gh646_status_label.py:test_owned_identity_and_pr_refusal` and `test_failed_removal_reopen_replay_and_cursor_retention`; these were read, not run this turn.
- [Should] Final QA remains open. This turn inspected the complete plan and label connector plus relevant writer, connector-parent, Express, reconciliation, and focused-test paths; it did not complete the mandated whole-file sweep of the large artifacts. Remaining schema/dump compatibility, unrelated/pre-existing defects, and surgical diff scope receive no approval from this turn. Finish that sweep after the blocker is resolved. No tests, gates, git commands, source edits, live migration, enablement, or deployment were performed; the producer's reported 38-case run is not independently re-attested here, and final qualification remains pending.

Handing off to terra-gh646-writer — address the admission bypass, record the disposition, and reopen Reviewer QA; go to the Producer window and say 'take your turn'.

### Producer · terra-gh646-writer · Round 1 disposition · 2026-09-17

- [Blocker] Implemented. `_sync_status_labels` now establishes `in-progress` only when the existing `roadmap-update` call carries `accepted_start=True`. Existing active rows retain a previously established label; inactive/terminal rows still clear it. Legacy appearance transitions retain their existing lifecycle event compatibility but cannot create this new authority.
- Added `test_ordinary_active_appearance_never_establishes_label`: foreign repository identity, native closed state, and native pull-request state each make ordinary `In progress` / `🚧` appearance without a label; a valid explicit accepted start remains the positive control.
- Red control witnessed: `python3 test/gh646_status_label.py --mutant appearance` fails the new assertion after deliberately restoring the old appearance-based label mutation. The corrected suite passes 39 tests; the wrapper also passes. This is focused evidence only, not final qualification.

Handing off to codex-gh646-review — review the narrow repair and decide whether the remaining bounded sweep can approve; go to the Reviewer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
