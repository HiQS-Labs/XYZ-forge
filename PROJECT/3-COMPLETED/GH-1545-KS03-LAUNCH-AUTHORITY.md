---
title: "GH-1545 (KS-03): Bake launch authority defaults into build_queue.py and kickstart/SKILL.md"
status: Complete
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
goal: "Bake KS-03 run defaults (CodeRabbit 30-min current-head wait + U5 waiver, KS-11 fail-closed decision defaults, verbatim quota fallback to agy, Flywheel per-PR approval satisfaction) into build_queue.py AUTHORITY and mirror in kickstart/SKILL.md"
gh_issue: 1545
roadmap_id: rmi-01M7W0M2J1GME4PAS6VC3Z93E5
---

# GH-1545 (KS-03): Bake launch authority defaults into `build_queue.py` and `kickstart/SKILL.md`

## Status

| What was just completed | What's next |
|---|---|
| Codex Plan QA Round 2 approved (`98dd3cf1`), implemented KS-03 `AUTHORITY` template in `build_queue.py` + `kickstart/SKILL.md` mirror + `CHANGELOG.md`, marked `rmi-01M7VYA2QRZN12K734SE2NJ6WB` accepted-start, retained pinned run-1 baseline record (`92ff5ce`) | Run recorded paired manual check + PDDA gate (`TESTS-RESULTS/2026-11-20+GH-1545/`), complete Codex Final QA, open PR and land |

## Goal & Scope (refs #1541 v5 KS-03, #1536)
Bake run defaults into the launch authority template emitted by `skills/1-hourly/kickstart/scripts/build_queue.py` and mirrored in `skills/1-hourly/kickstart/SKILL.md`, eliminating mid-run `PARENT` amendments for these four classes:

1. **`skills/1-hourly/kickstart/scripts/build_queue.py` (`AUTHORITY` template):**
   - **CodeRabbit-advisory rule + U5 safeguards:** A PR authored by `{owner}` may merge when `development` is merged in where needed, the classified gate is green on that exact SHA, independent cross-model QA has approved the final head, hosted checks are green, and EITHER CodeRabbit has reviewed the current head with no open Major OR 30 minutes have passed since a `@coderabbitai review` request on the **current head** with no review. Re-read reviews immediately before merge. Record the timeout path as `advisory not received; predeclared waiver used`, never as reviewed or approved. Any Major CodeRabbit posted blocks until fixed or answered.
   - **KS-11 fail-closed decision defaults:**
     - Round cap: land only with an independent reviewer's explicit approval covering the final head; Minor/nit findings may be deferred only when the reviewer explicitly tagged them Minor/nit and accepted the deferral, otherwise park and continue independent work; never auto-accept on gate, hook, containment, schema, kernel, or Costly surfaces (`utils/ci-route.sh` `full_required`); any PR landed with accepted Minor/nit deferrals states that explicitly and never claims `Approved` beyond what the reviewer stated.
     - Conflict hubs from the merge-cleanup forecast route to a separate recorded batch.
     - Operator decision comments (KS-02) release holds only when authored by `{owner}`, applicable, and not superseded.
   - **Provider quota fallback:** When the reviewer seat's stop reason verbatim states quota, switch that turn's reviewer to `agy` and record the actual model name; if both providers are capped, park. Never infer quota from a round cap or generic failure.
   - **Flywheel per-PR approval boundary:** State explicitly that once granted by the operator in this block, this launch grant satisfies Flywheel's per-PR merge approval step (`skills/2-daily/flywheel/SKILL.md:109-120`) for `{owner}` PRs within these bounds while preserving exact full-SHA `--prs N@<approved-full-sha>` pin verification before `--execute`.
   - **Unchanged boundaries:** Keep `Status: NOT YET GRANTED. The parent records the operator's grant here before dispatch.`, issue-closing/status-comment grants, out-of-scope stop boundary (`{other}`), CLI flags, classification rules, byte-identical replay determinism, and read-only repo behavior unchanged.
2. **`skills/1-hourly/kickstart/SKILL.md` (§1 Parent step 2 & Authority note):**
   Mirror the same four launch defaults concisely in Parent step 2 so the runbook and `build_queue.py` stay aligned.
3. **No new test suites (GH-831) & no new policy engine/runner:** Pure template/runbook update; keep `build_queue.py` surgical and read-only.

