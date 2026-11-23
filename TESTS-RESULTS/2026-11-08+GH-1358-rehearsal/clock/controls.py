import ast,json,sys,types
from pathlib import Path
source=Path(sys.argv[1]).read_text()
node=next(n for n in ast.walk(ast.parse(source)) if isinstance(n,ast.FunctionDef) and n.name=='run_pre_advance_gate')
code=compile(ast.fix_missing_locations(ast.Module(body=[node],type_ignores=[])),str(sys.argv[1]),'exec')
def case(name,wall_step=0,mono_step=0,exit_after=1,exit_code=0,cap=10,group_missing=False):
    clock=types.SimpleNamespace(mono=100.,wall=1000.,ticks=0)
    def sleep(_):clock.mono+=mono_step;clock.wall+=wall_step;clock.ticks+=1
    polls=[0];kills=[];logs=[]
    def poll():
        polls[0]+=1
        if group_missing and polls[0]==2:
            clock.wall+=20;return 0
        return exit_code if clock.ticks>=exit_after else None
    proc=types.SimpleNamespace(pid=12345,poll=poll)
    def kill(p,why):
        assert p.poll() is None,'must not signal an exited process'
        kills.append(why)
    env={'args':types.SimpleNamespace(target_root=None,pre_advance_baseline=None),
         '_gate_env':lambda:{},'os':types.SimpleNamespace(environ={}),
         '_gate_guard_config':lambda:{'cpu_s':0,'wall_s':cap,'rss_mb':0,'poll_s':1,'tier':'manual'},
         'pre_advance_cmd':'controlled process; no external execution',
         'subprocess':types.SimpleNamespace(Popen=lambda *a,**kw:proc),
         'time':types.SimpleNamespace(monotonic=lambda:clock.mono,time=lambda:clock.wall,sleep=sleep),
         '_gate_group_rss_mb':lambda _: (None,'group-missing') if group_missing else (1,'ok'),
         '_gate_kill_group':kill,'GATE_GUARD_KILL_EXIT':108,'GATE_RSS_UNAVAILABLE_WARNING':'unavailable',
         'gate_guard_cpu_attribution':lambda rc,cpu:(rc,None), '_gate_rss_summary':lambda *args:'controlled RSS',
         'run_gate_result':[None],'_RESULT':{},'log':logs.append}
    exec(code,env)
    result=env['run_pre_advance_gate']()
    return {'case':name,'exit':result,'kills':kills,'log':logs,'result':env['_RESULT']}
cases=[case('normal-success',1,1),case('genuine-red',1,1,exit_code=7),
       case('sleep-running',20,1,exit_after=2),case('sleep-child-already-exited',20,1),
       case('backward-wall-monotonic-expiry',-20,11),case('cap-disabled',20,1,cap=0),
       case('group-missing-late-completion',group_missing=True)]
expected=[0,7,108,108,108,0,108]
for c,want in zip(cases,expected):c['expected']=want;c['pass']=c['exit']==want
print(json.dumps(cases,indent=2))
if '--expect-old-red' in sys.argv:
 assert not cases[2]['pass'] and not cases[3]['pass'] and not cases[6]['pass']
else:assert all(c['pass'] for c in cases)
