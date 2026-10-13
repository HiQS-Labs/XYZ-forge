from pathlib import Path
import datetime, hashlib, json, os, subprocess
root=Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-environment/discovery')
verify=Path('/Users/noelsaw/task-clones/ate-remediation-20261003/verify')
task=Path('/Users/noelsaw/task-clones/ate-remediation-20261003/task')
repo=verify
timestamp=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
def git_identity(path):
    def git(*args):
        p=subprocess.run(['git','-C',str(path),*args],capture_output=True,text=True,timeout=10)
        return {'rc':p.returncode,'stdout':p.stdout.strip(),'stderr':p.stderr.strip()}
    gdir=git('rev-parse','--absolute-git-dir')['stdout']
    cfg=Path(gdir)/'config'
    return {
      'path':str(path),'head':git('rev-parse','HEAD'),'branch':git('symbolic-ref','-q','HEAD'),
      'status':git('status','--porcelain=v1','--branch'),'core_bare':git('config','--get','core.bare'),
      'remotes':git('remote','-v'),'local_email':git('config','--local','--get','user.email'),
      'worktrees':git('worktree','list','--porcelain'),
      'config_sha256':hashlib.sha256(cfg.read_bytes()).hexdigest() if cfg.is_file() else None
    }
base_env=os.environ.copy()
for k in ['XYZ_HARNESS','XYZ_REPO_ROOT','XYZ_HARNESS_DB','OPENROUTER_API_KEY','DEEPSEEK_API_KEY']:
    base_env.pop(k,None)
base_env.update({'HOME':str(root/'home'),'XDG_CONFIG_HOME':str(root/'xdg')})
results=[]
for suite in ['find-harness.sh','gh396-find-harness-roots.sh']:
  for mode in ['clean','inherited']:
    env=base_env.copy()
    if mode=='inherited':
      env['XYZ_HARNESS']=str(task)
      env['XYZ_REPO_ROOT']=str(task)
    argv=['python3','utils/py/proc_group.py','--timeout','90','--','bash',f'test/{suite}']
    record={'at_utc':timestamp(),'suite':suite,'mode':mode,'argv':argv,'cwd':str(verify),
      'effective_selection_env':{'XYZ_HARNESS':env.get('XYZ_HARNESS'), 'XYZ_REPO_ROOT':env.get('XYZ_REPO_ROOT')},
      'verify_before':git_identity(verify),'task_before':git_identity(task)}
    p=subprocess.run(argv,cwd=verify,env=env,capture_output=True,text=True,timeout=110)
    record.update({'outer_rc':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'timed_out':p.returncode==124,
      'verify_after':git_identity(verify),'task_after':git_identity(task)})
    record['verify_identity_unchanged']=record['verify_before']==record['verify_after']
    record['task_identity_unchanged']=record['task_before']==record['task_after']
    log=root/'logs'/f'{suite}.{mode}.json'
    log.write_text(json.dumps(record,indent=2)+'\n')
    results.append({'suite':suite,'mode':mode,'rc':p.returncode,'identity_unchanged':record['verify_identity_unchanged'] and record['task_identity_unchanged'],'log':str(log),'tail':(p.stdout.splitlines()[-8:] if p.stdout else [])})
summary={'at_utc':timestamp(),'verify_base':'3fbed72f781d1ad060e298b798a44c32edef393d','task_base_before':'863480bf1bb10f54c2b8c0845a64d123bf84d49e','results':results}
(root/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
