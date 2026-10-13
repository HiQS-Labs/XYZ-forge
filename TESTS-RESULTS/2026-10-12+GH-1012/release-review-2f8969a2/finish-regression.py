import json,subprocess
from pathlib import Path
root=Path('/tmp/xyz1012-regression-20261012-2008')
out=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/release-review')
args={'head':['rev-parse','HEAD'],'origin':['remote','get-url','origin'],'bare':['rev-parse','--is-bare-repository'],'name':['config','--local','--get','user.name'],'email':['config','--local','--get','user.email'],'status':['status','--porcelain=v1'],'common':['rev-parse','--git-common-dir'],'gitdir':['rev-parse','--absolute-git-dir'],'local_config':['config','--local','--list']}
after={}
for k,v in args.items():
 r=subprocess.run(['git',*v],cwd=root,capture_output=True,text=True);after[k]={'rc':r.returncode,'value':r.stdout.strip(),'stderr':r.stderr.strip()}
(out/'regression-identity-after.json').write_text(json.dumps(after,indent=2)+'\n')
before=json.loads((out/'regression-identity-before.json').read_text())
changes={k:{'before':before[k],'after':after[k]} for k in before if before[k]!=after[k]}
(out/'regression-identity-comparison.json').write_text(json.dumps({'unchanged':not changes,'differences':changes},indent=2)+'\n')
print(json.dumps({'unchanged':not changes,'differences':changes},indent=2))
