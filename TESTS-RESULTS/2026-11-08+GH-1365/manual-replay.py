"""Manual GH-1365 replay: actual Jog CLI, captured GH reads, local-only writes.
Usage: python3 manual-replay.py SOURCE_CLONE DISPOSABLE_WORK_DIRECTORY
The work directory must be empty. No production function is monkeypatched.
"""
import copy,hashlib,importlib.util,json,os,shutil,sqlite3,subprocess,sys,tempfile
from pathlib import Path
source=Path(sys.argv[1]).resolve()
D='TESTS-RESULTS/2026-11-08+GH-1365'
work=Path(sys.argv[2]).resolve();work.mkdir(parents=True,exist_ok=False)
root=work/'primary';remote=work/'remote.git'
def run(a,cwd=None,**kw): return subprocess.run(a,cwd=cwd,check=True,**kw)
run(['git','clone','--no-hardlinks',str(source),str(root)],stdout=subprocess.DEVNULL)
run(['git','branch','-m','development'],cwd=root)
run(['git','clone','--bare','--no-hardlinks',str(root),str(remote)],stdout=subprocess.DEVNULL)
H='50b60b19901254a6da50ef550ee4a6283c9d9bcf'
run(['git','--git-dir',str(remote),'update-ref','refs/pull/1361/head',H])
run(['git','remote','set-url','origin','https://github.com/HiQS-Labs/XYZ-forge.git'],cwd=root)
realgit=shutil.which('git');bins=work/'bin';bins.mkdir()
# Command adapters are test boundaries, never installed or inherited by real checkouts.
gitshim='''#!PYTHON
import os,sys
from pathlib import Path
a=sys.argv[1:]
if 'fetch' in a:
 i=a.index('fetch')
 if 'origin' in a[i:]: a[a.index('origin',i)]=os.environ['SPIKE_REMOTE']
os.execv(os.environ['SPIKE_REAL_GIT'],[os.environ['SPIKE_REAL_GIT'],*a])
'''.replace('PYTHON',sys.executable)
(bins/'git').write_text(gitshim);(bins/'git').chmod(0o755)
ghshim='''#!PYTHON
import json,os,sys
from pathlib import Path
a=sys.argv[1:];s=Path(os.environ['SPIKE_IO'])
with (s/'gh-calls.jsonl').open('a') as f:f.write(json.dumps(a)+'\\n')
if a[:2]==['pr','view']:print((s/'pr.json').read_text())
elif a[:2]==['issue','view']:print((s/'issue.json').read_text())
elif a[:2]==['run','list']:print('[]')
elif a[:2]==['issue','comment']:
 d=json.loads((s/'issue.json').read_text());d.setdefault('comments',[]).append({'body':a[a.index('--body')+1]});(s/'issue.json').write_text(json.dumps(d));print('RECORDED_ONLY: issue comment')
elif a[:2]==['issue','close']:
 d=json.loads((s/'issue.json').read_text());d.update(state='CLOSED',stateReason='COMPLETED');(s/'issue.json').write_text(json.dumps(d));print('RECORDED_ONLY: issue close')
else:print('UNEXPECTED GH OPERATION '+repr(a),file=sys.stderr);sys.exit(90)
'''.replace('PYTHON',sys.executable)
(bins/'gh').write_text(ghshim);(bins/'gh').chmod(0o755)
for n in ('pr.json','issue.json'):shutil.copy(root/D/n,work/n)
os.environ.update(PATH=str(bins)+':'+str(Path(sys.executable).parent)+':'+os.environ['PATH'],SPIKE_REMOTE=str(remote),SPIKE_REAL_GIT=realgit,SPIKE_IO=str(work))
sys.path.insert(0,str(root/'utils/py'));sys.path.insert(0,str(root/D))
import harness_paths
run(['git','config',harness_paths.primary_config_key(str(root)),str(root)],cwd=root)
B='TESTS-RESULTS/2026-11-07+GH-1287/jog/gh1287-exec1-gateretry1'
results=[]
def state():
 with sqlite3.connect(root/'releases.db') as c:
  return {'queue':c.execute('SELECT status,failure_reason FROM jog_queue WHERE gh_number=1287').fetchall(),
          'counts':[c.execute('SELECT COUNT(*) FROM '+t).fetchone()[0] for t in ('op_receipts','work_events')]}
