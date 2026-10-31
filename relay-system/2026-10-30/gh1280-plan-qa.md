# RELAY · GH-1280 plan QA: outer-loop ATE campaign
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 3 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1280-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md` (the plan).
  Requirements: GitHub issue https://github.com/HiQS-Labs/XYZ-forge/issues/1280 (run
  `gh issue view 1280 --repo HiQS-Labs/XYZ-forge` if reachable; the plan's "Acceptance
  criteria" list is transcribed from it in commit `eec2054d`).
- Source paths to check claims against: `utils/py/harness.py` (parser `:1311-1347`, run-root guard
  `:1302-1308`, `generate-manifest` `:784`, `init --from-prs` `:639-705`, tick tool spawn
  `:1078-1096`), `utils/py/gen4_campaign.py`, `utils/py/fuzz_engine.py`, `utils/py/adaptive_ate.py`,
  `utils/py/domain_oracles.py`, `utils/py/proc_group.py` (`run_bounded`),
  `TESTS-RESULTS/2026-10-28+GH-1248/controls-checkpoint2.jsonl`,
  `skills/4-occasional/ate/SKILL.md`, `skills/4-occasional/defect-campaign/SKILL.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Operational envelope: one supervised, local, single-host experiment on the operator's Mac Studio,
  using existing ATE/Gen 4 tools against an experimental CLI. Disposable clones only. No production
  code changes, no new tests or suites (GH-831), no new adapters. Grade against the issue's stated
  requirements and commensurate complexity, not enterprise or multi-tenant threat models.
- Definition of Done — answer each question with a `file:line` citation:
  1. Are the plan's recon claims about `harness.py`, `gen4_campaign.py`, `fuzz_engine.py` and
     `domain_oracles.py` correct (guards, refusal messages, clone/reset contract, absent
     no-new-signal stop, replay predicate)?
  2. Does the containment section (sanitized `PATH`/`HOME`, base argv exclusions, `run_bounded` hard
     cap, identity canaries) actually keep a mutant from reaching the network, `validate.sh`,
     `ci-local.sh`, the primary checkout or the production ledger? Name any concrete path it misses.
  3. Is any issue requirement missing from the plan (smoke controls, budgets, stop conditions, the
     review gates, evidence/provenance)?
  4. Are Track B's stateful claims honest — does each of B1–B3 have a real fixture reset, a semantic
     predicate and a cleanup check, or should one be held?
  5. Is the segmented no-new-signal stop for the long window a faithful, minimal way to meet the
     issue's limit given gen4 has no such stop, and is its stated limitation honest?
  6. Does the plan avoid building a duplicate subsystem or new adapter? Flag over- or
     under-engineering.
  7. Is the rating `rated 55/40/50/35` and its rationale grounded (appeal neutral at 50)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL

Basis: Block execution pending the containment, supervision, stop-limit and stateful-control corrections below. This is a plan review, not campaign qualification. Reviewed the entire 237-line plan, including its pre-existing content; the defects below are in that full artifact. No production repair, adapter or new suite is requested.

swept file: yes

Evidence scope: graph tools (including project/index/coverage tools) are unavailable in this session; used direct numbered source reads. `gh issue view 1280 --repo HiQS-Labs/XYZ-forge` exited 0 and returned the live OPEN issue, including “Stop earlier after 50 consecutive cases” and “stop after 3 consecutive batches or 500 cases”. The plan has no transcribed Acceptance criteria section despite Setup's description; the live issue supplied requirements. No git command, suite, pytest, executable fixture or campaign was run. Runtime qualification remains **[Unverified — needs clone run]**.

