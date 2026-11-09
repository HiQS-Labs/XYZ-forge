# Independent verification loops — medium-level exploration proposal

Forge already has relevant mechanisms. Extend their authority boundaries only after a
small supervised calibration succeeds; do not add another scheduler, ledger or broad
replacement testing platform. The historical GH-1284 calibration in this directory
stopped before candidate execution and supplies no semantic success evidence.

## Existing components and missing enforcement

| Existing seam | Verified role | Proposed extension |
|---|---|---|
| `skills/4-occasional/defect-campaign/SKILL.md` | Independent semantic oracle, controls, bounds and dispositions | Enforced immutable ownership of contract/fixtures |
| `skills/4-occasional/ate/SKILL.md`, `utils/py/gen4_campaign.py` | Variation, corpus feedback, candidate replay | Semantic acceptance separate from exit/digest matching |
| `utils/py/marathon_drive.py` | Attempt caps, acceptance rechecks, terminal result | Bind independent evidence to exact candidate/contract |
| `utils/py/jog_run.py`, `utils/py/relay_attest.py` | Reviewed-candidate attestation and landing checks | Reuse existing authority path for verification evidence |
| `MACHINE-CONTRACTS.md`, `TESTS-RESULTS/README.md` | Versioned receipts, single writer and retained provenance | Reference oracle/fixture/runner identities and replay artifacts |

Recon used clean local `25bfa30fc` source plus live GitHub policy/source checks;
publication base was `7c06ea30`. These are inspected implementation/policy claims,
not observed proof of end-to-end immutable verification. ATE's exit/digest replay and
optional healing handoff using `validate.sh --print-mode` do not establish semantics.

## Ownership and loop

An operator or independent specification owner approves intended behavior, forbidden
side effects, environments, tolerances and clean/failing controls before implementation.
Freeze that contract and fixtures by content identity. Actor feedback may expose
visible cases, but the actor cannot weaken their definitions. A disputed requirement
returns to the owner; changing it invalidates the old receipt and starts a new scope.

The actor edits permitted implementation files. An independent evaluator grades the
contract from runner-produced evidence. The trusted runner controls command execution,
permissions and receipt writing. Deterministic output, exit and state comparisons take
precedence; evaluator-agent judgment is reserved for genuinely qualitative criteria,
with explicit uncertainty and no authority to override deterministic failures.

Separate write permissions must protect contract, fixtures, runner and final-check
corpus from actor/candidate. Same-user path separation plus hashes only detects some
observed changes; it is not immutable enforcement. Hold autonomous claims if existing
execution controls cannot provide the needed boundary. No code change implementing
that boundary is included here.

Reuse the existing attempt/supervision path for visible-case repair, then independently
controlled final checks. Limit attempts, total elapsed time, command timeouts and total
spend including evaluator/final-check costs. Stop on repeated non-progress, budget,
identity/containment failure, invalid evidence, uncertain cleanup or disputed contract.
Keep behavioral failure, unavailable verification and exhausted budget distinct.

## Surface and verifier quality

For Forge begin with actual CLI argv, stdout/stderr, exit codes and filesystem/state
effects. Preserve useful unit/integration coverage. CI can also host independent
verifiers; independence is an ownership property, not a reason to delete test suites.

Validate the verifier with known-good and known-bad revisions before actor repair.
Later introduce individually approved source mutations in disposable copies and
require the same semantic predicate to detect them. A seeded-fault score measures
those selected faults only. Escaped defects should update the upstream contract and
relevant runtime coverage through review, not merely add instructions to an actor.

Retain exact candidate/base/contract/fixture/runner identities, sanitized environment,
ordered operations, outputs and before/after state. Seeds alone are insufficient for
stateful/concurrent replay. Publish committed provenance with exact source bindings;
reference existing receipts rather than create a second authoritative ledger. A
semantic pass does not authorize review approval, merge or promotion.

## Phased next steps and decisions

1. Review this inconclusive manual run and its setup boundary; expect no passing claim.
2. Separately approve any revised setup/helper and fresh calibration; expect fixed
   and broken revisions distinguished on actual CLI behavior, replay and state effects.
3. Evaluate existing permission/supervision enforcement; expect an honest supported or
   held result, not another runner built to rescue the experiment.
4. Separately approve a bounded actor/evaluator exercise with exact attempts, time,
   spend, write permissions and independent final cases; measure missed seeded defects,
   false alarms, reproducibility, repair cost and operator review effort.
5. Only then propose minimal driver/receipt changes and their rollback/qualification.

Operator decisions required: new calibration scope and exact commands; any source
mutation or actor/evaluator calls; immutable-permission changes; receipt/driver/gate
changes; each individual new CI case/assertion/parameter; any promotion-policy change.
GH-831 prohibits new gate machinery by default; GH-1131 forbids routine development
full-suite reruns. This proposal authorizes none of those actions, merge or deployment.
