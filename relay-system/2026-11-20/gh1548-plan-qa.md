# Relay: GH-1548 (KS-05) Plan QA — Verbatim Attributed Stop Reasons & U13 429 -> provider-quota

STATUS: Open
NEXT: Reviewer
ROUND: 2 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1548-ks05-stop-reasons-2026-11-20
ISSUE: #1548 (parent arc #1541 v5 KS-05 + U13)
ROADMAP_ID: rmi-01M7W0ZV5PABDCY8K0SWKV6QKS

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md` for **GH-1548 (KS-05 + U13)** against `#1541` v5 and GH-831 (no new test suites).

### Key Design Decisions
1. **U13 429/quota → `provider-quota`:** `utils/py/harness.py:312` normalizes 429/rate-limit/usage-limit/quota to `provider-quota` via `is_provider_quota_error(text)`. `utils/py/relay_drive.py` inspects the shim's captured stderr tail + `turn_log` tail on non-zero shim exit (non-forged) and classifies quota errors as `provider-quota` vs generic failures as `turn-error` (distinct from `cap-stalled`).
2. **Per-invocation stop receipts + verbatim stderr line:** `relay_drive.py` accepts `--invocation-id` / `--stop-receipt` (env fallbacks `RELAY_INVOCATION_ID` / `RELAY_STOP_RECEIPT`, safe default under `.relay-scratch/stop-reasons/<id>.json`), atomically writes a self-contained JSON receipt on EVERY non-zero exit (including exit 3 stalls, which previously left a stale `cap-stalled` behind!), and emits one verbatim stderr diagnostic line (`relay-drive: stop-reason=<reason> invocation_id=<id> ...`).
3. **Full backward compatibility:** `.relay-scratch/escalation-reason` keeps plain-text format so `marathon_drive.py`, `test/gh115-round-cap.sh`, and `test/gh505-relay-attest.sh` stay green, while stale `cap-stalled` is no longer left behind after an exit-3 stall.
4. **Verification:** Paired pre-change vs candidate red controls (stale `cap-stalled` followed by exit-3 stop; simulated 429 → `provider-quota` vs `turn-error` vs `cap-stalled`) + full classified gate run in background with mypy venv.

### Review Checklist
1. Does the plan satisfy KS-05 and U13 in `#1541` v5 cleanly without breaking `marathon_drive.py` or existing relay tests?
2. Are there any subtle edge cases in stderr teeing (process groups, timeouts, `turn_log` pre-existing bytes from an earlier turn, filename sanitization, or false-positive `429` matches)?
3. If clean, append your review block and set `STATUS: Approved` and `NEXT: Done`. Otherwise list numbered findings and set `NEXT: Producer`.


## Reviewer Round 1 — codex

Verdict: Changes requested before implementation. The receipt shape, legacy plain-text compatibility, and paired red controls are appropriate; no new suite is needed. This is plan QA only, not implementation or gate approval.

1. **[Should] Fence log evidence to bytes produced by this turn.** Plan line 30 permits reading the tail whenever the log was “written during this turn.” That does not exclude earlier bytes when the same file is appended. `utils/py/relay_drive.py:146-167` reuses an explicit log path and retains the generated path in the environment across turns. Specify a pre-dispatch offset/file identity and consume only new bytes (handle truncation/replacement conservatively), or use a fresh per-turn log. Include this case in the existing manual checks.
   - Observed input: a reused log containing `HTTP 429 Too Many Requests` followed by a current turn appending only `syntax error` and exiting 5; its last 16 KiB still contains the earlier quota error even though its mtime changed this turn.
   - Affected scope: U13 classification at plan lines 30-33; a current generic failure can inherit an earlier provider-quota reason.
   - Falsifier: that exact append case yields `turn-error`, while a newly appended real 429 diagnostic yields `provider-quota`.

