import argparse, hashlib, json, os, pathlib, shutil, signal, sqlite3, subprocess, sys, time
source=pathlib.Path.cwd(); sys.path.insert(0,str(source/'utils/py'))
import jog_run as j
from gate_receipt import write_receipt
from harness_paths import primary_config_key
ap=argparse.ArgumentParser(); ap.add_argument('--out',required=True); a=ap.parse_args()
out=pathlib.Path(a.out).resolve();out.mkdir(parents=True,exist_ok=True)
assert source.name.endswith('-verify') and (source/'.git').is_dir()
records=[]
def cmd(argv, cwd=None, env=None):
 p=subprocess.run([str(x) for x in argv],cwd=cwd,env=env,capture_output=True,text=True)
 if p.returncode: raise RuntimeError(f'{argv}: {p.returncode}: {p.stdout} {p.stderr}')
 return p.stdout.strip()
def git(root,*args):return cmd(['git','-C',root,*args])
def app(root,*args):return cmd([sys.executable,source/'utils/py/releases_app.py','--root',root,*args])
def row(root):
 c=sqlite3.connect(root/'releases.db');c.row_factory=sqlite3.Row
 try:return [dict(x) for x in c.execute('SELECT gh_number,global_id,status,attempt_count,lease_pid,failure_reason FROM jog_queue ORDER BY gh_number')]
 finally:c.close()
