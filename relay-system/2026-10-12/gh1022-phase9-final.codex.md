# RELAY · GH1022 Phase9 preserved W7 caller final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Author
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

### Producer · Round 2

VERDICT: PARKED
Basis: S1 implemented and S2 qualified/repaired at source commit50b4a78e; same artifact/token/cap, Round1 preserved. Independent Round2 pending.

- S1 Implemented: the existing pending commit receipt now persists native `git write-tree` after proving staged paths are owned, before commit. Both normal completion and lost-result adoption require the exact full tree plus parent/blobs/live bytes/clean state before clearing intent. Actual Git extra-README red and current refusal are retained; exact lost-commit control still resumes. Unknown committed work and intent remain intact. No new receipt store/schema/gate.
- S2 Implemented/qualified: actual fresh-clone hook absence allowed the earlier ordinary push (red retained). Reuse runtime-pinned `githooks/install.sh --check`, ordinary installer, then check; absent/foreign/bypassed/unknown hooks hold. Current actual installed hook runs, refusing hook blocks publication with local state retained, retry runs the same hook before exact remote readback. Actual subprocess publication timeout leaf stops its owned group; this is NOT a whole-caller budget proof.
- Qualification: `phase9-r2-qualified.json` binds 12 rc0 owned temporary flows to both source hashes at50b4a78e, including same-date, recovery, competing default writer, negative-input batch, hook installed/refusal/timeout leaf and unknown-tree hold. Existing disposable planner source suite and rating16 pass. Earlier qualified manifest/R1/red receipts remain historical, not current approval. No permanent tests/cases/parametrizations/registry changes.
- R1 incomplete sweep remains open: read whole current core, whole 7,552+line canonical owner, whole main plan, weekly skill and relevant unchanged owner/planner/caller fixture sources in bounded pages that do not truncate. Declare swept file honestly; no diff-only approval. Source-only review with harmless in-memory probes; no suites/executable fixtures/network/connectors/subagents/live actions or Git except this relay. Require citations and actual failing inputs for requested behavior changes.
- Remaining limits: nonempty associated PR/accounting, older cached writer and exhaustive interrupted-transfer interleavings/full normal gate remain unqualified. Findings cannot be cleared by empty census. Metadata delivery remains UNKNOWN/HELD. W8–W11/full1022 active. Preserve R6FAIL6/6/Medium1028,1027unapproved, closedPhase6/7/8 and Phase9planApprovedR1/3. No cap extension or new test authority.

Handing off to Reviewer(codex) — take Phase9 final Round2 within the same three-round cap.

### Reviewer · Round 2

VERDICT: FAIL
Basis: S1's tree repair passes the bounded source controls and S2 now reuses the installed-hook workflow. Exact interrupted-commit admission still accepts an unexpected second parent (S3), clearing the intent for an unknown history result. Repair or disposition that concrete input within the existing cap. This verdict does not reopen R6 or closed Phase6/7/8.
swept file: yes

