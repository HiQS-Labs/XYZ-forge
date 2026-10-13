# Independent Codex final code QA receipt

Extracted verbatim from the committed Round 2 reviewer block; full protocol and attestation in gh1006-final-qa.md. The classified full gate remains a publication condition.

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
