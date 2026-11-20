# Relay: GH-1548 (KS-05) Plan QA — Verbatim Attributed Stop Reasons & U13 429 -> provider-quota

STATUS: In Progress
NEXT: Reviewer
ROUND: 1 / 3
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
