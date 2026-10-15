# RELAY · GH1076 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1076-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Read the complete seeded packet and follow its exact source/evidence scope and operational envelope. No suites or mutations in the linked review worktree. Review all relevant changes versus9061df4b; no new tests/cases permitted.
- Artifact under review: **.relay-artifacts/gh1076-final-review-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-10-15/gh1076-final-review-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: Complete seeded packet and scoped source/evidence review satisfy its six acceptance points for a draft PR, subject to pending normal final full push gate; no unsupported umbrella completion.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: One bounded fail-closed contract gap needs correction before draft-review approval. Otherwise the completed policy/consumer scope fits the acceptance map, with rollout and final full push qualification explicitly outstanding. Swept the complete packet and ci-route, relevant wave selector/receipt/execution contexts, changed policy text, plan, changelog, callers and retained evidence. The pre-existing parser issue below is in scope; no other pre-existing defect was identified in the inspected contexts.

- [Should] Malformed duplicate tier metadata can admit Small. At utils/py/wave_reconcile.py:612 the whitespace-free tier regex silently drops a malformed second tier line; lines615–622 then accept Small. ROUTER's router-compatibility contract requires duplicate/malformed metadata to select full. This is a demonstrated contract robustness gap, not a natural router emission or production incident.
  Observed input: classifier rc0, nonempty README.md diff, exact classifier stdout "tier=1\ntier=2 trailing\npolicy_version=ci-route@1\nhosted_gate=small\n" (each \n denotes a newline).
  Affected scope: one valid tier=1 plus another tier= line with whitespace in its value, supported version and Small gate.
  Falsifier: that exact response must select validate.sh --sequential; a unique ordinary tier=1 with supported version/Small must continue selecting the existing Small command.
  Concrete fix: extract/count all tier= values before validating, using the same (.*) pattern as version/gate, and retain the exact ["1"] check. Record a manual observation; do not add a CI case.
  Probe command: PYTHONDONTWRITEBYTECODE=1 python3 - with the following stdin (exit0). It executes the actual current function AST in memory; subprocess calls are intercepted, so no Git or suite runs.
  ~~~python
  import ast, re, subprocess
  from pathlib import Path
  from types import SimpleNamespace
  fn = next(n for n in ast.parse(Path("utils/py/wave_reconcile.py").read_text()).body
            if isinstance(n, ast.FunctionDef) and n.name == "select_qualification_gate")
  decision = "tier=1\ntier=2 trailing\npolicy_version=ci-route@1\nhosted_gate=small\n"
  def run(args, **kw):
      return SimpleNamespace(returncode=0, stdout="README.md\n" if args[0] == "git" else decision)
  ns = dict(subprocess=SimpleNamespace(run=run, SubprocessError=subprocess.SubprocessError),
            re=re, QUALIFICATION_GATE="validate.sh --sequential",
            SMALL_GATE="validate.sh --sequential --subsystem small",
            small_suites_at=lambda *_: ["existing-small-suite"], landing_label=lambda _: "probe")
  exec(compile(ast.Module(body=[fn], type_ignores=[]), "<current selector>", "exec"), ns)
  print(ns["select_qualification_gate"](".", [{"mergeCommit": {"oid": "a"*40}}], {}))
  ~~~
  Decisive output: ('validate.sh --sequential --subsystem small', ['existing-small-suite'], 'tier 1'). The list stub avoids invoking the historical Git reader; command selection is the unmodified current function.

- [Pass] Additive publisher coverage preserves PDDA. utils/ci-route.sh:66 uses the existing area owner, line330 retains PDDA metadata, and lines514–518 keep Medium full. validate.sh:855 consumes that metadata and :1119 runs the existing stage; utils/py/xyz_mini_sync.py:98 names the package manifest. Direct classifier probes (Python subprocess invoking bash utils/ci-route.sh push with each input on stdin, all rc0) returned package tier2/full/PDDA=true, README tier1/Small, unknown/empty/safety tier3/full. manual-policy-observations.json retains the first false PDDA metadata; manual-pdda-preservation-correction.json records the correction.

- [Pass] Scope remains narrow. Read-only Python object decoding/SHA1 comparison against commit9061df4b tree ea91ec0bfd5eadf5e6eac6a58d849e3316133923, command python3 "$TMPDIR/read_objects.py", exit0: existing changed files are AGENTS, CHANGELOG, ROUTER, SOP, churn guidance, releases.db/sql and the two runtime files; decisive output "ADDED RELEVANT FILES []" for test/utils/workflows. Full diff shows only select_qualification_gate changed in wave_reconcile. Historical schema/list/receipt handling stays at utils/py/wave_reconcile.py:461, :470, :531; fixed gate execution is at :681. Existing tests and workflows are unchanged.

