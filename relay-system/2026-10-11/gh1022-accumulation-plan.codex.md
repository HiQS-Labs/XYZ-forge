# RELAY · GH-1022 phase 4 canonical accumulation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
6. **Commit only the relay file** (`relay(gh1022-accumulation-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md`, specifically Phase 4 active design; ground against full shared intake/core, canonical releases_app/HQ/planner source and governance.
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Definition of Done: Review the next canonical accumulation phase against current #1022 requirements and source owners. Does this remain least-mechanism canonical CLI reuse, preserve ratings/GIDs/status/owner edits, handle full initial/retained membership, concurrency/recovery and unchanged runs without a second orchestrator? Identify concrete unknown policy inputs and minimal safe implementation boundaries. No full umbrella acceptance claim. No new test/case/gate/runner, no dispatch or live writes. Reviewer may read sources and execute only harmless read/in-memory probes; do not run mutation-heavy suites/gates, Git/gh/external writes, source changes or extra agents in this reviewer worktree. Only this relay file may change. Independent plan review before source implementation; same authorized Codex harness, not an extra advisor.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Published staged draft #1024 at d7ef2bc9. Required continuation W6/W7 is active: concrete Phase 4 design appended at eb85e2da. Full issue/comments and current source recon already retained. Review this design as a separate next-phase plan; prior final QA budget covered the foundation implementation, not this new policy design. Do not approve any unimplemented behavior as delivered. Preparation flags leave unresolved operator policy explicit; writes remain local only and held. No test approvals or execution authority inferred.

### Reviewer · Round 1

VERDICT: FAIL
Basis: the held canonical-writer design is sound in outline, but its assertion that authoritative planner reuse preserves override ranking is false in current source. Resolve that boundary before implementation; this is plan QA, not umbrella acceptance or runtime delivery approval.
swept file: yes

- [Should] Reconcile the rank contract before promising authoritative selection (plan `PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:239`). `releases_app.py:4455` says override wins; `RELEASES-DB-FAQS.md:145` requires it. `_marathon_plan.py:786` selects no `rating_ovr` and line 791 uses only the sum. An in-memory execution of the actual AST-extracted `_load_ledger_from_db` returned 210 for axes 70/65/50/25 with override 320. Cheapest fix: expose axes/override/effective rank through the canonical reader, explicitly document this existing planner limitation, and hold selection until a separately reviewed canonical-owner correction; accumulation alone need not expand into planner repair.
  Observed input: in-memory roadmap row `(1022,70,65,50,25,'rmi-probe','PROJECT/1-INBOX/GH-1022.md','probe',320)`; actual `db_ranks={1022:210}`, expected effective rank 320.
  Affected scope: fully rated ledger rows with a non-null override differing from their sum; ordinary unrated/NULL-gh rows must retain their existing identity and hold semantics.
  Falsifier: remove the override from the same row: expected rank 210; unchanged non-override results would disprove a need to alter that scope. A real canonical planner run yielding 320 for the override row would disprove the finding.
  Probe command (exit 0; no filesystem DB or full engine invocation):
  ```python
  # Executed via: PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
  import ast, sqlite3, types
  from pathlib import Path
  from contextlib import closing
  p=Path('utils/py/_marathon_plan.py')
  tree=ast.parse(p.read_text())
  fn=next(n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='_load_ledger_from_db')
  c=sqlite3.connect(':memory:')
  c.execute('CREATE TABLE roadmap_items(gh_number, rating_pri, rating_sev, rating_appeal, rating_effort, global_id, doc_path, title, rating_ovr)')
  c.execute("INSERT INTO roadmap_items VALUES(1022,70,65,50,25,'rmi-probe','PROJECT/1-INBOX/GH-1022.md','probe',320)")
  ns={'closing':closing,'sqlite3':types.SimpleNamespace(connect=lambda *a,**k:c,Row=sqlite3.Row,Error=sqlite3.Error),'Path':Path,'roadmap_render':lambda conn:'','EngineExit':RuntimeError}
  exec(compile(ast.Module(body=[fn],type_ignores=[]),str(p),'exec'),ns)
  result=ns['_load_ledger_from_db'](types.SimpleNamespace(_parse_ledger=lambda text:[]), '/nonexistent-in-memory-probe')
  print('input: axes=70/65/50/25 rating_ovr=320; expected override rank=320; actual planner db_ranks=',result[1])
  print('control: without override expected sum=210; actual=',result[1][1022])
  # PY
  ```
  Decisive output: `actual planner db_ranks= {1022: 210}`. The second printed control is a sum comparison, not a second override-free execution; no end-to-end selection claim is made.
- [Nit] Name the held resume outcome when the canonical target advances. Plan line 259 says create/resume from the exact refreshed target SHA, while lines 268/273 preserve accumulated owner state and forbid automatic merge-rebuild. Add a sentence: existing branch base differs from refreshed target → report both SHAs, retain branch/checkpoint, hold for explicit reconciliation. Specify the receipt/accounting path and checkpoint cut as run-start UTC with inclusive overlap, so recovery/no-change verification has a precise contract. These are missing plan details, not claimed observed runtime failures.
- [Nit] Refresh the cold-reader pointers: plan frontmatter `phases: 3`, status row at line 21 and TOC at line 23 omit the active Phase 4. Make next-up the separate accumulation review/implementation and distinguish historical foundation approval.
- [Pass] The proposed accumulation path preserves the existing write owner and the dispatch hold: plan lines 264–279 require CLI writes with connectors disabled, untouched existing rows/captures, complete accounting before checkpoint advance and no-change no-commit. `releases_app.py:1657` owns the journal/transaction/generation/receipt/dump protocol, and `hq-lib.sh:423` owns capture rendering with `ratings_provisional: true`. Retain these boundaries; do not import `ingest_weekly_intake`'s fallback/scratch behavior (`planner_core.py:537–584`) into weekly preparation.

Evidence limits: nearest available graph is XYZ-forge at the primary checkout, generation 2026-09-01T15:54:30Z, not this reviewer worktree. Graph searches returned no relevant nodes; coverage reports changed metadata, untracked planner_core and missing issue_intake. Used exact current-worktree source reads instead. Read the entire 294-line artifact, including prior dispositions; the stale phase/status pointers above are the additional pre-existing doc findings. No Git, external queries/writes, suites, fixtures, extra agents or source edits were run. Concurrent writes, crash recovery, branch resume and no-change behavior remain [Unverified — needs clone run]. Latest live issue comments/target drift were not independently queried in this read-only turn; no current-target conformance claim is made.

Handing off to Producer (author) — disposition the rank finding and clarify the plan, then open Round 2.

### Producer · Round 2
Should implemented in design, not source: canonical-owner override omission is explicit; accumulation exposes truthful existing-ledger axes/override/rank, selection stays HELD until separately reviewed W8 owner correction. Never add a weekly scorer. Nits implemented: target drift on resume holds preserving existing state and names SHAs; committed accounting/local recovery paths explicit; run-start UTC and caller-supplied inclusive overlap; unchanged run retains old cut/commit. Frontmatter/status/TOC now include Phase 4. Existing canonical ledger suite in disposable clone: 145 passed, 0 failed, HEAD/origin preserved. No new tests or source code yet. Re-review this narrowed accumulation design; no need to approve future W8 implementation or whole umbrella. Only this relay file may change.

### Reviewer · Round 2

VERDICT: PASS
Basis: approve the narrowed Phase 4 accumulation design for implementation. The canonical rank gap is explicitly held for W8; this verdict neither approves that future correction nor attests delivered accumulation behavior or umbrella acceptance.
swept file: yes

- [Pass] Round 1 rank finding is dispositioned without a second scorer: `PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:240–250` extends the existing reader, preserves owner ratings/overrides and holds selection pending canonical-owner correction. Current JSON omission is visible at `utils/py/releases_app.py:4439–4445`; the human reader's override contract is at `:4455–4462`. The in-memory probe below reproduces the planner omission at `utils/py/_marathon_plan.py:787–795` and now executes the actual override-free control. Retain both controls in W8's durable verification; no planner repair is authorized by this review.
- [Pass] Resume and no-change contracts now have concrete accounting boundaries: plan `:264–274` names target-drift hold, both SHAs, retained branch/checkpoint, committed intake and Git-dir recovery paths, run-start UTC, inclusive overlap and unchanged-cut retention. Initial backfill and retained/carryover/dependency membership remain explicit; ambiguous dependencies hold. Keep these as final implementation acceptance criteria.
- [Pass] Canonical write ownership and preservation are retained at plan `:275–290`: sanctioned capture/CLI calls, connectors disabled, unchanged captures/rows, per-write generation checks, partial receipts, commit before checkpoint and no blanket reset. `releases_app.py:1657–1773` owns lock/journal/transaction/receipt/dump durability; `hq-lib.sh:423–431` owns capture rendering. These source boundaries support reuse; they do not prove the proposed concurrency or recovery behavior.
- [Pass] Cold-reader pointers reflect Phase 4 at plan `:13`, `:21`, `:28`; verification and unresolved policy remain explicit at `:296–305`. No additional unresolved pre-existing defect was found in the full 309-line plan sweep. The historically documented planner/readiness limitations remain held, not silently approved.

Probe command (exit 0; AST-extracted actual reader, SQLite memory only; no engine/fixture execution):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, sqlite3, types
from pathlib import Path
from contextlib import closing
p=Path('utils/py/_marathon_plan.py')
fn=next(n for n in ast.walk(ast.parse(p.read_text())) if isinstance(n,ast.FunctionDef) and n.name=='_load_ledger_from_db')
for override in (320,None):
    c=sqlite3.connect(':memory:')
    c.execute('CREATE TABLE roadmap_items(gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,global_id,doc_path,title,rating_ovr)')
    c.execute('INSERT INTO roadmap_items VALUES(?,?,?,?,?,?,?,?,?)',(1022,70,65,50,25,'rmi-probe','PROJECT/1-INBOX/GH-1022.md','probe',override))
    ns={'closing':closing,'sqlite3':types.SimpleNamespace(connect=lambda *a,**k:c,Row=sqlite3.Row,Error=sqlite3.Error),'Path':Path,'roadmap_render':lambda conn:'','EngineExit':RuntimeError}
    exec(compile(ast.Module(body=[fn],type_ignores=[]),str(p),'exec'),ns)
    result=ns['_load_ledger_from_db'](types.SimpleNamespace(_parse_ledger=lambda text:[]),'/nonexistent-in-memory-probe')
    print('override=%r actual=%r expected=%r' % (override,result[1],override if override is not None else 210))
PY
```
Decisive output:
```text
override=320 actual={1022: 210} expected=320
override=None actual={1022: 210} expected=210
```

Evidence limits: Verify-tier discovery used the nearest indexed primary XYZ-forge project, generation 2026-09-01T15:54:30Z; all 82 project listings were paginated, and this worktree has no matching index. Relevant graph search was fully returned but stale. Coverage flagged changed releases/planner/HQ metadata, absent plan/issue_intake and untracked planner_core; current-worktree source reads supplied the material evidence instead. SWE rubric applied to the whole plan. No Git, external issue queries, suites, executable fixtures, extra agents, artifact/source changes or live application writes were performed. Producer's 145/0 clone run is reported evidence, not independently reproduced here. Concurrent edits, partial-write/commit recovery, branch resume, backfill and no-change behavior remain [Unverified — needs clone run]; final source QA and exact-revision gates remain required.

Relay closed (Approved), no further turn needed. Producer (author) continues the separately verified implementation with selection and dispatch held.  [Unverified — no citation]


### Attestation · relay-drive — 2026-10-11T16:54:35Z
task: GH1022-ACCUMULATION-PLAN-R2
reviewer: codex
status: Approved
reviewed-head: 8de581dbf5c34e6346651737cd6625becb7f2ab6
added-range: 12944+4671
added-sha256: f47a8040bd9cb9b7413faba420e33cc39bab5d206679dd468544675cbb3029a1
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
