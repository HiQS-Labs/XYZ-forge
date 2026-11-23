# Manual verification commands

Executed only in a disposable full clone, Python 3.13 venv. No provider calls.
The following one-off probe was executed from temp/, not registered as a suite.

```python
import sys,json,os
from pathlib import Path
from types import SimpleNamespace
from dataclasses import replace
sys.path.insert(0,str(Path.cwd()/'utils/py')); import harness as h
root=h.DEFAULT_RUN_ROOT/'gh1254-green-v2'; root.mkdir(parents=True,exist_ok=True)
results=[]
def item(n,slot=1,urgent=False):
 return dict(type='inbox',id=n,available_at_slot=slot,created_at='2026-11-08T00:00:00+00:00',kind='note-request',body='hello '+n,urgent=urgent)
def init(name,items,limit=2,adapter='rules'):
 d=root/name;d.mkdir();s=d/'scenario.jsonl';s.write_text(''.join(json.dumps(i)+'\n' for i in items));m=d/'manifest.json';h.generate_manifest(s,m);i=d/'instances'/'C';h.init_instance(i,s,m,10,.01,{'adapter':adapter,'cache_ttl_s':300,'max_cold_deferral_slots':limit});return i
def rows(i,table):
 c=h.connect(i/'state.db');r=[dict(x) for x in c.execute('select * from '+table)];c.close();return r
def rec(i):return json.loads(rows(i,'receipts')[-1]['json'])
def check(name,value,detail):
 assert value,(name,detail)
 results.append(dict(check=name,result='PASS',detail=detail))
i=init('cold',[item('a')]);h.run_tick(i,1);r=rec(i);check('cold deferred',rows(i,'inbox_items')[0]['status']=='pending' and r['cache']['deferred']=={'a':3},r)
n=len(rows(i,'events'));h.run_tick(i,1);check('rerun no event or call',len(rows(i,'events'))==n,{'events':n})
h.run_tick(i,2);check('skipped call does not warm',rec(i)['cache']['last_call_at'] is None,rec(i)['cache']);h.run_tick(i,3);check('feasible deadline executes',rows(i,'inbox_items')[0]['status']=='consumed' and rec(i)['tool']=='note',rec(i))
i=init('urgent',[item('u',urgent=True)]);h.run_tick(i,1);check('urgent no cache delay',rows(i,'inbox_items')[0]['status']=='consumed',rec(i));t=json.loads((i/'telemetry/transcripts/slot_001.json').read_text());check('missing tokens null',t['cache_read_tokens'] is None and t['cache_creation_tokens'] is None,t)
for value in ['', '0','false','no','off','1','true']:
 os.environ['FACTORY_SUPERVISED']=value;i=init('supervision-'+(value or 'absent'),[item('a')],0);h.run_tick(i,1);r=rec(i)['supervision'];check('declaration '+repr(value),r['declared']==(value in ['1','true']) and r['restart_performed'] is False,r)
os.environ.pop('FACTORY_SUPERVISED',None)
i=init('contention',[item('a'),item('b')]);h.run_tick(i,1);h.run_tick(i,3);r=rec(i);check('oversubscribed deadline visible',r['cache']['deadline_unexecuted_ids']==['b'] and rows(i,'inbox_items')[1]['status']=='pending',r);h.run_tick(i,4);check('contention work not dropped',all(x['status']=='consumed' for x in rows(i,'inbox_items')),rec(i))
# Account parsing through the real adapter, with bounded process runner replaced by reported CLI output.
original=h.run_bounded
for label,usage,rc in [('known',{'cached_input_tokens':40,'cache_creation_input_tokens':60},0),('absent',{},0),('failed',{'cached_input_tokens':7},1),('invalid',{'cached_input_tokens':True,'cache_creation_input_tokens':-1},0)]:
 def fake(argv,**kw):
  Path(argv[argv.index('-o')+1]).write_text(json.dumps(h._safe_idle('fixture')))
  return SimpleNamespace(stdout=json.dumps({'type':'turn.completed','usage':usage}),stderr='',rc=rc,timed_out=False)
 h.run_bounded=fake
 r=h.codex_decide({'inbox':[item('a')],'probe_targets':[]},{'codex_model':'fixture','codex_effort':'medium','adapter_timeout_s':1})
 expected={'known':(40,60),'absent':(None,None),'failed':(7,None),'invalid':(None,None)}[label]
 check('usage '+label,(r.cache_read_tokens,r.cache_creation_tokens)==expected and r.actual_cost is None,vars(r))
h.run_bounded=original
# Paired same-scenario modeled calls. No provider calls/spend; a deterministic adapter supplies $0.01/call.
original_adapter=h._adapter
h._adapter=lambda snap,fault,cfg: replace(h.rules_decide(snap),called=bool(snap['inbox']),actual_cost=.01 if snap['inbox'] else 0,cache_read_tokens=0 if snap['inbox'] else None,cache_creation_tokens=100 if snap['inbox'] else None)
scenario=[item('a',1),item('b',2),item('u',2,True)]
comparison={}
for name,limit in [('without',0),('with',2)]:
 i=init('paired-'+name,scenario,limit,'codex')
 for slot in range(1,6):h.run_tick(i,slot)
 ev=[json.loads(r['json']) for r in rows(i,'events')];calls=sum(e.get('agent_called',False) for e in ev)
 comparison[name]={'scenario_sha256':h._config(i)['scenario_sha256'],'calls':calls,'modeled_cost':sum(r['actual_cost'] or 0 for r in rows(i,'reservations')),'consumed':sum(r['status']=='consumed' for r in rows(i,'inbox_items'))}
 if name=='with':
  snaps=[json.loads(r['json']) for r in rows(i,'snapshots')];check('reported call warms following slot',snaps[2]['cache']['cold'] is False,snaps[2]['cache'])
h._adapter=original_adapter
check('same-scenario modeled comparison',comparison['with']['scenario_sha256']==comparison['without']['scenario_sha256'] and comparison['with']['consumed']==comparison['without']['consumed']==3,comparison)
Path('temp/gh1254/green.json').write_text(json.dumps({'checks':results,'comparison':comparison,'limitations':['modeled cost only; no live savings claim','restart not exercised','oversubscribed deadline remains open']},indent=2)+'\n')
print(json.dumps({'passed':len(results),'comparison':comparison}))

```

CLI smoke: factory-primitive init --cache-ttl 300 --max-cold-deferral-slots 2; tick --slot 1 twice. Both returned completed; one receipt persisted.
