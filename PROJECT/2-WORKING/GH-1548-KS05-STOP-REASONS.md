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
| Bootstrapped fresh clone off reconciled `origin/development` (`0edbab45d6`), registered `rmi-01M7W0ZV5PABDCY8K0SWKV6QKS`, completed grounded recon of `utils/py/harness.py:312`, `utils/py/relay_drive.py:636-644,917-1003,1153-1199`, `utils/py/marathon_drive.py:3530,3743`, `test/gh115-round-cap.sh`, and `test/gh505-relay-attest.sh` | Complete Codex Plan QA (`relay-system/2026-11-20/gh1548-plan-qa.md`), mark accepted-start, implement changes, run paired red/green checks + background full classified gate with mypy venv, Final QA, PR, and land |

## Goal & Scope (refs #1548, #1541 v5 KS-05 + U13, #1536)

Resolve two failure-attribution gaps exposed by run 1 (interventions #2 and #3, where a 3-round relay cap was misread as Codex quota, plus U13 where a 429/quota failure is hidden behind a generic turn failure):

### 1. U13: Classify 429 / Quota Exhaustion as `provider-quota` (Distinct from `cap-stalled` and `turn-error`)
- **`utils/py/harness.py`:**
  - Define module-level `PROVIDER_QUOTA_RE = re.compile(r"(?:\b429\b|too many requests|rate.?limit|usage.?limit|insufficient_quota|\bquota\b)", re.I)` and helper `is_provider_quota_error(text: str) -> bool`.
  - At line 312 (`CodexAdapter.evaluate` non-zero exit): classify matching 429/rate-limit/usage-limit/quota text as `"provider-quota"` (replacing internal-only `"rate-limited"`), distinct from `"adapter-error"` and `"timeout"`.
- **`utils/py/relay_drive.py`:**
  - Reuse the exact same quota detector (importing `is_provider_quota_error` from `harness` with stdlib regex fallback if invoked standalone).
  - During a turn shim execution (`proc = subprocess.Popen(...)`), capture a bounded tail (last 16 KiB) of the shim's stderr via a streaming pipe/tee thread that still forwards every line transparently to `relay_drive`'s own `sys.stderr` (preserving real-time operator output and process group semantics), and also inspect the tail of `turn_log` (if present and written during this turn).
  - When `res_code != 0` and the terminal verdict is NOT `"forged"`:
    - If `is_provider_quota_error(combined_tail)` is true → classify stop reason as **`provider-quota`** (distinct from `cap-stalled` and `turn-error`).
    - Otherwise → classify stop reason as **`turn-error`** (preserving `exit_code = res_code` in the structured stop receipt and diagnostic line; preserving `sys.exit(res_code)` exit status unchanged).
  - Update `skills/1-hourly/relay-xyz/SKILL.md` exit-5 table note to reflect `provider-quota` and `turn-error`.

### 2. Per-Invocation Stop-Reason Attribution (Never Inherit a Previous Run's `.relay-scratch/escalation-reason`)
- **Backward compatibility with existing callers/tests:**
  - `utils/py/marathon_drive.py:3743`, `test/gh115-round-cap.sh`, and `test/gh505-relay-attest.sh` read plain text from `<root_dir>/.relay-scratch/escalation-reason`. Keep writing plain text to `.relay-scratch/escalation-reason` so zero existing consumers break.
- **Invocation-attributed receipt & verbatim stderr diagnostic in `utils/py/relay_drive.py`:**
  - Add CLI flags `--invocation-id <id>` (default: `RELAY_INVOCATION_ID` env var, else auto-generated `<relay_task>-<pid>-<epoch_ms>`) and `--stop-receipt <path>` (default: `RELAY_STOP_RECEIPT` env var, else `<root_dir>/.relay-scratch/stop-reasons/<safe-invocation-id>.json`).
  - Sanitize `invocation_id` for filenames (`re.sub(r"[^A-Za-z0-9._-]", "_", invocation_id)`), rejecting empty/traversal values.
  - Add `write_stop_receipt(reason_str, exit_code)`: atomically writes (tempfile + `os.replace`) a single self-contained JSON receipt:
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
    AND emits one canonical verbatim diagnostic line to stderr:
    `relay-drive: stop-reason=<reason_str> invocation_id=<id> exit_code=<rc> receipt=<path>`
  - Invoke `write_stop_receipt(...)` on EVERY non-zero stop path in `relay_drive.py`:
    - `exit_escalate(reason_str)` (exit 4: `cap-stalled`, `cap-progressing-extended`, `human-escalation`, `forged-terminal`, `unattested-terminal`, `close-mismatch`, `consult-verify-divergence`, etc.)
    - Failed turn (`res_code != 0`: `provider-quota`, `turn-error`, or forged-terminal variants)
    - Review handback (exit 5: `review-handback`)
    - Stall / no-progress exits (exit 3: `zero-output-stall`, `no-action-stall`, `no-progress`) — NOTE: previously exit 3 did NOT overwrite `.relay-scratch/escalation-reason`, so a previous run's `cap-stalled` stayed behind and was misread as the second run's stop reason! Now exit 3 writes its own per-invocation stop receipt AND updates `.relay-scratch/escalation-reason` (or clears/replaces it with the actual exit-3 code) so a second run NEVER inherits the first run's `cap-stalled`!
  - Note on `kickstart_status.py` (KS-04): KS-04 already consumes `--receipt <path>` JSON (`stop_reason`/`reason`) and `--run-log <path>` (`stop-reason=<reason>`) verbatim, and rejects plain-text unattributable `.relay-scratch/escalation-reason`. Once KS-04 lands, `kickstart_status.py` reads these exact KS-05 receipts natively with zero schema drift.

### Files Changed (Full Route — `utils/py/harness.py`, `utils/py/relay_drive.py`; Zero New Test Suites per GH-831)
1. `utils/py/harness.py` (`PROVIDER_QUOTA_RE`, `is_provider_quota_error`, normalize 429/quota to `"provider-quota"`)
2. `utils/py/relay_drive.py` (`--invocation-id`, `--stop-receipt`, streaming stderr capture for quota detection, `provider-quota` vs `turn-error`, atomic per-invocation stop receipt + verbatim stderr line on all non-zero exits including exit 3)
3. `skills/1-hourly/relay-xyz/SKILL.md` (update exit-5 reason table note)
4. `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md` + canonical `releases.db`/`releases.sql`
5. `TESTS-RESULTS/2026-11-20+GH-1548/` (recorded paired pre-change vs candidate checks + full gate log + `provenance.jsonl`)

### Planned Verification & Red Controls (`TESTS-RESULTS/2026-11-20+GH-1548/manual-check.md`)
1. **Red control A (previous `cap-stalled` followed by a different stop):**
   - Pre-change (`0edbab45d6`): leave `cap-stalled` in `.relay-scratch/escalation-reason`, then run `relay_drive.py --review-once` with a no-action stub (exit 3). Observe `.relay-scratch/escalation-reason` STILL reads `cap-stalled` and no per-invocation receipt exists — the second run inherits the first run's `cap-stalled`!
   - Candidate: same sequence with `--invocation-id run2 --stop-receipt ...`: Run 2's receipt records `no-action-stall` (NOT `cap-stalled`), stderr prints `stop-reason=no-action-stall invocation_id=run2`, and `.relay-scratch/escalation-reason` no longer holds Run 1's `cap-stalled`.
2. **Red control B (U13 — simulated 429 vs generic turn-error vs cap-stalled):**
   - Pre-change (`0edbab45d6`): simulated 429 stub exiting 5 → `relay_drive.py` writes generic `turn-failed-rc5`; `harness.py` returns `"rate-limited"`.
   - Candidate:
     - Simulated 429 stub (`HTTP 429 Too Many Requests / quota exceeded`, exit 5) → `relay_drive.py` writes `provider-quota` (receipt + stderr + escalation file) AND `harness.py` `CodexAdapter` returns `normalized="provider-quota"`.
     - Simulated generic failure stub (`syntax error`, exit 5) → `relay_drive.py` writes `turn-error` (distinct from `provider-quota` and `cap-stalled`).
     - Round-cap exhaustion (`--round-cap 1`, non-converging stub, exit 4) → `relay_drive.py` writes `cap-stalled` (distinct from `provider-quota` and `turn-error`).
3. **Existing test compatibility & full classified gate (background):**
   - Verify `bash test/gh115-round-cap.sh` and `bash test/gh505-relay-attest.sh` pass.
   - Classify diff via `utils/ci-route.sh pull_request` (`route=full`).
   - Run full classified gate (`validate.sh` / pre-push full gate) in the **background** with `/Users/noelsaw/kickstart-clones/mypyvenv/bin` on `PATH` and retain its log + `provenance.jsonl` (zero raw `/Users/` paths).