- [Should] **S3 — exact ordinary preservation recovery checks only the first parent.** `planner_core.py:1653` uses `HEAD^`, and normal completion at `:1677` has the same predicate. An unexpected merge commit with the intended tree, exact blobs/live bytes, clean state and first parent equal to `root_head` is adopted; its additional parent is never inspected. The caller's separate native ancestry recovery already checks the complete ordered parent list (`:1713–1717`). Reuse that native parent-list read for ordinary preservation completion/admission and require the intended single parent before clearing intent. Keep the separate intentional ancestry merge's two-parent contract; no new store, suite or gate.
  Observed input: actual nested `commit` AST executed in memory with `root_head=a*40`, `pending_tree=c*40`, pending `releases.db=b*40`, HEAD `d*40`, parents `[a*40,e*40]`, tree `c*40`, matching live/committed blob `b*40`, clean state. It returns, advances `root_head` and clears `pending_commit`; no full-parent read occurs. This is an observed source-decision failure, **not** an executed Git merge/crash fixture.
  Affected scope: ordinary pending-preservation result admission and normal preservation commit completion; commits intended to have exactly the recorded previous HEAD as their sole parent. Intentional native ancestry integration remains separately governed.
  Falsifier: sole parent `[a*40]` with exact tree/blobs must adopt; extra parent `[a*40,e*40]`, wrong first parent or wrong tree must refuse and retain intent. Current exact/wrong-first-parent/wrong-tree controls behave accordingly, but extra-parent adopts. In a disposable clone, an extra-parent lost-result control that already refuses through another caller predicate would narrow or disprove the end-to-end impact; record it before claiming actual Git qualification.
  Root cause: first-parent identity is treated as complete parent identity; Fix site: existing commit completion/admission predicates; Why not upstream/downstream: a clean committed result contains no dirty-path signal, and clearing the receipt loses the distinction. The existing ancestry path demonstrates the native full-parent mechanism.

  Quoted source-decision command (no subprocess, Git execution, executable fixture or source write):
  ```bash
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PROBE'
  import ast
  from pathlib import Path
  p=Path('skills/3-weekly/weekly-planner/scripts/planner_core.py')
  r=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='reconcile_weekly')
  c=next(n for n in ast.walk(r) if isinstance(n,ast.FunctionDef) and n.name=='commit')
  for mode in ('exact','extra-parent','wrong-first-parent','wrong-tree'):
      parents=['a'*40]+(['e'*40] if mode=='extra-parent' else [])
      if mode=='wrong-first-parent': parents[0]='f'*40
      state={'root_head':'a'*40,'pending_commit':{'releases.db':'b'*40},'pending_tree':'c'*40}
      reads=[]
      def git(argv,root):
          reads.append(argv)
          if argv==['rev-parse','HEAD']: return 'd'*40
          if argv==['rev-parse','HEAD^']: return parents[0]
          if argv==['rev-parse','HEAD^{tree}']: return ('f' if mode=='wrong-tree' else 'c')*40
          if argv[0] in ('hash-object','rev-parse'): return 'b'*40
          if argv==['rev-list','--parents','-n','1','HEAD']: return ' '.join(['d'*40,*parents])
          raise AssertionError(argv)
      ns=dict(state=state,git=git,root=None,guard=lambda:None,dirty=lambda root:set(),durable=lambda *a:None,receipt_path=None)
      exec(compile(ast.Module(body=[c],type_ignores=[]),str(p),'exec'),ns)
      try: ns['commit'](['releases.db'],'unused'); result='ADOPTED'
      except ValueError as e: result='REFUSED '+str(e)
      print(mode,result,'parent_count='+str(len(parents)),'intent_retained='+str(state['pending_commit'] is not None),'all_parents_read='+str(any(x[0]=='rev-list' for x in reads)))
  PROBE
  ```
  Exit 0; decisive output:
  ```text
  exact ADOPTED parent_count=1 intent_retained=False all_parents_read=False
  extra-parent ADOPTED parent_count=2 intent_retained=False all_parents_read=False
  wrong-first-parent REFUSED unknown committed handoff state parent_count=1 intent_retained=True all_parents_read=False
  wrong-tree REFUSED unknown committed handoff state parent_count=1 intent_retained=True all_parents_read=False
  ```

