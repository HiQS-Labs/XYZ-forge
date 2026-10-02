# RELAY · 2026-10-02 fold ledger preservation follow-up QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-fold-ledger-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed fold branch at SHA 727c79aa, especially releases.sql and releases.db, against pinned development SHA 75b75181. Read the prior independent review in relay-system/2026-10-02/pr-fold-qa.codex.md first; its B1 finding prompted the repair.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: independent read-only follow-up on B1, with PASS/FAIL/PARKED and citations. Confirm that all seven development work events for GH-896/GH-901 retain their original GIDs and payloads, and GH-896 retains its original `in-progress` status/accepted-start event and GID. Compare all nine added roadmap rows and GH-506/GH-896 updates by business fields to the pre-repair fold commit `612ba69c`, allowing a deliberate GH-896 status-label correction and fresh IDs/timestamps/positions. Confirm the four Jog additions and existing queue rows have intended state. Check `releases.sql` and `releases.db` agree using read-only probes. No new code changes were made. Do not run tests or mutating commands in the relay worktree; final `ci-local.sh` will run separately in a disposable full clone after this receipt is committed. Treat a concrete remaining data loss as a blocker. Explicitly state `swept file: yes` or `swept file: no` and explain scope.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS

Basis: B1 is repaired at `727c79aadf9f5a77d72f704c8c1bb24b78303158`. Development's original accepted state and history survive; the fold's intended business changes and queue state survive; the complete SQL dump agrees with the committed database. This approves the ledger-preservation follow-up, not publication or the outstanding disposable-clone gate.

swept file: yes

Scope: every statement/row of `releases.sql` and every table of `releases.db`, including pre-existing data, against development `75b75181299d605b5458dbf4fd367680a05cbb53` and pre-repair fold `612ba69c639bae5719e920c25e8b45d7c2e20558`. Whole-tree object comparison checked the no-code-change claim; this is not another whole-source audit of the seven PRs. SHA-1-validated object reads supplied pinned snapshots without invoking Git. SQLite opened with `mode=ro&immutable=1`; SQL literals were parsed independently, retaining NULLs and resolving DB foreign keys to GIDs. All probes used `PYTHONDONTWRITEBYTECODE=1` and scratch-only temporary paths. The nearest available graph is another checkout, generation `2026-10-02T14:56:13Z`; its coverage excludes the DB and lacks this relay. Direct pinned data, not that graph, supports this review. No suites, executable fixtures, application writers, commits or artifact edits ran.

- **[Pass] B1: all seven original events and GH-896's authority are preserved.** The five GH-896 and two GH-901 development events match in every dumped field, including original GIDs, payload strings, transaction IDs and timestamps (`releases.sql:2846`–`:2852`). GH-896 retains row `rmi-01M3SBWHWGSWAFVKTW7ZAE1MMX` and `status_label='in-progress'` (`:773`). Accepted-start event `wev-01M3SDW9K2KKMCRCBAS3TMY2F7` still contains `"accepted_start": true` at `2026-09-30T15:10:40Z` (`:2849`). Its only additional event is a metadata `updated` with `"transition": false` (`:2895`), not a replacement start. Probe `python3 .relay-scratch/ledger.py`, exit **0**: `BASE_7_EVENTS_EXACT` listed all seven matches. `python3 .relay-scratch/final-check.py`, exit **0**: `GH896_label in-progress missing_original_events 0`, event counts `[('896', 6), ('901', 2)]`. Negative control `python3 .relay-scratch/final-check.py red`, exit **1** against the actual pre-repair snapshot: `GH896_label None missing_original_events 7`, `AssertionError: GH-896 accepted status missing`. No fix requested.

- **[Pass] All nine additions and both intended updates retain business fields.** GH-825/856/882/904/905/906/907/911/922 (`releases.sql:778`–`:786`) match `612ba69c` after excluding only global ID, first-seen/write timestamps and position. GH-506 (`:685`) matches too: Deferred section, retired `PROJECT/4-MISC/` path, five NULL rating fields. GH-882 retains its working path, 🚧 and `in-progress` (`:786`). GH-896 (`:773`) differs from pre-repair business fields only by the deliberate NULL → `in-progress` correction; its normalized rating text is preserved. Probe `python3 .relay-scratch/ledger.py`, exit **0**: `ADDED_ROADMAP ['825', '856', '882', '904', '905', '906', '907', '911', '922']`; each `ROADMAP_BUSINESS_DIFF` was `{}`, except GH-896's `{'status_label': (None, 'in-progress')}`. No fix requested.

