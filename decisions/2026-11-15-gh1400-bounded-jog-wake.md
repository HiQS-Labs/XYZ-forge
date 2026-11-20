# GH-1400: compose the existing Jog owner

Decision: an opt-in bounded wake on `jog run`, not a second scheduler, queue or ledger.
The existing primary lock/writers, execution history, preflight, Marathon and receipt publisher
remain owners. Native retries are explicit; unknown results hold. Ahead local development is
preserved under a ref before alignment; tracked dirt and collisions hold.

Bet: removing receipt/adoption and clone-handoff reconstruction produces an observable capability
without a new framework. Accept only the canonical plan's real CLI and refusal controls, independent
review and classified gate. Controlled evidence does not qualify unattended real-world throughput.

Reversibility: Costly at the orchestration boundary. Disable the opt-in flag/revert implementation
without deleting receipts, attempts, branches or logs. Revisit if a bounded authorized real trial
still needs those same manual interventions. Publication and cleanup clocks remain separate from
dispatch cutoff. No scheduler activation, live dispatch, merges or deployments are authorized here.

Owner/acceptance: `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md` implementation slice.