- [Pass] **S1 full-tree repair, limited to its stated data predicate.** `planner_core.py:1672–1675` rejects unaccounted staged paths and records native `write-tree`; `:1651–1657` and `:1677–1680` require that tree before completion. Independent in-memory execution of the actual nested AST gave `exact ADOPTED intent_retained=False`; extra-tree, wrong-parent, wrong-blob and dirty each gave `REFUSED unknown committed handoff state intent_retained=True` (exit 0). Removing only the two tree predicates in an in-memory AST copy changed extra-tree to `ADOPTED intent_retained=False`, witnessing the control's sensitivity. Retained actual producer evidence separately says `EXTRA_TREE_HELD unknown committed handoff state` and `INTENT_AND_OWNER_WORK_PRESERVED` (`TESTS-RESULTS/2026-10-11+GH-1022/phase9-r2-extra-tree-hold.log:3–4`); the old observed admission remains in `phase9-r1-extra-tree-red.log:3`. S3 above prevents treating this as full commit-identity clearance.
- [Pass] **S2 source repair uses the existing hook owner.** Runtime loading pins `hook_installer` (`planner_core.py:1385–1386`); publication performs check/install/check before push (`:1803–1818`). `githooks/install.sh:64–91` checks executable marked stub and rejects overriding hooksPath; its installation refuses foreign configuration/hooks. Producer evidence retains `FRESH_HOOK_PRESENT False` / `ORDINARY_PUSH_SUCCEEDED_WITHOUT_HOOK` (`phase9-r1-hook-absence-red.log:2–3`), current refusing push (`phase9-r2-hook-refusal.log:2`), and current timeout plus unchanged remote (`phase9-r2-hook-timeout.log:932–933`). These are inspected producer controls, not reviewer-reexecuted hook or full-budget qualification. The empty-env suspicion was falsified: `${XYZ_SKIP_PREPUSH:-0}` in `githooks/pre-push:82` and the installer's fallback defaults empty to zero, consistent with the caller's `('', '0')` allowance.
- [Pass] **Nonempty accounting decision leaf retains holds.** Independently compiled only `planner_core.py:1770–1798` with one issue77, one completed lifecycle fact and a draft PR. Exit 0: bodies `fixes #77` and the exact `fixture/repo/issues/77` URL produce `REVIEW_OR_LANDING leads=1`; `fixes #777`, `other/repo/issues/77` and unrelated text produce `HELD leads=0`. All five retain `UNKNOWN; reported completion is not criterion evidence`. This measures that leaf, not a full nonempty GitHub/caller flow. Command method: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PROBE'`, AST-extract the contiguous accounting assignments/loop preceding `if args.publish`, compile in memory with the stated nonempty dictionaries and a stubbed canonical reported-state function, print decision/lead-count/delivery, then `PROBE`.
- [Pass] **Qualification manifest identifies the current source bytes.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `import hashlib,json; from pathlib import Path; e=json.loads(Path('TESTS-RESULTS/2026-10-11+GH-1022/phase9-r2-qualified.json').read_text()); [print('SOURCE_HASH_MATCH',f,hashlib.sha256(Path(f).read_bytes()).hexdigest()==h) for f,h in e['source_sha256'].items()]`, then `PY`. Exit 0: both owner and core `SOURCE_HASH_MATCH ... True`. The manifest's twelve rc0 entries remain producer evidence; this does not independently prove their runtime execution.
- [Nit] **Weekly capability prose contradicts its new section.** `skills/3-weekly/weekly/SKILL.md:89` still says “Durable reconciliation and rollover remain unimplemented,” and `:193` calls it a “separate unimplemented caller”; the later “Preserved reconciliation and rollover (implementation under verification)” section describes the implemented caller. Qualify those earlier sentences as prior-mode limits or point them to the current under-verification section, while keeping global coordination/dispatch limits explicit.
- [Unverified — needs clone run] Full nonempty associated-PR/caller accounting, older cached-source-writer execution, exhaustive interrupted-transfer interleavings, actual normal-hook/full-caller IO qualification and final harness gate remain unqualified here. The user reserves suites/executable fixtures for a disposable full clone; none were run. R2 source hashes match, but `provenance.jsonl`'s last entry is still `phase9-r1-repairs`, listing R1 repair logs rather than the new twelve-flow R2 manifest. Add the R2 run attribution to the existing provenance ledger before citing those reruns as independent qualification; preserve historical entries.

Sweep: read complete current `planner_core.py` (1,990 lines), canonical `releases_app.py` (7,552), main plan (1,363), both weekly skills and shared intake (369), plus unchanged `gh32-releases-app.sh`, `gh32-releases-artifacts.sh`, `gh360-scoped-receipt-chain-rebuild.sh`, `gh418-planner-ledger-source.sh` and `gh698-planner-db-ratings.sh` source. Truncated multi-file outputs were not counted for omitted spans; those source spans were reread in smaller pages. This includes pre-existing writer/read/schema/dump/recovery/default CLI paths, not just the new diff. No additional newly witnessed pre-existing defect is asserted beyond the already documented legacy advisory heuristics and R6/GH1028 limitation; this is not an all-CRUD concurrency or fleet-completeness guarantee.

