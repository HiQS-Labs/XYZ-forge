# Final QA relay — GH-976 implementation
STATUS: Approved
NEXT: codex (Reviewer)

## Your role

You are the **reviewer**. Review-only turn: `ALLOW_PATHS` is empty; write only this relay file.
Do not edit source, plan, or evidence. No `validate.sh`, `test/*.sh`, or executable fixtures in the
worktree (read-only probes under `.relay-scratch/` are fine).

## What to review

The committed implementation of the plan you approved in `relay-system/2026-10-05/gh976-plan-qa-codex.md`:

- `utils/py/relay_drive.py` — the new `commits_touch_non_receipt()` helper and the oracle call site
  (`git log -1 --stat`, `git show HEAD -- utils/py/relay_drive.py`).
- `PROJECT/2-WORKING/GH-976-RELAY-RECEIPT-ONLY-PROGRESS.md` — the approved plan, status updated.
- `TESTS-RESULTS/2026-10-05+GH-976/` — `SUMMARY.md`, `provenance.jsonl` (ten control runs plus the
  existing suite run), and the control script `gh976-controls.sh`.
- `CHANGELOG.md` top entry.

Operational envelope: a local CLI relay supervisor for one developer's headless agent loops. This repo
forbids new test suites and `validate.sh` registry entries (GH-831); the diff must contain neither.

## Definition of Done

1. **Does the code match the approved plan?** Receipt directories with trailing slashes; relay file
   excluded only when it resolves inside `target_repo()`; `git diff --name-only before..after` in that
   repo; False on empty SHA or git error; resolved-items arm and hard ceiling untouched; the frozen
   Bash twin untouched. Cite file:line for any deviation.
2. **Is any real repair wrongly classified as a receipt?** Consider a builder whose only change is
   under one of the excluded prefixes, and a relay file path that collides with a target file name.
3. **Does the evidence substantiate the claims?** Read `provenance.jsonl`: are the base runs for A/B
   genuine failures of the candidate expectation, do C/D prove the HEAD arm still extends, does E
   cover the no-SHA branch, is the suite run present and green, and are the expected exits honest?
   Note the fixture retry around `index.lock` recorded in `SUMMARY.md`; say whether it masks anything.
4. **Scope hygiene.** Any new suite, registry entry, gate machinery, unrelated refactor, or accidental
   file in the diff?
5. **Issue mapping.** Does the change satisfy the current acceptance list on issue #976 (receipt-only
   → `cap-stalled` at the original cap, no `Extension · System`; real-file still extends; gh115 suite
   green)? Is the persisted rating `80/75/50/85` still consistent with the evidence?

Rate findings `[Blocker]`, `[Must]`, `[Should]`, `[Note]`; behaviour-change requests carry
`Observed input:`, `Affected scope:`, `Falsifier:`. Set `STATUS: Approved` only if the implementation
is correct and the evidence supports it; otherwise `STATUS: Changes requested`.

## Round log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


### Round 1 · codex · final QA · 2026-10-05

**Verdict: Changes requested — two Must correctness findings.** The ordinary receipt/repair controls support the intended fix, but exact-file coordinates and Git pathname parsing leave receipt-only extension possible. Review-only: only this relay file was edited; no git command, suite, pytest, driver dispatch or executable fixture was run. Revisions were inspected by reading existing loose objects, not invoking git. Review edits are Easy to reverse. Production blast radius remains the Python driver's bounded cap-extension decision for all consumers.

1. **[Must] Resolve repository and relay paths before testing containment (`utils/py/relay_drive.py:610–612`).** `abspath` normalizes lexical paths but does not resolve symlinks. On this Mac `/tmp` resolves to `/private/tmp`; sampling `/tmp/gh976-probe` and opening the same repository's transcript through `/private/tmp/gh976-probe/notes/thread.md` yields a relative path beginning with `..`, drops the exact-file exclusion, and reports progress for `notes/thread.md` alone. The approved plan explicitly requires the relay file to be excluded when it resolves inside `target_repo()`. Use canonical resolved paths for both operands and a component-aware containment check; `startswith("..")` also treats an in-repo filename such as `..thread.md` as external. Keep external transcripts from excluding a coincident target basename.

   **Observed input:** target repo `/tmp/gh976-probe`, relay `/private/tmp/gh976-probe/notes/thread.md`, diff output `notes/thread.md\n`, fixed resolved count, unequal nonempty SHAs. Probe: canonical repository coordinates equal, helper returns **True**, expected False.
   **Affected scope:** receipt-only cap-reaching turns with aliased repository/transcript coordinates, including macOS system path aliases.
   **Falsifier:** a non-mutating helper probe with these coordinates returns False; the external-basename case still returns True. Record an alias receipt-only integration control in the existing manual evidence from a disposable full clone, expecting exit 4 `cap-stalled` at cap 2 and no extension. No new suite or gate.

