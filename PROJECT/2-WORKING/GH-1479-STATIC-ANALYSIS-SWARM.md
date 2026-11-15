---
gh_issue: 1479
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1479
title: "refactor: add Python static analysis and decompose swarm-preflight main"
status: Blocked — plan relay attempt cap (2-WORKING)
created: 2026-11-14
updated: 2026-11-14
owner: noelsaw
goal: >
  Establish a reproducible typed Python baseline and decompose swarm-preflight's giant entry point
  without changing its CLI, artifacts, state transitions, or exit codes.
doc_type: bugfix
branch: feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14
complexity: 3
risk: 3
effort: 3
phases: 5
---

# GH-1479 — static analysis and swarm-preflight decomposition

## Status

| What was just completed | What's next |
|---|---|
| Codex plan round 1 returned FAIL; all four findings and the count nit were dispositioned and committed. Baseline suites passed in a disposable clone. Round 2 is blocked by the two-attempt lane cap after one completed review and one failed re-dispatch. | Operator decides whether to authorize one forced Codex round 2 or hold the task. No accepted-start or production edit has occurred. |

## Acceptance capture

- Split the 734-line `main()` into named input, repository-state, probe/evaluation, and emission stages with typed context passed explicitly.
- Annotate module function contracts, using explicit `Any` only at dynamic JSON boundaries.
- Add one dependency manifest and mypy configuration, then invoke the scoped check through the existing validation path. No new test file, suite, or registry entry.
- Existing preflight and parity suites pass; main and adjacent smoke paths are equivalent to the pre-change behavior; scoped mypy has a witnessed failing red control.
- Do not touch the active `marathon_drive.py`, `merge_cleanup.py`, or `releases_app.py` lanes.

## Modernization arc

This is the first implementation group and the shared arc tracker. Later groups execute serially:

- #1480 — merge-cleanup entry point and landing loop after #1475.
- #1481 — marathon-drive main after #1467.
- #1482 — releases_app boundaries after #1471.
- #1483 — Jog and wave-reconcile entry points after the pattern is established.

Static-analysis scope expands one typed module at a time. The arc does not promise whole-repository strict typing or retirement of the Bash twins in this change.

## Rating — 2026-11-14: `75/60/50/55` (pri/sev/appeal/effort)

The operator selected this modernization directly, raising priority. Severity reflects recurring maintenance risk rather than a current outage. Appeal is neutral. Effort is moderate: one executor plus a new typed baseline. Recurrence evidence is repeated executor repairs and large-function review burden in the last 14 days, not a claim of rising production incidents; the preceding 14-day window was not audited, so the trend is unknown.

## Recon

Base `5967bde25` (`origin/development`). `utils/py/swarm_preflight.py:1206-1939` is a 734-line `main()`. The module has 42 module-level function definitions, 47 including nested helpers. Its stages are currently interleaved: CLI parsing and source selection; contract loading/merge; git freshness inspection; detached-ref probe evaluation; acceptance/source/gate checks; normalized candidate construction; text/JSON emission; and packet writing.

The existing helpers remain the implementation to reuse, including `extract_contract`, `merge_contracts`, `eval_probes`, `expand_effective_artifacts`, `check_acceptance_fidelity`, `check_source_url`, `lane_plan`, `normalize`, and `build_marathon_invocation_artifact`. No new executor or producer is needed. Observable writes are git fetch/worktree add/remove/prune, stdout/stderr and `SystemExit`, plus `run-candidate.json`, `lane-plan.json`, `freshness.json`, `readiness.json`, `marathon-invocation.txt`, `marathon-invocation.json`, and `packet.md`. Preserve their order, shapes, and exit codes.

The static-analysis seam is `test/test_python_layer.py:44-46` (`test_swarm_preflight_module_load`), already run by the existing Python layer. Extending that existing check with a scoped mypy invocation adds no test function, file, suite, registry entry, or new runner. Use `sys.executable`, `cwd=REPO_ROOT`, and an explicit config path. `follow_imports=skip` keeps imported `harness_paths` outside the scoped analysis. The existing CI dependency steps are `.github/workflows/ci.yml:184,402` and `.github/workflows/wave-reconcile.yml:52`; local toolchain guidance is `README.md:285` and `ROUTER.md:35`. The gate requires Python >=3.10, so the typed syntax and mypy configuration will target 3.10 rather than claiming older-runtime compatibility.

