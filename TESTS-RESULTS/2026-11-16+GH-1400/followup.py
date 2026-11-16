import json,os,pathlib,signal,subprocess,sys,time
base=pathlib.Path(sys.argv[1]).resolve() if len(sys.argv)>1 else pathlib.Path.cwd()/'temp/gh1400-followup'
baseline_rev=sys.argv[2] if len(sys.argv)>2 else '1d9658c3c63c1b1a8780ad26e4962f808b3c7625'
sys.argv=[sys.argv[0],'--out',str(base)]
text=pathlib.Path('TESTS-RESULTS/2026-11-15+GH-1400/check.py').read_text();exec(text[:text.index('def setup(name)')])
def identity():return [git(source,'rev-parse','HEAD'),git(source,'remote','get-url','origin'),git(source,'config','--get','core.bare'),subprocess.run(['git','-C',source,'config','--local','--get','user.email'],capture_output=True,text=True).stdout.strip(),git(source,'status','--porcelain','--untracked-files=no')]
start_identity=identity()
WORKER='''#!/usr/bin/env python3
import argparse,json,os,pathlib,signal,subprocess,sys,time
p=argparse.ArgumentParser();p.add_argument('--issue');p.add_argument('--result');p.add_argument('--execution-id');a,_=p.parse_known_args();t=pathlib.Path.cwd()
with open(t/'.tick/starts','a') as f:f.write(a.issue+'\\n')
(t/'.tick'/('worker-'+a.issue+'.pid')).write_text(str(os.getpid()))
mode=json.loads(os.environ.get('FIXTURE_MODES','{}')).get(a.issue,'approve')
def git(*x):return subprocess.check_output(['git',*x],text=True).strip()
git('switch','-c','fixture-'+a.issue+'-'+a.execution_id);(t/'feature.txt').write_text(a.issue);git('add','feature.txt');git('commit','-qm','controlled candidate');head=git('rev-parse','HEAD')
d=t/'.xyz/receipts';d.mkdir(parents=True,exist_ok=True);(d/(head+'.json')).write_text(json.dumps({'sha':head,'exit_code':0,'gate':'controlled fixture','mode':'synthetic'}))
r={'schema':'marathon-drive/result@1','execution_id':a.execution_id,'outcome':'approved','reason':'controlled result','exit_code':0,'issue':a.issue,'phase':'p','lane':'p','token':'T'+a.issue,'attempt':{'count':1,'max':2},'target_repo':{'path':str(t)},'base_branch':'development','head_branch':'fixture-'+a.issue+'-'+a.execution_id,'head_sha':head,'gate':{'result':'green'},'acceptance':{'checked':False},'pr':{'number':int(a.issue),'url':'https://example.invalid/pr/'+a.issue},'timestamps':{'finished_at':'2026-11-16T00:00:00Z'},'approval_preserved':False}
nopr={'number':None,'url':None,'state':None}
if mode in ('red','stop-owner'):r.update(outcome='escalated',reason='pre-advance-failed',exit_code=5,gate={'result':'red','exit':1},pr=nopr)
elif mode=='red-dirty':r.update(outcome='escalated',reason='pre-advance-failed',exit_code=5,gate={'result':'red','exit':1},pr=nopr)
elif mode=='ledger':r.update(outcome='escalated',reason='pre-advance-failed',exit_code=5,gate={'result':'red','exit':1},pr=nopr);open(t/'releases.sql','a').write('-- fixture ledger change\\n')
elif mode=='guardkill':r.update(outcome='escalated',reason='gate-killed',exit_code=5,gate={'result':'red','exit':108},pr=nopr)
elif mode=='postapprove':r.update(outcome='post-approve-failed',reason='post-approve-failed',exit_code=9,approval_preserved=True,pr=nopr)
elif mode=='refused':r.update(outcome='refused',reason='builder-equals-reviewer',exit_code=2,gate={'result':'not-run'},pr=nopr)
elif mode=='interrupted':r.update(outcome='interrupted',reason='interrupted (exit 143)',exit_code=143,gate={'result':'not-run'},pr=nopr)
elif mode=='notrun':r.update(outcome='escalated',reason='relay-failed-before-gate',exit_code=4,gate={'result':'not-run'},pr=nopr)
elif mode=='lock':r.update(outcome='lock-contention',reason='driver lock held by a live peer',exit_code=1,gate={'result':'not-run'},pr=nopr)
elif mode=='crashed':r.update(outcome='crashed',reason='driver raised an unhandled exception',exit_code=1,gate={'result':'red'},pr=nopr)
elif mode=='mismatch':r.update(outcome='escalated',reason='pre-advance-failed',exit_code=5,gate={'result':'red'},pr=nopr,execution_id='wrong')
if mode in ('corrupt','kill-corrupt'):pathlib.Path(a.result).write_text('{"schema": "marathon-drive/result@1", truncated')
elif mode not in ('kill-missing','missing'):pathlib.Path(a.result).write_text(json.dumps(r))
if mode=='red-dirty':(t/'feature.txt').write_text('uncommitted lane edit')
if mode=='stop-owner':
 owner=subprocess.Popen([sys.executable,'-c','import time;time.sleep(300)'],start_new_session=True,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);os.kill(owner.pid,signal.SIGSTOP)
 lock=t/'.git/relay-driver.lock';lock.mkdir();(lock/'pid').write_text(str(owner.pid));(t/'.tick/stopped-owner').write_text(str(owner.pid))
if mode.startswith('kill'):
 sys.stdout.flush();os.kill(os.getppid(),signal.SIGKILL);time.sleep(1)
'''
PREFLIGHT='''import argparse,json,os,pathlib,sys
p=argparse.ArgumentParser();p.add_argument('--gh-issue');p.add_argument('--out');a=p.parse_known_args()[0];d=pathlib.Path(a.out);d.mkdir(parents=True,exist_ok=True);t=pathlib.Path.cwd()
if a.gh_issue in os.environ.get('FIXTURE_NOT_READY','').split(','):
 print('verdict : not-ready (exit 3)');print('readiness : blocked — next: dependency GH-901 not delivered');sys.exit(3)
packet=d/'packet.json';packet.write_text('{}')
x={'schema':'swarm-preflight/marathon-invocation@1','argv':[str(t/'worker.py'),'--issue',a.gh_issue,'--result',str(d/'result.json')],'env':{},'harness_root':str(t),'target_root':str(t),'packet_path':str(packet),'issue':a.gh_issue,'phase':'p'+a.gh_issue,'lane':'p','gate':'fixture','builder':'codex','reviewer':'agy','base_ref':'development','result_path':str(d/'result.json'),'packet_dir':str(d),'artifacts':['feature.txt'],'drive_command':'controlled worker'}
(d/'marathon-invocation.json').write_text(json.dumps(x))
'''
ISSUES=[901,902,903,904]
def setup(name,held=()):
 work=out/name;work.mkdir();root=work/'primary';root.mkdir();git(root,'init','-qb','development');git(root,'config','user.name','Fixture');git(root,'config','user.email','fixture@example.invalid')
 remote=work/'remote.git';cmd(['git','init','-q','--bare',remote]);git(root,'remote','add','origin',remote);git(root,'config',primary_config_key(str(root)),root)
 app(root,'init')
 for n in ISSUES:app(root,'jog','add',str(n))
 (root/'.gitignore').write_text('.tick/\n.xyz/\n__pycache__/\n');(root/'feature.txt').write_text('initial\n')
 for n in ISSUES:
  p=root/f'PROJECT/2-WORKING/GH-{n}-FIXTURE.md';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(f'---\ngh_issue: {n}\n---\n# Fixture\n')
 pf=root/'utils/py/swarm_preflight.py';pf.parent.mkdir(parents=True);pf.write_text(PREFLIGHT)
 w=root/'worker.py';w.write_text(WORKER);w.chmod(0o755)
 git(root,'add','.');git(root,'commit','-qm','synthetic fixture');git(root,'push','-q','origin','development')
 if held:
  for n in held:j.jog_set_status(str(root),n,'parked',failure_reason='fixture: held before the wake')
  git(root,'add','-A');git(root,'commit','-qm','fixture held rows');git(root,'push','-q','origin','development')
 target=work/'execution';cmd(['git','clone','-q','--branch','development',remote,target]);git(target,'config','user.name','Fixture');git(target,'config','user.email','fixture@example.invalid')
 (target/'.tick').mkdir();(target/'.tick/starts').write_text('')
 pub=work/'publication';cmd(['git','clone','-q','--branch','development',remote,pub]);git(pub,'config','user.name','Fixture');git(pub,'config','user.email','fixture@example.invalid')
 return root,target,pub
