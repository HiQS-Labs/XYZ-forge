# RELAY · GH-1064 final QA — script-owned merge-batch record, sweep inputs, --record-sweep, exit 4
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
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
6. **Commit only the relay file** (`relay(gh1064-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/scripts/batch_record.py` and the rest of the
  committed implementation on this branch (the diff against origin/development). Code files:
  - `skills/2-daily/merge-cleanup/scripts/batch_record.py` (new)
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`land_prs` wrapper, `_record_batch_outcomes`, `_land_prs_loop` hooks, `select_batch`, `record_sweep`, exit 4)
  - `skills/2-daily/merge-cleanup/scripts/toposort_prs.py` (`_soft_reasons`)
  - `skills/2-daily/merge-cleanup/SKILL.md` (recite item 6, Phase 5 exits, Drive loop step 6, Done rule, protocol section, capability table, options line)
  - `test/gh534_phase_b_tests.py` (stub verbs, `batch_of`, `TestBatchIssue`, updated exit expectations)
  - `test/gh534_phase_c_tests.py` (import, `REQUIRED_CAPABILITIES`, AST pins, controls, updated exit expectations)
- The approved plan and its acceptance map: `PROJECT/2-WORKING/GH-1064-MERGE-BATCH-ISSUE-QA.md`
  (plan QA thread: `relay-system/2026-10-14/gh1064-plan-qa.md`, Approved round 3, including its nits).
- Evidence:
  - `bash test/gh436-merge-cleanup.sh` → `Ran 185 tests … OK`, run from this task clone on commit `bd0229e9`.
  - Three red controls in `TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl` and the `red-*.log` files.
  - The full gate (`route=full`, tier 3) runs once after this review approves, in a disposable clone.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- **Operational envelope:** a local operator CLI landing a handful of PRs per run in one repo. Grade
  against the approved plan and the operator scope (the script records and the agent runs the
  suite; exit 4; threshold 2). Do not ask for new suites, guards, runners (GH-831) or enterprise
  fail-safes.
- **Definition of Done — answer each with file:line evidence:**
  1. Does the code match each approved plan item (steps 1–5, R1–R7, and the round-3 nits: landing order, the :935 attribution, a post-merge stop keeping the oid)?
  2. Hard-stop recording: does the wrapper/`_ERR_SINK` design attribute **every** in-loop `return 2` (all 22 sites) to the PR in hand with its diagnostic, and leave later PRs `unattempted`? Is there any path where a stale `current`/`errs` mis-attributes a stop, or where `_ERR_SINK` leaks across calls?
  3. Exit precedence: 2 (including a Phase 6 failure) > 3 > 4 > 0, with Phase 6 running before 4; the QA-only empty-queue resume; and `--record-sweep` doing no discovery, merge or teardown.
  4. Issue ownership: can `update` ever overwrite text outside the markers? Is non-blocking failure honored everywhere (create, view, edit), with the landing unaffected?
  5. `find_unfinished` / `qa_pending` / `continuable`: correct on the resume scenarios, and no accidental match of another repo's or branch's batch?
  6. Is there a duplicate subsystem or writer (a second gh wrapper, lock or persistence path)? Is the test footprint commensurate and inside GH-831 (no new file or registry entry)?
  7. Do the tests and red controls actually substantiate the claims, or could any pass vacuously?
  8. Pre-existing defects in the touched code that this change makes worse.

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
Basis: The implementation substantially follows the approved plan, but two concrete acceptance gaps need small corrections: a positively observed closed PR never becomes terminal in the batch, and the printed sweep command splits the documented primary path at its space. No new subsystem, suite or gate is requested. These are Easy, local corrections; preserve existing landing policy.
swept file: yes

Scope: Read the complete six implementation files named in Setup, the plan and its earlier QA, the retained red-control receipts, and the relevant persistence/tool-resolution/classifier boundaries. Verify-tier graph discovery returned no matching symbols; all 84 projects were enumerated and none indexes this worktree. The nearest XYZ-forge generation is 2026-09-01T15:54:30Z in another checkout; coverage reports the scripts/tests not_tracked or missing and the selector metadata_changed. Exact seeded source therefore supplies the evidence below. No git command, test suite, pytest, executable fixture, or artifact edit was run. `scripts/` below means `skills/2-daily/merge-cleanup/scripts/`.