Verify-tier graph: all82 projects enumerated, no matching worktree/task root. Nearest primary `XYZ-forge` generation `2026-09-01T15:54:30Z`; reconcile lookup0/no more. Coverage checked exact core/owner/intake/skills/plan/installer/fixture paths: changed/missing/not-tracked primary metadata, plus gh32 parse-partial237 (read directly). Evidence comes from current direct source, not this stale foreign graph; no reindex or negative claim relies on it.

Only this relay tracked file changed; scratch directory only under `.relay-scratch/`. No Git command, suite, pytest, executable fixture, network/connectors, live operation or extra agent was used. The absolute pinned tick's `release --help` returned usage/exit2 (unsupported help flag); it made no release. Preserve R6FAIL6/6 / MediumGH1028, GH1027 unapproved, closedPhase6/7/8 and Phase9planApprovedR1/3. No new cap/tests/agents; W8–W11/fullGH1022 remain active.

Handing off to Author — disposition S3, correct the capability prose and R2 attribution, and retain the qualification limits; go to the Author window and say 'take your turn'.

### Producer · Round 3

VERDICT: PARKED
Basis: S3 repaired atd9e7d6a7, exact frozen source requalified; final independent round pending in SAME cap3/artifact/token. No extra allowance requested or inferred.

S3 Implemented: actual native Git commit-tree two-parent ordinary result with exact intended tree/first parent/blobs and clean state was admitted before repair (`phase9-r2-extra-parent-red.log`). Both ordinary admission/completion now read the complete native rev-list parents and require exactly [recorded previous HEAD]. The intentional ancestry merge retains its separate exact ordered two-parent contract. Current actual extra-parent flow refuses, retaining exact intent/unknown HEAD/predecessor; exact single-parent lost commit and intentional lost two-parent ancestry still resume (`phase9-r3-extra-parent-hold.log`, `phase9-r3-commit-loss.log`, `phase9-r3-ancestry-loss.log`). No new store/schema/gate/CI case.

Nit Implemented: earlier weekly prose now points observation/API limits to implemented reconciliation section under verification. Attribution Implemented: append-only existing provenance now binds R2 twelve flows/nonempty PR/full Git red plus R3 fourteen flows and disposable existing suites. Wrong helper identity/unused Path expression errors were corrected without product changes and retained; these are helper errors, not product reds. Current `phase9-r3-qualified.json` matches owner/core source bytes atd9; fourteen flows rc0, including full nonempty draft PR + foreign same-number link (UNKNOWN delivery), actual parent refusal, recovery/interleavings already scoped, normal installed/refusing hooks/timeout leaf/same-date. Existing gh418 PASS, gh69816/0 and disposable Git identity preserved. No full normal gate claimed yet.

Review whole current core/owner/plan/skills/covering unchanged fixture sources; R2 whole sweep yes is retained, not reset. Independent controls/citations/actual input/scope/falsifier remain required. Source-only: no new agent, suite/executable fixture/network/connectors/live action or Git except relay. Remaining older cached-writer/exhaustive interleavings/whole-caller budget qualification limits are explicit; do not invent a blanket guarantee. Default advisory heuristics and original R6/GH1028 remain separately documented, not silently repaired by this scope. W8–W11/full1022 incomplete; no firing/landing authority or universal idle proof. Keep closed Phase6–8, Phase9planApprovedR1/3, R6FAIL6/6/Medium1028 and1027 unapproved immutable. If new finding remains at cap, escalate honestly rather than reset.

Handing off to Reviewer(codex) — take final Phase9 Round3 within the existing cap.


### Reviewer · Round 3

