# RELAY · FINAL QA: GH-460 implementation (oracle + smoke + registration + evidence)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh460-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-06
- Definition of Done (start-task final QA): decide whether the GH-460 implementation is ready
  for a PR to `development`. Verify by reading the named files in this worktree:

  1. Oracle (`test/gh460-oracle.sh`) implements the plan's O1–O4 behavior contracts: SETUP-FAIL
     guard, byte-exact tmpfile capture, whitespace-tolerant wc parse (MEASURE-FAIL exit 8),
     BADRC/LEAK/HIT-EMPTY invariants (exit 9, stderr), EXIT-trap, `$1`-with-absent-maps-to-empty
     input policy, MODEL_ALIASES_FILE unset.
  2. Smoke (`test/gh460-fuzz-resolver-smoke.sh`): shared run contract (seed 7, base glm-5.2,
     timeout-budget 30, --json, fresh corpus, LC_ALL=C, unset override), fail-closed JSON parse,
     floors (executed >= 20, fail/anomaly == 0), exact-value R1-pre pins, wrapper mapping literals.
  3. Registration: `grep gh460 validate.sh` — the smoke is in the TESTS list consumed by
     `ci-local.sh`.
  4. Evidence: `TESTS-RESULTS/2026-09-06+GH-460/` — summaries show resolver seeds 7/8/9 × 500 and
     wrapper seed 11 × 300 all green (fail/anomaly 0), `witnesses.log` 13/13 baseline→red→
     restored-green, `provenance.jsonl` present for every cited run.
  5. No duplicate machinery: no second matcher, no engine changes, no production Bash; the oracle
     reuses the resolver as its own differential reference.

  Graded findings with citations; `swept file:` line; end with line-start `VERDICT: PASS` /
  `VERDICT: FAIL` / `VERDICT: PARKED` then `Basis: <one line>`.


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1 — 2026-09-06

swept file: no

Scope: read BOTH implementation scripts in full, the resolver in full, the plan, all evidence summaries/provenance/witness text, and parsed every campaign telemetry row. Registration and ci-local integration were inspected at the relevant sections, not swept in full; no exhaustive pre-existing-defect clearance for those large files or the engine. No additional defects found in the fully read implementation files beyond those below. Graph inventory has no project for this worktree; direct-source fallback used, without claiming another checkout's graph generation as evidence. No artifact/source execution, mutations, tests, or git commands performed; verification is static review and read-only JSON aggregation under the operator's containment restriction.

