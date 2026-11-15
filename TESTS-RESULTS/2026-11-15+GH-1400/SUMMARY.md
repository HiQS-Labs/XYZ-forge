# GH-1400 bounded Jog supervision — focused evidence

Implementation manual candidate: `97aa938be8472214abeca429fbac45a43f64621c`.
Independent plan QA Approved round 1/3. Final QA and classified full gate pending.

- Main controlled real CLI: 12/12 mandatory checks, repeated after latest-result hardening.
  A starts from a synthetic interrupted durable result, is published/projected without another
  builder, and B executes once. Adjacent repeat retains both attempts and execution histories.
- Readiness refusal, missing/mismatched result, malformed history, expired deadline, stopped
  owner, tracked dirt, timeout/restart and unique branch/log preservation all pass.
- Four adjacent controls include original-source rejection (cold recovery leaves approved A
  unpublished), SIGTERM worker removal plus no-rebuild restart, unknown-owner refusal, and
  aggregation missing/duplicate/failed/empty rejection with a passing clean control.
- Three final controls reject missing/invalid latest gate retry and foreign result target;
  older approved evidence does not authorize rebuilding or silently substitute for uncertainty.
- Existing Jog–Marathon integration: 227/227 baseline and implementation. Codex shim: 43/43.
  The full gate remains separate, as do actual provider capacity and real product acceptance.

The manual commands run from the disposable full helper only. Synthetic fixture Git repositories
and SQLite state live under its ignored temp directory. Initial crash state is deliberately seeded;
this is not an actual supervisor-kill qualification. Cancellation uses a real process and signal.
Worker/approval/gate/PR results are controlled, not independent product review or real gate proof.
The existing integration suite exercises the actual Marathon chain with deterministic agents.
No live models, connected services, LTVera dispatch, server writes or schedule activation occurred.

The helper retained its exact HEAD per run, canonical origin, core.bare=false and local identity;
tracked working tree remained clean. All fixture artifacts remain locally for audit. Committed
records retain scripts, command outputs, selected IDs and results; no new suite or registry.

Attempt1 passed its declared 12 checks, but source audit then found the latest-gate-retry fallback
and missing repeated-wake held reporting. Candidate97aa938 fixes those within the approved scope;
attempt2 repeats the 12 controls and latest adds 3. No failure was relabeled PASS.
One implementation hardening round; no exhausted blocker budget. Initial relay setup refused
because this fresh clone had no tick log; explicit tick init then the same review succeeded.
Independent review is actual relay output, never these manual scripts.

Limits: no native context continuity, external-effect exactly-once, power-loss/correlated-state-loss,
PID-reuse or cold-lock-reclaim race qualification. Dispatch cutoff bounds preflight/worker groups;
existing publication/cleanup clocks are separate. A child escaping the group/owner remains outside
this demonstrated containment. No throughput or zero-cost claim. NO_ENTRY: observations are bounded
controlled evidence rather than a general operational lesson.

## Review correction evidence

Final QA round1 requested changes (S1 explicit resume fallback; S2 retry intent saved after dispatch). Both are fixed in d1b372874. The author also found detached unique work losing its named/current reference: `detached-before/result.json` deliberately remains false (the reporting script itself exits zero; that is not a green control). Alignment now holds before changing detached HEAD.

`review-fixes/results.json` contains all eight required unique passing checks: detached hold; direct resume missing, invalid and mismatched retry holds; valid original and latest-retry publication; retry intent visible before a real local process-group kill followed by direct resume and supervised wake; completed retry publication. Synthetic worker/results remain provider-free. The killed process is a fixture worker, not a live provider or a power-loss guarantee. Replay from the full verify clone by copying retained check.py and review-fixes.py into temp/gh1400-manual and running the latter with an unused output directory (its output name is explicit in the script). Original failures and first review remain retained. Final independent approval and full gate remain pending.

Existing Jog integration rerun after corrections: 227 pass, 0 fail at d1b372874; see jog-review-fixes.log.
