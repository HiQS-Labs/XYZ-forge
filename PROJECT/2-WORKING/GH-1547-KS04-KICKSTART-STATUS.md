---
title: "GH-1547 (KS-04): kickstart_status.py thin derived read-only status report"
status: active
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
goal: "Implement skills/1-hourly/kickstart/scripts/kickstart_status.py as a thin, strictly read-only derived report over existing run record, pr_minder --json --no-conflict-files, pinned LANDING_CLONE attempt records + remote PR state, log age / U3 liveness with full stopped-ownership proof, canonical final-QA staleness, and invocation-attributed verbatim stop reason"
gh_issue: 1547
roadmap_id: rmi-01M7W0NS5BZNRPBKBJP51QQ5M1
---

# GH-1547 (KS-04): `kickstart_status.py` Thin Derived Read-Only Status Report

## Status

| What was just completed | What's next |
|---|---|
| Codex Plan QA Round 3 approved (`8a369120`), implemented `kickstart_status.py` + `SKILL.md` mirror (`ee70eced`), passed all paired red/green, U3/U10/final-QA/stop-reason, GH-1527 live read-only check, `mypy`, and PDDA gate (`TESTS-RESULTS/2026-11-20+GH-1547/`) | Complete Codex Final QA (`relay-system/2026-11-20/gh1547-final-qa.md`), push branch, open PR, and land from pinned `LANDING_CLONE` |

## Goal & Scope (refs #1547, #1541 v5 KS-04 + U3 + U10, #1536)

Build `skills/1-hourly/kickstart/scripts/kickstart_status.py` (Python stdlib only, typed, `mypy --allow-untyped-defs --allow-incomplete-defs` clean) as a **thin, strictly read-only derived status report** over existing records — **NOT a readiness engine** and **NOT a new state store**.

