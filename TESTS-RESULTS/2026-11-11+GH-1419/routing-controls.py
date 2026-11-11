"""Manual GH1419 controls; run only in a disposable full clone. No provider calls."""
import ast
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

root = Path.cwd()
sys.path.insert(0, str(root / 'utils/py'))
import marathon_drive as md
import jog_run as jog
import profile_resolve
rows = []
def check(name, value, detail=None):
    rows.append(dict(name=name, passed=bool(value), detail=detail))
    if not value:
        raise AssertionError(name)

lanes = profile_resolve.lanes(str(root))
check('nonempty nine routes', len(lanes) == 9, sorted(lanes))
for lane, info in lanes.items():
    env = {}
    md.route_agent(lane+'-builder', env)
    md.route_agent(lane+'-reviewer', env)
    check(lane+' pair retained', env[info['agent_var']] == lane+'-builder,'+lane+'-reviewer')
for actor in ['gemini', 'unknown', 'claude,other', 'claude x', '']:
    try: md.route_agent(actor, {}); rejected=False
    except ValueError: rejected=True
    check('refuse '+repr(actor), rejected)
with patch.dict(os.environ, {'CLAUDE_BIN':'/usr/bin/true', 'CODEX_BIN':'/usr/bin/true', 'AGY_BIN':'/usr/bin/true'}):
    for builder, reviewer in [('claude-build','claude-review'), ('codex','agy'), ('codex','claude')]:
        error=jog.validate_marathon_executor(SimpleNamespace(builder=builder,reviewer=reviewer))
        check('Jog '+builder+'/'+reviewer, error is None, error)
    check('same actor refused', bool(jog.validate_marathon_executor(SimpleNamespace(builder='claude',reviewer='claude'))))
    with patch.dict(os.environ, {'CLAUDE_BIN':'/nonexistent/gh1419'}):
        check('missing binary refused', bool(jog.validate_marathon_executor(SimpleNamespace(builder='codex',reviewer='claude'))))

# Run the real dispatcher with controlled shims that record the exact child environment.
# Then feed that environment into each real Python shim main; stop at its first RTL
# object construction, AFTER the identity and (Claude) binary checks. No model executes.
with tempfile.TemporaryDirectory(prefix='gh1419-dispatch-') as d:
    d=Path(d)
    (d/'marathon-agent.sh').write_bytes((root/'relay-automation/marathon-agent.sh').read_bytes())
    for lane,info in lanes.items():
        shim=d/(lane+'-turn.sh')
        shim.write_text('#!/usr/bin/env python3\nimport os,json\nprint(json.dumps(dict(os.environ)))\n')
        shim.chmod(0o755)
        for role,peer in [('builder','reviewer'),('reviewer','builder')]:
            actor=lane+'-'+role
            env={**os.environ,info['agent_var']:lane+'-builder,'+lane+'-reviewer', 'RELAY_AGENT':actor,'RELAY_FILE':str(d/'relay.md'),'MARATHON_BUILDER':lane+'-builder','MARATHON_REVIEWER':lane+'-reviewer'}
            for other in lanes.values():
                if other['agent_var'] != info['agent_var']: env.pop(other['agent_var'],None)
            r=subprocess.run(['bash',str(d/'marathon-agent.sh')],env=env,text=True,capture_output=True)
            child=json.loads(r.stdout) if r.returncode==0 else {}
            check('dispatch '+actor, child.get(info['agent_var'])==actor and child.get('RELAY_PEER')==lane+'-'+peer,r.stderr)
            if lane in ('claude','codex'):
                spec=importlib.util.spec_from_file_location('manual_'+lane,root/'utils/py'/f'{lane}-turn.py')
                module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
                class ReachedIdentity(Exception): pass
                def stop(*a,**kw): raise ReachedIdentity()
                child['CLAUDE_BIN']='/usr/bin/true'
                with patch.dict(os.environ,child,clear=True),patch.object(module,'RelayTurnLib',stop),patch.object(sys,'argv',['manual']):
                    try: module.main(); reached=False
                    except ReachedIdentity: reached=True
                    except SystemExit: reached=False
                check('actual shim identity '+actor,reached)
    r=subprocess.run(['bash',str(d/'marathon-agent.sh')],env={**os.environ,'RELAY_AGENT':'claude-unlisted','RELAY_FILE':'unused','CLAUDE_AGENT':'claude-builder,claude-reviewer'},capture_output=True,text=True)
    check('unlisted actor refused',r.returncode==2 and 'unknown agent' in r.stderr)

# Execute the existing recovery function with controlled state and real reviewer dispatch
# already established above; its nested dependencies are observations, not new machinery.
tree=ast.parse((root/'utils/py/marathon_drive.py').read_text())
node=next(n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='recover_timeout_exit')
for actor,expected,calls in [('claude-reviewer','timeout-during-review-recovery',1),('claude-builder','timeout-builder-still-owned-turn',0)]:
    seen=[]; reason=['']; emit=['']
    def recovery(**kw): seen.append(kw); return 7
    ns=dict(args=SimpleNamespace(builder='claude-builder',reviewer='claude-reviewer',phase_id='manual'),artifacts_exist=lambda:True,file_status=lambda:'Open',token_state=lambda:('open',actor),terminal_status=lambda x:False,timeout_reason=reason,timeout_emit=emit,log=lambda *x:None,relay_task='manual',_run_relay_drive=recovery,cli_round_cap=2)
    exec(compile(ast.Module(body=[node],type_ignores=[]),'<actual recovery>','exec'),ns)
    rc=ns['recover_timeout_exit']()
    check('timeout '+actor,rc==7 and reason[0]==expected and len(seen)==calls and (not seen or seen==[{'review_once':True}]),dict(reason=reason,calls=seen))

# Baseline source reproduces the actual pre-fix rejection and scalar overwrite.
base=subprocess.check_output(['git','show','07e36a89:utils/py/jog_run.py'],text=True)
node=next(n for n in ast.walk(ast.parse(base)) if isinstance(n,ast.FunctionDef) and n.name=='validate_marathon_executor')
ns=dict(_MARATHON_REVIEWER_PREFIXES=('codex','gemini','agy'),os=os)
exec(compile(ast.Module(body=[node],type_ignores=[]),'<baseline>','exec'),ns)
error=ns['validate_marathon_executor'](SimpleNamespace(builder='codex',reviewer='claude'))
check('baseline Claude refusal witnessed',bool(error),error)
base=subprocess.check_output(['git','show','07e36a89:utils/py/marathon_drive.py'],text=True)
node=next(n for n in ast.walk(ast.parse(base)) if isinstance(n,ast.FunctionDef) and n.name=='route_agent')
ns=dict(os=os,die=lambda x:None)
exec(compile(ast.Module(body=[node],type_ignores=[]),'<baseline>','exec'),ns)
with patch.dict(os.environ,{'CLAUDE_AGENT':''}):
    ns['route_agent']('claude-builder');ns['route_agent']('claude-reviewer')
    check('baseline overwrite witnessed',os.environ['CLAUDE_AGENT']=='claude-reviewer')
print(json.dumps(rows,indent=2))
