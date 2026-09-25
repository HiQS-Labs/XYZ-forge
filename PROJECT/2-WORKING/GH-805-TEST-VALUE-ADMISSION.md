---
gh_issue: 805
source: https://github.com/HiQS-Labs/XYZ-forge/issues/805
title: "Audit test value and enforced test admission"
status: "In progress — enforced gateway"
created: 2026-09-25
updated: 2026-09-25
owner: operator
goal: "Determine necessary test coverage and evaluate a minimal enforceable admission pilot"
doc_type: plan
effort: 3
complexity: 3
risk: 3
phases: 3
ratings_provisional: false
related: [802, 732, 774, 801, 365]
---

# GH-805 — Test value and admission

## Status

| What was just completed | What's next |
|---|---|
| Bounded repairs verified; completion audit corrected the overclaim | Implement operator-approved admission gateway on PR #811 |

## Table of contents

- [Recon and ratings](#recon-and-ratings)
- [Execution checklist](#execution-checklist)
- [Verification and handoff](#verification-and-handoff)
- [Decision to make](#decision-to-make)

## Recon and ratings

Execution base: `0ae3452a5774c6e72b633dd61648137e80516e6b`; branch `feat/gh805-test-value-admission`, one PR targeting development. This plan supersedes the original six-step intake checklist and implements the seven-step [review checklist](https://github.com/HiQS-Labs/XYZ-forge/issues/805#issuecomment-5825833432). GH-808/gh251 is GLM-owned and excluded; consume its results only if landed. GH-774 shares the routing seam; this PR repairs confirmed gaps, without claiming all its wider suggestions complete.

The bet: existing inventory and route owners can support useful coverage repair and an observe-only pilot without a second registry or approval service. Mandatory approval is a separate decision: same-account model signatures and builder-editable metadata are not authenticated approval. If independent reviewer identity and trusted verifier execution remain unavailable, this work ends with a documented no-go for enforcement, not simulated trust.

Ratings read back from RELEASES: GH-805 **85/75/50/35**, GH-774 **85/80/50/65** (priority/severity/appeal/cheapness). GH-805 has broad confidence and maintenance consequences but no observed new corruption; GH-774 risks missed product regressions on focused gates and has a narrower repair. Appeal is neutral, no operator rank override. Recurrence window 2026-09-11–25 versus 2026-08-28–09-10: #774 and #801 are concrete coverage-selection/ratchet examples; they do not establish one root cause or a measured rising rate. Complete incident counts and trend are unknown.

Entry points and affected consumers:

- `validate.sh:TESTS` → shell runners; `utils/ci-route.sh` → focused subsets. `gate_inventory.py:registered_gates/inventory` already generates shell metadata; `gh419-gate-inventory.sh` and `litmus-release.sh` consume its current JSON contract. Preserve that default contract; new audit/decision output is opt-in. Parse literal entries without shell evaluation, reject empty/duplicate registration, distinguish comments.
- `gh436-merge-cleanup.sh` → `gh436-merge-cleanup.py` → three gh534 modules: covered indirectly, do not add again. Four synthetic shell suites use registered wrappers; test/lib files and gh306 exemptions explain other shell exclusions. Inventory traces edges and labels unknowns rather than claiming filename discovery is complete coverage.
- Both `validate.sh` and `ci-local.sh` explicitly run `test/test_python_layer.py`; neither collects `test/flightdeck/`. `package.json:test:unit` owns the four Node unit files, with no full-gate caller. Reuse these existing test commands in both full runners, preserving telemetry/error aggregation. Flightdeck uses ephemeral loopback only; Node unit eligibility is established by focused runs on the supported host. Browser `.mjs` tests are outside this registration change.
- `utils/ci-route.sh:SUBSYSTEM_TESTS_releases` omits existing full-gate suites. Limit repair to the confirmed four (`jog-queue`, `gh75-dashboard`, `gh605-board-policy`, `gh605-work-state`) plus other #774 named direct importers only after source confirmation. Extend existing gh35/gh365 route checks; do not make a second execution list.
- `gh269-roadmap-retired.sh` documents planner status 0/4 but rejects only 3. Repair the accepted-set predicate and demonstrate rejection of another error. Its DB sync scenario remains distinct from the gh567 dashboard scanner and gh568 CLI/AST checks.
- `gh165-governance-canonical-paths-guard.sh` has four static guards and broad quote/comment filtering. Witness planted prohibited writes and missing-input controls; repair only demonstrated blind spots, state remaining syntactic limits. No general AST/linter framework.
- GH177 sandbox hook is live in `.claude/settings.json`; CHANGELOG documents historical 8/22-case matrices, but no current registered regression. Recover representative block/allow/wrapper cases by sending JSON to the hook, never executing dangerous example commands. One small registered hook suite is justified; extend existing suites for all other new controls.
- gh567 repeats filesystem discovery in its writer audit. Experiment with one discovered file list reused by policy-specific searches; retain gh269/567/568 registrations and their distinct controls. If matched evidence does not justify the change, retain the original implementation.
- Existing telemetry/provenance under TESTS-RESULTS is the evidence writer; historical GH591 duration is 4809.278s with gh251 1044.435s, not a current baseline. Index existing parallel records by revision/width/host/result, leave unavailable dimensions unknown.

## Gateway continuation — operator-approved admission

User now explicitly requests finishing the gateway, reporting more than 100 added tests at roughly four per day without notification. That rate is operator-reported, not independently measured here. The operator selected **human approval of every coverage decision initially**. Existing PR author and local API identity are both `noelsaw1` (ID 56978803): same-account model signatures cannot constitute independent approval.

### Recon and decision

`gate_inventory.py` owns existing inventory/advisory validation; extend that CLI with a small admission module, not a second registry. `githooks/pre-push` already resolves push ranges and routes expensive validation; admission checks should run first against the integration merge-base, not merely the last push. `validate.sh`/`ci-local.sh` remain execution authorities. `gh419-gate-inventory.sh` is the existing test owner for inventory/metadata behavior.

GitHub repo policy currently has no protection on development; Actions token defaults read-only and `can_approve_pull_request_reviews=false`. The organization is on Free, so an organization-required-workflow design is not available. Required status checks alone do not pin a workflow and are not the approval boundary. Use **native required CODEOWNER review by @noelsaw1, dismiss stale approvals, require last-push approval, enforce for administrators, no bypass actors**, plus a required deterministic admission check. This applies to all PRs; one coverage decision per code change (reuse/extend/add/no-add), not one approval per assertion. Operator approval is native GitHub review, never an agent-writable boolean or comment. Admin credentials remain administrative authority; this is not protection against a person/agent deliberately changing repository settings with that authority.

Use `CODEOWNERS` wildcard to ensure review cannot be evaded by moving tests outside named directories or modifying the verifier/workflow. A new native Actions dispatch publisher opens bot-authored PRs from existing task branches, reading only branch data and never executing candidate code. Operator-authored PR #811 cannot receive its author's native review: bootstrap landing/activation needs explicit operator direction at handoff, not a fabricated approval or silent replacement PR.

The existing hosted reconciler currently asserts development is unprotected and directly pushes via `hosted_lane_publish.py`. Add a protected-branch mode which publishes its existing allowlisted artifacts on a bot PR; never grant GitHub Actions a direct-push bypass. Skip reconciliation of that publisher's own lifecycle-only PR, and avoid repeatedly running qualification while an outstanding reconcile PR awaits review. Preserve the existing unprotected downstream behavior. These consumers must be repaired before activating protection.

### Ordered implementation and acceptance

1. [ ] **Single decision command and disclosure — High, quick win.** Extend inventory CLI with prepare/check admission commands. Generate `.github/test-admission.json` from a rationale file and a nonempty Git diff; bind the complete non-packet changed-file manifest (old/new blob IDs and modes) and merge-base, require outcome, behavior, existing coverage, reason, red evidence, cost/unknown explanation and issue. Report added/modified/deleted test files, registered-suite delta when parseable, and explicit unknown case counts; all executable changes require a decision, docs-only changes are explicitly classified. → An omitted file, added assertion inside an existing file, stale product edit, renamed/deleted test, malformed JSON and fabricated approval flag cannot pass; generated metadata is proposed, never approval.
2. [ ] **Early local refusal and trusted hosted checking — High.** The push hook validates committed proposal before expensive test execution. A `pull_request_target` workflow checks out base code only, fetches candidate objects as data and calls the same checker, publishing a coverage summary/catalog artifact; never execute candidate scripts, package hooks or imports. → Missing/stale proposals refuse; docs-only changes explain no-test route; fake candidate checker is not executed. Native review, not a check-name match, supplies approval authority.
3. [ ] **Human approval and compatible publishing — High, Costly.** Add CODEOWNERS, bot PR dispatch and protected reconciliation publication using native APIs and existing publisher. Supply an activation/read-back procedure for the exact native review/check policy and Actions PR-creation setting, with no bot bypass. → Bot and human identities are distinct; stale review is dismissed; direct integration pushes are refused after activation; reconcile artifacts arrive through reviewable PRs without recursively qualifying themselves. Prepare everything before requesting bootstrap merge/activation; no merge/settings mutation during build.
4. [ ] **Bounded proof and truthful handoff — High.** Extend existing gh419 and hosted-publisher tests; do not add a new suite. Run focused controls in a disposable full clone, retain provenance, obtain final Codex relay QA, then the final macOS gate and hosted check where executable before bootstrap. → Distinguish implemented and locally verified from activated on development; leave live policy/approval-path checkboxes open until actually witnessed. Retain #805's broader sample/value-analysis work as incomplete rather than equating gateway work with closing the whole issue.

Costly because all builders, PR reviews and hosted reconciliation cross this boundary. Rollback is a reviewed revert plus restoration of the saved repository policy; never automatic removal of protection on a failing check. Tripwires: rejected legitimate proposal, unexpected reviewer identity, candidate execution in trusted job, or blocked reconciliation without a PR; stop rollout and diagnose via debug-mantra. No new DB, service, model invocation per test, numerical cap, legacy approval backfill, or GH808/gh251 edits. Reuse the existing gh419 suite for a bounded control matrix and gh740 publisher suite for the publication branch; full-gate timing is not an admission-cost benchmark.

Plan QA and final QA each use the shipped Codex relay, capped at three rounds. Implementation starts only after plan approval. Activation is a separate final, concrete operator decision because start-task does not authorize merging/deployment. Preserve existing ratings and operator scope; urgency is explicit without inventing a measured growth trend.

## Execution checklist

1. [x] **Inventory — Medium; meaningful quick win.** Extend `utils/py/gate_inventory.py` with an opt-in audit view derived from the current registry, route mapping and runner invocations; include indirect gh534 and explicit helper/manual/unknown classifications with source references. Retain a generated snapshot and historical artifact index, no hand-maintained runner list. → Nonempty fixture/source checks reproduce counts; commented, duplicate and empty registry controls fail appropriately; original JSON consumers stay compatible.
2. [x] **Selection repair — High; bounded quick win.** Extend the existing releases mapping and both full-runner Python/Node invocation paths after focused supported-host eligibility checks. Preserve existing collectors and tier behavior; add a missing-mapping red control in the existing routing suite. → Before/after selected sets show additions only, Flightdeck and Node cases run once per full runner, nonzero child exit propagates, and incremental time is recorded in disposable clones.
3. [x] **Meaningful controls — High; bounded quick win.** Tighten gh269's planner exit handling, witness/repair gh165's concrete guarded-write failures, and restore a small gh177 hook matrix including sandboxed block, unsandboxed allow and read-only syntax commands. New hook coverage needs one registered suite; other checks extend current suites. → Each claimed protection has a witnessed seeded failure and restored green, with nonempty logs and pre/post clone identity evidence.
4. [x] **Simplification experiment — Medium; benefit uncertain.** Map the distinct gh269/567/568 invariants, then trial one-time gh567 file discovery without combining suites or dropping policy checks. Compare base/candidate LOC including helpers, discovery count, diagnostics, focused runtime and seeded detections. → Retain only a demonstrated maintenance/runtime improvement; unchanged detection and diagnostics required, otherwise record a keep decision.
5. [x] **Trust contract — High; prerequisite, not a quick win.** Specify reuse/extend/add/no-add decisions, coverage IDs, overlap rationale, test/product file digests, source/reviewer identity, routing and red evidence; additions inside existing files and weakening/deletion invalidate the bound content. Record that local metadata validation cannot authenticate approval; mandatory use would require a separately authenticated authorized reviewer and trusted verifier revision/check producer on development, with deliberate operator override audited and fail-closed missing authority. → A proposed design covers forged/self/stale/missing/malformed/verifier edits; live authority unavailable means explicit no-go, without changing branch protection.
6. [x] **Observe-only pilot — High; not a quick win.** Add optional decision-record validation and a generated projection to the existing inventory tool, using one bounded JSON metadata artifact under the GH805 evidence directory (no DB/server and no new scheduling authority). States are proposed/unreviewed/advisory-reviewed; approval_trusted remains false without independently verified authority, even if metadata says approved. → Codex independently adjudicates retirement-cohort keep/extend choices, legitimate gh177 addition and an inappropriate duplicate proposal; record stale/malformed/missing/forged observations, review disagreement/latency and tool cost, separately scoring metadata validation and semantic recommendation accuracy. Do not label synthetic fixtures real-world false-accept estimates.
7. [x] **Decisions and handoff — High; not a quick win.** Publish separate coverage and mandatory-admission decisions, observed suite/case/invariant counts, retained protections and cost limits; attribute any available #808 evidence separately. Default recommendation retains independent policy guards and declines mandatory admission until authentic authority and required trusted execution exist. → Final Codex review, focused evidence, one final full gate and applicable hosted exact-head evidence support one PR; mark issue checklist items only when demonstrated, leave issue open awaiting merge.

## Verification and handoff

Plan QA precedes implementation and ledger accepted-start. Review the actual source paths above and this complete plan, not merely the summary. Final QA reviews the committed diff, decision cohort and evidence before the one final full qualifying gate. Reviewer writes are restricted to its relay thread and never runs tests in its linked worktree.

All mutation-heavy tests run in a separate disposable full clone. Capture commands, exit status, timings, revision and pre/post HEAD/config/remotes identity in committed `TESTS-RESULTS/2026-09-25+GH-805/provenance.jsonl`; identity drift invalidates the run. Red controls mutate only fixture/disposable content and restore saved bytes, never reset a valued checkout. Focused suites are gh419, gh35/gh365 routing, runner envelope, gh269/165/177/567/568 plus the existing Flightdeck/Node commands and targeted PDDA checks. Test footprint stays proportional: no fuzzers, alternative runner, sweeping legacy backfill or bulk deletions.

Review/dogfood/conformance arcs remain in this same branch: plan relay; focused implementation and real-cohort CLI use; final relay and runner parity/conformance, then full gate. Routing and gate changes are Costly shared confidence changes: rollback is a reviewed revert of this scoped PR, retaining prior safety checks and no external policy changes. Inventory/pilot output alone is Easy and nonblocking. Never weaken tests merely to obtain green; unresolved baseline failures remain reported and prevent a ready claim.

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

## Safety, rollback, and non-goals

- Audit/catalog exploration is Easy to reverse; test removal, selection changes, and mandatory admission are **Costly** because they affect every builder, reviewer, and merge path. Pilot rollback restores the prior tests/routing and returns only the new admission layer to observe mode; existing containment and verification controls remain enforced.
- Preserve the required local macOS gate and exact-SHA hosted attestation. All mutation-heavy verification runs in disposable full clones with pre/post identity checks; no production clone experiments.
- No arbitrary test-count cap, automatic bulk deletion, line-coverage-only ranking, or reduction in containment to achieve a faster green gate. Quarantine, if proposed, must remain observable with owner/issue/expiry rather than silently disabling coverage.
- No new heavyweight service, database, model training, or parallel registry without a demonstrated need. Catalog formatting and admission policy must not cost more recurring work than they remove.
- “All new tests approved” means **admission before landing**, not preventing an agent from drafting or running an experimental test. Final approval authority and tamper resistance must be resolved before calling the system enforceable.

— GPT 6 Astra Light

## Execution evidence

Steps 1–6 are implemented and supported by [the report](../../TESTS-RESULTS/2026-09-25+GH-805/REPORT.md), generated catalog, advisory cohort and committed provenance. Plan relay approved revision 7813ab52; implementation e5f7659d passed eight focused suites, with five external mutation controls failing as expected. Step 7 is now complete; final gate and hosted PR evidence are recorded below. No merge or release claim.

### Gate-discovered bounded amendment

The first full gate failed 419/422 with intact clone identity. Two scoped integration corrections replace the fictional GH177 payload path with a real inert path and update the releases route count from 24 to 28. The third failure reproduces on unchanged 0ae3452a: GH390’s MagicMock fixture reaches its 500,000-call ceiling between RSS watchdog samples. A simple fixture-only repair holds that same bounded allocation for two pinned one-second polling intervals before its existing failure exit; production guard, allocation limit and required gate-killed verdict stay unchanged. This is an obvious local reversible test repair, so it uses start-task’s simple-change exception rather than another architecture review; final relay round 3 explicitly reviews it and its disabled-guard red control.

Final full pre-push validation passed 422/422 on 9625367f with intact clone identity. The branch pushed without bypass; promotion is not claimed. Final relay round 3 approved the gate-discovered fixture amendments. [PR #811](https://github.com/HiQS-Labs/XYZ-forge/pull/811) is mergeable against development; hosted blocking smoke passed on 73e31244. The prior all-complete claim is superseded by the completion audit and gateway continuation above. Broader acceptance and activation remain outstanding.