- [Should] **F1 / DoD 1,5,8 — Record a positively observed CLOSED skip as terminal.** The loop writes `skipped: state CLOSED` (scripts/merge_cleanup.py:1034-1037, persisted at :941-942), but `continuable` accepts only `closed` or merged-and-reconciled (scripts/batch_record.py:101-107). After QA covers the landed subset, `find_unfinished` still selects this completed record (:126), and `record_sweep` tells the caller to continue (:1620-1621). OPEN-only discovery cannot revisit that closed PR. Use one consistent terminal representation for this observed state; keep holds/drafts/handoffs non-terminal. Verify in the existing suite or a retained manual clone check.
  Observed input: live refresh `{state: "CLOSED"}` for planned PR 2 after PR 1 landed; the exact skip branch plus `_record_batch_outcomes` produced `{'status': 'skipped: state CLOSED'}` in a non-mutating AST extraction probe. With `verdict.covers=[1]`, the predicate probe below reports QA covered but continuation required.
  Affected scope: planned PRs positively observed CLOSED during the landing loop; this does not ask to infer closure from an absent PR or change merge eligibility.
  Falsifier: a batch with PR 1 merged/reconciled and covered, and PR 2 positively CLOSED must have `qa_pending=False`, `continuable=False`, and no unfinished match. Replacing CLOSED with a hold/draft/handoff must retain `continuable=True`.
  Command (exit 0; source branch additionally traced at scripts/merge_cleanup.py:1034-1037):
  ~~~sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'PROBE'
  import copy, sys
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  import batch_record as b
  r={'planned':[{'pr':1},{'pr':2}], 'outcomes':{'1':{'status':'merged','reconcile':'ok'},'2':{'status':'skipped: state CLOSED'}},'landed_order':[1],'verdict':{'covers':[1]}}
  print('CLOSED:', b.qa_pending(r), b.continuable(r))
  c=copy.deepcopy(r); c['outcomes']['2']['status']='closed'
  print('terminal control:', b.qa_pending(c), b.continuable(c))
  PROBE
  ~~~
  Decisive output: `CLOSED: False True`; `terminal control: False False`.

- [Should] **F2 / DoD 1 — Quote the primary in the printed sweep command.** scripts/batch_record.py:302 interpolates an unquoted path into a shell command, while SKILL.md:453,462 explicitly documents primaries under `Documents/GH Repos`. Even after the caller replaces `<tmp>`, this produces three positional operands for clone. Apply shell quoting to the primary (standard-library `shlex.quote` suffices); do not introduce a runner. Keep the placeholder convention or make its replacement instructions explicit.
  Observed input: `primary=/Users/noelsaw/Documents/GH Repos/XYZ-forge`, the path documented by this skill, with `<tmp>` replaced by `/private/tmp/gh1064-sweep`. The actual command expression parses into separate `/Users/noelsaw/Documents/GH` and `Repos/XYZ-forge` operands.
  Affected scope: printed sweep commands for primary paths containing shell whitespace/metacharacters; no merge, classification or teardown behavior changes.
  Falsifier: parse the generated clone command after placeholder substitution and expect one source operand exactly equal to that primary and one destination operand; a no-space primary must remain equivalent. No actual clone is needed to prove tokenization.
  Command (exit 0):
  ~~~sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'PROBE'
  import ast, shlex
  from pathlib import Path
  s=Path('skills/2-daily/merge-cleanup/scripts/batch_record.py').read_text()
  t=ast.parse(s)
  d=next(n for n in ast.walk(t) if isinstance(n,ast.Dict) and any(isinstance(k,ast.Constant) and k.value=='command' for k in n.keys))
  e=next(v for k,v in zip(d.keys,d.values) if isinstance(k,ast.Constant) and k.value=='command')
  c=eval(compile(ast.Expression(e),'<source command>','eval'),{'primary':Path('/Users/noelsaw/Documents/GH Repos/XYZ-forge'),'gate':'validate.sh --sequential'}).replace('<tmp>','/private/tmp/gh1064-sweep')
  print(shlex.split(c.split(' && ')[0]))
  PROBE
  ~~~
  Decisive output: `['git', 'clone', '--no-local', '/Users/noelsaw/Documents/GH', 'Repos/XYZ-forge', '/private/tmp/gh1064-sweep']`. This measures shell tokenization; no git command ran.

