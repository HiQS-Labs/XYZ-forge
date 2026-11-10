import ast,json,types,sys,subprocess
from pathlib import Path
rows=[]
def nodes(path):
 if path.endswith('.before.py'):
  name=Path(path).name.replace('.before.py','.py')
  source=subprocess.check_output(['git','show','a8186569ba1fa1b5f8631ac066048177704ef498:utils/py/'+name],text=True)
 else:source=Path(path).read_text()
 return list(ast.walk(ast.parse(source)))
def run(block,env):exec(compile(ast.fix_missing_locations(ast.Module(body=block,type_ignores=[])),'controlled-source','exec'),env)
for version,prefix,suffix in [('baseline','TESTS-RESULTS/2026-11-10+GH-1243/review-followup/','.before.py'),('candidate','utils/py/','.py')]:
 ns=nodes(prefix+'swarm_preflight'+suffix);inv=next(n for n in ns if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='invocation' for t in n.targets));cap=[n for n in ns if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='round_cap_arg' for t in n.targets)]
 for configured in (2,None):
  env=dict(slug='demo',drive_cmd='drive',art_csv='file',target_root_line='',gate_cmd='gate',merged={'round_cap':configured});run(cap+[inv],env);observed='--round-cap 2' in env['invocation'];rows.append(dict(version=version,check='text_cap',configured=configured,observed=observed,expected=configured==2,pass_=observed==(configured==2)))
 ns=nodes(prefix+'consult'+suffix);assigns=[n for n in ns if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='diagnostic_out' for t in n.targets)];summaries=[n for n in ns if isinstance(n,ast.AugAssign) and isinstance(n.target,ast.Name) and n.target.id=='summary' and 'see transcript for error' in ast.unparse(n)]
 for model in ('codex','agy'):
  for i,n in enumerate(summaries):
   env=dict(m=model,out='answer.md',summary='');run(assigns+[n],env);want='answer.md.transcript' if model=='codex' else 'answer.md';ok=('-> '+want+' (') in env['summary'];rows.append(dict(version=version,check='failure_summary',model=model,branch=i,observed=env['summary'],expected=want,pass_=ok))
 ns=nodes(prefix+'relay_drive'+suffix);review=next(n for n in ns if isinstance(n,ast.If) and ast.unparse(n.test)=='args.review_once' and n.lineno>1000);strict=next(n for n in ns if isinstance(n,ast.If) and 'args.strict_role_handoff' in ast.unparse(n.test) and 'nactor' in ast.unparse(n.test));block=sorted([review,strict],key=lambda n:n.lineno)
 for nextactor in ('unexpected','codex'):
  def escalate(reason):raise RuntimeError(reason)
  env=dict(args=types.SimpleNamespace(review_once=True,strict_role_handoff=True,builder='codex',reviewer='agy'),ns='In progress',nactor=nextactor,actor='agy',terminal_status=lambda s:False,nrfsig='changed',rfsig='old',nnextp='x',nextp='y',s='In progress',relay_file='temp/review-1406/nonexistent',rf_text_before='',review_blocks_added=lambda a,b:1,xyz_relay_emit=lambda a:None,exit_escalate=escalate,sys=sys,print=lambda *a:None)
  try:run(block,env);result='returned'
  except SystemExit as e:result='exit:'+str(e.code)
  except RuntimeError as e:result=str(e)
  expected='explicit-cap-invalid-handoff' if nextactor=='unexpected' else 'exit:5';rows.append(dict(version=version,check='review_once_handoff',nextactor=nextactor,observed=result,expected=expected,pass_=result==expected))
assert any(not r['pass_'] for r in rows if r['version']=='baseline')
assert all(r['pass_'] for r in rows if r['version']=='candidate')
Path('temp/review-1406/results.json').write_text(json.dumps({'method':'controlled execution of extracted actual AST statements; not full CLI/gate qualification','rows':rows},indent=2)+'\n')
print(json.dumps({'baseline_failed':sum(not r['pass_'] for r in rows if r['version']=='baseline'),'candidate_passed':sum(r['pass_'] for r in rows if r['version']=='candidate')}))
