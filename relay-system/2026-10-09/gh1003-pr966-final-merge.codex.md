# RELAY · GH1003 PR 966 final refreshed merge QA
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
6. **Commit only the relay file** (`relay(gh1003-pr-966-final-refreshed-merge-qa): <role> r<N>`); no push. **Stop** and report one line.
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


## Final refreshed merge review

Candidate before scaffold: e2e3f8a88ec646f57d607672e8d3b369b52b7c2e. Integration parent: 1e83bfb9d792d9c2dd4650d2956d9ac182566c12. Earlier complete review: relay-system/2026-10-08/gh1003-pr966-merge.codex.md; renewed approved correction: relay-system/2026-10-09/gh1003-pr966-merge-r2.codex.md. Reuse those complete reviews for unchanged feature/runtime and old history. Incoming #953 runtime and integration receipts already have final Approved QA at relay-system/2026-10-09/gh1003-pr953-final-merge.codex.md and hosted qualification. Do not repeat already approved feature recon; review the final integration/preservation delta and whole artifacts involved.

Read TESTS-RESULTS/2026-10-08+GH-1003/pr-966/final-refresh-proof.json, provenance, gate-result.json, gate-neutral-result.json and raw logs. Independently compare complete parent changelogs as ordered subsequences; complete roadmap business fields and remaining business tables; canonical SQL/DB/digest/receipt-chain consistency; current status labels and exact raw_text. Writer-owned IDs, positions and admission timestamps may change but never backdate admission. Integration completed rows use NULL status_label. Confirm no duplicate issue identity and no business field loss. LEADERBOARD must match exact integration bytes. All incoming runtime differences against tested own candidate 4a965bff58c50b9bada89ad78c6230dec5112058 must match integration blobs exactly. No manually authored runtime/test/registry edits are expected. Account separately for newly added evidence and relay scaffolds.

Qualification truth: the identical small gate first failed with inherited XYZ_HARNESS pointing at primary, identity intact. With XYZ_HARNESS absent it passed validate.sh --sequential --subsystem small, identity intact. Both results and raw logs are committed; this is an environment-neutral successful control, not claiming the original run green. Final exact-head second-full-clone release check and hosted smoke remain outstanding. Keep #964 operator checks / #971 deployed refresh pending; do not execute them.

Graph context: Verify tier current canonical project Users-noelsaw-Documents-GH-Repos-XYZ-forge, root /Users/noelsaw/Documents/GH Repos/XYZ-forge, generation 2026-10-09T08:04:52Z. check_index_coverage reported metadata_match/no_recorded_issue for utils/py/releases_app.py and canonical merge_cleanup.py/ledger_merge.py; current deployed helpers hash match canonical. Coverage is best effort. A seeded review checkout is not this indexed root; use exact local artifacts/object reads for current preservation claims and state any gaps. Relevant source: replay_ops label loss is known and corrected in candidates using existing writer, broader repair PARKED.

Safety: pure read review only. No suite, pytest, fixtures or mutating DB verbs in this linked review worktree. Only edit this relay. In-memory parsing/comparison and red controls are fine. Return Approved or an observed blocker/Should with concrete input, citations and falsifier. Witness at least one preservation/digest red control; retain truthful limits. No promotion or production verification claim.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