- [Pass] **DoD 1,2 — Stop attribution and landing-order nits.** The wrapper installs a fresh track and clears `_ERR_SINK` before finalization (scripts/merge_cleanup.py:917-925); each PR resets `current`/`errs` before policy validation (:981-990), including the former :935 site. The loop has exactly 22 hard-return sites at current lines 990,1023,1041,1050,1058,1070,1112,1138,1145,1155,1171,1176,1184,1189,1201,1210,1217,1222,1234,1239,1244,1251. Each reaches the wrapper with the current PR; diagnostics come through `log_err` (:152-155), including the merge helper's failure (:228,237). Later rows retain their initialized `unattempted` status (scripts/batch_record.py:69; scripts/merge_cleanup.py:930-944). The remote merge is saved before fetch/reconcile (:1223-1234); post-merge stops retain that status/OID and add the failure (:935-937). Actual landing order is append-only (scripts/batch_record.py:140-141) and supplies the inclusive range (:277-280). These are source/AST conclusions, not execution of all 22 paths.

- [Pass] **DoD 1,3 — Dispatch and precedence.** `--record-sweep` dispatches immediately after primary resolution, before Phase 0 (scripts/merge_cleanup.py:1328-1335); it reads/stores a verdict and updates the issue without discovery/merge/teardown (:1600-1622). Phase-5 exits 2/3 return before Phase 6 (:1516-1519); normal Phase 6 failures return 2 before the QA predicate (:1561-1570), giving 2 > 3 > 4 > 0. Empty-queue executing resumes still select a batch (:1511,1578-1587). qa_pending compares landed PRs with verdict coverage independently of other statuses (scripts/batch_record.py:96-98), so later landings reopen QA. Input rejection precedes mutation (:307-323).

- [Pass] **DoD 4 — Marked-block ownership and non-blocking gh failures.** Create failures become `issue_error` (scripts/batch_record.py:211-217); read failures/missing markers return without an edit (:227-238); successful replacement preserves the prefix/suffix outside markers (:239), and edit errors are recorded (:247-248). The injected callable is the driver's bounded `_gh` (scripts/merge_cleanup.py:71-75,947,1591,1616). Narrow in-memory callable probes also observed create/read/edit errors returning normally, missing-marker updates doing no edit, and byte-identical outside text on replacement. Source citations establish the branches; full landing behavior under those errors remains for a clone run.

- [Pass] **DoD 1,5,6 — Resume, metadata and reuse, except F1.** `find_unfinished` filters repo/integration and requires overlap only for non-empty queues (scripts/batch_record.py:121-126). Selection precedes the first merge and creates for a 2+ resume without a prior record (scripts/merge_cleanup.py:1511-1516,1581-1591); no-record single-PR and non-executing runs stay exempt (:1578-1589). Stored file lists (:59) and soft reasons (scripts/toposort_prs.py:148,160) feed cross-PR overlap over retained landings (scripts/batch_record.py:281-300), including hard pairs. Persistence reuses `attempt_record.RecordLock/save` (:86-89; scripts/attempt_record.py:61-89,117-122); classification uses the existing tool resolver/selector (scripts/batch_record.py:253-269; scripts/ledger_merge.py:263-273; utils/py/wave_reconcile.py:593-618), with full-gate fallback. No second gh wrapper, lock implementation or runner is introduced in the reviewed files.

- [Pass] **DoD 6,7 — Existing-suite footprint and meaningful red controls.** The added behavior stays in the existing Phase B/C modules: issue-call ordering and outcomes (test/gh534_phase_b_tests.py:745-763), hard-pair resume/coverage (:765-795), pre/post-merge stops (:797-820), caller-text preservation and malformed verdicts (:822-841), and no-batch resume (test/gh534_phase_c_tests.py:796-814). Phase C imports `TestBatchIssue` (:34) and requires the new ownership rows (:543-546); AST pins target the real loop (:551-553). The three retained provenance entries (TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl:1,2,3) record nonzero controls with decisive failures `0 != 4`, `0 != 2 : accepted 'verdict: clean\\n'`, and missing caller text. They demonstrate sensitivity to their three mutations; they do not cover F1/F2 or prove all error paths. No new test file/registry entry is requested.

- [Unverified — needs clone run] **DoD 7 — Final runtime attestation.** The Setup's 185-test result is producer-reported; this evidence directory retains the three red logs, not the complete positive run. I did not run prohibited gates/fixtures here. After corrections, retain focused green evidence and the already-planned full disposable-clone gate against the final implementation. Specifically exercise Phase-6 failure over QA pending and standalone recording without discovery/teardown; source ordering alone is not a runtime pass.

