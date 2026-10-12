"""Recorded one-off ownership controls; no CI registration or case added."""
import json, os, subprocess, sys
from pathlib import Path
ROOT=Path('/private/tmp/xyz1037-distribution-green-20261012')
OUT=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/sync-fixes')
source=ROOT/'manager-source';bundle=source/'skills/3-weekly/skills-army-hq'
clean=ROOT/'pulse-collection';records=[];env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1')
def run(cwd,*argv):
 r=subprocess.run(argv,cwd=cwd,env=env,capture_output=True,text=True,timeout=60)
 records.append(dict(cwd=str(cwd),argv=list(argv),exit=r.returncode,stdout=r.stdout,stderr=r.stderr));assert r.returncode==0,records[-1];return r
run(source,'git','config','user.name','Ownership Fixture');run(source,'git','config','user.email','fixture@example.invalid')
with (bundle/'README.md').open('a') as f:f.write('\nSecond fixture README revision.\n')
run(source,'git','add','--',str(bundle/'README.md'));run(source,'git','commit','-qm','fixture second revision')
rows=[]
for case in ('unrelated-dirt','preexisting-readme'):
 child=ROOT/case;assert not child.exists()
 run(ROOT,'git','clone','--no-local','--quiet',str(clean),str(child))
 run(child,'git','config','user.name','Ownership Fixture');run(child,'git','config','user.email','fixture@example.invalid')
 cli=[sys.executable,'-B',str(bundle/'scripts/intake.py'),'--root',str(child),'--apply']
 run(ROOT,*cli,'init','--adopt-existing')
 targets=json.loads((child/'targets.json').read_text())['targets'];assert targets and not any(x['enabled'] for x in targets)
 if case=='unrelated-dirt':
  (child/'notes.txt').write_text('owned fixture note\n');run(child,'git','add','notes.txt');run(child,'git','commit','-qm','fixture note baseline')
  (child/'notes.txt').write_text('unrelated edit must remain\n')
 else:
  (child/'README.md').write_text('preexisting staged README edit\n');run(child,'git','add','README.md')
 before=run(child,'git','rev-parse','HEAD').stdout.strip()
 index_before=run(child,'git','show',':README.md').stdout if case=='preexisting-readme' else None
 result=run(ROOT,*cli,'update','skills-army-hq','--source',str(bundle))
 after=run(child,'git','rev-parse','HEAD').stdout.strip();dirty=run(child,'git','status','--porcelain=v1').stdout
 assert before==after and dirty and 'unrelated uncommitted changes' in result.stderr
 if case=='unrelated-dirt':assert (child/'notes.txt').read_text()=='unrelated edit must remain\n'
 else:assert run(child,'git','show',':README.md').stdout==index_before
 rows.append(dict(case=case,head_unchanged=before==after,dirty=dirty,warning=result.stderr,foreign_edit_preserved=True,
   limit='Existing transaction still refreshes working root README; this check verifies it is not auto-committed and the staged original is preserved.' if case=='preexisting-readme' else 'Other dirty file bytes preserved.'))
(OUT/'ownership-refusal-controls.json').write_text(json.dumps(dict(candidate='11597ea6ba4fb491da70681d21e793eec5ec4d94',rows=rows,commands=records),indent=2)+'\n')
print(json.dumps(rows,indent=2))
