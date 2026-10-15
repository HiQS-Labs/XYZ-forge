"""Read-only replay of already committed @1 records through old/current consumers."""
import importlib.util,json,sys,subprocess,datetime
from pathlib import Path
sys.dont_write_bytecode=True
base=Path('/Users/noelsaw/Documents/Codex/2026-10-14/task')
repo=base/'forge-gh1076-spike';old=base/'forge-gh1076-before-matched-gate'
sys.path.insert(0,str(repo/'utils/py'))
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
cur=load('current_wave',repo/'utils/py/wave_reconcile.py');prior=load('prior_wave',old/'utils/py/wave_reconcile.py')
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()
entries=cur.committed_qualifications(str(repo));records=[]
for entry in entries:
 meta={'mergeCommit':{'oid':entry.get('landing_commit')}}
 if entry.get('artifact_kind')=='commit':meta.update(artifactKind='commit',sha=entry.get('landing_commit'),number=entry.get('landing_commit'))
 else:meta['number']=entry.get('pr')
 a=prior.qualification_receipt_matches(str(repo),entry,meta);b=cur.qualification_receipt_matches(str(repo),entry,meta)
 records.append(dict(pr=entry.get('pr'),kind=entry.get('artifact_kind'),tested=entry.get('tested_commit'),landing=entry.get('landing_commit'),gate=entry.get('gate'),suites=entry.get('suites'),old_accepts=a,current_accepts=b))
report=dict(timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),old_consumer='f974fcee15647aae6551fcc81b129f5a6127120b',current_consumer=head,repository_head=head,method='Production functions on actual committed wave receipts and raw files at current source HEAD. No receipt mutations, fixtures, tests, gates or remote actions. Metadata uses each recorded landing/pr identity; this compares parser/replay compatibility, not independent GitHub PR ownership truth.',records=records,count=len(records),accepted_old=sum(r['old_accepts'] for r in records),accepted_current=sum(r['current_accepts'] for r in records),differences=[r for r in records if r['old_accepts']!=r['current_accepts']])
(base/'gh1076-config-evidence/historical-receipt-compatibility.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['count','accepted_old','accepted_current','differences']}))
