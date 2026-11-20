---
title: "GH-1547 (KS-04): kickstart_status.py thin derived read-only status report"
status: active
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
goal: "Implement skills/1-hourly/kickstart/scripts/kickstart_status.py as a thin, strictly read-only derived report over existing run record, pr_minder --json --no-conflict-files, pinned LANDING_CLONE attempt records + remote PR state, log age / U3 liveness, final-QA staleness, and verbatim stop reason"
gh_issue: 1547
roadmap_id: rmi-01M7W0NS5BZNRPBKBJP51QQ5M1
---

# GH-1547 (KS-04): `kickstart_status.py` Thin Derived Read-Only Status Report

## Status

| What was just completed | What's next |
|---|---|
| Bootstrapped fresh clone off reconciled `origin/development` (`0edbab45d6`), registered `rmi-01M7W0NS5BZNRPBKBJP51QQ5M1`, completed recon of `run_record.py`, `pr_minder.py --json --no-conflict-files`, `attempt_record.py`, and GH-1527 read-only check | Complete Codex Plan QA (`relay-system/2026-11-20/gh1547-plan-qa.md`), mark accepted-start, implement `kickstart_status.py` + `SKILL.md` mirror, record paired red/green + read-only evidence, Final QA, PR, and land |

## Goal & Scope (refs #1547, #1541 v5 KS-04 + U3 + U10, #1536)

Build `skills/1-hourly/kickstart/scripts/kickstart_status.py` (Python stdlib only, typed, `mypy --allow-untyped-defs --allow-incomplete-defs` clean) as a **thin, strictly read-only derived status report** over existing records — **NOT a readiness engine** and **NOT a new state store**.