- [Pass] **DoD 8 — Whole-file sweep conclusion.** F1 is the pre-existing generic non-OPEN skip representation becoming incompatible with the new terminal predicate (scripts/merge_cleanup.py:1034-1037; scripts/batch_record.py:104). No additional pre-existing defect made worse by this change was identified in the complete six-file sweep. Existing merge/durability and teardown boundaries remain at scripts/merge_cleanup.py:1230-1253,1516-1519,1528-1563; the new code records outcomes around them.

Root cause: the new consumer's terminal vocabulary differs from the existing skip writer, and the new display command omits shell argument quoting. Fix those boundaries directly; neither finding calls for merge-policy changes or extra machinery.

Handing off to Producer (claude-a) — disposition F1/F2, make the small corrections, retain existing-suite/manual evidence, and request Reviewer round 2. The harness owns the one-file commit; this reviewer ran no git command.

### Producer · Round 2 · claude-a

Both findings hold and are fixed in `d35db0c8`; the evidence is in `8b3b36dc`.

- **F1 — Implemented.** A PR positively observed CLOSED is now recorded as `closed`, and one
  observed MERGED outside the run as `closed: merged outside this run`
  (`scripts/merge_cleanup.py`, the non-OPEN skip branch). `continuable` treats `closed` and
  `closed:*` as terminal (`scripts/batch_record.py` `continuable`). Holds, drafts and handoffs stay
  non-terminal. Your falsifier ran as a retained manual check
  (`TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl`, "F1 closed is terminal"): with the landed
  subset covered, `closed` and `closed: merged outside this run` give `qa_pending=False` and
  `continuable=False`, while hold, draft and handoff give `continuable=True`. SKILL.md states that
  `closed` is terminal.
- **F2 — Implemented.** The command now uses `shlex.quote(str(primary))`. The manual check tokenizes
  the generated clone command for `/Users/noelsaw/Documents/GH Repos/XYZ-forge` and for a plain path,
  and gets exactly one source operand and one destination operand each time.
- **Runtime asks from your Unverified item, now pinned in the existing suite:**
  - Phase 6 failure outranks QA pending: in `test_two_pr_queue_…_exits_4`, a QA-only `--resume`
    whose teardown fails returns **2**, and the record still reports `qa_pending`.
  - `--record-sweep` runs no Phase 0 or discovery: the `verdict()` helper patches
    `prepare_primary_landing` and `fetch_open_prs_with_retry` to raise, and every `--record-sweep` call
    in `TestBatchIssue` still passes.
- **Positive run retained:** `bash test/gh436-merge-cleanup.sh` gives `Ran 185 tests … OK`, in
  `TESTS-RESULTS/2026-10-14+GH-1064/gh436-green.log` (lines 3901/3903), with a provenance row.
- The full disposable-clone gate still runs once, on the commit this review approves.

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: Ship through the already-planned disposable-clone gate. F1/F2 are corrected at their writer/consumer and command-formatting boundaries; no further required correction was identified. Approval covers source review and the retained focused evidence, not a full-gate result.
swept file: yes

Scope: Re-read the entire six implementation files listed in Setup, the approved plan and round-3 precision notes, this complete relay, and the persistence/tool-resolution/classifier seams. Verify-tier graph lookup found no matching symbols; all 84 projects were enumerated, none for this worktree. The nearest XYZ-forge index is generation 2026-09-01T15:54:30Z in another checkout; coverage reports the six paths missing/not_tracked, so exact seeded source supplies the evidence. No git command, suite, pytest, executable fixture, or artifact edit ran. `scripts/` below means `skills/2-daily/merge-cleanup/scripts/`.

- [Pass] **F1 / DoD 1,5 — Closed is terminal.** The live non-OPEN branch writes `closed` for CLOSED and `closed: merged outside this run` for MERGED (scripts/merge_cleanup.py:1034-1039); the predicate accepts those terminal statuses (scripts/batch_record.py:102-109). Holds/drafts/handoffs remain non-terminal. The pure probe below measures the original falsifier and its negative controls; the old `skipped: state CLOSED` representation still demonstrates the original failure. The producer's retained result is TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl:4. No merge-eligibility policy change is needed.

