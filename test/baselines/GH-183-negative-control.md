# GH-183 negative control (pre-fix, recorded 2026-08-23)

Soak evidence: #177 §3.4 (probe D5). CLI explore mode hardcoded `base_env={}`,
so the env family generated exactly ONE vector (the conflicting-identity
variant), which every shim cleanly deferred at exit 0:

    total_probes: 1, anomalies: 0, env_keys: [[RELAY_AGENT, AGY_AGENT, CLAUDE_AGENT]]

Missing-env testing was impossible by construction. Compounding:
`execute_with_process_limits` built on `os.environ.copy()`, so ambient `RELAY_*`
silently satisfied "missing key" mutations (machine-dependent results).

Post-fix expectation: mutations derive from a declared `--base-env` base and
execute over a CLEAN environment; ambient runner vars provably cannot satisfy
them. Verified by test/gh183-explorer-env-soundness.sh (ambient sentinel).
