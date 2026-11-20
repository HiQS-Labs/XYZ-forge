# Manual Check — GH-1553 (KS-06: Amendments Applied, Not Just Acknowledged)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/scripts/run_record.py` and `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; no new test suite per GH-831).

## 1. Pre-Change Red Control (`outputs/pre-change-red.txt`)
- Evaluated pre-change `run_record.py` (`git show origin/development:skills/1-hourly/kickstart/scripts/run_record.py`) on a temporary v1 record declaring `OPERATOR_AMENDMENT: OA-0312` and `INTERVENTION: I-1`:
  - `validate --json` exited `0` with `unresolved_ids=['OA-0312']` — `INTERVENTION: I-1` was silently missed from `unresolved_amendments`.
  - `check-amendments <record>` exited `2` with `invalid choice: 'check-amendments'` (no pre-landing/on-resume blocking subcommand existed).

## 2. Changed CLI Controls (`outputs/controls-green.txt`)
All CLI controls ran directly against the candidate `skills/1-hourly/kickstart/scripts/run_record.py` on disposable temp run records (reproducible via `python3 skills/1-hourly/kickstart/scripts/run_record.py check-amendments <tmp-record> [--json]` and `append ...`):
- **Control 1 (03:12Z `#1495`/`#1496` replay — `OA-0312`):**
  - Unapplied `OPERATOR_AMENDMENT: OA-0312 2026-11-20T03:12Z ...` -> `check-amendments <record>` exited `2` (strictly read-only; no `<record>.lock` file created).
  - After appending `APPLIED: OA-0312 → applied ...` -> `check-amendments <record>` exited `0` (`OK amendments=1 unresolved=0`).
- **Control 2 (All 3 prefixes + Window A + escalated + superseded chain + cross-prefix ID uniqueness):**
  - Record declaring `OPERATOR_AMENDMENT: OA-1`, `PARENT_NOTE: PN-1`, `PARENT_NOTE: PN-2`, and `INTERVENTION: I-1`:
    - Window A (unapplied): `check-amendments` blocked all 4 IDs (`rc=2`) while `interventions` list preserved `['I-1']`.
    - `APPLIED: I-1 → escalated ...`: remained blocking (`rc=2`) until resolved.
    - `APPLIED: PN-1 → superseded PN-2 ...`: remained blocking (`rc=2`) until `PN-2` itself reached terminal `applied` (`rc=0`, `OK amendments=4 unresolved=0`).
    - Cross-prefix duplicate ID (`INTERVENTION: OA-1` colliding with `OPERATOR_AMENDMENT: OA-1`): rejected cleanly (`rc=1`).

## 3. Source-Only Walkthroughs (Simulated Observations Against Revised `SKILL.md`)
*Note: The two walkthroughs below are explicitly labeled simulated policy walkthroughs against the revised `skills/1-hourly/kickstart/SKILL.md` ("Authoritative Amendment Enforcement (KS-06, U2/U11/U12)"), distinct from the executable CLI controls above.*

### Walkthrough A — Changed `#1495`/`#1496` Landing Decision Under `OA-0312` Waiver
- **Simulated Input:** Run record contains `OPERATOR_AMENDMENT: OA-0312 2026-11-20T03:12Z operator waived CodeRabbit wait after 30m for #1495/#1496 when hosted checks green and Codex Final QA approved`.
- **Pre-Change Behavior (Run 1 Baseline):** Child acknowledged the chat message without re-reading/applying `OA-0312` from the run record and left `#1495`/`#1496` stalled waiting for CodeRabbit.
- **Changed `SKILL.md` Walkthrough Observation:**
  1. Before landing, child runs `skills/1-hourly/kickstart/scripts/run_record.py check-amendments <record>` -> exits `2` citing unresolved `OA-0312`, blocking all unrelated work and landings.
  2. Child reads `OA-0312` from the run record, appends `APPLIED: OA-0312 → applied applied 30m CodeRabbit waiver to #1495/#1496 pre-merge authority check`, re-runs `check-amendments` -> exits `0`.
  3. Child evaluates `#1495`/`#1496` under the updated waiver authority (recording `"advisory not received; predeclared waiver used"`) and dispatches landing rather than stalling.

### Walkthrough B — Window B Crash Reconciliation (Crash After `APPLIED:` Persisted, Before External Effect Completes)
- **Simulated Input:** Run record already contains `APPLIED: OA-0312 → applied land PR #1495 under 30m waiver`, so `run_record.py check-amendments <record>` intentionally exits `0` on resume. However, the child crashed after persisting `APPLIED:` and before finishing the external merge/landing action.
- **Changed `SKILL.md` Walkthrough Observation (quoting `SKILL.md` Window B rule):**
  - On resume, before advancing unrelated work, child inspects observable remote/local state for the named artifact (`PR #1495`) per Transition 4 step 3:
    1. **If remote PR `#1495` is `MERGED`:** **ADOPT** the completed landing (run post-merge reconciliation if needed, never re-merge) and record completion.
    2. **If remote PR `#1495` is `OPEN` and provably unstarted (no active driver/lock/check session and head unchanged):** **EXECUTE** the pending landing before advancing unrelated work.
    3. **If outcome is uncertain (e.g., active/ambiguous lock, moved head, or unreachable remote state):** **HOLD** without repeating external effects and surface evidence to parent.

## 4. Route, Type Check & PDDA
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/run_record.py`: 0 issues (`outputs/mypy.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
