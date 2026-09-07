# Baseline preflight observations

Command: `bash validate.sh --throttle`, macOS disposable full clone at `2e4f8d48831b2265a29eeaca8ce93a61bc39e386`. These are selected captured observations, not a complete run transcript or passing gate receipt.

- Runner announced 333 pooled suites plus 16 in sequential driver-lock lane, 2 workers.
- agy-turn.sh, codex-turn.sh, relay-review-once.sh and relay-artifact-file.sh reported rc=0.
- gh370-progress-telemetry.sh reported rc=1. Its log contained `printf: write error: Broken pipe` at line 45 while the captured output contained `changed-files=1`. Source has a printf-to-grep-quiet pipeline; this supports an assertion failure, not a missing progress value. No fix attempted.
- gh399-packet-acceptance-continuation.sh and gh365-validate-telemetry.sh also reported parallel rc=1. Causes were not investigated in this planning task.
- Runner serial retries for all three printed `PASSES when run alone`. This does not erase the parallel failures or prove a complete run.
- Operator task checkpoint was plan plus Agy QA; after that finished, the broader baseline run was interrupted. It began recovery of a missing parallel result for marathon-root-audit.sh; the known run process group was terminated and the command exited 143. No complete gate result exists.
- Post-run process-group query returned no members. Identity bracket confirmed core.bare false, expected local source origin, absent local user.email, same HEAD, and clean status.

No deploy-skills runtime was built or tested. The two Agy plan-review results are independently retained in the committed relay and provenance file.
