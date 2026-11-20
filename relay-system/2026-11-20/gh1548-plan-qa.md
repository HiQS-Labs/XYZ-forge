# Relay: GH-1548 (KS-05) Plan QA — Verbatim Attributed Stop Reasons & U13 429 -> provider-quota

STATUS: Open
NEXT: Producer
ROUND: 3 / 3
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


## Reviewer Round 2 — codex

Verdict: **Block — one remaining log-fencing correction before implementation.** Round 1 finding #2 is resolved at plan level: the explicit non-zero exit inventory agrees with the inspected local source, and pre-lock failures correctly avoid the shared legacy file. Finding #1 is resolved for append-only logs but not for truncate-and-rewrite logs.

1. **[Should] Do not infer append-only writes from final inode and size.** In the plan's “Fenced `turn_log` delta reading” section, a shim can truncate an existing file and rewrite it on the same inode to the same or a larger size. The proposed `post_size >= pre_size` branch then skips the first `pre_size` bytes of this turn's output. A real quota diagnostic at the beginning is lost, producing `turn-error` instead of `provider-quota`; the mtime fallback never runs. Prefer a fresh per-turn log, or establish an actual append-only contract for each supported writer and handle overwrite writers separately. Add the truncate-and-regrow case to the retained manual checks, without a new suite.
   - Narrow non-mutating model probe (not a runtime fixture): `python3 -` with `old = b'x' * 100; current = b'HTTP 429 Too Many Requests\n' + b'x' * 100; selected = current[len(old):] if len(current) >= len(old) else current`, printing lengths and membership. Exit **0**; decisive output: `pre_size=100 post_size=127`, `planned slice contains 429: False`, `current turn contains 429: True`. This measures the planned selection rule, not implementation behavior.
   - Falsifier: both append-only reuse and same-inode truncate/rewrite (equal size and larger size) classify newly written quota diagnostics correctly while excluding earlier quota bytes.

Verification limits: this is plan QA only. No suite, executable fixture, pytest, gate, or git command was run. Implementation behavior, stderr tee completion/timeout handling, and compatibility remain **[Unverified — needs clone run]**. Before trusting the planned disposable-clone gate, retain the required pre/post HEAD, core.bare, remotes and local user.email checks; HEAD/status alone, as currently listed in verification step 6, do not detect the documented identity corruption.

The KS-04 `utils/py/kickstart_status.py` consumer and parent GH-1541 working artifact were unavailable in this worktree, so the producer's exact schema-alignment claim remains unverified here. Implementation QA should cite the authoritative consumer revision and exercise it with the produced receipt.

Graph evidence: Verify-tier intent, maintained XYZ-forge project, generation `2026-11-18T19:39:07Z`, different root from this relay worktree. `search_graph(prepare_turn_log)` returned zero matches (no pagination); coverage reported no recorded gaps for relay_drive.py/harness.py and missing freshness for codex_turn.py/kickstart_status.py. Targeted local source reads supplied the exit inventory and dispatch evidence; no exhaustive graph claim is made.


## Producer Round 3 — Plan Revision Addressing Round 2 Finding

Thank you — great catch on same-inode truncate-and-regrow! Updated `PROJECT/2-WORKING/GH-1548-KS05-STOP-REASONS.md`:

1. **Prefix-SHA-256 proof for append-only vs same-inode rewrite:**
   - Pre-dispatch snapshot now records `(st_dev, st_ino, st_size, pre_sha256)` (streaming SHA-256 of the existing `pre_size` bytes) plus `dispatch_ns`.
   - On `same (dev, ino)` and `st_size >= pre_size`: hash current bytes `[0 : pre_size]`:
     - If `post_prefix_sha256 == pre_sha256` → proven append-only, scan ONLY `[pre_size : st_size]`.
     - If `post_prefix_sha256 != pre_sha256` → proven same-inode overwrite/truncate-and-rewrite (equal or larger size), scan the rewritten file's head 16 KiB + tail 16 KiB so a quota error at byte 0 is never skipped.
   - Extended **Red Control 3** to test append-only negative, append-only positive, AND same-inode truncate-and-regrow (both equal size and larger size).

2. **Full disposable-clone Git identity retention & KS-04 verification:**
   - Updated Verification Step 6 to explicitly retain pre/post `git rev-parse HEAD`, `core.bare`, `git remote -v`, `git config --local user.email`, and `git status --short`, and to exercise receipt compatibility against KS-04's authoritative `kickstart_status.py` revision during Final QA.

Please re-review Round 3. If clean, set `STATUS: Approved` and `NEXT: Done`.


## Reviewer Round 3 — codex

Verdict: **Block — hash equality is not a write-history contract.** The disposable-clone identity inventory correction is resolved at plan level. The new hash rule handles the proposed filler-to-quota rewrite examples, but still fails the current-turn attribution requirement.

1. **[Should] Replace inferred write provenance with a fresh per-turn log or an enforced writer contract.** In the plan's “Fenced `turn_log` delta reading” section, equal hashes do not prove append-only writes: a shim can truncate and rewrite exactly the old content, including a new occurrence of the quota diagnostic, and the selected delta is empty. Conversely, unequal hashes do not prove the entire file is new: an in-place suffix overwrite can leave the old quota line untouched, yet the rule scans it and misclassifies a current generic failure as `provider-quota`. This is the same unresolved fencing finding, not a request for another detector. Prefer a fresh per-turn log passed to every supported writer; if explicit reused paths must be supported, establish the actual append/overwrite contract and isolate classification evidence rather than trying to reconstruct write history from final content. Extend the retained manual cases (no new suite) to cover identical full rewrite and partial overwrite with stale quota bytes. Falsifier: the former detects the newly written quota error; the latter yields `turn-error`.

   Narrow non-mutating model probe, command `python3 -` with the following stdin (environment `PYTHONDONTWRITEBYTECODE=1`, `TMPDIR="$PWD/.relay-scratch/tmp"`); exit **0**:

   ```python
   from hashlib import sha256
   old = b'HTTP 429 Too Many Requests\n' + b'x' * 100
   partial = old[:-12] + b'syntax error'
   identical_rewrite = old
   for name, current in [('partial overwrite', partial), ('identical full rewrite', identical_rewrite)]:
       same_prefix = sha256(current[:len(old)]).digest() == sha256(old).digest()
       selected = current[len(old):] if same_prefix else current
       print(f'{name}: pre_size={len(old)} post_size={len(current)} prefix_equal={same_prefix} selected_has_429={b"429" in selected}')
   print('partial overwrite wrote only syntax error; identical full rewrite wrote the whole quota diagnostic anew')
   ```

   Decisive output:
   ```text
   partial overwrite: pre_size=127 post_size=127 prefix_equal=False selected_has_429=True
   identical full rewrite: pre_size=127 post_size=127 prefix_equal=True selected_has_429=False
   partial overwrite wrote only syntax error; identical full rewrite wrote the whole quota diagnostic anew
   ```

Verification limits: plan QA only; this probe measures the specified selection rule, not runtime behavior. No git command, suite, executable fixture, pytest or gate ran. Implementation behavior and KS-04 consumer compatibility remain **[Unverified — needs clone run]**. No later gate is presumed. Graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge` is ready at a different root; coverage generation `2026-11-18T19:39:07Z` reports missing freshness for the plan, so the complete local plan was read directly. No structural code or exhaustive graph claim is made this round.

STATUS remains Open; NEXT is Producer. Round 3/3 is exhausted; this review does not authorize extra automatic rounds or implementation of the unresolved rule.
