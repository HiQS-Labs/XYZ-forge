# GH-1254 focused evidence

Agent-assisted; runtime candidate `2e6f50939d0278745d2e1ab8249ae9597ebe9c8b`. No live provider calls or spend.

- Pre-fix red control: cold work consumed immediately; receipt supervision and token fields absent.
- Candidate: 21 manual assertions pass, 21 existing Python tests pass; CLI init/tick/rerun smoke passes.
- Cache TTL and maximum withholding are persisted in config.json (the per-instance run configuration), and each snapshot records the observed cold state and last actual call. No call means no warmth update.
- Same-scenario modeled comparison: without deferral 3 calls / $0.03, with deferral 1 call / $0.01, both consume all 3 inputs. Stub assumes $0.01/call. This reflects deferred deterministic selection replacing model calls; it does NOT establish cache billing savings. Actual Codex billing remains unknown and cache-creation tokens null when unreported.
- One due note executes at slot 3. Two notes due at slot 3 leave the second explicitly unexecuted in the receipt; it runs at slot 4. No claim of unconditional deadlines.
- Declaration checks cover absent, false values, and positive declarations; restart_performed remains false. No restart was attempted.

## Open acceptance

Restart allowed/refused behavior and launchd restart/declaration consistency are unexercised: the factory CLI has no such mechanism. GH-1248's plan and 2026-10-29 report explicitly defer its watchdog. A bounded read-only search of current user LaunchAgents found no factory-primitive entry; this does not prove absence of all external supervision. Parent/GH-1248 scheduling work owns any required follow-up for GH-1358.

Unconditional execution by deadline under overload remains OPEN. A single-action tick cannot execute two independent notes at the same deadline. The existing rules evaluator now prioritizes due deferred inputs; a separate scheduler was not added. Budget, pause and tool failures retain their existing restrictions.

Final independent QA Approved at 7366edcd3; full applicable gate is pending parent host release. No #1356 completion claim.

## Integration checkpoint

Original candidate 522155356 passed full validate.sh 409/409, Python21/21, identity unchanged.
PR1324 landed while that gate ran; safely merged runtime 2bed0a59b and reconciliation 248ecec4d.
Only changelog conflict; retained both entries. Runtime overlap is packet validation, not cache/supervision.
Combined candidate 0cee95e21 passes repeated manual21, Python21 and inherited packet9 controls.
Normal combined-SHA push gate pending host availability; no reuse of a receipt for another SHA.

## Final publication

PR1369 published combined candidate `79c735156907e98be2572bf70f6585af5e33e8e1`.
Normal push full gate passed **409/409** (Python21/21); exact-SHA receipt and full log retained.
One failed invocation is also retained: caller-supplied XYZ_VALIDATE_MAX_JOBS=4 polluted
the mode-selection suite, producing 408/409. Removing that override with the verified
Python environment passed the existing suite 29/29 and the full gate. No source or gate
acceptance change. Initial diagnostic probes lacked the venv and are labeled separately.
Initializer repair1 and environment repair1 resolved; no inherited blocker counters reset.
Final evidence-only publication does not change runtime. Hosted checks are reported live
in the PR, not inferred from these local results. Parent outer review remains required.
