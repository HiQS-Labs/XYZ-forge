import ast, types, os, sys, json, sqlite3, tempfile, contextlib, io, subprocess
from pathlib import Path
sources={'fixed':Path('utils/py/jog_run.py').read_text(),'prior':subprocess.check_output(['git','show','HEAD:utils/py/jog_run.py'],text=True)}
def control(source,case):
 tree=ast.parse(source)
 main=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='jog_run_main')
 loop=next(n for n in ast.walk(main) if isinstance(n,ast.While) and any(isinstance(x,ast.Name) and x.id=='tasks_processed' for x in ast.walk(n)))
 code=compile(ast.Module(body=[loop],type_ignores=[]),'actual-main-loop','exec')
 holder=Path(tempfile.mkdtemp(prefix='qa-loop-',dir='temp'));db=str(holder/'queue.db');c=sqlite3.connect(db);c.execute('create table jog_queue(id,global_id,gh_number,position,attempt_count,status)');c.executemany('insert into jog_queue values(?,?,?,?,?,?)',[(i,str(i),i,i,0,'pending') for i in (1,2,3)]);c.commit();c.close()
 leases=[];dispatches=[];states={};switches=[]
 good={'status':'projected-parked','committed_receipt':{'path':'receipt'},'published_head':'head','result_path':'result'}
 if case=='stale':states['1']={'executions':[good.copy()]}
 class Error(Exception):pass
 class Lock:
  def __init__(self,*a):pass
  def acquire(self):pass
  def release(self):pass
 def sqlstatus(n,status):
  c=sqlite3.connect(db);c.execute('update jog_queue set status=? where gh_number=?',(status,n));c.commit();c.close()
 def lease(root,n,pid):leases.append(n);sqlstatus(n,'running')
 def state(root,gid):return states.get(gid,{'executions':[]})
 def phase(root,n,gid,**kw):
  dispatches.append(n)
  if case=='stale':return 'parked','refused before new execution'
  record=good.copy()
  if case=='publication-failed':record['status']='receipt-publication-failed';record.pop('committed_receipt')
  states.setdefault(gid,{'executions':[]})['executions'].append(record)
  return ('completed','already landed') if case=='completed-bound' else ('parked','awaiting-landing')
 def git(root,*args):
  if args[0]=='status':return b' M file' if case=='dirty' and dispatches else b''
  if args[0]=='symbolic-ref':return b'lane' if dispatches else b'development'
  if args[0]=='switch':switches.append(args[1]);return b''
 env=dict(args=types.SimpleNamespace(max_tasks=2,builder='codex',reviewer='agy',auto_merge=False),tasks_processed=0,checkpoint=True,sqlite3=sqlite3,db_path=db,_ensure_jog_schema=lambda c:None,JogSupervisorLock=Lock,target='fake',root='fake',_git=git,ContractError=Error,os=os,sys=sys,jog_acquire_lease=lease,find_issue_doc=lambda *a:'/PROJECT/1-INBOX/doc' if case=='promotion-failed' else None,promote_contract_to_working=lambda *a,**kw:(None,'controlled refusal'),jog_set_status=lambda r,n,s,**kw:sqlstatus(n,s),executor='marathon',simulate=False,jog_resolve_ledger_gid=lambda r,n:str(n),jog_load_state=state,run_marathon_phase=phase,load_marathon_result=lambda p:{'outcome':'approved','pr':{} if case=='missing-pr' else {'number':1}},_ledger_abs_path=lambda *a:'result')
 error=None
 with contextlib.redirect_stdout(io.StringIO()):
  try:exec(code,env)
  except Error as e:error=str(e)
 return {'leases':leases,'dispatches':dispatches,'switches':switches,'error':error}
rows=[]
for case,expected in [('published',[1,2]),('completed-bound',[1,2]),('dirty',[1]),('promotion-failed',[]),('stale',[1]),('publication-failed',[1]),('missing-pr',[1])]:
 r=control(sources['fixed'],case);assert r['dispatches']==expected,(case,r);rows.append({'version':'fixed','case':case,**r,'pass':True})
for case in ['published','completed-bound','promotion-failed']:
 r=control(sources['prior'],case);rows.append({'version':'prior','case':case,**r})
Path('temp/qa-jog-loop-results.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows,indent=2))
