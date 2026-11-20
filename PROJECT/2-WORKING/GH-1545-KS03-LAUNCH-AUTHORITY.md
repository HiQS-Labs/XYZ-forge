---
id: GH-1545
title: "kickstart: bake run defaults into launch authority template (KS-03)"
status: active
roadmap_id: rmi-01M7VYA2QRZN12K734SE2NJ6WB
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1545
refs: ["#1541", "#1536"]
---

# GH-1545 (KS-03) — Launch Authority Defaults in `build_queue.py` & `kickstart/SKILL.md`

## Problem
During kickstart run 1 (2026-11-19 → 11-20), `skills/1-hourly/kickstart/scripts/build_queue.py` emitted a minimal `AUTHORITY` block that omitted four recurring operational policies:
1. CodeRabbit advisory wait cap, current-head clock semantics (U5), pre-merge re-read, and exact waiver wording.
2. Fail-closed decision defaults (KS-11): round-cap handling (explicit reviewer approval / Minor-nit deferral bounds / no auto-accept on `full_required` surfaces), conflict-hub separate batching, and KS-02 operator-decision validity.
3. Reviewer-seat provider quota fallback (verbatim quota stop reason → `agy` with named model; park if both capped).
4. Explicit satisfaction of Flywheel's per-PR merge approval step (`skills/2-daily/flywheel/SKILL.md:109-120`) for `--owner` PRs.

Because those defaults were absent at launch, run 1 incurred avoidable mid-run `OPERATOR_AMENDMENT` / `PARENT_NOTE` interventions and operator escalations.

## Scope & Surgical Design
1. **`skills/1-hourly/kickstart/scripts/build_queue.py` (`AUTHORITY` constant only):**
   Expand `AUTHORITY` so every generated run record carries all four launch defaults verbatim:
   - **Merge eligibility & CodeRabbit advisory (incl. U5):** Merge PRs authored by `{owner}` when `development` is merged in where needed, the classified gate is green on that exact SHA, independent cross-model QA has approved the final head, hosted checks are green, and either CodeRabbit has reviewed the current head with no open Major or 30 minutes have passed since a `@coderabbitai review` request on the current head with no review. Re-read reviews immediately before the merge. Record the timeout path verbatim as `advisory not received; predeclared waiver used`, never as reviewed or approved. Any posted Major blocks until fixed or answered.
   - **KS-11 fail-closed decision defaults:**
     - Round cap: land only with an independent reviewer's explicit approval covering the final head; Minor/nit findings may be deferred only when the reviewer explicitly tagged them Minor/nit and accepted the deferral, otherwise park and continue independent work; never auto-accept on gate, hook, containment, schema, kernel, or Costly surfaces (`utils/ci-route.sh` `full_required`); any PR landed with accepted Minor/nit deferrals states that explicitly and never claims `Approved` beyond what the reviewer stated.
     - Conflict hubs from the merge-cleanup forecast route to a separate recorded batch.
     - Operator decision comments (KS-02) release holds only when authored by `{owner}`, applicable, and not superseded.
   - **Provider quota fallback:** When the reviewer seat's stop reason verbatim states quota, switch that turn's reviewer to `agy` and record the actual model name; if both providers are capped, park. Never infer quota from a round cap or generic failure.
   - **Flywheel per-PR approval boundary:** State explicitly that once granted by the operator in this block, this launch grant satisfies Flywheel's per-PR merge approval step (`skills/2-daily/flywheel/SKILL.md:109-120`) for `{owner}` PRs within these bounds while preserving exact full-SHA `--prs N@<approved-full-sha>` pin verification before `--execute`.
   - **Unchanged boundaries:** Keep `Status: NOT YET GRANTED. The parent records the operator's grant here before dispatch.`, issue-closing/status-comment grants, out-of-scope stop boundary (`{other}`), CLI flags, classification rules, byte-identical replay determinism, and read-only repo behavior unchanged.
2. **`skills/1-hourly/kickstart/SKILL.md` (§1 Parent step 2 & Authority note):**
   Mirror the same four launch defaults concisely in Parent step 2 so the runbook and `build_queue.py` never drift.
3. **No new test suites (GH-831):** No files under `test/` or CI registries.

## Preflight Contract
- **Target files:** `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/2-WORKING/GH-1545-KS03-LAUNCH-AUTHORITY.md`, `TESTS-RESULTS/2026-11-20+GH-1545/*`, `relay-system/2026-11-20/gh1545-*.md`, `releases.db`, `releases.sql`.
- **Classified route:** `utils/ci-route.sh pull_request` → `route=docs`, `tier=1` (`utils/pdda/pdda.sh run`).
- **Typecheck:** `mypy --strict skills/1-hourly/kickstart/scripts/build_queue.py` (or `mypy` if pre-existing untyped defs exist — verify exact baseline first, keeping changes cleanly typed).

## Verification Plan (R2 Discriminating Manual Check)
Record a literal runnable manual procedure and verbatim output under `TESTS-RESULTS/2026-11-20+GH-1545/` (`manual-check.md`, `outputs/pre-change-authority.md`, `outputs/changed-authority.md`, `outputs/check-transcript.log`, `pdda-run.log`, `provenance.jsonl`):
1. **Paired pre-change vs changed replay:** Replay the saved 2026-11-19 run-1 inputs (`TESTS-RESULTS/2026-11-19+GH-1527/inputs/`) through the pre-change `origin/development` `build_queue.py` and the changed `build_queue.py` with identical flags (`--as-of 2026-11-19 --owner noelsaw1 --other-session 1400,1418 --needs-operator 1508 --repo-slug HiQS-Labs/XYZ-forge`).
2. **Discriminating assertion across all 4 run-1 amendment classes:** Verify that pre-change output fails all 4 checks (no 30-min current-head CodeRabbit waiver clause, no KS-11 round-cap/conflict-hub/KS-02 decision defaults, no verbatim quota fallback to `agy`, no Flywheel per-PR approval satisfaction clause) and therefore required manual amendments/operator escalation, whereas the changed output satisfies all 4 clauses while keeping Queue / Needs-operator / Not-queued sections byte-identical to pre-change and preserving `Status: NOT YET GRANTED`.
3. **Replay determinism & read-only invariance:** Two back-to-back replays produce identical SHA-256 outputs, and repo refs / `FETCH_HEAD` / object counts remain unchanged before and after execution.
4. **Classified gate:** `utils/pdda/pdda.sh run` exits `0` with `0 errors`.
5. **Scope honesty:** Live run-2 "zero PARENT amendments for KS-03 classes" remains uncredited until run 2 (KS-17).
