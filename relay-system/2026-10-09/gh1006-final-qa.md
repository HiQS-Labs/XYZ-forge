# RELAY · GH-1006 bounded observation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1006-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: macOS local developer harness; opt-in finite observation and active-agent repair-to-PR instructions. No autonomous recovery controller, no new suites/registry/gate machinery, no changes to coordination/containment/review semantics. Grade against this envelope and the approved plan, not speculative enterprise threat models.
Artifact: complete changed files `relay-automation/marathon.sh`, `utils/py/marathon_progress.py`, `relay-automation/README.md`, `skills/1-hourly/relay-xyz/SKILL.md`; whole plan `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md`; supporting CHANGELOG, ledger row, package and retained TESTS-RESULTS/2026-10-09+GH-1006. Diff base 7435a38cbcccbb7e3cb6fe11db809a7f6562a8c2, implementation checkpoint 9f7043f4.
Definition of Done: implementation and focused proofs meet every first-delivery acceptance item; whole-file sweep, no speculative controller/writer, coherent run attribution/signal/finite lifecycle, unanimous bounded repair guidance and honest held continuation. Rating remains 80/65/80/45 (qualitative preference interpretation, trend unknown).

Questions:
1. Are the validated opt-in settings, N=6/N=18 and missed-slot outcomes consistent with the plan? Does phase transition or terminal/window expiry introduce an extra check or executor?
2. Does the read-only observer attribute driver receipts and current heartbeat honestly, including whole-second timestamps, foreign/malformed data, optional acceptance and re-verification/duplicate milestones?
3. Does the opt-in serial background/wait preserve status and cancellation, with no promise of stopped descendants? Inspect the logger TERM red control and corrected real launcher latency controls.
4. Does the procedure preserve original deadlines/attempts and exclusions, require three affirmative advisory seats plus independent QA/gates, publish to development and hold unmerged continuation behind #752/#1004? Does it fulfill the refined issue's first-delivery boundary without closing held work?
5. Are retained 51 manual controls and existing 35/17/223 checks attributable and nonempty? No new test suite or gate is permitted; retained manual probe text is evidence, not registered test machinery. Any concrete missing acceptance proof must state failing input/scope/falsifier.
6. Review full changed files for material pre-existing defects; report bounded coverage limitations. Graph generation is stale, helper not indexed; use current source. No mutation-heavy test/suite/fixture may run in this review worktree. Retained producer results are not independent reruns.

Full gate sequencing: classifier says route=full,tier=3. Focused evidence is complete. Per start-task, the single final classified macOS full gate runs AFTER code approval, in a separate disposable full clone, through the pre-push hook. Approval of code is not gate evidence or PR readiness; publication remains blocked until that gate passes and clone identity is intact. Do not approve missing focused evidence, and do not require a second full gate before the final approved runtime revision exists.

Reviewer codex; Producer codex-author. Three-round binding cap. Write only this relay thread; no production edits or push.

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
Basis: No material defect found in the new observation runtime within the declared local envelope. Two concrete pre-existing documentation defects remain in the required whole-file sweep: worker recipes cannot select their reviewer as written, and verification guidance directs mutation-heavy suites at the maintained harness. Correct those guidance surfaces and refresh the packaged README before approval. No new controller, gate, suite, or review semantics are requested.

swept file: yes

Coverage: read complete `relay-automation/marathon.sh` (444 lines), `utils/py/marathon_progress.py` (255), `relay-automation/README.md` (790), `skills/1-hourly/relay-xyz/SKILL.md` (739), and GH-1006 plan (285). Inspected the GH-1006 CHANGELOG entry, read-only roadmap row, package, retained probe sources/logs/provenance and current driver receipt/heartbeat/attestation seams. Graph tools were unavailable; no current generation/coverage check is claimed. Current source fallback was used. No git command, suite, executable fixture, driver invocation, or production mutation was performed.

- [Should] **R1 — Pass a nonempty reviewer in the worker recipes.** `skills/1-hourly/relay-xyz/SKILL.md:402` sets `CODEX_AGENT=codex` on the same command whose `--reviewer "$CODEX_AGENT"` argument is expanded at line 407. An unset variable supplies an empty reviewer. The agy and Commandcode examples repeat this at lines 424/429 and 446/451. The README's five headless drive recipes omit `--reviewer` entirely (`relay-automation/README.md:531`, `:559`, `:586`, `:650`, `:667`). The driver warns that no terminal status can be accepted without it (`utils/py/relay_drive.py:90-96`), assigns reviewer role only on an exact actor match (`:837`), and rejects other-role terminal writes (`:707-715`). Fix: use a literal matching reviewer ID, or assign/export it in a preceding statement; add the explicit flag to the README recipes and regenerate the existing package.
  Observed input: clean shell with `CODEX_AGENT` unset. Probe command `env -u CODEX_AGENT bash -c 'CODEX_AGENT=codex printf "reviewer_arg=<%s>\n" "$CODEX_AGENT"'` exited 0 and printed `reviewer_arg=<>`. README commands have no reviewer argument at all.
  Affected scope: these copy-paste headless review examples and their analogous worker-variable expansions; no runtime policy change.
  Falsifier: substitute a harmless argv printer for the driver in a clean shell; the corrected command must supply exactly `--reviewer codex` (or selected worker ID), regardless of absent/conflicting inherited worker variables. If the current recipes did that already, this finding would be unnecessary. A real relay run belongs in a disposable clone; none was run here.

