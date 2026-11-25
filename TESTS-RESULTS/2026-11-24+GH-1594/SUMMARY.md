# GH-1594 target qualification smoke

Walked the candidate start-task instructions at `dc7f6bce31bc657dfb346f63e6f2a6d302bfac68`
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

The existing vendored CI smoke qualifies harness behavior. The start-task regression
was in prose. The targeted smoke above is the acceptance check for that boundary.
