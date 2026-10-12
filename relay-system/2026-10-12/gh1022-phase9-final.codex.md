# RELAY · GH1022 Phase9 preserved W7 caller final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Author
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
6. **Commit only the relay file** (`relay(gh1022-phase9-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: Author
- Started: 2026-10-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

Artifact scope: whole current core, whole canonical owner, weekly skill/main plan and relevant unchanged owner/planner/caller fixture sources. Candidate5c09a12c plus source-qualified evidence/doc commit; source hashes are in phase9-qualified.json. This is bounded genuinely new W7 caller/orientation functionality, not a reset of R6 or closed Phase8. Do not approve only a diff.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Implemented Approved Phase9 plan; independent finalQA pending within prior genuine-new-scope cap3.

Current core reuses existing runtime/preparation/census/private lock/receipt/writers. Canonical adapter swaps bounded delta orientation only, retains physical source/digest order/defaults. Cross-clone envelope retains original private fields/bytes and stops default/source writers; destination same preparation lock held through integration/prepare. Exact directory/bootstrap, parent/tree/blob/split-intent evidence gates resume; source worktree/HEAD retained. Canonical captures/intake accounted before native ancestry, then fresh broad prepare/no-op. Explicit published adoption/normalFF publication is opt-in with supplied normal-hook IO ceiling. No alias/schema/second ledger/orchestrator/gate/test framework or live action.

Current nine source-qualified flows passed (rollover/no-op; lost commit/clone/ancestry/split intent; competing destination writer; exact published adoption/localbare publication; six refusal batch; same-date advance). Earlier witnessed red failures and repairs retained. Existing disposable owner145/scoped27/planner-sourcePASS/rating16; full normal gate still pending. Current source hashes in phase9-qualified.json match source. Metadata/reporting is HELD; PR references are leads, reported done is not criterion evidence. Some nonempty PR, older cached-writer and exact normal-hook budget/interleavings remain explicitly unqualified—inspect limits rather than approving from empty input.

Read complete owners and surrounding code/plan/skills/covering existing fixture sources in paged chunks. Every behavior-change finding needs actual input/scope/falsifier; classify full-sweep limits honestly. No source edits, new agents, suites/executable fixtures, network/connectors/live actions or Git commands/writes except this relay; harmless in-memory source probes permitted. Preserve all R6FAIL6/6Medium1028,1027unapproved, closedPhase6/7/8 and Phase9planApprovedR1/3. No extra cap/tests granted by recent status messages. Full W8–11/1022 remains active. Handing off to Reviewer(codex)—take finalPhase9 Round1.


### Reviewer · Round 1

VERDICT: FAIL
Basis: The bounded caller has a concrete source-decision failure in exact interrupted-commit admission (S1). Fix or disposition it before approval. Runtime qualification and the requested whole-owner/whole-plan sweep remain incomplete; this is not W7, Phase9, publication or GH1022 approval.
swept file: no

- [Should] **S1 — pending preservation commits are admitted without accounting for the whole tree.** In `skills/3-weekly/weekly-planner/scripts/planner_core.py:1648–1653`, matching the first parent, pending ledger blobs and a clean worktree clears the intent and adopts HEAD. A clean committed unrelated change is invisible to those checks. The originating commit path likewise records only blobs (`:1662–1668`). In contrast, native ancestry recovery binds a full tree (`:1700–1708`). Bind the intended full result (or prove the complete parent-to-commit change set and exact blobs/modes) within this existing receipt/commit path, and reject additional committed changes before clearing intent. Do not add a store, gate or test suite.
  Observed input: source-decision probe below: parent `a*40`, HEAD `d*40`, pending `releases.db=b*40` and `releases.sql=c*40`, those live/committed blobs exact, clean worktree, but HEAD also changes `README.md` from `2*40` to `e*40`. Actual nested `commit` returns and changes `root_head` to HEAD/`pending_commit` to null. This is an in-memory decision reproduction, not a real Git crash/recovery run.
  Affected scope: reconciliation's `pending_commit` recovery when destination HEAD differs from the recorded parent; the same expected-result binding should cover the normal commit's completion before writing its receipt.
  Falsifier: exact parent plus ONLY the two intended ledger changes must remain adoptable; a mismatched ledger blob or additional README change must refuse and retain intent. The current code adopts the exact control and extra-README input, and refuses the wrong-ledger control.

  Quoted probe command (no subprocess, real Git, executable fixture or source write):
  ```bash
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PROBE'
  import ast
  from pathlib import Path
  p=Path('skills/3-weekly/weekly-planner/scripts/planner_core.py')
  r=next(n for n in ast.parse(p.read_text()).body
         if isinstance(n,ast.FunctionDef) and n.name=='reconcile_weekly')
  c=next(n for n in ast.walk(r)
         if isinstance(n,ast.FunctionDef) and n.name=='commit')
  for mode in ('exact','extra-readme','wrong-ledger'):
      before={'releases.db':'0'*40,'releases.sql':'1'*40,'README.md':'2'*40}
      after={**before,'releases.db':'b'*40,'releases.sql':'c'*40}
      if mode=='extra-readme': after['README.md']='e'*40
      if mode=='wrong-ledger': after['releases.db']='f'*40
      state={'root_head':'a'*40,'pending_commit':{'releases.db':'b'*40,'releases.sql':'c'*40}}
      def git(argv,root):
          if argv==['rev-parse','HEAD']: return 'd'*40
          if argv==['rev-parse','HEAD^']: return 'a'*40
          if argv[0]=='rev-parse' and argv[1].startswith('HEAD:'): return after[argv[1][5:]]
          if argv[0]=='hash-object': return after[argv[-1]]
          raise RuntimeError('unexpected read '+repr(argv))
      ns=dict(state=state,git=git,root=None,guard=lambda:None,
              dirty=lambda root:set(),durable=lambda *a:None,receipt_path=None)
      exec(compile(ast.Module(body=[c],type_ignores=[]),str(p),'exec'),ns)
      try:
          ns['commit'](list(state['pending_commit']),'unused')
          result='ADOPTED'
      except ValueError as e: result='REFUSED: '+str(e)
      print(mode,result,'changed_paths='+repr([k for k in after if before[k]!=after[k]]))
  PROBE
  ```
  Decisive observed output: `exact ADOPTED changed_paths=['releases.db', 'releases.sql']`; `extra-readme ADOPTED changed_paths=['releases.db', 'releases.sql', 'README.md']`; `wrong-ledger REFUSED: unknown committed handoff state`. The combined control/publication probe exited 1 AFTER these lines because my publication mock looked for `push` instead of `git push`; the earlier recovery-only probe exited 0 and separately printed `TREE_OR_CHANGED_PATH_READ: False` and `{"pending_commit": null, "root_head": "dddddddddddddddddddddddddddddddddddddddd"}`. The publication mock was corrected in the next probe (exit 0); this bookkeeping error is not an artifact failure.
  Root cause: the receipt records selected blobs but not the complete intended committed result; Fix site: existing reconciliation commit/receipt creation and admission; Why not upstream/downstream: clean committed extra paths already evade dirty-path checks, and clearing intent loses the opportunity to distinguish the unknown commit.

- [Unverified — needs clone run] **S2 — ordinary push does not establish installed normal hooks.** New destination creation is `planner_core.py:1596` (ordinary full clone); publication `:1800–1807` sends ordinary push and reports “normal hooks” without checking/wiring them. The existing installer explicitly states “A fresh clone or a second machine that has never run this has NO gate” (`githooks/install.sh:25–28`). A source AST scan over the complete reconciliation function returned `RECONCILE_HOOK_INSTALL_OR_CHECK_LITERALS: []` (exit 0). A corrected in-memory publication-leaf probe with publish=true, timeout=600 and absent remote branch returned exactly `ls-remote; git push origin HEAD:refs/heads/auto-2026-10-12; ls-remote`, then `publication_effects="explicit ordinary fast-forward Git push and normal hooks; no force/dispatch/merge"` (exit 0). Neither probe proves actual hook behavior. In a disposable full clone, measure a freshly created destination with ordinary default hook configuration and a witnessed refusing normal hook, and disposition whether the existing installation/check workflow must be reused before publication. No new gate machinery requested. The injected localbare qualification and configured timeout alone do not establish this property or a real hook ceiling.

- [Pass] Orientation uses the existing selector with an opt-in policy and retains physical source metadata: `utils/py/releases_app.py:6571–6574` swaps only selected table roles; its return retains original parsed source digests/generations; recovery `:6708–6712` and check `:6794` pass the declared orientation, and `:6768–6769` binds the receipt to physical source index 1. This is source inspection, not independent delta-mode runtime qualification.
- [Pass] Current core/owner source hashes match the frozen qualification manifest. Command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `import hashlib,json; from pathlib import Path; e=json.loads(Path('TESTS-RESULTS/2026-10-11+GH-1022/phase9-qualified.json').read_text()); [print('SOURCE_HASH_MATCH',f,hashlib.sha256(Path(f).read_bytes()).hexdigest()==h) for f,h in e['source_sha256'].items()]`, then `PY`. Exit 0; decisive output `SOURCE_HASH_MATCH utils/py/releases_app.py True` and `SOURCE_HASH_MATCH skills/3-weekly/weekly-planner/scripts/planner_core.py True`. The manifest's nine rc0 records remain producer evidence, not reviewer-reexecuted flows (`phase9-qualified.json:7–47`).
- [Unverified — needs clone run] Nonempty associated PR/accounting, an older cached source writer, full interrupted transfer/interleavings, normal-hook publication and the final harness gate remain unqualified here, as already disclosed in `PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:1330–1332`. No validate/test/pytest/executable fixture, network, connector, live operation or Git command was run.

Sweep/graph limits: read the complete reconciliation and surrounding preparation/runtime/census/main paths, legacy planner paths, weekly skill and relevant planner-skill sections; inspected canonical selector/input/recovery/apply/staged-builder source (`releases_app.py:6489–7047`) and Phase9 plan/checkpoint/earlier plan-review receipt. Some multi-file read outputs were truncated and explicitly not counted as complete. I did NOT complete the entire 7,552-line owner, 1,332-line main plan or all unchanged fixture-source sweeps. Consequently there is no whole-file/pre-existing-defect clearance; the full-sweep requirement remains outstanding. S1 is in the new caller; no additional pre-existing defect is asserted from partial coverage.

Verify-tier graph lookup: paginated all 82 projects; none matched this worktree/task clone. Nearest primary-checkout `XYZ-forge` coverage generation `2026-09-01T15:54:30Z`; planner search returned 0/no more. Coverage for owner/planner/intake reported respectively metadata_changed/not_tracked/missing. Candidate direct source and quoted probes are the evidence; no completeness claim uses this stale/foreign graph.

Only this relay file changed. Preserve R6 FAIL6/6 / Medium GH1028, GH1027 unapproved, closed Phase6/7/8 and Phase9 plan ApprovedR1/3; no new cap, tests or agents, and W8–W11/full GH1022 remain active.

Handing off to Author — disposition S1, qualify/disposition S2 and remaining review limits within existing authority, then go to the Author window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