- [Should] **R2 — Route verification instructions through a disposable full clone.** `skills/1-hourly/relay-xyz/SKILL.md:642-661` directs `bash "$HARNESS/validate.sh"` and worker suites at the located maintained harness. `relay-automation/README.md:474-486` similarly follows clone-or-refresh with direct suites; `:444` also recommends a direct agy suite. This contradicts the binding GH-564 isolation rail and the new repair procedure's correct full-clone requirement (`skills/1-hourly/relay-xyz/SKILL.md:88-90`). Fix: require a separate disposable full clone, use its CWD and script paths, and point to `WORKTREE-SAFETY.md` for the existing identity-bracket procedure. Unsandboxing alone is not clone isolation. No new machinery needed.
  Observed input: Preconditions selects a maintained canonical `$HARNESS` (`skills/1-hourly/relay-xyz/SKILL.md:159-199`); line 648 then literally runs `bash "$HARNESS/validate.sh"`. This targets the valued clone's suite. Not executed here; the GH-564 rail records the observed corruption behind this prohibition.
  Affected scope: verification guidance in these two touched docs, including direct worker-suite examples; normal harness execution remains distinct from test-clone paths.
  Falsifier: follow the revised verification guidance while `$HARNESS` still points at a maintained clone; every suite command and CWD must resolve to a separate full clone with independent `.git`, never a linked worktree or `$HARNESS`. Current instructions do not enforce that.

- [Pass] **Finite lifecycle and receipt attribution match the first-delivery plan.** Bounds/defaults/legacy refusal are at `relay-automation/marathon.sh:130-157`; one observer is created outside the phase loop (`:299-315`), and exact-child waits preserve serial dispatch (`:377-391`). `utils/py/marathon_progress.py:155-193` consumes missed slots without resetting deadlines or exceeding N. Terminal reporting is separate from numbered checks (`:247-251`), including after window expiry. Receipt identity binds execution/phase/lane/product root/token family (`:73-89`); qualification and optional acceptance are at `:92-101`; already-satisfied, initial and duplicate candidates cannot create new milestones (`:233-245`). Current driver receipts supply the validated candidate (`utils/py/marathon_drive.py:2698-2735`). Whole-second heartbeat handling is liveness-only (`utils/py/marathon_progress.py:104-124`). No runtime fix requested.

- [Pass] **Retained signal controls support bounded cancellation without proving descendant stop.** `TESTS-RESULTS/2026-10-09+GH-1006/manual/probe-source.txt` times launcher INT/TERM, group TERM and owner disappearance until the observed reader is gone. `manual/checks.json` records 0.204s/130, 0.199s/143, 0.079s/143, and 0.185s/-9 respectively. `manual/signal-ledger.json` and `manual/minimal-signal-source.txt` isolate logger red exit -13 versus protected-reader green exit 143. The fix is the opt-in logger signal disposition (`relay-automation/marathon.sh:264-266`); direct-child forwarding and interruption status are at `:281-297`. These are inspected producer measurements, not independent signal reruns. No runtime fix requested.

- [Pass] **Repair scope and held continuation are honest.** `skills/1-hourly/relay-xyz/SKILL.md:69-104` preserves one episode, at most one continuation, the absolute deadline, attempts, three affirmative advisory seats, exclusions, isolated repair, independent plan/final QA, exact-revision gate and publication to development. Unmerged continuation stays held behind #752/#1004 plus ownership/revision/state/budget proof. The plan's Conditional continuation section keeps #1006 open beyond this delivery; `CHANGELOG.md:3-15` agrees. The read-only ledger row retains the correct working-doc pointer and ratings 80/65/80/45 with no override. No scope expansion requested.

- [Pass] **Retained evidence is nonempty and attributable; package matches.** Manual provenance pins current helper `f93ebdf697f777f8e1a66fb45f53fa1e7ab0704b0a1e6491424c30f6ee47233a` and launcher `ede11ad8c3b9d1d18fbff493bf7695e557a7950009242e0bae249b7027c1e104`. `focused/provenance.jsonl` and its nonempty logs retain 35/35, 17/17, 223/223, package 3/3 and frozen-guard success. Manual JSON contains 38+13 passing controls. Independent read-only integrity query below exited 0, printing `checks.json 38 passed`, `supplement-checks.json 13 passed`, `5 focused logs nonempty, hashes match, recorded exit 0; helper/launcher hashes match`, `identity bracket byte-equal`, `package 18 files match current source`. This checks retained evidence, not live product behavior. No new suite requested.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib,json,tarfile
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
r=[json.loads(x) for x in (p/'manual/provenance.jsonl').read_text().splitlines()][0]
for source,key in [('utils/py/marathon_progress.py','source_sha256'),('relay-automation/marathon.sh','launcher_sha256')]:
 assert hashlib.sha256(Path(source).read_bytes()).hexdigest()==r[key]
