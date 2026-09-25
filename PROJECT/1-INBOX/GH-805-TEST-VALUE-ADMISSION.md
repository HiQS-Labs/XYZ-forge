---
gh_issue: 805
source: https://github.com/HiQS-Labs/XYZ-forge/issues/805
title: "Audit test value and enforced test admission"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-09-25
updated: 2026-09-25
owner: operator
goal: "Determine necessary test coverage and evaluate a minimal enforceable admission pilot"
doc_type: feedback
effort: 3
complexity: 3
risk: 3
phases: 3
ratings_provisional: true
related: [802, 732, 774, 801, 365]
---

# GH-805 — Test value and admission

Local intake capture; the issue is the discussion surface. This is an audit proposal, not an approved implementation design. Ratings and the three broad stages (inventory, evidence, pilot decision) are provisional.

## Decision to make

**How many tests do we actually need, which ones earn their recurring cost, and should new coverage require machine-enforced admission?** Audit first; do not assume either that 417 registered shell suites are excessive or that every existing suite deserves to remain forever.

Operator concern: Markdown guidance alone does not reliably constrain agent-generated tests. Proposed direction is an admission oracle that records an approval before new tests can land and writes their catalog entries. This issue evaluates that direction and a minimal pilot; it does **not** authorize blanket test deletion or a new autonomous approval service.

Related: #802 (evidence review), #732 (gate cost and existing optimization work), #774 (selection gaps), #801 (focused tests missed a repository-wide ratchet), #365 (completed test-suite recalibration). This is a distinct test-value/admission audit, not a replacement for those efforts or the general Oracle initiative in #467.

## Ground truth and limits

Source snapshot: `development@c84dc61888f2c812597f9d9d7719e00ae2a2b339`, inspected 2026-09-25 UTC.

