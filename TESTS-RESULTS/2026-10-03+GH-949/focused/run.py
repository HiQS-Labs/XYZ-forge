import subprocess,json,datetime,pathlib,time,os
repo=pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/verify')
out=pathlib.Path(__file__).parent
suites=['gh478-runaway-guard.sh','ate-run-variations.sh','gh142-ate-exit-contract.sh','synthetic/gh102-telemetry-schema.sh','gh-gen4-phase1-domain-oracles.sh','gh155-phase1-metamorphic-invariants.sh','gh365-runner-envelope.sh']
def identity():
 return {key:subprocess.run(cmd,cwd=repo,text=True,capture_output=True).stdout for key,cmd in {'head':['git','rev-parse','HEAD'],'bare':['git','config','--get','core.bare'],'remote':['git','remote','-v'],'email':['git','config','--local','--get','user.email'],'status':['git','status','--porcelain'],'worktrees':['git','worktree','list','--porcelain']}.items()}
env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1');env.pop('XYZ_HARNESS',None);env.pop('XYZ_REPO_ROOT',None)
for suite in suites:
 before=identity();started=datetime.datetime.now(datetime.timezone.utc).isoformat();name=suite.replace('/','_')
 with (out/(name+'.log')).open('w') as f:r=subprocess.run(['bash','test/'+suite],cwd=repo,stdout=f,stderr=subprocess.STDOUT,env=env,timeout=600)
 after=identity();record=dict(suite=suite,command=['bash','test/'+suite],started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),rc=r.returncode,before=before,after=after,identity_unchanged=before==after)
 with (out/'provenance.jsonl').open('a') as f:f.write(json.dumps(record)+'\n')
 print(suite,r.returncode,'identity',before==after,flush=True)
 if before!=after:break
