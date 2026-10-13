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
    cwd = pathlib.Path(cwd).resolve()
    assert cwd.is_dir() and cwd.is_relative_to(OUT) and cwd != OUT, cwd
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
    command=['python3',H/'utils/py/marathon_drive.py']
    if env.get('FAIL_COMPLETION_WRITE'):
        code="import sys,runpy;sys.path.insert(0,sys.argv[1]+'/utils/py');import relay_attest;relay_attest.write=lambda rec:(_ for _ in ()).throw(OSError('manual completion write failure'));runpy.run_path(sys.argv.pop(1)+'/utils/py/marathon_drive.py',run_name='__main__')"
        command=['python3','-c',code,str(H)]
    return run([*command,'--phase-id','p1','--phases-dir',root/'phases','--phase-brief',brief,'--builder','claude','--reviewer','agy','--pre-advance-cmd',gate,'--result-file',root/'result.json','--execution-id','manual-recovery',*extra],root,env,False)

def record(name,p,root,expected):
    text=p.stdout+p.stderr
    (OUT/(name+'.log')).write_text(text)
    ok=p.returncode==expected
    rows.append(dict(name=name,rc=p.returncode,expected=expected,ok=ok,dispatched=(root/'dispatched').exists(),result=json.loads((root/'result.json').read_text()) if (root/'result.json').exists() else None))
    if not ok: raise AssertionError((name,p.returncode,expected,text[-3500:]))

root,env,brief=fixture('force')
p=drive(root,env,brief,['--force'])
# Baseline dispatches the intentionally failing stub (exit7), proving re-dispatch.
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
if FIXED:
    sys.path.insert(0,str(H/'utils/py'))
    import relay_attest
    def recpath(root): return pathlib.Path(relay_attest.path_for('MARATHON-P1-TURN',str(root)))
    def mutate(root,label='later operator change'):
        (root/'src.txt').write_text(label+'\n');run(['git','add','src.txt'],root);run(['git','commit','-qm',label],root)
    root,env,brief=fixture('numeric','MARATHON-P1-TURN-2')
    p=drive(root,env,brief,['--force']);record('numeric-force-recovery',p,root,0)
    assert not (root/'dispatched').exists()
    root,env,brief=fixture('red-gate')
    p=drive(root,env,brief,gate='false');record('red-gate-no-completion',p,root,5)
    assert 'phase_completion' not in json.loads(recpath(root).read_text())
    p=drive(root,env,brief,['--force']);record('red-gate-force-recovery',p,root,0)
    assert not (root/'dispatched').exists()
    root,env,brief=fixture('legacy-later')
    mutate(root)
    p=drive(root,env,brief);record('legacy-later-refuses',p,root,4)
    p=drive(root,env,brief,['--force']);record('legacy-force-rebuild',p,root,7)
    assert (root/'dispatched').exists()
    for name,value in [('null',None),('wrong-phase',dict(phase='other')),('wrong-lane',dict(lane='other')),('wrong-review',dict(added_sha256='0'*64)),('bad-sha',dict(candidate=''))]:
        root,env,brief=fixture('malformed-'+name)
        p=drive(root,env,brief);record('seed-'+name,p,root,0)
        rec=json.loads(recpath(root).read_text())
        if isinstance(value,dict):rec['phase_completion'].update(value)
        else:rec['phase_completion']=value
        recpath(root).write_text(json.dumps(rec))
        p=drive(root,env,brief);record('refuse-'+name,p,root,4)
    for name in ['missing','empty']:
        root,env,brief=fixture(name+'-attest')
        if name=='missing':recpath(root).unlink()
        else:recpath(root).write_text('')
        p=drive(root,env,brief);record(name+'-attestation-refuses',p,root,4)
    root,env,brief=fixture('unrelated','OTHER-PHASE-TURN')
    p=drive(root,env,brief);record('unrelated-token-rebuild',p,root,7)
    assert (root/'dispatched').exists()
    root,env,brief=fixture('divergent')
    p=drive(root,env,brief);record('seed-divergent',p,root,0)
    run(['git','symbolic-ref','HEAD','refs/heads/divergent-root'],root)
    run(['git','commit','--allow-empty','-qm','unrelated root'],root)
    p=drive(root,env,brief);record('divergent-head-refuses',p,root,4)
    root,env,brief=fixture('post-mutation')
    change="printf unreviewed > src.txt; git add src.txt; git commit -qm post-mutation"
    p=drive(root,env,brief,['--post-approve-cmd',change]);record('post-approve-mutation-refuses',p,root,4)
    assert 'phase_completion' not in json.loads(recpath(root).read_text())
    root,env,brief=fixture('recovery-gate-mutation')
    p=drive(root,env,brief);record('seed-gate-mutation',p,root,0)
    pinned=json.loads(recpath(root).read_text())['phase_completion']
    mutate(root)
    p=drive(root,env,brief,gate=change);record('recovery-gate-mutation-refuses',p,root,4)
    assert json.loads(recpath(root).read_text())['phase_completion']==pinned
    root,env,brief=fixture('historical-effects')
    p=drive(root,env,brief,['--post-approve-cmd','printf called >> effects']);record('seed-effects',p,root,0)
    mutate(root)
    p=drive(root,env,brief,['--post-approve-cmd','printf repeated >> effects','--requires-test','absent-test']);record('historical-effects-not-repeated',p,root,0)
    assert (root/'effects').read_text()=='called'
    rec=json.loads(recpath(root).read_text());head=run(['git','rev-parse','HEAD'],root).stdout.strip()
    assert relay_attest.candidate_ok(rec,head,str(root))[0] is False
    assert json.loads((root/'result.json').read_text())['gate']['receipt_path'] is None
    root,env,brief=fixture('write-failure')
    env['FAIL_COMPLETION_WRITE']='1'
    p=drive(root,env,brief);record('completion-write-failure-refuses',p,root,4)
    assert 'phase_completion' not in json.loads(recpath(root).read_text())
    assert 'phase-completion-write-failed' in p.stdout
    # Full shell traversal: prior completed p1 must pass before explicit retry of p2 dispatches.
    root,env,brief=fixture('two-phase')
    p=drive(root,env,brief);record('seed-two-phase',p,root,0);mutate(root)
    plan=root/'PROJECT/2-WORKING/recovery/MARATHON.yaml';plan.parent.mkdir(parents=True)
    plan.write_text('phases:\n  - id: p1\n    reviewer: agy\n    brief: brief.md\n  - id: p2\n    reviewer: agy\n    depends_on: p1\n    brief: brief.md\n')
    env.update(MARATHON_HOME=str(H))
    p=run(['bash',H/'relay-automation/marathon.sh','--plan',plan,'--phases-dir',root/'phases','--retry','p2','--builder','claude','--pre-advance-cmd','true'],root,env,False)
    record('two-phase-later-retry',p,root,7)
    assert 'phase p1 complete' in p.stdout and 'MARATHON-P2-TURN-2' in p.stdout

(OUT/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
