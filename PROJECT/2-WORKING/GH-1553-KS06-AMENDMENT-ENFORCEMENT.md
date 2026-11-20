---
issue: 1553
title: "kickstart(KS-06): amendments must be applied with explicit disposition, not merely acknowledged"
status: active
roadmap_id: rmi-01M7W3BP6KV0Q0WYC7KFVZV750
parent_arc: 1541
milestone: KS-06
created: 2026-11-20
---

# GH-1553 (KS-06) — Amendments Are Applied, Not Just Acknowledged

## Objective
Enforce U2/U11/U12 amendment handling in `skills/1-hourly/kickstart/SKILL.md` and `skills/1-hourly/kickstart/scripts/run_record.py` so every run-record amendment (`OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, `INTERVENTION:`) must reach an explicit disposition (`applied`, `superseded`, or `escalated`) before any landing or subsequent work, and a crash immediately after chat acknowledgement still blocks resume until resolved.

## Grounded Recon
- `skills/1-hourly/kickstart/scripts/run_record.py` (KS-15) already parses v1 `OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, `INTERVENTION:`, and `APPLIED:` lines with `applied`, `superseded`, and `escalated` dispositions and computes `unresolved_amendments`, but has no dedicated fail-closed pre-landing/on-resume gate CLI subcommand.
- `skills/1-hourly/kickstart/SKILL.md` references the run-record contract but does not yet mandate checking unresolved amendments before every landing and on every resume, distinguishing thread messages (wake-up only) from the authoritative run record, or blocking other work after a crash immediately following chat acknowledgement.
- `utils/ci-route.sh` classifies edits to `skills/1-hourly/kickstart/**`, `PROJECT/**`, `TESTS-RESULTS/**`, `CHANGELOG.md`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. **`skills/1-hourly/kickstart/scripts/run_record.py`:**
   - Add strictly read-only `check-amendments <record> [--json]` subcommand:
     - Parses `<record>` via existing `parse_record()`.
     - Treats any amendment lacking a terminal disposition (`applied` or `superseded`) — including unacknowledged amendments AND `escalated` amendments (held) — as blocking, along with any record parse errors.
     - Exits `0` ONLY when `errors == []` and `unresolved_amendments == []` (zero unresolved amendments).
     - Exits `2` when any unresolved amendment (including `escalated`) or parse error is present, printing the exact blocking IDs/dispositions (or JSON payload with `--json`).
     - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/run_record.py` passes with 0 issues.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Authoritative Amendment Enforcement (KS-06, U2/U11/U12)** subsection:
     - Run record is the authoritative amendment channel; thread/chat messages are at most wake-ups and NEVER satisfy an amendment.
     - Stable ID + `OPERATOR_AMENDMENT:` (citing operator turn/comment/decision), `PARENT_NOTE:`, or `INTERVENTION:` prefix; explicit disposition `applied` (with concrete action/artifact), `superseded` (naming a later declared amendment ID), or `escalated` (run held).
     - Mandatory check on every resume AND immediately before every landing using `kickstart_status.py` / `run_record.py check-amendments`; append `APPLIED: <ID> -> <disposition> <action>` BEFORE executing the affected action.
     - Crash-after-acknowledgement rule: acknowledging an amendment in chat without appending `APPLIED:` leaves it unresolved on disk and blocks all other work/landings on resume.
3. **`CHANGELOG.md`:** Add concise GH-1553 (KS-06) entry.
4. **Paired Red/Green Manual Check (`TESTS-RESULTS/2026-11-20+GH-1553/`, no new test suite GH-831):**
   - **Control 1 (03:12Z amendment replay — #1495 / #1496):** Pre-change (no gate) left the 03:12Z CodeRabbit-waiver amendment unapplied while #1495/#1496 waited; changed path catches the unresolved amendment via `run_record.py check-amendments` (exit 2), appends `APPLIED: OA-0312 -> applied ...`, and clears to exit 0 (zero unresolved).
   - **Control 2 (Crash immediately after acknowledgement):** Simulate a wake/chat acknowledgement followed by crash with NO `APPLIED:` line in the run record; on resume `check-amendments` exits 2 (blocking other work/landings). Verify `APPLIED: <ID> -> escalated ...` keeps exit 2 (held), while `applied` or `superseded by <newer-ID>` exits 0 (zero unresolved).
   - Run `./utils/pdda/pdda.sh run` and write `provenance.jsonl`.

## Acceptance Criteria
- `run_record.py check-amendments` exits 2 on unresolved/escalated/parse-error records and 0 only when zero unresolved amendments remain; mypy passes cleanly.
- `skills/1-hourly/kickstart/SKILL.md` enforces run-record authority, dispositions, pre-landing & on-resume checks, and crash-after-ack blocking.
- Both paired red/green manual controls recorded under `TESTS-RESULTS/2026-11-20+GH-1553/` with `provenance.jsonl`.
- `./utils/pdda/pdda.sh run` passes with 0 errors.
