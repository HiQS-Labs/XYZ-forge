# GH-496 PR 1 — Gate Provenance & Test Results Summary

Branch: `feat/gh496-selective-ci`
Target Commit: `8968bb2e` (re-qualified — see "Receipt attribution" below)
Qualification Environment: Disposable full clone `~/marathon-clones/xyz-gh496-gate-pr1` (un-sandboxed, independent `.git`)
Gate: `./validate.sh` (368 parallel test suites + pytest layer + clone invariants)

## Gate Results Summary

| Suite / Check | Result | Detail |
|---|---|---|
| `test/gh496-telemetry-isolation.sh` | 14 / 14 PASS | Out-of-tree path, env overrides, 10-worker concurrency, auto-seed, exact row query, clean tree, red control |
| `test/gh35-test-tiers.sh` | 71 / 71 PASS | Test tiers, registry drift, subsystem mappings |
| `test/ci-route.sh` | 63 / 63 PASS | Fast routing, telemetry subsystem mappings |
| `test/mktemp-trap-guard.sh` | 1 / 1 PASS | Static audit of 523 shell scripts; no unguarded mktemp patterns |
| `test/gh1-adoption-guard.sh` | 11 / 11 PASS | Fixture containment audit; zero unaudited suites |
| `validate.sh --subsystem telemetry` | 5 / 5 PASS | Telemetry subsystem suites + clone invariants |
| Full `./validate.sh` | **368 / 368 PASS** | All suites passed; 0 failed |
| `Codex Consult Review` | PASSED | Independent review completed; all blocker and should recommendations resolved |
| `clone-identity-invariant` | PASS | `core.bare=false`, `origin` intact, `HEAD` unchanged |
| Full `./validate.sh` at `8968bb2e` | **368 / 368 PASS** | Re-qualification run, `~/marathon-clones/xyz-gh496-merge`, log `full-gate-8968bb2e.log.gz` |

## Receipt attribution

The first receipts in `provenance.jsonl` name `7e2084d2` and `02f3190e`. The branch was
rewritten after those runs and neither object exists on it — the branch is
`ee4038f0 → fa98ab0f → 141f2ced → 8968bb2e`. Under the GH-425 rule those receipts do not
attribute to this head, so they are kept as history only and the qualifying receipt for
this PR is the `full-gate-requalification` row at `8968bb2e`.

One suite, `gh35-test-tiers.sh`, failed in the parallel lane and passed when re-run alone.
`validate.sh` classifies that as GH-528 driver-lock contention rather than a product
failure and counts it passed; the run's own warning names it and recommends adding it to
`DRIVER_LOCK_LANE`.

## Telemetry Relocation Invariant Attestation

1. Live harness turn shims append invocation and evaluation records to `~/.xyz/projects/<project-key>/telemetry/harnesses.db`.
2. Git working tree status across harness turns remains 100% clean (`git status --porcelain` is empty).
3. In-repo curated registry files (`harnesses.db`, `harnesses.sql`, `HARNESS-MODELS-REGISTRY.generated.md`) remain byte-identical.