- [Pass] **F2 / DoD 1 — The primary is one shell operand.** scripts/batch_record.py:304 now uses `shlex.quote(str(primary))`. The probe evaluates that exact source expression and checks the documented spaced path, a plain path and a metacharacter path without running any shell command from the generated text. Removing quoting reproduces the split source operand. Retained producer checks are provenance.jsonl:5-7 in the same evidence directory.

  Narrow probe command (exit **0**; only imports/pure calls, source parsing and in-memory assertions):
  ~~~sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 -B - <<'PROBE'
  import ast, copy, shlex, sys
  from pathlib import Path
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  import batch_record as b
  r={'planned':[{'pr':1},{'pr':2}], 'outcomes':{'1':{'status':'merged','reconcile':'ok'},'2':{}},'landed_order':[1],'verdict':{'covers':[1]}}
  for status in ('closed', 'closed: merged outside this run', "skipped: hold-label 'hold'", 'skipped: draft', 'handoff', 'skipped: state CLOSED'):
      r['outcomes']['2']['status']=status
      got=(b.qa_pending(r), b.continuable(r))
      print(status, got)
      assert got == (False, status not in ('closed','closed: merged outside this run'))
  t=ast.parse(Path('skills/2-daily/merge-cleanup/scripts/batch_record.py').read_text())
  d=next(n for n in ast.walk(t) if isinstance(n,ast.Dict) and any(isinstance(k,ast.Constant) and k.value=='command' for k in n.keys))
  e=next(v for k,v in zip(d.keys,d.values) if isinstance(k,ast.Constant) and k.value=='command')
  for p in ('/Users/noelsaw/Documents/GH Repos/XYZ-forge', '/tmp/plain', "/tmp/a'$(printf injected);"):
      c=eval(compile(ast.Expression(e),'<source command>','eval'),{'primary':Path(p),'gate':b.FULL_GATE,'shlex':shlex}).replace('<tmp>','/private/tmp/sweep')
      tokens=shlex.split(c.split(' && ')[0])
      print('clone tokens:', tokens)
      assert tokens == ['git','clone','--no-local',p,'/private/tmp/sweep']
      if 'GH Repos' in p:
          unquoted=shlex.split(f'git clone --no-local {p} /private/tmp/sweep')
          print('unquoted red control:', unquoted)
          assert unquoted != tokens
  s=ast.parse(Path('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py').read_text())
  f=next(n for n in s.body if isinstance(n,ast.FunctionDef) and n.name=='_land_prs_loop')
  loop=next(n for n in ast.walk(f) if isinstance(n,ast.For) and isinstance(n.target,ast.Name) and n.target.id=='pr')
  sites=sorted(n.lineno for n in ast.walk(loop) if isinstance(n,ast.Return) and (isinstance(n.value,ast.Constant) and n.value.value==2 or isinstance(n.value,ast.IfExp) and isinstance(n.value.body,ast.Constant) and n.value.body.value==2))
  print('hard returns:', sites, 'count:',len(sites))
  assert len(sites)==22
  print('PASS: pure predicates, command tokenization and hard-return enumeration; no git/test/fixture executed')
  PROBE
  ~~~
  Decisive output: `closed (False, False)`; `closed: merged outside this run (False, False)`; hold/draft/handoff each `(False, True)`; old `skipped: state CLOSED (False, True)`. Quoted clone tokens include one source `/Users/noelsaw/Documents/GH Repos/XYZ-forge`; the unquoted control splits it into `/Users/noelsaw/Documents/GH` and `Repos/XYZ-forge`. All three path assertions passed. The hard-return enumeration reports `[990, 1023, 1042, 1051, 1059, 1071, 1113, 1139, 1146, 1156, 1172, 1177, 1185, 1190, 1202, 1211, 1218, 1223, 1235, 1240, 1245, 1252]`, count **22**. Enumeration is source evidence, not execution of those branches.

- [Pass] **DoD 1,2 — Approved hooks and precision notes remain satisfied.** `_soft_reasons` retains filenames (scripts/toposort_prs.py:148,160); planned rows store normalized files and dependency reasons (scripts/batch_record.py:49-62). The wrapper installs a fresh tracker and clears `_ERR_SINK` before finalization (scripts/merge_cleanup.py:917-925); the loop resets current/errors before policy validation (:981-990), covering the former :935 attribution nit. All enumerated hard-return paths stay under that wrapper. Later unvisited rows retain `unattempted` (scripts/batch_record.py:70). Remote merge status/OID is saved before fetch (:1224-1235), and a post-merge stop adds the reconcile failure without replacing it (:935-937). Actual landing order is append-only (scripts/batch_record.py:142-143) and supplies the inclusive range (:279-282). No stale current/errors or sink leak was identified in these serial CLI call paths.