### Inputs Read (Existing Records Only)
1. **Run record** (`--record <path>`, required):
   - Parsed via `skills/1-hourly/kickstart/scripts/run_record.py:parse_record(...)` (reusing KS-15's v1 contract).
   - Extracts:
     - `landing_clone` (`LANDING_CLONE:` header, pinned for the run per U10).
     - `items_done`: completed progress lines (e.g. `MERGED` / `DONE` / `PARKED` / `CLOSED` items from `## Progress log`, plus `GATE:` targets).
     - `current_item`: explicit `CURRENT:` / in-progress line or last active milestone marker if present (else `none`).
     - `unapplied_amendments`: all `OPERATOR_AMENDMENT:` and `PARENT_NOTE:` entries without a matching `APPLIED:` disposition (both from `parse_record()["unresolved_amendments"]` AND fallback scan if a pre-KS-15 legacy amendment line caused a validation error, so an unapplied amendment is NEVER hidden by a parse warning).
     - `interventions`: parsed `INTERVENTION:` count & entries.
     - `record_valid` and `record_errors`: surfaced verbatim so malformed records are visible rather than silently dropped.
2. **Open PRs (`merge-ready` summary)** via `skills/2-daily/pr-minder/scripts/pr_minder.py --json --no-conflict-files --repo-root <target-root>` (or `--prs-json <path>` for deterministic offline replay; `--skip-prs` omitted in default runs):
   - Derives per-PR `merge_ready: bool` strictly from `pr_minder` JSON flags:
     `not draft and not held and not inherited_hold and not unknown and not conflicting and not failing and not behind`.
   - Lists explicit blocking reasons when `merge_ready` is `False` (`draft`, `held`, `inherited_hold`, `unknown`, `conflicting`, `failing`, `behind (drift=N)`).
   - Explicitly notes this is derived PR hygiene status, NOT a merge-readiness approval engine (cross-model QA / CodeRabbit / authority rules remain with the caller).
3. **Attempt records (pinned `LANDING_CLONE` ONLY, per U10):**
   - Scans ONLY `<landing_clone>/.tick/merge-cleanup/<repo-slug>/pr-*.json` (using `LANDING_CLONE:` from the run record, with `--landing-clone <path>` override allowed only when explicitly passed for isolated fixture replay; if `--landing-clone` differs from the run record's `LANDING_CLONE:` when both are real paths, surfaces a mismatch warning).
   - Flags any attempt whose `outcome == "in_progress"` as a **stale/in-progress attempt record** (reporting `pr`, `record_path`, `attempt_index`, `repair_count`, `head_sha`, `started`, `rung`).
   - Pairs EVERY in-progress attempt record with **remote PR state** via read-only `gh pr view <N> --json state,headRefOid,mergeCommit,mergedAt` (or `--remote-prs-json <path>` replay fixture; if unavailable/offline, reports `remote_state: "unknown"`, NEVER infers from local files).
   - Derives `head_matches_attempt: bool | None` (`remote.headRefOid == attempt.head_sha`) so KS-08 recovery callers immediately see MERGED-unreconciled vs OPEN-head-unchanged vs OPEN-head-changed vs unknown.
4. **Log age & U3 Liveness State:**
   - Finds the newest log file in optional `--log-dir <dir>` / `--log-file <file>` (or `<landing_clone>/.tick/merge-cleanup/` logs if present) and computes `newest_log_age_seconds` against `--now <iso-utc>` (default UTC now).
   - Evaluates U3 liveness using explicit stopped-ownership signals (`--owner-state live|stopped|unknown`, optional `--owner-pid <int>` checked read-only via `os.kill(pid, 0)`, optional `--lock-path <path>` existence check, optional `--quiet-seconds` default `120`, `--stale-seconds` default `600`):
     - `confirmed-stopped`: ONLY when explicit stopped-ownership proof is verified (e.g., `--owner-state stopped` AND no live PID AND no active lock).
     - `stale-candidate`: `newest_log_age_seconds >= stale_seconds` and NOT `confirmed-stopped`. Always emits advisory: `"log age alone never authorizes finish or redispatch; prove stopped ownership first"`.
     - `quiet`: owner is live (or lock active) and `quiet_seconds <= newest_log_age_seconds < stale_seconds`.
     - `waiting`: owner is live (or active log with `newest_log_age_seconds < quiet_seconds`).
     - `unknown`: insufficient log/ownership evidence (e.g. no log and unknown owner).
   - **Hard U3 invariant:** log age alone NEVER yields `confirmed-stopped` and NEVER authorizes `attempt_record.py finish` or redispatch.
5. **Final-QA Staleness (seam for KS-13):**
   - Reads the latest recorded Final QA head SHA from the run record (`FINAL_QA:` / progress log final-QA head mention, or explicit `--final-qa-sha <sha>`) and compares it against the latest landed SHA (latest `GATE:` / `MERGED` SHA in the run record, or `--development-head <sha>`, or read-only `git -C <target-root> rev-parse origin/development`).
   - Reports `final_qa.status`: `fresh` (matches latest landed SHA), `stale` (a landing occurred after the recorded final QA head, listing the newer landed SHA(s)), `missing` (no final QA recorded yet), or `unknown`.
6. **Current Run's Stop Reason Verbatim (seam for KS-05):**
   - Accepts optional `--run-log <path>` / `--receipt <path>`, `--run-started-at <iso-utc>`, and `<target-root>/.relay-scratch/escalation-reason` (or `--escalation-file <path>`).
   - Priority:
     1. If `--receipt <path>` or `--run-log <path>` contains an explicit stop diagnostic line for this run, quote it **verbatim** with `source`.
     2. Otherwise, consult `.relay-scratch/escalation-reason` ONLY if it is attributable to this run (specifically: `--run-started-at` is provided AND the escalation file's mtime is `>= run_started_at`, OR the file itself carries a matching attribution key). If unattributable (missing `--run-started-at` or mtime older than `--run-started-at`), report `stop_reason: "unknown"`, `attribution: "unattributable"` — NEVER infer quota or cap, and NEVER inherit a stale escalation file from a previous run!
     3. If no stop file/log exists, report `stop_reason: "none"` (or `"unknown"` when a stopped run lacks reason evidence).

### Output Formats
- Default: concise human-readable Markdown/text status report (sections: Summary & Liveness, Items Done / Current, Unapplied Amendments, PR Merge-Ready Summary, Stale Attempts + Remote PR State, Final-QA Staleness, Stop Reason).
- `--json`: deterministic JSON object (`sort_keys=True`, `indent=2`) containing all derived fields.
- Exit codes: `0` on successful report generation (even when unapplied amendments, stale attempts, or `stale-candidate` liveness are present — it is a read-only report, not a gate!), `2` on invalid CLI args or unreadable `--record`.

### Files Changed (Docs Route, Zero New Test Suites per GH-831)
1. `skills/1-hourly/kickstart/scripts/kickstart_status.py` (new, stdlib-only, read-only)
2. `skills/1-hourly/kickstart/SKILL.md` (document `kickstart_status.py` contract, CLI, U3 states, and read-only guarantee)
3. `CHANGELOG.md` (add GH-1547 / KS-04 entry)
4. `PROJECT/2-WORKING/GH-1547-KS04-KICKSTART-STATUS.md`, `releases.db`, `releases.sql`
5. `TESTS-RESULTS/2026-11-20+GH-1547/` (recorded paired pre-change vs candidate checks + red controls + GH-1527 read-only invariance check + `provenance.jsonl`)

### Planned Verification & Red Controls (`TESTS-RESULTS/2026-11-20+GH-1547/manual-check.md`)
1. **Red control (pre-change):** `skills/1-hourly/kickstart/scripts/kickstart_status.py` does not exist at base `0edbab45d6`; operator/parent must manually inspect multiple files and has no single read-only derived report.
2. **Stuck vs Live fixtures (U3):**
   - Live active log (30s old, `--owner-state live`) → `waiting`
   - Quiet live log (240s old, `--owner-state live`) → `quiet`
   - Stuck/old log (900s old, `--owner-state live` or `unknown`) → `stale-candidate` (NEVER `waiting`/`quiet` AND NEVER `confirmed-stopped`)
   - Verified dead (`--owner-state stopped`, dead PID, no lock) → `confirmed-stopped`
   - Red control: verify stuck fixture (900s old) is rejected if misclassified as live or confirmed-stopped.
3. **Unapplied amendment fixture:** run record with `OPERATOR_AMENDMENT:` + `PARENT_NOTE:` lacking `APPLIED:` → both surfaced in `unapplied_amendments`; once `APPLIED:` is present → cleared.
4. **Stale attempt + remote PR state fixture (U10):** pinned `LANDING_CLONE` `.tick/merge-cleanup/.../pr-1539.json` with `outcome: "in_progress"` paired with `--remote-prs-json` showing `MERGED` vs `OPEN` (unchanged head) vs missing (`unknown`); verifies second unpinned clone is ignored.
5. **Final-QA staleness fixture:** final QA recorded on older SHA with newer landed SHA → `stale`; matching SHA → `fresh`.
6. **Stop reason attribution fixture:** stale `.relay-scratch/escalation-reason` with mtime older than `--run-started-at` → `unknown (unattributable)` (NOT inherited!); mtime `>= --run-started-at` → quoted verbatim.
7. **GH-1527 Read-Only Live Check:** run live `kickstart_status.py` against the repo clone with a logging `git` shim on `PATH` and before/after snapshots of `git show-ref`, `FETCH_HEAD` stat/hash, and `git count-objects -v` → 0 mutating git calls (`fetch`/`merge-tree`/`update-ref`), all 3 snapshots byte-identical.
8. **Static & Governance Gates:** `utils/ci-route.sh pull_request` (`route=docs`), `mypy --allow-untyped-defs --allow-incomplete-defs`, `./utils/pdda/pdda.sh run` (0 errors), zero raw `/Users/` paths, full `provenance.jsonl`.
