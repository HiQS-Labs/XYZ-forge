# RELAY · GH-564 work backfill + review_ready producer — plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh564-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-564-WORK-BACKFILL-REVIEW-READY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the plan, executed as written, satisfies every acceptance criterion on
  https://github.com/HiQS-Labs/XYZ-forge/issues/564; every claim about existing code is true at
  `59b692b2`; both verbs are `perform_write` callers through the existing `work emit` seam and
  no second write path appears; the backfill mapping's **section-wins-for-Completed** rule is
  sound against the live distribution the recon table shows (40 rows Completed/🆕); the
  review-ready scan cannot fail the verb and runs outside the connector lock; every acceptance
  check has a red control; and nothing in the plan is a rebuild of what #559 already ships.
- **Specific questions.** (1) Is "latest event == intended event" the right idempotence key, or
  does it miss a case (e.g. a row that went parked → in_flight → parked)? (2) Is `pr_merged` from
  a Completed section honest enough given the `{"source":"backfill"}` payload, or should backfill
  use a distinct event name? (3) Should the review-ready scan live in `reconcile` or be its own
  verb? (4) Any acceptance criterion on #564 the plan does not map to a check?
- Read the live code, not the plan's word: `utils/py/releases_app.py` (`cmd_work_emit` :4845,
  `cmd_work_reconcile` :4887, `perform_write` :1578), `utils/py/work_connectors/`,
  `skills/merge-cleanup/scripts/merge_cleanup.py:198-230`, `test/gh549-work-events.sh`.
- **You are the Reviewer: edit nothing but this relay thread.**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex · r1

swept file: yes

**Verdict: Changes requested** — the seam and placement are sound, but the planned Completed event is semantically false and the stated idempotence cannot be guaranteed under concurrent reconciles/backfills.

- [Blocker] **Backfill mapping / event semantics:** mapping every `Completed` row to `pr_merged` asserts a merge that the ledger snapshot did not witness. The existing producer explicitly limits `pr_merged` to a successful `gh pr merge`; its comment says a completed roadmap marker does not prove a merge (`skills/merge-cleanup/scripts/merge_cleanup.py:214-222`). A `{source:"backfill"}` payload preserves provenance but does not make the event name honest. Use a distinct snapshot/completed event (mapped to Done) or a non-merge event that preserves the Completed claim; add the mapping, receipt, and board-result tests.

- [Blocker] **Idempotence / write race:** `_latest_event` is described as a read before `_emit_work_event` (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:100-115`), while the `WriterLock` is only acquired inside `perform_write` (`utils/py/releases_app.py:1590-1615`). Two commands can both observe the same older latest event, serialize their writes afterward, and each emit a duplicate. Move the compare-and-conditional-record decision inside the same writer transaction (or otherwise make it atomic), and add a parallel backfill/reconcile red control that proves exactly one event/receipt is produced.

- [Blocker] **Proof / red controls:** the Definition of Done requires a red control for *every* acceptance check, but the proposed test plan names controls only for the latest-event guard and failing `gh` (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:120-123`). Add non-vacuous red controls for dry-run's zero writes, the Completed/🆕 section-precedence mapping, repeat-backfill no-op, receipt-chain/check-clean proof, draft/no-closing-PR exclusions, and review-ready board placement; each must mutate the relevant guard/branch and observe failure.

- [Pass] **Placement / scope:** keeping the review-ready scan in `work reconcile`, before dispatch and outside the connector lock, is the lean location; the current reconcile is already the replay/repair verb (`utils/py/releases_app.py:4887-4912`), and `perform_write` records its event within the receipt transaction (`utils/py/releases_app.py:1643-1654`). No pre-existing defect was found in the swept artifact beyond the findings above.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · round 1

All three blockers accepted; the plan is revised at `1870a355`.

- **[Blocker] `pr_merged` from Completed — IMPLEMENTED.** You are right, and it is the same
  argument that removed marker→merged from the live stream in #549 plan QA; I should have applied
  it myself rather than hedging with a payload. Backfill now emits a distinct **`completed`** event
  for a Completed section. `DEFAULT_STATUS_MAP` gains `"completed": "Done"` so the column is the
  same by default, but the event name says exactly what the ledger claims. Check 23 covers it.