- [Pass] **DoD 3 — Exit precedence and isolated recording.** Phase-5 exits 2/3 return before teardown (scripts/merge_cleanup.py:1517-1520); a Phase-6 failure returns 2 before the QA predicate (:1562-1571), preserving 2 > 3 > 4 > 0. Executing empty-queue resumes select the retained batch (:1512,1576-1588). `--record-sweep` dispatches before Phase 0 (:1335-1336) into the standalone load/validate/update path (:1601-1623). The existing suite now pins Phase-6 failure over pending QA (test/gh534_phase_b_tests.py:768-772), and every verdict helper call forbids Phase 0/discovery (:738-744). Source ordering also excludes merge/teardown from standalone recording.

- [Pass] **DoD 4 — Issue ownership and gh failure handling.** Create/read/edit failures preserve local state and return normally (scripts/batch_record.py:213-219,229-240,249-250); successful update retains the prefix and suffix outside the markers (:241). All calls use injected driver `_gh`, whose launch/timeout failures become return codes (scripts/merge_cleanup.py:71-75,947,1592,1617). The retained whole-body overwrite control goes red on lost caller text (TESTS-RESULTS/2026-10-14+GH-1064/red-update-overwrites-whole-body.log:91); the existing ownership check asserts caller text survives (test/gh534_phase_b_tests.py:831-850). These do not claim protection against simultaneous human edits between GitHub read and write.

- [Pass] **DoD 5,6 — Resume identity, QA coverage and existing owners.** `find_unfinished` filters exact repo/integration and non-empty queue overlap (scripts/batch_record.py:123-128); `qa_pending` independently compares landed coverage (:97-99). New landings invalidate a partial verdict; single-PR/no-record and non-executing runs remain exempt (scripts/merge_cleanup.py:1579-1592). The resumed hard-pair/empty-queue scenarios are pinned at test/gh534_phase_b_tests.py:774-804 and the no-batch resume at test/gh534_phase_c_tests.py:796-814. Persistence reuses `attempt_record.RecordLock/save` (scripts/batch_record.py:87-90), gh remains injected (:11-12), and gate selection reuses the resolver/classifier with full fallback (:255-271). No duplicate gh wrapper, lock implementation, persistence owner or suite runner was identified. Changes to verification remain in the two existing Phase B/C modules and capability-owner pins (test/gh534_phase_c_tests.py:34,543-553).

- [Pass] **DoD 7 — Focused green evidence is now retained; controls are non-vacuous.** The retained `gh436-green.log:3901-3903` reports `Ran 185 tests in 340.134s` and `OK`; provenance.jsonl:8 records exit 0 with the explicit caveat that the corrections were uncommitted atop `cfedc42b` when run. The three prior mutation receipts/logs remain (provenance.jsonl:1-3), showing threshold `0 != 4`, empty-clean acceptance `0 != 2`, and lost caller text. These substantiate the focused checks and their three mutations; they are not independent exact-final-commit/full-gate attestation.

- [Pass] **DoD 8 — Whole-file sweep conclusion.** No additional pre-existing defect requiring correction within this change was identified after re-reading all six files. F1 resolves the incompatible old skip writer/new terminal consumer (scripts/merge_cleanup.py:1034-1039; scripts/batch_record.py:102-109). Existing landing/durability and teardown boundaries remain explicit (:1231-1254,1517-1520,1528-1564 in merge_cleanup.py); the batch layer records around them.

- [Unverified — needs clone run] The full `route=full`, tier-3 gate against the final committed implementation remains outstanding, exactly as Setup schedules it after approval. This reviewer did not run prohibited gates or fixtures, and approval is not permission to skip that gate or treat the earlier dirty-tree focused receipt as exact-final-commit evidence.

Relay closed (Approved), no further review turn needed. Handing the completed token to the harness with `done`; Producer (claude-a) proceeds with the scheduled disposable-clone full gate. The harness owns the relay-file commit; this reviewer ran no git command.


### Attestation · relay-drive — 2026-10-15T02:06:25Z
task: RELAY-gh1064-final-qa
reviewer: codex
status: Approved
reviewed-head: 9a64c66db6ac28451dd64174be030602e18fe4b3
added-range: 21393+10189
added-sha256: 3c0592b34bb266009fae828b97a97897a7ecd1309c439b73194c4146ca6f27d8
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
