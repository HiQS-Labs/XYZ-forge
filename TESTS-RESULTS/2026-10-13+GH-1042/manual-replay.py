"""Recorded manual GH1042/1045 recovery checks; not a registered suite.
Run in a disposable full clone: python3 <this file> [--expect-fixed].
"""
import json, os, pathlib, subprocess, sys, tempfile
H = pathlib.Path.cwd().resolve()
FIXED = '--expect-fixed' in sys.argv
OUT = H / 'temp/recovery-manual'
OUT.mkdir(parents=True, exist_ok=True)
rows = []
def run(cmd, cwd, env=None, check=True):
    p = subprocess.run([str(x) for x in cmd], cwd=cwd, env=env, text=True, capture_output=True)
    if check and p.returncode: raise RuntimeError((cmd,p.returncode,p.stdout,p.stderr))
    return p

def fixture(name, task='MARATHON-P1-TURN'):
    root = pathlib.Path(tempfile.mkdtemp(prefix=name+'-', dir=OUT))
    run(['git','init','-q'],root)
    run(['git','config','user.email','manual@example.invalid'],root)
    run(['git','config','user.name','manual recovery'],root)
    (root/'.gitignore').write_text('.tick/\n.xyz/\n')
    (root/'src.txt').write_text('approved\n')
    (root/'phases/p1').mkdir(parents=True)
    relay=root/'phases/p1/RELAY.md'
    relay.write_text(f'# Phase p1\nSTATUS: Approved\nNEXT: agy\n\n<!-- marathon-drive: task={task} builder=claude reviewer=agy round-cap=2 -->\n\nbody\n')
    run(['git','add','.'],root);run(['git','commit','-qm','reviewed input'],root)
    env=dict(os.environ, MARATHON_ROOT=str(root), XYZ_ROOT=str(H), XYZ_HARNESS=str(H), TICK_REPO_ROOT=str(root), TICK_BIN=str(H/'bin/tick'), XYZ_HARNESS_LOGGING='0', XYZ_DEVICE_CONFIG_PATH='/dev/null', XYZ_ARCHIVE_ROOT=str(root))
    run([H/'bin/tick','init'],root,env)
    run([H/'bin/tick','log','task.created',task,'--agent','marathon'],root,env)
    run(['bash',H/'test/lib/attest-stub.sh','--relay-file',relay,'--relay-task',task,'--reviewer','agy','--target-root',root],root,env)
    run(['git','add','phases'],root);run(['git','commit','-qm','approved transcript'],root)
    brief=root/'brief.md';brief.write_text('## brief\nbody\n')
    stub=root/'stub';stub.write_text('#!/bin/sh\nprintf dispatched >> "'+str(root/'dispatched')+'"\nexit 7\n');stub.chmod(0o755)
    env.update(MARATHON_RELAY_DRIVE=str(stub),CLAUDE_BIN=str(stub),AGY_BIN=str(stub))
    return root,env,brief

def drive(root,env,brief,extra=(),gate='true'):
    return run(['python3',H/'utils/py/marathon_drive.py','--phase-id','p1','--phases-dir',root/'phases','--phase-brief',brief,'--builder','claude','--reviewer','agy','--pre-advance-cmd',gate,'--result-file',root/'result.json','--execution-id','manual-recovery',*extra],root,env,False)

def record(name,p,root,expected):
    text=p.stdout+p.stderr
    (OUT/(name+'.log')).write_text(text)
    ok=p.returncode==expected
    rows.append(dict(name=name,rc=p.returncode,expected=expected,ok=ok,dispatched=(root/'dispatched').exists(),result=json.loads((root/'result.json').read_text()) if (root/'result.json').exists() else None))
    if not ok: raise AssertionError((name,p.returncode,expected,text[-3500:]))

root,env,brief=fixture('force')
p=drive(root,env,brief,['--force'])
# Baseline dispatches stub and fails; exact baseline exit is 4 escalation.
record('force-gate-only',p,root,0 if FIXED else 7)
assert (root/'dispatched').exists() is (not FIXED)
root,env,brief=fixture('history')
p=drive(root,env,brief);record('initial-completion',p,root,0)
initial=json.loads((root/'result.json').read_text())
(root/'src.txt').write_text('later phase shared-file change\n');run(['git','add','src.txt'],root);run(['git','commit','-qm','later phase change'],root)
p=drive(root,env,brief);record('historical-recovery',p,root,0 if FIXED else 4)
assert not (root/'dispatched').exists()
if FIXED:
    assert rows[-1]['result']['reviewed_candidate']==initial['reviewed_candidate']
    assert rows[-1]['result']['head_sha']!=initial['reviewed_candidate']
root,env,brief=fixture('force-family','MARATHON-P1-TURN-R2')
p=drive(root,env,brief);record('force-token-family',p,root,0 if FIXED else 7)
root,env,brief=fixture('drift')
(root/'src.txt').write_text('unreviewed before completion\n');run(['git','add','src.txt'],root);run(['git','commit','-qm','unreviewed edit'],root)
p=drive(root,env,brief);record('unreviewed-refusal',p,root,4)
root,env,brief=fixture('explicit')
p=drive(root,env,brief,['--relay-task','MARATHON-P1-TURN-2']);record('explicit-rebuild',p,root,7)
assert (root/'dispatched').exists()
(OUT/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
