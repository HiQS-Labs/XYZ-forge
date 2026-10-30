# RELAY · GH-1261 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1261-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1261-PLAN-DRAFT-PHASE-2B.md`
- Also read (the code the plan cites): utils/py/harness.py (GH-1257 plan-draft section: PATH_RE, _planner, _cited_paths, render_brief, _build_proposal, plan_draft, _verify_plan_draft, init_from_prs, BRIEF_KEYS, CLI init flags); utils/py/_marathon_plan.py (_pack_waves, _zone_of, _deps_of, compute record shape); TESTS-RESULTS/2026-10-29+GH-1257/SUMMARY.md; issues #1261 and #216.
- Operational envelope: a local, single-operator, read-only experiment on an unmerged spike branch (stacked on feat/gh1248-outer-loop-primitive). Grade against the plan's stated requirements and commensurate complexity; do not demand multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): verification is existing suites plus manual controls under `TESTS-RESULTS/`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the plan is grounded in the actual code paths; both changes extend `harness.py` plan-draft and reuse the existing planner (no second planner, writer or suite, no planner change); read-only and offline claims hold (the only new GitHub read is one `gh issue list` at init); the bare-name tie-break and unregistered-issue handling cannot make the proposal less conservative than Phase 2A for ledger issues; acceptance criteria are falsifiable with a red control; the rating 55/40/50/60 is reasonable.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · claude-a

Plan ready for review: `PROJECT/2-WORKING/GH-1261-PLAN-DRAFT-PHASE-2B.md` (commit on this branch). Specific questions:

1. Is the bare-name tie-break (unique basename; else the single match outside `test/` and `fixtures/`; else unresolved) safe, or does it create a wrong-path risk worse than the current under-count?
2. Is the `.xyz/` prefix strip correct for downstream-filed issues, and should it apply only when the stripped path exists in the frozen listing?
3. For unregistered issues: is a synthesized planner record (state `unregistered`, deps from `Engine._deps_of` over title + body, no contract) enough for `_pack_waves`, and does adding those lanes to the dependency view behave correctly?
4. Does `--unregistered` defaulting to 0 preserve Phase 2A behaviour exactly?
5. Are the acceptance checks and the red control sufficient to detect the actual failure?

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: the extension points and rating are reasonable, but the plan relaxes the issue's ambiguity contract and does not yet preserve dependency or write-set conservatism in the cases below.
swept file: yes

Reviewed the entire plan, the cited harness/planner paths, Phase 2A SUMMARY, and live issues #1261/#216. No additional plan defects found beyond the findings below. Verify-tier discovery attempted against `XYZ-forge`; graph generation `2026-09-01T15:54:30Z` is from another checkout, symbol search returned zero, and coverage flags the planner metadata changed. Findings therefore use this worktree's source, not graph completeness claims. No git commands, suites, executable fixtures, or artifact edits performed. Full implementation/gate results remain [Unverified — needs clone run].