def run(name,root,target,pub,modes=None,env=None,max_tasks=2,runner=None,deadline=None):
 extra=['--root',root,'jog','run'] if runner is None else ['--root',root]
 head=[sys.executable,source/'utils/py/releases_app.py'] if runner is None else [sys.executable,runner]
 argv=head+extra+['--target-root',target,'--checkpoint-root',pub,'--builder','codex','--reviewer','agy','--max-tasks',str(max_tasks),'--supervise-until',str(deadline or int(time.time()+90))]
 e={**os.environ,'CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true','FIXTURE_MODES':json.dumps({str(k):v for k,v in (modes or {}).items()}),**(env or {})}
 if runner is not None:e['PYTHONPATH']=str(source/'utils/py')
 p=subprocess.run([str(x) for x in argv],capture_output=True,text=True,env=e,timeout=150)
 (out/(name+'.log')).write_text(f'$ {" ".join(map(str,argv))}\nrc={p.returncode}\n'+p.stdout+p.stderr)
 return p
def starts(t):
 s=(t/'.tick/starts').read_text().split();return {n:s.count(str(n)) for n in ISSUES}
def byn(r):return {x['gh_number']:x for x in row(r)}
def ex(r,n):
 x=byn(r)[n];p=state(r,x['global_id']);return json.loads(p.read_text())['executions'] if p.exists() else []
