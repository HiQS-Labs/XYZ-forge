import importlib.util, pathlib, tempfile, subprocess, json, os, sys
from unittest.mock import patch
root=pathlib.Path.cwd(); spec=importlib.util.spec_from_file_location('scan',root/'skills/2-daily/merge-cleanup/scripts/scan_clones.py'); s=importlib.util.module_from_spec(spec); spec.loader.exec_module(s)
w=pathlib.Path(tempfile.mkdtemp(prefix='gh1247-probe-'))
def git(p,*args):
 r=subprocess.run(['git','-C',str(p),*args],capture_output=True,text=True,check=True); return r.stdout.strip()
origin=w/'origin.git'; subprocess.run(['git','init','--bare','-q',str(origin)],check=True)
r=w/'clone'; subprocess.run(['git','clone','-q',str(origin),str(r)],check=True)
git(r,'config','user.email','fixture@example.test');git(r,'config','user.name','Fixture');git(r,'checkout','-b','development');git(r,'commit','--allow-empty','-m','base');git(r,'push','-q','origin','development')
git(r,'checkout','-b','archive');git(r,'commit','--allow-empty','-m','archive');git(r,'tag','archive/light');git(r,'tag','-a','archive/annotated','-m','annotation');git(r,'push','-q','origin','--tags');git(r,'checkout','development');git(r,'update-ref','-d','refs/heads/archive')
with patch.object(s,'merged_pr_index',return_value={'ok':True,'by_head':{},'truncated':False}):
 good=s.classify_local_refs(r); print('remote-identical',json.dumps(good))
 git(r,'tag','local-only','archive/light')
 local=s.classify_local_refs(r); print('local-only',json.dumps(local))
 git(r,'tag','-d','local-only');git(r,'tag','-f','archive/light','development')
 different=s.classify_local_refs(r); print('different',json.dumps(different))
 real=s.run_git
 def fail(p,args,**kw):
  if args and args[0]=='ls-remote':return subprocess.CompletedProcess(args,1,'','fixture query failed')
  return real(p,args,**kw)
 with patch.object(s,'run_git',side_effect=fail):
  failed=s.classify_local_refs(r); print('lookup-failure',json.dumps(failed))
# Simulate deployed source path, with no inherited PATH/override or host config.
deployed=w/'deployed/merge-cleanup/scripts/scan_clones.py';deployed.parent.mkdir(parents=True);deployed.touch()
h=w/'maintained';(h/'bin').mkdir(parents=True);(h/'bin/tick').write_text('#!/bin/sh\nprintf \'[]\\n\'\n');(h/'bin/tick').chmod(0o755)
subprocess.run(['git','init','-q',str(h)],check=True); git(h,'remote','add','origin','https://github.com/HiQS-Labs/XYZ-forge.git')
c=w/'config/xyz';c.mkdir(parents=True);(c/'harness').write_text(str(h)+'\n')
with patch.object(s,'__file__',str(deployed)),patch.dict(os.environ,{'HOME':str(w/'home'),'XDG_CONFIG_HOME':str(w/'config'),'PATH':'','XYZ_HARNESS':str(h)},clear=True):
 env_tick=s._tick_binary(); print('tick-env',env_tick); os.environ.pop('XYZ_HARNESS')
 with patch.object(s,'run_git',side_effect=lambda p,a,**kw: subprocess.CompletedProcess(a,0,'https://github.com/HiQS-Labs/XYZ-forge.git\n','')):
  config_tick=s._tick_binary(); print('tick-config',config_tick)
 (c/'harness').unlink(); missing=s._tick_binary(); print('tick-missing',missing)
if '--expect-fixed' in sys.argv:
 assert good['ok'] and not good['unlanded'] and len(good['landed']) == 3, good
 assert local['ok'] and len(local['unlanded']) == 1 and 'local-only' in local['unlanded'][0], local
 assert different['ok'] and len(different['unlanded']) == 1 and 'archive/light' in different['unlanded'][0], different
 assert not failed['ok'] and failed['failed_query'], failed
 assert env_tick == config_tick == str(h/'bin/tick') and missing is None
 print('ALL FIXED CONTROLS PASS')