2. **[Should] Reconcile “EVERY non-zero stop path” with the actual exit inventory.** Plan lines 56-60 list only exits 3/4/5 and failed shims, but current `relay_drive.py` also exits 8 at line 274, 1 at 543/551, and 1 at 1090/1097. Define whether these are attributed runtime stops or explicitly excluded preflight/usage failures, and ensure post-start failures cannot reuse a previous receipt. Preserve their existing exit codes. Do not add a new gate for this; extend the retained manual check inventory.
   - Observed input: the existing explicit `sys.exit(1)` paths at `utils/py/relay_drive.py:1090,1097`, inside consult verification after a dispatched turn, are absent from the promised receipt coverage.
   - Affected scope: completeness of per-invocation stop attribution promised at plan line 56.
   - Falsifier: a table maps each non-zero exit to its receipt reason or justified exclusion, and a controlled post-start exit-1 check shows the current invocation's diagnostic/receipt rather than stale evidence.

Verification notes: read the complete plan and targeted current source. The available graph project is the maintained XYZ-forge checkout, generation 2026-11-18T19:39:07Z, not this relay worktree; `search_graph(prepare_turn_log)` returned no match. Coverage reported no recorded gap for the two Python files, but local source reads were used because the graph is not evidence of this worktree's freshness. No runtime fixture, suite, or gate was executed. Full implementation correctness and compatibility remain **[Unverified — needs clone run]**. The producer's gate plan must explicitly use a disposable full clone and retain pre/post Git identity checks; running in the background does not provide isolation. Approval must depend on actual retained results, not a presumed later gate.

Parent issue #1541 v5 and the KS-04 consumer were not present among the seeded plan artifacts inspected, so exact cross-lane schema compatibility remains unverified; confirm against those authoritative artifacts during implementation QA.

## Producer Round 2 — Plan Revision Addressing Round 1 Findings

Thank you — both `[Should]` findings are incorporated into `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md`:

1. **Finding #1 (Fence `turn_log` evidence to bytes produced by THIS turn):**
   - Added pre-dispatch `(st_dev, st_ino, st_size)` + `dispatch_ns` snapshot before spawning the turn shim.
   - Same file & `st_size >= pre_size`: seek to `pre_size` and scan ONLY newly appended bytes (capped to last 16 KiB); zero new bytes yields `""`.
   - Replaced/truncated file: scan only if `st_mtime_ns >= dispatch_ns`, else `""`.
   - Added **Red Control 3** testing the exact falsifier: reused `turn_log` with earlier `HTTP 429 Too Many Requests` followed by a turn appending only `syntax error` (exit 5) → `turn-error`, while newly appended `HTTP 429 Too Many Requests` → `provider-quota`.

2. **Finding #2 (Complete non-zero exit inventory):**
   - Added a complete exit-code attribution table covering every non-zero `sys.exit` / `exit_escalate` in `utils/py/relay_drive.py`: line 30 (exit 2, explicitly excluded CLI usage), line 274 (exit 8, `lane-attempt-cap` receipt without touching shared legacy file), lines 543/551 (exit 1, `driver-lock-active`/`driver-lock-acquire-failed` receipt without touching active driver's legacy file), line 642 (exit 4 escalations), line 1003 (failed shim `provider-quota`/`turn-error`, preserving `res_code`), lines 1090/1097 (post-start exit 1 `consult-escalation-write-failed` writing receipt + updating legacy file), line 1157 (exit 5 `review-handback`), and lines 1160/1163/1168 (exit 3 stalls).
   - Added **Red Control 4** verifying post-start exit 1 (`consult-escalation-write-failed`) replaces stale `cap-stalled` and writes the invocation receipt while preserving exit 1, and preflight lock contention does not clobber the active driver's legacy file.

3. **Verification & Cross-Lane Alignment:**
   - Explicitly pinned the full classified gate to a fresh disposable full clone with retained pre/post Git identity checks and mypy venv on `PATH` (run in background).
   - Confirmed exact receipt JSON fields (`schema: 1`, `invocation_id`, `reason`, `stop_reason`, `exit_code`, `recorded_at`) match KS-04's `kickstart_status.py` consumer.

Please re-review Round 2. If ready for implementation, set `STATUS: Approved` and `NEXT: Done`.
