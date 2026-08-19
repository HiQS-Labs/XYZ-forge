---
title: "GH-57: RELEASES SQLite system fuzzing & multi-scenario resilience suite"
gh_issue: 57
source: "https://github.com/HiQS-Suite/XYZ-forge/issues/57"
status: active
created: 2026-08-19
updated: 2026-08-19
owner: unassigned
goal: "Exercise the GH-32 SQLite RELEASES ledger through comprehensive synthetic fuzzing and scenario recipes ahead of production usage, and evaluate builder models."
doc_type: bugfix
---

# GH-57 — SQLite RELEASES Ledger Fuzzing Recipes & Multi-Scenario Suite

## Status

| What was just completed | What's next |
|---|---|
| Built `test/gh57-releases-fuzz.sh` with 42 assertions covering all 7 failure scenarios from `RELEASES-DB-FAQS.md`, updated `utils/fuzzing/fuzz-loop.sh` with structured output (`FUZZ_RESULT` / `FUZZ_SUMMARY`), registered in `validate.sh` and `utils/ci-route.sh`, and completed builder evaluation ladder across Muse Spark, Qwen 3.8-Max, GLM-5.2, and Codex CLI. | Complete full suite validation in standalone clone, update Harness Models Registry and CHANGELOG, and report findings on GitHub issue #57. |

## Goal

Provide automated synthetic fuzzing and negative-control recipes that exercise the SQLite RELEASES ledger (`utils/py/releases_app.py`, `utils/releases-merge-resolve.sh`) across all critical edge cases identified in `RELEASES-DB-FAQS.md` before real-world production merges.

## Scenarios Implemented

1. **Concurrent Branch Divergence & GID-Keyed Merge**:
   - Disjoint branches importing separate releases merge cleanly through GID-keyed logical dump union without primary key collision.
   - Deterministic renumbering of physical integer rowids on `--rebuild`.
   - Business-state receipt chain integrity preserved across merge rebuilds.
2. **Unequal Write Counts & Generation Headers**:
   - Branches with unequal write counts generate multiple `-- generation` headers.
   - Refusal of naive union dump under `dump-multi-generation` with zero modification to live DB.
   - Clean resolution and state repair via `utils/releases-merge-resolve.sh`.
3. **Duplicate Settings & Content Collision**:
   - Detection and refusal of duplicate `settings` rows (`dump-duplicate-setting`).
   - Detection and refusal of duplicate release `global_id` with conflicting contents (`dump-duplicate-gid`).
4. **Crash Injection & Journal Recovery at 5 Boundaries**:
   - Inject crashes via `RELEASES_APP_CRASH_AT` at `pre-commit`, `post-commit`, `post-stage`, `mid-rename`, and `post-rename`.
   - Injected crashes exit 70, leave intent journal active, and fail-closed subsequent writes with `rule=journal-live`.
   - `releases check` cleanly recovers state and verifies generation trio.
5. **Writer Lock Contention in Git Common-Dir**:
   - Lock file `releases-app.lock` placed in resolved git common directory.
   - Second concurrent writer refused with `rule=writer-lock` and exit code 4.
   - Database remains uncorrupted; writer succeeds immediately once lock is released.
6. **Malformed & Torn Dump Load Protection**:
   - Torn dumps (e.g. duplicate natural keys) refused under `dump-load`.
   - Displaced database preserved atomically, live DB untouched.
7. **Generated Markdown Drift Report**:
   - Side-by-side view `RELEASES.generated.md` generated without touching `RELEASES.md`.
   - Discrepancies reported in `RELEASES.generated.md.drift`.

## Verification

| Target | Result |
|---|---|
| `test/gh57-releases-fuzz.sh` | **42/42 PASS** (exit 0) |
| `utils/fuzzing/fuzz-loop.sh` | **5/5 PASS** (exit 0) |
| `test/ci-route.sh` | **27/27 PASS** (exit 0) |