def published(r):return git(r,'rev-parse','HEAD')==git(r,'ls-remote','origin','refs/heads/development').split()[0]
required=['local-failure-continues','local-failure-dirty-holds','stop-owner-next-wake-publishes','red-gate-killed','red-post-approve-failed','red-refused','red-interrupted','red-missing-receipt','red-clone-ledger-changed','budgets-held','dependent-not-dispatched','no-reentry-next-wake','restart-adopts-once','restart-missing-holds','restart-corrupt-holds','stop-owner-after-failure','stop-checkpoint-contradiction','red-lock-contention','red-crashed','red-gate-not-run','red-corrupt-receipt','red-mismatched-receipt','baseline-red']
(out/'required.json').write_text(json.dumps(required))
def ck(name,pred,detail):
 records.append({'id':name,'pass':bool(pred),'detail':detail,'source':git(source,'rev-parse','HEAD')})
r,t,pb=setup('local');p=run('local',r,t,pb,{901:'red'});q=byn(r);s=starts(t)
ck('local-failure-continues',p.returncode==0 and s=={901:1,902:1,903:0,904:0} and q[901]['status']=='failed' and 'pre-advance-failed' in (q[901]['failure_reason'] or '') and 'result:' in q[901]['failure_reason'] and q[901]['attempt_count']==1 and q[902]['status']=='parked' and ex(r,901)[-1]['status']=='projected-failed' and 'failed task-locally' in p.stdout and published(r),{'rc':p.returncode,'starts':s,'rows':q,'stdout':p.stdout[-1500:],'stderr':p.stderr[-800:]})
ck('budgets-held',s[903]==0 and 'reached max-tasks limit (2)' in p.stdout and q[903]['status']=='pending' and q[903]['attempt_count']==0,{'starts':s,'rows':q})
p2=run('local-next',r,t,pb,{},max_tasks=1);s2=starts(t);q2=byn(r)
ck('no-reentry-next-wake',p2.returncode==0 and s2[901]==1 and s2[903]==1 and byn(r)[901]['status']=='failed' and q2[901]['attempt_count']==1 and len(ex(r,901))==1,{'starts':s2,'rows':q2,'stdout':p2.stdout[-800:]})
r,t,pb=setup('held',held=(902,));p=run('held',r,t,pb,{901:'red'},env={'FIXTURE_NOT_READY':'904'},max_tasks=4);s=starts(t);q=byn(r)
ck('dependent-not-dispatched',s=={901:1,902:0,903:1,904:0} and q[902]['status']=='parked' and q[902]['attempt_count']==0 and q[904]['status']=='parked' and 'preflight-refused' in (q[904]['failure_reason'] or '') and q[901]['status']=='failed',{'rc':p.returncode,'starts':s,'rows':q,'stdout':p.stdout[-1200:]})
for mode,cid in [('kill-approve','restart-adopts-once'),('kill-missing','restart-missing-holds'),('kill-corrupt','restart-corrupt-holds')]:
 r,t,pb=setup(cid);mm={901:'kill' if mode=='kill-approve' else mode};p=run(cid+'-killed',r,t,pb,mm);s1=starts(t);mid=byn(r)
 journal=json.loads((r/'.tick/jog/checkpoint.json').read_text());killed=p.returncode==-9 and s1=={901:1,902:0,903:0,904:0} and mid[901]['status']=='running' and journal.get('phase')=='running' and not ex(r,901)[-1].get('committed_receipt')
 wp=t/'.tick/worker-901.pid';end=time.monotonic()+20
 while wp.exists() and time.monotonic()<end:
  try:os.kill(int(wp.read_text()),0);time.sleep(.1)
  except ProcessLookupError:break
 else:
  pass
 try:os.kill(int(wp.read_text()),0);orphan=True
 except ProcessLookupError:orphan=False
 killed=killed and not orphan
 p2=run(cid+'-restart',r,t,pb,{},max_tasks=1);s2=starts(t);q=byn(r);e=ex(r,901)
 if mode=='kill-approve':ok=killed and p2.returncode==0 and s2=={901:1,902:1,903:0,904:0} and len(e)==1 and bool(e[0].get('committed_receipt')) and q[901]['attempt_count']==1 and q[901]['status']=='parked' and 'awaiting-landing' in (q[901]['failure_reason'] or '') and 'recovered GH-901' in p2.stdout and published(r)
 else:ok=killed and s2=={901:1,902:1,903:0,904:0} and len(e)==1 and not e[0].get('committed_receipt') and q[901]['status']=='parked' and 'supervision held' in (q[901]['failure_reason'] or '') and q[901]['attempt_count']==1
 ck(cid,ok,{'killed_rc':p.returncode,'after_kill':{'starts':s1,'row':mid[901],'journal_phase':journal.get('phase')},'restart_rc':p2.returncode,'starts':s2,'rows':q,'executions':e,'stdout':p2.stdout[-1200:],'stderr':p2.stderr[-600:]})
