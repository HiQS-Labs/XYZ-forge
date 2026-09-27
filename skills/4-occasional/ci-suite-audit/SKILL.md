---
name: ci-suite-audit
description: >-
  Audit registered CI test suites and recommend retention, split, nightly,
  quarantine, or turn-off verdicts based on runtime receipts, failure history,
  touch-set overlap, and prose/junk assertion analysis. Use when an operator asks
  to "audit test suites", "curate CI tests", "find slow tests", "identify redundant tests",
  "review test retention", "evaluate test gate health", or prepare the full-suite audit.
---

# ci-suite-audit — Test Suite Curation & Retention Triage Playbook

A structured, evidence-governed method for evaluating and curating test suites in large CI registries.
It inspects runtime performance, defect and flake history, touch-set overlap, sibling coverage, and
assertion quality (prose and junk checks) to classify test suites into actionable, defensible verdicts.

The skill serves as the canonical curation method for full-suite audits (GH-854, GH-862).

---

## Operating Rules & Core Constraints

1. **Manual Invocation Only:** The skill is invoked by an operator for occasional audits (e.g. quarterly sweeps or after major CI churn windows). It is not automated, not scheduled, not wired into CI workflows, and does not run on pull requests.
2. **Text-Only Skill:** Contains instructions and documentation only. No executable scripts live in the skill directory or under `utils/`, `scripts/`, or `bin/`. Any one-off extraction or scoring code needed during an audit belongs in that run's evidence directory (`TESTS-RESULTS/<date>+GH-<n>/`).
3. **Proposes Verdicts; Humans Decide:** The skill generates structured recommendations with citations and confidence ratings. It **never** directly edits `validate.sh`, `test/`, `utils/ci-route.sh`, or GitHub Actions workflows, never deletes files, and never opens pull requests. Changes to the registry or test files must be reviewed and approved by an operator per verdict class.
4. **Restricted GitHub Writes:** The skill's only permitted GitHub write operations are creating/updating its own dedicated report issue and appending per-turn decision comments on that issue (see *Report Issue & Per-turn Comments*). It never modifies or comments on any other issue or PR.
5. **Freeze & No New Tests Compliance (GH-831):** The skill respects repository test freezes. It introduces no new gate machinery, no new runner scripts, and no new test arrays (`NIGHTLY_TESTS` stays out of tree; candidates remain in `TESTS`). Quarantined suites use the existing unregister-and-exempt mechanism in `test/gh306-registry-bidirectional.sh`.
6. **Honest Metrics:** Anything not measured is `UNKNOWN`; nothing is estimated silently.
7. **Log Evidence Preservation:** Save each downloaded or extracted workflow log, run summary, or receipt into the evidence folder (`TESTS-RESULTS/<date>+GH-<n>/`) the first time it is read.

---

## Unit & Data Access Modes

### Unit of Analysis
The unit of curation is **one entry in the `TESTS=(...)` array in `validate.sh`** (411 suites).
- Anything the suite executes via `bash`, `python3`, `node`, or binary invocation belongs to its unit (e.g. `gh436-merge-cleanup.sh` running `gh436-merge-cleanup.py`).
- Sourced libraries (`test/_setup.sh`, `test/lib/*.sh`) provide shared fixture and containment context.
- Always record the `validate.sh` commit SHA and the current `test/gh306-registry-bidirectional.sh` `EXEMPT` list before scoring. Assert `TESTS` is non-empty and matches `validate.sh --list`, and record `EXEMPT` separately.
- **Subdirectory Suites:** Note that `test/gh306-registry-bidirectional.sh` `EXEMPT` only governs top-level `test/*.sh` files. Subdirectory suites (e.g. `synthetic/*`) that are turned off come out of `TESTS` and their own registry pin (`test/gh141-synthetic-registry.sh`), not into gh306 `EXEMPT`.

### Access Modes

1. **In-Checkout Mode (Preferred):**
   - The operator invokes the skill inside an active, clean repository checkout on the target branch (e.g. `development`).
   - The skill does not pull or clone automatically.
   - Uses local disk tools (`rg`, file inspections, committed receipts) to inspect full source, helpers, and test definitions across all registered suites.
2. **Connector-Only Mode (Fallback):**
   - Used when operating without a local workspace clone, reading registry files, receipts, and workflow logs via the GitHub connector.
   - Full source reads are prioritized for: every non-KEEP candidate, the top 10 heavy suites by runtime, every `#853` isolation member, and every suite with a failure in the analysis window.
   - Suites evaluated solely from run logs or labels are strictly capped at `LOW` confidence and cannot receive a non-KEEP verdict without explicit source retrieval.

