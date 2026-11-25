# GH-1594 target qualification smoke

Walked the candidate start-task instructions at `0064332dca9fc5b0a0c0b13dcba8d4feaa1913cf`
from verified repository identity through provisioning, final verification and the
push decision. The workflow is a skill document. We ran its commands in two fresh
full clones without dispatching another build or pushing from the consumer.

- **XYZ Forge** at `7d6a441906849e13970f8960b2280a1e6a0d4207`: the immediate
  check refused an unwired clone with exit 1. Installation and the subsequent
  check both exited 0.
- **XYZ Layout Engine** at `d47eb2530f3b37e867d591e277339137e04c6982`: vendored
  Forge from the same Forge base using `relay-automation/xyz-vendor.sh <consumer>
  --with-releases --no-register`. Verified the vendored relay and RELEASES CLI
  existed and the root installer was absent. The previous check reproduced
  exit 127. The consumer's `pnpm test` passed all four canaries and its PDDA
  check exited 0 in observe mode with zero errors and four warnings.
- **Consumer without a documented applicable gate:** walked the decision in the
  skill. It requires an operator gate decision before proceeding.

| Workflow checkpoint | Forge walkthrough | Vendored Layout Engine walkthrough |
|---|---|---|
| Opening checklist / target resolution | Canonical Forge, integration branch `development` | Canonical Layout Engine, integration branch `main` |
| Step 3 | Install and check the hook in the fresh clone | Follow host setup; absent root Forge installer is expected |
| Step 7 | Use the classified gate. For a full route, first push runs the full hook gate; a later push uses a prior full-gate receipt | Run the host tests and PDDA check |
| Step 9 | Check the hook before pushing; if it will run mutation-heavy suites, use a separate disposable full clone | Apply host push policy; target `main` |

For a Forge first push on the full route, the walkthrough reached final review
approval first. It then selected a disposable full clone at the approved SHA,
with canonical origin and the same attempt context. That clone checks its installed
hook before push, runs the full gate once, compares its before/after identity, and
targets `development` for the ready PR after a green gate. This PR is classified
docs-only, so the full-route example is a walkthrough.

Verified the Forge capture-to-pickup sequence with a scratch copy of the base
ledger: the capture existed with zero rows for #1594, rated pickup created one,
and repeated pickup preserved that row.

The existing vendored CI smoke qualifies harness behavior. The start-task regression
was in prose. The targeted smoke above is the acceptance check for that boundary.
