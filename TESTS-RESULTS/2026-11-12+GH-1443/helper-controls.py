"""Manual source-owner controls, including mixed selection and unevaluated input."""
import argparse,contextlib,io,json,os,pathlib,sqlite3,subprocess,sys,tempfile
from unittest.mock import patch
sys.path.insert(0,str(pathlib.Path.cwd()/'utils/py'))
import jog_run as j
results=[]
def check(name,passed,observed):results.append(dict(case=name,passed=bool(passed),observed=observed))
with tempfile.TemporaryDirectory(prefix='gh1443-helper-') as d:
 root=pathlib.Path(d);doc=root/'PROJECT/1-INBOX/GH-99001-CONTROL.md';doc.parent.mkdir(parents=True);(root/'probe.py').write_text('raise SystemExit(1)\n')
 legacy='---\ngh_issue: 99001\nfix_probes:\n  - python3 probe.py\n---\n'
 doc.write_text(legacy+'## Preflight Contract\n```json\nINVALID\n```\n')
 p,r=j.promotion_probes(str(root),str(doc));check('valid legacy wins over invalid contract',p==['python3 probe.py'] and r is None,[p,r])
 contract={'target':{'repo':str(root),'ref':'development'},'gate':'python3 probe.py','fix_probes':[{'type':'path_absent','path':'missing'}],'artifacts':['probe.py']}
 doc.write_text(legacy.replace('python3 probe.py','python3 missing.py')+'## Preflight Contract\n```json\n'+json.dumps(contract)+'\n```\n')
 p,r=j.promotion_probes(str(root),str(doc));check('invalid legacy uses real contract fallback',p==['path_absent:missing'] and r is None,[p,r])
 doc.write_text('---\ngh_issue: 99001\n---\n')
 p,r=j.promotion_probes(str(root),str(doc));check('neither source supplies probes',p==[],[p,r])
 with patch.object(j,'_resolve_preflight_py',return_value=str(root/'absent')):
  rc,msg=j._dry_run_preflight(str(root),99001);check('missing helper not evaluated',rc==2 and 'not evaluated' in msg,[rc,msg])
 # Mixed queue: real entry point loop, static/external seams controlled; no execution call allowed.
 c=sqlite3.connect(root/'releases.db');c.execute('CREATE TABLE jog_queue(gh_number INTEGER,position INTEGER,attempt_count INTEGER,status TEXT)');c.executemany('INSERT INTO jog_queue VALUES(?,?,0,?)',[(99001,1,'pending'),(99002,2,'pending')]);c.commit();c.close()
 args=argparse.Namespace(root=str(root),target_root=str(root/'target'),dry_run=True,simulate=False,executor='marathon',builder='codex',reviewer='agy',auto_merge=False,checkpoint_root=None,max_tasks=2)
 output=io.StringIO();rc=0;before=(root/'releases.db').read_bytes()
 with patch.object(j,'_validate_execution_target',return_value=str(root/'target')),patch.object(j,'validate_marathon_executor',return_value=None),patch.object(j,'_dry_run_preflight',side_effect=[(4,'already landed (exit 4)'),(0,'ready (exit 0)')]) as pre,contextlib.redirect_stdout(output):
  try:j.jog_run_main(args)
  except SystemExit as e:rc=e.code
 check('mixed queue visits all and refuses',rc==2 and pre.call_count==2 and 'GH-99002' in output.getvalue(),{'rc':rc,'output':output.getvalue()})
 check('mixed queue preserved',before==(root/'releases.db').read_bytes() and not(root/'.tick').exists(),'DB bytes unchanged; no .tick')
 args.target_root=None;args.reviewer=None
 with contextlib.redirect_stdout(io.StringIO()):j.jog_run_main(args)
 check('bare preview no role requirement',True,'returned normally')
 # Role checker preserves imported routing/result state, and rejects missing role without dispatch.
 import marathon_drive
 before_env=dict(os.environ);before_result=dict(marathon_drive._RESULT)
 error=j.validate_marathon_executor(args)
 check('role admission preserves ambient state',bool(error) and before_env==dict(os.environ) and before_result==marathon_drive._RESULT,error)
print(json.dumps({'cases':results,'passed':sum(r['passed'] for r in results),'total':len(results)},indent=2))
assert all(r['passed'] for r in results)