## Preflight Contract
- **Target files:** `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md`, `TESTS-RESULTS/2026-11-20+GH-1545/*`, `relay-system/2026-11-20/gh1545-*.md`, `releases.db`, `releases.sql`.
- **Classified route:** `utils/ci-route.sh pull_request` → `route=docs`, `tier=1` (`utils/pdda/pdda.sh run`).
- **Static check:** `mypy` on `skills/1-hourly/kickstart/scripts/build_queue.py` (using the repo's mypy 1.14.1 environment, zero regressions).

## Verification Plan (R2 Discriminating Manual Check)
Record a literal runnable manual procedure and verbatim output under `TESTS-RESULTS/2026-11-20+GH-1545/` (`manual-check.md`, `outputs/pre-change-authority.md`, `outputs/changed-authority.md`, `outputs/decision-replay.txt`, `outputs/check-transcript.log`, `pdda-run.log`, `provenance.jsonl`), pinning exact SHAs rather than moving refs:

1. **Pinned pre-change revision & retained amendment source:**
   - Pre-change `build_queue.py` extracted verbatim from pinned commit `6270a2b5da9964d3f4d99ed4fa1755397d398561` (pre-KS-03 `development` tip; or the exact merged base SHA recorded in `provenance.jsonl` if KS-15 lands first, verifying identical `build_queue.py` blob SHA).
   - Retained run-1 amendment sequence pinned to PR `#1542` commit `92ff5cebefec586d2f5e4009d042eb9709f05ec7` (`TESTS-RESULTS/2026-11-19+kickstart-a6590cb2/run-record.md`, lines 85–118), with exact observed PRs, heads, timestamps, and events recorded and hashed in `provenance.jsonl`.
2. **Paired pre-change vs changed queue-generation replay:**
   - Replay `TESTS-RESULTS/2026-11-19+GH-1527/inputs/` through pinned pre-change `build_queue.py` and changed `build_queue.py` with identical flags (`--as-of 2026-11-19 --owner noelsaw1 --other-session 1400,1418 --needs-operator 1508 --repo-slug HiQS-Labs/XYZ-forge`).
   - Verify Queue / Needs-operator / Not-queued sections are byte-identical (`Status: NOT YET GRANTED` preserved) and all four KS-03 clauses are absent pre-change and present post-change.
3. **Bounded recorded manual decision replay on the saved run-1 amendment sequence (plus U5 / KS-11 / quota negative controls):**
   Record a paired decision table (`pre-change AUTHORITY` disposition vs `changed AUTHORITY` disposition, citing exact run-1 evidence and generated authority clauses) covering:
   - **Case A — Run-1 CodeRabbit rate-limit (`#1495` head `239183bf7`, `#1496` head `48e0f6b09`, request `02:50Z`, checked `>=03:20Z`, 0 Majors, gate+QA+hosted green):** Pre-change required `PARENT 03:12Z` amendment (`OA-3`); changed autonomously merges on the current head after immediate pre-merge review re-read and records `advisory not received; predeclared waiver used`.
   - **Case B — U5 negative control (stale-head timer):** Request on `239183bf7` at `02:50Z`, head pushed to new SHA `999999999` at `03:15Z`, checked at `03:25Z` (10 min on current head). Changed AUTHORITY refuses waiver because the 30-min clock runs from a review request on the **current head**.
   - **Case C — U5 negative control (posted Major):** `#1526` head `5c5557936` (2 posted CodeRabbit Majors) or a late Major arriving before pre-merge re-read at `03:22Z`. Changed AUTHORITY blocks until fixed or answered even after 30 min.
   - **Case D — Run-1 round cap vs quota (`#1519` / PR `#1532` head `eea4c81a0`, 3-round relay cap `cap-stalled`, non-quota, gate/preflight surface):** Pre-change had no round-cap or quota clause (caused `S-2 02:02Z` false `agy` switch, `02:06Z` withdrawal, and `OA-2 ~03:00Z` operator escalation). Changed AUTHORITY refuses `agy` switch (stop reason is not verbatim quota) and fails closed under KS-11(a) (parks without operator question; never auto-accepts on gate surfaces).
   - **Case E — Quota positive & both-capped negative controls:** Verbatim quota stop reason on reviewer seat → switches that turn's reviewer to `agy` and records actual model; both providers quota-capped → parks.
   - **Case F — KS-11(a) Minor/nit deferral control:** Reviewer explicitly approves final head while tagging and accepting Minor/nit deferral on a non-protected surface → eligible to land stating the deferral explicitly without claiming unqualified `Approved`.
   - **Case G — Flywheel per-PR approval boundary:** `--owner` (`noelsaw1`) PR with verified full-SHA pin satisfies Flywheel's per-PR approval step once launch grant is recorded; non-`--owner` PR still stops and asks.
4. **Determinism & read-only invariance:** Two back-to-back runs produce identical SHA-256 outputs, and git refs / `FETCH_HEAD` / `git count-objects -v` are unchanged before and after execution.
5. **Classified gate:** `utils/pdda/pdda.sh run` exits `0` with `0 errors`, output saved to `pdda-run.log`.
6. **Scope honesty:** Live run-2 target ("zero PARENT amendments for KS-03 classes") and runtime enforcement of KS-02/KS-05/KS-10/KS-11 remain uncredited here (deferred to their respective milestones and run 2 / KS-17).