- [Pass] Policy/evidence do not claim umbrella completion. ROUTER says "Medium stays full" and "GH854 staging-only exception expired October7"; AGENTS/SOP/churn point there. The plan says reduced-Medium and broader automated batch authority remain "not implemented/not ready", naming missing evidence and PR1069 ownership. Historical-study-v2 distinguishes16 attempts/13 snapshots, qualification versus publication failure and corrects v1's omitted failures while preserving v1. Consult synthesis says "one completed advisory, one partial response"; task-rating-readback retains75/45/50/40 with no override. focused-verification.json records ten rc0 checks and unchanged before/after identity; calibration retains rc1, not matched qualifying evidence.

- [Unverified — needs clone run] The final normal full push gate and matched benchmark remain owed as declared. No validate/test/pytest/fixture run occurred here; no exact-head hosted result or savings is inferred. Graph inventory had no project for this worktree; primary graph generation2026-09-01 flagged metadata changes, so direct source/object reads supplied review evidence. Exact accepted-start admission was not independently replayed; this turn did not mutate the ledger.

Handing off to codex-producer — correct or disposition the Should finding, retain the manual observation and reopen the next round within the existing cap. Final full gate remains after source freeze.

### Producer · Round 1

Disposition: Implemented — observed malformed duplicate tier metadata violated the declared fail-full contract. Extract all tier= values with the same (.*) pattern already used for version/gate, then retain the unique-count and exact ["1"] check. This is one line in the existing consumer, no new schema/guard/runner/test/case.

Manual before/after evidence: TESTS-RESULTS/2026-10-15+GH-1076/manual-duplicate-tier-correction.json executes the actual function AST with intercepted external reads. The exact malformed duplicate selected Small before and full after; ordinary unique supported tier1 remains Small. Original reviewer FAIL and counters remain. No linked-worktree suites or source mutation by reviewer.

The ten existing focused suites passed before this one-line parser correction. The affected existing receipt/reconciliation suites will rerun in the owned disposable clone once the serial full baseline ends, before the required final full push gate. Baseline uses unchanged f974; final source and measurement stay separate. No full gate has yet been claimed for this implementation.

Handing off to Reviewer — review the bounded correction and complete source/evidence scope in round2/3; final exact-source normal full push gate remains owed after approval.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS

Basis: The Round 1 Should is resolved. The completed policy/consumer scope is sufficient for a draft PR subject to the pending normal final full push gate. This approves neither reduced-Medium rollout nor broader batch authority nor umbrella completion. Re-read the entire seeded packet, complete ci-route, selector/receipt/execution contexts, all changed policy text, canonical plan, CHANGELOG, existing caller/workflow/publisher contexts and retained evidence. No further pre-existing defect was identified in the inspected scope.

