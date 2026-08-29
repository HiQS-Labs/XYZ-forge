# Phase 5 vendored default-path run (2026-08-29)

Post-flip evidence for the Phase 5 QA gate's vendored half: a consumer repo with the
harness under `.xyz/`, one queue item with full intake, driven from a foreign cwd with
`jog run --builder codex --reviewer agy` and **no `--executor` flag** — the default
executor dispatched the vendored marathon drive (`.../consumer/.xyz/relay-automation/
marathon-drive.sh`), stub builder landed the declared artifact, stub reviewer Approved,
gate green, receipt `approved` with `target_repo` = the consumer repo, row parked
awaiting-landing (no PR — canned gh), foreign cwd byte-clean.

- `driver.sh` — the deterministic driver (rebuilds the fixture from any checkout).
- `marathon-result.json` — the receipt (outcome approved, gate green).
- `state.json` — the consumer's execution ledger.

Root-half evidence: the GH-314 real run (PR #320, verified `jog land`) — see the plan
doc's Phase 5 row.