### Inputs Read (Existing Records Only)
1. **Run record** (`--record <path>`, required):
   - Parsed via `skills/1-hourly/kickstart/scripts/run_record.py:parse_record(...)` (reusing KS-15's v1 contract).
   - Extracts:
     - `landing_clone` (`LANDING_CLONE:` header, pinned for the run per U10).
     - `items_done`: completed progress lines (`MERGED` / `DONE` / `PARKED` / `CLOSED` items from `## Progress log`).
     - `current_item`: explicit `CURRENT:` / in-progress line if present (else `none`).
     - `unapplied_amendments`: all `OPERATOR_AMENDMENT:` and `PARENT_NOTE:` entries without a matching `APPLIED:` disposition (both from `parse_record()["unresolved_amendments"]` AND a fallback scan if a pre-KS-15 legacy amendment line caused a parse error, so an unapplied amendment is NEVER hidden by a parse warning).
     - `interventions`: parsed `INTERVENTION:` count & entries.
     - `record_valid` and `record_errors`: surfaced verbatim so malformed records are visible rather than silently dropped.
2. **Open PRs (`merge-ready` summary)** via `skills/2-daily/pr-minder/scripts/pr_minder.py --json --no-conflict-files --repo-root <target-root>` (or `--prs-json <path>` for deterministic offline replay):
   - Derives per-PR `merge_ready: bool` strictly from `pr_minder` JSON flags:
     `not draft and not held and not inherited_hold and not unknown and not conflicting and not failing and not behind`.
   - Lists explicit blocking reasons when `merge_ready` is `False` (`draft`, `held`, `inherited_hold`, `unknown`, `conflicting`, `failing`, `behind (drift=N)`).
   - Explicitly states this is derived PR hygiene status, NOT a merge-readiness approval engine (cross-model QA / CodeRabbit / authority rules remain with the caller).
3. **Attempt records (pinned `LANDING_CLONE` ONLY, per U10):**
   - Scans ONLY `<landing_clone>/.tick/merge-cleanup/<repo-slug>/pr-*.json` (using `LANDING_CLONE:` from the run record, with `--landing-clone <path>` override allowed only when explicitly passed for isolated fixture replay; if both are present and resolve to different paths, surfaces a mismatch warning).
   - Flags any attempt whose `outcome == "in_progress"` as a **stale/in-progress attempt record** (reporting `pr`, `record_path`, `attempt_index`, `repair_count`, `head_sha`, `started`, `rung`).
   - Pairs EVERY in-progress attempt record with **remote PR state** via read-only `gh pr view <N> --json state,headRefOid,mergeCommit,mergedAt` (or `--remote-prs-json <path>` replay fixture; if unavailable/offline, reports `remote_state: "unknown"`, NEVER infers from local files).
   - Derives `head_matches_attempt: bool | None` (`remote.headRefOid == attempt.head_sha` via prefix-safe hex comparison) so KS-08 recovery callers immediately see MERGED-unreconciled vs OPEN-head-unchanged vs OPEN-head-changed vs unknown.
4. **Log age & U3 Liveness State (Full Stopped-Ownership Proof & Strict Precedence):**
   - Finds the newest log file in optional `--log-dir <dir>` / `--log-file <file>` (or `<landing_clone>/.tick/merge-cleanup/` logs if present) and computes `newest_log_age_seconds` against `--now <iso-utc>` (default UTC now).
   - Consumes the complete 4-part kickstart stopped-ownership proof (`kickstart/SKILL.md:55-57,229-230`; KS-08) without becoming a recovery engine:
     1. **Owner / coordinator state:** `--owner-state live|stopped|unknown` (default `unknown`), plus optional `--owner-pid <int>` checked read-only via `os.kill(pid, 0)` (a live PID overrides `--owner-state stopped` to `live`).
     2. **Lock state:** `--lock-state clear|held|unknown` (default `unknown`), plus optional `--lock-path <path>` checked read-only for existence (an existing lock forces `held`; if `--lock-path` is given and absent, lock is `clear`).
     3. **Associated builders / checks / push subprocesses:** `--children-state live|stopped|unknown` (default `unknown`).
     4. **Detached sessions:** `--sessions-state live|stopped|unknown` (default `unknown`).
   - **Strict unambiguous precedence** (with `--quiet-seconds` default `120`, `--stale-seconds` default `600`):
     1. `confirmed-stopped`: ONLY when ALL four parts are explicitly proven stopped/clear (`owner == "stopped"`, `lock == "clear"`, `children == "stopped"`, `sessions == "stopped"`). If ANY component is `live` or `unknown`, `confirmed-stopped` is REFUSED.
     2. `stale-candidate`: NOT `confirmed-stopped` AND `newest_log_age_seconds is not None and newest_log_age_seconds >= stale_seconds` (takes strict precedence over `waiting`/`quiet` even when ownership is `live` — an old silent log is a `stale-candidate`, never reported live/healthy!). Always emits advisory: `"log age alone never authorizes finish or redispatch; prove complete stopped ownership first"`.
     3. `quiet`: NOT `confirmed-stopped`, NOT `stale-candidate`, at least one ownership component is `live`/`held`, AND `newest_log_age_seconds is not None and newest_log_age_seconds >= quiet_seconds`.
     4. `waiting`: NOT `confirmed-stopped`, NOT `stale-candidate`, AND (at least one ownership component is `live`/`held` with log age `< quiet_seconds` or no log yet, OR fresh log `< quiet_seconds` with non-stopped ownership).
     5. `unknown`: otherwise (e.g., dead coordinator with `unknown` children/sessions and no fresh/stale log, or no log and all ownership `unknown`).
   - **Hard U3 invariant:** log age alone NEVER yields `confirmed-stopped` and NEVER authorizes `attempt_record.py finish` or redispatch.
5. **Final-QA Staleness (Canonical `GATE: final-QA` + Landed-Head Separation, seam for KS-13):**
   - **Canonical Final-QA event selection:** reads `parse_record()["gates"]` in chronological/line order where `target.lower() in ("final-qa", "final_qa")` (plus optional `--final-qa-sha <sha>` override for explicit fixture testing).
     - Tracks the latest canonical `final-QA` gate (both its `verdict` and `sha` and line number).
     - Never treats a `verdict == "red"` final-QA gate as fresh!
   - **Strict separation of actual landings vs task gates:**
     - Non-landing task `GATE:` lines (e.g. `GATE: PR-1547 ...` or `GATE: GH-1547 ...`) are **NEVER** treated as landings and NEVER invalidate Final QA!
     - Actual landing evidence comes ONLY from:
       (a) `MERGED` progress lines in `## Progress log` (line number + merge/reconciled SHA), AND/OR
       (b) an explicit `--development-head <sha>` passed by the caller after verifying remote freshness.
     - Local `git rev-parse origin/development` is NEVER silently assumed fresh; when no `--development-head` is provided and no post-QA `MERGED` line appears in the run record, status is `unknown` (`"development head freshness unverified; pass --development-head"`).
   - **Prefix-safe SHA comparison:** normalizes hex lowercase and compares `a.startswith(b) or b.startswith(a)` when `min(len(a), len(b)) >= 7`, so abbreviated and full SHAs of the same commit match cleanly.
   - **Final-QA verdicts:**
     - `missing`: no canonical `final-QA` event (and no `--final-qa-sha`).
     - `stale`: latest canonical `final-QA` verdict is `red`; OR a `MERGED` progress line occurs after the latest green `final-QA` line with a different commit; OR `--development-head` is provided and does NOT prefix-match the latest green `final-QA` SHA.
     - `fresh`: latest canonical `final-QA` verdict is `green`, NO `MERGED` progress line occurs after it, AND `--development-head` is provided and prefix-matches its SHA.
     - `unknown`: latest canonical `final-QA` is `green` with no later `MERGED` line, but `--development-head` was not supplied (cannot prove no unseen landing occurred).
6. **Current Run's Stop Reason Verbatim (Invocation-Attributed, Rejects Mtime-Only Shared Files, seam for KS-05):**
   - Accepts optional `--run-log <path>`, `--receipt <path>`, `--invocation-id <id>`, and `--harness-root <path>` (explicit harness root; does NOT blindly assume `--target-root` is the harness root — defaults to `--harness-root` only when passed, or checks `--escalation-file <path>` directly).
   - **Strict attribution order (mtime alone AND sidecar-only metadata are NEVER accepted as attribution!):**
     1. Exclusive per-run `--receipt <path>` or `--run-log <path>`: if an explicit stop diagnostic line/field exists for this run, quote it **verbatim** (`attribution: "run-receipt"` or `"run-log"`).
     2. Shared harness-root `<harness-root>/.relay-scratch/escalation-reason` (or `--escalation-file <path>`): accepted ONLY when `--invocation-id <id>` is provided AND the shared file ITSELF is a single self-contained structured payload carrying BOTH matching `invocation_id == <id>` AND an explicit non-empty `reason` (either JSON object `{"invocation_id": "<id>", "reason": "<verbatim>"}` or keyed lines `invocation_id=<id>` + `reason=<verbatim>`). Sidecar-only metadata (e.g., `<escalation-file>.meta.json`) is **NEVER** accepted because a plain-text writer (like current `relay_drive.py:636-640`) can overwrite the shared file without updating any sidecar; any sidecar is ignored (and if payload `invocation_id` differs from `--invocation-id`, it is rejected).
     3. If a shared escalation file exists without a matching self-contained `invocation_id` + `reason` payload (plain-text file, missing `--invocation-id`, newer file written by a different invocation, stale sidecar with overwritten plain-text payload, or conflicting payload `invocation_id`), report `stop_reason: "unknown"`, `attribution: "unattributable"`, `unattributed_shared_file_present: true` — NEVER inherit its text and NEVER infer quota or cap!
     4. If no stop evidence exists anywhere, report `stop_reason: "none"` (or `"unknown"` if `liveness == "confirmed-stopped"` with no recorded stop reason).

### Output Formats
- Default: concise human-readable Markdown/text status report (sections: Summary & Liveness, Items Done / Current, Unapplied Amendments, PR Merge-Ready Summary, Stale Attempts + Remote PR State, Final-QA Staleness, Stop Reason).
- `--json`: deterministic JSON object (`sort_keys=True`, `indent=2`) containing all derived fields.
- Exit codes: `0` on successful report generation (read-only report, not a gate), `2` on invalid CLI args or unreadable `--record`.

### Files Changed (Docs Route, Zero New Test Suites per GH-831)
1. `skills/1-hourly/kickstart/scripts/kickstart_status.py` (new, stdlib-only, read-only)
2. `skills/1-hourly/kickstart/SKILL.md` (document `kickstart_status.py` contract, CLI, U3 states, and read-only guarantee)
3. `PROJECT/2-WORKING/GH-1547-KS04-KICKSTART-STATUS.md` + canonical `releases.db`/`releases.sql` pickup registration (updated only via `releases_app.py`, reconciled on merge)
4. `TESTS-RESULTS/2026-11-20+GH-1547/` (recorded paired pre-change vs candidate checks + red controls + GH-1527 read-only invariance check + `provenance.jsonl`)
- *(Note on `CHANGELOG.md`: omitted from branch edits per repo policy / PDDA guidance unless explicitly required; reconciliation handles routine ledger views.)*

### Planned Verification & Red Controls (`TESTS-RESULTS/2026-11-20+GH-1547/manual-check.md`)
1. **Red control (pre-change):** `skills/1-hourly/kickstart/scripts/kickstart_status.py` does not exist at base `0edbab45d6`.
2. **Stuck vs Live & Full Stopped-Ownership fixtures (U3):**
   - Active live (`owner=live`, 30s log) → `waiting`
   - Quiet live (`owner=live`, 240s log) → `quiet`
   - Old log with live ownership (`owner=live`, 900s log) → `stale-candidate` (precedence over `waiting`; advisory present)
   - Dead coordinator + live child/session (`owner=stopped`, `lock=clear`, `children=live`, `sessions=stopped`) → NOT `confirmed-stopped`
   - Dead coordinator + unknown child/session (`owner=stopped`, `lock=clear`, `children=unknown`, `sessions=unknown`) → NOT `confirmed-stopped` (`unknown` or `stale-candidate` if old log)
   - Complete 4-part stopped proof (`owner=stopped`, dead PID, `lock=clear`, `children=stopped`, `sessions=stopped`) → `confirmed-stopped`
3. **Unapplied amendment fixture:** run record with `OPERATOR_AMENDMENT:` + `PARENT_NOTE:` lacking `APPLIED:` (including a legacy parse-warning shape) → surfaced in `unapplied_amendments`; once `APPLIED:` present → cleared.
4. **Stale attempt + remote PR state fixture (U10):** pinned `LANDING_CLONE` `.tick/merge-cleanup/.../pr-1539.json` (`outcome: "in_progress"`) paired with `--remote-prs-json` (`MERGED`, `OPEN` same head, `OPEN` changed head, missing → `unknown`); second unpinned clone ignored.
5. **Final-QA staleness fixtures:**
   - Canonical green `GATE: final-QA` + matching full/abbreviated `--development-head` → `fresh`
   - Canonical green `GATE: final-QA` + later non-landing task `GATE: PR-999` + matching `--development-head` → STILL `fresh`
   - Canonical red `GATE: final-QA` → `stale`
   - Canonical green `GATE: final-QA` + real later `MERGED` line (or newer `--development-head`) → `stale`
   - Canonical green `GATE: final-QA` + no `--development-head` → `unknown` (unverified local head)
6. **Stop-reason attribution fixtures:**
   - Previous stale `cap-stalled` file (plain text, no invocation ID) → `unknown (unattributable)`
   - Different invocation writing a NEWER shared file (mtime > run start, different/missing invocation ID) → STILL `unknown (unattributable)` (mtime alone rejected!)
   - Matching-A stale sidecar `.meta.json` paired with plain-text overwritten-B payload → `unknown (unattributable)` (sidecar-only rejected!)
   - Conflicting payload `invocation_id=B` paired with matching-A sidecar `.meta.json` → `unknown (unattributable)`
   - Single self-contained structured shared payload matching `--invocation-id` (JSON or keyed lines) and exclusive per-run `--receipt` → quoted verbatim
7. **GH-1527 Read-Only Live Check:** live `kickstart_status.py` run with logging `git` shim on `PATH` and before/after `git show-ref`, `FETCH_HEAD` stat/sha256, `git count-objects -v` → 0 mutating git calls, all 3 snapshots byte-identical.
8. **Static & Governance Gates:** `utils/ci-route.sh pull_request` (`route=docs`), `mypy --allow-untyped-defs --allow-incomplete-defs`, `./utils/pdda/pdda.sh run` (0 errors), zero raw `<home-dir>/` paths, full `provenance.jsonl`.
