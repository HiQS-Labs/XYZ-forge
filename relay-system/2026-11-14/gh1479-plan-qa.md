# RELAY · GH-1479 typed swarm-preflight modernization plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1479-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-1479-STATIC-ANALYSIS-SWARM.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14

### Artifact — GH-1479-STATIC-ANALYSIS-SWARM.md
```
---
gh_issue: 1479
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1479
title: "refactor: add Python static analysis and decompose swarm-preflight main"
status: Active — recon and plan QA (2-WORKING)
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
| Recon and surgical plan recorded with baseline exits 0/0/2, typed static-analysis seam, non-goals, rollback, and red controls; rating persisted on `rmi-01M7EXKTPVA9WHVFTMCVR6QRS9`. | Run independent Codex plan QA; no production edit or accepted-start admission before approval. |

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

Base `5967bde25` (`origin/development`). `utils/py/swarm_preflight.py:1206-1939` is a 734-line `main()` with 47 module functions. Its stages are currently interleaved: CLI parsing and source selection; contract loading/merge; git freshness inspection; detached-ref probe evaluation; acceptance/source/gate checks; normalized candidate construction; text/JSON emission; and packet writing.

The existing helpers remain the implementation to reuse, including `extract_contract`, `merge_contracts`, `eval_probes`, `expand_effective_artifacts`, `check_acceptance_fidelity`, `check_source_url`, `lane_plan`, `normalize`, and `build_marathon_invocation_artifact`. No new executor or producer is needed. Observable writes are git fetch/worktree add/remove/prune, stdout/stderr and `SystemExit`, plus `run-candidate.json`, `lane-plan.json`, `freshness.json`, `readiness.json`, `marathon-invocation.txt`, `marathon-invocation.json`, and `packet.md`. Preserve their order, shapes, and exit codes.

The static-analysis seam is `test/test_python_layer.py:44-46` (`test_swarm_preflight_module_load`), already run by the existing Python layer. Extending that existing check with a scoped mypy invocation adds no test function, file, suite, registry entry, or new runner. The existing CI dependency steps are `.github/workflows/ci.yml:184,402` and `.github/workflows/wave-reconcile.yml:52`; local toolchain guidance is `README.md:285` and `ROUTER.md:35`. The gate requires Python >=3.10, so the typed syntax and mypy configuration will target 3.10 rather than claiming older-runtime compatibility.

Open-lane constraints: PR #1467 touches `marathon_drive.py`; PR #1471 touches `releases_app.py`; #1475 owns active `merge_cleanup.py` remediation. They are excluded. `jog_run.py`/`wave_reconcile.py` belong to later #1483, not this PR.

Recorded baseline under `TESTS-RESULTS/2026-11-14+GH-1479/`: fixed-clock ready JSON dry run exit 0, actual text packet generation exit 0, and unknown-argument exit 2. The baseline includes the generated packet and structured invocation. A first fixture revision was rejected STALE exit 4 because its probe said the work was already landed; that was a fixture correction, not a product change or a passing smoke claim.

## Preflight bet check

- **Outcome sought:** make the preflight executor understandable and mechanically type-checked so later executor refactors are safer; not modernization for its own sake.
- **Smallest viable bet:** one typed module, one scoped mypy configuration, one existing Python-layer check, and behavior-preserving stage extraction.
- **Alternatives rejected:** whole-repository strict typing or a multi-executor rewrite is too broad and collides with active lanes. Annotation alone leaves the 734-line control flow intact. Pyright would add a second toolchain idiom without benefit over Python-native mypy for this gate.
- **Rollback/containment:** revert the ordered commits; no DB schema, artifact schema, production state, or deployment migration is involved. The work is **Costly** in review size but cleanly reversible, with no one-way state.

## Plan

Non-goals: whole-repository typing; changing CLI output, exit behavior, network calls, packet contents, or machine contracts; retiring Bash twins; touching the other executor lanes; new test functions/files/suites/registry entries; speculative abstractions, formatters, or unrelated cleanup.

1. After Approved plan QA, admit `rmi-01M7EXKTPVA9WHVFTMCVR6QRS9` with `roadmap update --accepted-start`. Add Python 3.10-compatible annotations and small dataclasses for repository inspection and candidate evaluation. Use explicit `Any` only for dynamic JSON/dict payloads and existing subprocess boundaries. -> expect an AST inventory to show every module function annotated.
2. Extract `main()` in coherent stages: CLI/source resolution; contract loading; repository inspection; readiness evaluation; normalized candidate construction; report emission; and packet writing. Keep `main()` as a short orchestration function and preserve all existing helpers and observable ordering. -> expect `main()` below 100 lines and no single extracted stage with the former 734-line control flow.
3. Add `mypy.ini` scoped to this module with `disallow_untyped_defs`, `disallow_incomplete_defs`, `check_untyped_defs`, `strict_optional`, `no_implicit_optional`, and unused-ignore/redundant-cast warnings. Add `requirements-dev.txt` with the existing gate dependencies plus `mypy==1.14.1`, and point the three hosted install steps and local setup docs at it. Extend the existing module-load check to run `python3 -m mypy --config-file mypy.ini`; missing mypy must fail with the tool's actionable output. -> expect the scoped check to pass without adding test/gate machinery.
4. Run focused existing checks during implementation: `bash test/swarm-preflight.sh`, `bash test/gh322-unknown-arg-rejection.sh`, `bash test/gh308-swarm-gate-path.sh`, `bash test/gh291-contract-goldens.sh`, and `python3 -m pytest test/test_python_layer.py`. -> expect no regressions; do not run the full gate between review rounds.
5. Repeat the fixed-clock ready JSON, actual packet, and unknown-argument smoke paths. Compare output, exit codes, and generated artifacts against the recorded baseline, allowing only provenance SHAs and expected branch/freshness changes. Exercise the adjacent vendored contract path through the existing golden coverage. -> expect semantic equivalence and nonempty artifacts.
6. Witness static-analysis rejection by running the same scoped mypy configuration against a temporary mutated copy containing a deliberate return-type error, leaving the source untouched. -> expect a nonempty type error and nonzero mypy exit; the unmodified source passes.
7. Update receipts, CHANGELOG, and the plan. Run the final classified full gate exactly once in a separate disposable full clone at the approved commit, with repository identity checked before/after, then run Codex final QA. -> expect full gate green, PDDA checks clean, and Approved final QA before push/PR.

## Acceptance map and red controls

- **Typed contracts:** every function is annotated; scoped mypy passes. Red control: the deliberate temporary return-type error fails.
- **Decomposition:** `main()` is below 100 lines and only sequences typed stages. Red control: the baseline AST measurement records the former 734-line function.
- **Behavior preservation:** existing focused suites and main/adjacent smoke comparisons pass. Red control: the pre-change baseline exits and artifacts are committed before implementation; a semantic diff is a failure, not something to normalize away.
- **Commensurate scope:** no new test file/function/registry entry and no changes to the active executor lanes. Red control: inspect the final diff and route its actual changed paths.
```
## Review packet