- `validate.sh` contains **417 unique quoted `.sh` entries in its `TESTS` array**. This is a suite-registration count, **not** a count of assertions, collected test cases, unique invariants, or every check executed by the gate.
- [`test/gh306-registry-bidirectional.sh`](https://github.com/HiQS-Labs/XYZ-forge/blob/c84dc61888f2c812597f9d9d7719e00ae2a2b339/test/gh306-registry-bidirectional.sh) already enforces existence/registration for a defined shell-file scope and explicitly documents blind spots, including nested and non-shell tests.
- [`utils/ci-route.sh`](https://github.com/HiQS-Labs/XYZ-forge/blob/c84dc61888f2c812597f9d9d7719e00ae2a2b339/utils/ci-route.sh), `test/gh35-test-tiers.sh`, and `test/gh365-tier-fail-closed.sh` already own routing and registry checks. Existence, registration, and routing do not establish marginal test value.
- Existing runner telemetry and #732's timing summary should supply cost evidence. No new full gate or test-removal experiment was run for this intake; present redundancy, savings, and oracle effectiveness are **unknown**.

Reproduce the narrow suite count from the pinned source:

```python
import re
from pathlib import Path
block = Path('validate.sh').read_text().split('TESTS=(')[1].split('\n)')[0]
names = re.findall(r'^\s*"([^"\n]+\.sh)"', block, re.M)
assert names and len(names) == len(set(names))
print(len(names))
```

## The hard questions

- Which tests protect distinct product behavior, contracts, safety boundaries, or historical failure classes? Which only check that a file, phrase, or implementation detail still exists?
- Which suites repeat expensive setup for assertions that belong in an existing parameterized suite? Which apparently duplicate tests are actually valuable independent checks, platform variants, or integration coverage?
- Which tests are not selected when their protected code changes, and which run far more often than their risk warrants?
- What is the marginal defect-detection value versus wall time, resource use, retries, maintenance churn, and review burden? “Never failed recently,” low line coverage, and filename similarity are not sufficient deletion criteria.
- Can an admission mechanism reduce net maintenance and gate cost, including its own cost, without rejecting useful regressions or rubber-stamping low-value tests?

## Proposed admission model to evaluate

Prefer extending the existing gate/registry and review receipt mechanisms over building a second runner, database, or model service. Recon must identify the actual callers and enforcement boundaries before implementation; a final implementation design is not asserted here.

**Decision outcomes:** reuse existing coverage, extend an existing test, add a new test, or approve no additional automated test with a risk-based explanation. Approve the coverage decision for a change set, not a separate ceremony for every assertion or function; every new test still must map to an approved decision.

**Decision record:** stable invariant/coverage ID; protected behavior and failure consequence; linked issue; existing coverage considered; selected outcome and reason; test entry points; red-control/evidence references; measured cost when available (otherwise explicitly unknown); routing; reviewer identity; reviewed revision or content digest; and exceptions. Keep case-level evidence where it belongs rather than copying every assertion into a large catalog.

**Authority split:** the builder proposes; an independent authorized reviewer evaluates necessity and overlap; the admission tool validates the decision and writes the canonical record/catalog projection. An LLM may recommend, but must not both invent a test and independently certify its necessity; `approved: true` in a builder-editable file is not trustworthy approval.

**Enforcement:** evaluate a deterministic check at the existing local gate plus a hosted merge-required check, with an approval source the candidate change cannot silently redefine. The pilot must define trusted verifier/reviewer identities, how evidence binds to relevant test/product changes, how changes invalidate approval, and how unavailable/malformed approval refuses admission; local hooks alone are bypassable.

**Catalog:** one authoritative metadata source and a generated/queryable view, reconciled with actual collection and runner selection. Start existing coverage as inventoried/unreviewed, not retroactively oracle-approved; phase enforcement for additions and meaningful modifications without blocking all legacy work on a wholesale backfill.

## Checklist — meaningful quick wins first

Severity describes the consequence of leaving a gap unresolved; these are investigation priorities, not claims that every gap is already proven.

1. [ ] **Define the units and decision rubric — Medium severity · Quick win.** Distinguish suite files, collected cases, assertions, and unique protected invariants, and publish the four admission outcomes above with concrete examples. Accept an evidence-backed “extend existing” or “no new test” decision so test creation does not become the default proof of productivity. Done when reviewers can apply the rubric to a small mixed sample and disagreements are recorded rather than hidden.

2. [ ] **Derive the current inventory from existing sources — Medium severity · Quick win for registration inventory; deeper coverage mapping is not.** List registered and unregistered entry points, language/framework, routing, exclusions, and available timing evidence, separating helpers/fixtures from executable tests. Identify scanner blind spots and missing data instead of treating an empty extraction as zero tests. Done when every count has a reproducible definition, nonempty source, and pinned revision; do not hand-maintain a second runner list.

3. [ ] **Measure test value on a bounded representative sample — High severity · Not a quick win.** Include expensive suites, churn-heavy guards, core safety tests, and ordinary product tests; map invariants and distinct negative controls, using existing timings and historical defects where available. Produce per-item decisions: keep, extend/consolidate, change execution frequency, retire, or investigate, with confidence and supporting evidence. Done when proposed savings have a matched baseline and each reduction names the protection retained or explicitly lost; report unknowns and use debug-mantra for failures.

4. [ ] **Prove one consolidation or retirement is safe before scaling — High severity · Conditional quick win after evidence.** Select one well-understood overlap and show the retained tests catch the relevant historical defect and distinguishing boundary cases under witnessed red controls in disposable full clones. Compare matched before/after runtime and detection, retaining logs and committed provenance; a unique critical failure missed by the candidate stops the experiment. If no safe reduction is demonstrated, report that outcome instead of manufacturing a deletion quota.

5. [ ] **Pilot admission and catalog generation in one subsystem — High severity · Costly shared-policy change; not a quick win.** Reuse the current review/gate path, initially reporting decisions in observe mode, then enforce only the pilot after testing rejection and acceptance behavior. Witness controls for missing/forged/self-issued approval, stale approval after relevant edits, tests added inside existing files, renamed/deleted tests, weakened assertions, malformed or empty discovery, and changes to the verifier itself. Done when legitimate regression coverage is admitted, unjustified/stale entries are refused, the catalog reconciles with execution, and approval latency/model/review cost is measured.

6. [ ] **Publish the count recommendation and a go/no-go on broader enforcement — High severity · Not a quick win.** Report baseline and proposed counts by suite/case/invariant where measurable, runtime and maintenance effects, residual blind spots, and the admission mechanism's own false-accept/reject evidence. Recommend keep/consolidate/retire decisions with traceable rationale rather than “cut X%,” and retain independent critical-safety coverage even if it rarely fails. Expand only if the pilot demonstrates net value; otherwise keep the useful inventory and decline the new approval machinery.

## Safety, rollback, and non-goals

- Audit/catalog exploration is Easy to reverse; test removal, selection changes, and mandatory admission are **Costly** because they affect every builder, reviewer, and merge path. Pilot rollback restores the prior tests/routing and returns only the new admission layer to observe mode; existing containment and verification controls remain enforced.
- Preserve the required local macOS gate and exact-SHA hosted attestation. All mutation-heavy verification runs in disposable full clones with pre/post identity checks; no production clone experiments.
- No arbitrary test-count cap, automatic bulk deletion, line-coverage-only ranking, or reduction in containment to achieve a faster green gate. Quarantine, if proposed, must remain observable with owner/issue/expiry rather than silently disabling coverage.
- No new heavyweight service, database, model training, or parallel registry without a demonstrated need. Catalog formatting and admission policy must not cost more recurring work than they remove.
- “All new tests approved” means **admission before landing**, not preventing an agent from drafting or running an experimental test. Final approval authority and tamper resistance must be resolved before calling the system enforceable.

— GPT 6 Astra Light