- **[Blocker] idempotence race — IMPLEMENTED, using the abort path that already exists.** The
  latest-event check moves **inside `mutate`**, which `perform_write` runs after `WriterLock` and
  after `BEGIN IMMEDIATE`. When the latest event already matches, `mutate` raises
  `_AlreadyRecorded`; `perform_write`'s existing except-path (`releases_app.py:1613-1625`) rolls
  back, clears the journal and re-raises **before** any receipt or generation bump, so a skip
  leaves no trace on the chain. No change to `perform_write`. One helper, `_emit_work_event(...,
  unless_latest_in=())`, carries it for `work emit`, backfill and the review-ready scan alike.
  Check 21e is the parallel control you asked for: two barrier-synchronized backfills → exactly N
  events; move the read before `perform_write` in the copy → 2N.
- **[Blocker] a red control per check — IMPLEMENTED.** The plan now carries a table of every
  check (21a–23) with its mutation and the failure it must observe. 21d cites leg 7's existing
  receipt-chain control rather than duplicating it; say so if you want it re-proven here.
- **[Pass] placement — noted.**

Two questions from the scaffold you did not answer, so I am deciding them and asking you to
object if you disagree: (1) `completed` rather than a generic `snapshot` event — one name per
ledger state keeps `status_map` meaningful; (3) the scan stays in `reconcile` per your Pass.

VERDICT: PARKED
Basis: producer turn — three blockers implemented in the plan at 1870a355; handing back for
round 2.

Handing off to Reviewer (codex) — take round 2 against the revised plan.

### Reviewer — codex · r2

swept file: yes

**Verdict: Changes requested** — r1's event semantics and transactional idempotence are now sound, but the review-ready scan still has an uncontained write failure and the table does not yet give every check a mutation-backed red control.

- [Blocker] **Fail-soft boundary is incomplete:** the plan catches only PR-list failures, then calls `_emit_work_event` per issue (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:121-128`). That helper reaches `perform_write`, whose `mutate` exception is rolled back and re-raised (`utils/py/releases_app.py:1613-1628`), so one locked/invalid/write-failed observation can still exit `work reconcile` before dispatch — contrary to “Never fails the verb.” Catch and report each emission failure (continue the scan and dispatch), while retaining `_AlreadyRecorded` as a quiet skip; add a copied-app control that forces one emission failure and proves reconcile exits 0 and replay still runs.

- [Blocker] **Red-control contract:** checks 22a, 22b, and 23 name an alternate fixture input/probe, not the promised source mutation and observed red result (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:148-153`). Add explicit copied-source mutations: remove/bypass the non-draft and linked-issue filters and observe their negative assertions fail; remove `completed` from the copied status map and observe the mapping assertion fail. This is required by the Definition of Done’s per-check red control, not additional feature scope.

- [Nit] The check table contains one `22c` row at `.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:150`; retain one canonical entry so implementation evidence has an unambiguous checklist.

- [Pass] **Semantic choices:** `completed` is the honest distinct Completed-snapshot event, and the exact-latest-event transactional guard correctly re-emits a row after a parked → in_flight → parked cycle (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:89-115`). Keeping the scan in reconcile before dispatch preserves the requested outside-connector-lock placement (`.relay-artifacts/GH-564-WORK-BACKFILL-REVIEW-READY.md:119-128`; `utils/py/work_connectors/__init__.py:376-397`). No additional pre-existing defect was found in the swept artifact.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · round 2

Both blockers accepted; plan at `b9abf956`.

- **[Blocker] fail-soft boundary — IMPLEMENTED.** Correct: `_emit_work_event` reaches
  `perform_write`, whose abort path re-raises, so a locked ledger on one issue would have exited
  the verb before dispatch. Each emission is now its own fail-soft unit — `_AlreadyRecorded` is
  the quiet skip, any other exception is printed with the issue number, counted, and the scan
  continues to the next issue and then to dispatch; the verb exits 0. Check **22f** is the
  copied-app control you asked for: force `_emit_work_event` to raise for one issue → the other
  issue's event lands, the cursor moves, rc 0; remove the per-emission `except` → rc ≠ 0, no
  dispatch. The one exception deliberately not caught is an injected `_crash`, which uses
  `os._exit` and never reaches an `except`.
- **[Blocker] red-control contract — IMPLEMENTED.** 22a, 22b and 23 now name copied-source
  mutations and the negative assertion each must flip: 22a swaps the emitted event name; 22b has
  one mutation per filter (drop `isDraft`; replace `linked_issues` with the PR's own number); 23
  deletes the `completed` key from the copied map.
- **[Nit] duplicate 22c — checked.** The table has one `22c` row; nothing to change.
- **[Pass] × 1 — noted.**

VERDICT: PARKED
Basis: producer turn — both round-2 blockers implemented in the plan at b9abf956; handing back
for round 3, the cap.

Handing off to Reviewer (codex) — round 3, the final plan round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
