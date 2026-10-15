"""Manual synthetic Git admission trace; no CI test or software PASS evidence."""
import json,os,subprocess,sys
from pathlib import Path
root=Path.cwd(); out=root/'gh1076-debug'; report=json.loads((out/'controlled-v2-report.json').read_text())
fixture=out/'admission-fixture'; source=root/'forge-gh1076-spike'
sys.dont_write_bytecode=True;sys.path.insert(0,str(source/'utils/py'))
import wave_reconcile as wave

def git(*args,stdin=None):
 p=subprocess.run(['git',*args],cwd=fixture if fixture.exists() else root,input=stdin,text=True,capture_output=True,check=True)
 return p.stdout.strip()
if fixture.exists():raise SystemExit('Preserve existing fixture; refusing overwrite')
subprocess.run(['git','clone','--no-hardlinks','--no-checkout',str(Path(report['fixture_root'])/'origin.git'),str(fixture)],check=True,capture_output=True,text=True)
git('config','user.name','GH1076 Controlled Fixture');git('config','user.email','fixture@example.invalid')
base=report['fixture_base'];git('switch','--detach',base)
payload=fixture/'skills/3-weekly/skills-army-hq/README.md';payload.write_text(payload.read_text()+'Manual admission trace only.\n')
git('add',str(payload.relative_to(fixture)));git('commit','-qm','CONTROLLED content-only source; not a real PR')
content=git('rev-parse','HEAD'); scope_base=wave.content_landing_base(str(fixture),content)
missing=wave.validate_pre_merge_receipts(str(fixture),content,900001)
p=fixture/'TESTS-RESULTS/CONTROLLED-ADMISSION-ONLY/provenance.jsonl';p.parent.mkdir(parents=True)
p.write_text(json.dumps(dict(schema_version='CONTROLLED-MANUAL-FIXTURE-ONLY',commit=content,pr=900001,result='pass',rc=0,WARNING='SIMULATED outcome, no software checks executed. Demonstrates admission predicates only.'))+'\n')
git('add',str(p.relative_to(fixture)));git('commit','-qm','CONTROLLED simulated admission receipt; not software qualification')
receipt_head=git('rev-parse','HEAD');tree=git('rev-parse','HEAD^{tree}')
landing=git('commit-tree',tree,'-p',base,'-p',receipt_head,stdin='CONTROLLED merged fixture; no GitHub PR\n')
git('update-ref','refs/gh1076-preserved/admission-landing',landing);git('switch','--detach',landing)
accepted=wave.validate_pre_merge_receipts(str(fixture),landing,900001)
try:wave.content_landing_base(str(fixture),landing);scope_error=None
except ValueError as e:scope_error=str(e)
paths=git('diff','--name-only',base,landing).splitlines()
result=dict(kind='CONTROLLED MANUAL ADMISSION TRACE; simulated receipt only, no software qualification',source_head=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip(),fixture=str(fixture),base=base,content_head=content,landing=landing,content_only_scope_accepts=scope_base==base,content_only_premerge_error=missing,receipt_bearing_premerge_error=accepted,receipt_bearing_scope_error=scope_error,landing_paths=paths,conclusion='The demonstrated ordinary in-PR receipt flow passes generic premerge receipt validation but forces full profile fallback. No admission policy or receipt exemption was changed.',limits='This does not prove all conceivable metadata arrangements are unreachable; no real PR, suite, installation, GitHub write, or setting change.')
(out/'admission-scope.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
