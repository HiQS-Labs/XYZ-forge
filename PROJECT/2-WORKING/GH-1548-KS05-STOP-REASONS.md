---
title: "GH-1548 (KS-05): quote stop reasons verbatim, attribute to current run, and surface 429 as provider-quota"
status: active
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
goal: "Emit invocation-attributed per-run stop receipts and verbatim stop diagnostics in utils/py/relay_drive.py and classify 429/quota failures as provider-quota in utils/py/harness.py and utils/py/relay_drive.py, distinct from cap-stalled and turn-error"
gh_issue: 1548
roadmap_id: rmi-01M7W0ZV5PABDCY8K0SWKV6QKS
---

# GH-1548 (KS-05): Stop Reasons Quoted Verbatim, Invocation-Attributed & 429 → `provider-quota`

## Status

| What was just completed | What's next |
|---|---|
| Addressed Codex Plan QA Round 1 & Round 2 findings (prefix-SHA-256 append-vs-rewrite detection + full disposable-clone Git identity checks) (pre-dispatch byte-offset/inode fencing for `turn_log`, complete exit-code attribution table covering exits 1/2/3/4/5/8 including post-start `1090,1097`, disposable-clone full-gate isolation & KS-04 receipt schema alignment) | Complete Codex Plan QA Round 3 (`relay-system/2026-11-20/gh1548-plan-qa.md`), mark accepted-start, implement changes, run paired red/green checks + background full classified gate in isolated clone, Final QA, PR, and land |

## Goal & Scope (refs #1548, #1541 v5 KS-05 + U13, #1536)

