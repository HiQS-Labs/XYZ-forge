#!/usr/bin/env python3
import datetime, json, os, pathlib, subprocess, sys, hashlib
VERIFY=pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/verify')
TASK=pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/task')
OUT=pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-environment/discovery/afterfix')
LOG=OUT/'logs'; LOG.mkdir(parents=True,exist_ok=True)

def run(argv,cwd=None,env=None):
    p=subprocess.run(argv,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=210)
    return p.returncode,p.stdout

def identity(repo):
    def g(*args):
        return run(['git','-C',str(repo),*args])[1].strip()
    cfg=repo/'.git'/'config'
    return {'path':str(repo),'head':g('rev-parse','HEAD'),'branch':g('branch','--show-current'),
            'status':g('status','--porcelain'),'core_bare':g('config','--local','--get','core.bare'),
            'remotes':g('remote','-v'),'user_email':g('config','--local','--get','user.email'),
            'worktrees':g('worktree','list','--porcelain'),'config_sha256':hashlib.sha256(cfg.read_bytes()).hexdigest() if cfg.exists() else None}

def utc(): return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
base_env=os.environ.copy()
for k in list(base_env):
    if any(x in k.upper() for x in ('TOKEN','SECRET','PASSWORD','CREDENTIAL','API_KEY','AUTH')): base_env.pop(k,None)
base_env.update({'XYZ_HARNESS':str(TASK),'XYZ_REPO_ROOT':str(TASK), 'HOME':str(OUT/'home'), 'XDG_CONFIG_HOME':str(OUT/'xdg'), 'PYTHONDONTWRITEBYTECODE':'1'})
pathlib.Path(base_env['HOME']).mkdir(exist_ok=True); pathlib.Path(base_env['XDG_CONFIG_HOME']).mkdir(exist_ok=True)
initial={'verify':identity(VERIFY),'task':identity(TASK)}
(OUT/'identity-before.json').write_text(json.dumps(initial,indent=2)+'\n')
records=[]
for suite in ['test/find-harness.sh','test/gh396-find-harness-roots.sh']:
    label='afterfix-'+pathlib.Path(suite).stem
    shell=f'''source test/lib/runner-envelope.sh
runner_envelope_begin "$PWD" "{label}" || exit 80
[ "${{XYZ_HARNESS+x}}" != x ] || {{ echo "ASSERT_FAIL XYZ_HARNESS not scrubbed"; exit 81; }}
[ "${{XYZ_REPO_ROOT+x}}" != x ] || {{ echo "ASSERT_FAIL XYZ_REPO_ROOT not scrubbed"; exit 82; }}
[ -n "${{XYZ_HARNESS_DB:-}}" ] && [ -f "$XYZ_HARNESS_DB" ] || {{ echo "ASSERT_FAIL XYZ_HARNESS_DB missing"; exit 83; }}
case "$XYZ_HARNESS_DB" in "${{TMPDIR:-/tmp}}"/runner-envelope.*/harnesses.db) echo "ASSERT_PASS selector overrides unset; XYZ_HARNESS_DB preserved in envelope scratch: $XYZ_HARNESS_DB";; *) echo "ASSERT_FAIL unexpected XYZ_HARNESS_DB=$XYZ_HARNESS_DB"; exit 84;; esac
bash "{suite}"
suite_rc=$?
runner_envelope_assert "$PWD" "{label}"
assert_rc=$?
pre_scrub_scratch=${{RUNNER_ENVELOPE_SCRATCH:-}}
pre_scrub_state=${{RUNNER_ENVELOPE_STATE:-}}
runner_envelope_scrub
[ ! -d "$pre_scrub_scratch" ] && [ ! -d "$pre_scrub_state" ] || {{ echo "ASSERT_FAIL envelope scratch not scrubbed"; exit 85; }}
echo "ASSERT_PASS envelope scratch/state removed"
[ "$suite_rc" -eq 0 ] && [ "$assert_rc" -eq 0 ]
'''
    argv=['python3','utils/py/proc_group.py','--timeout','150','--','bash','-c',shell]
    t0=utc(); before={'verify':identity(VERIFY),'task':identity(TASK)}
    rc,out=run(argv,cwd=VERIFY,env=base_env)
    t1=utc(); after={'verify':identity(VERIFY),'task':identity(TASK)}
    log=LOG/(pathlib.Path(suite).stem+'.json')
    log.write_text(json.dumps({'suite':suite,'argv':argv,'cwd':str(VERIFY),'ambient_injected':{'XYZ_HARNESS':str(TASK),'XYZ_REPO_ROOT':str(TASK)},'started_utc':t0,'ended_utc':t1,'returncode':rc,'output':out,'identity_before':before,'identity_after':after},indent=2)+'\n')
    records.append({'suite':suite,'started_utc':t0,'ended_utc':t1,'argv':argv,'returncode':rc,'verify_identity_unchanged':before['verify']==after['verify'],'task_identity_unchanged':before['task']==after['task'],'raw_output':str(log)})
    print(f'[{suite}] rc={rc}; verify/task identities unchanged={before["verify"]==after["verify"] and before["task"]==after["task"]}; log={log}')
    print(out[-1800:])
    if rc: break
final={'verify':identity(VERIFY),'task':identity(TASK)}
(OUT/'identity-after.json').write_text(json.dumps(final,indent=2)+'\n')
with (OUT/'provenance.jsonl').open('a') as f:
    f.write(json.dumps({'event':'afterfix_control','candidate_sha':initial['verify']['head'],'ambient_override_target':str(TASK),'baseline_identities':str(OUT/'identity-before.json'),'final_identities':str(OUT/'identity-after.json'),'cases':records},sort_keys=True)+'\n')
if initial['verify']['head']!='76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d': sys.exit('Unexpected verify clone HEAD')
if initial['task']['head']!='863480bf1bb10f54c2b8c0845a64d123bf84d49e': sys.exit('Unexpected task clone HEAD')
if final!=initial: sys.exit('Clone identity drift')
if len(records)!=2 or any(r['returncode'] or not r['verify_identity_unchanged'] or not r['task_identity_unchanged'] for r in records): sys.exit('afterfix result failed')