### Data Limitations & Disclosures
Every audit report must explicitly disclose data boundaries:
- **Committed Receipts:** Committed validation receipts represent passing (`green`) runs by construction; they provide accurate runtime distributions but no failure signal.
- **Hosted CI Logs:** Historical failure logs are extracted from hosted `validate.sh` summary `failed:` blocks. Log retention is subject to GitHub Actions artifact windows (typically 14–90 days).
- **Label Coverage:** Some test runs or shims may produce partial test label manifests (e.g. 355 of 411 suites labeled). Unlabeled suites are marked `UNKNOWN` for label-based heuristics.
- **Unmeasured Signals:** Any signal, log, or receipt not directly observed or parsed is recorded as `UNKNOWN`; it is never estimated silently.

---

## Inputs

| Signal | Source | Collection Rule |
|---|---|---|
| **Registry** | `validate.sh` `TESTS`, gh306 `EXEMPT` | Record commit SHA; assert `TESTS` is non-empty and its count matches `validate.sh --list`. Record gh306 `EXEMPT` list separately. |
| **Current Tier** | `utils/ci-route.sh` registry mapping | Record Small (tier 1/2), Medium, or Large-only for each suite. |
| **Runtime** | `TESTS-RESULTS/.../validation.jsonl` (`event:"suite"`, `duration_ms`) | Compute median duration across at least 3 green full-gate receipts. Record runner host architecture. |
| **Failure Tally** | Hosted `validate.sh` job summary `failed:` logs | Record failures as `k of N runs` over the analysis window (never report "never failed"). |
| **Failure Cause** | PRs/issues linked to failures; #853 tracking list | Classify failure mechanisms using the Failure Taxonomy. |
| **Labels & Hints** | `PASS:` / `ok -` output in full run logs | Extract sub-check counts and keyword hints for overlap and prose checks. |
| **Source Code** | Suite file, executed scripts, sourced helpers | Full source read required for every non-KEEP recommendation. |

### Known Flake Candidates to Seed
When initializing an audit, seed known non-deterministic candidates identified in prior windows:
- `gh610-claude-subscription` (intermittent across PR runs)
- `gh123-lock-progress-bound` (timing and progress bounds)
- `registry-lock-concurrency` (intermittent contention / race)
- Active `#853` suite isolation tracker members (`agent-chorus-bridge`, `gh492`, `gh620`, etc.)

---

## Detectors (D1–D9)

### D1: Runtime Profiling
- Measure median execution time in seconds, global runtime rank, and share of the median full gate (currently ~2988 s / ~50 min).
- **Heavy Suite:** Rank ≤ 10 or consuming ≥ 1.0% of the total gate runtime.
- Recompute rankings from fresh receipts after any suite trimming PR.
- *Role:* Runtime breaks ties and nominates NIGHTLY candidates. **Runtime alone never justifies turning off a test.**

### D2: Failure History & Defect Attribution
- Classify all observed failures across the audit window using the Failure Taxonomy.
- Same-commit / same-SHA divergence (passing on one run, failing on another) serves as primary evidence of non-determinism (`flake`).

### D3: Touch-Set Overlap
- For each suite, statically analyze:
  1. Binaries and scripts executed (`bash <x>`, `python3 utils/py/<y>`, `bin/tick <verb>`, `node <z>`).
  2. Library files sourced (`test/_setup.sh`, `test/lib/*.sh`).
  3. Repository paths read or grepped.
  4. Repository paths written or modified.
- Two suites overlap when their **invoked target entry points overlap**.
- Text similarity (e.g. 5-token shingle Jaccard ≥ 0.6) or label similarity is a secondary tiebreaker only after touch-sets overlap. Filename similarity (e.g. `gh155-phase3` vs `gh155-phase5`) is not overlap if distinct subsystems are invoked.

### D4: Sibling Coverage
- A suite is **covered** when a named sibling suite tests the same target entry points with an equal or superset set of behavioral assertions.
- *Example:* `synthetic/synthetic-pi-model-unset.sh` is covered by `test/pi-turn.sh` (which asserts exit code 5, clean working tree, no commit, and uninvoked model binary).

