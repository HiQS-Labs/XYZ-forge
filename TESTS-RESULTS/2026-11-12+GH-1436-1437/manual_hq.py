from pathlib import Path
import json,os,subprocess,tempfile
root=Path.cwd()
with tempfile.TemporaryDirectory(prefix='gh1436-hq-') as d:
 p=Path(d);target=p/'repos/beta-app';subprocess.run(['git','init','-q',str(target)],check=True);subprocess.run(['git','-C',str(target),'remote','add','origin','https://github.com/testorg/beta-app.git'],check=True)
 (target/'.pdda-mode').write_text('observe\n');(target/'PROJECT/1-INBOX').mkdir(parents=True);(target/'utils/pdda').mkdir(parents=True);(target/'utils/pdda/pdda.sh').write_text('#!/bin/sh\nexit 0\n');(target/'ROADMAP.md').write_text('# Roadmap\n## Ledger\n### Queue / parked intake\n')
 registry=p/'pdda';registry.mkdir();(registry/'registry-test.tsv').write_text('beta-app\t2026-07-04T00:00:00Z\tobserve\tabc1234\tyes\n')
 stub=p/'gh';stub.write_text('#!/bin/sh\nif [ "$2" = create ]; then touch "'+str(p/'created')+'"; echo https://github.com/testorg/beta-app/issues/777; else echo "[]"; fi\n');stub.chmod(0o755)
 env=dict(os.environ,HQ_PDDA_REGISTRY_DIR=str(registry),HQ_XYZ_REGISTRY=str(p/'none.tsv'),HQ_REBALANCE_DB=str(p/'none.db'),HQ_SEARCH_ROOTS=str(p/'repos'),HQ_GH_BIN=str(stub))
 for c in [{'target':'bad'},{'target':None},{'fix_probes':['bad']},{'artifacts':[1]},[],None]:
  body='## Preflight Contract\n```json\n'+json.dumps(c)+'\n```\n'
  r=subprocess.run(['bash',str(root/'utils/hq/hq.sh'),'park','--create','--title','shape check','beta-app',body],env=env,capture_output=True,text=True)
  assert r.returncode==1 and 'malformed-contract' in r.stderr,(r.returncode,r.stdout,r.stderr)
  assert not (p/'created').exists() and not list((target/'PROJECT/1-INBOX').iterdir())
  print('PASS HQ rejects before any issue/capture write:',json.dumps(c))
 body='## Preflight Contract\n```json\n{"artifacts":["README.md"]}\n```\n'
 r=subprocess.run(['bash',str(root/'utils/hq/hq.sh'),'park','--title','partial','beta-app',body],env=env,capture_output=True,text=True)
 assert r.returncode==0,(r.stdout,r.stderr)
 print('PASS HQ partial contract preview accepted; no external writes')
