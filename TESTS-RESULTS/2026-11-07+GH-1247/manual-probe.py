import importlib.util, pathlib, tempfile, subprocess, json, os, sys
from unittest.mock import patch
root=pathlib.Path.cwd(); spec=importlib.util.spec_from_file_location('scan',root/'skills/2-daily/merge-cleanup/scripts/scan_clones.py'); s=importlib.util.module_from_spec(spec); spec.loader.exec_module(s)
w=pathlib.Path(tempfile.mkdtemp(prefix='gh1247-probe-'))
def git(p,*args):
 r=subprocess.run(['git','-C',str(p),*args],capture_output=True,text=True,check=True); return r.stdout.strip()
origin=w/'origin.git'; subprocess.run(['git','init','--bare','-q',str(origin)],check=True)
r=w/'clone'; subprocess.run(['git','clone','-q',str(origin),str(r)],check=True)
git(r,'config','user.email','fixture@example.test');git(r,'config','user.name','Fixture');git(r,'checkout','-b','development');git(r,'commit','--allow-empty','-m','base');git(r,'push','-q','origin','development')
git(r,'checkout','-b','archive');git(r,'commit','--allow-empty','-m','archive');git(r,'tag','archive/light');git(r,'tag','-a','archive/annotated','-m','annotation');git(r,'push','-q','origin','--tags');git(r,'checkout','development');git(r,'branch','-d','archive') if False else git(r,'update-ref','-d','refs/heads/archive')
with patch.object(s,'merged_pr_index',return_value={'ok':True,'by_head':{},'truncated':False}):
 print('remote-identical',json.dumps(s.classify_local_refs(r)))
 git(r,'tag','local-only','archive/light')
 print('local-only',json.dumps(s.classify_local_refs(r)))
 git(r,'tag','-d','local-only');git(r,'tag','-f','archive/light','development')
 print('different',json.dumps(s.classify_local_refs(r)))
 real=s.run_git
 def fail(p,args,**kw):
  if args and args[0]=='ls-remote':return subprocess.CompletedProcess(args,1,'','fixture query failed')
  return real(p,args,**kw)
 with patch.object(s,'run_git',side_effect=fail):print('lookup-failure',json.dumps(s.classify_local_refs(r)))
# Simulate deployed source path, with no inherited PATH/override or host config.
deployed=w/'deployed/merge-cleanup/scripts/scan_clones.py';deployed.parent.mkdir(parents=True);deployed.touch()
h=w/'maintained';(h/'bin').mkdir(parents=True);(h/'bin/tick').write_text('#!/bin/sh\nprintf \'[]\\n\'\n');(h/'bin/tick').chmod(0o755)
c=w/'config/xyz';c.mkdir(parents=True);(c/'harness').write_text(str(h)+'\n')
with patch.object(s,'__file__',str(deployed)),patch.dict(os.environ,{'HOME':str(w/'home'),'XDG_CONFIG_HOME':str(w/'config'),'PATH':'','XYZ_HARNESS':str(h)},clear=True):
 print('tick-env',s._tick_binary());os.environ.pop('XYZ_HARNESS');print('tick-config',s._tick_binary());(c/'harness').unlink();print('tick-missing',s._tick_binary())
