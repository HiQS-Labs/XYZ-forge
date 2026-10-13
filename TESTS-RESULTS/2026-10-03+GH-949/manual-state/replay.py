"""Manual GH-949 before/after replay; no suite or gate registration."""
import datetime, hashlib, json, os, pathlib, subprocess, sys, time
repo=pathlib.Path(sys.argv[1]).resolve(); out=pathlib.Path(sys.argv[2]).resolve()
out.mkdir(parents=True,exist_ok=False)
sys.path.insert(0,str(repo/'utils/py'))
from domain_oracles import check_zero_state,check_host_containment
rows=[]
def run(cmd, **kw):return subprocess.run(cmd,text=True,capture_output=True,timeout=30,**kw)
def record(case,passed,observed):rows.append(dict(case=case,passed=bool(passed),observed=observed));print(json.dumps(rows[-1]),flush=True)
def git(p,*args):
 r=run(['git','-C',str(p),*args]);assert r.returncode==0,(args,r.stderr);return r.stdout
# Existing directory-link digest probes, with unchanged/file controls.
a=out/'target-a';b=out/'target-b';a.mkdir();b.mkdir();(a/'sentinel').write_text('a');(b/'sentinel').write_text('b')
for case in ['noop','file','link-add','link-remove','link-retarget']:
 p=out/case;p.mkdir();(p/'sentinel').write_text('unchanged')
 if case in ('link-remove','link-retarget'):(p/'link').symlink_to(a,target_is_directory=True)
 code={'noop':'pass','file':'from pathlib import Path; Path("sentinel").write_text("changed")','link-add':f'from pathlib import Path; Path("link").symlink_to({str(a)!r})','link-remove':'from pathlib import Path; Path("link").unlink()','link-retarget':f'from pathlib import Path; Path("link").unlink(); Path("link").symlink_to({str(b)!r})'}[case]
 result=check_zero_state([sys.executable,'-c',code],str(p),timeout=3)
 record(case,result['passed']==(case=='noop'),result)
assert (a/'sentinel').read_text()=='a' and (b/'sentinel').read_text()=='b'
# Owned linked worktree fixtures only. Never execute suites in them.
for case in ['standalone-config','linked-config','linked-worktree-config','linked-noop']:
 d=out/case;d.mkdir();p=d/'primary';p.mkdir();w=d/'work';w.mkdir();git(p,'init','-q');git(p,'-c','user.name=Probe','-c','user.email=probe@example.invalid','commit','--allow-empty','-qm','fixture')
 h=p
 if case.startswith('linked'):
  h=d/'linked';git(p,'worktree','add','--detach',str(h),'HEAD')
 if case=='linked-worktree-config':git(p,'config','extensions.worktreeConfig','true')
 cmd=[sys.executable,'-c','pass'] if case=='linked-noop' else ['git','-C',str(h),'config','--worktree' if case=='linked-worktree-config' else '--local','gh949.probe','changed']
 try:
  result=check_host_containment(cmd,str(w),str(h),timeout=3)
  record(case,result['passed']==(case=='linked-noop'),result)
 finally:
  if h!=p:git(p,'worktree','remove',str(h))
# HOME must not be needed for a valid explicit override.
for xdg in [False,True]:
 env=dict(os.environ,XYZ_HARNESS=str(repo));env.pop('HOME',None);env.pop('XDG_CONFIG_HOME',None)
 if xdg:env['XDG_CONFIG_HOME']=str(out/'xdg')
 r=run(['bash',str(repo/'skills/1-hourly/relay-xyz/find-harness.sh'),'--env'],env=env,cwd=out)
 record('home-unset-xdg-'+str(xdg),r.returncode==0 and str(repo) in r.stdout,{'rc':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
# Actual ATE producer; controlled git-init disposable repo, no remote, mock classifier.
for case in ['empty-grid','missing-command','utc-timestamp']:
 d=out/case;d.mkdir();scratch=d/'scratch';scratch.mkdir();git(scratch,'init','-q');(scratch/'sentinel').write_text('preserve')
 log=d/'rows.jsonl';control=d/'control.json';control.write_text('{"action":"sentinel"}')
 grid={'variation_keys':['x'],'x':[] if case=='empty-grid' else ['a'],'model':'stub','message':'manual probe','expects_edits':False,'command_template':[str(d/'missing')] if case=='missing-command' else [sys.executable,'-c','pass']}
 (d/'grid.json').write_text(json.dumps(grid))
 env=dict(os.environ,HOME=str(d),GIT_CONFIG_GLOBAL='/dev/null',GIT_CONFIG_NOSYSTEM='1',TZ='America/Los_Angeles',PYTHONDONTWRITEBYTECODE='1')
 cmd=[sys.executable,str(repo/'utils/ate/scripts/run_variations.py'),'--repo',str(scratch),'--variations',str(d/'grid.json'),'--log',str(log),'--control',str(control),'--mock-classifier','--minutes','0.02']
 begin=time.time();r=run(cmd,env=env,cwd=d);end=time.time();(d/'stdout').write_text(r.stdout);(d/'stderr').write_text(r.stderr)
 records=[json.loads(s) for s in log.read_text().splitlines()] if log.exists() else []
 observed={'rc':r.returncode,'rows':len(records),'records':records,'stderr':r.stderr,'command':cmd,'utc_start':begin,'utc_end':end}
 if case=='empty-grid':ok=r.returncode!=0 and not records and control.read_text()=='{"action":"sentinel"}' and (scratch/'sentinel').read_text()=='preserve'
 elif case=='missing-command':ok=r.returncode!=0 and len(records)==1 and records[0]['status']=='fail' and records[0]['classification']['category']=='spawn_error'
 else:
  stamps=[datetime.datetime.fromisoformat(x['timestamp'].replace('Z','+00:00')).timestamp() for x in records]
  ok=bool(stamps) and all(begin-1<=s<=end+1 for s in stamps)
 record(case,ok,observed)
sha=git(repo,'rev-parse','HEAD').strip()
(out/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
(out/'provenance.jsonl').write_text(json.dumps({'source_sha':sha,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':sys.argv,'script_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),'checks':len(rows),'correct_properties':sum(r['passed'] for r in rows),'result_sha256':hashlib.sha256((out/'results.json').read_bytes()).hexdigest()})+'\n')
print('SUMMARY',sum(r['passed'] for r in rows),'/',len(rows))
