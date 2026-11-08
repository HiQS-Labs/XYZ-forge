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