r,t,pb=setup('stop-owner')
try:
 p=run('stop-owner',r,t,pb,{901:'stop-owner'});s=starts(t);q=byn(r);lock=t/'.git/relay-driver.lock'
 ck('stop-owner-after-failure',p.returncode==4 and s=={901:1,902:0,903:0,904:0} and q[901]['status']=='failed' and q[902]['status']=='pending' and q[902]['attempt_count']==0 and lock.exists() and (lock/'pid').read_text()==(t/'.tick/stopped-owner').read_text(),{'rc':p.returncode,'starts':s,'rows':q,'stdout':p.stdout[-1000:],'stderr':p.stderr[-600:]})
finally:
 pid=t/'.tick/stopped-owner'
 if pid.exists():
  try:os.kill(int(pid.read_text()),signal.SIGKILL);time.sleep(.3)
  except ProcessLookupError:pass
journal=json.loads((r/'.tick/jog/checkpoint.json').read_text()).get('phase');unpub=not published(r)
p2=run('stop-owner-next-wake',r,t,pb,{},max_tasks=1);s2=starts(t);q2=byn(r)
ck('stop-owner-next-wake-publishes',journal=='running' and unpub and p2.returncode==0 and s2=={901:1,902:1,903:0,904:0} and q2[901]['status']=='failed' and published(r),{'journal_before':journal,'unpublished_before':unpub,'rc':p2.returncode,'starts':s2,'rows':q2,'stdout':p2.stdout[-800:]})
r,t,pb=setup('local-dirty');p=run('local-dirty',r,t,pb,{901:'red-dirty'});s=starts(t);q=byn(r)
ck('local-failure-dirty-holds',p.returncode==2 and 'tracked changes' in p.stderr and s=={901:1,902:0,903:0,904:0} and q[901]['status']=='failed' and q[902]['status']=='pending' and (t/'feature.txt').read_text()=='uncommitted lane edit',{'rc':p.returncode,'starts':s,'rows':q,'stderr':p.stderr[-600:]})
r,t,pb=setup('stop-checkpoint');old=git(r,'rev-parse','HEAD');(r/'foreign.txt').write_text('foreign');git(r,'add','foreign.txt');git(r,'commit','-qm','foreign change outside the wake')
(r/'.tick/jog').mkdir(parents=True,exist_ok=True);(r/'.tick/jog/checkpoint.json').write_text(json.dumps({'base':old,'phase':'running','queue':{}}))
p=run('stop-checkpoint',r,t,pb,{901:'red'});s=starts(t);q=byn(r)
ck('stop-checkpoint-contradiction',p.returncode==2 and 'checkpoint held' in p.stderr and s=={901:0,902:0,903:0,904:0} and all(x['status']=='pending' and x['attempt_count']==0 for x in q.values()),{'rc':p.returncode,'starts':s,'stderr':p.stderr[-600:]})
for mode,cid in [('guardkill','red-gate-killed'),('postapprove','red-post-approve-failed'),('refused','red-refused'),('interrupted','red-interrupted'),('missing','red-missing-receipt'),('ledger','red-clone-ledger-changed'),('lock','red-lock-contention'),('crashed','red-crashed'),('notrun','red-gate-not-run'),('corrupt','red-corrupt-receipt'),('mismatch','red-mismatched-receipt')]:
 r,t,pb=setup(cid);p=run(cid,r,t,pb,{901:mode});s=starts(t);q=byn(r)
 ck(cid,s=={901:1,902:0,903:0,904:0} and q[901]['status']=='failed' and q[902]['status']=='pending' and 'stopping queue execution on task failure' in p.stdout and 'failed task-locally' not in p.stdout,{'rc':p.returncode,'starts':s,'rows':q,'stdout':p.stdout[-800:]})
