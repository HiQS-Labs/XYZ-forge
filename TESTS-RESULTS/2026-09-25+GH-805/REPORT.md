# GH-805 test value and admission pilot

Coverage repairs are justified; a blanket test cull and mandatory admission rollout are not. This is a bounded audit, not a census of semantic invariants or a trusted approval service.

## Units and inventory

| Unit | Base | Candidate | Meaning |
|---|---:|---:|---|
| Registered shell suites | 417 | 418 | `validate.sh:TESTS`; one GH177 hook suite added |
| Tracked shell files under test | 435 | 436 | Includes helpers, exemptions and nested fixtures |
| Flightdeck collected Python cases | 39 | 39 | Existing cases newly included in both full runners |
| Node unit cases | 14 | 14 | Four existing files, newly included in both full runners |
| Retirement policy suites | 3 | 3 | All distinct protections retained |
| Assert / whole-estate invariant count | unknown | unknown | No defensible global count inferred from files |

Generate the view with `python3 utils/py/gate_inventory.py --audit --decisions TESTS-RESULTS/2026-09-25+GH-805/decisions.json`. Default output retains the original GH419/litmus JSON contract. The audit reads current tracked files, canonical TESTS and `ci-route.sh subsystems`; source references are discovery hints, explicitly not proof of execution. The checked-in catalog is a reproducible snapshot, never a second scheduling authority.

The 18 shell files outside TESTS comprise eight `test/lib` helpers, two setup helpers, two legacy manual agy tests, the per-mutant gh460 oracle, four synthetic suites called by registered wrappers, and the deliberately manual recursive gamma fixture. `gh306-registry-bidirectional.sh:EXEMPT` owns the top-level exclusions; gamma has a nonrecursive staleness probe in the gate. An exemption is an explanation, not an endorsement of indefinite exclusion.

GH534's three Python modules are reached through registered `gh436-merge-cleanup.sh` → `gh436-merge-cleanup.py` imports → unittest discovery. A duplicate standalone registration was rejected. Flightdeck and Node previously had no checked-in full-gate caller; focused supported-host runs passed 39 and 14 cases respectively. Browser `.mjs` and arbitrary dynamic imports remain outside this narrow repair.

`historical-telemetry-index.json` indexes 40 existing JSONL artifacts, retaining available run-start and summary records with revision, host, width and result. Missing dimensions remain unknown; unlike historical runs are not matched benchmarks. The historical GH591 wave measurement of gh251 was 1044.435/4809.278 seconds (21.7%); GH808 remains GLM-owned and no savings from it are claimed here.

## Repairs and witnessed controls

| Change | Before control | Candidate control / protection |
|---|---|---|
| gh269 planner exit | Injected exit 5 still returned suite rc0 | Same injection returns rc1; 0/4 are the accepted set |
| gh165 quoted mover | `shutil.move("active.md", "PROJECT/3-COMPLETED/active.md")` was invisible | Same injection returns rc1; missing required inputs also fail |
| GH177 hook regression | No registered hook payload matrix | 17 cases pass; replacing hook with exit0 fails the suite |
| releases selection | Four named suites omitted from focused releases | Additions only; removing gh605-work-state fails the routing suite |
| full non-shell lanes | Flightdeck/Node absent | Both runner snippets execute each lane once; child rc7 fails both; deleting Node call makes runner-envelope red |
| inventory / decisions | Parser could accept empty/duplicate or commented entries | Fixtures reject empty/duplicate/dynamic registry; stale/missing/self-issued records flagged; asserted trusted approval remains false |

Logs and `provenance.jsonl` retain exact commands, revisions, results and elapsed times. Baseline execution used a separate full clone at 7813ab52 (docs-only changes from 0ae3452a); candidate execution used e5f7659d. Identity snapshots match before/after focused runs. A mistyped baseline filename returned rc127 and is retained as a failed invocation; the corrected gh568 run passed. Expected red-control failures are not gate failures or successful production runs.

GH165 is still a bounded static canary: literal same-line moves and named PDDA/triage write shapes, not a proof against computed destinations or every language. It deliberately retains the existing conservative triage `open` check. GH177 preserves the hook's documented parse-error fail-open and approximate shell parsing; nested substitutions and xargs/find dispatch are not advertised as covered.

## Simplification result

Retain all three retirement suites. GH269 protects planner/DB/PDDA behavior; GH567 protects dashboard artifacts and invocations; GH568 protects release-view CLI/write/AST/runtime behavior. Neither filename similarity nor the shared word “retired” establishes redundancy.

