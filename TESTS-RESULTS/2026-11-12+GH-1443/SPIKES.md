# Three bounded preparation spikes

## 1. Readiness parity — implement
Controlled jog_run_main with nonempty queue returns0 for failed preflight and invalid checkpoint options. baseline.json records unchanged fixture DB/no .tick state; readiness-controls.py is a manual replay, not a suite. Existing lint_probe separately rejects python3 -c as path -c, but dry-run never calls promotion lint. Share read-only owners; aggregate nonzero (including already-landed4: not ready for new work), retaining all item output.
Falsifier: failed readiness becomes nonzero; bare preview stays0. Checkpoint scope is static options/clone/origin/clean publication/development branch, not remote freshness or recovery.

## 2. Gate environment — defer installation/execution
LTVera-Pandas cde22b467 pyproject.toml requires Python>=3.11,<3.12 and pydantic2.13.4; buffer-server/requirements.txt pins pydantic2.10.4. One environment cannot satisfy both. Existing separate interpreter gates are legitimate; Jog/Marathon preserve caller variables. Arbitrary gate commands are not dependency manifests.
Decision: report environment/services unverified, do not execute gates twice or install/guess dependencies. User verifies chosen interpreter/services per1442/1014. Future falsifier: distinguish actual interpreter/import errors from product failure.

## 3. Reviewer route — implement static checks, defer capacity
Controlled entry point accepts missing reviewer and same codex/codex. Existing validate_marathon_executor rejects these and probes configured routes/binaries without provider requests, restoring imported state. Reuse only target-aware real Marathon readiness; retain bare preview/simulation. Executable presence cannot prove live credits/capacity. Report that unknown without silent paid probes or fallback.
Falsifier: invalid roles refuse before mutations/provider calls; valid roles reach per-item evaluation.

## Limits
Baseline stubs target/preflight seams: it proves orchestration behavior, not live preflight/provider success. Final evidence includes actual CLI and helper controls. No production change/gate/provider run during these three spikes. No new setup subsystem or schema.
