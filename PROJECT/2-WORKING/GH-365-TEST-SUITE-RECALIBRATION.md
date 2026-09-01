---
gh_issue: 365
source: https://github.com/HiQS-Labs/XYZ-forge/issues/365
title: "GH-365: test-suite recalibration — finish tiering, prove parallel equivalence, and define smoke/promotion lanes"
status: In progress (2-WORKING — execution began 2026-09-01)
created: 2026-09-01
updated: 2026-09-01
owner: agent-b (orchestrator: GLM 5.3)
goal: Cut recoverable validation latency (runner-envelope drift, process-heavy governance, static-analysis duplication, long-tail suites) without weakening containment, timeout, or promotion coverage — correctness and falsifiability land before optimization.
doc_type: plan
effort: 4
complexity: 4
risk: 3
phases: 9
fix_probes:
  - bash test/gh365-runner-envelope.sh
  - bash test/gh365-driver-lane-registry.sh
  - bash test/gh365-validate-telemetry.sh
  - bash test/gh365-pdda-gov-scan.sh
  - bash test/gh365-shellcheck-parallel.sh
---

# GH-365 · Test-suite recalibration

## Status

| What was just completed | What's next |
|---|---|
| Steps 1–5 + 8 + 9-matrix landed and pushed (branch through 858e5e0d): envelope (22/0), telemetry (14/0), lane registry (5/0), PDDA single-scan (governance 72s→4.9s, byte-identical, 22/0), ShellCheck width (10/0), full-tree fail-closed sweep + registry drift guard (5/0, caught gh153 genuinely unregistered), route/width matrix + smoke-lane decision (not added, reasoning in-doc). | Step 7 (long-tail suites) in flight via delegate; step 6 width campaigns on a quiet host; real-push tier-1/2 latency receipts; final sequential qualifying ci-local run at the final commit; then the PR |

## Capture

Recalibrate the suite after GH-347 landed by measuring the new critical path, finishing the
fail-closed tier-routing contract, running the owed multi-width equivalence campaign, and deciding
whether an XYZ-specific functional smoke lane adds measured defect-detection value.

The work must keep four decisions distinct: fast feedback, integration drift detection,
self-reported local verification, and independent full sequential macOS promotion evidence.

## Plan of record — the issue's final execution plan (2026-09-01)