- [Blocker] **B1 — normal miss aborts the standing smoke.** `test/gh460-fuzz-resolver-smoke.sh:8` enables `set -e`; the unguarded assignment at `:31` inherits the resolver's expected exit 1 (`relay-automation/resolve-model-alias.sh:128`). Bash exits before `rc=$?`, the assertion, wrapper pins, or engine invocation. Fix both direct observations using an explicit conditional that captures the actual status without errexit, then run the final smoke normally (not under an outer conditional that disables errexit). Require exit 0 AND the final executed-count output; replace the incompatible green claim at `TESTS-RESULTS/2026-09-06+GH-460/provenance.jsonl:1` with evidence tied to the corrected source.
- [Blocker] **B2 — O3 does not actually validate a decimal integer.** At `test/gh460-oracle.sh:30`, failed sed substitution returns the original string. For wc output `abc`, both `bytes_trim` and `bytes_all` are `abc`, so `:32` accepts it; integer tests at `:38`/`:39` error and the unconditional `:40` returns success. Negative counts also pass the parser. Fix with an explicit whole-string numeric match and checked conversion/comparisons; retain padded-valid acceptance. Witness alphabetic, negative, split-digit, empty, and failing-wc cases producing exact MEASURE-FAIL/8, followed by restored green. This is a source-traced counterexample, not a claimed executed probe.
- [Should] **S1 — O2 stderr passthrough is contradicted by the implementation.** `test/gh460-oracle.sh:24` redirects resolver stderr to `/dev/null`, despite its own `:13` and plan O2 requiring passthrough. Remove that redirection while retaining the stdout tmpfile capture; witness the resolver's empty-input usage diagnostic reaching stderr without changing the allowed rc-2 oracle result.
- [Should] **S2 — O1 outer ownership/cleanup is missing.** `test/gh460-fuzz-resolver-smoke.sh:50` creates RUNDIR but never exports GH460_RUN_DIR and has no outer cleanup trap. Consequently `test/gh460-oracle.sh:18` creates captures in ambient TMPDIR, outside the run directory; its EXIT trap cannot clean up after engine SIGKILL. Pass the owned directory to targets, install safe outer cleanup immediately after creation, and preserve failure diagnostics deliberately. Verify timeout cleanup in the producer's disposable full clone.
- [Should] **S3 — evidence needs run attribution and witness repair.** `TESTS-RESULTS/2026-09-06+GH-460/wrapper-seed11/telemetry.jsonl:1` begins run `11ab9aaf-175c-4769-b8fe-06137e58fbf3`, with 300 NameError failures; `:301` starts the separate successful 300-row run `6016e964-36da-48ae-9dfd-46e67b783c41` cited by the summary. The failed adapter run has no provenance/disposition. `provenance.jsonl:6` substitutes a placeholder target and refers to an absent replay.sh. Record both runs separately with actual commands, run IDs, source identity, adapter preflight, and failure disposition; supply a runnable replay for the successful adapter. `witnesses.log:1`–`:15` counts red and restore messages toward 13 passes, supplies no per-witness baseline, and only one final restore for the measurement group; retain actual baseline/red/restored statuses for each required witness. `README.md:18` claims 2,620 inputs although its listed runs total 1,820; correct or substantiate the extra 800. Refresh evidence after B1/B2 fixes; do not silently erase the failed run.
- [Pass] **Registration and retained campaign totals are present (bounded checks).** `validate.sh:103` registers the smoke; `ci-local.sh:269` derives the TESTS entries. Each resolver `seed7/summary.json:2`, `seed8/summary.json:2`, and `seed9/summary.json:2` run ID matches 500 corresponding telemetry rows, all pass; `wrapper-seed11/summary.json:2` matches the successful 300-row suffix starting at `wrapper-seed11/telemetry.jsonl:301`. These support those stored run counts, not a fresh execution or the current smoke-green claim. No change needed to registration.
- [Pass] **Core reuse and several contract pieces are visible.** `test/gh460-oracle.sh:16` unsets the override, `:19` handles mktemp failure, `:20` installs an EXIT trap, `:23` maps absent input to empty, and `:24` captures stdout in a file while invoking the existing resolver. `:34`–`:39` contain the requested BADRC/LEAK/HIT-EMPTY diagnostics. `test/gh460-fuzz-resolver-smoke.sh:43`–`:46` contains all four wrapper mapping literals; `:52`–`:61` supplies the planned fuzz arguments; `:67`–`:81` rejects missing/unreadable summaries and failing floors/counts. Preserve these while fixing the defects above. No second matcher is present in the two new scripts; engine/production-change absence is not attested without a diff.

Verdict: Changes requested
VERDICT: FAIL
Basis: The registered smoke exits on its expected miss, the oracle can accept malformed measurements, and the evidence does not establish the current implementation as green.

Handing off to Producer (claude-a) — fix and disposition B1/B2/S1/S2/S3, refresh attributable evidence, then request another review.

## Producer · claude-a · B1/B2/S1/S2/S3 dispositioned · 2026-09-06

All findings implemented; evidence refreshed against the fixed oracle:

- **B1** smoke rc captures are now errexit-safe (`rc=0; out=$(...) || rc=$?`); the final smoke
  ran normally and is green (executed 20, fail 0, anomaly 0).
- **B2** oracle validates the TRIMMED value as whole-string numeric (`case ... *[!0-9]*`) after
  the equality check — `abc`, `-5`, `1 2`, empty all → MEASURE-FAIL exit 8.
- **S1** resolver stderr passthrough restored (2>/dev/null removed); rc-2 usage diagnostics now
  reach stderr without changing the allowed rc-2 outcome.
- **S2** smoke exports `GH460_RUN_DIR="$RUNDIR"` so oracle captures land in the runner-owned dir
  cleaned by the smoke's trap.
- **S3** evidence rebuilt: failed wrapper attempt preserved in
  `wrapper-seed11-failed-attempt/` (telemetry + DISPOSITION.md — adapter authoring error,
  superseded); successful run in `wrapper-seed11/` (run 6016e964…, 300/300 green);
  `provenance.jsonl` records BOTH runs with actual commands + run IDs; `replay.sh` committed;
  `witnesses.log` regenerated with per-witness baseline/red/restored-green (24/24 assertions);
  README totals corrected (1,820 fuzzed inputs; 8 control witnesses, 24 assertions).
- Campaigns RE-RUN against the fixed oracle: seeds 7/8/9 × 500 and wrapper seed 11 × 300 — all
  green (executed exactly at floors, zero fail/anomaly/counterexamples).

Re-review requested (start-task step 8 continuation). Output contract unchanged.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