def state(root,gid):return root/'.tick/jog'/gid/'state.json'
def setup(name):
 work=out/name; work.mkdir();root=work/'primary';root.mkdir();git(root,'init','-b','development');git(root,'config','user.name','Fixture');git(root,'config','user.email','fixture@example.invalid')
 remote=work/'remote.git';cmd(['git','init','--bare',remote]);git(root,'remote','add','origin',remote)
 git(root,'config',primary_config_key(str(root)),root)
 app(root,'init');app(root,'jog','add','901');app(root,'jog','add','902')
 (root/'.gitignore').write_text('.tick/\n.xyz/\n__pycache__/\n')
 (root/'feature.txt').write_text('initial\n')
 for n in [901,902]:
  p=root/f'PROJECT/2-WORKING/GH-{n}-FIXTURE.md';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(f'---\ngh_issue: {n}\n---\n# Fixture\n')
 pf=root/'utils/py/swarm_preflight.py';pf.parent.mkdir(parents=True)
 pf.write_text('''import argparse,json,os,pathlib,sys
p=argparse.ArgumentParser();p.add_argument('--gh-issue');p.add_argument('--out');a=p.parse_args();d=pathlib.Path(a.out);d.mkdir(parents=True,exist_ok=True);t=pathlib.Path.cwd()
if os.environ.get('FIXTURE_HOLD'):
 print('verdict : not-ready (exit 3)');sys.exit(3)
packet=d/'packet.json';packet.write_text('{}')
x={'schema':'swarm-preflight/marathon-invocation@1','argv':[str(t/'worker.py'),'--issue',a.gh_issue,'--result',str(d/'result.json')],'env':{},'harness_root':str(t),'target_root':str(t),'packet_path':str(packet),'issue':a.gh_issue,'phase':'p'+a.gh_issue,'lane':'p','gate':'fixture','builder':'codex','reviewer':'agy','base_ref':'development','result_path':str(d/'result.json'),'packet_dir':str(d),'artifacts':['feature.txt'],'drive_command':'controlled worker'}
(d/'marathon-invocation.json').write_text(json.dumps(x))
''')
 worker=root/'worker.py';worker.write_text('''#!/usr/bin/env python3
import argparse,json,os,pathlib,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--issue');p.add_argument('--result');p.add_argument('--execution-id');a,_=p.parse_known_args();t=pathlib.Path.cwd()
with open(t/'.tick/starts','a') as f:f.write(a.issue+'\\n')
if os.environ.get('FIXTURE_SLEEP'):time.sleep(30)
def git(*x):return subprocess.check_output(['git',*x],text=True).strip()
git('switch','-c','fixture-'+a.issue);(t/'feature.txt').write_text(a.issue);git('add','feature.txt');git('commit','-m','controlled candidate');head=git('rev-parse','HEAD')
d=t/'.xyz/receipts';d.mkdir(parents=True,exist_ok=True);(d/(head+'.json')).write_text(json.dumps({'sha':head,'exit_code':0,'gate':'controlled fixture','mode':'synthetic'}))
r={'schema':'marathon-drive/result@1','execution_id':a.execution_id,'outcome':'approved','reason':'controlled result','exit_code':0,'issue':a.issue,'phase':'p','lane':'p','token':'T'+a.issue,'attempt':{'count':1,'max':2},'target_repo':{'path':str(t)},'base_branch':'development','head_branch':'fixture-'+a.issue,'head_sha':head,'gate':{'result':'green'},'acceptance':{'checked':False},'pr':{'number':int(a.issue),'url':'https://example.invalid/pr/'+a.issue},'timestamps':{'finished_at':'2026-11-15T00:00:00Z'}}
pathlib.Path(a.result).write_text(json.dumps(r))
''');worker.chmod(0o755)
 git(root,'add','.');git(root,'commit','-m','synthetic fixture');git(root,'push','origin','development')
 target=work/'execution';cmd(['git','clone','--branch','development',remote,target]);git(target,'config','user.name','Fixture');git(target,'config','user.email','fixture@example.invalid')
 (target/'.tick').mkdir();(target/'.tick/starts').write_text('901\n');(target/'retained-relay.log').write_text('unique log\n')
 git(target,'switch','-c','fixture-901');(target/'feature.txt').write_text('901');git(target,'add','feature.txt');git(target,'commit','-m','approved controlled A')
 head=git(target,'rev-parse','HEAD');write_receipt(str(target),head,'controlled fixture','synthetic',0)
 rows=row(root);gid=rows[0]['global_id'];base=state(root,gid).parent;packet=base/'gh901-exec1/preflight';packet.mkdir(parents=True)
 cmd([sys.executable,target/'utils/py/swarm_preflight.py','--gh-issue','901','--out',packet],cwd=target)
 inv=json.loads((packet/'marathon-invocation.json').read_text())
 receipt={'schema':j.MARATHON_RESULT_SCHEMA,'execution_id':'gh901-exec1','outcome':'approved','reason':'controlled interrupted result','exit_code':0,'issue':'901','phase':'p','lane':'p','token':'T901','attempt':{'count':1,'max':2},'target_repo':{'path':str(target)},'base_branch':'development','head_branch':'fixture-901','head_sha':head,'gate':{'result':'green'},'acceptance':{'checked':False},'pr':{'number':901,'url':'https://example.invalid/pr/901'},'timestamps':{'finished_at':'2026-11-15T00:00:00Z'}}
 pathlib.Path(inv['result_path']).write_text(json.dumps(receipt))
 state(root,gid).write_text(json.dumps({'schema':j.JOG_EXECUTION_STATE_SCHEMA,'gid':gid,'gh_number':901,'executions':[{'execution_id':'gh901-exec1','status':'dispatched','packet_dir':str(packet),'result_path':inv['result_path']}]}))
 c=sqlite3.connect(root/'releases.db');c.execute("UPDATE jog_queue SET status='running',attempt_count=1,lease_pid=99999999 WHERE gh_number=901");c.commit();c.close()
 # Retained synthetic crash input uses a direct DB edit only inside this disposable fixture.
 # Canonical writers own every effect of the CLI under observation.
 return root,target,gid,receipt

def wake(name,root,target,extra=None,env=None,deadline=None):
 argv=[sys.executable,source/'utils/py/releases_app.py','--root',root,'jog','run','--target-root',target,'--builder','codex','--reviewer','agy','--max-tasks','2','--supervise-until',str(deadline or int(time.time()+60))]+(extra or [])
 p=subprocess.run([str(x) for x in argv],capture_output=True,text=True,env={**os.environ,'CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true',**(env or {})},timeout=90)
 (out/(name+'.log')).write_text(p.stdout+p.stderr)
 return p

def check(name,predicate,detail):
 records.append({'id':name,'pass':bool(predicate),'detail':detail});assert predicate,(name,detail)