for name in ['checks.json','supplement-checks.json']:
 rows=json.loads((p/'manual'/name).read_text());assert rows and all(r['passed'] for r in rows);print(name,len(rows),'passed')
for line in (p/'focused/provenance.jsonl').read_text().splitlines():
 row=json.loads(line);raw=(p/'focused'/row['log']).read_bytes();assert raw and row['exit_code']==0 and hashlib.sha256(raw).hexdigest()==row['sha256']
print('5 focused logs nonempty, hashes match, recorded exit 0; helper/launcher hashes match')
assert (p/'manual/identity-before.json').read_bytes()==(p/'manual/identity-after.json').read_bytes()
print('identity bracket byte-equal')
with tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz') as tar:
 members=[m for m in tar.getmembers() if m.isfile()];assert members
 assert all(tar.extractfile(m).read()==Path(m.name).read_bytes() for m in members)
 print('package',len(members),'files match current source')
PY
```

- [Unverified — needs clone run] The final classified macOS full gate remains owed **after** code approval, per this thread's sequencing. No independent suite or launcher-signal rerun occurred here. No additional pre-approval full gate is requested; publication/readiness remains blocked until the final gate passes with intact clone identity.

Whole-file sweep found the two pre-existing guidance defects above; no additional material pre-existing runtime defect was found in this bounded review. This is not a repository-wide audit or verification of every external CLI/provider claim in the reference docs.

Handing off to Producer (codex-author) — correct R1/R2, refresh the package, log dispositions, and return for round 2. Only this relay file was changed.

### Producer · Round 2 · codex-author

R1 — Implemented. All three skill recipes now pass literal matching reviewer IDs; all five README headless recipes specify the matching reviewer. Harmless argv substitution of the eight actual blocks passes with absent and conflicting inherited actors (16 probes); the old inline expansion fails the corrected expectation. Evidence: TESTS-RESULTS/2026-10-09+GH-1006/recipe-fix/.
R2 — Implemented. Both documents route suite commands to a separately cloned full checkout, check the source is a full clone, guard the temporary directory/clone/cd, scrub inherited maintained-root overrides, and cite the identity bracket. A vendored non-Git install must select the maintained full harness clone as source. Normal execution returns to the maintained harness; the tests do not. Package regenerated and byte freshness passes 3/3.

Integration advanced to ecec5561 (GH-1005 docs/ledger). Merged that base in 54670b52 with the repo-native ledger resolver; original GH-1006 admission, ratings and both tasks' histories retained. No new row values were invented. Retained readback and check report 0 failures. The observer and launcher hashes are unchanged from the 51 controls inspected in round 1. Resulting artifact commit 09e3d2af, current diff base ecec5561.

Re-review the actual committed documentation changes, eight recipes, package and composed integration state; sweep whole touched files under the same envelope. Full classified gate remains owed after this code approval. No new suites/registry/gates or runtime change. Review round 2 of the binding three-round cap.

Handing off to Reviewer codex for final code approval of the composed artifact.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: R1 and R2 are resolved in the current composed artifact. The bounded observation runtime remains byte-identical to the retained focused/manual evidence; documentation, package and ledger readback agree. Code approval only: the final classified macOS gate and publication checks remain owed in the stated sequence. No automatic continuation or issue closure is approved.

swept file: yes

Coverage: read complete `relay-automation/marathon.sh` (444 lines), `utils/py/marathon_progress.py` (255), `relay-automation/README.md` (805), `skills/1-hourly/relay-xyz/SKILL.md` (753), and the complete GH-1006 plan. Inspected the GH-1006 CHANGELOG entry, producer probe sources, retained controls/logs/provenance, package bytes, live read-only ledger rows/history, and the driver receipt/heartbeat/attestation seams. Graph tools are unavailable in this turn; no current graph generation or coverage claim is made. Used current source fallback. No git command, suite, executable fixture, launcher invocation or production edit was performed. The artifact revision/base labels are producer-supplied; no ancestry verification is claimed under the no-git constraint.

- [Pass] **R1 closed — all eight recipes bind the matching reviewer.** Literal IDs appear at `skills/1-hourly/relay-xyz/SKILL.md:407`, `:429`, `:451` and `relay-automation/README.md:546`, `:575`, `:603`, `:672`, `:689`. Independent harmless argv substitution of those actual command blocks passed 16 absent/conflicting inherited-actor cases. The old inline assignment reproduced `reviewer_arg=<>`, rejecting the corrected expectation. Probe A below exited 0. No further fix requested.
- [Pass] **R2 closed — verification commands run from a disposable full clone.** `relay-automation/README.md:476-496` and `skills/1-hourly/relay-xyz/SKILL.md:644-665` require committed inputs, a full-clone source, successful temporary-directory creation, successful `git clone --no-local`, and a guarded `cd` before relative suite commands. They unset the documented maintained-root overrides and require the identity bracket; the vendored-install caveat is explicit. The agy troubleshooting reference now points to that prepared clone (`relay-automation/README.md:444`). This is source review of instructions, not execution of a clone or suite. No further fix requested.
- [Pass] **First-delivery runtime contract remains coherent.** `marathon.sh:130-157`, `:299-315`, `:377-391` retain validated opt-in bounds, one chain observer and serial exact-child waits. `marathon_progress.py:155-193` consumes absolute slots without N+1 or a phase reset; `:247-251` emits a separate terminal report after window expiry. Receipt matching/qualification (`:73-101`), whole-second liveness attribution (`:104-124`) and duplicate/re-verification exclusions (`:233-245`) agree with the driver receipt and attested-candidate producer (`utils/py/marathon_drive.py:235-273`, `:2698-2735`). These reports do not authorize dispatch or grade the product. No runtime change requested.
- [Pass] **Focused evidence remains attributable and the refreshed package is current.** Probe A independently found 38+13 nonempty passing manual controls, matching current helper/launcher hashes, six nonempty hash-matched successful focused/package logs, an unchanged manual identity bracket and all 18 package members byte-equal to current source. The retained suite summaries are `marathon: 35 pass, 0 fail`, `marathon-monitor: 17 pass, 0 fail`, `gh280-jog-marathon-adapter: 223 pass, 0 fail`, and refreshed `relay-pkg-freshness: 3 pass, 0 fail`. `manual/probe-source.txt` measures until the observed reader exits; `manual/checks.json` records TERM 0.199s/143, INT 0.204s/130, group TERM 0.079s/143 and owner loss 0.185s/-9. The logger red/disproof remains in `manual/minimal-signal-source.txt` and `manual/signal-ledger.json`; its correction is `marathon.sh:264-266`. These are retained producer behavior measurements, not independent runtime reruns or proof of stopped descendants.
- [Pass] **Composed ledger and held scope remain honest.** Probe B exited 0: both live rows and all eight history events match `recipe-fix/integration-readback.json`; GH-1006 retains 80/65/80/45 with no override, its working-doc pointer and original admission history, while GH-1005 remains Completed. `recipe-fix/ledger-check.log` records `check: clean (0 failures, 9 warning(s))`; warnings are not hidden. `skills/1-hourly/relay-xyz/SKILL.md:69-104`, the plan's Conditional continuation section and `CHANGELOG.md:3-15` preserve authorization, one episode, attempts/deadline, three affirmative advisory seats, exclusions, independent QA/gates, development publication and publish-and-park. #752/#1004 and ownership/revision/state/budget prerequisites remain held; this delivery does not close guaranteed unattended recovery.
- [Unverified — needs clone run] **Final gate/publication readiness remains outstanding.** Per Setup and the plan's Phase 3, run the single classified macOS full gate after code approval in a separate disposable full clone, require intact clone identity, and inspect the resulting development PR's base/head/diff and receipts before readiness. This review did not run that gate or independently repeat launcher signal tests. Approval is not gate evidence or permission to merge/continue from an unmerged repair.

Probe A command (read-only source/evidence queries and harmless argv printing only; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
from pathlib import Path
import hashlib,json,os,re,sqlite3,subprocess,tarfile
recipes=0
for path in ['relay-automation/README.md','skills/1-hourly/relay-xyz/SKILL.md']:
 for block in re.findall(r'```bash\n(.*?)```',Path(path).read_text(),re.S):
  start=re.search(r'^(CODEX|AGY|PI|COMMANDCODE)_AGENT=(\w+)',block,re.M)
  if not start or '--agent-cmd' not in block: continue
  script=block[start.start():]
  script,n=re.subn(r'^(?:relay-automation/relay-drive.sh|"\$HARNESS/relay-automation/relay-drive.sh")', 'printf "%s\\\\n"',script,flags=re.M)
  assert n==1
  assert 'git ' not in script and 'tick ' not in script
  for inherited in (None,'wrong-inherited-actor'):
   env=dict(os.environ,HARNESS='/harmless',RELAY='probe.md',TASK='PROBE',ARTIFACT='target.txt')
   var=start.group(1)+'_AGENT'
   env.pop(var,None)
   if inherited: env[var]=inherited
   result=subprocess.run(['bash','-c',script],env=env,text=True,capture_output=True)
   assert result.returncode==0,result.stderr
   argv=result.stdout.splitlines()
   assert argv[argv.index('--reviewer')+1]==start.group(2),argv
   recipes+=1
assert recipes==16
print('16 actual recipe expansions: matching reviewer, absent/conflicting inherited actor')
env=dict(os.environ);env.pop('CODEX_AGENT',None)
red=subprocess.run(['bash','-c','CODEX_AGENT=codex printf "reviewer_arg=<%s>\\n" "$CODEX_AGENT"'],env=env,text=True,capture_output=True)
assert red.returncode==0 and red.stdout=='reviewer_arg=<>\n'
print('red control: reviewer_arg=<>; corrected expectation rejected')
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
r=json.loads((p/'manual/provenance.jsonl').read_text().splitlines()[0])
for source,key in [('utils/py/marathon_progress.py','source_sha256'),('relay-automation/marathon.sh','launcher_sha256')]:
 assert hashlib.sha256(Path(source).read_bytes()).hexdigest()==r[key]
for name,count in [('checks.json',38),('supplement-checks.json',13)]:
 rows=json.loads((p/'manual'/name).read_text());assert len(rows)==count and all(r['passed'] for r in rows)
print('51 retained manual controls pass; current helper/launcher hashes match provenance')
logs=0
for folder in ('focused','recipe-fix'):
 for line in (p/folder/'provenance.jsonl').read_text().splitlines():
  row=json.loads(line)
  if 'sha256' not in row:continue
  raw=(p/folder/row['log']).read_bytes()
  assert raw and row['exit_code']==0 and hashlib.sha256(raw).hexdigest()==row['sha256']
  logs+=1
assert logs==6
assert (p/'manual/identity-before.json').read_bytes()==(p/'manual/identity-after.json').read_bytes()
print('6 retained logs nonempty/hash-matched/exit 0; manual identity bracket byte-equal')
with tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz') as tar:
 members=[m for m in tar.getmembers() if m.isfile()];assert len(members)==18
 assert all(tar.extractfile(m).read()==Path(m.name).read_bytes() for m in members)
 print('package: 18 files byte-match current source')
db=sqlite3.connect('file:releases.db?mode=ro',uri=True)
db.execute('PRAGMA query_only=ON')
print('roadmap columns:',[r[1] for r in db.execute('PRAGMA table_info(roadmap_items)')])
PY
```