Resolve two failure-attribution gaps exposed by run 1 (interventions #2 and #3, where a 3-round relay cap was misread as Codex quota, plus U13 where a 429/quota failure is hidden behind a generic turn failure):

### 1. U13: Classify 429 / Quota Exhaustion as `provider-quota` (Distinct from `cap-stalled` and `turn-error`)
- **`utils/py/harness.py`:**
  - Define module-level `PROVIDER_QUOTA_RE = re.compile(r"(?:\b429\b|too many requests|rate.?limit|usage.?limit|insufficient_quota|\bquota\b)", re.I)` and helper `is_provider_quota_error(text: str) -> bool`.
  - At line 312 (`CodexAdapter.evaluate` non-zero exit): classify matching 429/rate-limit/usage-limit/quota text as `"provider-quota"` (replacing internal-only `"rate-limited"`), distinct from `"adapter-error"` and `"timeout"`.
- **`utils/py/relay_drive.py`:**
  - Reuse the exact same quota detector (importing `is_provider_quota_error` from `harness` with stdlib regex fallback if invoked standalone).
  - During a turn shim execution (`proc = subprocess.Popen(...)`), capture a bounded tail (last 16 KiB) of the shim's stderr via a streaming pipe/tee thread that still forwards every line transparently to `relay_drive`'s own `sys.stderr` (preserving real-time operator output and process group semantics).
  - **Fenced `turn_log` delta reading (Plan QA Round 1 Finding #1 + Round 2 Finding #1):**
    - Immediately before dispatching the turn shim (`prepare_turn_log` already resolved `turn_log`), snapshot `pre_log_stat = (st.st_dev, st.st_ino, st.st_size, pre_sha256)` — computing the streaming SHA-256 digest of the existing `pre_size` bytes — if `turn_log` exists (else `None`), and record `dispatch_ns = time.time_ns()`.
    - After the turn shim exits with `res_code != 0`, inspect ONLY bytes proven to be produced by THIS turn (sampling head 16 KiB + tail 16 KiB of any selected region > 32 KiB so a quota error at either the start or end is caught):
      - If `pre_log_stat is None` and `turn_log` now exists → entire file is newly created by this turn.
      - If `(st.st_dev, st.st_ino) == (pre_dev, pre_ino)` and `st.st_size >= pre_size`:
        - Hash the current file's first `pre_size` bytes (`post_prefix_sha256`).
        - If `post_prefix_sha256 == pre_sha256` → **proven append-only**: seek to `pre_size` and scan ONLY `[pre_size : st.st_size]` (empty if `st.st_size == pre_size`; earlier bytes in a reused log are NEVER scanned).
        - If `post_prefix_sha256 != pre_sha256` → **proven same-inode truncate-and-rewrite / overwrite**: scan the rewritten file's head + tail (even when `post_size == pre_size` or `post_size > pre_size`), so a quota error written at byte 0 of a rewritten log is NEVER skipped!
      - If the file was replaced (`(st_dev, st_ino)` changed) or truncated smaller (`st.st_size < pre_size`) → scan head + tail ONLY if `st.st_mtime_ns >= dispatch_ns`; otherwise read `""` conservatively.
  - When `res_code != 0` and the terminal verdict is NOT `"forged"`:
    - If `is_provider_quota_error(stderr_tail + "\n" + turn_log_delta)` is true → classify stop reason as **`provider-quota`** (distinct from `cap-stalled` and `turn-error`).
    - Otherwise → classify stop reason as **`turn-error`** (recording `exit_code = res_code` in the structured stop receipt and diagnostic line; preserving `sys.exit(res_code)` unchanged).
  - Update `skills/1-hourly/relay-xyz/SKILL.md` exit-code notes to document `provider-quota`, `turn-error`, and per-invocation stop receipts.

### 2. Per-Invocation Stop-Reason Attribution (Never Inherit a Previous Run's `.relay-scratch/escalation-reason`)
- **Backward compatibility with existing callers/tests:**
  - `utils/py/marathon_drive.py:3743`, `test/gh115-round-cap.sh:141`, and `test/gh505-relay-attest.sh:136` read plain text from `<root_dir>/.relay-scratch/escalation-reason`. Keep writing plain text to `.relay-scratch/escalation-reason` on post-start runtime stops so zero existing consumers break.
- **Invocation-attributed receipt & verbatim stderr diagnostic in `utils/py/relay_drive.py`:**
  - Add CLI flags `--invocation-id <id>` (default: `RELAY_INVOCATION_ID` env var, else auto-generated `<relay_task>-<pid>-<epoch_ms>`) and `--stop-receipt <path>` (default: `RELAY_STOP_RECEIPT` env var, else `<root_dir>/.relay-scratch/stop-reasons/<safe-invocation-id>.json`).
  - Sanitize `invocation_id` for default filenames (`re.sub(r"[^A-Za-z0-9._-]", "_", invocation_id).strip("._-") or "run"`), preventing path traversal.
  - Add `write_stop_receipt(reason_str, exit_code, update_legacy_file=True)`:
    - Atomically writes (tempfile in same directory + `os.replace`) a single self-contained JSON receipt matching KS-04's `kickstart_status.py` consumer schema:
      ```json
      {
        "schema": 1,
        "invocation_id": "<id>",
        "relay_task": "<task>",
        "reason": "<exact reason_str>",
        "stop_reason": "<exact reason_str>",
        "exit_code": 4,
        "recorded_at": "<ISO-8601-UTC>"
      }
      ```
    - When `update_legacy_file=True` (driver lock is held — post-start runtime stops), also atomically updates `<root_dir>/.relay-scratch/escalation-reason` with `reason_str + "\n"` so no earlier run's `cap-stalled` survives into a subsequent stop.
    - Emits one canonical verbatim diagnostic line to stderr:
      `relay-drive: stop-reason=<reason_str> invocation_id=<id> exit_code=<rc> receipt=<path>`

### 3. Complete Non-Zero Exit-Code Attribution Inventory (Plan QA Round 1 Finding #2)

| Location in `utils/py/relay_drive.py` | Exit Code | Category | Stop Reason | Writes Per-Invocation Receipt + Stderr Line? | Updates Legacy `.relay-scratch/escalation-reason`? |
|---|---|---|---|---|---|
| Line 30 (CLI usage / bad args) | `2` | Preflight usage (explicitly excluded) | n/a | No (before repo/invocation setup) | No |
| Line 274 (`lane-attempt-cap`) | `8` | Preflight guard (before lock) | `lane-attempt-cap` | Yes | No (lock not held) |
| Lines 543, 551 (lock active / acquire fail) | `1` | Preflight lock contention | `driver-lock-active` / `driver-lock-acquire-failed` | Yes | No (another driver may hold lock) |
| Line 642 (`exit_escalate(...)`: lines 800, 812, 824, 842, 869, 1108, 1120, 1126, 1130, 1135, 1199) | `4` | Post-start escalation | Exact `reason_str` (`cap-stalled`, `cap-progressing-extended`, `human-escalation`, `forged-terminal`, `unattested-terminal`, `close-mismatch`, `token-state`, `consult-verify-divergence`, etc.) | Yes | Yes |
| Line 1003 (non-zero turn shim) | `res_code` (preserved) | Post-start turn failure | `provider-quota` (if 429/quota in stderr tail or post-offset `turn_log` delta) else `turn-error` | Yes | Yes |
| Lines 1090, 1097 (post-start consult escalation write failure, GH-204) | `1` | Post-start runtime failure | `consult-escalation-write-failed` | Yes | Yes |
| Line 1157 (`--review-once` handback) | `5` | Post-start review handback | `review-handback` | Yes | Yes |
| Lines 1160, 1163, 1168 (stalls / no-progress) | `3` | Post-start stall | `zero-output-stall` / `no-action-stall` / `no-progress` | Yes | Yes (replaces any prior `cap-stalled`) |

Exit `0` paths (lines 75, 819, 848, 1143, 1194) are normal completion / `--help` / dry-run and do not emit a stop-failure receipt.

## Planned File Touch List
1. `utils/py/harness.py` — `PROVIDER_QUOTA_RE`, `is_provider_quota_error()`, classify 429/quota as `"provider-quota"` at line 312.
2. `utils/py/relay_drive.py` — `--invocation-id`, `--stop-receipt`, `write_stop_receipt()`, stderr tee capture + pre-dispatch offset/inode-fenced `turn_log` delta read, U13 `provider-quota` vs `turn-error` classification, and full exit-inventory coverage (exits 1/3/4/5/8).
3. `skills/1-hourly/relay-xyz/SKILL.md` — document `provider-quota`, `turn-error`, and per-invocation stop-reason receipts.
4. `TESTS-RESULTS/2026-11-20+GH-1548/` — paired red/green manual check, transcripts, existing relay regression runs, disposable-clone full classified gate log + pre/post Git identity checks, diffs, PDDA log, and `provenance.jsonl`.
5. `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md` — this working doc.

## Verification Plan (GH-831 Compliant — No New Test Suites)
Recorded under `TESTS-RESULTS/2026-11-20+GH-1548/`:
1. **Red Control 1 (stale `cap-stalled` vs new exit-3 stop):** Pre-change `relay_drive.py` leaves stale `cap-stalled` in `.relay-scratch/escalation-reason` after a zero-output exit-3 stall with no invocation-attributed receipt; candidate writes invocation-attributed JSON receipt `zero-output-stall` + verbatim stderr line and overwrites legacy file with `zero-output-stall`.
2. **Red Control 2 (U13 429/quota vs `turn-error` vs `cap-stalled`):**
   - `CodexAdapter.evaluate` non-zero exit with HTTP 429 returns `"provider-quota"` (vs pre-change `"rate-limited"`), non-quota returns `"adapter-error"`.
   - `relay_drive.py` shim exiting non-zero with `HTTP 429 Too Many Requests` / `insufficient_quota` on stderr → `provider-quota`.
   - `relay_drive.py` shim exiting non-zero with generic error → `turn-error` (distinct from `provider-quota` and `cap-stalled`).
3. **Red Control 3 (Plan QA Round 1 & Round 2 Finding #1 — reused `turn_log` append & same-inode truncate/rewrite fencing):**
   - Append-only negative: pre-populate reused `turn_log` with `HTTP 429 Too Many Requests`; run a failing turn that appends ONLY `syntax error` and exits 5 → classified as `turn-error` (NOT `provider-quota`).
   - Append-only positive: run a failing turn that newly appends `HTTP 429 Too Many Requests` to the same reused `turn_log` and exits 5 → classified as `provider-quota`.
   - Same-inode truncate-and-regrow (equal size & larger size): pre-populate reused `turn_log` with 100 bytes of filler, then run failing turns that open the same file with `"w"` (same inode) and write `HTTP 429 Too Many Requests\n` at byte 0 padded to equal size (`post_size == pre_size`) and larger size (`post_size > pre_size`) → BOTH classified as `provider-quota` (prefix hash detects the rewrite and never skips byte 0).
4. **Red Control 4 (Plan QA Round 1 Finding #2 — post-start exit-1 attribution):**
   - Pre-seed stale `.relay-scratch/escalation-reason` with `cap-stalled`; trigger post-start consult-verify escalation write failure (no `STATUS:` line, exit 1 at line 1090) → emits verbatim `consult-escalation-write-failed` + invocation receipt + updates legacy file (never inherits stale `cap-stalled`), preserving exit code `1`.
   - Verify preflight lock-contention exit 1 emits `driver-lock-active` receipt without clobbering the active driver's `.relay-scratch/escalation-reason`.
5. **Existing Regression Checks:** Run `bash test/gh115-round-cap.sh` and `bash test/gh505-relay-attest.sh` unchanged.
6. **Full Classified Gate in Disposable Full Clone:** Because `utils/py/harness.py` and `utils/py/relay_drive.py` trigger `route=full`, run the full classified gate (`./utils/ci-route.sh` + repo gate) inside a fresh disposable full clone (isolated from this task clone, with `mypy==1.14.1` venv on `PATH`, executed in the background) and retain complete pre/post Git identity checks (`git rev-parse HEAD`, `git config --get core.bare`, `git remote -v`, `git config --local --get user.email`, `git status --short`) + full gate log + `./utils/pdda/pdda.sh run` (0 errors) + `provenance.jsonl`. During Final QA, verify receipt JSON compatibility directly against KS-04's authoritative `kickstart_status.py` revision.