r,t,pb=setup('baseline');bl=out/'baseline_jog.py';bl.write_text(git(source,'show',baseline_rev+':utils/py/jog_run.py')+'\n')
p=run('baseline',r,t,pb,{901:'red'},runner=bl);s=starts(t);q=byn(r)
blob=git(source,'rev-parse',baseline_rev+':utils/py/jog_run.py')
ck('baseline-red',s=={901:1,902:0,903:0,904:0} and q[901]['status']=='failed' and q[902]['status']=='pending' and 'stopping queue execution on task failure' in p.stdout,{'baseline':baseline_rev,'blob':blob,'rc':p.returncode,'starts':s,'stdout':p.stdout[-800:],'predicate':'unfixed runtime must leave independent B undispatched'})
end_identity=identity()
ids=[x['id'] for x in records]
complete=bool(required) and len(set(ids))==len(ids) and set(ids)==set(required) and all(x['pass'] for x in records) and start_identity==end_identity
(out/'results.json').write_text(json.dumps({'complete':complete,'identity_start':start_identity,'identity_end':end_identity,'records':records},indent=1))
print(json.dumps({'complete':complete,'passed':sum(x['pass'] for x in records),'required':len(required),'failed':[x['id'] for x in records if not x['pass']],'source':start_identity[0]}))
sys.exit(0 if complete else 1)
