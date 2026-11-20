import json,pathlib,sys,time
sys.argv=[sys.argv[0],'--out',str(pathlib.Path.cwd()/'temp/gh1400-manual/latest')]
text=pathlib.Path('temp/gh1400-manual/check.py').read_text();exec(text[:text.index("required=['adoption")])
for name,mode in [('retry-missing','missing'),('retry-invalid','invalid'),('wrong-target','target')]:
 r,t,g,receipt=setup(name);sp=state(r,g);s=json.loads(sp.read_text())
 if mode in ('missing','invalid'):
  path=sp.parent/'gate-retry.json';s['executions'][0]['gate_retries']=[{'execution_id':'gh901-exec1-gateretry1','result_path':str(path)}];sp.write_text(json.dumps(s))
  if mode=='invalid':path.write_text('{}')
 else:
  receipt['target_repo']['path']=str(r);path=pathlib.Path(s['executions'][0]['result_path']);path.write_text(json.dumps(receipt))
 p=wake(name,r,t);rs=row(r);assert 'supervision held' in rs[0]['failure_reason'] and (t/'.tick/starts').read_text().count('901\n')==1
 records.append({'id':name,'pass':True,'rows':rs,'output':p.stdout+p.stderr})
(out/'results.json').write_text(json.dumps(records,indent=2));print(json.dumps({'passed':len(records)}))
