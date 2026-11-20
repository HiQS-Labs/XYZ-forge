---
issue: 1553
title: "kickstart(KS-06): amendments must be applied with explicit disposition, not merely acknowledged"
status: active
roadmap_id: rmi-01M7W3BP6KV0Q0WYC7KFVZV750
parent_arc: 1541
milestone: KS-06
owner: antigravity
goal: "Enforce U2/U11/U12 amendment disposition tracking across OPERATOR_AMENDMENT, PARENT_NOTE, and INTERVENTION prefixes in run_record.py and skills/1-hourly/kickstart/SKILL.md."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1553 (KS-06) — Amendments Are Applied, Not Just Acknowledged

## Status

| What was just completed | What's next |
|---|---|
| Addressed Plan QA R1 findings (included `INTERVENTION:` in `run_record.py` disposition/unresolved tracking, added explicit crash-after-APPLIED reconciliation protocol, strengthened paired 03:12Z replay + PDDA frontmatter/Status table + `CHANGELOG_WRITES` policy). | Complete Plan QA R2 approval, implement `run_record.py` + `kickstart/SKILL.md`, execute paired red/green controls + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1553/`, and pass Final QA. |

## Objective
Enforce U2/U11/U12 amendment handling in `skills/1-hourly/kickstart/scripts/run_record.py` and `skills/1-hourly/kickstart/SKILL.md` so every run-record amendment across all three prefixes (`OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, and `INTERVENTION:`) must reach an explicit disposition (`applied`, `superseded`, or `escalated`) before any landing or subsequent work, and crashes in either window (after chat acknowledgement before `APPLIED:`, or after `APPLIED:` before the named action completes) never allow unapplied work to be skipped.

## Grounded Recon
- `skills/1-hourly/kickstart/scripts/run_record.py:158-263` (KS-15) parses v1 `OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, `INTERVENTION:`, and `APPLIED:` lines, but currently puts `INTERVENTION:` only in `interventions` (never in `amendment_by_id` or `unresolved_amendments`), so an unresolved `INTERVENTION:` is not flagged and `APPLIED: <intervention-id> -> ...` is rejected as undeclared.
- `skills/1-hourly/kickstart/SKILL.md` does not yet mandate checking unresolved amendments before every landing and on every resume, distinguishing thread messages (wake-up only) from the authoritative run record, or specifying reconciliation for both crash windows.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
- `utils/ci-route.sh` classifies edits to `skills/1-hourly/kickstart/**`, `PROJECT/**`, `TESTS-RESULTS/**`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. **`skills/1-hourly/kickstart/scripts/run_record.py`:**
   - **Track `INTERVENTION:` in disposition resolution while preserving `interventions`:** keep `interventions.append(entry)` intact for KS-04/KS-18 reporting AND register `INTERVENTION:` entries in `amendment_by_id` / `amendments` (enforcing cross-prefix ID uniqueness), so `APPLIED: <intervention-id> -> applied|superseded|escalated ...` is accepted and any unresolved or `escalated` `INTERVENTION:` appears in `unresolved_amendments`.
   - **Add strictly read-only `check-amendments <record> [--json]` subcommand:**
     - Parses `<record>` via `parse_record()`.
     - Exits `0` ONLY when `errors == []` and `unresolved_amendments == []` (zero unresolved entries across `OPERATOR_AMENDMENT`, `PARENT_NOTE`, and `INTERVENTION`; a `superseded` entry clears only itself, while the newer superseding amendment must also reach a terminal disposition for global exit `0`).
     - Exits `2` when any unresolved entry (including `escalated`) or parse error is present, printing the blocking IDs/kinds/dispositions (or JSON payload with `--json`).
   - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/run_record.py` exits 0.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Authoritative Amendment Enforcement (KS-06, U2/U11/U12)** subsection:
     - Run record is the authoritative amendment channel; thread/chat messages are at most wake-ups and NEVER satisfy an amendment.
     - Stable ID + `OPERATOR_AMENDMENT:` (citing operator turn/comment/decision), `PARENT_NOTE:`, or `INTERVENTION:` prefix; explicit disposition `applied` (with concrete action/artifact), `superseded` (naming a later declared amendment ID, which itself must be resolved), or `escalated` (run held).
     - Mandatory pre-landing and on-resume check via `kickstart_status.py` / `run_record.py check-amendments`; append `APPLIED: <ID> -> <disposition> <action/artifact>` BEFORE executing the affected action.
     - **Two crash-window rules on resume:**
       - *Window A (crash after chat/wake acknowledgement, before `APPLIED:` is persisted):* `check-amendments` exits `2` and blocks all landings and unrelated work until a valid disposition is persisted.
       - *Window B (crash after `APPLIED: <ID> -> applied <action/artifact>` is persisted, before the affected action's external effect completes):* on resume, before advancing unrelated work, reconcile the recorded action/artifact against actual observable state (remote PR/issue state, git ref, or saved receipt) per Transition 4 step 3: adopt if verified complete; execute before unrelated work if provably unstarted and safe; HOLD without repeating external effects if the outcome is uncertain.
3. Honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
4. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1553/`, no new test suite GH-831):**
   - **Control 1 (03:12Z amendment replay — #1495 / #1496, clearly separating CLI check + instruction walkthrough):**
     - *Pre-change / Red:* replay the run-1 03:12Z CodeRabbit-waiver amendment shape with no pre-landing gate (and show pre-change `run_record.py` also missed `INTERVENTION:` entries); #1495 and #1496 remained waiting on CodeRabbit because the amendment was not applied before the landing decision.
     - *Changed / Green:* `run_record.py check-amendments` exits `2` on the unapplied 03:12Z amendment (blocking landing/unrelated work), records `APPLIED: OA-0312 -> applied ...`, and clears to exit `0`, with source-only walkthrough confirming the changed landing decision proceeds under the applied waiver.
   - **Control 2 (All 3 prefixes + both crash windows + superseded chain, executable CLI checks + Window B reconciliation walkthrough):**
     - Executable `run_record.py` check covering `OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, and `INTERVENTION:`:
       - Window A (wake/chat ack only, no `APPLIED:` on disk) -> `check-amendments` exits `2` (blocking resume/landings) for all three prefixes.
       - `APPLIED: I-1 -> escalated run held` -> still exits `2` (held); `APPLIED: I-1 -> applied ...` -> clears `I-1`.
       - `APPLIED: PN-1 -> superseded by PN-2` while `PN-2` is unresolved -> still exits `2` until `PN-2` is resolved -> then exits `0`.
     - Window B walkthrough: crash after `APPLIED: OA-2 -> applied merge PR #1495` before merge confirmation -> resume checks remote PR state before unrelated work (MERGED -> adopt/reconcile; OPEN unchanged -> execute; uncertain -> hold).
   - Run `./utils/pdda/pdda.sh run` (0 errors) and generate `provenance.jsonl`.

## Acceptance Criteria
- `run_record.py` tracks `INTERVENTION:` alongside `OPERATOR_AMENDMENT:` and `PARENT_NOTE:` in disposition/unresolved resolution while preserving `interventions`, and provides read-only `check-amendments` (exit 2 on unresolved/escalated/parse errors, exit 0 only when zero unresolved remain).
- `skills/1-hourly/kickstart/SKILL.md` codifies run-record authority, dispositions, pre-landing & on-resume checks, and both crash-window recovery rules.
- Paired red/green checks (labeled accurately), mypy (0 issues), PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1553/`.
