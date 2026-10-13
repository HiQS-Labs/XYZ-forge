---
name: swe
description: Govern software planning, implementation, and code review with surgical changes that balance safety, security, maintainability, and performance. Apply when designing features, editing code, reviewing diffs or build plans, or assessing whether a new subsystem, dependency, test, or CI gate earns its maintenance cost. Scale evidence and ceremony to the change; this is an engineering rubric, not a replacement execution pipeline.
---

# SWE

Deliver the required behavior with the smallest sound change. Minimize total complexity to understand, operate, verify, and maintain, not raw line count. Meet safety and security requirements; balance maintainability and performance against the actual workload. Reuse existing mechanisms when their contracts fit. Every addition must earn its continuing cost.

## Scope and working mode

Use the same standards in three modes:

- **Planning:** establish the current behavior, choose the smallest adequate design, and define observable acceptance before implementation.
- **Implementation:** extend the existing owner and conventions, keep the diff focused, and verify the final behavior. Revisit assumptions when evidence changes.
- **Review:** assess the actual plan or diff and its evidence. Report concrete failures, unjustified complexity, and missing verification; do not manufacture findings or rewrite unrelated code.

This skill does not authorize deployments, issue creation, external messages, new infrastructure, or unrelated cleanup. Follow the project's instruction, permission, documentation, and verification contracts. A stricter repository prohibition on tests or gate machinery takes precedence over the general test policy below.

For a small, reversible change, a short rationale and focused verification are enough. Do not require a new plan, issue, dashboard, phase structure, metric, or checklist unless the task or repository requires it. Scale up for shared contracts, security boundaries, persistent state, concurrency, migrations, and difficult rollback.

## Four axes

| Axis | Decision to establish | Relevant evidence |
| --- | --- | --- |
| Safety | Can ordinary failures, retries, concurrency, or operator mistakes lose data, corrupt state, or cause unintended effects? Can we recover? | Failure paths, invariants, bounded retries, idempotency where needed, rollback |
| Security | Can untrusted input or actors cross a trust boundary, gain authority, expose secrets, or misuse access? | Entry points, authorization and validation at the boundary, least privilege, dependency exposure |
| Maintainability | Does this reduce or contain the number of concepts, owners, write paths, dependencies, and special cases? | Existing mechanisms examined, clear ownership, readable contracts, focused diff |
| Performance | Does this meet the relevant latency, throughput, memory, I/O, or cost constraint at representative scale? | Workload and budget, baseline where relevant, comparable measurements, uncertainty |

These axes are not an arithmetic score. A maintainability win cannot average away an unacceptable security or safety risk. Among acceptable options, prefer the simplest design that meets the performance need. Accept extra mechanism for a material, evidenced benefit; do not optimize on speculation or assume a shorter diff is safer.

For consequential tradeoffs, record the requirement, options considered, selected approach, cost accepted, and evidence that would change the decision. Routine edits need no four-part essay.

## Pillar 0: Recon — ground the change

Current-state evidence establishes what exists today. The Blast section extends that map with the proposed change’s new systems, data, consumers, and failure paths; copying the current radius unchanged is insufficient. For greenfield work, assess the available requirements and boundaries instead of inventing existing-system recon.

### Surgical change and reuse

Before proposing a new mechanism, identify the current owner, entry point, relevant callers and consumers, state reads and writes, and failure paths. Cite the source supporting material claims; name unresolved unknowns. Trace only as far as the risk requires. Quoting a changed file does not establish its callers or downstream contracts.

Choose the smallest adequate option: no change or configuration, reuse an existing path, extend that path, or introduce a new mechanism with a concrete reason. Prefer existing platform, standard-library, and installed capabilities when they meet the requirements safely.

- Do not create a parallel implementation, registry, writer, wrapper, queue, policy engine, or source of truth merely because a local implementation is easier to write.
- Do not force reuse across incompatible responsibilities or security boundaries. Explain the mismatch and keep any necessary separation explicit.
- Do not extract a framework for a hypothetical future use. Abstraction must simplify present responsibilities; a use-count or line-count threshold alone is not justification.
- Keep unrelated refactors out of the diff. Removing obsolete code is useful when its consumers and replacement are verified; fewer lines alone are not evidence of correctness.
- Temporary duplication for migration needs a canonical owner, synchronization strategy, retirement condition, and bounded lifetime.

## Verification without suite proliferation

Verification is required; adding tests is not the default. Test count and coverage percentage are not success criteria by themselves. CI maintenance is part of the product's engineering cost.

Start with existing evidence and the smallest relevant existing check. Reuse or adjust existing coverage when its contract changes and project policy permits. A focused, reproducible manual check can be sufficient for a bounded change when policy permits; record its command or procedure, revision, outcome, and limitations in the existing evidence location.

Before adding a test, establish all of the following, briefly:

- The specific consequential failure it would catch and why recurrence is plausible.
- The existing coverage examined and the actual gap; do not infer a gap merely because there is no test named after this change.
- Why extending an existing check or recording a focused manual check is inadequate.
- How the assertion checks observable behavior rather than mirroring implementation details, mocks, names, or incidental formatting.
- The expected runtime, fixtures, dependencies, flakiness exposure, and ongoing maintenance responsibility.

Then separately justify CI placement: why must it run at that frequency, on that change set, and as a blocking gate? A useful test does not automatically need every-commit execution or a new suite, runner, lane, or telemetry service. A benchmark must meet this same bar; renaming a test does not bypass it.

Do not add a customary batch of tests per feature, regression, or review comment. Do not add tests that enforce this policy. Do not multiply scenarios unless each protects a distinct material contract. Preserve necessary security and data-integrity coverage; restraint is not permission to leave consequential behavior unverified.

