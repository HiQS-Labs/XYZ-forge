"""Unregistered read-only observations, not CI cases or a live qualification."""
import os,sys,json,hashlib,subprocess,datetime,importlib.util
from pathlib import Path
sys.dont_write_bytecode=True
root=Path('/Users/noelsaw/Documents/Codex/2026-10-14/task');repo=root/'forge-gh1076-spike';out=root/'gh1076-config-evidence'
sys.path.insert(0,str(repo/'utils/py'))
import wave_reconcile as w
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()
env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1');env.pop('XYZ_CI_OPTIMIZED',None)
path='skills/3-weekly/skills-army-hq/README.md\n'
controls=[]
# Observe the requested on/off and fail-closed behavior through actual CLI and router.
for label,file,override in [('file-on','on.json',None),('file-off','off.json',None),('env-off-over-file-on','on.json','0'),('malformed-file-even-with-env-on','malformed.json','1')]:
 config=root/'gh1076-settings'/file
 if file=='malformed.json':config.write_text('{ invalid JSON\n')
 e=dict(env,XYZ_DEVICE_CONFIG_PATH=str(config))
 if override is not None:e['XYZ_CI_OPTIMIZED']=override
 c=subprocess.run(['python3','utils/py/device_config.py','--ci'],cwd=repo,env=e,capture_output=True,text=True)
 r=subprocess.run(['bash','utils/ci-route.sh','push'],cwd=repo,env=e,input=path,capture_output=True,text=True)
 fields=dict(x.split('=',1) for x in r.stdout.splitlines() if '=' in x)
 controls.append(dict(observation=label,config=json.loads(c.stdout),config_rc=c.returncode,router_rc=r.returncode,router={k:fields.get(k) for k in ['tier','hosted_gate','profile_enabled','profile_candidate']}))
on=dict(env,XYZ_DEVICE_CONFIG_PATH=str(root/'gh1076-settings/on.json'))
r=subprocess.run(['bash','utils/ci-route.sh','push'],cwd=repo,env=on,input='utils/py/wave_reconcile.py\nutils/py/device_config.py\n',capture_output=True,text=True)
large=dict(x.split('=',1) for x in r.stdout.splitlines() if '=' in x)
try:w.content_landing_base(str(repo),head);scope='admitted'
except (ValueError,subprocess.SubprocessError) as exc:scope=str(exc)
source='f874fa8d4d69e2db4f56a8863e6de9b61275842c'
old=repo/'TESTS-RESULTS/2026-10-15+GH-1076/disabled-profile'
rows=[json.loads(x) for x in (old/'proposed-validation-bundle.jsonl').read_text().splitlines()];phases=[]
for row,(name,gate,suites,extra) in zip(rows,w.content_profile_phases(str(repo),source)):
 raw=row['telemetry_utf8'].encode();summary=w.qualification_summary(raw,source,suites,extra,strict=True)
 phases.append(dict(phase=name,gate=gate,original_sha256=hashlib.sha256(raw).hexdigest(),hash_matches=hashlib.sha256(raw).hexdigest()==row['telemetry_sha256'],run=summary['run'],passed=summary['passed'],total=summary['total'],strict_summary_accepted=True))
# Inspect the legacy generic outcome predicate on the new nested outcome shape only.
# This is not written to any production evidence path or presented as passing PR evidence.
shape={'schema_version':'wave-qualification@2','qualification':{'result':'pass','rc':0}}
outcomes=[shape[k] for k in ('result','status') if k in shape]
legacy_accepts=(bool(outcomes) or 'rc' in shape) and all(isinstance(v,str) and v in ('pass','passed','PASS') for v in outcomes)
if 'rc' in shape:legacy_accepts=legacy_accepts and type(shape['rc']) is int and shape['rc']==0
fingerprint=w.qualification_environment(str(repo),head)
report=dict(timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),consumer=head,kind='Unregistered manual observation; no new tests, suite runs, installs, remote actions or live optimized qualification',config_controls=controls,large_change_router={k:large.get(k) for k in ['tier','hosted_gate','profile_enabled','profile_candidate']},current_commit_raw_scope=scope,historical_original_phase_replay=phases,historical_limit='Actual original bytes at f874, not current-source execution, not an @2 receipt, not a combined run',legacy_generic_accepts_nested_outcome=bool(legacy_accepts),environment_fingerprint=fingerprint,global_settings_written=False)
(out/'manual-observations.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['config_controls','large_change_router','current_commit_raw_scope','historical_original_phase_replay','legacy_generic_accepts_nested_outcome']},indent=2))
