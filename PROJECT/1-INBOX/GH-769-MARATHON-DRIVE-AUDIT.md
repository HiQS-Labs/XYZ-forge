---
title: "GH-769: marathon_drive.py audit (duplication, dead code, seams, performance, test gaps)"
status: Proposed (1-INBOX — not yet active)
gh_issue: 769
source: https://github.com/HiQS-Labs/XYZ-forge/issues/769
doc_type: feedback
created: 2026-09-23
updated: 2026-09-23
owner: Claude
goal: inventory what a safe refactor of utils/py/marathon_drive.py has to deal with, ranked, with a split plan and follow-up order
gh_issue: 769
doc_type: report
---

# GH-769: marathon_drive.py audit

## Summary

`utils/py/marathon_drive.py` (3,573 lines) is the default runtime for one marathon phase. `relay-automation/marathon-drive.sh:9-18` runs it with `exec` unless `XYZ_PYTHON=0`. Its callers are `marathon.sh` (once per phase), `jog_run.py` (the reviewed-item executor, which reads its `marathon-drive/result@1` receipt), and the `drive_command` that swarm-preflight emits. In `ARCHITECTURE/system-diagram.json` it is the `marathon` node, with edges from `operator-skills`, `planner-preflight` and `jog`, and edges to `relay-drive` and `gate-stack`.

The file's main structural problem is `main()`. It runs 2,502 lines (1015–3515), holds 52 nested closures, and shares state through single-element lists used as mutable cells. That is why so much logic is repeated inside it and why so little of it can be tested without a full driven run. I found 30 findings:

| Category | Count |
| --- | --- |
| Duplication inside the file | 10 |
| Duplication with other parts of the repo | 6 |
| Dead or unreachable code | 3 |
| Structure and seams | 3 |
| Performance and telemetry | 4 |
| Test gaps | 3 |
| Doc drift | 1 |

Three of them are real behaviour defects, not just cleanup:

- **F2:** `jog_run.py` still accepts `gemini` as a reviewer, which marathon rejects.
- **F18:** the macOS memory-compressor figure is 4x too low because the page size is hard-coded.
- **F19:** the RSS layer of the gate guard turns itself off without saying so when `ps` cannot run.

Test coverage is broad: 89 test files reference the driver. But almost all of it drives the whole script end to end. Several suites also pin the source text or copy a fixed list of files, and those will break on any split (F24). So the safety-net work has to come before any extraction.

I checked every finding against the code at `a47c212b` plus the working tree. Anything I could not verify is marked **unverified**.

## Findings (ranked)

"Effort" is S, M or L. "Confidence" is how sure I am that the finding is accurate as stated.