VERDICT: FAIL
Basis: S3 is repaired at both ordinary preservation boundaries, but S4 observes the same incomplete result identity in the existing final preparation commit reached by this caller. At Round3/3 this relay is Escalated, without resetting the cap or authorizing more work. This is a source-decision failure; actual end-to-end Git/hook impact still needs a disposable-clone control.
swept file: no

- [Should] **S4 — final preparation certifies selected blobs and first parent, not the complete intended commit.** The caller invokes `prepare_weekly` at `skills/3-weekly/weekly-planner/scripts/planner_core.py:1759–1761`. Its existing final commit leaf (`:1349–1373`) stages and checks selected objects, then checks only `HEAD^`, ledger/generation and those objects before persisting `complete_commit`. It does not bind the intended full tree or full parent list. The subsequent reconciliation check (`:1769–1771`) tests HEAD against that newly certified commit and dirty state, so a clean committed extra path/additional parent has no distinguishing signal there. Extend this existing preparation completion boundary using the native intended-tree and exact single-parent checks already used by reconciliation's preservation commit; retain intent/unknown results rather than certifying them. Do not add a store, suite or gate.
  Observed input: actual preparation final-commit AST leaf below, recorded predecessor `a*40`, returned HEAD `d*40`, exact branch/base/ledger/generation, all intended staged/live/committed blobs `b*40`. With an extra committed `README.md` change (`3*40 -> f*40`) it returns `changed=True` and records `complete_commit=d*40`. Separately, with parents `[a*40,e*40]` and the exact intended paths it also records completion. Exact control completes; wrong-owned-blob refuses. These are in-memory decisions with mocked native reads, not real Git fixture runs.
  Affected scope: final local `prepare_weekly` commit completion, including reconciliation's delegated fresh preparation. This is pre-existing source in the touched core, not a request to reopen legacy readiness heuristics, R6 or closed Phase6–8.
  Falsifier: exact intended full staged tree with sole recorded previous HEAD must complete; extra committed README or extra parent must refuse and retain uncompleted evidence. A disposable-clone control showing that the caller already rejects either concrete result before checkpoint completion would narrow or disprove its end-to-end impact; record that evidence before claiming runtime qualification.
  Root cause: the final preparation boundary still treats selected blob/first-parent checks as complete commit identity. Fix site: existing preparation staging/completion. Why not upstream/downstream: before-commit checks cannot certify the returned result, and downstream compares against the same already-certified HEAD; a clean result carries no dirty-path signal.

  Quoted command:
  ```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import ast
from pathlib import Path
p=Path('skills/3-weekly/weekly-planner/scripts/planner_core.py')
f=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='prepare_weekly')
t=next(n for n in ast.walk(f) if isinstance(n,ast.With) and any(isinstance(s,ast.Assign) and any(isinstance(x,ast.Name) and x.id=='owned' for x in s.targets) for s in n.body))
start=next(i for i,s in enumerate(t.body) if isinstance(s,ast.Assign) and any(isinstance(x,ast.Name) and x.id=='owned' for x in s.targets))
leaf=ast.FunctionDef(name='leaf',args=ast.arguments(posonlyargs=[],args=[],kwonlyargs=[],kw_defaults=[],defaults=[]),body=t.body[start:],decorator_list=[])
module=ast.fix_missing_locations(ast.Module(body=[leaf],type_ignores=[]))
for mode in ('exact','extra-readme','extra-parent','wrong-owned-blob'):
    previous='a'*40; current='d'*40; base='c'*40; blob='b'*40
    parents=[previous]+(['e'*40] if mode=='extra-parent' else [])
    before={'releases.db':'0'*40,'releases.sql':'1'*40,'PROJECT/4-MISC/weekly/2026-10-12/intake.json':'2'*40,'README.md':'3'*40}
    after={**before,'releases.db':blob,'releases.sql':blob,'PROJECT/4-MISC/weekly/2026-10-12/intake.json':blob}
    if mode=='extra-readme': after['README.md']='f'*40
    if mode=='wrong-owned-blob': after['releases.sql']='f'*40
    reads=[]; committed=False
    def git(argv,root):
        global committed
        reads.append(argv)
        if argv[0]=='commit': committed=True; return ''
        if argv[0]=='add': return ''
        if argv==['branch','--show-current']: return 'auto-2026-10-12'
        if argv==['rev-parse','HEAD']: return current if committed else previous
        if argv==['rev-parse','HEAD^']: return parents[0]
        if argv[0]=='hash-object': return after[argv[-1]] if committed else blob
        if argv[0]=='rev-parse' and argv[1].startswith('HEAD:'): return after[argv[1][5:]]
        if argv[0]=='rev-parse' and argv[1].startswith(':'): return blob
        raise AssertionError(argv)
    state={'paths':{},'ledger_rows':[{'global_id':'fixture'}],'generation':5}
    ns=dict(state=state,git=git,root=None,relative='PROJECT/4-MISC/weekly/2026-10-12/intake.json',
            accounting=[],capture_objects={},base=base,preparation_head=previous,branch='auto-2026-10-12',
            date='2026-10-12',repository='fixture/repo',target_head=lambda root:base,rows=lambda:state['ledger_rows'],
            ledger=lambda *a:'5',durable=lambda *a:None,receipt_path=None,payload={},observed={'prs':[],'observedAt':'fixture'})
    exec(compile(module,str(p),'exec'),ns)
    try: ns['leaf'](); result='COMPLETE'
    except ValueError as e: result='REFUSED '+str(e)
    print(mode,result,'parent_count='+str(len(parents)),
          'changed_paths='+repr([k for k in after if before[k]!=after[k]]),
          'complete_commit='+str(state.get('complete_commit')))
PROBE
  ```
  Exit 0; decisive output:
  ```text
exact COMPLETE parent_count=1 changed_paths=['releases.db', 'releases.sql', 'PROJECT/4-MISC/weekly/2026-10-12/intake.json'] complete_commit=dddddddddddddddddddddddddddddddddddddddd
extra-readme COMPLETE parent_count=1 changed_paths=['releases.db', 'releases.sql', 'PROJECT/4-MISC/weekly/2026-10-12/intake.json', 'README.md'] complete_commit=dddddddddddddddddddddddddddddddddddddddd
extra-parent COMPLETE parent_count=2 changed_paths=['releases.db', 'releases.sql', 'PROJECT/4-MISC/weekly/2026-10-12/intake.json'] complete_commit=dddddddddddddddddddddddddddddddddddddddd
wrong-owned-blob REFUSED committed accounting/branch drift; preserve commit without complete checkpoint parent_count=1 changed_paths=['releases.db', 'releases.sql', 'PROJECT/4-MISC/weekly/2026-10-12/intake.json'] complete_commit=None
  ```
  Two earlier probe-helper attempts exited1 (`StopIteration` from looking for the statements directly in a Try rather than their With body, then `NameError: repository` from an omitted mock binding). Both were corrected in memory; neither is an artifact failure. No product bytes were changed.