- **[Should] F1 — Contain the outer command's filesystem writes before launch (DoD 2).** Plan `:102-120,234-237` relies on cwd/PATH/HOME and after-the-fact canaries, but `harness.py:1356-1358` calls `generate_manifest` before `_run_root`; `:784-785` creates parents and writes an unrestricted output. The sandbox at `:1088-1096` protects tick's tool child only. `../../etc/passwd` from `<sandbox>/clone` resolves outside that clone; its containing directory can be created in the writable scratch ancestor. A canary elsewhere and git status inside the clone miss that write. Cheapest correction: apply an existing OS sandbox to the complete target invocation with explicitly allowed scratch write roots and denied network, or narrow/hold the unsafe target until an existing enforcement mechanism is demonstrated. Keep the fixed `factory-primitive` head.
  Observed input: the actual mutator produces `['generate-manifest','--output','../../etc/passwd']` (probe below); no write was executed.
  Affected scope: Track A `generate-manifest` output-path mutants and their automatic/manual replays.
  Falsifier: in the disposable smoke clone, this mutant is denied before creating/modifying the resolved external path while the declared in-root output succeeds, with both paths inspected. An enforced outer sandbox already doing that would discharge this finding.
  Read-only probe command (after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`), exit **0**:
  ```python
  python3 - <<'PYPROBE'
  import ast,pathlib,random,unicodedata
  s=ast.parse(pathlib.Path('utils/py/fuzz_engine.py').read_text())
  names={'FAMILIES','BOUNDARY_SCALARS','UNICODE_SNIPPETS','STRUCTURE_SNIPPETS','mutate','plan_mutants'}
  n=[x for x in s.body if isinstance(x,ast.FunctionDef) and x.name in names or isinstance(x,ast.Assign) and any(getattr(t,'id',None) in names for t in x.targets)]
  d={'random':random,'unicodedata':unicodedata}
  exec('from __future__ import annotations\n'+ast.unparse(ast.Module(body=n,type_ignores=[])),d)
  print(d['plan_mutants'](['generate-manifest','--output','temp/factory-primitive/ate-smoke/manifest.json'],1321,50)[1])
  PYPROBE
  ```
  Decisive output: `{'index': 1, 'family': 'structure', 'argv': ['generate-manifest', '--output', '../../etc/passwd'], 'parent_size': 73}`. Seed 1321 demonstrates the supported mutation family, not a claim that the first frozen smoke batch emits this mutant.

- **[Should] F2 — The external cap does not kill all descendants (DoD 1–3).** Plan `:115-116` says the entire Gen 4 group is killed “with descendants”. Every `fuzz_engine.execute` calls `run_bounded` (`fuzz_engine.py:238-245`), which starts a **new session** (`proc_group.py:122-125`); `kill_existing` kills only the supplied PGID (`:81-105`). The active mutant is therefore outside the supervisor's Gen 4 group. Tick tools create another session (`harness.py:1096`). Also, `pgrep -f gh1280-sb` can miss a mutant whose argv only contains the relative harness path and `temp/factory-primitive/fz`; cwd is not argv. Phase-boundary canaries (`plan:117,203-209`) do not implement the issue's immediate safety stops.
  Observed input: the planned nested `run_bounded(gen4)` → `execute(relative harness argv)` → `run_bounded(mutant)` chain, interrupted by the outer hard timeout.
  Affected scope: smoke and long-run timeout/safety cancellation and descendant accounting, including automatic Gen 4 replay.
  Falsifier: a disposable-clone cancellation control proves the active mutant and any tool session are gone at the cap, using recorded PIDs/PGIDs rather than a sandbox-name argv match; a live canary violation demonstrably halts further cases.
  Fix: specify an existing supervisor/reaper mechanism that owns those groups and observes live safety signals, including bounded cleanup/grace within the total wall budget. Otherwise hold execution. Do not claim process-tree enforcement from a group kill alone. **[Unverified — needs clone run]** for cancellation behavior; the session separation is source evidence.

- **[Should] F3 — Preserve both no-new-signal limits and the smoke budget (DoD 3,5).** Plan `:158-160` runs one 200-case invocation with a 1,500-second discovery cap and omits the 50-consecutive-case smoke stop. Plan `:201-209` waits for 500-case segments and expressly drops the three-batch stop. These differ from the live issue; describing the limitation does not authorize relaxing it. The independent supervisor can consume incremental telemetry (`fuzz_engine.py:308-315`) without adding a Gen 4 feature; shorter bounded invocations are another option if cumulative streaks/target rotation are preserved. Keep control/Track B work inside the smoke's total discovery budget too.
  Observed input: 50 consecutive already-classified smoke refusals; or long-run batches 1–3 (150 cases) with no new signature. The current plan continues both sequences. A 1,500-second discovery timeout also exceeds 1,200 seconds.
  Affected scope: discovery accounting and early-stop supervision in both phases, across targets/segments, plus automatic replay time.
  Falsifier: a frozen telemetry sequence causes smoke to stop at case 50 and long discovery at the end of batch 3, while novelty resets the appropriate streak; recorded timing stays within the declared budgets. If existing assets cannot do this, keep the long window held rather than substitute a weaker contract.

- **[Should] F4 — Relocate the historical SQL controls before replay (DoD 2,4).** Plan `:170-171` says to reuse the recorded commands. `controls-checkpoint2.jsonl:10-11` (`missing-decision`, `missing-snapshot`) include SQL DELETE commands with absolute DB paths under `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge/temp/XYZ-forge-gh1248-outer-loop-2026-10-28/...`, independent of cwd. The interpreter path is also historical. Thus “fresh run root” alone does not relocate those writes.
  Observed input: row 10's `sqlite3.connect(sys.argv[1]); ... DELETE FROM decisions ...` with that absolute `missing-decision/instances/C/state.db` argument; row 11 additionally deletes snapshots.
  Affected scope: those two B1 SQL controls and any absolute-path arguments in the reused command records.
  Falsifier: inspect the frozen replay argv: every mutable path resolves inside the new control clone, the selected interpreter matches the pinned runtime, and a deliberately external path is rejected before SQL executes.
  Fix: explicitly substitute the owned clone/run root and interpreter, validate resolved paths at use, record adapted argv, and compare structured expectations from the logs. Hold any control that cannot be safely relocated. Do not execute the historical strings verbatim.

- **[Should] F5 — B3 lacks the recovery operation (DoD 4).** At plan `:175-176`, `crash-act` exits before `_run_tool` (`harness.py:1204-1210`); the tick remains nonterminal. `status` (`:1268-1297`) reports stored state and does not reconcile. `_reconcile` classifies `uncertain` only during a subsequent tick (`:1126-1141,958-972`). The historical crash-act control (`controls-checkpoint2.jsonl:7`) correctly includes `tick --slot 2` before status.
  Observed input: fresh init → `tick --slot 1 --fault crash-act` → `status`, exactly B3's listed sequence.
  Affected scope: B3's expected `uncertain`/no-retry predicate and its replay.
  Falsifier: in a disposable clone, status alone already shows the completed reconciliation receipt and quarantined item; source currently shows it cannot. After an explicit recovery tick, expect the original slot uncertain, its item quarantined, and no retry of that intent.
  Fix: reuse the historical recovery sequence and assert original-slot receipt, quarantine, absence of duplicate tool execution and per-case cleanup; do not require no new action at slot 2, which may legitimately handle another item. Until exercised, B3 stays conditional/held.

- **[Should] F6 — Require the issue's accountable report fields (DoD 3).** Plan `:180-184,211-220` specifies candidate categories and evidence, but does not require per-candidate owner/impact, root-cause-aware dedupe against existing work, explicit classification denominators or the final exercised/excluded coverage and actual budget totals. These are explicit issue/defect-campaign requirements, not a new reporting system.
  Observed input: Phase 3's proposed record can contain only a category and replay outputs and still satisfy the written steps.
  Affected scope: final candidate disposition rows and SUMMARY.md.
  Falsifier: a sample record/summary is rejected when owner, severity/impact, evidence, replay/controls, denominator, actual budget or coverage exclusions are missing, and accepted when populated (manual review suffices).
  Fix: name these fields in the existing evidence/report step and include a stop/go conclusion for later stateful work. No new gate or schema implementation is needed.

- **[Nit] F7 — Rating is present, rationale is absent (DoD 7).** Plan `:38` and `releases.sql:941` agree on `rated 55/40/50/35`, with appeal neutral at 50. Neither gives the requested rationale. Add one short explanation for priority/severity/effort cheapness; the bounded experiment's value is robustness evidence, not a proven production incident. Do not rescore merely to satisfy review.

- **[Pass] DoD 1 — Most recon is accurate.** Fixed head assembly (`fuzz_engine.py:224-228`) and dispatch (`harness.py:1397-1401`) keep the registry alias unreachable; no concrete route from these templates to validate.sh/ci-local.sh was found. Run-root guard, unguarded manifest output, PRS snapshot/gh use and tool-only sandbox match `harness.py:639-657,784-785,1085-1096,1302-1308`. Gen 4 cloning/reset, post-batch identity observations and between-batch duration checks match `gen4_campaign.py:84-103,152-192`. Refusal classification and replay limitations match `adaptive_ate.py:297-337` and `fuzz_engine.py:440-449`. These are source checks, not runtime containment proof.
- **[Pass] DoD 4 — B2 has a usable existing predicate.** A fresh initialized root with a completed slot and repeated same tick reaches the existing-terminal early return (`harness.py:1126-1130`); the oracle compares output/tree digests (`domain_oracles.py:369-387`), supplemented by the plan's SQLite row counts (`plan:172-174`). B1/B3 need F4/F5; all three still need individually recorded cleanup and runtime evidence before coverage is claimed. Track A is only reset per batch (`gen4_campaign.py:175-187`), so init observations must not be labelled independent per-case fixtures.
- **[Pass] DoD 3,6 — Reuse and review shape are proportionate.** Plan `:95-101,153-157,194-200,211-220` reuses existing tools/controls, skips weakening minimization, supplies witnessed negative controls and two independent review boundaries, and retains provenance. No duplicate adapter/subsystem is proposed. Add enforcement/records to those existing seams; do not expand into production repair. Identity changes may invalidate results and require stop/inspection rather than automatic retry.

Handing off to Producer (claude-a): correct/disposition F1–F7 in the plan, then open Round 2 for Reviewer. No campaign is authorized by this FAIL verdict.

### Producer · Round 1 → 2 · claude-a

All seven findings accepted and implemented in `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md` (see its "Plan QA dispositions" table):

- F1 Implemented — every Track A mutant now runs under `/usr/bin/sandbox-exec -f <profile>` (allow default, deny network, deny file-write outside the gen4 sandbox root and /dev); added a witnessed-red control (`generate-manifest --output <outside path>` denied, path absent) next to the in-root success. Track A has no `tick`, so no nested sandbox.
- F2 Implemented — an independent supervisor owns the gen4 process group and, on any stop, sweeps every process whose argv contains `harness.py factory-primitive` or the profile path (asserting none exist pre-launch), recording PIDs. Live canary check every 5 s; a supervisor negative control (deliberate canary edit) must trigger an immediate stop.
- F3 Implemented — supervisor enforces the smoke 50-consecutive-case stop and the long-run 3-batch (150 events) / 500-case limits from live `telemetry.jsonl`, plus the 1,200 s smoke discovery wall; frozen-telemetry negative control included. Segmentation dropped.
- F4 Implemented — B1 adapts each recorded argv (interpreter, run root, the two SQL `state.db` paths), records it, and asserts every mutable path resolves inside the control clone's `temp/factory-primitive/`; unrelocatable cases are held.
- F5 Implemented — B3 now runs the recovery `tick --slot 2` before `status`; predicate: slot 1 `uncertain`, item quarantined, no second tool run for that intent, no surviving process.
- F6 Implemented — candidate rows carry target, argv, invariant, root cause, severity/impact, owner, evidence, replay/controls, rediscovery link; SUMMARY states coverage in/out, actual budgets, per-class denominators, held tracks and a stop/go call.
- F7 Implemented — acceptance criteria and rating rationale sections restored (lost when the capture doc was promoted).

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

VERDICT: FAIL

Basis: The revised plan substantially addresses F1–F7, but the stopping mechanism, shared smoke budget and crash oracle still need the corrections below before execution. Swept the entire 318-line plan, including pre-existing content; no additional pre-existing plan defects found beyond the findings and limitations recorded here. This is plan QA, not runtime qualification.

swept file: yes

Evidence scope: graph project/index/coverage tools are unavailable in this session; used direct numbered source reads. `gh issue view 1280 --repo HiQS-Labs/XYZ-forge` exited 0 and returned the OPEN issue, including the 20-minute discovery budget and both no-new-signal limits. No git command, suite, pytest, executable fixture or campaign was run. Sandbox enforcement, supervisor cancellation and all stateful outcomes remain **[Unverified — needs clone run]**; planned controls are not witnessed results.

- **[Should] F8 — Five-second observation cannot enforce the stated case boundary (DoD 3,5).** Plan `:124-132,192-193,238-244` polls telemetry every 5 seconds and then kills the driver. In `fuzz_engine.py:290-315`, appending an event is immediately followed by the next iteration; there is no supervisor acknowledgement. If event 50 arrives just after a poll, case 51 can launch before the next poll. The same problem affects the third long-run batch. A frozen-file classification check (`plan:177-180`) only proves counting; it does not prove that execution stops at that boundary. The plan also promises an immediate stop while explicitly allowing five seconds of observation delay.
  Observed input: the written 5-second supervisor loop at `plan:126`, combined with the real event-append/next-execution path at `fuzz_engine.py:290-315`; case 50 is visible but the producer is free to start case 51 before the next observation.
  Affected scope: smoke 50-case streak, long-run three-batch/500-case streak, and safety cancellation latency.
  Falsifier: a disposable-clone control with the actual launching supervisor records case 50 as the last launched case (and no case 51) when the streak is reached just after a poll; likewise no fourth batch after three no-signal batches. A reader stopping after consuming an already-produced file is insufficient.
  Fix: specify a launch boundary that waits for the stop decision, or bounded invocations that cannot launch beyond the remaining allowance; preserve target rotation and cumulative streaks. If existing mechanisms cannot supply it within scope, hold execution or obtain an explicit issue-contract change rather than claim exact enforcement. State the actual safety detection latency and reserve termination grace inside hard walls. No production driver change or new suite is requested.

- **[Should] F9 — Start one smoke clock before controls (DoD 3).** The phase heading promises all tracks within 20 minutes discovery, but `plan:168-184` runs controls first and grants Track A another 1,200 seconds from its own launch; Track B follows at `:195-215`. Positive-duration controls + the allowed full Track A window already exceed the total. This leaves F3 partially unresolved despite the restored heading.
  Observed input: the ordered controls → Track A (1,200 seconds from launch) → Track B sequence at `plan:168-215`.
  Affected scope: all smoke control/Track A/Track B discovery and automatic replay, followed by the ten-minute replay/cleanup reserve.
  Falsifier: a recorded timeline with deliberately time-consuming controls shows Track A receiving only the remaining discovery time, Track B held if none remains, and cleanup complete within the total 30 minutes.
  Fix: set a shared monotonic discovery deadline before step 3, pass only remaining time to each operation (including fixed Track B commands), stop discovery at that deadline, and reserve cleanup within the total wall. Keep the 200 mutation cap cumulative. This is a contract clarification, not a new timer framework.

- **[Should] F10 — B3 must expect zero tool executions for the crashed intent (DoD 4).** Recovery is now present, but `plan:211-212` defines no retry as “one tool output for that intent”. `harness.py:1204-1210` records tool-start metadata, then `os._exit(70)` executes before `_run_tool`. Reconciliation quarantines the intent and finishes it uncertain (`:965-972`); it does not execute that tool. One output would therefore fail a correct crash-act control, or accept an erroneous retry.
  Observed input: fresh init → slot 1 `--fault crash-act` → slot 2 recovery, with the plan's one-output predicate.
  Affected scope: B3 crash-act replay only; outputs for a different intent at slot 2 are separate.
  Falsifier: the disposable-clone control shows zero tool executions/output for the original tick/intent, its uncertain receipt and quarantined item, and no surviving process; a deliberate retry/output attributed to that original intent must fail the predicate.
  Fix: require zero original-intent tool executions/output before and after recovery; separately permit legitimate slot-2 work. Do not infer execution from `tool_started_at` alone.
  Read-only AST probe (no import/execution of target), exit **0**:
  ```python
  import ast
  from pathlib import Path
  t = ast.parse(Path('utils/py/harness.py').read_text())
  crash = next(n for n in ast.walk(t) if isinstance(n, ast.If) and ast.unparse(n.test) == "fault == 'crash-act'")
  f = next(n for n in t.body if isinstance(n, ast.FunctionDef) and n.lineno <= crash.lineno <= n.end_lineno)
  tool = next(n for n in ast.walk(f) if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == '_run_tool')
  print(f'function={f.name}; crash-act exit={crash.body[0].lineno}; _run_tool={tool.lineno}; exit precedes tool={crash.body[0].lineno < tool.lineno}')
  ```
  Command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with the body above. Decisive output: `function=run_tick; crash-act exit=1207; _run_tool=1210; exit precedes tool=True`. An initial AST lookup assumed a function named `tick` and exited **1**, `StopIteration`; the corrected lookup finds the enclosing function structurally. Neither probe launched a target.

- **[Pass] DoD 1 — Recon remains source-grounded.** Guard/output/PRS/tool paths match `harness.py:639-657,784-785,1085-1096,1302-1358`; immutable target head assembly is `fuzz_engine.py:224-228`; per-batch clone/reset and absent streak enforcement are `gen4_campaign.py:84-103,152-192`. Refusal and replay qualifications match `adaptive_ate.py:297-337` and `fuzz_engine.py:440-449`. No route from the declared fixed-head argv to the registry/gate entry points was found in this source trace.
- **[Pass] DoD 2,4 — F1/F4 have concrete planned controls; B2 retains a real predicate.** The outer sandbox specification and external-path refusal control are now `plan:110-118,174-176`; historical SQL paths are explicitly relocated/validated at `:197-205`. These discharge the plan omissions, subject to clone-run proof. B2's completed-tick early return and digest checks are `harness.py:1126-1130` and `domain_oracles.py:369-387`, with SQL counts at `plan:206-208`. Per-case reset/cleanup and hold language is `plan:213-215`. B3 needs F10. Track A init remains batch-reset coverage only (`plan:189-191`), so it cannot establish independent per-case init semantics; do not expand that claim at contract review.
- **[Pass] DoD 3,6,7 — Reporting, review and rating corrections are proportionate.** `plan:231-237,248-279` names hash-bound review, accountable dispositions, actual totals/denominators, exclusions and committed provenance. `plan:283-288` grounds 55/40/50/35 and neutral appeal. The temporary supervisor at `:124-132` fills an existing enforcement gap without proposing a new adapter or permanent subsystem; F8/F9 concern whether its contract works, not a request to build a framework. Segmentation has been dropped (`:238`), so DoD 5 now concerns live supervision and is unresolved by F8. F6/F7 are discharged at plan level; F2 still requires actual nested-process cancellation evidence before smoke can pass.

Root cause: the revised plan equates asynchronous observation with a launch boundary and misreads pre-tool crash metadata as a completed tool effect; Fix site: the plan's supervision/budget contract and B3 predicate; Why not upstream/downstream: this turn reviews the experiment contract only, and production repairs or new adapters are outside scope.

Handing off to Producer (claude-a): disposition F8–F10, revise the plan, and open Round 3 for Reviewer. No campaign is authorized by this FAIL verdict.

### Producer · Round 2 → 3 · claude-a

F8–F10 accepted and implemented (plan "Plan QA dispositions" table). The supervisor draft is now committed for review at `TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py` (evidence copy, not a suite; `utils/ci-route.sh:65` routes `TESTS-RESULTS/*` as docs).

- F8 Implemented — exact launch boundary: every Track A target runs `sandbox-exec -f <profile> python3 supervisor.py --gate <contract> -- utils/py/harness.py factory-primitive {mutant}`. Because `fuzz_engine.fuzz` appends case N-1 before launching case N (`fuzz_engine.py:290-315`), the gate (`supervisor.py` `gate()`) re-reads telemetry, applies the streak / quiet-batch / budget stops and a read-only canary check, and refuses with rc 125 before the harness runs; it writes a stop file the 1 s watcher then acts on. Gated events are excluded from counts. Remaining latencies stated in the plan: wall stop ≤1 s, mid-mutant canary change ≤5 s plus that mutant's 30 s timeout; grace reserved inside walls. The supervisor negative control now uses the real gate+watcher against the real target (base argv a guaranteed refusal): exactly 51 harness invocations, then a gated case.
- F9 Implemented — one monotonic deadline `D = T0 + 1,200 s` set before controls; order controls → Track B → Track A, each gets `D − now`; pending work at `D` is held; total smoke by `T0 + 1,800 s`; timeline recorded.
- F10 Implemented — B3 requires zero tool executions/output for the crashed intent before and after recovery (`harness.py:1207` exit precedes `:1210` `_run_tool`); slot-2 work for a different intent allowed.

This is round 3 of 3. Handing off to Reviewer (codex).

### Reviewer · Round 3 · codex

VERDICT: FAIL

Basis: Block execution under this revision. F9 and F10 are corrected at plan level, and the launch gate addresses the asynchronous observation gap in principle, but its supplied tracker still violates the no-new-signal boundary and the same gate prevents the required post-stop replay. Round 3 of 3 ends Escalated; Producer/operator must resolve these findings before execution. This is plan QA, not campaign qualification.

swept file: yes

Evidence scope: swept the entire 347-line plan and the entire 244-line supervisor evidence copy, including pre-existing content; the findings below are the remaining material defects found in that scope. Graph project/index/coverage tools are unavailable in this session (tool inventory returned no matching tools), so claims use numbered source reads and one pure, in-memory AST-extracted tracker probe. `gh issue view 1280 --repo HiQS-Labs/XYZ-forge` exited **1**, `error connecting to api.github.com`; live issue state could not be refreshed. Requirements were checked against the plan's Acceptance criteria and the earlier issue observations quoted in this relay, not represented as a fresh live read. No git command, suite, pytest, executable fixture, sandbox control or campaign was run. Runtime containment, cancellation, controls and stateful outcomes remain **[Unverified — needs clone run]**.

- **[Should] F11 — The supplied tracker does not enforce the promised no-new-signal limits (DoD 3,5).** Plan `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md:264-269` promises an exact stop before a fourth quiet batch. `TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py:94-99` closes the previous batch only when it consumes the first event of the next batch. At the launch gate before that next case, that event does not yet exist. The probe below shows a warm-up batch plus three quiet 50-case batches (200 events) still yields no stop; event 201, already an extra harness execution, is required to recognize quiet batch 3. Separately, `:93,99` treats **every** candidate occurrence as new signal, even when its normalized signature is already in `seen`: 501 identical tracebacks leave both counters at zero. Repeated rediscovery can therefore run to the wall/mutation cap instead of the no-new-signal stop. This keeps F8 partially unresolved.
  Observed input: one target, seeds 1281–1284, 50 identical expected-refusal events per seed; then seed 1285's first identical event. Separately, 501 identical rc-1 tracebacks, with one unique signature. Exact input and output are below.
  Affected scope: smoke's consecutive-case counter and the long-run three-batch/500-case counters, including repeated candidate signatures; not a request to change Gen 4 production code.
  Falsifier: before launching event 201 in the four-batch sequence, the real gate refuses; a repeated candidate signature resets novelty only on its first occurrence and then reaches the configured no-new-signature threshold. A genuinely new signature resets the applicable counter. Record these as manual controls in the existing evidence package, without adding a suite.
  Fix: close/count a completed batch at its actual launch boundary using the frozen batch size or explicit batch identity/completion information, and distinguish candidate capture from signature novelty. Preserve the independent case and batch limits. If that cannot be expressed within this experiment, hold the long run rather than claim exact enforcement.

  Probe command (pure tracker computation; no subprocess, target import, fixture or filesystem mutation), exit **0**:
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY'
  import ast, pathlib, re
  p=pathlib.Path('TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py')
  t=ast.parse(p.read_text())
  nodes=[n for n in t.body if isinstance(n,(ast.FunctionDef,ast.ClassDef)) and n.name in {'classify','signature','Tracker'} or isinstance(n,ast.Assign) and any(getattr(a,'id',None)=='EXPECTED' for a in n.targets)]
  d={'re':re}; exec(compile(ast.Module(body=nodes,type_ignores=[]),str(p),'exec'),d)
  c={'target_names':['refusal'],'seed':1280,'quiet_batch_stop':3,'streak_stop':500,'max_mutations':10000}
  def event(seed, rc=2, stderr='factory-primitive: run root must stay under temp/factory-primitive'):
   return {'exit_code':rc,'extra':{'seed':seed,'stderr_sample':stderr}}
  x=d['Tracker'](c)
  for seed in range(1281,1285):
   for _ in range(50): x.feed(event(seed))
   print('batch_end',seed-1280,'events',x.events,'quiet_batches',x.quiet_batches,'stop',x.stop_reason())
  x.feed(event(1285)); print('first_case_batch5','events',x.events,'quiet_batches',x.quiet_batches,'stop',x.stop_reason())
  y=d['Tracker']({**c,'streak_stop':50})
  for i in range(501): y.feed(event(1281+i//50,1,'Traceback (most recent call last)\nValueError: same defect'))
  print('identical_candidates','events',y.events,'unique_signatures',len(y.seen),'streak',y.streak,'quiet_batches',y.quiet_batches,'stop',y.stop_reason())
  PY
  ```
  Decisive output:
  ```text
  batch_end 1 events 50 quiet_batches 0 stop None
  batch_end 2 events 100 quiet_batches 0 stop None
  batch_end 3 events 150 quiet_batches 1 stop None
  batch_end 4 events 200 quiet_batches 2 stop None
  first_case_batch5 events 201 quiet_batches 3 stop no-new-signal: 3 consecutive batches without a new signature
  identical_candidates events 501 unique_signatures 1 streak 0 quiet_batches 0 stop None
  ```

- **[Should] F12 — Give replay a separate bounded contract; the discovery gate refuses it (DoD 1,3,4).** Plan `:242-247` requires replay in the kept sandbox and a semantic re-check “under the same wrapper”. The wrapper now includes the discovery gate (`:127-135`). After a normal gate stop, `supervisor.py:127-129` returns 125 for every subsequent invocation because the stop file persists. Even deleting that file does not solve it: `:130-144` reads the exhausted discovery telemetry and recreates the stop before `execv`. `fuzz_engine.py:446-449` faithfully executes that wrapped target and compares its result to the original observation, so this yields a gate refusal instead of the candidate's replay. Gen 4's automatic post-discovery replay at `gen4_campaign.py:203-219` also retains the gate. Thus the revision blocks the semantic evidence that must qualify candidates, rather than merely restricting new discovery.
  Observed input: the planned post-stop replay with an existing stop file containing `no-new-signal: ...`, or with that file removed but telemetry still at `streak_stop`; replay target is the plan's same sandbox/gate/harness wrapper.
  Affected scope: automatic Gen 4 replay, explicit fuzz replay and the clean/failing semantic controls after a discovery stop. Discovery limits must remain in force for discovery.
  Falsifier: after a witnessed discovery stop, one selected candidate and its clean control actually reach the harness under the same OS sandbox, with explicit replay time/case bounds; candidate outcome matches its semantic predicate, while another discovery launch remains refused. Merely clearing the stop file or observing rc 125 is insufficient.
  Fix: explicitly separate replay accounting/state from exhausted discovery state while retaining the sandbox, canary checks, per-command cap and cleanup. Name which automatic replays are deliberately suppressed and perform the required manual semantic replays within the reserved replay budget. No production replay-engine change is required.

- **[Pass] DoD 1 — Recon remains grounded, with replay integration qualified by F12.** Fixed-head assembly and dispatch are `fuzz_engine.py:224-228` and `harness.py:1397-1401`; run-root/output/PRS/tool behavior is `harness.py:639-657,784-785,1085-1096,1302-1358`. Gen 4 clone/reset and between-batch duration checks are `gen4_campaign.py:84-103,152-192`; no streak stop exists on that path. Error classification is `adaptive_ate.py:297-337`; replay compares the stored vector at `fuzz_engine.py:446-449`. These are source observations, not witnessed runtime results.
- **[Pass] DoD 2 — The plan retains concrete containment controls; enforcement remains conditional.** Plan `:110-149,194-203` specifies the outer write/network sandbox, sanitized environment, fixed target head, identity canaries and process sweep, with negative controls. No additional concrete argv route to the primary ledger, network or gate scripts was found in the inspected fixed-head dispatch. The important remaining boundary limitation is operational: `supervisor.py:43-47` runs canary commands without a timeout, so its 1 s / 5 s watcher latency at plan `:142-145` is not established by source alone. The frozen contract/clone controls must demonstrate bounded canary commands and actual nested-session cleanup; hold if they cannot. No runtime containment PASS is claimed.
- **[Pass] DoD 3,4 — F9/F10 are discharged at plan level.** Plan `:175-180` sets one clock before controls and assigns only remaining discovery time to controls, Track B and Track A. Plan `:232-241` requires recovery, zero original-intent tool executions/output, quarantine and per-case reset/cleanup; this matches the pre-tool crash exit at `harness.py:1204-1210` and recovery at `:958-972,1135-1141`. B1 relocates interpreter/SQL paths at plan `:220-228`; B2 adds row-count checks at `:229-231` to the existing terminal early return (`harness.py:1126-1130`) and digest oracle (`domain_oracles.py:369-387`). B1–B3 remain conditional/held until exercised; this review does not count planned checks as stateful coverage.
- **[Pass] DoD 3,6,7 — Report fields, review gates and rating remain proportionate.** Plan `:257-263,274-305` requires frozen hash-bound review, accountable dispositions, actual budgets/denominators, coverage exclusions and committed provenance. Plan `:307-314` grounds `55/40/50/35` and neutral appeal. No new state adapter or duplicate production subsystem is proposed (`:95-101`); the temporary supervisor is campaign tooling whose supplied implementation must still meet its own stated contract. DoD 5 is unresolved by F11, rather than discharged by the introduction of a gate.
- **[Nit] F13 — Refresh stale descriptions.** Plan `:46-47` says the task branch changes only the doc and ledger, and `:95-99` describes a short shell loop and no classifier. This revision also supplies a 244-line Python supervisor with `EXPECTED`/`classify` at `supervisor.py:13-33`. Update the artifact/source inventory and describe the temporary classification used for stopping accurately; no new mechanism is requested.

Root cause: the launch gate uses a tracker that recognizes batch completion only from the next completed case, treats candidate status as perpetual novelty, and shares exhausted discovery state with replay; Fix site: the temporary supervisor and the plan's replay contract; Why not upstream/downstream: these are experiment orchestration defects, and changing production Gen 4/fuzz engines or accepting unexecuted replay results would expand scope or hide them.

Handing off to Producer (claude-a): relay Escalated at the round limit; resolve F11–F12 and the stated clone-run qualifications with the operator before any campaign. No execution approval is granted by this verdict.

### Producer · Round 3 dispositions (post-escalation) · claude-a

Relay stays Escalated at the 3-round cap; no Round 4 is opened without the operator. Dispositions recorded for the operator:

- F11 Implemented — `Tracker.feed` now closes a batch at its own last case using the frozen batch size, and novelty is a signature's first occurrence only (a repeated candidate is still captured). Re-running the Round 3 probe on the fixed tracker: quiet batches reach 3 at event 200, `stop_reason` set before event 201; 50 identical tracebacks after the first stop at event 51 with all 51 captured.
- F12 Implemented — replay uses a separate replay contract (own stop file, no discovery telemetry, canary kept); gen4 auto-replay is deliberately suppressed; a witnessed control shows a post-stop replay reaching the harness while discovery stays refused.
- F13 Implemented — plan inventory/classifier description refreshed; canary commands now have a 10 s timeout (timeout counts as a violation).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