| id | category | file:line | evidence | proposed fix | what else it affects | effort | confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | structure | `marathon_drive.py:1015-3515` | `main()` is 2,502 lines with 52 nested `def`s. State is passed between closures through list cells: `run_gate_result`, `drive_started`, `phase_outcome_recorded` (1410-1418), `lane_branch_cut` (2586), and `timeout_reason`/`timeout_emit` (3372-3373). Closures refer to names that are bound later: `_write_interrupted_phase_record` (1751) reads `relay_file`, `phase_dir`, `rel_relay` and `save_transcript`, which are only defined at 2062-2198. | Add a `RunContext` dataclass (args, roots, paths, tokens, flags). Lift the closures to module functions that take `ctx`. Split into modules as in the plan below. | Every closure. Also the tests that call `main()` directly (`test/test_python_layer.py:98-157`). | L | high |
| F2 | cross-repo dup (drift) | `marathon_drive.py:771-818, 1942-1954, 1956-2002, 2022, 2262-2277, 3311`; `jog_run.py:176` | The set of agent ids is maintained by hand in 6 places in this file: probe, `*_AGENT` reset, `route_agent`, the reviewer check, `GATE_SCRUBBED_ENV`, and the `*_TURN_ROOT` tuple. The comments at 1950 and 2271 count "NINTH" and "TENTH" copies. `jog_run._MARATHON_REVIEWER_PREFIXES = ("codex", "gemini", "agy")` still includes `gemini`, which marathon removed in GH-346 (2011-2014, 2022). Jog's own comment says this mirror exists so "an invalid reviewer fails before ANY lease mutation". A `gemini*` reviewer passes Jog and then dies in marathon with exit 2. | Put one `AGENT_ROUTES` table in the file and drive probe, reset, route and turn-root from it. Keep the `GATE_SCRUBBED_ENV` literal, which gh307 and gh441 require. Remove `gemini` from `jog_run.py:176`, or import the prefixes. | `test/gh346-gateway-allowlists.sh`, which checks each copy by grepping the source. `jog_run` lease flow. `bin/marathon-yaml:99` (already codex/agy only). | S (jog fix), M (table) | high |
| F3 | cross-repo dup | `marathon_drive.py:1116-1177, 1242-1294, 1701-1732, 2437-2448`; `relay_drive.py:245-290, 402-416, 515-551, 178-198` | The following exist nearly word for word in `relay_drive.py`: the lock acquisition and stale-reclaim block, `lane_attempt_gate` and `lane_attempt_reset` (including the `date -u` subprocess), the `token_state` parser, and the `tick analyze` cost-summary extractor. The only differences are message prefixes, stdout vs stderr, and receipt bookkeeping. `relay_drive.py:516` already says "a fourth inline copy is the bug class". | Move `acquire_driver_lock(root, label)`, a `lane_attempts` helper (count, gate, reset), `tick_info(task) -> dict` and `tick_cost_block()` into `rtl.py`, which both files already import for `driver_lock_path`. | `test/gh376-relay-drive-lock-parity.sh` (greps `lock_dir, lock_label = driver_lock_path(root)` at :284), `test/lane-attempt-cap.sh`, `test/driver-lock.sh`, and the Bash twins' parity. | M | high |
| F4 | cross-repo dup | `marathon_drive.py:2107, 2201, 3020-3023`; `rtl.py:643` | `rtl_transcript_root` is resolved 3 times by running `bash -c 'source relay-turn-lib.sh && rtl_transcript_root "<root>"'` with `shell=True`. `rtl._rtl_transcript_root` is a Python port that documents itself as equivalent. The Bash side is `relay-turn-lib.sh:134-159`, and `rtl.py:616-666` ports it together with `rtl_repo_slug`. On escalation it runs twice, because `escalate()` resolves it and then calls `save_transcript()`, which resolves it again. `root` is placed inside a double-quoted shell string, so a path containing `"`, `$` or a backtick would break it (from reading the code; I did not run it). Measured cost of the Bash call on this host is about 0.00s, so this is not a performance issue. | Call `rtl._rtl_transcript_root(root)` (and make it public). Resolve it once per run and keep it on the context. | `test/gh314-transcript-writeset.sh` and `test/archive-writers.sh` (the `XYZ_ARCHIVE_ROOT` paths). `swarm_preflight.py:1696` and `relay_drive.py:954` have the same pattern. | S | high |
| F5 | in-file dup + test gap | `marathon_drive.py:2319-2331` vs `2405-2418` | The GH-378 baseline-allowance block, including setting `run_gate_result` and `_RESULT`, appears verbatim in both the unguarded (`MARATHON_GATE_GUARD=0`) and guarded branches. `test/gh378-gate-requires-green-suite.sh` only exercises the guarded path. `test/gh390-gate-guard.sh:269` uses guard=0 without a baseline. So the unguarded copy is never tested. | Pull out `_apply_gate_verdict(rc, baseline)` and call it from both branches. Add a guard=0 + baseline case. | gh378, gh390. | S | high |
| F6 | in-file dup | `marathon_drive.py:499-509, 2437-2448, 3209-3219` | `tick info` output is parsed three ways: `resolve_force_relay_task._status`, `token_state`, and `reconcile_relay_task`. The last two are copy-pastes. `rtl.py:510, 582` and `relay_drive.py:402` parse it too. | One `tick_info(task) -> {status, claimer, handoff_to}` helper (see F3). | gh642, gh385, gh491, gh408 suites. | S | high |
| F7 | in-file dup | `marathon_drive.py:1584-1588, 1635-1641, 1872-1875` | The same origin-URL-to-`owner/repo` regex chain, with a `gh repo view` fallback, appears 3 times. `harness_paths.github_slug_from_origin` (`harness_paths.py:130`) already exists, and marathon_drive already imports `harness_paths`. Note that marathon's regex accepts any host, while `harness_paths` accepts only github.com. | Add `_repo_slug(repo)` = `github_slug_from_origin(repo) or gh repo view`. Confirm that the non-github-host behaviour is not relied on (**unverified**: no test found that uses a non-github remote with `--log-github`). | gh284, gh322, gh425 run-log suites. | S | high |
| F8 | in-file dup | `137` vs `1420`; `470` vs `1431`; `128` vs `1528`; `1160` | These pairs are the same helper written twice: `_result_cmd_out` and `_cmd_out`, `_utc_now_z` and `_utc_now`, `_derive_issue_number` and `lane_issue_number` (the docstring at 129 says so). The attempt-file timestamp at 1160 spawns `date -u` instead of calling `_utc_now_z()`. | Keep the module-scope versions and delete the closures. | None visible outside the file. | S | high |
| F9 | in-file dup | `190-198, 1128-1134, 1182-1189` | The `.tick/attempts/<lane>` file is counted in 3 places. Line 192 also works out the lane key inline with its own regex instead of using `_lane_key` (1113). | Add `_attempts_file(root, lane)` and `_attempt_count(path)` (and share them with relay_drive, per F3). | `test/lane-attempt-cap.sh`, `test/debug-mantra.sh`. | S | high |
| F10 | in-file dup | `207-216, 1775-1778, 2424-2432` | The relay file's `STATUS:` line is read 3 separate ways: receipt, interrupted record, and `file_status`. | Add `read_relay_status(path)` (and count rounds in the same pass for 1779). | gh388, gh290 receipt grid. | S | high |
| F11 | in-file dup | `2172-2175, 2215-2220, 3198-3204` | The same "`git add` / `diff --cached --quiet` / commit only if changed" sequence (GH-207) is written 3 times: escalation, transcript, render. | Add `_commit_if_changed(repo, path, msg) -> bool`. | gh207 paths inside `test/marathon-drive.sh`, `test/synthetic/gh131-marathon-target-root.sh`. | S | high |
| F12 | in-file dup | `1792-1796, 2136-2142, 3265-3270`; writer `relay_drive.py:128` | `.relay-scratch/last-turn-incident.json` is read twice with the same try/except. It is deleted before each drive. The writer is in another module, and no schema is shared between them. | Add `_read_turn_incident()` and share a constant path (or a helper in `rtl.py`). | gh371, gh372. | S | high |
| F13 | in-file dup | `2634-2636, 2645-2658, 2674-2676, 2687-2688, 2811-2813, 3459-3462, 3469-3472, 3499-3512` | About 11 exit paths repeat the same tail: `log`, `escalate`, `xyz_marathon_emit("red", …)`, `sys.exit(N)`. | Add `halt(reason, relay_exit, emit_text, code)`. | Every escalation test (gh407 attribution, marathon-drive.sh). | S | high |
| F14 | in-file dup | `276-289, 1465-1479` | The atomic write (`mkstemp` + `os.replace` + unlink on failure) is written twice: receipt and driver heartbeat. `rtl.py:788` and `relay_attest.py:164, 216` have more copies. | Add `atomic_write_json(path, obj, **dump_kw)`. `sort_keys` has to stay per caller, because the byte-compatible heartbeat depends on it. | gh284 heartbeat byte-compat, gh290. | S | high |
| F15 | dead distinction / correctness | `3338-3370`, caller `3456-3462` | `recover_already_satisfied_lane` returns 0, 3, or the raw `review_exit` (for example 4, 6 or 7 from the `--review-once` pass). The caller only checks `== 0`. Every other value is logged as `no-progress` and exits 3, so a containment violation (6) or timeout (7) during the recovery review is reported under the wrong reason. The only `--review-once` case in `test/marathon-drive.sh:508-550` is the approve path. | Send a non-3 return through the normal `relay_exit` dispatch. Add a test for the review-once exit-6 case. | Jog receipt `reason`; marathon.sh halt table. | S | high |
| F16 | dead code + test gap | `1863` | The `MOCK_GH_ISSUE_STATE` test hook appears nowhere else in the repo. The `issue-closed` preflight (exit 4, 1880-1890) has no marathon test. The only `issue-closed` test is `test/gh267-express-skill.sh:285`, which tests express.py's own check. | Add a marathon test that uses the hook, or remove the hook. | none | S | high |
| F17 | dead code | `3329`; `953`; `1535`; `2507`; `961, 973, 1293, 2108, 2205, 3318`; `2552` | These are unused or redundant: the `aroot` local in `artifacts_exist` is never used. The `root=` parameter of `_phase_memory_sample` is never read (3 callers pass it). The `repo=` parameter of `trunk_ref` is never passed; its only caller is 1665, even though the docstring names the branch guard, and the guard reimplements the lookup at 3106. `requires_test_delta` is a pure pass-through. There are redundant local `import`s (`re` twice, which is already imported at module level, plus `glob`, `datetime` and `atexit` twice). The `sys.path.insert` at 2552 repeats line 19. | Delete them, or inline where it helps readability. | none | S | high |
| F18 | performance/telemetry bug | `972-977` | The compressor figure uses `pages * 4096`. `vm_stat` on this host reports "page size of 16384 bytes", so on Apple Silicon `compressor_mb` is 4x too low. That value is logged and sent to `tick cost --compressor-mb`. | Parse the page size from the `vm_stat` header, or use `os.sysconf("SC_PAGE_SIZE")`. | `test/gh382-marathon-memory-telemetry.sh` does not pin the page size: it only checks for `compressor peak: [0-9]+MB`, so the fix needs a new assertion. Tick cost records. | S | high |
| F19 | performance/safety | `899-916, 2361-2362, 2399-2402` | `_gate_group_rss_mb` returns -1 on any `OSError`. `ps` raises `PermissionError` (an `OSError`) in this Claude Code sandbox, as I saw during this audit. At -1 the RSS cap never fires, nothing is logged, and `peak_rss_mb` stays at 0, so the final log line reports "peak group RSS 0MB". On macOS this is the only memory layer, per the comment at 859-862. | Log once when the RSS probe is unavailable, and report the peak as "unavailable". Optionally make the guard fail closed behind an env flag. | gh390, gh457. | S | high (code), unverified (whether real marathons run sandboxed) |
| F20 | performance | `2356-2372` | The gate poll runs `ps -axo pgid=,rss=` (the full process table) every `poll_s`, which defaults to 1s, for up to 1800s on the `full` tier. I could not measure the cost because `ps` is blocked in this sandbox (**unverified magnitude**). The fast poll is deliberate, to catch fast allocators. | Leave it alone unless measured. If needed, back off after the first 60s (for example 1s, then 2s, then 5s), still capped by RSS. | gh390, gh457. | S | medium |
| F21 | performance (network) | `1575-1577, 1592-1594, 1621-1623, 1685-1686, 1862-1878` | A green phase with `--log-github` runs `gh auth status` twice and fetches all issue comments twice: attestation, then run log. `_preflight_check_issue_closed` runs `gh issue view` (and possibly `gh repo view`) on every live and dry run where an issue number can be derived, whether or not `--log-github` is set. That is 1-2 network calls per phase. Whether `gh auth status` hits the network is **unverified**. | Resolve slug and auth once per run and cache them in the context. Pass the fetched comments from the attestation to the run log. | gh284, gh322, gh425. | S | medium |
| F22 | test gap | `1571-1616` | `marathon_emit_phase_qa_attestation` (GH-124 QW1) has no test: no test mentions `xyz-qa-receipt` or "Phase QA Attestation". Its body labels the reviewer line as `` `{reviewer}` ({builder}) `` (1607). | Add a mock-gh test (the gh284/gh322 pattern). | none | S | high |
| F23 | test gap | `3433-3447` | The timeout-recovery reasons `timeout-no-live-actor`, `timeout-builder-still-owned-turn` and `timeout-during-review-recovery` are not mentioned by any test. Only `timeout-no-artifact` is (test/marathon.sh, gh280). | Add stub-relay-drive exit-7 cases for each token state. | Jog receipt reasons. | S | high |
| F24 | test gap (refactor hazard) | `test/gh346-gateway-allowlists.sh:51,251,284,291,328`, `test/gh307-gate-env-scrub.sh:30-51`, `test/gh441-gate-env-contract.sh:32,88`, `test/gh376-relay-drive-lock-parity.sh:284`, `test/gh346-profile-resolve.sh:163`, `test/gh457-gate-tiers.sh:29`, `test/gh371-interrupt-snapshot.sh:9`, `test/gh372-escalation-log-tail.sh:9` | These suites read `marathon_drive.py` as source text. Some grep exact lines; gh346:291 uses a `sed` range that ends on `/^    )/`, which depends on 4-space indentation inside `main()`. gh371 and gh372 copy a fixed list of 5 `utils/py` files into a fake harness, so any new sibling module would be missing there (ImportError). | Before any split, point these tests at the symbols (import and inspect) or at a manifest, and update the fixture copy lists. | All the suites listed. | M | high |
| F25 | cross-repo dup | `relay-automation/marathon-drive.sh` (1,359 lines) | The frozen Bash twin (GH-308) is the whole driver again. It still runs under `XYZ_PYTHON=0`, and 24 test files use that setting. Known divergences are pinned in comments: pi, commandcode and deepseek routing (1957-1982), the timeout gate probe (3411-3418), and a phantom `gemini`. | Twin retirement as its own decision. It is not part of the split. | `test/gh308-frozen-twin-guard.sh`, 24 `XYZ_PYTHON=0` suites, CI (`.github/workflows/ci.yml:365`). | L | high |
| F26 | cross-repo dup | `marathon_drive.py:235-274`; `jog_run.py:128-155` | The `marathon-drive/result@1` receipt keys are written by hand here and checked against a separate hand-written required-key list in Jog. Nothing is shared. | Put a `RESULT_KEYS` constant and schema in a small shared module (or in `telemetry_schema.py`) that both import. | gh280, gh290, gh291 contract goldens. | S | high |
| F27 | structure | `329, 1293-1294, 1854-1855, 3318-3319, 3567-3572` | There are two exit-hook mechanisms. `_ON_EXIT` (receipt, interrupted record, run log, heartbeat stop, cost summary) runs in the `finally` of `__main__`. `atexit` (lock removal, XYZ heartbeat clear) runs afterwards. So the order depends on the mechanism, and `main()` called directly (as `test_python_layer.py` does) never runs `_ON_EXIT`. | Use one ordered hook registry owned by a runner function, and keep `atexit` only for the lock. | gh284, gh388, test_python_layer. | S | high |
| F28 | doc drift | `ARCHITECTURE/system-diagram.json` (edges) | The `marathon` node only has edges to `relay-drive` and `gate-stack`. The driver also calls `tick` directly (the seed, `log`, `info` and `cost` at 3242-3247, 2186, 1009), `github-api` (gh issue, pr and api at 172, 1592, 1878), `runtime-telemetry` (append-xyz-completion and write-xyz-heartbeat at 1296, 1314), and `marathon-closeout.sh` (2600). | Add the edges the next time the diagram is regenerated. Do not hand-edit it; ARCHITECTURE/README.md says so. | all four `system-diagram*` specs | S | high |
| F29 | cross-repo dup | `marathon_drive.py:1862-1890`; `swarm_preflight.py:647`, `_marathon_plan.py:472`, `express.py:524` | The closed-issue check is written 4 times. The marathon copy may be intentional defence in depth for direct invocations (**unverified intent**). | Share an `issue_state(repo, n)` helper. Keep the marathon call site. | preflight/plan suites | S | medium |
| F30 | structure (refactor hazard) | `2076` vs `3077` | `refuse_trunk_commit` defines a local `commit_root = args.target_root or root` that shadows the outer `commit_root = phase_commit_root(...)`, and the two mean different things (#131 vs GH-402). Once the closures are lifted into shared state, it is easy to swap one for the other. | Rename the inner one to `receiving_repo`. | gh402, gh131 synthetic. | S | high |

## Test coverage

- **Test files:** 89 files under `test/` reference `marathon_drive` or `marathon-drive.sh`. Every name checked appears in `validate.sh`'s suite list. I did not run the suite: the GH-177 hook blocks it in the sandbox, and this was a read-only audit.
- **Direct unit calls:** tests call only module-scope helpers directly: `xyz_debug_log_*`, `xyz_harvest_findings`, `run_tick_loud`, `phase_commit_root`, `write_terminal_result`/`_RESULT`, `resolve_force_relay_task`, `_phase_memory_sample`, `_probe_bin_or_file`, `preflight_write_set_trackable`, `runlog_find_comment_id`, and the constants in gh346, gh390 and gh457.
- **Closure behaviour:** everything inside `main()` is tested only through full driven runs with stubbed tick and relay-drive, mainly `test/marathon-drive.sh` (1,168 lines).
- **Gaps that block a safe refactor:**
  - F5: the unguarded baseline path.
  - F15: review-once exit codes other than 0 and 5.
  - F16: the issue-closed preflight.
  - F22: the QA attestation.
  - F23: three of the timeout reasons.
  - F24: the source-text and fixture-list tests.

## Proposed split

The approach: keep `utils/py/marathon_drive.py` as the entry point and the import surface, and add flat private siblings with an underscore prefix, following the existing `_marathon_plan.py` pattern. Line 19's `sys.path.insert` already makes siblings importable when the file is loaded via `importlib` from stdin (the gh322 constraint noted at 2252).

**Entry point**

- `marathon_drive.py` (about 350 lines)
  - `argparse`, `RunContext` construction, the top-level sequence, and the `__main__` signal/exit wrapper.
  - Re-exports every name tests use today (`_RESULT`, `write_terminal_result`, `run_tick_loud`, `phase_commit_root`, `xyz_debug_log_*`, `preflight_write_set_trackable`, `_probe_*`, `GATE_TIERS`, `gate_guard_cpu_attribution`, `_phase_memory_sample`, `SMALLCODE_DEFAULT_BIN`, `DEEPSEEK_DEFAULT_BIN`).
  - For now, keeps the literal `GATE_SCRUBBED_ENV` and `for _shim in (...)` tuple that gh307, gh346 and gh441 read, unless F24 is done first.

**Private sibling modules**

| Module | What moves there | Roughly from |
| --- | --- | --- |
| `_md_context.py` | `RunContext` dataclass, which replaces the list cells (F1, F27) | new |
| `_md_receipt.py` | `_EXIT_MEANINGS`, `_exit_meaning`, `_result_outcome`, `_RESULT`, `_result_arm`, `write_terminal_result`, the `RESULT_KEYS` shared with jog (F26), and the hook registry (F27) | 24–330 |
| `_md_debuglog.py` | Sentinel Tier 1 (`_json_esc`, `xyz_debug_log_*`, `xyz_harvest_findings`) | 364–468 |
| `_md_agents.py` | the one `AGENT_ROUTES` table, `route_agent`, `_probe_agent_bin`, `_probe_*`, the reviewer rule, the `*_AGENT` reset, and `*_TURN_ROOT` propagation (F2) | 722–818, 1942–2026, 3310–3312 |
| `_md_gate.py` | tiers and config, RSS/kill/CPU attribution, `run_pre_advance_gate(cmd, cwd, env, baseline)` with one verdict helper (F5, F19), the runnability preflight, and `_gate_env` | 820–950, 1857–1932, 2224–2418 |
| `_md_git.py` | `_cmd_out`, `_commit_if_changed` (F11), `_repo_slug` (F7), `_repo_rel_prefix`, `phase_commit_root`, `preflight_write_set_trackable`, `path_has_nonempty_phase_delta`, and the branch guard (F30) | 566–720, 2475–2505, 3065–3187 |
| `_md_tick.py` | `tick_info` (F6), `run_tick_loud`, `resolve_force_relay_task`, `reconcile_relay_task`, the seed sequence, and the lane attempts (F9); a candidate to move into `rtl.py` for F3 | 487–565, 1113–1177, 3209–3247 |
| `_md_telemetry.py` | driver heartbeat, XYZ heartbeat/emit, `_phase_memory_sample` (F18), and the cost summary | 953–1012, 1296–1335, 1434–1523, 1701–1732 |
| `_md_github.py` | run log, QA attestation, issue-closed preflight, `open_lane_pr`, with cached slug and auth (F21) | 1525–1700, 1862–1890, 2588–2621 |
| `_md_records.py` | relay template render, debug-mantra note, `escalate`, `save_transcript` (F4), the interrupted-phase record, and the turn-incident reader (F12) | 1179–1240, 1751–1852, 2089–2222, 2876–2972 |
| `_md_outcome.py` | `file_status`/`token_state`/`attested_terminal`, acceptance recheck, `complete_phase_success`, satisfied/retry checks, the two recovery paths, the `relay_exit` dispatch, and `halt()` (F13, F15) | 2424–2474, 2507–2870, 3258–3515 |

Every module reads the shared state through `RunContext`, so none of them needs anything bound inside `main()` (F1). Moving the code is a behaviour-preserving extraction that should land with no semantic diff. The fixes flagged in F2, F5, F15, F18 and F19 should land as their own commits before or after the move, never inside it.

## Suggested order for follow-up issues

1. **Safety net (M).**
   - Add the missing tests: F5, F15, F16, F22, F23.
   - Make the source-text and fixture-list suites robust to layout (F24).
   - Nothing moves until this is green.
2. **Small behaviour fixes (S each, separate PRs):**
   - F2 (jog `gemini` mirror)
   - F18 (vm_stat page size)
   - F19 (RSS probe unavailable)
   - F15 (misattributed recovery exit)
3. **Dedup inside the file, no behaviour change (S):**
   - F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F17, F30
   - Each is small enough for a relay-reviewed single phase.
4. **Introduce `RunContext` and extract the module-scope groups (M):**
   - `_md_receipt`, `_md_debuglog`, `_md_agents`, `_md_gate`
   - These are already mostly at module scope, so this is low risk.
5. **Extract the closure groups (L):**
   - telemetry and github first (all best-effort, and never change the exit code)
   - then records
   - then outcome, which is the most contract-bearing: exit codes and receipt reasons consumed by Jog and marathon.sh
6. **Share with relay_drive (M):** F3 (lock, attempts, tick info, cost summary into `rtl.py`), F26 (receipt schema), F21 caching, F29.
7. **Retire the Bash twin (L, separate decision under GH-308):** F25.
8. **Diagram refresh (S, any time):** F28, done through the swe-diagram skill.
