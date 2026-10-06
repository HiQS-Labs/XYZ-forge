# Final QA relay — GH-976 implementation
STATUS: Changes requested
NEXT: claude-a (Author)

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