Open-lane constraints: PR #1467 touches `marathon_drive.py`; PR #1471 touches `releases_app.py`; #1475 owns active `merge_cleanup.py` remediation. They are excluded. `jog_run.py`/`wave_reconcile.py` belong to later #1483, not this PR.

Recorded baseline under `TESTS-RESULTS/2026-11-14+GH-1479/`: fixed-clock ready JSON dry run exit 0, actual text packet generation exit 0, and unknown-argument exit 2. The baseline includes the generated packet, structured invocation, and exact input `preflight-main.md`; replay uses that retained document instead of the ignored `temp/` original. A first fixture revision was rejected STALE exit 4 because its probe said the work was already landed; that was a fixture correction, not a product change or a passing smoke claim.

**Pre-existing conformance exception:** `MACHINE-CONTRACTS.md` states an atomic-write common rule, but the packet files and structured invocation are currently written directly with `open(..., "w")` at `swarm_preflight.py:1776-1780,1786-1788,1931-1932`. This PR preserves that existing behavior and does **not** claim the current implementation satisfies atomic publication. Repair is a separately scoped decision and must not be silently included in the refactor.

## Preflight bet check

- **Outcome sought:** make the preflight executor understandable and mechanically type-checked so later executor refactors are safer; not modernization for its own sake.
- **Smallest viable bet:** one typed module, one scoped mypy configuration, one existing Python-layer check, and behavior-preserving stage extraction.
- **Alternatives rejected:** whole-repository strict typing or a multi-executor rewrite is too broad and collides with active lanes. Annotation alone leaves the 734-line control flow intact. Pyright would add a second toolchain idiom without benefit over Python-native mypy for this gate. Atomic-write repair is excluded because it changes observable publication behavior.
- **Rollback/containment:** revert the ordered commits; no DB schema, artifact schema, production state, or deployment migration is involved. The work is **Costly** in review size but cleanly reversible, with no one-way state.

## Plan

Non-goals: whole-repository typing; changing CLI output, exit behavior, network calls, packet contents, or machine contracts; retiring Bash twins; touching the other executor lanes; atomic-write repair; new test functions/files/suites/registry entries; speculative abstractions, formatters, or unrelated cleanup.

### Stage-owned interfaces

Use three small, immutable dataclasses, not one mutable context:

- `SourceSelection`: input mode, ordered source docs/issues, primary doc, slug, root/drive paths, and fixed timestamps. Produced by CLI/source resolution.
- `RepositoryState`: branch/commit/upstream divergence, fetch and dirty state, suggested branch state, ref/commit comparison, detached-ref probe results, missing/frozen artifacts, and stale-lock fields. Produced by repository inspection; no readiness decisions move here.
- `CandidateEvaluation`: candidate state, gate and expanded artifact presentation, acceptance/source checks, ready/next-action, lane plan, and normalized-candidate inputs. Produced by readiness evaluation in the existing first-failure order.

`main()` only sequences source resolution → contract loading → repository inspection → candidate evaluation → normalization → reporting → packet writing. Each stage receives only named inputs and returns its owned record. Dynamic JSON stays `dict[str, Any]` at the boundary; do not use `locals()`, `vars()`, `**kwargs` pass-through, a mutable bag of former locals, or a global context. Record the final stage signatures in the implementation receipt so review can see the bounded producer/consumer flow.