2. **[Must] Parse literal Git pathnames without stripping them (`utils/py/relay_drive.py:604–605,615–617`).** `git diff --name-only` without `-z` quotes unusual filenames. A receipt named `relay-system/réceipt.md` can therefore arrive as `"relay-system/r\303\251ceipt.md"`; its leading quote defeats every receipt prefix and grants progress. Conversely, `strip()` changes a genuine path beginning with a space: ` relay-system/repair.py` lies outside the excluded directory but becomes `relay-system/repair.py` and is wrongly rejected. [Git's official diff documentation](https://git-scm.com/docs/git-diff#Documentation/git-diff.txt--z) specifies that `-z` preserves pathnames and uses NUL terminators; use that representation and preserve filename bytes/whitespace when filtering.

   **Observed input:** quoted receipt-only name returns **True**, expected False; literal leading-space real-file name returns **False**, expected True (probe below).
   **Affected scope:** receipt filenames containing non-ASCII/control/quote characters and real filenames with significant leading/trailing whitespace.
   **Falsifier:** literal NUL-delimited receipt paths remain excluded, literal real paths remain progress, and ordinary/mixed cases retain their results. Record the relevant manual control/red result in the existing evidence directory from a disposable full clone, rather than adding a suite.

3. **[Note] Ordinary plan compliance and GH-115 preservation (DoD 1/2).** `RECEIPT_DIRS` at :597 retains trailing slashes. The helper uses `target_repo()` and the specified `before..after` diff; :600 and :606–607 return False on missing/equal SHA and Git failure. The independent resolved-items arm (:1128–1129), hard ceiling (:766–767), and cap extension bounds (:1132) remain present. A useful repair confined to `TESTS-RESULTS/` or `marathon-system/` is deliberately excluded by the approved policy; mixed real-file work qualifies. The probe verifies an external transcript with a colliding target basename still counts as real progress. The two Must findings concern incorrect implementation of that policy, not a request to broaden it.

4. **[Note] Evidence is credible for the cases it covers (DoD 3).** All eleven `provenance.jsonl` records are present. Base A/B genuinely fail the candidate expectation, exiting **10** with driver rc 4, `cap-progressing-extended`, two extensions/two records/four commits instead of the required stalled cap 2. Candidate A/B exit 0 with driver rc 4, `cap-stalled`, zero extensions/records and two commits. Base/candidate C/D exit 0 with two extensions/records and four commits, holding resolved count fixed; these exercise the HEAD arm. E exits 0 with the expected missing-SHA stalled result. The existing gh115 receipt records exit 0 and **7 pass, 0 fail**. These expected exits are honest; a control's exit 10 is the assertion failure, not the driver's exit.

   The index.lock retry (`gh976-controls.sh:28–33`) does not mask the recorded failure: it retries the same in-turn commit; :46–53 require the exact commit count, and :47 prints exhaustion. None of the retained outputs contains `COMMIT FAILED`. It addresses the disclosed fixture race on both sides, without changing the progress expectation. This is a review of retained results, not a fresh observation of integration execution. Candidate records explicitly identify an **uncommitted** candidate atop `cbcb054d...`; the suite record lacks an exact tested revision. The harness's subsequent disposable-clone gate must establish final committed-state evidence. **[Unverified — needs clone run]** for that final gate and the newly identified edge-case integration controls.

5. **[Note] Scope hygiene (DoD 4).** Loose-object inspection identifies implementation commit `7b8a5e44a6b95e4f77e828f492a9ba0b3883df6a`, parent `cbcb054d94e6c0383afccdf91bfb9dd8e84b77fd`; current HEAD `ebcce138...` scaffolds this final review. Changed top-level entries in the implementation are `CHANGELOG.md`, `PROJECT`, `TESTS-RESULTS`, `releases.db`, `releases.sql`, and `utils`. Parent/candidate tree IDs are identical for **`test/`, `validate.sh`, and `relay-automation/`**, establishing no new registered suite/registry edit/frozen Bash twin edit there. The retained shell control is manual evidence under TESTS-RESULTS, as authorized by the plan. Some deeper objects are packed and the loose-object probe could not decode them; no exhaustive whole-diff claim about other utils changes is made. No new gate or parallel runtime subsystem appears in the inspected helper/call site.

6. **[Should] Restore/read back the persisted rating (DoD 5).** The doc still states `80/75/50/85`, and `releases.sql:3032` retains a `rated` event with those values, but the current roadmap row (`releases.sql:806`) and read-only `releases.db` query return **NULL in all four rating fields**. Thus the event is persisted, but the current effective rating is not. Restore through the existing RELEASES CLI and read back the row; do not hand-edit the dump or add machinery. The modest-effort bugfix and base red controls still support the stated rationale; the missing current values prevent calling that rating intact.

   **Observed input:** `select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort from roadmap_items where gh_number='976'` → `[(976, None, None, None, None)]` (read-only URI query, exit 0).
   **Affected scope:** GH-976's current PRS rating/readers.
   **Falsifier:** the same read-only query returns `80,75,50,85` after a governed CLI update.

7. **[Note] Current issue mapping.** GitHub connector `github_fetch_issue(repository_full_name="HiQS-Labs/XYZ-forge", issue_number=976)` succeeded. [Issue #976](https://github.com/HiQS-Labs/XYZ-forge/issues/976) currently accepts receipt-only stalled original cap/no extension, real-file extension, gh115 plus `validate.sh --auto` green, and a consumer #75 backlink. It explicitly withdraws prose adjudication parsing in favor of `STATUS: Escalated`. Ordinary controls satisfy the first two examples and gh115 is recorded green, but the first acceptance is not general until Findings 1/2 are fixed. Final gate and consumer backlink remain landing work; neither is asserted complete here.

**Non-mutating probe command (exit 0).** This executes only the seeded helper's AST with mocked subprocess output, and uses the host's existing `/tmp` alias; it neither calls git nor dispatches a fixture. The same probe separately returned False for empty SHA and a mocked Git error. Scratch/bytecode environment was confined as requested.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import ast, os, subprocess
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/relay_drive.py'); t=ast.parse(p.read_text())
m=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='main')
f=next(n for n in m.body if isinstance(n,ast.FunctionDef) and n.name=='commits_touch_non_receipt')
r=next(n for n in m.body if isinstance(n,ast.Assign) and any(isinstance(x,ast.Name) and x.id=='RECEIPT_DIRS' for x in n.targets))
def check(label,repo,relay,out,before='a',after='b',error=False):
    def output(cmd,**kw):
        if error: raise subprocess.CalledProcessError(1,cmd)
        return out
    e=dict(os=os,subprocess=SimpleNamespace(check_output=output,DEVNULL=subprocess.DEVNULL),target_repo=lambda:repo,relay_file=relay)
    exec(compile(ast.Module(body=[r,f],type_ignores=[]),str(p),'exec'),e)
    print(label,'progress='+str(e['commits_touch_non_receipt'](before,after)))
root='/private/tmp/gh976-probe'
check('plain-receipt',root,root+'/notes/thread.md',b'relay-system/receipt.md\n')
check('real-file',root,root+'/notes/thread.md',b'src/repair.py\n')
check('external-basename-collision',root,'/outside/notes/thread.md',b'notes/thread.md\n')
print('alias_coordinates_equal='+str(os.path.realpath(root)==os.path.realpath('/tmp/gh976-probe')))
check('alias-exact-receipt','/tmp/gh976-probe',root+'/notes/thread.md',b'notes/thread.md\n')
check('quoted-receipt',root,root+'/notes/thread.md',b'"relay-system/r\\303\\251ceipt.md"\n')
check('leading-space-real-file',root,root+'/notes/thread.md',b' relay-system/repair.py\n')
check('no-SHA',root,root+'/notes/thread.md',b'src/repair.py\n',before='')
check('git-error',root,root+'/notes/thread.md',b'',error=True)
PYPROBE
```

Decisive output:

```text
plain-receipt progress=False
real-file progress=True
external-basename-collision progress=True
alias_coordinates_equal=True
alias-exact-receipt progress=True
quoted-receipt progress=True
leading-space-real-file progress=False
no-SHA progress=False
git-error progress=False
```

**Evidence limits:** Verify-tier intent; graph tools are not exposed in this session, so no project/generation/coverage claim is made. Source claims use current targeted reads. The AST probe verifies classifier behavior with supplied Git-format output; Git's actual integration behavior for these edge cases still requires the disposable clone run. No final gate, merge readiness, full-tree cleanliness, consumer backlink, or teardown is attested.

### Round 1 · claude-a · Author response · 2026-10-05

Driver note: round 1 exited 3 (stall classification) although a full review block was appended; the
content is treated as the review (same oddity as plan QA round 1; parked separately).

1. **[Must] alias coordinates** — Accepted. `commits_touch_non_receipt` now takes `os.path.realpath`
   of both repo and relay file and uses `os.path.commonpath` for containment (component-aware; no
   `startswith("..")`). Integration control **F** added: driver samples the repo through the
   `$TMPDIR` alias, relay file opened through its realpath, receipt-only → base extends (10),
   candidate `cap-stalled` at cap 2 (0). External transcript with a colliding basename still counts
   as progress (unchanged logic; relay_rel stays empty when outside).
2. **[Must] literal pathnames** — Accepted. `git diff --name-only -z`, split on NUL, no `strip()`;
   bytes decoded with `surrogateescape`. Control **G** (`relay-system/réceipt.md`) added: base
   extends (10), candidate `cap-stalled` (0).
3. **[Note]** — no change.
4. **[Note] revision** — provenance regenerated against the **committed** candidate
   `e7559676` (14 control records + the gh115 suite record, all expected exits met).
5. **[Note]** — no change; `test/`, `validate.sh`, `relay-automation/` still untouched.
6. **[Should] rating** — Accepted. Row read back `80,75,50,85` after `roadmap rate` (the rating was
   nulled by the promotion-time `roadmap update --raw-text` whose bullet carried no `rated` token;
   filed as a separate harness issue, not fixed here).
7. **[Note]** — final gate and consumer backlink remain landing work.

Commits since your reviewed head: `e7559676` (helper), `d37729b8` (evidence). STATUS back to Open.


### Round 2 · codex · final QA · 2026-10-05

**Verdict: Approved — both Must findings and the rating finding are resolved.** No remaining Blocker or Must finding in the reviewed implementation. This approves the implementation and retained focused evidence; the final disposable-clone gate and consumer backlink remain landing work. Only this relay file was edited. No git command, suite, pytest, driver dispatch, or executable fixture was run. Review edits are Easy to reverse; production blast radius remains the Python driver's bounded cap-extension decision.

1. **[Note] Plan compliance / Round 1 Must fixes.** `utils/py/relay_drive.py:606–607` uses the target repository, the specified before..after range, `--name-only -z`, and surrogateescape; :621–623 preserves literal pathnames without stripping. :615–618 canonicalizes both operands and uses component-aware containment before deriving the exact-file exclusion. The non-mutating AST probe now returns False for the aliased exact receipt, Unicode receipt, and an in-repo `..thread.md`; True for significant leading-space real paths, mixed changes, and external transcript/basename collision. Missing/equal SHA (:600–601), empty diff, and Git error (:608–609) return False. Independent resolved-item progress (:1133–1134), extension bound (:1136), and hard ceiling (:772) remain intact. Direct loose-object comparison confirms current relay_drive.py is byte-identical to committed candidate `e75596760efe13b672f23c1954d1416669a26eb6`.

2. **[Note] Repair classification.** Trailing-slash directory prefixes (:597) avoid excluding similarly named real directories. The exact-file exclusion does not exclude an external transcript's coincident target basename. Useful repairs entirely under TESTS-RESULTS/ or marathon-system/ remain deliberately excluded by the approved policy; mixed source work qualifies. No policy expansion is requested.

3. **[Note] Retained evidence supports the fix.** All 15 nonempty provenance records have matching actual/expected exits and identify base `6d81df9f6949e64f22997a4f2aca738a420141c9` or committed candidate `e7559676...`. Base A/B/F/G genuinely fail the candidate expectation (control exit 10): driver rc 4, cap-progressing-extended, two extensions/records, four commits. Candidate A/B/F/G pass (0): driver rc 4, cap-stalled, zero extensions/records, two commits. C/D pass on both sides with fixed resolved count and four commits/two extensions, establishing retained integration evidence for the HEAD arm. E passes the missing-SHA stalled case. The suite record identifies the committed candidate and reports **7 pass, 0 fail**, exit 0. The control assertion failure is exit 10; it is correctly distinguished from driver exit 4.

   F's pre-fix red on the original base establishes the original receipt-only defect; it does not independently isolate the intermediate abspath implementation's alias bug. The Round 1 AST red and this round's AST green provide that narrower falsifier. G similarly has retained original-base red plus candidate green and the Round 1 pathname-specific red. The index.lock retry retries the same commit without altering expected progress; exact commit-count checks and absence of COMMIT FAILED in retained output prevent the disclosed dropped-turn race from masquerading as success. No evidence of masking the defect was found.

4. **[Note] Scope hygiene.** Read-only loose-object tree comparison from `cbcb054d...` through evidence commit `d37729b8543bbac1674575ba8dd83df5d19b683f` shows CHANGELOG, the GH-976 plan, this review transcript, releases.db/sql, TESTS-RESULTS and utils changed. Top-level tree identities for **test/, validate.sh, and relay-automation/** are unchanged, proving no suite/registry/frozen twin changes in those surfaces. Some deeper old TESTS-RESULTS/utils objects are packed and were not decoded; no exhaustive whole-utils diff claim is made. The inspected production helper/call site adds no runner, dependency, gate, or parallel subsystem. The retained shell script is manual evidence, outside the test registry.

5. **[Note] Rating / issue mapping.** Read-only SQLite readback now returns **[(976, 80, 75, 50, 85)]**, resolving Round 1 Should. The bounded bugfix, demonstrated receipt-only failure, preserved positive behavior, and small implementation remain consistent with that rating. Fresh GitHub connector fetch of [issue #976](https://github.com/HiQS-Labs/XYZ-forge/issues/976) confirms the accepted receipt-only stalled/original-cap/no-extension behavior, real-file extension, gh115 plus validate.sh --auto, and consumer #75 backlink. Retained controls substantiate the first two and gh115. **[Unverified — needs clone run]** for the final validate.sh --auto gate; the user explicitly assigns that to the harness after this turn. Consumer backlink remains pending and is not attested here. Prose adjudication acceptance remains explicitly withdrawn in favor of existing STATUS: Escalated.

**Non-mutating probe command (exit 0).** The helper's AST was executed with mocked subprocess output; no Git process or fixture was executed. The command asserts the exact NUL diff invocation. Decisive output follows.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import ast,os,subprocess,sqlite3,json
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/relay_drive.py')
m=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='main')
nodes=[n for n in m.body if (isinstance(n,ast.FunctionDef) and n.name=='commits_touch_non_receipt') or (isinstance(n,ast.Assign) and any(isinstance(x,ast.Name) and x.id=='RECEIPT_DIRS' for x in n.targets))]
def probe(label,repo,relay,out,want,before='a',after='b',error=False):
    def output(cmd,**kw):
        assert cmd==['git','-C',repo,'diff','--name-only','-z',before+'..'+after]
        if error: raise subprocess.CalledProcessError(1,cmd)
        return out
    env=dict(os=os,subprocess=SimpleNamespace(check_output=output,DEVNULL=subprocess.DEVNULL),target_repo=lambda:repo,relay_file=relay)
    exec(compile(ast.Module(body=nodes,type_ignores=[]),str(p),'exec'),env)
    got=env['commits_touch_non_receipt'](before,after)
    assert got==want,(label,got,want)
    print(label,got)
r='/private/tmp/gh976-probe'
probe('alias-exact','/tmp/gh976-probe',r+'/notes/thread.md',b'notes/thread.md\0',False)
probe('unicode-receipt',r,r+'/thread.md','relay-system/réceipt.md\0'.encode(),False)
probe('leading-space-real',r,r+'/thread.md',b' relay-system/repair.py\0',True)
probe('external-collision',r,'/outside/notes/thread.md',b'notes/thread.md\0',True)
probe('dotdot-name',r,r+'/..thread.md',b'..thread.md\0',False)
probe('mixed',r,r+'/thread.md',b'relay-system/r.md\0src/repair.py\0',True)
probe('no-SHA',r,r+'/thread.md',b'src/a\0',False,before='')
probe('git-error',r,r+'/thread.md',b'',False,error=True)
db=sqlite3.connect('file:'+str(Path('releases.db').resolve())+'?mode=ro',uri=True)
print('rating',db.execute("select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort from roadmap_items where gh_number='976'").fetchall())
db.close()
rows=[json.loads(x) for x in Path('TESTS-RESULTS/2026-10-05+GH-976/provenance.jsonl').read_text().splitlines()]
assert len(rows)==15 and all(x['exit_code']==x['expected_exit'] and x['stdout'] for x in rows)
print('provenance: 15 nonempty records, all expected exits match')
PYPROBE
```

```text
alias-exact False
unicode-receipt False
leading-space-real True
external-collision True
dotdot-name False
mixed True
no-SHA False
git-error False
rating [(976, 80, 75, 50, 85)]
provenance: 15 nonempty records, all expected exits match
```

**Evidence limits.** Verify tier. Full list_projects pagination returned 77 projects, none for this task worktree. Nearest XYZ-forge index is ready, generation 2026-09-01T15:54:30Z. Graph search returned no relevant current helper symbols; coverage reports metadata_changed for the source/turn-library/suite and missing for the plan. Current targeted source reads supply the material evidence; graph freshness/completeness is not asserted. Integration results above are inspected retained receipts, not fresh executions. Approval does not attest the later gate, PR, merge, consumer backlink, or clone cleanup.

**Handoff: done — claude-a.**

### Round 2 · claude-a · Author note · 2026-10-05

Driver refused to attest round 2: STATUS was Approved but the tick token was released to claude-a
instead of closed (`close-mismatch`, exit 4). No code changed since your reviewed head. Round 3 asks
only this: re-read the same revision; if your verdict stands, write a one-paragraph confirmation
below, set `STATUS: Approved`, and **close the token with `tick done`** (do not `release`). If it
does not stand, say why and set `STATUS: Changes requested`.

### Round 3 · codex · final QA confirmation · 2026-10-05

**Verdict: Approved — Round 2 approval stands.** Re-read the current helper, oracle call site and evidence summary; a read-only loose-object comparison (Python/zlib, no git process; exit 0) returned `relay_drive.py byte-identical to committed candidate e7559676`. Re-ran the exact Round 2 embedded AST/read-only SQLite/provenance probe with `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3` (Python extracts the last embedded `PYPROBE` body and executes it): exit **0**; decisive output `alias-exact False`, `unicode-receipt False`, `leading-space-real True`, `external-collision True`, `dotdot-name False`, `mixed True`, `no-SHA False`, `git-error False`, `rating [(976, 80, 75, 50, 85)]`, and `provenance: 15 nonempty records, all expected exits match`. No new Blocker or Must finding. Graph inventory still has no index for this worktree; nearest XYZ-forge generation is 2026-09-01T15:54:30Z and helper coverage says metadata_changed, so this confirmation relies on current source and the narrow probe. Only this relay file was edited; no git command, suite, pytest or executable fixture ran. The final disposable-clone gate remains **[Unverified — needs clone run]** and the consumer backlink remains landing work. Closing the claimed token with the absolute env-pinned `tick done RELAY-gh976-final-qa --agent codex`, as explicitly requested by Round 3, to resolve the prior close-mismatch.

### Attestation · relay-drive — 2026-10-06T05:05:01Z
task: RELAY-gh976-final-qa
reviewer: codex
status: Approved
reviewed-head: d909968774225773e48a5d70694fbf42c95a9ec4
added-range: 24952+1508
added-sha256: 9de793bf698fe505159f13361d7f498af438488a8707f5faea9a62c848f62768
