# RELAY · GH-1003 PR 971 generated-view correction QA
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
6. **Commit only the relay file** (`relay(gh-1003-pr-971-generated-view-correction-qa): <role> r<N>`); no push. **Stop** and report one line.
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

Goal: verify the generated-view correction to the already reviewed merge candidate. Read the previous complete review at relay-system/2026-10-08/gh1003-pr971-merge.codex.md and the correction commit 9ce8e5b28ac4ba150548c97db8ab9c093f879f4c. The previous review independently passed both entire parent changelogs, all ledger tables/receipts and normal code merge. Its only requested correction on #953/#966 was the routine LEADERBOARD delta. #971 also removes its routine view delta for the same binding policy.

The correction changes exactly LEADERBOARD.md to integration-parent blob 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1:LEADERBOARD.md; it changes neither authoritative ledger nor code nor changelog. The original view bytes are preserved in primary scratch, not deleted. Review the changed file in full and compare object/blob identities. Do not repeat the already completed full-ledger sweep unless an unexpected artifact difference is observed. This is a bounded metadata correction, no new behavior or machinery.

Questions:
1. Does the corrected view exactly match the integration parent, satisfying AGENTS.md's rule that routine views belong to hosted reconciliation?
2. Are authoritative ledger, changelog and runtime/source blobs identical to the previously reviewed passing resolution?
3. Is the prior Should finding resolved with no new defect in this correction? Return Approved or specific Changes requested with observed input/falsifier; cite the previous receipt and correction head.

The final-head release check and relevant existing gate run belong in a separate full clone. Do not run suite/pytest/fixtures or change artifacts. Edit only this transcript.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approve the bounded generated-view correction at `9ce8e5b28ac4ba150548c97db8ab9c093f879f4c`, seeded at `cfd57d7d08c4830713cbd5c99bdf3263d3548e45`. The entire view equals the integration parent; authoritative data and source remain identical to the previously approved candidate. Final-head release check and existing gate remain pending in a separate disposable full clone.
swept file: yes

Scope: read all 309 lines of `LEADERBOARD.md`, the complete prior receipt, and SHA-verified commit/tree objects. No new or additional pre-existing defect affecting this bounded correction found. Nearest indexed XYZ project is a different checkout, generation `2026-10-09T06:48:49Z`; coverage marks both relay paths missing and DB excluded. Direct local bytes and objects supply this review's evidence; no structural graph completeness claim is made.

- [Pass] **Routine view delta removed exactly.** `AGENTS.md:54-58` assigns routine views to hosted reconciliation; `LEADERBOARD.md:1-2` retains the integration parent's generation **1481** and generated-file notice. Correction and integration `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1` both reference blob `86a63289f4def9c436de2419377ed8379cfabe17`, including file mode; working bytes match. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 "$TMPDIR/view_object_probe.py"` (read-only standard-library loose/packed object reader, verifying SHA-1 for every accessed object). Exit **0**; decisive output: `"correction_changed_paths ['LEADERBOARD.md']"`, `"leaderboard_blob 86a63289f4def9c436de2419377ed8379cfabe17 integration_blob 86a63289f4def9c436de2419377ed8379cfabe17 working_bytes 66283 lines 309"`. Red controls: `"red_control_byte_mutation_equal False"` and `"red_control_prior_view_equal False"`; changing one byte and substituting the old candidate view both fail equality. Fix: none.

- [Pass] **Previously approved ledger, changelog and source preserved.** Prior approval is `relay-system/2026-10-08/gh1003-pr971-merge.codex.md:87-101`, candidate `bf746fb42ecdd38810d8b6b652a20724181f9df0`; its attested head is at line **110**. Same object-probe command, exit **0**: `"correction_vs_previously_reviewed_candidate ['LEADERBOARD.md', 'relay-system/2026-10-08/gh1003-pr971-merge.codex.md']"`, `"nonview_nonrelay_differences []"`, `"identical_nonview_nonrelay_leaf_entries 4869"`. Identical blob IDs across prior candidate, correction and seed: `releases.db = 7530c4a30767f9d4a84a474c55a0e1060f2f23d7`; `releases.sql = a40097e61c85376fa75bd737d6007a2521264828`; `CHANGELOG.md = 37f422ccab59ea5f4a7947c6a9905d41fe8fac0f`. Their working bytes also match. Seed differs from correction only by this renewed relay file. No ledger sweep was repeated because no unexpected artifact difference exists. Fix: none.

- [Pass] **Complete restored view is internally consistent; shared routine-view concern resolved.** `LEADERBOARD.md:6-13` defines sum/override ranking and the table; lines **14-305** contain 292 rows, and line **307** correctly names GH-474 at score 360. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` with a read-only parser splitting on unescaped pipes and asserting nonempty input, 11 columns, ranks 1–292, axis bounds/sums, override ranking, descending scores and unique GH identities. Exit **0**; decisive output: `"292 nonempty rows: 11 columns, contiguous ranks, axis sums, override scores, descending order, unique GH identities PASS"`, `"top (1, 360, '474') last (292, 4, '413')"`. In-memory first-rank mutation produced `"red_control_rank_mutation_valid False"`. The PR #971 prior receipt itself was PASS with no requested fixes (line **101**); it accepted the generated projection (line **99**). This renewed approval addresses the shared policy concern described above, without inventing a prior Should in that receipt. Generation 1481 intentionally awaits hosted refresh; it does not claim parity with ledger generation 1486. Fix: none.

Required fixes: none. [Unverified — needs clone run] Final-head release check and relevant existing gate must be supplied by the harness before landing, as already required by the prior receipt at line **101**. No git process, suite, pytest or executable fixture was run; only this transcript changed outside permitted scratch. Probe outputs are quoted here because scratch is discarded.

Relay closed (Approved), no further review turn needed. Handing the completed result to Producer **merge-cleanup** for the separate final-head checks and landing decision.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