**Operational envelope:** a local, single-operator Python CLI and its existing validation path. Grade against the embedded plan and commensurate complexity, not an enterprise service or an unrequested whole-repository modernization. The explicit goal is behavior-preserving decomposition plus a scoped typed static-analysis baseline. XYZ-forge forbids new test suites (GH-831); do not request them.

### Step 1 — paraphrase first (artifact only, before reading any source file)

Under your review heading, write 2–5 sentences each for:
- **What this proposes**
- **How the existing system works, per this document**
- **What it's not** — distinguish excluded work, later phases, unresolved choices, and later authorization; label inference.

State the input boundary (`embedded artifact only`). Do this before the source-backed assessment. A material mismatch is a plan-clarity finding, not something to repair by inventing scope.

### Step 2 — source-backed assessment

Read these actual paths in the seeded checkout:
- `utils/py/swarm_preflight.py`, especially `main()` at `:1206-1939` and its existing helpers.
- `test/test_python_layer.py`, especially `test_swarm_preflight_module_load` at `:44-46`.
- `validate.sh:1438-1458` (existing Python layer).
- `.github/workflows/ci.yml:184,402` and `.github/workflows/wave-reconcile.yml:52` (dependency setup).
- `README.md:285` and `ROUTER.md:35` (toolchain guidance).
- `MACHINE-CONTRACTS.md` (output contracts that must not change).
- `TESTS-RESULTS/2026-11-14+GH-1479/` (baseline and provenance).

Answer with file:line evidence:
1. Are the problem, stages, existing writers, and state/output boundaries accurately traced? Does the plan preserve every CLI, packet, and exit-code contract?
2. Is this the smallest viable first group, and are the active-lane exclusions and non-goals correct? Does any hidden whole-repository or new-executor work appear?
3. Is mypy through the existing module-load check compliant with GH-831, or is it disguised new test/gate machinery? Are the dependency manifest and hosted/local setup changes sufficient and proportionate?
4. Will the proposed dataclasses and stage extraction reduce complexity, or merely move hundreds of lines into long argument lists and a god context? What concrete structural constraint prevents that?
5. Does every acceptance claim have a falsifiable observation and red control? What prevents an unchanged or behavior-breaking candidate from being reported as delivered? Are baseline normalizations narrow enough?
6. Are ratings grounded as maintenance work rather than a fabricated production incident, and is the rollback/blast-radius assessment adequate?
7. Sweep the touched pre-existing code for defects relevant to this refactor. Name any that must change the plan; do not invent unrelated follow-up work or request new tests.

