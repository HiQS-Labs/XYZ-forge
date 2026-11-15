# RELAY · GH-1479 typed swarm-preflight modernization plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