- **[Pass] Jog additions and existing rows retain intended state.** GH-904/907/906/905 are pending at positions 1/2/3/4, with zero attempts and NULL lease/failure fields (`releases.sql:798`–`:801`). Their roadmap entries remain queued with their working-doc paths and ratings (`:781`–`:784`). Existing pending GH-554/555/307/313 remain at 5/5/6/7 (`:802`–`:805`), exactly +4 from development; all existing terminal rows are unchanged. The duplicate position 5 was already present in the pre-repair fold/source resolution, as the prior review recorded. Probes `python3 .relay-scratch/ledger.py` and `python3 .relay-scratch/final-check.py`, both exit **0**: `ALL_JOG_BUSINESS_MATCH 18`, `BASE_JOG_ALL_14_RETAINED pending shift +4 only; terminal rows exact`. No repair regression or additional queue fix requested.

- **[Pass] Whole-ledger preservation and SQL/database agreement.** All 511 development work events and 1,510 operation receipts survive exactly; the repair adds 35 events and 37 receipts. All 295 other existing roadmap rows are exact, including both NULL-issue-number rows; their 293 NULL labels remain NULL. Ten other populated tables have no base-row differences. All **2,858 rows across 15 populated tables** match the immutable DB after integer-key-to-GID normalization; the sixteenth table, `connector_cursors`, is empty. This includes the quoted accepted-start and queue rows above, rather than only aggregate counts. Probe `python3 .relay-scratch/ledger.py`, exit **0**: every `DB_SQL_MATCH` passed, all reported base-table missing counts were `0`, and `ALL_CHECKS_PASS`. `python3 .relay-scratch/final-check.py`, exit **0**: `TOTAL_ROWS_DB_SQL_MATCH 2858`, `INTEGRITY ok; FOREIGN_KEYS 0 violations`, `WORKTREE_MATCHES_PINNED_SQL_DB True`. Whole-tree object comparison reported only `releases.sql`, `releases.db` and `LEADERBOARD.md` changed since `612ba69c`; no code changes were introduced by the repair. No fix requested.

- **[Nit] Pre-existing evidence irregularity, unchanged by this repair.** Four GH-740/GH-741 events at `releases.sql:2642`–`:2645` have transaction IDs absent from `op_receipts`. For example, `wev-01M334NS5ZT896PYFZBPFAT5HV` names `7eb3ebcf18974f9ba5b1ee17a4d7276b`. An initial broader receipt assertion in `python3 .relay-scratch/final-check.py` exited **1**. A read-only comparison (`python3 -`, exit **0**) found the same four unmatched events, with identical full records, in development, pre-repair and repaired snapshots. The refined preservation probe exited **0** with `NEW_EVENTS_HAVE_RECEIPTS 35 BASE_UNMATCHED_UNCHANGED 4`. This establishes historical evidence incompleteness, not new fold loss or a demonstrated runtime failure. Follow-up: inspect those original transactions if receipt provenance is separately reconciled; do not fabricate replacement events or receipts in this repair. No other concrete pre-existing ledger defect was established by this bounded sweep.

- **[Unverified — needs clone run] Final qualification remains outstanding.** Per Setup, the harness must run `ci-local.sh` separately in a disposable full clone after this receipt is committed. No claim is made about runtime suites, application receipt-chain validation, or live GitHub projection.

Relay closed (Approved), no further review turn needed. Producer / claude-a resumes the separately required disposable-clone gate. The harness owns the one-file commit; this reviewer made none.


### Attestation · relay-drive — 2026-10-02T16:44:09Z
task: RELAY-pr-fold-ledger-qa-2026-10-02
reviewer: codex
status: Approved
reviewed-head: 77ec0d5e6c95d2be4f93c475d4b898091bc95fe0
added-range: 6299+6683
added-sha256: 86b47115fb6151e6545b6146e2d4df29217c2ffb4a5134b77776e53d73f05770
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
