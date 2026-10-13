import hashlib,json,subprocess
from pathlib import Path
R=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/corrected-release')
M='4895148683120b8b6f808d4dcd66267a3754fd2c'
F='af50c205e3f04f3fc6a02ac6c402f2013123b127'
B='a076b1b117a68252dc3d9d1c4901b0c31fcb4db3'
RUN=38326961087

def raw(path):
 p=subprocess.run(['gh','api','repos/HiQS-Labs/XYZ-forge/'+path],capture_output=True)
 assert p.returncode==0,p.stderr.decode(errors='replace')
 return p.stdout

def api(path,name):
 b=raw(path);(R/name).write_bytes(b);return json.loads(b)

run=api(f'actions/runs/{RUN}','main-ci-final.json')
assert run['head_sha']==M and run['head_branch']=='main' and run['event']=='push'
assert run['status']=='completed' and run['conclusion']=='success'
jobs=api(f'actions/runs/{RUN}/jobs','main-jobs-final.json')['jobs']
mac=next(j for j in jobs if 'promotion boundary' in j['name'])
smoke=next(j for j in jobs if 'vendored smoke' in j['name'])
assert mac['conclusion']=='success' and smoke['conclusion']=='success' and 'macos-latest' in mac['labels']
for name in ('Run the authoritative validator (no skips)','Promotion evidence'):
 assert next(s for s in mac['steps'] if s['name']==name)['conclusion']=='success'
log=raw(f"actions/jobs/{mac['id']}/logs");assert len(log)>1000
(R/'main-boundary.log').write_bytes(log)
line='MACOS-BOUNDARY: green '+M
matches=[s for s in log.decode(errors='replace').splitlines() if s.strip().endswith(line)]
assert matches,'no actual exact-main green output'
assert not any(s.strip().endswith('MACOS-BOUNDARY: red '+M) for s in log.decode(errors='replace').splitlines())
commit=api('git/commits/'+M,'actual-main-commit.json');candidate=api('git/commits/'+F,'actual-candidate-commit.json');ref=api('git/ref/heads/main','current-main-ref.json')
assert [p['sha'] for p in commit['parents']]==[B,F] and commit['tree']['sha']==candidate['tree']['sha']
result={'qualified_main':M,'tested_candidate':F,'last_good_main':B,'main_parents':[B,F],'main_tree_matches_candidate':True,'run':RUN,'url':run['html_url'],'macos_job':mac['id'],'macos_labels':mac['labels'],'macos_conclusion':mac['conclusion'],'full_validator_step':'success','smoke_conclusion':smoke['conclusion'],'boundary_output':matches,'raw_log_bytes':len(log),'raw_log_sha256':hashlib.sha256(log).hexdigest(),'current_main':ref['object']['sha'],'current_main_matches':ref['object']['sha']==M,'limit':'qualifies this immutable main SHA only; declared live-agent exclusion, no installed/provider pilot proof; canonical issue/plan write remains separately denied'}
(R/'MAIN-QUALIFICATION.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
