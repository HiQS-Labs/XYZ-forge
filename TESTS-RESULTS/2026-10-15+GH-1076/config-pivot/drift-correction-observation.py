"""Unregistered fault observation reusing the existing gh425 fixture; never a CI test or real qualification."""
import sys,os,json,subprocess,importlib.util,contextlib,io,datetime
from pathlib import Path
from unittest.mock import patch
sys.dont_write_bytecode=True
base=Path('/Users/noelsaw/Documents/Codex/2026-10-14/task');repo=base/'forge-gh1076-focused-verify';out=base/'gh1076-config-evidence'
sys.argv=['manual-observation',str(repo)]
source=(repo/'test/gh425-gate-provenance-pr.sh').read_text().split("<<'PY'\n",1)[1].rsplit('\nPY',1)[0].split('unittest.main(',1)[0]
ns={'__name__':'gh1076_existing_fixture'};exec(compile(source,'existing-gh425-fixture','exec'),ns)
current=ns['wave']
oldpath=out/'pre-correction-wave.py';oldpath.write_bytes(subprocess.check_output(['git','show','3a12a9f2:utils/py/wave_reconcile.py'],cwd=repo))
spec=importlib.util.spec_from_file_location('gh1076_pre_correction',oldpath);old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
import proc_group
facts=[]
for label,module,fault in [('before-environment-drift',old,'environment'),('after-environment-drift',current,'environment'),('before-process-drift',old,'process'),('after-process-drift',current,'process'),('after-stable-incomplete-proof',current,'proof')]:
 ns['wave']=module;fixture=ns['Qualification']();fixture.setUp(); fixture_runner=fixture.root/'validate.sh'; fixture_runner.write_text(fixture_runner.read_text().replace('p.mkdir(parents=True)', 'p.mkdir(parents=True,exist_ok=True)')); fixture.git('add','validate.sh'); fixture.git('commit','-m','manual-only repeatable telemetry folder'); fixture.sha=fixture.git('rev-parse','HEAD').strip(); fixture.meta=dict(fixture.meta,mergeCommit={'oid':fixture.sha}); calls=[];captured=io.StringIO();realrun=proc_group.run_bounded;real_summary=module.qualification_summary;summary_calls=[0]
 def run(args,**kw):
  if args[:2]==['bash','validate.sh']:calls.append(list(args))
  return realrun(args,**kw)
 def summary(*args,**kwargs):
  summary_calls[0]+=1;r=real_summary(*args,**kwargs)
  if fault=='proof' and summary_calls[0]==1:raise ValueError('manual identity-stable incomplete-proof observation')
  return r
 try:
  with contextlib.ExitStack() as stack:
   stack.enter_context(patch.object(module,'select_qualification_gate',return_value=(module.CONTENT_GATE,None,'controlled existing fixture observation')))
   stack.enter_context(patch.object(module,'content_source_identity',return_value=('b'*40,fixture.sha)))
   stack.enter_context(patch.object(module,'content_policy_revision',return_value='c'*40))
   stack.enter_context(patch.object(module,'content_profile_phases',return_value=[('small',module.QUALIFICATION_GATE,None,module.SMALL_NON_SUITE),('skills-army-hq',module.QUALIFICATION_GATE,None,())]))
   stack.enter_context(patch.object(module,'qualification_environment',side_effect=[{'manual':'before'},{'manual':'changed' if fault=='environment' else 'before'}]))
   stack.enter_context(patch.object(module,'qualification_summary',side_effect=summary))
   stack.enter_context(patch.object(proc_group,'run_bounded',side_effect=run))
   stack.enter_context(contextlib.redirect_stdout(captured));stack.enter_context(contextlib.redirect_stderr(captured))
   try:fixture.qualify('wrong-run' if fault=='process' else '');code=0
   except module.ReconcileError as exc:code=exc.code
  receipts=list(fixture.root.rglob('provenance.jsonl'))
  schemas=[json.loads(p.read_text().splitlines()[0]).get('schema_version') for p in receipts]
  facts.append(dict(observation=label,exit_code=code,fixture_validation_commands=calls,passing_fixture_receipt_written=bool(receipts),fixture_schemas=schemas,log=captured.getvalue(),source='3a12a9f2' if module is old else subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()))
 finally:fixture.doCleanups()
ns['wave']=current
report=dict(timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),kind='Unregistered bounded fault observation, using existing gh425 disposable fixture and fixture telemetry only. NOT real suite execution, PR proof, an @2 qualification or CI test/case. No registration/source-test edits/installations/network.',method='Existing fixture setup/runner reused; only temporary telemetry mkdir uses exist_ok=True so the single-run fixture can run twice. Original first observation hit that fixture limitation and is retained separately. No repository test edits. Selection/identity metadata are controlled to enter profile branch; only environment, launched-run ID or proof availability differ. Temporary generated fixture provenance is discarded, never committed.',observations=facts)
(out/'drift-correction-observation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps([{k:v for k,v in f.items() if k not in ['log','source']} for f in facts],indent=2))