Supersedes Draft 1's tactics where they conflict ([final
comment](https://github.com/HiQS-Labs/XYZ-forge/issues/365#issuecomment-5498257579), which folds
in the [exploratory post-#347
profile](https://github.com/HiQS-Labs/XYZ-forge/issues/365#issuecomment-5498097911) and the [GLM
5.3 accuracy review](https://github.com/HiQS-Labs/XYZ-forge/issues/365#issuecomment-5498223090)).
Work stops at each step's `Expect` gate before proceeding.

**Bet:** most of the recoverable latency is concentrated in measurement-invalidating runner drift,
process-heavy governance, repeated/static analysis, and a small long tail of integration suites.

**Failure mode to prevent:** a faster green run that executed a different suite/assertion set,
skipped a contended assertion, dirtied or changed the identity of its clone, or could not retain
its evidence.

**Reversibility:** instrumentation and runner-envelope work are Easy. Routing, parallel
equivalence, or promotion-meaning changes are Costly (rollback = the current full sequential macOS
path). No parallel route gains qualifying status inside this plan unless its predeclared
equivalence gate passes.

| # | Step | Expect gate | Status |
| --- | --- | --- | --- |
| 1 | One shared scratch/identity envelope for `validate.sh` + `ci-local.sh` (single helper, not a copy); audit `XYZ_HARNESS_DB` overrides/bypasses; identity capture before/after via clone-identity machinery; witnessed red = intentional mutation invalidates the receipt | Clean-start qualifying run ends clean and writes its gate record; both runners exercise the same envelope contract | pending |
| 2 | Retained phase/suite/assertion/worker telemetry (monotonic JSONL: lane, worker, queue/start/end, RCs, output hash/bytes, pass/fail/skip + reasons); denominator verified (309 + 3 post-#367, not the stale 307 label); exploratory output in `temp/`, cited evidence committed with provenance | Aggregate work, critical path, semantic coverage, retries, and invalid runs reconstructable from retained data | pending |
| 3 | Close PR #367's counterexample: `gh346-gateway-allowlists.sh` real-driver probes contend in the pool, ~36s retrying, then SKIP routing assertions while exiting green — move to the serialized lane AND derive lane membership from an auditable driver-invocation registry recognizing Bash + direct-Python shapes; guard/red control for new real-driver callers | Sequential and parallel modes execute the same semantic assertions; a contention-skip cannot report equivalence or silently remain pooled | pending |
| 4 | PDDA governance cross-reference: replace per-line `printf`/`grep`/`sed` fan-out (2 passes × ~2,775 lines) with one in-process scan per file/run retaining extraction across passes; per-check timings; witnessed reds for missing/broken refs; characterize `pdda.sh run` vs `pdda-repo-contract.sh` vs `pdda-local-checks.sh` before any dedup; leave fast RELEASES reads alone | Materially lower PDDA time, unchanged findings, explicit decision on intentional duplication |
| 5 | ShellCheck census first (census result: exactly one local scan site — `ci-local.sh` — plus the hosted job; no suite executes shellcheck), then parallel independent files at the balanced 4-worker width; mutation-flip red on serial AND parallel shapes | Identical diagnostics/verdicts, no multiplied redundant sweep, measured wall-time improvement |
| 6 | Re-baseline from merge SHA `6fe36fbb` (not the exploratory parent `102b11b0`); widths sequential/2/default/4/burst incl. Python/npm lanes and a loaded-host campaign; model the ceiling `max(pool aggregate / width, serialized-lane aggregate)` + fixed overhead before labeling the ~132.7s gap recoverable; per-width mutation-flip red | Explained speedup curve, witnessed worker-dropout detection, no retry masking a reproducible failure |
| 7 | Long tail in descending critical-path order: `gh280` prebuilt immutable fixture seed + section-local copies; controlled clocks/fakes for poll/timeout-heavy suites (production timeouts unchanged); measure #367's per-turn Bash alias-resolution subprocess before caching | Lower aggregate + critical-path time, byte/semantic-equivalent verdicts, no timeout dilution |
| 8 | Fail-closed tier routing derived from canonical registries (GH-306 bidirectional guard pattern); unknown/renamed/deleted/empty-range/workflow/runner/containment/kernel changes escalate to Tier 3; real-push Tier 1/2 latency | Every governed change classified or demonstrably fails closed; reds for unknown/renamed/deleted/empty-range |
| 9 | Smoke lane only if failure history shows earlier real-defect detection than Tier 1/2; publish the route/width matrix (trigger, set, latency, CPU policy, skip/retry behavior, evidentiary meaning); qualifying run stays full sequential macOS | Operators can tell feedback / drift detection / self-verification / promotion evidence apart unambiguously |

### Definition of done

- [ ] Both runners share one tested scratch/identity envelope; a qualifying clean-start run ends clean and retains evidence.
- [ ] Committed receipts reconstruct fixed cost, governance, pool/lane/retry work, assertion/skip coverage, critical path, and validity.
- [ ] PR #367's contention-skip shape cannot report equivalence or silently remain in the pool.
- [ ] PDDA and ShellCheck changes preserve witnessed red behavior and have before/after component timings.
- [ ] Sequential/2/default/4/burst campaigns use identical commits, explicit denominators, semantic coverage matrices, and red controls.
- [ ] Heavy-suite improvements preserve production timeouts, containment, fixture isolation, and negative controls.
- [ ] Tier routing inherits canonical registry ownership and fails closed on ambiguity.
- [ ] The final route matrix preserves full sequential macOS promotion unless a separately reviewed later decision changes it.

### Non-goals

- Weakening timeout, containment, clean-tree, or macOS promotion contracts to meet a latency number.
- Treating a green suite RC as equivalence when assertions were skipped.
- Optimizing already-fast RELEASES DB queries without new evidence.
- Turning `harnesses.db` into the timing-receipt store (no merge resolver; #367 declared-vs-dispatched caveats).
- Expanding Phase 3/model-routing work from PR #367 inside this test recalibration.

## Acceptance summary

- Retain a post-GH-347 latency and runner-minute baseline.
- Classify every governed path or fail closed to Tier 3.
- Measure Tier 1/2 on real pushes.
- Prove or bound parallel equivalence with committed multi-width receipts.
- Add a smoke lane only if observed XYZ defects justify it and a witnessed red control falsifies it.
- Preserve full sequential macOS promotion evidence unless a later explicit decision changes it.

## Preflight Contract

```json
{
  "issue": 365,
  "target": "development",
  "gate": "bash ci-local.sh",
  "fix_probes": [
    "bash test/gh365-runner-envelope.sh",
    "bash test/gh365-driver-lane-registry.sh",
    "bash test/gh365-validate-telemetry.sh",
    "bash test/gh365-pdda-gov-scan.sh",
    "bash test/gh365-shellcheck-parallel.sh"
  ],
  "artifacts": [
    "validate.sh",
    "ci-local.sh",
    "test/lib/runner-envelope.sh",
    "utils/py/pdda_gov_scan.py",
    "test/gh365-runner-envelope.sh",
    "test/gh365-driver-lane-registry.sh",
    "test/gh365-validate-telemetry.sh",
    "test/gh365-pdda-gov-scan.sh",
    "test/gh365-shellcheck-parallel.sh"
  ]
}
```

## Acceptance

- [ ] Step 1 gate: clean-start `ci-local.sh` ends clean and successfully writes its gate record; both runners use the one envelope helper.
- [ ] Step 2 gate: telemetry receipts reconstruct aggregate work, critical path, semantic coverage, retries, and invalid runs; denominator verified 309 + 3.
- [ ] Step 3 gate: gh346 contention-skip cannot report equivalence; a newly registered real-driver caller cannot silently remain pooled (witnessed red).
- [ ] Step 4 gate: PDDA single-scan preserves findings (witnessed reds intact) with before/after component timings; explicit duplication decision recorded.
- [ ] Step 5 gate: ShellCheck serial and 4-worker shapes return identical verdicts; mutation-flip rejected by both.
- [ ] Step 6 gate: width campaigns from identical commits with explicit denominators and per-width mutation reds; speedup explained against the scheduling-ceiling model.
- [ ] Step 7 gate: heavy-suite optimizations preserve timeouts, containment, fixture isolation, negative controls.
- [ ] Step 8 gate: tier routing fails closed on unknown/renamed/deleted/empty-range; real-push Tier 1/2 latency recorded.
- [ ] Step 9 gate: route/width matrix published; full sequential macOS promotion preserved.
