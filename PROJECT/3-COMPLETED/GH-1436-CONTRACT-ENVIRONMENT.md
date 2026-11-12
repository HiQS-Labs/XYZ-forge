---
gh_issue: 1436
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1436
title: Malformed contracts must not halt unrelated reconciliation
status: Complete
created: 2026-11-12
updated: 2026-11-12
owner: Codex
goal: Fix the reported contract and environment failure using existing validation owners.
---

# GH-1436 — Malformed contracts must not halt unrelated reconciliation

## Status

| What was just completed | What's next |
|---|---|
| Implementation, independent QA and full qualification passed (408/408). | Publish one shared PR; the issue closeout comments record its URL and final head. |

## Symptom

Landing PR #1431 with merge-cleanup (2026-11-12): the merge succeeded (`f8ae7f899`), then post-merge `wave_reconcile --pr 1431` exited 6 and merge-cleanup stopped before the reconcile commit:

```text
File "utils/py/_marathon_plan.py", line 1200, in compute
    ref = (r["contract"].get("target") or {}).get("ref") or "HEAD"
AttributeError: 'str' object has no attribute 'get'
merge-cleanup: ERROR — PR #1431: post-merge reconciliation FAILED — stopping before the next PR
```

`compute()` evaluates **every** active capture doc, so one malformed Preflight Contract anywhere in `PROJECT/1-INBOX` / `2-WORKING` blocks reconciliation for every merged PR, not just its own.

## Observed

| Claim | Command | Observed |
|---|---|---|
| Crash reproduces in the primary | `python3 utils/py/wave_reconcile.py --pr 1431` at `f8ae7f899` | exit 6, same traceback, mutations rolled back |
| Only one doc is malformed | parse every `## Preflight Contract` JSON in 1-INBOX + 2-WORKING | one non-object `target`: `PROJECT/2-WORKING/GH-1427-CLAUDE-TURN-BUILDER-CEILING.md` (`"target": "utils/py/claude-turn.py"`) |
| The malformed field is the whole cause | disposable clone, `wave_reconcile --pr 1431 --dry-run`, unpatched vs `target` → `{"repo": ".", "ref": "development"}` | unpatched exit 6 (crash); patched exit 0 ("Wave reconciliation completed successfully") |
| Origin of the bad shape | #1427 issue body (filed 2026-11-11 from LTVera-Pandas) | contract hand-written with a string `target`; start-task copied it; plan QA approved it (the #1426 session's QA did catch the same mistake in its own doc) |

## Root cause

Root cause: `_marathon_plan.compute()` trusts the contract's shape (`target` must be a dict) without validating it, so malformed intake data becomes a crash in a shared, gating post-merge path. Fix site: contract validation in `_marathon_plan` (flag the row, e.g. `malformed-contract`, and skip shape-dependent probes) plus the intake writers/templates that let a string `target` through. Why not only fix the doc: the next hand-written or LLM-written contract with the same mistake halts every landing again.

## Acceptance

- [ ] A capture doc whose contract `target` is not an object (string, list, null) yields a flagged/warned row in marathon-plan output, and `wave_reconcile` completes for unrelated PRs. Red control: the GH-1427 doc as it stood at `f8ae7f899` → exit 6 today.
- [ ] The same validation covers the other shape-dependent fields read in `compute()` (`fix_probes`, `artifacts`).
- [ ] Intake (`/idea`, `file-xyz-bug`, `hq park --create`) or `pdda.sh` rejects or normalizes a non-object `target` at filing time, so the bad shape cannot land in a doc.
- [ ] Existing marathon-plan / wave-reconcile suites pass; evidence under `TESTS-RESULTS/` (no new suites, GH-831).

## Immediate remediation (done separately)

The GH-1427 doc's contract is corrected on `development` so #1431's reconciliation can finish; this issue tracks the harness hardening.

## PRS proposal

pri 70: a single bad doc blocks every post-merge reconcile and halts merge-cleanup mid-batch.
sev 65: no data loss (reconcile rolls back), but landings strand unreconciled until someone traces it.
appeal 50: neutral.
effort 70: a type guard plus a flag in one function, and a validation hook at intake.


## Shared implementation plan — GH-1436 and GH-1437

Base: `3ad3c0d88fb3d10a0e685b34544264143290f1e1`; one branch and one PR for both issues.

| Issue | Scope | Dependencies | Rating | State |
|---|---|---|---|---|
| #1436 | Planner contract shape and intake rejection | None | 70/65/50/70 | Final QA and full gate passed; PR publication |
| #1437 | Existing gate environment probe and documentation | None | 55/40/50/75 | Final QA and full gate passed; PR publication |

Clone/branch: `XYZ-forge-gh1436-contract-environment-2026-11-12` / `fix/XYZ-forge-gh1436-contract-environment-2026-11-12`. One shared PR; publication URL and final head are recorded in each issue's start-task closeout comment. #1437 retains its own capture and ledger row.

### Recon and bet

`_marathon_plan.Engine.compute()` calls `_zone_of` before inspecting contract types, then `_eval_probe` and target.ref/artifact path probes. `_unregistered_record` also dereferences incoming contracts. `swarm_preflight.extract_contract` owns existing validation but only checks container presence for probes/artifacts; it can itself dereference a non-object. `hq.sh cmd_park` creates GitHub issues and capture docs from the request body without validating a supplied contract.

