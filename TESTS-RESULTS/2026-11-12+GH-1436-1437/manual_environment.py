from pathlib import Path
import os,subprocess,sys,tempfile
root=Path.cwd();text=(root/'validate.sh').read_text();block=text[text.index('# GH-732 environment faults BEGIN'):text.index('# GH-732 environment faults END')]
assert block and 'python3' in block
with tempfile.TemporaryDirectory(prefix='gh1437-') as d:
 p=Path(d);script=p/'block.sh';script.write_text(block+'\necho SUITES_WOULD_START\n')
 for name,fail in [('old-python','version'),('missing-yaml','yaml'),('missing-pytest','pytest'),('missing-requests','requests'),('healthy',None)]:
  b=p/name;b.mkdir();shim=b/'python3'
  shim.write_text('#!/usr/bin/env python3\n') if False else None
  code='#!/bin/sh\n'
  if fail=='version':code+='case "$2" in *version_info*print*) echo 3.9.6; exit 0;; *version_info*) exit 1;; esac\n'
  elif fail:code+='if [ "$1" = -c ] && [ "$2" = "import '+fail+'" ]; then exit 1; fi\n'
  code+='exec "'+sys.executable+'" "$@"\n';shim.write_text(code);shim.chmod(0o755)
  r=subprocess.run(['bash',str(script)],env=dict(os.environ,PATH=str(b)+':'+os.environ['PATH']),capture_output=True,text=True)
  if fail:
   assert r.returncode==3 and r.stdout.count('ENVIRONMENT FAULT: python3')==1 and 'SUITES_WOULD_START' not in r.stdout,(name,r.returncode,r.stdout)
   assert 'PATH="$HOME/.cache/xyz-forge-test-venv/bin:$PATH" bash validate.sh' in r.stdout
  else:assert r.returncode==0 and 'SUITES_WOULD_START' in r.stdout
  print('PASS',name,'rc',r.returncode,r.stdout.strip())
 r=subprocess.run(['/bin/bash',str(root/'validate.sh'),'--print-mode'],env=dict(os.environ,PATH='/usr/bin:/bin'),capture_output=True,text=True)
 assert r.returncode==3 and 'version 3.9.6' in r.stdout and 'ENVIRONMENT FAULT: python3' in r.stdout,(r.returncode,r.stdout,r.stderr)
 print('PASS real Apple Python command: PATH=/usr/bin:/bin bash validate.sh --print-mode rc=3; '+r.stdout.split('ENVIRONMENT FAULT: python3',1)[1].strip())