GH567 now discovers the candidate files once and reuses that array for its three policy searches. The file shrank from 226 to 222 lines, four traversal expressions became one, and filename-bearing diagnostics remain intact even for a one-file fixture. Existing canary/writer/empty-input red controls pass. Focused baseline/candidate samples were 0.461/0.393 seconds on this host; one sample is insufficient for a runtime improvement claim. The concrete gain is less duplicated discovery, with no helper or suite deletion. Combined retirement-suite LOC rises from 799 to 804 because gh269 gained meaningful controls; no 550-line reduction is claimed.

## Admission contract and pilot

Four allowed coverage decisions are **reuse**, **extend**, **add**, and **no-add**. Approve the coverage decision for a change set, not a ritual per assertion. `decisions.json` is the bounded cohort metadata; the tool alone derives the displayed state and hard-codes `approval_trusted=false` and `would_refuse_mandatory=true`. Valid metadata becomes advisory-reviewed; invalid/incomplete metadata is unreviewed. There is no new database, service, execution registry or merge blocker.

| Proposal | Independent advisory decision | Rationale |
|---|---|---|
| Retire/merge gh269/567/568 | Reuse distinct suites | Each has policy-specific controls absent from the others |
| New suite for planner exit | Extend gh269 | Existing owner can carry this regression |
| New GH177 hook suite | Add | Live containment boundary lacks registered regression |
| Separate GH534 wrapper | No-add | Existing GH436 collector already imports all three modules |

Luna high `/root/admission` independently inspected the source cohort in approximately three minutes and agreed with all four decisions; identity is advisory, not an authenticated GitHub reviewer. Final Codex relay review also evaluates this cohort. Four selected proposals are too few and too curated to estimate a real-world semantic false-accept/reject rate. Observed disagreement in that advisory review: 0/4. Tool execution cost is in provenance; model token/currency cost is unavailable, not zero. Plan relay wall time was 2m18s; final review overhead is recorded in its thread.

Metadata controls cover malformed/empty input, missing fields, duplicate IDs, self-issued review, stale content, missing/deleted content and attempted `approval_trusted:true`. Content hashes cover entire listed product/test files, so additions inside files, weakening, renames/deletions and edits invalidate listed bindings. This is not proof that a proposer listed every relevant file, that a reviewer is authorized, or that a candidate did not change the verifier. No record is accepted as trusted admission; semantic correctness is assessed separately from shape/digest validation.

A mandatory system would need an authenticated reviewer principal independent of the proposer; approval bound to the change set and complete relevant-content manifest; a verifier revision supplied from trusted protected configuration, not candidate code; and an expected check producer required on **development**. Missing/forged/self/stale/malformed approval or verifier changes must refuse until independently reviewed; intentional operator overrides must be authenticated, scoped, visible and retained. Current same-account model signatures and locally supplied records meet none of those authentication requirements. Unavailable authority therefore fails the rollout decision, not ordinary repository test execution.

Live policy read-back returned `development` unprotected (HTTP404) and an empty ruleset list. No settings were changed. Rollback of the pilot is simply stopping the opt-in command; rollback of coverage/routing changes is a reviewed revert retaining the previous safety gates.

## Decisions

**Coverage: GO for these measured repairs and the small GH567 maintenance simplification.** Retain all three retirement policy suites, reject duplicate GH534 scheduling, and add only the demonstrated hook gap. An optimal total test count cannot be inferred; 418 shell registrations is the resulting implementation, not a target or recommended permanent cap.

**Mandatory admission: NO-GO.** There is no independently authenticated approval source or required trusted verifier on development. Continue observe mode if useful; do not sell valid JSON as “all new tests approved.” Broad enforcement, automatic deletion, a database catalog migration and legacy backfill are deferred unless a later authorized design supplies the missing authority and demonstrates net value.

