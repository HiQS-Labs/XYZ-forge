"""Isolated recorded publication retry/red control; not a CI case."""
import json,os,subprocess,sys
from pathlib import Path
ROOT=Path('/private/tmp/xyz1012-final-marker-retry-af50c205');assert not ROOT.exists();ROOT.mkdir()
BASE=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/XYZ-forge-gh1012-corrected-evidence-2026-10-12')
CHILD=Path('/private/tmp/xyz1012-final-controls-af50c205/mini-child')
OUT=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/corrected-release');commands=[];rows=[]
env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1')
def run(cwd,*argv,expect=0):
 r=subprocess.run(argv,cwd=cwd,env=env,capture_output=True,text=True,timeout=90);commands.append(dict(cwd=str(cwd),argv=list(argv),rc=r.returncode,stdout=r.stdout,stderr=r.stderr));assert r.returncode==expect,commands[-1];return r
for label,red in [('candidate',False),('guard-removed-red',True)]:
 source=ROOT/(label+'-source');remote=ROOT/(label+'-remote.git');child=ROOT/(label+'-child')
 run(ROOT,'git','clone','--no-local','--quiet',str(BASE),str(source));run(source,'git','config','user.name','Retry Fixture');run(source,'git','config','user.email','fixture@example.invalid')
 run(ROOT,'git','clone','--no-local','--quiet','--bare',str(CHILD),str(remote));run(ROOT,'git','clone','--no-local','--quiet',str(remote),str(child))
 helper=source/'utils/py/xyz_mini_sync.py';s=helper.read_text();s=s.replace('    ("skills/3-weekly/weekly-planner", "skills/weekly-planner", "adapted"),\n','')
 if red:s=s.replace('{p for p in remote_manifest.stdout.splitlines() if not p.endswith("/")}', 'set(remote_manifest.stdout.splitlines())')
 helper.write_text(s);run(source,'git','add','utils/py/xyz_mini_sync.py');run(source,'git','commit','-qm','fixture drop entry'+(' and remove marker retry guard' if red else ''))
 # Clean ignored content may leave an empty-owned adapted directory after upstream removal.
 (child/'.git/info/exclude').write_text('skills/weekly-planner/ignored-fixture\n')
 ignored=child/'skills/weekly-planner/ignored-fixture';ignored.parent.mkdir(parents=True,exist_ok=True);ignored.write_text('preserved ignored bytes\n')
 assert not run(child,'git','status','--porcelain=v1').stdout.strip()
 hook=remote/'hooks/pre-receive';hook.write_text('#!/bin/sh\nexit 1\n');hook.chmod(0o755)
 cli=[sys.executable,'-B',str(helper),'--dest',str(child)]
 fail=run(source,*cli,'--push',expect=3)
 head=run(child,'git','rev-parse','HEAD').stdout.strip()
 result=run(source,*cli,'--apply',expect=2 if red else 0)
 assert run(child,'git','rev-parse','HEAD').stdout.strip()==head and ignored.read_text()=='preserved ignored bytes\n'
 marker='skills/weekly-planner/' in (child/'MANIFEST.txt').read_text().splitlines();assert not marker
 rows.append(dict(label=label,push_exit=3,retry_exit=result.returncode,local_head_retained=True,removed_marker_absent=True,ignored_bytes_preserved=True,source_sha=run(source,'git','rev-parse','HEAD').stdout.strip(),stderr=result.stderr))
(OUT/'marker-retry-control.json').write_text(json.dumps(dict(tested_candidate='af50c205e3f04f3fc6a02ac6c402f2013123b127',rows=rows,commands=commands),indent=2)+'\n');print(json.dumps(rows,indent=2))