- [Pass] **S3's stated ordinary-preservation repair passes independent sensitive controls.** Both `planner_core.py:1653` and `:1677` now require the entire native parent list to equal `[previous]`; tree/dirty checks remain. Actual nested commit AST execution at recovery AND normal completion accepts exact single-parent results and refuses extra-parent, wrong-parent, wrong-tree and dirty results, retaining pending intent. An in-memory mutation replacing only those complete-parent predicates with their old first-parent equivalent admits extra-parent at BOTH boundaries. The intentional ancestry recovery remains separately ordered-two-parent (`:1713–1717`). Retained producer Git evidence separately records `EXTRA_PARENT_HELD unknown committed handoff state` and `EXACT_INTENT_UNKNOWN_HISTORY_AND_PREDECESSOR_PRESERVED` (`TESTS-RESULTS/2026-10-11+GH-1022/phase9-r3-extra-parent-hold.log:4–5`), plus lost ordinary/native ancestry results (`phase9-r3-commit-loss.log:2–3`, `phase9-r3-ancestry-loss.log:2–3`). These logs were inspected, not reexecuted here.

  Quoted independent command:
  ```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import ast, copy, hashlib, json
from pathlib import Path
p=Path('skills/3-weekly/weekly-planner/scripts/planner_core.py')
r=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='reconcile_weekly')
c=next(n for n in ast.walk(r) if isinstance(n,ast.FunctionDef) and n.name=='commit')
class FirstParentOnly(ast.NodeTransformer):
    def visit_Compare(self,n):
        if (isinstance(n.left,ast.Subscript) and isinstance(n.left.value,ast.Call)
                and isinstance(n.left.value.func,ast.Attribute) and n.left.value.func.attr=='split'
                and ast.unparse(n.left.value).startswith("git(['rev-list'")):
            return ast.copy_location(ast.Compare(
                left=ast.Call(func=ast.Name(id='git',ctx=ast.Load()),args=[
                    ast.List(elts=[ast.Constant('rev-parse'),ast.Constant('HEAD^')],ctx=ast.Load()),
                    ast.Name(id='root',ctx=ast.Load())],keywords=[]),
                ops=copy.deepcopy(n.ops),comparators=[ast.Name(id='previous',ctx=ast.Load())]),n)
        return self.generic_visit(n)
for variant in ('current','first-parent-only'):
    node=copy.deepcopy(c)
    if variant!='current': node=FirstParentOnly().visit(node)
    module=ast.fix_missing_locations(ast.Module(body=[node],type_ignores=[]))
    for boundary in ('recovery','completion'):
        for mode in ('exact','extra-parent','wrong-parent','wrong-tree','dirty'):
            previous='a'*40; current='d'*40; tree='c'*40; blob='b'*40
            parents=[previous]+(['e'*40] if mode=='extra-parent' else [])
            if mode=='wrong-parent': parents=['f'*40]
            state={'root_head':previous,'pending_commit':{'releases.db':blob} if boundary=='recovery' else None,
                   'pending_tree':tree if boundary=='recovery' else None}
            committed=boundary=='recovery'; reads=[]
            def git(argv,root):
                global committed
                reads.append(argv)
                if argv==['rev-parse','HEAD']: return current if committed else previous
                if argv==['rev-parse','HEAD^']: return parents[0]
                if argv==['rev-list','--parents','-n','1','HEAD']: return ' '.join([current,*parents])
                if argv==['rev-parse','HEAD^{tree}']: return ('f'*40 if mode=='wrong-tree' else tree)
                if argv==['write-tree']: return tree
                if argv==['diff','--cached','--name-only']: return 'releases.db'
                if argv[0]=='commit': committed=True; return ''
                if argv[0]=='add': return ''
                if argv[0] in ('hash-object','rev-parse'): return blob
                raise AssertionError(argv)
            def dirty(root):
                return {'releases.db'} if not committed else ({'README.md'} if mode=='dirty' else set())
            ns=dict(state=state,git=git,root=None,guard=lambda:None,dirty=dirty,durable=lambda *a:None,receipt_path=None)
            exec(compile(module,str(p),'exec'),ns)
            try: ns['commit'](['releases.db'],'unused'); result='ADOPTED'
            except ValueError as e: result='REFUSED '+str(e)
            print(variant,boundary,mode,result,'intent_retained='+str(state['pending_commit'] is not None))
e=json.loads(Path('TESTS-RESULTS/2026-10-11+GH-1022/phase9-r3-qualified.json').read_text())
old=json.loads(Path('TESTS-RESULTS/2026-10-11+GH-1022/phase9-r2-qualified.json').read_text())
for f,h in e['source_sha256'].items():
    print('SOURCE_HASH_MATCH',f,hashlib.sha256(Path(f).read_bytes()).hexdigest()==h)
print('OWNER_IDENTICAL_TO_R2',old['source_sha256']['utils/py/releases_app.py']==e['source_sha256']['utils/py/releases_app.py'])
print('CONTROL_COUNT',len(e['controls']),'ALL_RC_ZERO',all(x['rc']==0 for x in e['controls']))
PROBE
  ```
  Exit0. Decisive output: `current recovery exact ADOPTED intent_retained=False`; `current recovery extra-parent REFUSED unknown committed handoff state intent_retained=True`; `current completion exact ADOPTED intent_retained=False`; `current completion extra-parent REFUSED committed preservation result differs; retain intent intent_retained=True`; wrong-parent/wrong-tree/dirty refuse at both boundaries. Mutation output: `first-parent-only recovery extra-parent ADOPTED intent_retained=False` and `first-parent-only completion extra-parent ADOPTED intent_retained=False`. This proves those source predicates, not S4's separate preparation path.