Probe receipt for R1–R3: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 .relay-scratch/gh1261-review-probes.py` exited **0**. The scratch probe AST-extracted only `_pack_waves`, `_find_by_gh`, `DEP_RESOLVED`, `_cited_paths`, and `PATH_RE`; no module entry points ran. For the cap case it explicitly models successful new resolutions, then applies the unchanged admission loop; this is a plan counterexample, not a run of an implemented Phase 2B parser. Decisive output is quoted in each finding. An earlier exploratory probe exited 1 because fewer than 25 underscore-prefixed Python files existed; it produced no cap evidence and was corrected to select the first 25 Python files.

- **[Should] R1 — Remove the non-test tie-break or obtain an explicit change to the issue's scope.** Plan lines 63/80 resolve some names with multiple tracked matches, while [#1261](https://github.com/HiQS-Labs/XYZ-forge/issues/1261) explicitly requires “An ambiguous bare name (matches 2+ tracked files) is not resolved”. The probe found `actual duplicate paths: utils/marathon-plan.sh test/marathon-plan.sh`; the planned rule chooses the former even when the intended target is the latter. Showing a source line does not establish the intended path. Keep ambiguous names unresolved; #216 can still gain the unique Python planner/reconciler paths via `.xyz/` normalization. Revise its exact write-set expectation accordingly.
  Observed input: #216 names `marathon-plan.sh`; both paths above exist, as the plan itself also records at line 46. A scoped issue saying `Fix marathon-plan.sh` supplies no evidence selecting either target.
  Affected scope: bare names with multiple tracked matches and exactly one match outside test/fixtures.
  Falsifier: a frozen listing containing only `utils/marathon-plan.sh` should resolve it; a listing containing both paths should report ambiguity and choose neither. Record both manual controls under the planned evidence directory.

- **[Should] R2 — Include every seeded unregistered issue in the dependency lookup, including held and pending requests.** Plan line 72 adds “those lanes” to the view, which only covers admitted drafts. `_pack_waves` at `utils/py/_marathon_plan.py:830–835` treats an absent record as a satisfied dependency. The actual extracted method returned `draft lanes only waves= [[1262]] unplaced= []`; with the held prerequisite present it returned `all seeded records waves= [] unplaced= [1262]`. Build lookup-only synthesized records from all frozen unregistered requests, overlay admitted lanes, and keep non-admitted records non-resolved. This extends `harness.py` without changing the planner.
  Observed input: seeded #1262 has scope and `utils/py/harness.py`, with `depends on #1263`; seeded #1263 has no sourced file/scope and is held (or has not had its tick yet). The packing probe used `a={gh:1262,state:ready,deps:[1263],writeset:[utils/py/harness.py],zone:x,zoneRule:null,zoneInferred:false}` and `b={gh:1263,state:unregistered,deps:[]}`.
  Affected scope: dependencies on another seeded unregistered request before it is admitted, whether the dependent is a ledger or unregistered draft.
  Falsifier: #1262 must stay unplaced while #1263 is held/pending; after #1263 becomes an admitted draft it must be in an earlier wave than #1262. A two-draft happy-path pair alone cannot detect this bug. Add these expected outcomes and a red control to Acceptance.

- **[Should] R3 — Account for the existing 25-path truncation before claiming greater conservatism.** `utils/py/harness.py:477–480` processes issue citations before capture-doc citations and silently caps the combined set at 25. Adding successfully resolved bare issue names can evict a previously sourced capture path. The probe returned `Phase 2A count= 1 PDDA retained= True` versus `step 1 additions before capture count= 25 PDDA retained= False`. Specify that new extraction preserves every previously admitted path and never packs a silently incomplete expanded set: remove the cap, or hold on overflow while retaining complete evidence. Do not change the planner.
  Observed input: no-contract ledger request with bare issue-body names `_marathon_plan.py active_explorer.py adaptive_ate.py agy-turn.py aider-turn.py ate_runaway_sweep.py backfill_source_url.py board_sync.py calibrate_tier1.py claude-turn.py claude_cli.py codex-turn.py commandcode-turn.py consult.py deepseek-turn.py device_config.py differential_oracle.py domain_oracles.py express.py fuzz_engine.py fuzz_inputs.py gate_env.py gate_inventory.py gate_receipt.py gen4_campaign.py`, and capture doc supplying scope plus `PROJECT/PDDA.md`. The probe models these 25 names resolving successfully to their `utils/py/` paths. Phase 2A retains PDDA; the unchanged loop drops it after the additions, losing its collision with another PDDA lane.
  Affected scope: no-contract drafts whose newly resolved citations exhaust the combined path budget before old issue/doc citations.
  Falsifier: replay this input with successful resolutions and a competing PDDA lane; the expanded result must retain PDDA or hold the draft, and cannot co-pack them on an incomplete set. Disabling new resolution is the red control for the set-preservation check. Record this manual case under `TESTS-RESULTS/2026-10-30+GH-1261/`.

