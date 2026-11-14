# GH-1465 verification receipts (2026-11-14)

Manual checks for #1465. No suite or registry entry was added (GH-831). Code under test:
`4d1596b5f` (fix, including shared `proc_group` RSS guard) vs `e0586fc30` (base,
`origin/development`). Paths in logs are redacted to `<clones>`, `<scratch>` and `<home>`.

| Check | Command / script | Result |
|---|---|---|
| **Red control** (real GH-955 builder and reviewer blocks from `TESTS-RESULTS/2026-11-11+GH-1428/`; scripted reviewer turn; gate is a script in the target repo that prints its cwd and exits as told, plus a self-limiting 250 MB allocator for the RSS guard) | `gh1465-red-control.sh <clone> e0586fc30 4d1596b5f gh955-builder.md gh955-reviewer.md` | Base: reviewer declares `gate run: yes — exit 0`, gate would exit 1, **attested rc 0** (the bug; nothing ran). Fix, same input: driver runs the gate, exit 1, **refused rc 4 `unverified-approval`**. Builder block with nothing unverified, gate exit 1: **refused `gate-failed`**. Gate exit 0 with no declaration: attested, record `gate_exit: 0` + `gate_cmd`, trailer `driver-gate: exit 0 — bash gate.sh 0`, `relay_attest.load` ok. Gate not runnable: exit 127, refused. Unarmed: attested as before, no gate fields. RSS cap (`MARATHON_GATE_RSS_MB=128`): 250 MB allocator killed at 261 MB, exit 108, **refused `unverified-approval`**. Escape hatch (`MARATHON_GATE_GUARD=0 MARATHON_GATE_RSS_MB=128`): same allocator completes exit 0, attested (`red-control.out`) |
| Where it runs | same run | The gate printed the target repo as its cwd and `RELAY_ROLE=scrubbed` (harness env removed by `gate_env`) |
| Residue | `fix-gate-green-leaves-file` row | A gate that leaves an untracked file in the target checkout does not fail the driver (rc 0, attested); the file stays, as it would after the pre-advance gate |
| Existing focused suites (disposable `-verify` full clone at `4d1596b5f` code, Python 3.14.7 + throwaway uv py3.12 venv for pytest suites) | `for s in gh390-gate-guard gh457-gate-tiers gh478-runaway-guard gh425-gate-provenance-pr gh610-claude-subscription gh505-relay-attest gh681-reviewer-probe-rules gh268-relay-cue-and-target-checks new-relay relay-pkg-freshness gh307-gate-env-scrub gh441-gate-env-contract debug-mantra; do bash test/$s.sh; done` plus `pytest -q test/test_python_layer.py` | all rc=0: `gh390-gate-guard` (23/0), `gh457-gate-tiers` (10/0), `gh478-runaway-guard` (43/0), `gh425-gate-provenance-pr` (23 tests OK), `gh610-claude-subscription` (12 tests OK + 4 pass), `gh505-relay-attest` (all pass), `gh681-reviewer-probe-rules` (all pass), `gh268-relay-cue-and-target-checks` (35/0), `new-relay` (17/0), `relay-pkg-freshness` (3/0), `gh307-gate-env-scrub` (12/0), `gh441-gate-env-contract` (18/0), `debug-mantra` (17/0), `test_python_layer.py` (21 passed) |

Not measured: the 900-second timeout path (exit 124); a live reviewer turn; a real host gate
(for example a DB-backed pytest file) run by the driver.

Scope note: the driver-run gate carries the 900-second wall-clock cap and the 8192 MB default
group-RSS guard (`MARATHON_GATE_RSS_MB`, disabled with `MARATHON_GATE_GUARD=0`). The `ulimit -t`
CPU cap stays on `marathon_drive.py`'s `run_pre_advance_gate`.

## Full gate (pre-push, disposable `-verify` full clone)

- Prior commit `4f3569a55` passed full `validate.sh` (`408 / 408`, Python layer `21 passed`, `621s`,
  `full-gate-py312.log`).
- Re-verification on `4d1596b5f`: pending full `validate.sh` run before push.
- A local run is self-reported and is not promotion qualification (AGENTS.md, GH-509).
