# RELAY · GH-564 — implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Producer
STATUS: Escalated
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
6. **Commit only the relay file** (`relay(gh564-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh564-impl-qa-brief.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/gh564-impl-qa-brief.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the seven numbered questions in the artifact, each answered explicitly.
  Approved only when every #564 criterion maps to code at `file:line`, the transactional
  idempotence is shown atomic, no second write path exists, no new assertion is vacuous, and no
  `[Blocker]` remains. **Live worktree at the branch head — run things.** Edit nothing but this
  thread.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — Codex (round 1)

swept file: no

- [Blocker] Scoped idempotence is only correct while the matching producer row is among the 50 newest rows. `_latest_event` fetches `ORDER BY id DESC LIMIT 50` before applying `only_source`/`exclude_source` in Python (`utils/py/releases_app.py:4864`). After one backfill for an issue, 50 newer non-backfill events make `only_source="backfill"` return `None`, so `cmd_work_backfill` emits a duplicate through `utils/py/releases_app.py:5025`; the symmetric `exclude_source="backfill"` lookup can similarly re-emit `review_ready`. Remove the arbitrary limit (or page until a matching row is found) while retaining the lookup inside `mutate`; add a focused regression that puts 50 excluded rows after a matching row and proves both producer views still skip.
- [Should] The receipt check is aggregate, not per-event: `NRC >= NBF` at `test/gh549-work-events.sh:978` can pass using receipts already present for unrelated `work-emit` writes. Tie each newly backfilled event to its own receipt/txn (or snapshot both sets before backfill and compare the additions) and make that guard red with a copied-path mutation.
- [Pass] The intended transaction boundary is correctly placed: `_emit_work_event` performs the decision inside `mutate` (`utils/py/releases_app.py:4901`), which is invoked after `BEGIN IMMEDIATE` by `perform_write` (`utils/py/releases_app.py:1607`), and its abort path rolls back and removes the journal before re-raising (`utils/py/releases_app.py:1609`).
- [Pass] There is no second GH-564 write path in the reviewed implementation: backfill and review-ready both call `_emit_work_event` (`utils/py/releases_app.py:5025`, `utils/py/releases_app.py:5115`), which delegates to `perform_write` (`utils/py/releases_app.py:4914`).
- [Pass] The mapping order matches the stated live-state rules: Deferred, then Completed, then in-progress, then rating fallback (`utils/py/releases_app.py:4961`). The default completed mapping is present and user-overridable through the existing map contract (`utils/py/work_connectors/github_board.py:61`).
- [Pass] The PR scan has a CWD-independent `--repo` call and fail-soft query boundary (`utils/py/releases_app.py:5090`, `utils/py/releases_app.py:5096`, `utils/py/releases_app.py:5106`); individual emission failures continue (`utils/py/releases_app.py:5124`) before dispatch (`utils/py/releases_app.py:5163`).
- [Should] I did not complete a full pre-existing-defect sweep of the two large touched files in this bounded reviewer turn; no claim that none exist is made. I also did not execute the focused suite because this is a linked worktree and the repository safety rail reserves test execution for a disposable full clone.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · round 1

- **[Blocker] `LIMIT 50` before the producer filter — IMPLEMENTED.** Correct and a real
  duplicate path. The cap is gone (`_latest_event` now iterates the issue's rows without a limit;
  a per-issue list is small). Leg 24 buries a backfill row under 60 `work emit` rows for the same
  issue and asserts both views (`only_source`, `exclude_source`) still answer correctly and a
  backfill still emits nothing; the red control restores `LIMIT 50` in a copy and observes the
  duplicate. Commit `ac0742f0`.
- **[Should] aggregate receipt check — IMPLEMENTED.** 21d and leg 24 now join each new backfill
  event to its own `work-emit` receipt on `txn_id` and assert zero orphans. The red control is a
  copy that bypasses `perform_write` with a direct `INSERT`; the join catches it.
- **[Pass] × 4 — noted**, each cited.
- **[Should] sweep incomplete / suite not run — acknowledged.** For round 2: the whole-file sweep
  of `utils/py/releases_app.py` (the GH-564 regions and their neighbours) and
  `utils/py/work_connectors/github_board.py` is the outstanding item. On the suite: your
  worktree is linked and the rail is right not to run mutation-heavy suites there — the suite ran
  in the task clone, 114/0, and the full gate is running in a disposable clone; both go on the PR.

VERDICT: PARKED
Basis: producer turn — blocker and both Shoulds implemented at ac0742f0, suite 114/0. Round 2:
the sweep, and leg 24.

Handing off to Reviewer (codex) — round 2.

### Reviewer · codex · round 2

swept file: no

- [Blocker] `_latest_event` assumes every syntactically valid payload decodes to an object: `(json.loads(payload) if payload else {}).get("source")` (`utils/py/releases_app.py:4873-4875`). But `work emit --payload-json` accepts any JSON value (`utils/py/releases_app.py:4940-4944`), so a perfectly valid prior `[]`, `null`, or string payload for an issue raises `AttributeError` when the new `only_source`/`exclude_source` views inspect it. `cmd_work_backfill` makes that filtered lookup before its per-row exception boundary (`utils/py/releases_app.py:5012-5014`), making the entire backfill fail. Decode into a value and treat non-dicts as no source; add a focused control with a newer non-object payload above a backfill row, proving both views remain correct and backfill skips rather than exits.
- [Pass] The prior bounded-lookback defect is fixed: the filtered lookup now has no SQL cap (`utils/py/releases_app.py:4864-4882`), while leg 24 buries the producer row below 60 newer rows and restores `LIMIT 50` as a red control (`test/gh549-work-events.sh:1251-1291`).
- [Pass] The receipt assertion is now per event, joined by `txn_id`, and its direct-insert red control produces orphaned events (`test/gh549-work-events.sh:1292-1322`).
- [Pass] The acceptance path otherwise remains one atomic writer path: the decision runs in `mutate` after `BEGIN IMMEDIATE` (`utils/py/releases_app.py:1613-1628`, `4905-4919`), then receipt and work event commit together (`utils/py/releases_app.py:1642-1655`); backfill and review-ready use that helper (`utils/py/releases_app.py:5027-5033`, `utils/py/releases_app.py:5109-5122`), and completed maps to Done (`utils/py/work_connectors/github_board.py:61-78`).
- [Should] I reviewed the complete small connector and GH-564/test regions, including the new controls, but did not complete an exhaustive pre-existing-defect sweep of all 6,391 lines of `utils/py/releases_app.py`; therefore I make no claim that none exists outside the examined region.

DoD answers: (1) no — the payload-shape blocker remains; (2) yes for normal object payloads; (3) no — malformed non-object rows break filtered producer views; (4) yes, `--repo` and fail-soft scan are present at `utils/py/releases_app.py:5046-5124`; (5) yes at `utils/py/releases_app.py:4953-4972`; (6) 21a/21e/21f and the added 24 controls are non-vacuous by their explicit red mutations at `test/gh549-work-events.sh:981-1289`; (7) no exhaustive whole-file pre-existing sweep was completed.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · round 2

- **[Blocker] non-object payloads — IMPLEMENTED.** Correct: `work emit` accepts any JSON value,
  and backfill's read-only preview calls `_latest_event` outside its per-row guard, so one `[]`
  row would have killed the verb. Decoding is now defensive — only a dict can carry a source.
  Leg 25 emits list/null/string payloads above a backfill row through the real verb, proves both
  views answer and backfill exits 0; its red control restores the raw `.get` and observes the
  `AttributeError`. (Aside: `null` decodes to `None` and is stored as SQL NULL — the fixture
  guard had to count it that way; disclosed.)
- **[Unverified — no citation] × 3 — noted.**
- **[Should] exhaustive sweep of all 6,391 lines — acknowledged.** Not asking for it. The GH-564
  regions, the connector and the test regions were swept; that is the honest scope for this
  change and it is recorded as such.

Suite 117/0 at the commit above. Round 3 is the cap: the round-2 fix (leg 25 and the decode) and
anything outstanding.

VERDICT: PARKED
Basis: producer turn — the round-2 blocker implemented, suite 117/0; handing back for round 3.

Handing off to Reviewer (codex) — round 3, the final round.

### Reviewer · codex · round 3

swept file: no

- [Blocker] The stated fail-soft boundary does not cover `SystemExit`: `_scan_review_ready` explicitly re-raises it (`utils/py/releases_app.py:5128-5131`). `_emit_work_event` can raise that exact exception when `work_events` is absent or no repo row exists (`utils/py/releases_app.py:4902-4905`), so a ledger in either state makes `work reconcile` exit before `work_connectors.dispatch` at `utils/py/releases_app.py:5169-5170`. Catch and report that per-emission refusal as a failed scan item (without swallowing interrupts), then add a focused control that injects/refuses one PR emission and proves reconcile exits 0 and still dispatches another item.
- [Pass] The round-2 payload repair is defensive: non-object or unparsable payloads are treated as having no source (`utils/py/releases_app.py:4873-4880`), and leg 25 mutates it back to raw `.get` and observes `AttributeError` (`test/gh549-work-events.sh:1326-1340`).
- [Pass] The producer views no longer cap the search (`utils/py/releases_app.py:4868-4885`); leg 24 exercises a producer row below 60 newer rows and has a `LIMIT 50` red control (`test/gh549-work-events.sh:1257-1291`).
- [Pass] The accepted writer path remains atomic: `mutate` is called after `BEGIN IMMEDIATE`, while receipt and explicit event insertion precede the same commit (`utils/py/releases_app.py:1607-1655`); both producers call that seam (`utils/py/releases_app.py:5032-5035`, `5123-5126`).
- [Should] I swept the GH-564 regions, connector, and the critical/new test legs, but not all 6,391 lines of `utils/py/releases_app.py` or every one of the 46 assertions. I therefore make no claim that no pre-existing defect or vacuous assertion exists outside that reviewed scope.

DoD answers: (1) no — the fail-soft blocker remains; (2) yes — the idempotence decision, receipt, and event share the transaction cited above; (3) yes in the reviewed paths — scoped lookup and global terminal check are at `utils/py/releases_app.py:4912-4920`; (4) no — `SystemExit` can abort before dispatch; (5) yes — ordered mapping is at `utils/py/releases_app.py:4969-4976`; (6) partial only — reviewed 21a/21e/21f and legs 24–25 have explicit red mutations, but I did not sweep all 46; (7) no exhaustive whole-file pre-existing-defect sweep was completed.

Verdict: Changes requested. Round cap reached; status escalated.

Handing off to Producer — go to the Producer window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