- **[Nit] Clarify zero-mode and brief verification wiring.** Plan lines 66–68 should say `gh issue list` runs only when N > 0; otherwise the new failure mode changes unflagged init behaviour. Lines 64/74 should explicitly wire `unresolved_names` into `BRIEF_KEYS` and the existing drop-key/Markdown consistency controls (`harness.py:35–38,519–543`). Candidate-set parity at line 82 is supportable; exact output-shape parity is incompatible with unconditional new source/key fields, so say which comparison is intended.
- **[Pass] Reuse and bounded scope.** Plan steps 1–3 extend `_cited_paths`, init, `plan_draft`, and `_build_proposal`; `_planner` already uses the frozen DB/listings (`harness.py:251–266`), and `_deps_of` is static (`_marathon_plan.py:686–700`). Synthesized records are sufficient if they also provide the brief reader's `flags`, `signals`, `contract`, and `deps` keys (`harness.py:472–496`). No second planner/writer/suite is needed. For `.xyz/`, reuse the existing realpath/containment/file checks (`harness.py:318–335`) and require the stripped target in the frozen listing; prefix text alone is not evidence of an existing target.
- **[Pass] Rating is proportionate.** Plan line 93's `55/40/50/60` fits a reversible local advisory experiment whose severity is limited by the absence of dispatch; the stated fixes remain bounded to the existing harness. The Phase 2A evidence explicitly reports the unsafe #216 under-count in its “Hand inspection” section. The resolution red control at plan line 83 is meaningful, but does not cover R2/R3.

Root cause: incomplete evidence extraction and omitted dependency records make a provisional proposal appear more complete than its inputs justify; fix sites: the existing harness extraction/admission and proposal view; why not upstream/downstream: the frozen issue text already contains the evidence and the existing planner correctly holds a prerequisite when its record is supplied.

Handing off to Producer (claude-a) — revise the plan and disposition R1–R3, then go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

Dispositions (plan revised in `PROJECT/2-WORKING/GH-1261-PLAN-DRAFT-PHASE-2B.md`):

- **R1 — Implemented.** Tie-break removed. Two or more tracked matches → unresolved, listed with count. #216 acceptance now expects `utils/py/wave_reconcile.py` and `utils/py/_marathon_plan.py` (via `.xyz/` strip) and `marathon-plan.sh` unresolved (2). One-match vs two-match controls added.
- **R2 — Implemented.** Lookup-only synthesized records for every frozen unregistered request (state `unregistered`, not in `DEP_RESOLVED`), overlaid by admitted lanes. Held/pending prerequisite → dependent unplaced; admitted prerequisite → earlier wave. Red control: admitted-only lookup wrongly packs the dependent.
- **R3 — Implemented (remove the cap).** The 25-path cap is removed, so new resolutions cannot evict an earlier path. 25+ citation control added (capture-doc path kept, collides with a competing lane).
- **Nit — Implemented.** `gh issue list` runs only when N > 0. `unresolved_names` joins `BRIEF_KEYS` and the existing verifier controls. Parity is candidate-set parity (same issues and order), stated explicitly.
- `.xyz/` strip now requires the stripped target in the frozen listing and reuses the existing containment checks (from your [Pass] note).

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: approve the plan for implementation. R1–R3 and the nit are addressed; the changes remain bounded to the existing harness and planner interfaces, with falsifiable manual controls. This approves the design, not an implemented result.
swept file: yes

Swept the entire revised plan, re-read the cited harness extraction/init/admission/proposal/verifier paths, planner record/dependency/zone/packing paths, Phase 2A SUMMARY, and live issues #1261/#216. No additional defects found in the reviewed plan beyond the now-addressed Round 1 findings. Verify-tier graph lookup again returned zero matching harness symbols; `XYZ-forge` generation `2026-09-01T15:54:30Z` belongs to another checkout and planner coverage reports `metadata_changed`. Used this worktree's source for material claims; no graph completeness claim. No git commands, suites, executable fixtures, source edits, or artifact edits performed.

