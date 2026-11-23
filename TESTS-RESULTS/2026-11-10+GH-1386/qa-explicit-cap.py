import ast,json,sys,subprocess
from pathlib import Path
from types import SimpleNamespace
sys.path.insert(0,'utils/py')
import swarm_preflight as sp
sources={f:Path('utils/py/'+f+'.py').read_text() for f in ('relay_drive','marathon_drive')}
t=ast.parse(sources['relay_drive']);main=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='main')
guards=[n for n in ast.walk(main) if isinstance(n,ast.If) and 'args.strict_role_handoff' in ast.unparse(n.test)]
extension=next(n for n in ast.walk(main) if isinstance(n,ast.If) and ast.unparse(n.test).startswith('round_idx == args.round_cap'))
review_guard=next(n for n in ast.walk(main) if isinstance(n,ast.If) and ast.unparse(n.test).startswith('args.review_once and'))
def run_node(node,e):exec(compile(ast.fix_missing_locations(ast.Module(body=[node],type_ignores=[])),'actual-source','exec'),e)
class Refusal(Exception):pass
def refuse(reason):raise Refusal(reason)
rows=[]
def loop(cap,actors,strict=True):
 e={'args':SimpleNamespace(strict_role_handoff=strict,builder='codex',reviewer='agy',round_cap=cap,review_once=False),'terminal_status':lambda x:False,'exit_escalate':refuse,'die':refuse,'hard_cap':cap*2,'round_idx':0,'made_progress':True,'eprint':lambda *a:None,'relay_file':'temp/qa-cap-relay.md'}
 seen=[]
 try:
  while e['round_idx']<e['args'].round_cap:
   i=e['round_idx'];e.update(actor=actors[i],nactor=actors[i+1],ns='working')
   run_node(guards[0],e);seen.append(e['actor']);e['round_idx']+=1
   run_node(guards[1],e);run_node(extension,e)
  error=None
 except Refusal as x:error=str(x)
 return seen,error
for name,cap,actors,expected,error in [('cap1-review',1,['codex','agy','codex'],['codex','agy'],None),('cap2-limit',2,['codex','agy','codex','agy','codex'],['codex','agy','codex','agy'],None),('repeat-builder',2,['codex','codex','agy'],['codex'],'explicit-cap-invalid-handoff'),('unknown-initial',2,['rogue','agy'],[],'explicit-cap-invalid-role'),('unknown-handoff',2,['codex','rogue'],['codex'],'explicit-cap-invalid-handoff')]:
 got,err=loop(cap,actors);assert (got,err)==(expected,error),(name,got,err);rows.append({'case':name,'turns':got,'error':err,'pass':True})
# Witness old/default behavior: the newly guarded malformed handoff is not refused.
got,err=loop(1,['codex','codex','agy'],False);assert got==['codex','codex'] and err is None;rows.append({'case':'prior/default repeated-builder red','turns':got,'desired_bound_violated':True})
# Execute the actual timeout recovery closure with controlled dependencies.
mt=ast.parse(sources['marathon_drive']);fn=next(n for n in ast.walk(mt) if isinstance(n,ast.FunctionDef) and n.name=='recover_timeout_exit')
for cap in (None,1,2):
 calls=[]
 e={'cli_round_cap':cap,'artifacts_exist':lambda:True,'file_status':lambda:'working','token_state':lambda:('open','agy'),'terminal_status':lambda s:False,'args':SimpleNamespace(builder='codex',phase_id='p'),'log':lambda *x:None,'relay_task':'t','_run_relay_drive':lambda **kw:calls.append(kw) or 5,'timeout_reason':[None],'timeout_emit':[None]}
 exec(compile(ast.fix_missing_locations(ast.Module(body=[fn],type_ignores=[])),'actual-timeout','exec'),e)
 for _ in range(2): assert e['recover_timeout_exit']()==5
 assert all(c['review_once']==(cap is not None) for c in calls)
 rows.append({'case':'timeout/repeated-recovery','explicit_cap':cap,'calls':calls,'pass':True})
for actor in ('codex','rogue','agy'):
 e={'args':SimpleNamespace(review_once=True,reviewer='agy'),'actor':actor,'role':'reviewer' if actor=='agy' else 'builder','die':refuse}
 try:run_node(review_guard,e);blocked=False
 except Refusal:blocked=True
 assert blocked==(actor!='agy');rows.append({'case':'review-once-identity','actor':actor,'blocked':blocked,'pass':True})
for cap in (None,1,2):
 out=sp.build_marathon_invocation_artifact('now','.','relay-automation/marathon-drive.sh','.', 'temp','x','gate','file',1,'development','codex','agy',round_cap=cap)
 assert ('--round-cap' in out['argv'])==(cap is not None)
 if cap:assert out['argv'][out['argv'].index('--round-cap')+1]==str(cap)
 rows.append({'case':'producer-cap-forwarding','cap':cap,'pass':True})
Path('temp/qa-explicit-cap-results.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows))
# Actual review-once refusal branch must return without another turn.
review_exit=next(n for n in ast.walk(main) if isinstance(n,ast.If) and ast.unparse(n.test)=='args.review_once' and 'review_blocks_added' in ast.unparse(n))
e={'args':SimpleNamespace(review_once=True),'ns':'working','s':'working','terminal_status':lambda x:False,'nrfsig':'new','rfsig':'old','nnextp':'codex','nextp':'agy','relay_file':'temp/qa-cap-relay.md','rf_text_before':'','review_blocks_added':lambda *a:1,'xyz_relay_emit':lambda *a:None,'sys':sys,'eprint':lambda *a:None}
try:run_node(review_exit,e);raise AssertionError('review refusal did not exit')
except SystemExit as x:assert x.code==5
rows.append({'case':'review-once-rejection','exit':5,'pass':True})
# Extractor rejects invalid explicit caps, rather than passing nonsense to Marathon.
for cap in (0,-1,True,'2'):
 doc=Path('temp/qa-cap-contract.md');c={'target':{'repo':'.','ref':'development'},'gate':'gate','fix_probes':[{'type':'path_absent','path':'x'}],'artifacts':['x'],'round_cap':cap};doc.write_text('## Preflight Contract\n```json\n'+json.dumps(c)+'\n```\n')
 try:sp.extract_contract(str(doc));raise AssertionError('invalid cap accepted')
 except SystemExit as x:assert x.code==3
 rows.append({'case':'invalid-cap','cap':cap,'rejected':True})
Path('temp/qa-explicit-cap-results.json').write_text(json.dumps(rows,indent=2)+'\n')
