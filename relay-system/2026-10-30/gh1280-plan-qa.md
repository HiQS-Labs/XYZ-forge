# RELAY · GH-1280 plan QA: outer-loop ATE campaign
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