Final QA round 1 rejected a missing Node summary contribution and unintended tier-2 Flightdeck selection. Both are repaired; the controlled runner now exercises the actual summary for tier2/tier3 and child rc0/7, and removing the Node total makes it red. Final full gate: **422/422 PASS** at `9625367f82ec2c39d9fc1cbec55ef0b2d3551628`, pre-push GREEN in 687s (691.167s including push), clone identity unchanged. The branch was pushed through the gate, with no bypass. [PR #811](https://github.com/HiQS-Labs/XYZ-forge/pull/811) targets development and is mergeable. The blocking [hosted smoke check](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36092283596/job/107937038509) passed for head 73e31244; hosted macOS promotion and Ubuntu canary jobs were skipped by their configured conditions. This local parallel run is not promotion evidence.

## Full-gate findings and bounded corrections

The first pre-push gate at 50adf9c0 ran 705.347 seconds and returned **419/422**, with matching pre/post clone identity. The local push was refused. Two failures belong to this change: the path scanner rejects fictional `test/example.sh` literals, and the route suite count still expected 24 rather than the intended 28. The repairs use a real inert hook payload path and update that count without weakening either check.

The third failure, gh390, reproduces on unmodified base 0ae3452a with intact identity. Diagnostic-only output capture shows `fixture safety ceiling reached before the guard fired`, exit 1 after 1s, peak observed RSS 2 MB: the fast bounded MagicMock fixture can finish between one-second polls. Its simple amendment holds the existing 500,000-call allocation for two pinned polling intervals before the same failure exit; it does not raise the allocation limit or change the production guard. Focused verification includes disabling the p7 guard to prove the fixture still fails when protection is absent. This adds one existing-test repair, not a new suite; final relay round 3 reviews it.

## Final verification

Final Codex relay round 3 approved the bounded amendments before the final full gate. The full gate returned 422/422 with no failures; raw telemetry and pre/post identity are in `final-gate/`. No suite was removed or quarantined to obtain green. The first 419/422 run remains under `full-attempt-1/`. Final implementation head is 9625367f; subsequent commits contain evidence/status only and use the normal documentation push gate.

## Handoff

Completion audit correction: the bounded implementation is verified, but the full issue is incomplete. Comprehensive inventory, representative value analysis, enforceable admission and broader synthesis remain outstanding. PR #811 remains open and unmerged. Coverage repair is GO; mandatory admission is NO-GO for the documented missing authority, with observe mode retained. The task clone is retained for `/merge-cleanup` only after its landing is verified. GH808 remains separate; no savings are attributed to it.


## Enforced gateway continuation — not yet activated

The operator requested finishing enforcement and selected human coverage approval. The continuation extends the inventory CLI with `admission prepare/check/publish/catalog`, complete Git-manifest binding, early push refusal, a trusted-base hosted checker, and bot PR publication. It adds zero registered suites; gh419, gh740 and gh421 carry the bounded regression controls. Native CODEOWNER review and separate agent credentials are the intended authority; generated metadata is never approval.

At c91cdf31, gateway controls passed in about 1.1s. Deliberately replacing the complete-manifest equality condition with false, removing the same-author rejection, and disabling early hook refusal each made gh419 return rc1; restoring saved bytes returned green. The committed `gateway-focused/provenance.jsonl` retains those runs. Protected publisher passed in 3.2s and workflow/reconciliation controls passed in 1.7s after updating the report-step expectation to skip pending operator review. The nonexistent gh487 standalone filename produced rc127 and is retained as an invocation error; GH487 behavior resides in gh544, which passed. No result from that mistyped invocation is counted as verification.

The API reports development unprotected, no rulesets, read-only default workflow tokens, and Actions PR creation disabled. Existing #811 is authored by the operator account. Implementation cannot itself prove human-only approval while agents retain that account's review/admin credentials. The activation runbook names bootstrap landing, credential separation, native review policy, bot-created/updated exact-head checks and protected reconciliation witnesses. None is declared active by local tests. Broader #805 representative value-analysis work remains open.


Final gateway Codex review round 2 approved 164a2a0a. Review corrections require a packet for executable documentation on either side of a change, and make bot CI dispatch `publication_only=true`: blocking smoke remains, while advisory full canary and deliberate-full concurrency are separated. Both controls have witnessed reds and focused greens. The gateway check itself had a 0.088s median across five local observations; this excludes human review latency. The fresh-clone hook initially reported not installed; installation and subsequent check passed before any push. The final macOS gate is next; historical 422/422 is not substituted for it.


Gateway record concurrency correction (3c9506c3): four focused suites pass with unchanged clone identity; receipts are in `gateway-record-focused/`. The real Git control conflicts on the old shared filename and merges distinct records cleanly. Final relay reopened for its third and last round; the in-flight full run at 2f75a185 is intermediate evidence, not verification of this later change.


Full gateway run at `2f75a185` failed **421/422** after 755.6 seconds with unchanged clone identity; push was refused. `gh777-inventory-ratchet.sh` rejected the newly introduced `coverage_admission.py`. Full receipts and telemetry are in `gateway-intermediate-full/`. The correction folds that implementation into the existing `gate_inventory.py` admission subcommand and updates its imports, with no baseline exception or new utility file. Four focused checks pass on the retained candidate patch (`gateway-ratchet-focused/`), including the ratchet's growth-rejection control. Round 3 approved the preceding record-format revision; it does not attest this subsequent relocation. Additional final QA awaits the requested operator exception to the three-round cap. No final full-green or live activation is claimed.