### D5: Prose Check
- Count assertions that inspect documentation and markdown files (`*.md`, `SKILL.md`, `docs/*`, `README`, `ROUTER.md`, `AGENTS.md`) versus assertions that execute codebase scripts/binaries and verify behavioral contracts.
- Exclude generated fixture files or runtime-emitted docs created inside a test sandbox (e.g. asserting `ESCALATION.md` was created by an agent turn is behavioral).
- **Prose Ratio:** `(doc-grep assertions) / (total assertions)`.
  - **Ratio ≥ 0.6 (Prose-only):** Candidate for TURN-OFF if no code is executed and no user-facing key/path is guarded.
  - **Ratio 0.2–0.6 (Mixed):** Candidate for SPLIT (keep behavioral checks; drop/move pure wording assertions).
  - **Ratio < 0.2 (Behavioral):** Retain on gate.

### D6: Junk Pattern Detection
Inspect individual assertions for anti-patterns:
- **Exact String Fragility:** Asserting exact prose strings that break on innocuous copy-edits but pass on broken logic.
- **Duplicate Contract Calls:** Repeating identical CLI invocations and flag checks across multiple independent suites without novel assertions.
- **Stub Implementing Assertion:** A test stub (e.g. mock `gh` or `git`) hardcodes the exact string the test subsequently asserts.
- **Private Call-Shape Checks:** Asserting internal Python function names or private helper argument lists instead of public CLI behavior.
- **Vacuous Negative Controls:** Assertions that mutate a local copy or test fixture and grep the copy without exercising the actual code path (e.g. `gh798` controls 8a/8b).

### D7: Can-It-Fail Verification
- Before asserting that a test suite cannot fail, trace all sourced helpers and error traps.
- A suite sourcing `_setup.sh` that calls `fail()` on error will exit 1 on failure even if the file concludes with `exit 0`.

### D8: Fixed-at-HEAD Verification
- For every historical flake or failure, check whether a remediating commit already landed on the active branch (e.g. `gh649` resolved by `pwd -P` canonical path resolution).
- If fixed at HEAD, classify as `fixed-flake` (KEEP); do not quarantine.

### D9: Four-Question Gate (OpenClaw)
For every evaluated suite:
1. *What contract or behavior does it protect?* (CLI verb, concurrency invariant, data integrity, routing).
2. *What credible regression makes it fail?* (State the failure scenario).
3. *Why doesn't existing coverage catch it?* (Identify the unique boundary).
4. *Does it require a test-only seam in production code?* (Reject artificial test-only hooks).
- *Verdict Effect:* A suite with no clear answer to Q1 or Q2 is a candidate for `TURN-OFF` or `MERGE` (it guards no identified behavior or failure mode). A suite with answers to Q1 and Q2 but no answer to Q3 is a candidate for `MERGE` into its covering sibling.

---

## Failure Taxonomy