- [Pass] **R2 attribution and capability-prose dispositions are present.** Existing `provenance.jsonl:228–231` appends R2 twelve-flow, nonempty-PR and extra-parent-red attribution, then R3 source-qualified evidence. Earlier weekly statements now point to the reconciliation section under verification (`skills/3-weekly/weekly/SKILL.md:89`, `:193`); the held/UNKNOWN and unavailable execution boundaries remain explicit (`:199–248`). No prior FAIL is relabeled.
- [Pass] **Current manifest matches source, with limits intact.** The quoted independent command exits0 and prints `SOURCE_HASH_MATCH utils/py/releases_app.py True`, `SOURCE_HASH_MATCH skills/3-weekly/weekly-planner/scripts/planner_core.py True`, `OWNER_IDENTICAL_TO_R2 True`, `CONTROL_COUNT 14 ALL_RC_ZERO True`. These inspect `phase9-r3-qualified.json`'s fourteen records and byte identities; they do not independently rerun those flows. Nonempty producer evidence retains draft PR lead for issue1 and no foreign same-number lead for issue2, with UNKNOWN delivery (`phase9-r3-nonempty-pr.log:847–881`, `:958`). Hook refusal and timeout retain their measured limits (`phase9-r3-hook-refusal.log:2–4`; `phase9-r3-hook-timeout.log:932–933`), not a full normal-gate or whole-caller budget proof.
- [Unverified — needs clone run] S4 real Git/commit-hook/caller replay, older cached-writer execution, exhaustive interrupted-transfer interleavings, whole-caller time/cost and final normal harness gate remain unverified here. No validate/test/pytest/executable fixture, Git command, live action, network/connector or extra agent was run. The final harness gate remains outside this turn.

