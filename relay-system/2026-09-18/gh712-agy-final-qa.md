# RELAY · GH-712 Jev ATE triage final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh712-agy-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **SUMMARY.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-18

### Artifact — SUMMARY.md
```
# GH-712 — Offline Jev vs Tier-1 / Gemma ATE triage replay

Date: 2026-09-18 · Model: `jev-1.13.0` on every response (217/217) · Input tokens: 73,208 (benchmark) + 144,629 (error log) = 217,837 (~$0.009 at $0.042/Mtok) · Live runs, not mocks (`summary.json` → `"mock": false`) · Tool: `utils/py/jev_triage.py` at the commit that carries this directory.

## Decision

**Phase 2 gate missed on both counts → Phase 3 (the `--classifier` shadow flag) was not started.** No change to `run_variations.py`, `tier1_classify`, or the calibration file.

| Gate (plan §Ordered implementation 3) | Required | Observed | Met |
|---|---|---|---|
| Benchmark FN at argmax (24 known-fail rows) | 0 | **1** (4.17%) | no |
| GH-141 `status` agreement with Gemma | ≥ 90% | 100.0% (143/143) | yes |
| GH-141 `category` agreement with Gemma | ≥ 80% | **4.2%** (6/143) | no |
| GH-141 `severity` agreement (reported, not gating) | — | 48.95% (70/143) | n/a |

## Replay 1 — Tier-1 benchmark (`calibrate_tier1.py --emit-benchmark`, 74 rows: 50 pass / 24 fail)

| | Jev pass | Jev fail |
|---|---:|---:|
| label pass (50) | 50 | 0 |
| label fail (24) | **1** | 23 |

- FN = 1, FP = 0. `fn_zero_threshold` = **0.48**: the one missed row carried P(fail) = 0.48; every other known-fail row had P(fail) ≥ 0.48 and every known-pass row had P(fail) < 0.48, so a decision threshold of 0.48 would give FN = 0 and FP = 0. That is one number recorded per the plan, not a tuned threshold — the gate was defined at argmax and is missed.
- The missed row: `exit_code 0`, `stderr "Segmentation fault"`, 2,000 ms. Tier-1 calls it `anomaly` ("rc=0 but stderr looks like crash"). Jev: `status pass` with **confidence 0.05**, `category crash` (0.75), `severity none`. Jev saw the crash (category) but followed the zero exit code for status; the near-zero confidence is the model saying the two signals conflict. A confidence gate would have routed this row to review; the plan did not define one.
- Tier-1 agreement: 65 agree, 0 disagree, 9 Tier-1 `anomaly` rows (8 → Jev `fail`, 1 → Jev `pass`, the row above).
- Category on known-fail rows: crash 9, config_error 7, env_missing 3, env_failure 3, timeout 1, ok 1 (the missed row). Severity: critical 22, none 2 (the missed row and one other rc=0 row).

## Replay 2 — GH-141 error log (143 rows, all exit 2, all `edited: false`, `expects_edits: true`)

| Field | Agreement | Gemma → Jev pairs |
|---|---:|---|
| status | 143/143 (100%) | fail→fail 143 |
| severity | 70/143 (49%) | critical→critical 70, high→critical 73 |
| category | 6/143 (4.2%) | auth_failure→env_missing 103, auth_failure→config_error 23, config_error→env_missing 9, config_error→config_error 5, env_failure→config_error 2, env_missing→env_missing 1 |

What the disagreement is, read against the stderr in the log:

- Every row's stderr ends in `<shim>-turn: RELAY_AGENT required` — a missing required environment variable. Gemma labelled 126 of them `auth_failure`; Jev labelled 103 `env_missing` and 40 `config_error`. On inspection Jev's category is the literal one and Gemma's is not, so the 4.2% figure measures disagreement with a Gemma mislabel, not a Jev error. The plan's gate used Gemma as the reference because it was the only label available; this replay shows GH-141's Gemma categories are not a usable reference for that field. The gate is still missed as written.
- Severity: Jev answered `critical` on all 143 (non-zero exit, per the rule in the question). Gemma split the same failure 73 `high` / 70 `critical`. Jev is the consistent one; this is why severity was reported and not gated.
- Jev is not fully consistent on category either: of 7 distinct stderr tails, 3 received mixed `env_missing` / `config_error` answers across rows (the `command` differs per row, so inputs are not identical). Category confidence: min 0.34, median 0.53. Status confidence: 1.0 on every row.

## Caveats

- The benchmark is the harness's own synthetic 74-row corpus shaped like real failures, not field data; its labels are known by construction.
- GH-141 is homogeneous (one failure cause, 143 times), so agreement there is a consistency check, not a discrimination test — and its Gemma reference is itself wrong on category.
- Two live runs, one model version, no prompt iteration after the first request. Question wording is frozen in `utils/py/jev_triage.py` at this commit.
- `rows.jsonl` carries verdicts, confidence, model, and request/response sha256 per row — no stderr text, no key.

## What would change the decision (operator call, not taken here)

1. Re-gate the benchmark with a recorded decision threshold (0.48) or a confidence floor (route status confidence < 0.5 to Tier-1's `anomaly` path) — 2 of 74 rows had status confidence < 0.5, both the conflicting-signal kind.
2. Replace the GH-141 category reference with a hand-labelled sample before re-measuring category agreement; the current reference cannot be met by a correct classifier.

Both are new decisions with their own gates; neither is implied by this result.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Definition of Done and review questions (Reviewer: answer every numbered item)

**Goal.** Final QA of the GH-712 implementation against its approved plan (`PROJECT/2-WORKING/GH-712-JEV-ATE-TRIAGE.md`, approved r2 in `relay-system/2026-09-18/gh712-codex-plan-qa.md`). The receipt is embedded above. The Phase 2 gate was missed, so the deliverable is the module, the test, the evidence and an honest negative result — Phase 3 was deliberately not started.

**Operational envelope.** One stdlib module (`utils/py/jev_triage.py`), one bash test with canned responses, fixtures, a results directory, a changelog entry. `run_variations.py`, `adaptive_ate.py`, `calibrate_tier1.py` and `utils/ate/tier1-calibration.json` must be untouched. Grade against the plan and commensurate complexity.

**Read in the worktree (read-only):** the plan; `utils/py/jev_triage.py`; `test/gh712-jev-triage.sh`; `test/fixtures/gh712/*`; `TESTS-RESULTS/2026-09-18+GH-712/{benchmark,errorlog}/summary.json` and the first rows of each `rows.jsonl`; `CHANGELOG.md` top entry; `git diff --stat origin/development...HEAD`.

**Questions.**

1. Untouched surfaces: confirm from the diff stat that `utils/ate/scripts/run_variations.py`, `utils/py/adaptive_ate.py`, `utils/py/calibrate_tier1.py` and `utils/ate/tier1-calibration.json` are unchanged.
2. Requirements 1–2 of the plan: cite the lines in `jev_triage.py` for the three Choice questions and their label sets (`env_missing` present), the 1,500-char tails, `expects_edits` rule selection, urllib-only with 3-attempt retry honoring `retry-after`, `--mock-responses` ordered replay, `fn_zero_threshold`, empty input → exit 2, `rows.jsonl` without stderr.
3. Gate arithmetic: from `benchmark/summary.json`, is FN = 1 / FP = 0 / `fn_zero_threshold` 0.48 consistent with the confusion counts and the rule "FN = label fail → jev pass"? From `errorlog/summary.json`, do the pair counts sum to 143 per field and match the agreement percentages in the receipt?
4. Test adequacy: does `test/gh712-jev-triage.sh` include the green control (FN = 0 on matching answers) and the red control (FN = 1), empty input, hash/model contract, no-stderr and no-key refusal? Anything that lets a hardcoded scorer pass?
5. Receipt honesty: does `SUMMARY.md` state that both gates were missed, why Phase 3 was not started, the Gemma-reference problem on category, and the confidence observation, without claiming a pass or a re-gate? Any claim the files do not support?
6. Publication safety: any key material or stderr text in `TESTS-RESULTS/2026-09-18+GH-712/`? Cite the fields `rows.jsonl` does contain.
7. Surface and machinery: anything beyond the envelope, or any file outside the plan's smallest affected surface?
8. Plan status/QA gates table and the changelog entry: truthful and consistent with the evidence?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with `file:line` or quoted-span citations; behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. Then a Verdict. `swept file: yes|no` line required.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