| Class | Evidence Required | Verdict Effect |
|---|---|---|
| `regression-caught` | Failure directly caught a real bug, confirmed by a subsequent product code fix (e.g. `gh436` in #812 caught by `0ae3452a`/#794; `gh496` caught race in #813/#818). | **Protected.** Stays on the PR gate regardless of runtime. |
| `coupling` | Failure caused by unrelated inventory changes, doc rewordings, or count shifts. | **KEEP-FIX.** Flag fragile D6 assertions for trimming. |
| `flake` | Same commit passed in another run; or error log cites timing bound/port race with no fix at HEAD. | **QUARANTINE** if no fix in progress; **KEEP-FIX** if fix is actively open. |
| `host` | Failure caused by runner environment (macOS vs Linux paths, `/tmp` contention, host Python). | **KEEP-FIX**, linked to #853 tracking umbrella. |
| `fixed-flake` | Cause of failure was resolved by a landed commit at HEAD (D8). | **KEEP.** Cite fixing commit. Do not quarantine. |
| `unattributed` | Unexplained timeout or missing summary log. | No change to verdict. Noted in coverage summary. |

---

## Verdicts, Decision Rules & Guardrails

| Verdict | Definition & Rule | Proposed Action (Requires Approval) |
|---|---|---|
| **KEEP** | Meets retention bar, catches regressions, or uniquely guards a contract. | Retain in `validate.sh` `TESTS`. |
| **KEEP-FIX** | Retained suite that is coupled, flaky, or host-sensitive with an active fix path. | Retain in `TESTS`; link fix issue or #853 umbrella. |
| **NIGHTLY** (candidate) | Heavy suite with a faster PR-time sibling covering its full target set (see NIGHTLY Rule). | Listed as candidate for future scheduled runs (#859). Remains in `TESTS`. |
| **QUARANTINE** | Flaky suite blocking CI with no immediate fix at HEAD. | Move from `TESTS` to `test/gh306-registry-bidirectional.sh` `EXEMPT` with `quarantine: <issue>` reason. Keep file on disk. If multiple suites share the same root cause, recommend running `whack-a-mole` instead of isolated quarantines. |
| **SPLIT** | Mixed suite (D5 prose ratio 0.2–0.6) combining behavioral checks with prose greps. | Propose splitting: retain executable contract checks; drop or move wording greps. |
| **MERGE** | Redundant suite whose unique assertions are folded into a named keeper suite. | Propose folding assertions into keeper after red control; then turn off. |
| **TURN-OFF** | Obsolete suite (target removed), pure prose suite (ratio ≥ 0.6 executing nothing), or fully covered sibling with no unique assertions. | Move from `TESTS` to `test/gh306-registry-bidirectional.sh` `EXEMPT` with audit reason. Keep file on disk. |
| **INVESTIGATE** | Insufficient evidence or conflicting signals. | Retain in `TESTS` pending further telemetry. |

### The Retention Bar
Always **KEEP** a suite that independently guards:
- Package installation, bootstrapping, or migration logic.
- Concurrency, file locks, or driver lock invariants.
- Security, credential containment, or network egress boundaries.
- CLI contracts (exit codes, standard flags, stdout/stderr protocols).
- Data integrity, database schemas, or ledger transactions (`releases.db`, `tick`).
- Gate routing or CI test selection contracts (`ci-route.sh`, `gh308`).
- Source inspection when it is the cheapest independent guard of a user-facing configuration key or path.

*Mantra:* **Static or slow is not a reason to delete.**

### The NIGHTLY Rule
A heavy suite $H$ is a candidate for NIGHTLY only when **all four conditions hold**:
1. $H$ is heavy (D1: rank ≤ 10 or ≥ 1.0% gate time) and has **no** `regression-caught` failures in the audit window or issue history.
2. A named sibling suite $S$ remains on the PR gate, and $S$'s invoked target scripts/binaries are a **superset** of $H$'s invoked targets (D3). Static reads, greps, and written files do not count toward superset target invocations; only invoked target scripts/binaries count.
3. $S$ is significantly faster (median duration of $S \le 20\%$ of $H$) and has no open flakes.
4. If $H$ guards a retention-bar contract, $S$ must guard that same contract.

*Fallback:* If no sibling qualifies, the verdict is `KEEP (heavy, no PR-time sibling)`.

### Core Guardrails
- **`0 of N runs` is never a reason to turn off or demote a test.**
- **A `regression-caught` suite is never proposed for NIGHTLY, QUARANTINE, or TURN-OFF.** (e.g. `gh436-merge-cleanup.sh` is 183 s median, red in 7/14 runs during #812; it remains on the PR gate).
- **An active #853 member is never turned off.** (Only `KEEP-FIX` or `QUARANTINE`).
- **Check Pinned Suites:** Before proposing `TURN-OFF`, verify whether other suites assert the entry in `TESTS` (e.g. `gh35-test-tiers.sh`, `gh365-driver-lane-registry.sh`, `gh141-synthetic-registry.sh`, `ci-workflow.sh`, `gh379-canary-uses-validate.sh`, or release manifest suites).
- **No Unbacked Merges:** If a proposed survivor for `MERGE` or `SPLIT` does not exist, mark the row as `parked: no survivor` rather than creating new suites under the freeze.
- **High Confidence Required:** Non-KEEP recommendations require full source inspection and `HIGH` or `MED` confidence.
- **Observation Window:** Approved turn-offs are moved to `EXEMPT` (or removed from registry pin) for an observation window before anyone considers deleting a file (at least 14 days).

---

## Output Format

The audit produces a machine-readable tab-separated values (TSV) dataset and a markdown summary, saved to the evidence directory:
`TESTS-RESULTS/<date>+GH-<issue>/ci-suite-audit.tsv`

### TSV Columns
```text
suite	tier_now	med_s	rank	pct_gate	fails (k of N)	fail_class	issues	touch_set	overlap_with	covered_by	prose_ratio	junk_flags	pins	gate_q1_q3	verdict	proposed_action	evidence	confidence	source_read	restore
```

- `evidence`: Cites `file:line`, job run ID, or GitHub issue/PR number.
- `confidence`: `HIGH` (source read + telemetry), `MED` (one of the two), `LOW`, or `UNKNOWN`.
- `restore`: Shell command to restore or un-exempt the suite if needed.

### Summary Markdown Layout
The summary report includes:
1. **Audit Metadata:** Run date, registry commit SHA, analysis mode (in-checkout vs connector), receipt count, and log window.
2. **Verdict Breakdown:** Tally of suites per verdict class.
3. **Heavy Suite Summary:** Top 10 suites by runtime with sibling coverage status.
4. **Actionable Proposals Table:** Itemized list of all non-KEEP candidates with proposed actions, citations, and confidence scores.
5. **Diagnostic & Remediation Reminders:** Sibling skill trigger status.

---

## Report Issue & Per-turn Comments

### Report Issue Creation & Deduplication
- **Title Format:** `ci-suite-audit: <audit date> report @ <registry SHA>` (e.g. `ci-suite-audit: 2026-09-27 report @ a076b1b1`).
- **Deduplication Marker:** The report issue body begins with an HTML comment marker:
  `<!-- ci-suite-audit:<registry-sha>:<audit-date> -->`
- **Dedupe First:** Before opening a new issue, search open issues for this marker (by label `ci-suite-audit` or title prefix `ci-suite-audit:`).
  - *Match found (same SHA or audit date):* Update the existing issue body and post a comment with the delta. **Never open a duplicate issue.**
  - *Multiple open matches:* Stop and request operator clarification.
  - *Closed match:* Open a new issue referencing the previous closed report.
- **Labels:** Apply `ci` and `stability`, plus `ci-suite-audit` if that label exists in the repository. **Never apply the `radar` label.**
- **GitHub Size Limit (65,536 chars):** If the full report exceeds GitHub's issue body limit, place the summary, verdict counts, non-KEEP rows, and reminders in the issue body. Post the full per-suite TSV/table across sequentially numbered issue comments (`table part k of n`).
- **Posting Fallback:** Attempt issue creation via GitHub CLI (`gh issue create`). If CLI is unavailable or unauthorized, create via GitHub connector tools. If running offline or without GitHub write permissions, write the formatted report to the evidence directory (`TESTS-RESULTS/<date>+GH-<issue>/ISSUE.md`) and alert the operator.

### Per-Turn Comments
- In interactive audit sessions, after each turn where a decision is reached, post **one** structured comment detailing:
  - Verdicts accepted, rejected, or overridden by the operator.
  - Follow-up issues filed (only with explicit operator authorization).
  - Open questions resolved.
- **Post Only on Changes:** Turns without decisions or changes generate no comment ("no change" comments are prohibited).
- Conclude each comment with the remaining open items. When all items are resolved, propose closing the issue. Close only upon operator confirmation.

### Safety & Redaction
- Redact all access tokens, API keys, secret variables, and environment values.
- Strip local machine paths, replacing them with repository-relative paths (`skills/...`, `test/...`).

---

## Related Skills

The skill recommends sibling skills for broader coordination; it never invokes them autonomously.

- **[radar](../../3-weekly/radar/SKILL.md):** The **diagnostic** sibling. Recommends running radar when CI failures reflect wider SDLC or process drift rather than isolated test defects:
  - *Trigger:* $\ge 25\%$ of red runs in the window are `unattributed` or `coupling`, or a trunk-red cluster appears (e.g. `gh436` and `gh674` red together across multiple runs, as in #812).
- **[whack-a-mole](../../3-weekly/whack-a-mole/SKILL.md):** The **remediation** sibling. Recommends running whack-a-mole when recurring test failures share a single root cause:
  - *Trigger:* $\ge 3$ suites fail due to the same underlying mechanism (e.g. shared runner port race or `/tmp` collision). If an existing umbrella covers the pattern (such as #853 for test isolation), cross-reference that issue instead of opening a new one.
- **[ci-optimize](../ci-optimize/SKILL.md):** Pipeline architecture cross-link (unit: entire CI/CD pipeline; `ci-suite-audit` unit: one test suite).

### Sibling Reminder Block
Every audit report and issue concludes with a status block:

```markdown
## Sibling Skill Recommendations
- **radar:** [trigger met: <evidence> | not triggered]
- **whack-a-mole:** [trigger met: <evidence (points to #853 if covered)> | not triggered]
```

---

## Proposed Authoring Gate (Proposal for Operators)

> **For operator decision. Not active by default.** Adapted from OpenClaw (MIT).
> Under the repository test freeze, no new test files may be added. When modifying or extending existing suites, apply this 4-question gate to every new assertion:

1. **What behavior or contract does this assertion protect?** (Name the CLI verb, schema constraint, or isolation boundary).
2. **What credible regression makes this assertion fail?** (Witness the failure under mutation or record a red control).
3. **Why don't existing assertions catch it?** (Check existing suites with `rg` before adding duplicate assertions).
4. **Does it rely on artificial test-only hooks in production code?** (Avoid adding flags or exports solely for testing).

---

## Sources

Upstream credits, MIT license texts, and copyright notices are documented in [`NOTICE`](NOTICE).
