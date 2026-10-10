# RELAY · GH-1003 PR 966 generated-view correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh-1003-pr-966-generated-view-correction-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: merge-cleanup
- Started: 2026-10-09
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Narrow renewed review

Goal: verify the generated-view correction to the already reviewed merge candidate. Read the previous complete review at relay-system/2026-10-08/gh1003-pr966-merge.codex.md and the correction commit 4a965bff58c50b9bada89ad78c6230dec5112058. The previous review independently passed both entire parent changelogs, all ledger tables/receipts and normal code merge. Its only requested correction on #953/#966 was the routine LEADERBOARD delta. #971 also removes its routine view delta for the same binding policy.

The correction changes exactly LEADERBOARD.md to integration-parent blob 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1:LEADERBOARD.md; it changes neither authoritative ledger nor code nor changelog. The original view bytes are preserved in primary scratch, not deleted. Review the changed file in full and compare object/blob identities. Do not repeat the already completed full-ledger sweep unless an unexpected artifact difference is observed. This is a bounded metadata correction, no new behavior or machinery.

Questions:
1. Does the corrected view exactly match the integration parent, satisfying AGENTS.md's rule that routine views belong to hosted reconciliation?
2. Are authoritative ledger, changelog and runtime/source blobs identical to the previously reviewed passing resolution?
3. Is the prior Should finding resolved with no new defect in this correction? Return Approved or specific Changes requested with observed input/falsifier; cite the previous receipt and correction head.

The final-head release check and relevant existing gate run belong in a separate full clone. Do not run suite/pytest/fixtures or change artifacts. Edit only this transcript.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for the bounded generated-view correction at `4a965bff58c50b9bada89ad78c6230dec5112058`. The prior Should is resolved; authoritative artifacts and source retain the earlier passing resolution. Final-head gate/release checks remain the Producer's separate disposable-clone work.
swept file: yes

Scope: all 309 lines of `LEADERBOARD.md`, full mode/blob maps for the correction, its direct parent, previously reviewed candidate and integration parent, and the complete previous receipt. No new or pre-existing defect affecting this correction was found. Graph coverage belongs to the original checkout at generation `2026-09-01T15:54:30Z`, with changed/unknown metadata, so this review uses direct file reads and SHA-1-checked stored loose/packed objects without invoking Git. No full-ledger audit was repeated.

- [Pass] **Integration-parent view restored exactly; prior Should resolved.** `LEADERBOARD.md:1` is `<!-- releases-app generation: 1481 -->`; `AGENTS.md:54` and `:56` assign routine views to hosted reconciliation. Correction `4a965bff58c50b9bada89ad78c6230dec5112058` and integration parent `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1` both reference leaderboard blob `86a63289f4def9c436de2419377ed8379cfabe17`. The worktree matches all its bytes. This meets the falsifier in `relay-system/2026-10-08/gh1003-pr966-merge.codex.md:96` for the Should at `:93`. Probe `python3 "$TMPDIR/object_compare.py"` exited 0: `leaderboard_exact_parent_and_worktree True bytes 66283 lines 309`; `correction_vs_direct_parent ['LEADERBOARD.md']` against direct parent `f74d7ea7498df68ae86c86ca05db818833428572`. No fix requested.

- [Pass] **Ledger, changelog, evidence and source retain the reviewed resolution.** Earlier passing findings at `relay-system/2026-10-08/gh1003-pr966-merge.codex.md:98`, `:100`, `:102` and `:104` cover candidate `3283b42d1ca138bfc1d5e3cc43bccb7eec6489f0`. The same object probe (exit 0) printed `correction_vs_previous_review ['LEADERBOARD.md', 'relay-system/2026-10-08/gh1003-pr966-merge.codex.md']`: the second path is the review receipt itself. All 5,753 remaining tracked modes/blobs match, including runtime/source and committed merge evidence. Unchanged blobs: `releases.sql` = `2094c6d7321bc81e9a22b13b9a582cb91b20b4da`; `releases.db` = `5ac4effc53bbd2f1863f21d1fe2015b938027e5e`; `CHANGELOG.md` = `c5694e764046dc61fe5dd6c38a05e5f82fce2b5a`. Their working files also match. Seeded head `48664ea247fbea53dceba3442ebb98f781bbb42e` differs from the correction only by this renewed transcript. No fix requested.

- [Pass] **Whole-view structure and scoring are sound.** `LEADERBOARD.md:6` describes the axes, `:12` names 11 columns, and `:306` names the leading score. Manual probe `python3 "$TMPDIR/view_probe.py"` exited 0: `whole_view_rows 292 column_count 11 ordinals_axes_calc_override_sort True`. Every row has the declared columns, contiguous ordinal, bounded axes, correct sum/override and descending score. The equality assertion rejected the old candidate blob `6704bb66d5843965d28118c44d9591de0c07a321`, printing `prior_candidate_parent_equality_red_control: AssertionError (expected)`; current bytes printed `corrected_worktree_parent_equality_green True`. An initial inline table probe exited 1 because it incorrectly expected 12 columns; the corrected probe follows the 11-column header. No artifact failure or fix requested.

- [Unverified — needs clone run] **Final-head release check and existing gate remain pending.** `relay-system/2026-10-08/gh1003-pr966-merge.codex.md:106` and `TESTS-RESULTS/2026-10-08+GH-1003/pr-966/provenance.jsonl:1` leave final-head validation pending. No suite, pytest, executable fixture or Git command was run here. This approval closes correction QA and does not attest the final-head gate.

Relay closed (Approved), no further review turn needed. Producer (merge-cleanup) continues with final-head release/gate checks in a disposable full clone; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-09T07:09:05Z
task: GH1003-PR966-MERGE-QA-R2
reviewer: codex
status: Approved
reviewed-head: 48664ea247fbea53dceba3442ebb98f781bbb42e
added-range: 6966+4029
added-sha256: 29e261dd016ce4277cfa2e313ae26d8e60efb29dea7bc1db4d7f6c6978f8c5a6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