1. After Approved plan QA, admit `rmi-01M7EXKTPVA9WHVFTMCVR6QRS9` with `roadmap update --accepted-start`. Add Python 3.10-compatible annotations and the three records above. Use explicit `Any` only for dynamic JSON/dict payloads and existing subprocess boundaries. -> expect an AST inventory to show every module function annotated and no `locals()`/`vars()` state forwarding.
2. Extract the stages while preserving every early `SystemExit`, readiness precedence, side effect, and existing helper. Keep `main()` below 100 lines and make each extracted stage own only its named responsibility; do not relocate the monolith into one evaluation function. -> expect the final signature inventory and bodies to demonstrate bounded dependencies.
3. Add `mypy.ini` scoped to this module with `disallow_untyped_defs`, `disallow_incomplete_defs`, `check_untyped_defs`, `strict_optional`, `no_implicit_optional`, `follow_imports=skip`, and unused-ignore/redundant-cast warnings. Add `requirements-dev.txt` with the existing gate dependencies plus `mypy==1.14.1`, and point the three hosted install steps and local setup docs at it. Extend the existing module-load check to run `sys.executable -m mypy --config-file <absolute-repo-config>` with `cwd=REPO_ROOT`; missing mypy must fail with actionable output. -> expect the scoped check to pass without adding test/gate machinery or widening into `harness_paths`.
4. In a separate disposable full clone, with repository identity checked before/after, run focused existing checks during implementation: `bash test/swarm-preflight.sh`, `bash test/gh322-unknown-arg-rejection.sh`, `bash test/gh308-swarm-gate-path.sh`, `bash test/gh291-contract-goldens.sh`, and the repo's existing test-venv `python3 -m pytest test/test_python_layer.py`. Preserve the logs. -> expect no regressions; do not run these commands in the task clone or rerun the full gate between review rounds.
5. Repeat the fixed-clock ready JSON, actual packet, and unknown-argument smoke paths using the retained `preflight-main.md`, fixed `SWARM_PREFLIGHT_NOW/TODAY`, the same explicit `--out`, and the same target ref. Compare output, exit codes, and generated artifacts against the baseline. Allow only individually recorded substitutions for the checkout root prefix, provenance/ref SHAs, `checkout_matches_ref`, `head_behind_ref`, and dirty state that actually changed; every substitution must name its old/new value and cause. Do not normalize candidate state, probes, readiness, acceptance, lane plan, gate/artifact content, invocation, or packet semantics. Exercise the adjacent vendored contract path through the existing golden coverage. -> expect semantic equivalence and nonempty artifacts.
6. Witness static-analysis rejection by running the same scoped mypy configuration against a temporary mutated copy containing a deliberate return-type error, leaving the source untouched. -> expect a nonempty type error and nonzero mypy exit; the unmodified source passes.
7. Update receipts, CHANGELOG, and the plan. Run the final classified full gate exactly once in a separate disposable full clone at the approved commit, with repository identity checked before/after, then run Codex final QA. -> expect full gate green, PDDA checks clean, and Approved final QA before push/PR.

## Acceptance map and red controls

- **Typed contracts:** every function is annotated; scoped mypy passes. Red control: the deliberate temporary return-type error fails.
- **Bounded decomposition:** `main()` is below 100 lines, the three records have named producers, and no `locals()`/`vars()` or ever-growing mutable context forwards state. Red control: the baseline AST measurement records the former 734-line function; the final stage-signature inventory exposes any relocated monolith.
- **Behavior preservation:** existing focused suites and main/adjacent smoke comparisons pass. Red control: the exact replay input and pre-change exits/artifacts are committed before implementation; any semantic diff outside the enumerated substitutions is a failure.
- **Commensurate scope:** no new test file/function/registry entry and no changes to the active executor lanes or packet-write mechanism. Red control: inspect the final diff and route its actual changed paths.

## Plan QA — round 1 dispositions

- **S1, replay input and comparisons — Implemented.** Retained the exact input document and fixed replay environment; enumerated permitted substitutions instead of blanket freshness normalization.
- **S2, relocated-monolith risk — Implemented.** Defined three stage-owned records, their producer/consumer flow, and explicit prohibitions; final signatures are review evidence.
- **S3, verification isolation — Implemented.** Every shell/pytest verification run, not only the final gate, is assigned to a disposable full clone with identity brackets.
- **S4, atomic-write mismatch — Modified.** Recorded the current direct-write behavior as a known pre-existing conformance exception. No repair or atomicity claim is in scope.
- **N1, function count — Implemented.** Corrected to 42 module-level definitions, 47 including nested helpers.

## Plan relay blocker — 2026-11-14

The first driver attempt completed Codex round 1 (`FAIL`), then escalated when the producer token did not advance. A second invocation attempted to open round 2 without first claiming the token and failed before dispatch; it nevertheless consumed the lane's second attempt. The corrected third invocation was refused by `lane-attempt-cap` at 2/2. No `--force`, new token, history reset, or accepted-start was used. Resume only with an explicit operator decision to authorize one forced Codex round 2 or to hold the task.

NO_ENTRY for lessons: plan review is unfinished and the block is coordination-specific; no implementation effect exists to grade.
