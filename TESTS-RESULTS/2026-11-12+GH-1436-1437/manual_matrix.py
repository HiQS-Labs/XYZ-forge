import copy, json, os, subprocess, sys, tempfile
from pathlib import Path
root=Path.cwd();sys.path.insert(0,str(root/'utils/py'))
from swarm_preflight import contract_shape_error, extract_contract
from _marathon_plan import _unregistered_record
from wave_reconcile import handle_marathon_plan_result, ReconcileError
base={'target':{'repo':'.','ref':'main'},'gate':'true','fix_probes':[{'type':'path_absent','path':'missing'}],'artifacts':['missing']}
cases=[('outer-list',[]),('outer-null',None),('outer-string','bad')]
for field,values in [('target',['bad',[],None,{'ref':[]}]),('fix_probes',['bad',None,['bad'],[{'path':[]}],[{'pattern':[]}]]),('artifacts',['bad',None,[42]]),('lanes',['bad',{'orchestrator_only':[1]}])]:
 for i,value in enumerate(values): c=copy.deepcopy(base);c[field]=value;cases.append((field+str(i),c))
with tempfile.TemporaryDirectory(prefix='gh1436-matrix-') as d:
 p=Path(d);(p/'PROJECT/2-WORKING').mkdir(parents=True)
 (p/'utils').mkdir();(p/'utils/marathon-plan-zones.default.json').write_bytes((root/'utils/marathon-plan-zones.default.json').read_bytes())
 doc=p/'PROJECT/2-WORKING/GH-9001-PROBE.md'
 (p/'ROADMAP.md').write_text('## Ledger\n### Queue / parked intake\n- **GH-9001 · probe** 🆕 → [d](PROJECT/2-WORKING/GH-9001-PROBE.md) · [#9001](https://github.com/o/r/issues/9001)\n')
 (p/'states.json').write_text('{"9001":"OPEN"}');(p/'branches').write_text('')
 env=dict(os.environ,QUEUE_PLAN_ROOT=d,QUEUE_PLAN_ROADMAP=str(p/'ROADMAP.md'),QUEUE_PLAN_GH_STATE_FILE=str(p/'states.json'),QUEUE_PLAN_BRANCHES_FILE=str(p/'branches'))
 def body(c):return '---\ntitle: probe\ncomplexity: 1\nrisk: 1\neffort: 1\n---\n## Preflight Contract\n```json\n'+json.dumps(c)+'\n```\n\n## PRS proposal\n- pri 50: fixture\n- sev 50: fixture\n- appeal 50: fixture\n- effort 50: fixture\n'
 for name,c in cases:
  assert contract_shape_error(c),name;doc.write_text(body(c))
  r=subprocess.run([sys.executable,str(root/'utils/py/marathon_plan.py'),'--format','json'],env=env,text=True,capture_output=True)
  assert r.returncode==5,(name,r.returncode,r.stdout,r.stderr)
  assert 'malformed-contract' in r.stdout and 'needs-contract' in r.stdout,(name,r.stdout)
  handle_marathon_plan_result(r,{9002})
  try:handle_marathon_plan_result(r,{9001})
  except ReconcileError as e:assert e.code==6
  else:raise AssertionError('owned malformed contract accepted')
  rec=_unregistered_record(9001,'probe',body(c),doc_rel='PROJECT/2-WORKING/GH-9001-PROBE.md',root=p)
  assert rec['state']=='needs-contract' and rec['contractError'] and not rec['writeset'],(name,rec)
  print('PASS',name,'planner held; unregistered held; unrelated reconcile continues; owned reconcile refuses')
 for name,c in [('healthy',base),('optional-null',dict(base,lanes=None,artifacts_new=None)),('partial',{'artifacts':['README.md']})]:
  assert contract_shape_error(c) is None;doc.write_text(body(c))
  r=subprocess.run([sys.executable,str(root/'utils/py/marathon_plan.py'),'--format','json'],env=env,text=True,capture_output=True)
  assert r.returncode==0,(name,r.returncode,r.stdout,r.stderr)
  if name=='partial':
   try:extract_contract(str(doc))
   except SystemExit as e:assert e.code==3
   else:raise AssertionError('partial execution accepted')
  else:assert extract_contract(str(doc))==c
  print('PASS',name,'planner preserved; execution completeness independently checked')
print('PASS all',len(cases)+3,'contract cases')