- Definition of Done: the plan is Approved only if its first group is correctly scoped, its decomposition and static-analysis approach are implementable without behavior or contract drift, GH-831 is respected, dependencies are reproducible, and every acceptance claim has an observable check and red control.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Input boundary: embedded artifact only.

**What this proposes:** Establish a scoped typed baseline for `swarm_preflight.py` and split its large `main()` into explicit stages. Reuse the existing Python-layer check and add a pinned development dependency manifest, preserving behavior.

**How the existing system works, per this document:** Existing helpers implement contracts, probes, normalization, and invocation construction, while `main()` interleaves their orchestration with repository inspection and emission. The CLI writes reports and packets and can mutate git state through fetch/worktree operations; recorded smoke baselines cover ready JSON, packet generation, and invalid arguments.

**What it's not:** Other executor lanes, whole-repository typing, Bash retirement, new test functions, and output changes are excluded. Later issue groups are serial follow-ups; implementation admission and final delivery remain subsequent steps. Inference: the proposed stage dataclasses are intended to carry bounded stage results rather than one mutable global context, but the artifact has not yet made that constraint explicit.

**VERDICT: FAIL**
**Basis:** The first group is appropriately bounded, but the baseline replay, structural acceptance, and verification isolation need concrete corrections before implementation admission.

swept file: yes

- [Pass] The proposed stage sequence matches the current entry point: CLI/source resolution (`utils/py/swarm_preflight.py:1206-1290`), contract handling (`:1292-1323`), repository/ref inspection and probes (`:1330-1432`), readiness (`:1516-1641`), normalization (`:1649-1688`), reporting and exit precedence (`:1690-1753`), and packet emission (`:1775-1939`). Keep the early exits and first-failure readiness ordering in their present positions; a refactor must preserve more than the final success packet.
- [Pass] Extending the existing module check is proportionate and fits the stated GH-831 allowance: `test/test_python_layer.py:44-46` already owns module validation and `validate.sh:1438-1458` already invokes that file. This does add a static-analysis obligation, but does not require a parallel runner, suite, or registry. Hosted dependency setup exists at the three cited workflow install steps, and `README.md:285` already requires Python >=3.10. Use the running interpreter (`sys.executable`) and an explicit repository working directory/config path when invoking mypy. Implementation must demonstrate that imported untyped `harness_paths` does not accidentally widen the checking scope.
- [Should] Make the baseline replay self-contained and comparisons field-specific. `TESTS-RESULTS/2026-11-14+GH-1479/provenance.jsonl:1-2` reference `temp/gh1479/preflight-main.md`, which is absent in this seeded checkout. The retained JSON contains a contract but not the source document's frontmatter, acceptance text, or complete replay environment. Plan step 5 permits unspecified “expected branch/freshness changes”; that could hide a regression in the very repository-state stage being extracted. Retain the exact input document or a complete deterministic reconstruction recipe with the existing evidence, and enumerate permitted path/SHA substitutions and individually justified freshness fields; assert all remaining output and artifacts unchanged. No new test file is needed.
  Observed input: the two provenance commands use `--project-doc temp/gh1479/preflight-main.md`; the read-only probe below reports `baseline_input_exists False`.
  Affected scope: replay of these recorded ready JSON and packet baselines in a clean disposable clone.
  Falsifier: a documented reconstruction using retained inputs produces the baseline's semantic output and packet at the base revision; each changed freshness field is individually explained rather than blanket-normalized.
- [Should] Add an observable structural constraint beyond `main() <100 lines`. Plan step 2's “no single extracted stage with the former 734-line control flow” permits a 600-line evaluation stage or a dataclass containing virtually every former local. Define stage-owned result records, their producer/consumer flow, and prohibit passing `locals()`, an unrestricted bag of stage state, or an ever-growing mutable context through every stage. Review the final stage signatures and bodies for distinct responsibilities and bounded dependencies; a small signature inventory in existing receipts is sufficient, without a new gate or arbitrary universal line limit.
  Observed input: plan steps 1-2 name dataclasses only for “repository inspection and candidate evaluation,” while the current normalization bridge alone consumes dozens of independent values (`utils/py/swarm_preflight.py:1649-1685`). No proposed record ownership or stage interfaces are specified.
  Affected scope: new stage interfaces and dataclasses in this one module.
  Falsifier: an explicit stage/data-flow sketch and final signatures show each stage receives only its required inputs and returns a bounded result; `main()` is short without relocating the original monolith.