required=['adoption-continuation','repeat-no-build','readiness-hold','mismatch-hold','missing-hold','malformed-hold','stopped-owner','expired-deadline','worker-timeout','branch-log-preserved','tracked-dirty-held','native-attempt-retained']
(out/'required.json').write_text(json.dumps(required))
r,t,g,receipt=setup('main');p=wake('main-first',r,t);rs=row(r)
check('adoption-continuation',p.returncode==0 and [x['status'] for x in rs]==['parked','parked'] and 'recovered GH-901' in p.stdout and (t/'.tick/starts').read_text()=='901\n902\n',{'rc':p.returncode,'rows':rs,'stdout':p.stdout})
before=(t/'.tick/starts').read_bytes();states={x['global_id']:state(r,x['global_id']).read_bytes() for x in rs};p=wake('main-repeat',r,t)
check('repeat-no-build',p.returncode==0 and before==(t/'.tick/starts').read_bytes() and all(state(r,k).read_bytes()==v for k,v in states.items()),p.stdout)
check('native-attempt-retained',all(x['attempt_count']==1 for x in row(r)) and all(len(json.loads(v)['executions'])==1 for v in states.values()),row(r))
for name,mode in [('readiness','hold'),('mismatch','mismatch'),('missing','missing'),('malformed','malformed'),('expired','expired'),('dirty','dirty'),('timeout','timeout')]:
 r,t,g,receipt=setup(name);sp=state(r,g);data=json.loads(sp.read_text());rp=pathlib.Path(data['executions'][0]['result_path'])
 if mode=='mismatch':receipt['execution_id']='wrong';rp.write_text(json.dumps(receipt))
 if mode=='missing':rp.unlink()
 if mode=='malformed':sp.write_text('[]')
 if mode=='dirty':(t/'feature.txt').write_text('uncommitted preserve')
 p=wake(name,r,t,env={'FIXTURE_HOLD':'1'} if mode=='hold' else {'FIXTURE_SLEEP':'1'} if mode=='timeout' else None,deadline=int(time.time()-1) if mode=='expired' else int(time.time()+3) if mode=='timeout' else None)
 starts=(t/'.tick/starts').read_text();rs=row(r)
 if mode=='hold':check('readiness-hold',starts=='901\n' and rs[1]['status']=='parked' and 'preflight-refused' in rs[1]['failure_reason'],rs)
 elif mode in ('mismatch','missing'):check(mode+'-hold',rs[0]['status']=='parked' and 'supervision held' in rs[0]['failure_reason'] and starts.count('901\n')==1,rs)
 elif mode=='malformed':check('malformed-hold',p.returncode==2 and starts=='901\n' and sp.read_text()=='[]',p.stderr)
 elif mode=='expired':check('expired-deadline',p.returncode==2 and starts=='901\n' and rs[0]['status']=='running',p.stderr)
 elif mode=='dirty':check('tracked-dirty-held',starts=='901\n' and (t/'feature.txt').read_text()=='uncommitted preserve',p.stdout+p.stderr)
 elif mode=='timeout':
  check('worker-timeout',p.returncode==2 and 'deadline reached' in p.stderr and starts=='901\n902\n',p.stderr)
  p2=wake('timeout-restart',r,t);assert (t/'.tick/starts').read_text()==starts and row(r)[1]['status']=='parked'
r,t,g,receipt=setup('preserve');git(t,'switch','development');(t/'local-contract.txt').write_text('unique contract');git(t,'add','local-contract.txt');git(t,'commit','-m','unique local contract');head=git(t,'rev-parse','HEAD');git(t,'switch','fixture-901');p=wake('preserve',r,t)
check('branch-log-preserved',p.returncode==0 and git(t,'rev-parse','jog-preserved-development-'+head)==head and (t/'retained-relay.log').read_text()=='unique log\n',p.stdout+p.stderr)
r,t,g,receipt=setup('stopped');owner=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)']);os.kill(owner.pid,signal.SIGSTOP)
try:
 lock=t/'.git/relay-driver.lock';lock.mkdir();(lock/'pid').write_text(str(owner.pid));p=wake('stopped',r,t)
 check('stopped-owner',p.returncode==4 and (t/'.tick/starts').read_text()=='901\n' and lock.exists(),p.stdout+p.stderr)
finally:os.kill(owner.pid,signal.SIGKILL);owner.wait()
assert len(records)==len(required) and {x['id'] for x in records}==set(required) and all(x['pass'] for x in records)
(out/'results.json').write_text(json.dumps(records,indent=2));print(json.dumps({'passed':len(records),'required':len(required),'source':git(source,'rev-parse','HEAD')}))
