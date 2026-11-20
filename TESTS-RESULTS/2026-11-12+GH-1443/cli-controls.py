"""Manual actual CLI control matrix with a controlled preflight executable, no provider/network."""
import hashlib,json,os,pathlib,sqlite3,subprocess,sys,tempfile
source=pathlib.Path.cwd(); work=pathlib.Path(tempfile.mkdtemp(prefix='gh1443-cli-'))
def git(root,*a):
 return subprocess.check_output(['git','-C',str(root),*a],stderr=subprocess.STDOUT,text=True).strip()
seed=work/'seed'; seed.mkdir(); git(seed,'init','-b','development');git(seed,'config','user.name','Fixture');git(seed,'config','user.email','fixture@example.invalid')
(seed/'releases.sql').write_text('-- fixture\n')
c=sqlite3.connect(seed/'releases.db');c.execute('CREATE TABLE jog_queue(gh_number INTEGER,position INTEGER,attempt_count INTEGER,status TEXT)');c.execute("INSERT INTO jog_queue VALUES(99001,1,0,'pending')");c.execute('CREATE TABLE roadmap_items(gh_number INTEGER, doc_path TEXT)');c.commit();c.close()
doc=pathlib.Path('PROJECT/1-INBOX/GH-99001-CONTROL.md');(seed/doc).parent.mkdir(parents=True)
good='---\ngh_issue: 99001\nfix_probes:\n  - python3 probe.py\n---\n# Manual fixture\n'
(seed/doc).write_text(good);(seed/'probe.py').write_text('raise SystemExit(1)\n')
sp=seed/'utils/py/swarm_preflight.py';sp.parent.mkdir(parents=True);sp.write_text('import os,sys\nn=int(os.environ.get("FIXTURE_RC","0"))\nprint(f"verdict : controlled (exit {n})")\nsys.exit(n)\n')
git(seed,'add','.');git(seed,'commit','-m','fixture')
roots={}
for name in ['primary','target','publication']:
 p=work/name; subprocess.run(['git','clone','--no-hardlinks',str(seed),str(p)],check=True,capture_output=True);git(p,'remote','set-url','origin','https://github.com/example/fixture.git');roots[name]=p
root,target,pub=(roots[n] for n in ['primary','target','publication'])
base=[sys.executable,str(source/'utils/py/jog_run.py'),'--root',str(root),'--dry-run','--target-root',str(target),'--builder','codex','--reviewer','agy','--max-tasks','1']
env={**os.environ,'PYTHONDONTWRITEBYTECODE':'1','CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true'}
records=[]
def run(name,expected,args=None,over=None):
 before={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'releases.db',root/'releases.sql']}
 p=subprocess.run(args or base,env={**env,**(over or {})},capture_output=True,text=True)
 after={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'releases.db',root/'releases.sql']}
 records.append(dict(case=name,expected=expected,actual=p.returncode,pass_=p.returncode==expected,output=p.stdout+p.stderr,ledger_unchanged=before==after,no_jog_state=not (root/'.tick').exists()))
run('valid target main path',0)
run('failed preflight',2,over={'FIXTURE_RC':'3'})
run('already landed is not new work readiness',2,over={'FIXTURE_RC':'4'})
run('missing reviewer',2,args=base[:base.index('--reviewer')]+base[base.index('--reviewer')+2:])
run('same reviewer',2,args=[('codex' if x=='agy' else x) for x in base])
run('missing binary',2,over={'AGY_BIN':'gh1443-does-not-exist'})
run('unknown role',2,args=[('unrecognized' if x=='agy' else x) for x in base])
run('auto merge unsupported',2,args=base+['--auto-merge'])
run('valid checkpoint',0,args=base+['--checkpoint-root',str(pub)])
run('publication equals execution',2,args=base+['--checkpoint-root',str(target)])
run('checkpoint needs bounded tasks',2,args=base[:-2]+['--checkpoint-root',str(pub)])
(pub/'foreign.txt').write_text('preserve\n');run('dirty publication',2,args=base+['--checkpoint-root',str(pub)]);git(pub,'add','foreign.txt');git(pub,'-c','user.name=Fixture','-c','user.email=fixture@example.invalid','commit','-m','retained foreign fixture')
git(pub,'branch','fixture-other');git(pub,'switch','fixture-other');run('wrong publication branch',2,args=base+['--checkpoint-root',str(pub)])
(target/doc).write_text('---\ngh_issue: 99001\nfix_probes:\n  - python3 -c "assert False"\n---\n# Bad probe\n');run('promotion unsupported command',2)
(target/doc).write_text(good.replace('gh_issue: 99001','gh_issue: "https://example.invalid/99001"'));run('inbox identity cannot be evaluated',2)
(target/doc).write_text(good);run('bare preview adjacent compatibility',0,args=[sys.executable,str(source/'utils/py/jog_run.py'),'--root',str(root),'--dry-run'])
print(json.dumps({'fixture_root':str(work),'source':git(source,'rev-parse','HEAD'),'cases':records,'passed':sum(r['pass_'] for r in records),'total':len(records),'all_preserved':all(r['ledger_unchanged'] and r['no_jog_state'] for r in records)},indent=2))
