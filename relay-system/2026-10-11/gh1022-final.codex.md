# RELAY · GH1022 staged implementation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
6. **Commit only the relay file** (`relay(gh1022-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Artifact: full committed diff from origin/development, PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md, shared library/10days adapters/planner core/weekly skill, and TESTS-RESULTS/2026-10-11+GH-1022.
- Operational envelope: staged, held single-repo discovery foundation; NOT umbrella completion. No branch reconciliation, freeze, dispatch or shared driver safeguards claimed shipped. All unimplemented acceptance is mapped in plan. No new CI tests/cases/gates allowed; grade proportionate to this milestone.
- Review the entire touched source files and evidence, not just diff. Independent plan/ownership QA receipts are in gh1022-plan.codex.md.
- Questions: (1) Are legacy CLI defaults/errors/projection/root/bucket/copy behavior preserved with explicit new Python/current-harness prerequisites? (2) Are paginated issues/PR files complete, qualified/deduplicated, with conflicting/foreign/offline/malformed reads UNKNOWN and no writes/checkpoint advancement? (3) Does weekly-intake route before scratch/capped fetch, reuse core advisory helpers and hold dispatch unconditionally? (4) Are any duplicate subsystem, hidden writer, new test/case/gate or unintended default policy change present? (5) Do source hashes/existing suite/manual negative controls support claims, and are missing #1022 phase criteria plainly held? (6) Compare latest target/base for redundancy/regression overlap; source implementation affects only this stage. Final classified docs/skill gate will run after review on the approved artifact; do not imply it already passed.
- Unapproved test proposals: none. No reviewer may recommend adding CI tests without individual operator approval. Review writes confined to relay file, no tests/fixtures/full gates/live dispatch in reviewer worktree.
- Output concrete graded findings, file/line citations, swept file and PASS/FAIL/PARKED verdict under protocol. Do not edit source.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The held architecture and source-bound evidence support this staged milestone, but malformed state values escape the promised UNKNOWN JSON contract. Resolve the focused finding below before approval; final clone gate/publication remain separate.
swept file: yes

- [Should] Validate state type before uppercasing in `skills/3-weekly/weekly-planner/scripts/issue_intake.py:166`. A null or numeric state raises AttributeError, which the weekly-intake error boundary at `planner_core.py:828–831` does not handle. Consumers receive no JSON observation rather than UNKNOWN. This remains fail-closed for dispatch, so it is not graded a data-loss blocker. Concrete fix: reject non-string states with ValueError before calling upper(); retain the existing valid-state allowlist. Record a manual negative control and valid-state control; no new CI case/suite/gate.
  Observed input: paginated issues response `[[{"number":1,"html_url":"https://github.com/example/repo/issues/1","title":"one","updated_at":"2026-10-11T00:00:00Z","state":null}]]`; same result for `state: 7`; PR response `[[]]`.
  Affected scope: issue/PR/prior-member records whose state is explicitly null or another non-string value at the shared normalization boundary.
  Falsifier: identical input with `state: "open"` must still return complete HELD with dispatch false; null/numeric inputs must produce UNKNOWN, complete false, dispatch false and exit 2 without partial success or writes. If that already happens on the reviewed bytes, this finding is unnecessary.
  Probe command (in-memory injected reads; no external commands, fixture executables or source edits):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 - <<'PROBE'
  import contextlib,io,json,sys,types
  from pathlib import Path
  def load(name):
      p=Path("skills/3-weekly/weekly-planner/scripts")/(name+".py")
      m=types.ModuleType(name); m.__file__=str(p.resolve())
      exec(compile(p.read_text(),str(p),"exec"),m.__dict__); return m
  m=load("issue_intake"); c=load("planner_core"); original=m.discover_weekly
  for state in ("open",None,7):
      row=dict(number=1,html_url="https://github.com/example/repo/issues/1",title="one",updated_at="2026-10-11T00:00:00Z",state=state)
      def runner(argv,root): return json.dumps([[row]]) if "/issues?" in argv[-1] else "[[]]"
      m.discover_weekly=lambda *a: original(*a,runner=runner)
      c.load_issue_intake=lambda:m
      sys.argv=["core","--mode","weekly-intake","--gh-repo","example/repo","--since","2026-10-01T00:00:00Z"]
      out=io.StringIO()
      try:
          with contextlib.redirect_stdout(out): c.main()
          result=json.loads(out.getvalue()); outcome=f'{result["status"]}, dispatch={result["dispatch_allowed"]}'
      except BaseException as e: outcome=f"{type(e).__name__}: {e}; stdout={out.getvalue()!r}"
      print(f"state={state!r}: {outcome}")
  PROBE
  ```
  Probe process exit 0 (exceptions intentionally captured for measurement); decisive output:
  ```text
  state='open': HELD, dispatch=False
  state=None: AttributeError: 'NoneType' object has no attribute 'upper'; stdout=''
  state=7: AttributeError: 'int' object has no attribute 'upper'; stdout=''
  ```
- [Pass] Preview routes before scratch/capped legacy reads (`planner_core.py:814–834`), reuses existing advisory functions (`:823–825`), and returns unconditional HELD/dispatch false (`issue_intake.py:258–262`). The new weekly skill explicitly holds ledger/freeze/dispatch and warns that advisory heuristics are not readiness (`skills/3-weekly/weekly/SKILL.md:15–19`, `:43–46`). Preserve this scope.
- [Pass] Transport uses paginated/slurped REST reads (`issue_intake.py:194–202`); prior members absent from the update window are refreshed (`:231–239`); PR-file count, shape and duplicate checks protect the file collection (`:248–254`). Qualified URL validation and conflicting normalized duplicates are explicit (`:145–191`). These are source findings, not an attestation of all malformed metadata.
- [Pass] Legacy extraction retains scan defaults/projection/200 ceiling (`issue_intake.py:61–89`), root precedence/jq handling (`:92–135`), first-match bucket traversal (`:41–58`), and a clear current-harness requirement (`intake_adapter.py:29–42`; `10days/SKILL.md`, “Python3 is required; copied installs must select a current harness”). Keep these interfaces. Retained gh369 logs report “14 pass / 0 fail”; manual-results records five baseline scan comparisons and copied-skill execution. These are recorded producer results, not reviewer suite runs.
- [Pass] The three `manual-results.json` source_hashes match current library, adapter and core bytes. Reviewer command: `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import hashlib,json,pathlib; d=json.loads(pathlib.Path("TESTS-RESULTS/2026-10-11+GH-1022/manual-results.json").read_text()); print([(p,hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()==h) for p,h in d["source_hashes"].items()])'` (equivalent hash loop executed within the first in-memory probe); process exit 0; all three comparisons True. Evidence contains offline/missing-file/conflicting/foreign controls and a removed-file red control; it does not cover the state-type failure above. Refresh hashes/evidence after the fix.
- [Pass] Existing outline policy weaknesses were swept: CI NONE readiness and unmet dependencies (`planner_core.py:199–241`), missing draft handling in legacy PR discovery (`:127–131`), and closure-number union (`:495–509`). They remain explicitly segregated in the plan's Remaining acceptance and preview warning (`:825`); this held milestone does not approve execution. No additional pre-existing defect requiring a change for this milestone found in the named source sweep.

Evidence limits: Verify-tier graph attempted via list_projects/index_status/search_graph and coverage. Nearest canonical XYZ-forge index is at a foreign root, generation 2026-09-01T15:54:30Z; search returned zero/no further page, coverage missing/not-tracked. Used full direct reads of the named library, adapter, shell entry points, planner core, weekly/10days skills, complete plan and existing gh369 suite, plus retained evidence and plan receipts. No source/artifact edits, Git commands, tests, pytest, executable fixtures, dispatch or external writes ran. [Unverified — needs clone run] Final classified gate remains pending, as stated in SUMMARY.md and the plan. Full committed diff inventory, absence of unrelated test/gate additions, and latest target/base redundancy comparison are not independently attested: no seeded diff/base comparison was available and this turn forbids Git. Have the outer harness check those before publication; do not infer them from this source sweep. Only the relay file was changed.

Handing off to Producer author — address the state-type finding, refresh manual evidence, and return for Round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
