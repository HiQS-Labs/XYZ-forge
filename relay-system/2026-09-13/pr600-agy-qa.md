# RELAY · PR 600 recovery Agy QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: codex
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(pr600-agy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh600-agy-qa.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/gh600-agy-qa.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-09-13
- Definition of Done: Answer all six QA questions with exact source citations; approval requires no material correctness blocker, with live acceptance explicitly pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

swept file: yes

- `[Pass]` **QA1**: Yes, `unreconciled_prs` derives history bounds dynamically from `.github/workflows/wave-reconcile.yml` history (`utils/py/wave_reconcile.py:1128`). It uses full `--paginate --slurp` pagination (`line 1137`), strictly validates API shapes and timestamps (`lines 1146-1157`), and safely handles shallow history (`line 1123`). No-issue PRs are captured as it queries all merged dev PRs. Legacy rows lacking merged PRs are caught in `catch_up_prs` which logs a warning (`line 1228`).
- `[Pass]` **QA2**: Yes. `unreconciled_prs` compares against `committed_qualifications` which explicitly requires `git show HEAD:TESTS-RESULTS/` for validation (`utils/py/wave_reconcile.py:495`). Rejected bot pushes are safely resumed because uncommitted receipts are ignored. A clean no-op correctly exits without invoking `run_subprocesses` or generating empty commits (see `main`'s early return at `line 2107`).
- `[Pass]` **QA3**: Yes. `catch_up_prs` takes the `max()` merged PR for each issue timeline (`utils/py/wave_reconcile.py:1232`). `main` tracks ownership in `issue_owners` (`line 1960`) and skips doc lifecycle updates if a PR is older (`line 2011`). The older PR still receives test evidence because `qualify_landings` only maps `landing_items` (`line 1956`), leaving cache-only metadata untouched.
- `[Pass]` **QA4**: Yes. `find_active_doc_for_issue` uses `sorted()` and anchors the regex `re.match(rf"^(?:GH-)?{issue_num}-", ...)` to deterministically resolve task docs (`utils/py/wave_reconcile.py:898`), bypassing notes like `recon-GH-N`. Issue state semantics correctly preserve OPEN umbrella phased issues (`line 2023`), and `validate_and_update_doc` preserves internal notes while only modifying specific frontmatter fields (`line 1031`).
- `[Pass]` **QA5**: Yes. `gh591-prepush-commit-boundary.sh` successfully isolates `.gitconfig` and templates (`test/gh591-prepush-commit-boundary.sh:15`) to catch hostile environments. `test_red_partial_and_identity_drift_produce_no_receipt` uses negative control fixtures like `wrong-run` (`test/gh425-gate-provenance-pr.sh:258`) to prove the parser rejects invalid telemetry. `test_new_schema_cannot_fall_through_to_legacy_pr_match` explicitly tests malformed `telemetry_sha256` (`test/gh425-gate-provenance-pr.sh:285`). The fixtures are meaningful and provide exact concrete payloads.
- `[Blocker]` **QA6 / Producer #599 finding**: The pre-merge check logic in `utils/py/wave_reconcile.py` (lines `1744` and `1755`) still uses the old loose regex `re.search(rf"(?:^|[^\d])(GH-)?{issue_num}(?:[^\d]|$)", fname)`. If a supporting note like `recon-GH-496-merge-churn-and-telemetry.md` exists alongside `GH-496-SHARPEN-CICD.md`, `run_pre_merge` finds both and fails the gate with "Ambiguous active doc match", halting any PR attempt.
  - **Fix**: Replace `re.search(...)` with `re.match(rf"^(?:GH-)?{issue_num}-", ...)` on lines 1744 and 1755 to match the canonical lookup logic.

**VERDICT**: PARKED
**Basis**: Found a pre-existing blocker in `run_pre_merge` that halts the validation gate. The producer must implement the regex fix before approval. Actual post-merge hosted qualification, next scheduled sweep and three consecutive automatic merge reconciliations remain UNVERIFIED because PRs are unmerged.

### codex disposition — Round 2

- **Implemented QA6:** Both pre-merge lookups now use the same anchored canonical filename rule as post-merge lookup; completed candidates are sorted. Change is three runtime lines at utils/py/wave_reconcile.py:1744,1754-1755. Existing true-canonical ambiguity check is preserved.
- **Witnessed regression:** Added test_pre_merge_ignores_supporting_notes_in_active_and_completed_dirs in test/gh421-auto-wave-reconcile.sh. It exercises both GH-N- and N- forms, forces supporting notes first and includes an unrelated issue suffix. Old source5031172f fails all four cases: active exit6 instead of0, completed sees no canonical schema validation. Current source passes all25 tests and the existing GH496 pre-merge suite. Raw red/green logs and non-qualifying provenance are retained in TESTS-RESULTS/2026-09-13+GH-584/gh600-premerge-{red,green}.log and gh600-gh496-green.log.
- **Review target update:** For this follow-up review use current HEAD for the three-line correction and regression test, with 5031172f as the source before this QA correction. Prior artifact baseline remains useful for the integrated sweep. No other runtime changes. Live hosted acceptance remains UNVERIFIED and merges still require the user's approval. Normal push gate is being run separately in a disposable full clone. Please verify the disposition and record PASS/FAIL/PARKED with exact citations. Do not run suites in this worktree or reach outside it to commit; the shim owns copyback/commit.

Handing off to agy for the corrected recovery review.


### Reviewer (agy) — Round 3

swept file: yes

- `[Pass]` **QA6 (Recovery Verification)**: The producer correctly implemented the canonical lookup fix using `re.match(rf"^(?:GH-)?{issue_num}-", ...)` for `2-WORKING` (`utils/py/wave_reconcile.py:1744`) and for `3-COMPLETED` (`utils/py/wave_reconcile.py:1755`). The regression test `test_pre_merge_ignores_supporting_notes_in_active_and_completed_dirs` was verified in `test/gh421-auto-wave-reconcile.sh:57`, which correctly asserts that both stages ignore supporting notes. I swept the touched files for pre-existing defects and found none.

**VERDICT**: PASS
**Basis**: The single blocker from Round 1 has been resolved exactly as instructed. No material correctness blocker remains.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-09-13T18:18:44Z
task: RELAY-pr600-agy-qa
reviewer: agy
status: Approved
reviewed-head: 4cdb82a2131cffa876e69ae41d4cef677123eff6
added-range: 8910+789
added-sha256: dcaa973b6064ab8e4f219380832a0f5e9745617177ad67a54cfba7df655324c6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
