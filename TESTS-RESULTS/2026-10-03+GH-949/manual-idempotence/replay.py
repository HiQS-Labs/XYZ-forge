import sys,json,pathlib,subprocess,datetime
repo=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False)
sys.path.insert(0,str(repo/'utils/py'))
from domain_oracles import check_idempotence_oracle
rows=[]
for kind in ['exit','output','stable']:
 cwd=out/kind;cwd.mkdir();(cwd/'sentinel').write_text('nonempty')
 count=out/(kind+'.count')
 code='from pathlib import Path; import sys; p=Path(sys.argv[1]); n=int(p.read_text()) if p.exists() else 0; p.write_text(str(n+1)); '
 code+= {'exit':'print("same"); sys.exit(3 if n==0 else 0)','output':'print("first" if n==0 else "later")','stable':'print("same")'}[kind]
 result=check_idempotence_oracle([sys.executable,'-c',code,str(count)],str(cwd),repetitions=3,timeout=2)
 rows.append(dict(case=kind,passed=result['passed']==(kind=='stable'),result=result))
(out/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
(out/'provenance.jsonl').write_text(json.dumps(dict(source_sha=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip(),utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),command=sys.argv,results=rows))+'\n')
print([(r['case'],r['passed']) for r in rows])