- **[Pass] R1 closed.** Plan lines 62–66 require a frozen-listing target for `.xyz/` normalization and say “Two or more → unresolved; no tie-break”. Lines 80–81 supply the one-match/two-match and #216 expectations. This follows #1261's explicit ambiguity requirement and preserves the existing containment checks (`utils/py/harness.py:318–335`).
- **[Pass] R2 closed.** Plan line 73 supplies lookup records for **every** frozen unregistered request, then overlays admitted lanes. That fits the actual `_pack_waves` predicate (`utils/py/_marathon_plan.py:830–835`). The narrow probe below observed: omitted prerequisite → dependent packed; held/pending prerequisite → dependent unplaced; admitted prerequisite → earlier wave. This measures the existing planner with proposed input shapes, not an implemented Phase 2B harness.
- **[Pass] R3 closed.** Plan line 65 removes the truncation at `utils/py/harness.py:477–480`; lines 75/83 require retaining the capture-doc path and its collision in the 25+ citation case. The prior counterexample cannot be silently truncated under the specified design. Implementation still needs to demonstrate it.
- **[Pass] Integration and scope.** Plan lines 64/68/71–76 cover the new brief key and rendering, zero-mode's absence of a list call, synthesized reader keys, frozen inputs, unchanged planner waves, and disposable-clone verification. These extend the existing owners (`harness.py:251–266,338–356,385–430,443–543,546–619,1095–1103,1139–1145`) without a second planner, writer, module or suite. The new required key and its producer are specified together, consistent with LESSONS-LEARNED's gate lesson. No Engine constructor change is proposed.
- **[Pass] Acceptance and rating.** Plan lines 75–86 specify nonempty pilot outputs, preservation/collision cases, dependency negative control, list failure, zero-mode parity and ledger identity, with evidence under `TESTS-RESULTS/2026-10-30+GH-1261/`. The red controls at line 86 target the under-count and omitted-record failure. Line 96's `55/40/50/60` remains proportionate to the local advisory experiment with no dispatch.
- **[Unverified — needs clone run]** Phase 2B execution, manual controls, offline/containment behavior of the implementation, byte-identical ledger, candidate parity and final gate remain future evidence. Run the planned pilot/controls and gate in a disposable full clone and retain provenance per repository policy.

Probe receipt: the following command exited **0**, with no module entry point, fixture or suite executed. It AST-extracts only the existing dependency constant and two packing methods; temporary bytecode is disabled.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, re
from pathlib import Path
p=Path('utils/py/_marathon_plan.py')
t=ast.parse(p.read_text())
c=next(n for n in t.body if isinstance(n,ast.ClassDef) and n.name=='Engine')
c.body=[n for n in c.body if isinstance(n,ast.FunctionDef) and n.name in {'_pack_waves','_find_by_gh'}]
m=ast.Module(body=[n for n in t.body if isinstance(n,ast.Assign) and any(isinstance(x,ast.Name) and x.id=='DEP_RESOLVED' for x in n.targets)]+[c],type_ignores=[])
ns={}; exec(compile(ast.fix_missing_locations(m),str(p),'exec'),ns)
e=ns['Engine']()
a=dict(gh=1262,state='ready',deps=[1263],writeset=['utils/py/harness.py'],zone='x',zoneRule=None,zoneInferred=False)
b=dict(a,gh=1263,state='unregistered',deps=[],writeset=['PROJECT/PDDA.md'])
for label,lanes,view in [('red',[a],[a]),('held/pending',[a],[a,b]),('admitted',[a,dict(b,state='ready')],[a,dict(b,state='ready')])]:
    waves,unplaced=e._pack_waves(lanes,view,force_tail=False)
    print(label,[[r['gh'] for r in w] for w in waves],[r['gh'] for r in unplaced])
PY
```

Decisive output (wave issue lists, then unplaced issue list):

```text
red [[1262]] []
held/pending [] [1262]
admitted [[1263], [1262]] []
```

Root cause: extraction lost cited files and the proposal omitted unresolved prerequisite records; fix sites: the existing harness extraction and provisional dependency view; why not upstream/downstream: issue text already provides the evidence and the existing planner honors dependencies when supplied their records.

Turn bookkeeping: the first relay-write command failed with `zsh:62: unmatched` (exit 1) before changing the file; the token `done` command then succeeded. Corrected the relay with a file-scoped patch. Token is closed; no self-commit performed.

Relay closed (Approved), no further turn needed. Producer may proceed with implementation and the planned disposable-clone verification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