Demonstrate that the chosen check can detect its target failure where practical, using the pre-fix behavior or a safe controlled mutation in isolation. Never damage shared state to obtain a red control. If sensitivity or coverage remains unverified, report that limit. Verify nonempty inputs before trusting an extraction-based assertion.

Do not silently disable or delete existing tests to make a change pass. Follow the repository's retirement policy and identify the obsolete contract, duplicate coverage, or other evidence supporting removal.

## Performance evidence without a new subsystem

Capture a baseline before changing behavior likely to affect a material performance constraint: hot paths, data volume, algorithms, queries, I/O, concurrency, startup, or resource use. Reuse existing representative workloads and measurement tools. A prose correction or equivalent rename does not earn a benchmark.

If the baseline was missed, measure a verified base revision in an isolated environment when practical; never invent a before measurement. For a new feature, define the expected workload and acceptable budget, and label the first measurement as its initial baseline rather than claiming an improvement.

Distinguish what is measured:

- **Pipeline performance:** existing CI job or step durations measure developer feedback time and execution cost. Setup, downloads, caches, retries, parallelism, and changes in test selection can alter these independently of product performance.
- **Product performance:** representative operations measured inside CI can reveal regressions. Whole-suite duration alone does not establish application latency, throughput, or resource efficiency.

For a comparison, keep workload, runtime, runner class and architecture, dependencies, cache policy, and concurrency comparable. Prefer paired base/candidate measurements on the same runner allocation when feasible; control ordering and warmup effects and isolate state between runs. Use repetitions proportionate to cost and noise, report a central value and spread, and retain raw evidence. A small noisy sample is inconclusive, not a pass or a claimed improvement.

Start new measurements as advisory observations unless the project already has an established performance gate or explicit requirement. Introduce a blocking threshold only for a meaningful budget or repeatable regression, with demonstrated measurement stability, material absolute and relative deltas, and an owner. Do not choose a universal percentage threshold or automatically refresh a baseline to hide regression. Follow repository limits on new gates.

Record a brief result in the existing task's PDDA document or equivalent and link its durable evidence: base and candidate revisions, command and workload, environment, samples, summary and variability, and interpretation. Respect repository provenance and artifact-retention requirements. If an existing issue tracks the work, link the same evidence there when issue updates are authorized; do not duplicate raw results across documents.

A new performance issue is warranted for actionable work or when repository intake requires it, not for every measurement. Do not add a benchmark suite, dashboard, scheduled workflow, or tracking subsystem without a concrete need that existing tools cannot satisfy. An explicitly requested measurement skill should minimize its mechanism and reuse this governance rather than duplicate it.

Measurement references, when needed: [GitHub runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) and [pyperf guidance on reproducible measurements](https://pyperf.readthedocs.io/en/latest/run_benchmark.html). These explain environment and sampling limits; they do not require installing pyperf or changing the host.

## Blast — failure, state, and rollback

Make failures discoverable through the existing error and observability path. Add a log, metric, or alert only when it enables a concrete diagnosis or action. Do not mandate a new logging system or correlation ID for every edit.

Bound retry and repair loops; establish their stop or escalation condition. Investigate intermittent failures as evidence rather than retrying them away. Reproduce, trace, falsify the hypothesis, and cross-check the evidence; use the project's debugging workflow where required.

For consequential changes, name the blast radius and reversibility: **Easy / Costly / One-way door**. Costly changes need a rollback path. For Costly and One-way changes, name the stop/rollback signal and the last safe intervention point. Where rollback is impossible, identify the pre-action checkpoint and require explicit authorization before proceeding. A shield, adapter, or dual-write path must itself earn its complexity.

Keep mutation ownership coherent; multiple legitimate callers may share a mutation path. Where multiple writers are necessary, state how consistency and conflicts are handled. Use explicit state models when transitions and invariants require them, not at an arbitrary state count. Use append-only history when audit or recovery requirements justify it. Background jobs should tolerate the retries and interruption their execution model permits. Store instants unambiguously; retain timezone semantics for local calendar rules.

For online schema or persistent-state migrations across mixed versions, establish compatibility, bounded backfill, concurrent-update ordering, convergence evidence, read cutover, and rollback before retirement. Use the simplest synchronization method that preserves those contracts; bidirectional synchronization and fallback reads are not universal requirements. If used, fallback must not silently return stale or unsafe data. Retire legacy storage only after old readers, writers, queued/delayed consumers, and the rollback window are accounted for. A safe offline migration need not inherit a rolling-deployment protocol.

## Planning and reporting

Follow the repository's document format and lifecycle. For substantial work without an established format, use a short status, intended outcome, current-state evidence, one ordered implementation sequence with acceptance checks, material tradeoffs, and verification/rollback provisions. Add phases and navigation only when their size warrants it. Every step must serve an acceptance criterion; every criterion needs a delivery and verification path. Backend work must reach its intended consumer.

Separate predicted effects from observed results. A plan is not verification, a green check without executed evidence is not proof, and the author asserting completion is not independent review. Follow applicable independent-review requirements; do not create a new review pipeline for a trivial edit.

In implementation reports, state the behavior changed, why it is the smallest sound approach, what ran and its result, and material limits. Mention omitted new tests or benchmarks only when that decision matters.

In reviews, lead with **Ship / Ship with conditions / Block**, scoped to the evidence and review authority. Give concrete findings by severity with location, consequence, and cheapest sound correction. Distinguish required fixes from optional preferences. Do not claim all four axes are proven when one was not examined; explain relevant unknowns without inventing work.
