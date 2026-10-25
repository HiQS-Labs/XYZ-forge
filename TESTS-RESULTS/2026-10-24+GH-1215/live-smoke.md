# GH-1215 manual checks (no new test/ suites, GH-831)

Host: MacBook Pro 14", macOS (Darwin 24.6.0), Kimi Code CLI 2.3.1 at `~/.kimi-code/bin/kimi`,
logged in to the operator's kimi.ai account. Model `kimi-code/k3.1-pro`.

| # | Check | Command | Result |
|---|---|---|---|
| R1 | Actor mismatch defers | `RELAY_AGENT=codex RELAY_FILE=x.md KIMI_AGENT=kimi relay-automation/kimi-turn.sh` | exit 0, `actor codex is not the Kimi agent (kimi) — deferring` |
| R1 | Missing gate var refuses | same with `RELAY_AGENT=kimi`, no `KIMI_AGENT` | exit 2, `KIMI_AGENT required` |
| R1 | Binary rule | `kimi-turn.sh --print-bin`; `KIMI_BIN=/opt/x kimi-turn.sh --print-bin` | `~/.kimi-code/bin/kimi` (installer fallback, `kimi` not on this shell's PATH); `/opt/x` |
| R3 | Empty output fails the turn | driven `--review-once` turn with `KIMI_BIN=kimi-stub.sh` (meta events, non-JSON chatter, a blank assistant message, exit 0) | shim: `kimi exited 0 but produced NO model output … failing the turn`; driver exit 5, no attestation, claim released. `empty-output-smoke.log` |
| R4 | Detection | `find-harness.sh --check` / `--env` | `ok  kimi CLI  (Path A worker, Kimi Code)  (~/.kimi-code/bin/kimi)`; `RELAY_HAS_KIMI=1`, `KIMI_BIN` exported |
| R4 | Detection red control | `PATH=/usr/bin:/bin:/opt/homebrew/bin HOME=/nonexistent KIMI_BIN=/nope find-harness.sh --check` / `--env` | `--  kimi CLI … (not found)`; `RELAY_HAS_KIMI=0` |
| R5 | Profile routing | `XYZ_DEVICE_CONFIG_PATH=<tmp> resolve-profile.sh 'kimi k3.1 pro' --env` with `{"harness":"kimi","gateway":"self","model":"kimi-code/k3.1-pro"}` | exports `KIMI_AGENT`, `KIMI_MODEL`, `RELAY_AGENT_CMD=relay-automation/kimi-turn.sh`. `profile-env.log`. Its "CLI 'kimi' is NOT on PATH" comment is a false warning in a non-interactive shell (bare-PATH check; the shim's installer fallback resolves it). Pre-existing behaviour shared with deepseek/smallcode; not changed here |
| Red | Allowlist suite before the dispatcher arm | `bash test/gh346-gateway-allowlists.sh` at `a89b45d7` | 62 pass, 1 fail: `#3 dispatcher did NOT route 'kimi'`. `red-control.log` |
| Suites | Focused existing suites at `d2cc3845` (disposable verify clone) | see `suites.log` | gh346-gateway-allowlists 63/0, gh441-gate-env-contract 18/0, find-harness 50/0, relay-xyz-skill-guard 12/0, gh393-deepseek-readiness 9/0, gh396-find-harness-roots 42/0, marathon-drive 162/0, path-integrity 3/0, gh346-resolver-fallback 11/0 |
| R7 main path | Live one-turn review relay | `KIMI_AGENT=kimi ALLOW_PATHS="" relay-drive.sh --relay-file relay-system/2026-10-24/gh1215-kimi-first-relay.md --agent-cmd relay-automation/kimi-turn.sh --reviewer kimi --review-once` | exit 0 in 9m 35s; `kimi-turn: committed kimi turn (file-scoped, no push)`; `attested Approved by kimi — reviewed a6303b792827, 2247 bytes of review text`. Review block: four cited `[Pass]` findings and Kimi's own probe of `has_model_output()`. Commits `f1a5ff7f`, `03aae234`. `live-relay-drive.log` |
| R7 adjacent path | Re-fire the driver on the closed thread | same command again | exit 4, `STATUS Approved but no attestation from this driver run … (GH-505)`; no Kimi dispatch, no commit. `refire.log` |

Limits: the live turn's stream-json transcript was not kept. It was pointed at `.relay-scratch/`,
which `rtl_enforce` sweeps after every turn (GH-91); the default `KIMI_LOG` is durable. The relay
block and attestation are the record. One live turn only; no timeout or containment-violation
case was run live (both paths are `RelayTurnLib`'s, unchanged).