`validate.sh` GH-732 checks only `import yaml`, emits a warning and continues. Its probe occurs before dispatching suites; the existing gh251 suite currently expects missing pytest to skip and missing yaml to warn. Those expectations must change with the requested behavior. No new suite/runner is required. Existing GH-732 summary tests cover PHP fault handling, which remains unchanged.

Outcome: malformed intake is held visibly without crashing unrelated landings; unsupported Python stops once with a concrete remedy before suites. Smallest viable bet: extend the existing preflight shape checks and existing environment-fault block, not a new schema or toolchain manager. Merely correcting GH-1427 or prepending PATH locally cannot prevent recurrence.

Blast radius: planner/readiness consumers, HQ park callers supplying a contract, and validate callers with unsuitable Python. No state schema or dispatch authority changes. Reversibility: Easy; revert the code commit, no data migration. Incorrectly broad validation could hold legacy partial contracts, so shape checks validate present fields rather than imposing all execution-required fields on planner/intake; extract_contract retains its existing required-field checks.

1. Add a small pure `contract_shape_error` helper in `swarm_preflight.py`, checking outer object and present target/ref/repo, probe objects and their string operands, artifact strings, and lanes path arrays before shape-dependent use. Reuse it in extract_contract, registered and unregistered planner input, and HQ park before external/file writes. Malformed planner rows use existing `needs-contract` state plus `malformed-contract` warning; no shape probes/writesets for those rows. -> strings/lists/null and malformed nested entries are held; healthy input unchanged.
2. Extend the existing GH-732 block to probe Python version and yaml/pytest/requests, report interpreter/version/missing modules on one ENVIRONMENT FAULT line and exit 3 before suites. Use the explicit PATH-prefix remedy rather than automatic interpreter selection. Document Python >=3.10 once in README at the gate-toolchain venv explanation. -> bad interpreters stop; healthy ones retain suite behavior.
3. Adapt only the existing gh251 absence assertions to the new contract. Record manual old-code red/new-code green malformed cases (including HQ no-write refusal) and environment controls under TESTS-RESULTS with provenance. Run existing marathon-plan, swarm-preflight, HQ intake, wave-reconcile, gh251, GH-732 suites in a separate disposable full clone. -> assertions discriminate the old defect and exercise neighboring healthy behavior.
4. Run final independent Codex QA, fix grounded findings, classify and run the required full push gate in isolation, commit evidence, publish one PR closing both issues, then verify exact head/base/checks and close out each issue. -> no merge performed.

### Boundaries and ratings

No new test files, registry entries, runners, dependencies, system Python installation, automatic venv creation, 3.9 compatibility rewrite, or unrelated doc cleanup. No new PDDA gate; HQ existing intake is the filing-time rejection boundary. No arbitrary issue probe commands executed during shape validation.

Ratings preserve issue proposals except #1437 appeal uses neutral 50 (the issue author's 55 is not an operator preference). #1436 blocks all reconciliation but rolls back safely; #1437 wastes full gates and confounds evidence, with no wrong-code landing reported. Recurrence window reviewed: 2026-10-29–11-12 versus 10-15–10-28; issue evidence names one malformed-doc incident and three agent sessions hitting the Python fault, not a proven rising trend. Related #1433/#1237/#1324 concern distinct Jog promotion/target paths and do not guard the observed compute dereference. Source remains vulnerable at the pinned base.

## Acceptance & Quality Checklist

- [x] Independent plan QA approved before implementation; [receipt](../../relay-system/2026-11-12/gh1436-plan.codex.md), reviewed 1a1a636d.
- [x] Both issues' focused acceptance checks reproduced and verified with committed provenance.
- [x] Final independent QA approved and required gate passes (408/408 at c48c940c).
- [ ] One PR targets development with both issue closeouts.

## Lessons Learned (For Future Agents)

NO_ENTRY: this bounded run supports the recorded fixes; no additional general lesson is asserted.

Plan QA nits: accepted partial-contract matrix addition. The reviewer read the actual committed plan path (seed mirror was absent), explicitly recorded that boundary, and the harness attested reviewed HEAD 1a1a636d; final QA will use --artifact-file correctly. Planner emits existing needs-contract finding with malformed-contract message/row flag so wave_reconcile retains attributable held-item semantics.

## Final review

Codex final QA Approved after two concrete findings and bounded repairs; [receipt](../../relay-system/2026-11-12/gh1436-final.codex.md), reviewed 9c506687. Existing focused suites and manual controls passed; [evidence](../../TESTS-RESULTS/2026-11-12+GH-1436-1437/SUMMARY.md). Full gate and PR publication remain pending. Edit verdicts: contract/helper/intake helped (discriminating controls); environment refusal helped; optional-null merge helped; documentation has no observed runtime effect.

Full qualification: 408/408 at c48c940c, [committed receipt](../../TESTS-RESULTS/2026-11-12+GH-1436-1437/provenance.jsonl). Final runtime code remains independently approved; the later mechanical assertion correction was outer-reviewed and rechecked, then covered by the full gate. Awaiting PR publication/merge; neither issue is closed by this branch yet.
