"""Bounded manual lint replay; never executes any inherited probe command."""
import ast,glob,hashlib,json,os,re,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2]
def git(*args):return subprocess.check_output(['git','-C',str(root),*args],text=True)
source=(root/'utils/py/jog_run.py').read_text();tree=ast.parse(source)
nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='lint_probe' or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='TRIVIAL_PROBE_PATTERNS' for t in n.targets)]
assert len(nodes)==2
ns={'re':re,'os':os,'glob':glob};exec(compile(ast.Module(body=nodes,type_ignores=[]),'current-lint-probe','exec'),ns)
results=[];inputs=[]
with tempfile.TemporaryDirectory(prefix='gh1447-replay-') as d:
 fixture=Path(d)
 for issue,slug in [(1171,'BRANCH-ARTIFACT-PREFLIGHT'),(1315,'LEGACY-PREVIEW-PARITY')]:
  for label,rev in [('original','f98ad1d925a28e0d724a70c8653b00a100521b59'),('repaired','811d582360df31d21d9ccb4208fb8e474191b08b')]:
   path=f'PROJECT/1-INBOX/GH-{issue}-{slug}.md';doc=git('show',f'{rev}:{path}');assert doc.strip()
   blocks=re.findall(r'```json\s*(.*?)```',doc,re.S);contracts=[json.loads(b) for b in blocks];c=next(c for c in contracts if 'fix_probes' in c)
   probes=[p for p in c['fix_probes'] if p.get('type')=='command'];assert len(probes)==1
   cmd=probes[0]['cmd'];assert cmd.strip();entry={'issue':issue,'label':label,'revision':rev,'doc':path,'doc_sha256':hashlib.sha256(doc.encode()).hexdigest(),'probe':probes[0]}
   if label=='repaired':
    rel=cmd.split()[1];assert not Path(rel).is_absolute() and '..' not in Path(rel).parts
    data=git('show',f'{rev}:{rel}');assert data.strip();f=fixture/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(data);entry['script_sha256']=hashlib.sha256(data.encode()).hexdigest()
   inputs.append(entry);ok,reason=ns['lint_probe'](str(fixture),cmd);results.append({'case':f'{issue}-{label}','accepted':ok,'reason':reason});assert ok==(label=='repaired')
 for name,cmd,want in [('empty','',False),('trivial','echo ok',False),('missing','python3 missing.py',False)]:
  ok,reason=ns['lint_probe'](str(fixture),cmd);results.append({'case':name,'accepted':ok,'reason':reason});assert ok==want
out=Path(__file__).parent
(out/'inputs.json').write_text(json.dumps(inputs,indent=2)+'\n')
(out/'replay-results.json').write_text(json.dumps({'source_revision':git('rev-parse','HEAD').strip(),'source_sha256':hashlib.sha256(source.encode()).hexdigest(),'results':results,'limits':'Only current lint_probe executed. No historical shell commands, probe semantics, full Swarm CLI or end-to-end delivery replay executed.'},indent=2)+'\n')
print(json.dumps(results,indent=2));print('PASS: 7/7 expected lint classifications; semantic acceptance unverified')