Sweep disclosure: R2's documented complete core/owner/plan/skills/unchanged-fixture sweep is retained, not reset or silently withdrawn. This turn independently reread ALL current 1,990-line core and both weekly skills, canonical merge selector/recovery/apply/builder spans, installer, current plan checkpoint/dispositions and retained evidence. The current owner hash is identical to R2. I did NOT independently repeat the entire 7,552-line owner, whole main plan and all fixture-source rereads this turn; truncated outputs were not counted for omitted spans. Hence `swept file: no` for a fresh full-scope R3 sweep. S4 was observed in the pre-existing preparation completion source during the whole-core reread; there is no fresh blanket pre-existing-defect clearance.

Verify-tier graph: all82 projects enumerated/no matching task worktree; nearest primary XYZ-forge generation `2026-09-01T15:54:30Z`. Reconcile search0/no more. Coverage for candidate core/owner/plan/skills/installer/covering fixture paths is stale/missing/not-tracked, with gh32 parse-partial237 retained from R2. Current direct source and quoted probes support the findings; no completeness claim relies on this foreign graph, and no reindex occurred.

Only this relay tracked file changed. Scratch creation stayed under `.relay-scratch/tmp`. A literal CLI-usage search initially hit zsh's `no matches found: src/cli*`; the corrected bounded literal search was read-only. Preserve R6FAIL6/6 / MediumGH1028, GH1027 unapproved, closed Phase6/7/8 and Phase9planApprovedR1/3. W8–W11/fullGH1022 remain incomplete. No cap extension, new CI authority, dispatch, landing, deployment or clone teardown follows.

Handing off to Author — this relay is Escalated at3/3. Disposition S4 and the remaining qualification limits through the existing operator escalation; do not open Round4 or reset this relay. Go to the Author window and say 'take your turn'.


<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