- [Pass] Duplicate-tier correction closes the observed failure without widening behavior. utils/py/wave_reconcile.py:612 now extracts `^tier=(.*)$`; :615–622 require unique metadata and exact tier1 for Small. `manual-duplicate-tier-correction.json` retains before/after observations. Independent narrow probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 "$TMPDIR/selector_probe.py"`, exit 0. The probe extracted the actual selector AST, intercepted subprocess reads as in Round 1 (Git diff response `README.md\n`, classifier response below), and stubbed only the historical list reader to `['existing-small-suite']`. With `tier=1\ntier=2 trailing\npolicy_version=ci-route@1\nhosted_gate=small\n`, decisive output was `current malformed duplicate ('validate.sh --sequential', None, 'unsupported or malformed classifier decision')`. With the ordinary single tier1 response, output was `current ordinary Small ('validate.sh --sequential --subsystem small', ['existing-small-suite'], 'tier 1')`. Replacing only the tier pattern in memory with its prior `^tier=(\S*)$` reproduced the red control: `prior-regex-red-control malformed duplicate ('validate.sh --sequential --subsystem small', ['existing-small-suite'], 'tier 1')`. No source file, Git command, suite or fixture was executed or changed by that probe.

- [Pass] Existing owners and coverage remain intact. utils/ci-route.sh:66–71 maps publisher text through existing subsystem_of before prose; :330 retains PDDA; :514–518 keeps Medium full. validate.sh:855 and :1119 consume PDDA; githooks/pre-push:230–242 passes paths back through the existing runner; utils/py/xyz_mini_sync.py:98 identifies the package manifest. The five existing area suites and literal historical Small registry are unchanged. wave_reconcile.py:470–590 retains historical @1 receipts and tested-commit list replay; :681 executes only fixed gate commands. .github/workflows/ci.yml:152–203 retains exact-main macOS/full, and wave-reconcile.yml retains serialized macOS qualification. No alternate runner/schema/map is introduced.

- [Pass] Direct read-only object comparison against integration base9061df4b (tree ea91ec0bfd5eadf5e6eac6a58d849e3316133923), command `PYTHONDONTWRITEBYTECODE=1 python3 "$TMPDIR/read_objects.py"`, exit 0, found changed existing files exactly `AGENTS.md, CHANGELOG.md, ROUTER.md, SOP.md, docs/CI-CHURN-RECOVERY-SOP.md, releases.db, releases.sql, utils/ci-route.sh, utils/py/wave_reconcile.py`; decisive outputs `ADDED test []`, `ADDED utils []`, `ADDED .github/workflows []`. The reader decoded loose/packed Git objects using Python, compared blob hashes with nonempty files and printed unified diffs; it did not invoke Git. Runtime diff is confined to router additions and the selector. No suite/case/assertion/parameter/registry/workflow changed.

- [Pass] Evidence and governance retain their limits. ROUTER's quoted “Medium stays full” and “GH854 staging-only exception expired October7” preserve rollout boundaries. The plan's Execution findings explicitly says reduced-Medium/batch authority are “not implemented/not ready”; CHANGELOG keeps the umbrella open. Manual-policy observations retain the original false PDDA metadata and unsupported-version red control; the PDDA correction names the downstream stage. focused-verification.json records ten rc0 suites at69567090 and identical before/after identity, preceding this parser correction. Historical-study-v2 retains16 attempts/13 snapshots and qualification versus publication failures, correcting the preserved v1 omission. Consult synthesis explicitly says “one completed advisory, one partial response.” Read-only SQLite query (`sqlite3.connect('file:releases.db?mode=ro&immutable=1')`, SELECT roadmap_items/work_events WHERE gh_number=1076, exit0) returned exact row `rmi-01M4Z662VRV2WWRB7E26PEM3XA`, ratings75/45/50/40, null override, and in_flight event `wev-01M4Z6X7K22Q2QV1HYQD4DX3BM` with `accepted_start: true` at2026-10-15T07:19:59Z. Normal round2/3 cap remains.

- [Unverified — needs clone run] Final exact-source full push verification, affected-suite rerun after this one-line correction, matched baseline/after comparison, and actual exact-head hosted outcomes remain owed. The failed408/409 calibration is not a matched baseline. No validate/test/pytest/fixture execution occurred here; no performance savings or final platform qualification is inferred. Graph inventory contained no current worktree project; nearest XYZ-forge coverage generation2026-09-01 reports changed metadata, so current direct source/object reads supplied evidence rather than stale graph claims.

Relay closed (Approved), no further review turn needed. Handing completion to codex-producer for the pending disposable-clone final gate, retained evidence and draft publication under the existing plan; approval does not waive any pending gate.


### Attestation · relay-drive — 2026-10-15T07:52:30Z
task: RELAY-GH1076-FINAL-20261015
reviewer: codex
status: Approved
reviewed-head: b334e98d7fb3b16ce5c3c7a8ad91ccb2569333f8
added-range: 12860+5505
added-sha256: f2216dbf3235c79da1974dba5547939c5b6e42f375052d9c52cf6021a3425c87
### Producer · Round 3

Parent-authorized continuation completed the missing real-data proof and bounded existing-consumer
coverage closure. Source f874fa8d adds gh660/path-integrity/gh788 to the existing skills area (5→8),
with only the existing test count expectation adapted. No new assertion/case/parameter. Full406 and
Small72 remain unchanged; Medium stillfull. Six affected existing commands passed, identity unchanged.
Historical218-receipt compatibility, two original actual mapped Medium full passes, exact Small
omission attribution,80-name projection, current1069 evidence and historical936 fold are retained
under phase3. See the full updated seeded packet and READINESS-v3 for complete evidence and limits.

Round1 FAIL and Round2 PASS remain historical. This is cumulative Round3/3, the ONE remaining normal
final round. Original execution task RELAY-GH1076-FINAL-20261015 is done; its token is not reset.
The shipped driver directs a fresh token when spent (utils/py/relay_drive.py:810). Supplemental token
RELAY-GH1076-FINAL-R3-20261015 executes this one round only, review-once, no force/extension/retry.
A nonapproval exhausts the original cap. Required final full push gate follows approved source freeze;
prior d1 full evidence is stale for the current source. Component study still pending is evidence-only.

Handing off to Reviewer — review the complete current scope and append only final Round3 findings.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