def exercise(name,expected):
 before=state()
 p=subprocess.run([sys.executable,str(root/'utils/py/releases_app.py'),'--root',str(root),'jog','land','1287','--pr','1361'],cwd=root,capture_output=True,text=True)
 after=state();assert p.returncode==expected,(name,p.returncode,p.stderr,p.stdout)
 if expected: assert before==after,(name,'mutated queue on refusal')
 results.append({'case':name,'rc':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'before':before,'after':after})
 return after
def commit_bundle():
 run(['git','add','--',B],cwd=root,stdout=subprocess.DEVNULL)
 run(['git','commit','-qm','manual control: fixture receipt only'],cwd=root)
code=root/'utils/py/jog_run.py';candidate=code.read_bytes()
code.write_bytes(subprocess.check_output(['git','show','cff1d0a16:utils/py/jog_run.py'],cwd=root))
exercise('baseline refuses actual PR1361 tail',2);code.write_bytes(candidate)
pr=(work/'pr.json').read_bytes()
for name,change in [('unmerged PR',{'state':'OPEN'}),('wrong base',{'baseRefName':'main'}),('wrong fetched head',{'headRefOid':'0'*40}),('unreachable merge',{'mergeCommit':{'oid':'0'*40}})]:
 d=json.loads(pr);d.update(change);(work/'pr.json').write_text(json.dumps(d));exercise(name,2)
(work/'pr.json').write_bytes(pr)
gate=root/B/'gate-receipt.json';gate_raw=gate.read_bytes()
gate.write_text('{}\n');commit_bundle();exercise('tampered committed gate',2);gate.write_bytes(gate_raw);commit_bundle()
first=exercise('candidate completes actual historical PR1361',0)
assert first['queue'][0][0]=='completed'
landing=root/B/'landing.json';saved=landing.read_bytes();d=json.loads(saved)
assert d['completion_policy']=='merged-pr' and 'tail_proof' not in d
assert d['tested_head_sha']==d['approved_head_sha']=='b39b9a2fe55c4a8509456d9171a5ec539d4f2cf0'
assert d['reviewed_head_sha']=='99aa9e262701d9b0947c6ac49289cd9e5200ac9d'
assert d['reviewed_candidate_sha']==d['tested_head_sha'] and d['landed_head_sha']==H
second=exercise('repeat closeout adds no transitions or evidence changes',0)
assert first==second and landing.read_bytes()==saved
# A valid, self-consistent historical receipt on a non-ancestor must not reintroduce ancestry.
# Controlled fixture only, never published as a real review or test result.
tree=subprocess.check_output(['git','rev-parse',H+'^{tree}'],cwd=root,text=True).strip()
unrelated=subprocess.check_output(['git','commit-tree',tree],input=b'manual unrelated historical candidate\n',cwd=root).decode().strip()
assert subprocess.run(['git','merge-base','--is-ancestor',unrelated,H],cwd=root).returncode==1
rpath=root/B/'marathon-result.json';r=json.loads(rpath.read_bytes())
r.update(head_sha=unrelated,reviewed_head=unrelated,reviewed_candidate=unrelated)
rpath.write_text(json.dumps(r)+'\n');g=json.loads(gate_raw);g['sha']=unrelated;gate.write_text(json.dumps(g)+'\n')
p=root/B/'provenance.jsonl';p.write_text(json.dumps({'source':'approved Marathon result','execution_id':r['execution_id'],'approved_sha':unrelated,'result_sha256':hashlib.sha256(rpath.read_bytes()).hexdigest(),'gate_sha256':hashlib.sha256(gate.read_bytes()).hexdigest()})+'\n')
m=root/B/'receipt.json';v=json.loads(m.read_bytes())
for n in v['files']:v['files'][n]=hashlib.sha256((root/B/n).read_bytes()).hexdigest()
m.write_text(json.dumps(v)+'\n');commit_bundle()
import jog_run
jog_run.jog_set_status(str(root),1287,'parked',failure_reason='manual non-ancestor fixture')
third=exercise('non-ancestor historical receipt can complete parked queue',0)
assert third['queue'][0][0]=='completed' and json.loads(landing.read_bytes())['tested_head_sha']==unrelated
out={'result':'PASS','source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip(),
     'boundary':'Actual Jog CLI and ledger; local bare fetch mirror; captured GitHub reads; issue writes recorded locally only',
     'cases':results,'historical_landing':d,'nonancestor_fixture_sha':unrelated}
(work/'results.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
