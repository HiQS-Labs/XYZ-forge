# GH-496 PR 1 — Gate Provenance & Test Results Summary

Branch: `feat/gh496-selective-ci`
Target Commit: `7e2084d2`
Qualification Environment: Disposable full clone `~/marathon-clones/xyz-gh496-gate-pr1` (un-sandboxed, independent `.git`)
Gate: `./validate.sh` (368 parallel test suites + pytest layer + clone invariants)

## Gate Results Summary

| Suite / Check | Result | Detail |
|---|---|---|
| `test/gh496-telemetry-isolation.sh` | 10 / 10 PASS | Default out-of-tree path, env overrides, auto-seed, clean working tree, red control |
| `test/gh35-test-tiers.sh` | 71 / 71 PASS | Test tiers, registry drift, subsystem mappings |
| `test/ci-route.sh` | 63 / 63 PASS | Fast routing, telemetry subsystem mappings |
| `test/mktemp-trap-guard.sh` | 1 / 1 PASS | Static audit of 523 shell scripts; no unguarded mktemp patterns |
| `test/gh1-adoption-guard.sh` | 11 / 11 PASS | Fixture containment audit; zero unaudited suites |
| Full `./validate.sh` | **368 / 368 PASS** | All suites passed; 0 failed |
| `clone-identity-invariant` | PASS | `core.bare=false`, `origin` intact, `HEAD` unchanged |

## Telemetry Relocation Invariant Attestation

1. Live harness turn shims append invocation and evaluation records to `~/.xyz/projects/<project-key>/telemetry/harnesses.db`.
2. Git working tree status across harness turns remains 100% clean (`git status --porcelain` is empty).
3. In-repo curated registry files (`harnesses.db`, `harnesses.sql`, `HARNESS-MODELS-REGISTRY.generated.md`) remain byte-identical.