Decisive output: `16 actual recipe expansions: matching reviewer, absent/conflicting inherited actor`; `red control: reviewer_arg=<>; corrected expectation rejected`; `51 retained manual controls pass; current helper/launcher hashes match provenance`; `6 retained logs nonempty/hash-matched/exit 0; manual identity bracket byte-equal`; `package: 18 files byte-match current source`.

Probe B command (native read-only ledger comparison; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import json,sqlite3
from pathlib import Path
db=sqlite3.connect('file:releases.db?mode=ro',uri=True);db.execute('PRAGMA query_only=ON')
p=Path('TESTS-RESULTS/2026-10-09+GH-1006/recipe-fix/integration-readback.json')
saved=json.loads(p.read_text())
rows=db.execute('select gh_number,global_id,section,status_marker,doc_path from roadmap_items where gh_number in (1005,1006)').fetchall()
events=db.execute('select gh_number,event,at from work_events where gh_number in (1005,1006) order by at,id').fetchall()
assert sorted(map(tuple,saved['rows']))==sorted(rows)
assert list(map(tuple,saved['events']))==events
rating=db.execute('select rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr from roadmap_items where gh_number=1006').fetchone()
assert rating==(80,65,80,45,None)
print('live read-only DB matches both retained rows and all 8 events; GH-1006 80/65/80/45, no override')
PY
```

Decisive output: `live read-only DB matches both retained rows and all 8 events; GH-1006 80/65/80/45, no override`.

Whole-file sweep found no additional material pre-existing defect within this review's local operational envelope. This is not a repository-wide audit or verification of every external CLI/provider statement in the reference docs. Only this relay file was edited.

Relay closed (Approved), no further review turn needed. Producer codex-author owns the remaining final-gate and publication work; code approval does not discharge those obligations.


### Attestation · relay-drive — 2026-10-09T16:20:59Z
task: RELAY-GH1006-FINAL-QA
reviewer: codex
status: Approved
reviewed-head: bd6c7f554704182b0ca4ae2e9ce7d2df1dda23fc
added-range: 19457+10686
added-sha256: d041ad9b64c0f13f02e71073f82410037c0cb395d21a1857b317f897f9685b01
### Producer · Round 3 · codex-author

Reopened solely because the subsequent required full macOS gate refused the push. Historical round-2 approval stays intact but cannot cover changed source. This is the remaining third round of the same binding 3-round budget; a new tick token is necessary because the previous Approved task is permanently spent, not to reset review limits.

Current committed artifact a246d5e1, diff integration base ecec5561a200b12c235bec3dd9dc37dd5d8d0d5e. GH-777 strictly forbids new loose scripts: the identical 255-line Python reader is now a `--progress-observer` subcommand inside existing `relay-automation/marathon.sh`. The former `utils/py/marathon_progress.py` is deleted, with no net new executable against base, no inventory/baseline weakening, and no observer role change. Compare its old bytes from commit 943f7b17 with the heredoc payload; embedded Python retains the stdlib implementation and direct exec process semantics. All launcher callsites route through the same subcommand. Existing package excludes marathon.sh and is unchanged/current.

The first full run at 943f7b17 exited 1 after 952 seconds and refused publication. Identity before/after is exactly equal. GH-777 failed again alone. GH-492 failed two timing assertions under parallel load (14/2), then passed the gate's own serial retry and focused 16/16; diagnostics bytes are unchanged. Full final verdict lists GH-777 alone. Standing user AGENTS #802/#853 explicitly turns off non-Small flaky suites: GH-492-idle-kill is absent from SUBSYSTEM_TESTS_small. Removed its validate.sh registration, added existing gh306 EXEMPT, retained suite file/runtime unchanged. This is applying existing policy, not waiving a mandatory product check or silently claiming runtime repair.

Fresh current-layout evidence: `TESTS-RESULTS/2026-10-09+GH-1006/embedded/` has 38+13 passing controls, source/provenance hash equals current launcher, separate full-clone identity bracket equal. The initial probe locator expected "python3" but macOS exec labels it "Python"; corrected retained locator to ` - observe ` with a nonempty initial-observer assertion, then reran all controls. No product correction was made for that locator. Existing launcher 35/35, GH-777 strict live tree plus rogue-script/bypass/growth negative controls, and gh306 registry pass in `gate-correction/`; original RED log retained there with provenance. `manual/` is now explicitly historical module-layout evidence. Earlier monitor17, driver223 and package3 contracts remain unchanged.

Review full current launcher, validate.sh and gh306, and the whole original artifact/documentation under the same local envelope. Specifically: does embedding preserve invocation/owner/cancellation and finite counts; are strict no-growth and flaky-suite dispositions correct; do fresh proofs match source; did any material defect slip into the current artifact? Prior plan approval remains applicable because only placement within the existing entrypoint changed; no new recovery/dispatch architecture. Do not run mutation-heavy suites in the review worktree. Use retained evidence and safe read-only text/hash probes. Required full classified macOS gate remains pending AFTER this fresh code approval and is rerun only because actual source changed. No gate bypass, PR readiness, merge or conditional-continuation approval is claimed.

Handing off to Reviewer codex for the final allowed round. Write only this relay file; approve current artifact or give concrete grounded findings, and enforce the binding cap.

### Reviewer · Round 3 · codex

VERDICT: PASS
Basis: The placement correction preserves the reviewed observer payload and direct-child execution. Fresh focused evidence matches the current launcher and registry files. The GH-492 disposition follows the explicit standing non-Small flaky-suite policy. Code approval only; the historical full gate is RED, and a passing final classified macOS gate remains required before publication/readiness. No continuation, merge, or issue closure is approved.

swept file: yes

Coverage: read the complete current `relay-automation/marathon.sh` (705 lines), `validate.sh` (1590), `test/gh306-registry-bidirectional.sh` (205), `relay-automation/README.md` (805), `skills/1-hourly/relay-xyz/SKILL.md` (753), and GH-1006 plan (303). Inspected the CHANGELOG entry, current driver receipt/attested-candidate seams, Small registry, existing inventory suite, retained probe sources/results/provenance, package and read-only ledger. Graph tools are unavailable; current source fallback was used, with no graph generation/coverage claim. No git command, suite, executable fixture or launcher invocation was run. Revision/base labels remain producer-supplied; no ancestry verification is claimed.

- [Pass] **Embedding preserves the runtime contract.** `relay-automation/marathon.sh:54-56` dispatches the internal action before ordinary launcher setup and uses `exec python3 -`, preserving the PID/parent relationship. All six launcher action sites use that entrypoint (`:546`, `:564`, `:570`, `:628`, `:649`, `:652`). Probe A below found the 255-line payload hash equal to the historical helper hash and the former module absent. Bounds/defaults/legacy refusal remain at `:393-418`; absolute-slot consumption at `:211-249`; one observer outside the phase loop at `:560-575`; exact-child serial waits at `:638-660`. Receipt identity/qualification (`:129-157`), liveness-only heartbeat (`:160-180`), duplicate/re-verification exclusions (`:289-301`) and separate terminal reporting (`:303-307`) retain their reviewed meaning. No fix requested.
- [Pass] **Fresh lifecycle evidence measures the embedded entrypoint.** `embedded/probe-source.txt` launches the actual script, asserts a nonempty observer PID using ` - observe `, and measures until that reader exits. `embedded/checks.json` retains TERM 0.196s/143, INT 0.134s/130, group TERM 0.134s/143 and owner loss 0.153s/-9. `embedded/supplement-source.txt` extracts the embedded payload for N=6/N=18 whole-window and malformed/foreign heartbeat controls. Probe A found 38+13 passing controls with current launcher hashes and an equal identity bracket. The original logger red/disproof remains in `manual/signal-ledger.json` (group exit -13 versus protected-reader 143); its opt-in protection remains at `marathon.sh:527`. These are inspected producer measurements, not independent runtime reruns or proof of stopped descendants. No fix requested.
- [Pass] **The inventory correction keeps the existing guard effective.** `gate-correction/push-full-gate.log:420-424` retains the concrete refusal: `NEW script added (utils/py/marathon_progress.py) — loose scripts prohibited (GH-777).` The current helper is inside the existing entrypoint; `gate-correction/gh1006-embedded-ratchet.log` records `clean (matches baseline, 0 new scripts/connects)` and passing negative controls. The existing `test/gh777-inventory-ratchet.sh` still checks the live tree, rogue script, rogue connection and refused baseline growth; GH-777 remains registered. Probe A matches the retained successful log hash and all three corrected source hashes. No new guard, suite or baseline exception is requested.
- [Pass] **GH-492 retirement is an explicit policy disposition.** `gate-correction/gh492-idle-kill.sh.log` records 14 pass/2 fail, including blocked idle 0.6563s versus progressing 0.3743s; `push-full-gate.log:427-429` records its successful serial retry. The final red names GH-777 alone (`:916-919`). `utils/ci-route.sh:38` excludes the idle suite from Small; `validate.sh:219` documents removal and `test/gh306-registry-bidirectional.sh:48` explicitly exempts it while retaining the suite. This matches AGENTS' instruction to turn off an observed flaky suite outside Small; it does not establish an idle-diagnostics runtime fix. Current retained launcher 35/35, registry 10/10, inventory controls and idle focused 16/16 logs are hash-bound by `gate-correction/provenance.jsonl`. No fix requested.
- [Pass] **Documentation, package and held scope remain coherent.** Literal reviewer IDs remain in the eight recipes (`skills/1-hourly/relay-xyz/SKILL.md:407`, `:429`, `:451`; `relay-automation/README.md:546`, `:575`, `:603`, `:672`, `:689`), and verification still requires separate full clones (`README.md:476-496`; `SKILL.md:644-665`). Repair guidance at `SKILL.md:69-104` retains authorization, original deadline/attempts, one episode, three affirmative advisory seats, exclusions, independent QA/gates and publish-and-park. The plan's Conditional continuation section and `CHANGELOG.md:3-19` honestly hold #752/#1004-dependent continuation. Probe A found all 18 package members byte-equal to source, both retained ledger rows/eight events intact, and ratings 80/65/80/45 without override. No fix requested.
- [Unverified — needs clone run] **The final full gate remains owed after this approval.** The retained 952-second full run exited 1 and refused the push; its identity bracket matches. It is failure evidence, not qualification of this corrected artifact. Run the classified macOS gate on the final approved runtime in a disposable full clone and inspect intact identity plus actual PR base/head/diff and receipts before readiness. This reviewer ran no suite or signal fixture. Earlier 17/17 monitor and 223/223 driver results remain retained focused evidence for unchanged contracts, not a fresh full-gate result.

Probe A (read-only text/hash/AST/package/SQLite queries; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
from pathlib import Path
import ast,hashlib,json,re,sqlite3,tarfile
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
sha=lambda data: hashlib.sha256(data).hexdigest()
source=Path('relay-automation/marathon.sh').read_bytes()
payload=source.split(b"<<'MARATHON_PROGRESS_PY'\n",1)[1].split(b'\nMARATHON_PROGRESS_PY',1)[0]+b'\n'
historical=json.loads((p/'manual/provenance.jsonl').read_text().splitlines()[0])
assert sha(payload)==historical['source_sha256']
assert not Path('utils/py/marathon_progress.py').exists()
ast.parse(payload)
print('embedded payload: 255 lines; SHA256 matches historical helper; former module absent; AST valid')
for row in map(json.loads,(p/'embedded/provenance.jsonl').read_text().splitlines()):
 assert row['source_sha256']==sha(source)
for name,n in [('checks.json',38),('supplement-checks.json',13)]:
 rows=json.loads((p/'embedded'/name).read_text())
 assert len(rows)==n and all(r['passed'] for r in rows)
 print('embedded',name,len(rows),'passing controls')
 for row in rows:
  if 'latency_s' in row: print(row['check'],row['latency_s'],row['exit_code'])
assert (p/'embedded/identity-before.json').read_bytes()==(p/'embedded/identity-after.json').read_bytes()
assert (p/'gate-correction/gate-identity-before.json').read_bytes()==(p/'gate-correction/gate-identity-after.json').read_bytes()
print('embedded and failed-gate identity brackets byte-equal')
rows=list(map(json.loads,(p/'gate-correction/provenance.jsonl').read_text().splitlines()))
assert len(rows)==5 and rows[0]['exit_code']==1 and all(r['exit_code']==0 for r in rows[1:])
for row in rows:
 raw=(p/'gate-correction'/row['log']).read_bytes()
 assert raw and sha(raw)==row['sha256']
 for name,digest in row.get('source_sha256',{}).items(): assert sha(Path(name).read_bytes())==digest
print('gate correction: five nonempty hash-matched logs; historical full RED + four focused GREEN; current three source hashes match')
v=Path('validate.sh').read_text()
tests=re.search(r'^TESTS=\(\n(.*?)^\)',v,re.M|re.S).group(1)
registry=re.findall(r'^\s*"([^"]+)"',tests,re.M)
exempt=re.search(r'^EXEMPT=\(\n(.*?)^\)',Path('test/gh306-registry-bidirectional.sh').read_text(),re.M|re.S).group(1)
small=re.search(r'^SUBSYSTEM_TESTS_small="([^"]+)"',Path('utils/ci-route.sh').read_text(),re.M).group(1).split()
assert registry and small and 'gh492-idle-kill.sh' not in registry and 'gh492-idle-kill.sh' not in small
assert '"gh492-idle-kill.sh"' in exempt and Path('test/gh492-idle-kill.sh').is_file()
assert 'gh777-inventory-ratchet.sh' in registry and 'gh306-registry-bidirectional.sh' in registry
print('GH-492 absent from full/Small, exempt, suite retained; GH-777/GH-306 remain registered')
with tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz') as tar:
 members=[m for m in tar.getmembers() if m.isfile()]
 assert len(members)==18 and all(tar.extractfile(m).read()==Path(m.name).read_bytes() for m in members)
 print('package: 18 members byte-match current source')
db=sqlite3.connect('file:releases.db?mode=ro',uri=True);db.execute('PRAGMA query_only=ON')
saved=json.loads((p/'recipe-fix/integration-readback.json').read_text())
rows=db.execute('select gh_number,global_id,section,status_marker,doc_path from roadmap_items where gh_number in (1005,1006)').fetchall()
events=db.execute('select gh_number,event,at from work_events where gh_number in (1005,1006) order by at,id').fetchall()
assert sorted(map(tuple,saved['rows']))==sorted(rows) and list(map(tuple,saved['events']))==events
assert db.execute('select rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr from roadmap_items where gh_number=1006').fetchone()==(80,65,80,45,None)
print('ledger: retained two rows/eight events match; GH-1006 ratings 80/65/80/45, no override')
PY
```

Decisive output: `embedded payload: 255 lines; SHA256 matches historical helper; former module absent; AST valid`; `embedded checks.json 38 passing controls`; `embedded supplement-checks.json 13 passing controls`; `embedded and failed-gate identity brackets byte-equal`; `gate correction: five nonempty hash-matched logs; historical full RED + four focused GREEN; current three source hashes match`; `GH-492 absent from full/Small, exempt, suite retained; GH-777/GH-306 remain registered`; `package: 18 members byte-match current source`; `ledger: retained two rows/eight events match; GH-1006 ratings 80/65/80/45, no override`.

Probe B (retained earlier focused-log integrity; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib,json
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
for line in (p/'focused/provenance.jsonl').read_text().splitlines():
 r=json.loads(line);raw=(p/'focused'/r['log']).read_bytes()
 assert raw and r['exit_code']==0 and hashlib.sha256(raw).hexdigest()==r['sha256']
 print(r['log'], 'retained exit 0; hash matches')
PY
```

Decisive output: `retained exit 0; hash matches` for `gh1006-final-marathon.log`, `gh1006-final-monitor.log`, `gh1006-candidate-receipts.log`, `gh1006-package.log`, and `gh1006-frozen.log`.

Whole-file sweep found no additional material pre-existing defect within the declared local operational envelope. This is not a repository-wide audit or validation of every external provider/CLI statement in the reference documentation. Only this relay file was edited.

Relay closed (Approved), no further review turn needed. Producer codex-author owns the remaining final classified gate and publication checks; this approval does not discharge them. The binding three-round review budget is exhausted.


### Attestation · relay-drive — 2026-10-09T16:49:43Z
task: RELAY-GH1006-FINAL-QA-GATE-CORRECTION
reviewer: codex
status: Approved
reviewed-head: c0abced3ae47fc9e0e4345f55eb7fc8cdf049e6d
added-range: 33985+11640
added-sha256: c0ddd16587c999b74bbdce969febcf4593125214a1ee6978ad7b3f478be86688
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