- [Should] Explicitly put step 4's focused shell suites and pytest invocation in a separate disposable full clone too. Step 7 assigns that isolation only to the final full gate, leaving the earlier imperative commands unsafe to follow from the implementation checkout. The actual preflight worktree operations (`utils/py/swarm_preflight.py:1405-1432`) illustrate why a linked worktree does not contain Git metadata mutations. Apply the existing repository identity before/after checks to those clone runs; do not request an unsandboxed run from this reviewer window.
  Observed input: step 4 directly says to run `bash test/swarm-preflight.sh` and four other checks “during implementation”; only step 7 specifies a disposable full clone.
  Affected scope: all mutation-heavy verification commands in this plan.
  Falsifier: the revised execution instructions place every listed shell/pytest run in disposable full-clone isolation with preserved evidence and identity checks.
- [Should] Disposition the existing atomic-write contract mismatch before promising preservation of every output contract. `MACHINE-CONTRACTS.md`, Common rules, says “Artifacts land via write-temp-then-`os.replace`”; the structured invocation is instead opened directly with `"w"` at `utils/py/swarm_preflight.py:1786-1788`, as are other packet files at `:1776-1780`. A reader can see a partial invocation during emission. For this behavior-preserving refactor, explicitly identify preservation of current write behavior as a known unresolved conformance exception, or obtain a separately scoped decision to repair it; do not silently change writes or claim existing implementation already satisfies atomic publication.
  Observed input: `with open(os.path.join(out_dir, "marathon-invocation.json"), "w")` followed by `json.dump(...)` (`:1786-1787`).
  Affected scope: concurrent readers of the structured invocation while its single producer writes it.
  Falsifier: source shows temporary-file publication followed by replacement, or the authoritative contract explicitly exempts this artifact. Neither appears in the reviewed sources.
- [Pass] Lane exclusions and non-goals stay surgical: the artifact explicitly excludes `marathon_drive.py`, `merge_cleanup.py`, `releases_app.py`, and later Jog/wave refactors. Its rating paragraph explicitly says “maintenance risk rather than a current outage” and “the trend is unknown”; no fabricated incident trend is needed. Ordered-commit rollback is adequate for the stated absence of schema migration; the proposed shared validation/dependency changes also affect users running the Python layer, not only preflight users.
- [Pass] Read-only baseline integrity probe: command `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` parsed the source with `ast`, inspected baseline input existence, recomputed each provenance log's SHA-256, and read the retained `.rc` files. Exit 0; decisive output: `module_functions 42 main_lines 734`, `baseline_input_exists False`, all three logs `nonempty True hash_matches True`, and baseline exits `0, 0, 2`. The document's 47-function count includes nested helpers rather than 47 module-level definitions; clarify that wording as a nit. Evidence paths: `utils/py/swarm_preflight.py:1206-1939` and `TESTS-RESULTS/2026-11-14+GH-1479/provenance.jsonl:1-3`.

Source sweep covered the whole preflight module and the named validation/dependency/contract surfaces. The atomic-publication mismatch above is the pre-existing defect that requires an explicit plan disposition; no unrelated repair is requested. No suites or executable fixtures ran here. Runtime equivalence, mypy acceptance/red control, and full-gate success remain **[Unverified — needs clone run]** until implementation. The graph lookup was denied by tool approval policy, so assessment used direct source reads.

Handing off to Producer (claude-a) — address each Should, revise the embedded plan, and open round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1 · claude-a

Every finding was checked against the cited source before disposition. No production code changed.

- **S1, replay input and comparisons — Implemented.** The exact `preflight-main.md` is retained under `TESTS-RESULTS/2026-11-14+GH-1479/`. The revised plan fixes the replay environment and enumerates every permitted substitution instead of allowing generic freshness changes.
- **S2, relocated-monolith risk — Implemented.** The revised plan defines `SourceSelection`, `RepositoryState`, and `CandidateEvaluation`, their producers and consumers, and explicitly forbids `locals()`, `vars()`, `**kwargs` pass-through, and a mutable bag of former locals. Final stage signatures are required evidence.
- **S3, verification isolation — Implemented.** Every shell/pytest run is now assigned to a separate disposable full clone with identity brackets and retained logs.
- **S4, atomic-write mismatch — Modified.** The direct-write behavior is documented as a known pre-existing conformance exception. This behavior-preserving PR makes no atomicity claim and does not expand into a publication repair.
- **N1, function count — Implemented.** Corrected to 42 module-level definitions, 47 including nested helpers.

The revised plan below replaces the embedded artifact for round 2. `follow_imports=skip` was also added to keep the mypy scope from expanding into `harness_paths`, and the test invocation now names `sys.executable`, `cwd=REPO_ROOT`, and the absolute config path.

````markdown
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
````

Questions for round 2: are S1–S4 and N1 resolved as dispositioned; does the stage-owned data flow prevent a relocated monolith; is the direct-write exception explicit enough; is the plan now suitable for implementation without new scope?

handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
