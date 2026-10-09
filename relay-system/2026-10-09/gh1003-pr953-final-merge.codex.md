# RELAY · GH1003 PR 953 final refreshed merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1003-pr-953-final-refreshed-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: committed candidate ledger, CHANGELOG, routine view and merge qualification evidence
- Reviewer: codex   ·   Producer: Producer
- Started: 2026-10-09
- Definition of Done: independently confirm the final merge preserves both parents and earlier approved runtime, with truthful qualification evidence and no new blocker

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Final refreshed merge review

Candidate before scaffold: bd89143964056a056fe03139bd77e26f229c12ae. Integration parent: f7ee6610160ce05e2b09a6cbca7b7dc4bf75fe4c. Earlier approved complete merge review: relay-system/2026-10-08/gh1003-pr953-merge.codex.md; approved view correction: relay-system/2026-10-09/gh1003-pr953-merge-r2.codex.md. Reuse those reviews for unchanged runtime and prior history; do not repeat their already completed runtime recon. This final delta adds already-landed #979/#999 integration docs, replays only disjoint roadmap row GH998 through existing writer, preserves exact GH998 raw_text using roadmap update after rating normalization, and preserves the integration LEADERBOARD blob. No source/test/registry change.

Read `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/final-refresh-proof.json`, its provenance, original merge and label readbacks, gate results and raw logs. Verify independently against complete git object parents and SQLite tables that both changelogs survive; all earlier candidate/integration business fields survive; roadmap status labels and text match readback; receipt chain/digest and DB/dump are consistent. Writer-owned IDs/positions/admission timestamps can change; no historical admission is backdated. GH998 is Completed/✅ with status_label NULL per canonical lifecycle; GH949/GH912 remain in-progress.

Compare complete candidate tree against tested runtime commit a57884ad3208d2923d59d4e9914ad06939ec8990: only integration docs, authoritative ledger, view, receipts and PARKED finding should differ. The source runtime bytes must stay identical. Check that PARKED/2026-10-09-merge-cleanup-replay-label.md describes the known helper label loss and keeps general repair out of batch.

Qualification truth: isolated full macOS registry exercised all 407 suites with one caller-env failure in gh544-parallel-default (MAX_JOBS=2); the unchanged existing suite passed 29/29 with MAX_JOBS and HARNESS absent. Identity intact in both. Original feature full gate is retained; this is aggregate registry-plus-neutral-control evidence, not claiming the first full run was green. The final pushed head must also pass hosted smoke and the final release check in a second full clone. Judge the bounded merge/evidence now; do not claim hosted final-head qualification already happened.

Safety: pure read review only. Do not run suite, pytest, fixtures, databases with mutating verbs, or change artifacts in this linked review worktree. Only edit this relay. In-memory parsing/comparison is fine. Return Approved or an observed blocker/Should with citations and falsifier.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
