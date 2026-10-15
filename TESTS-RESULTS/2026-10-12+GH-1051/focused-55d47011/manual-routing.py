from pathlib import Path
import copy,hashlib,json,subprocess,yaml
ROOT=Path('/private/tmp/XYZ-forge-gh1051-pages-development-2026-10-12-verify')
OUT=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/pages-hotfix')
a=yaml.load((OUT/'pages-before.yml').read_text(),Loader=yaml.BaseLoader)
b=yaml.load((ROOT/'.github/workflows/pages.yml').read_text(),Loader=yaml.BaseLoader)
expected=copy.deepcopy(a);expected['on']['push']['branches']=['development'];expected['concurrency']['group']='pages-${{ github.ref }}'
for job in ('build','deploy'):expected['jobs'][job]['if']="github.ref == 'refs/heads/development'"
assert b==expected,'unexpected workflow field changed'
def verdict(w,event,ref):
 triggered=event=='workflow_dispatch' or event=='push' and ref.removeprefix('refs/heads/') in w['on']['push']['branches']
 guards={j:w['jobs'][j].get('if') for j in ('build','deploy')}
 assert all(g is None or g=="github.ref == 'refs/heads/development'" for g in guards.values())
 jobs={j:triggered and (g is None or ref=='refs/heads/development') for j,g in guards.items()}
 return {'triggered':triggered,'jobs':jobs,'concurrency':w['concurrency']['group'].replace('${{ github.ref }}',ref)}
rows=[]
for event,ref in [('push','refs/heads/development'),('workflow_dispatch','refs/heads/development'),('push','refs/heads/main'),('workflow_dispatch','refs/heads/main'),('workflow_dispatch','refs/tags/v1'),('workflow_dispatch','refs/heads/other')]:
 old=verdict(a,event,ref);new=verdict(b,event,ref);wanted=ref=='refs/heads/development';assert all(v==wanted for v in new['jobs'].values());rows.append({'event':event,'ref':ref,'original':old,'fixed':new})
assert verdict(a,'workflow_dispatch','refs/heads/main')['jobs']['deploy']
assert verdict(a,'workflow_dispatch','refs/heads/main')['concurrency']==verdict(a,'workflow_dispatch','refs/heads/development')['concurrency']
assert verdict(b,'workflow_dispatch','refs/heads/main')['concurrency']!=verdict(b,'workflow_dispatch','refs/heads/development')['concurrency']
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
r={'source_commit':head,'workflow_sha256':hashlib.sha256((ROOT/'.github/workflows/pages.yml').read_bytes()).hexdigest(),'only_four_declared_changes':True,'rows':rows,'original_main_dispatch_red':True,'original_shared_concurrency_red':True,'fixed_controls_pass':True,'limit':'one-off manual static contract check of the exact literal ref expressions and declared workflow fields; no hosted dispatch/deployment, CI case, test registration or runner machinery'}
(OUT/'manual-routing.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'head':head,'manual_controls':'pass','original_controls':'red','rows':len(rows)}))
