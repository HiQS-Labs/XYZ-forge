import json, os, subprocess, sys, tempfile
from pathlib import Path
root=Path.cwd()
with tempfile.TemporaryDirectory(prefix='gh1436-') as d:
 p=Path(d); (p/'PROJECT/2-WORKING').mkdir(parents=True)
 (p/'ROADMAP.md').write_text('## Ledger\n\n### Queue / parked intake\n\n- **GH-9001 · probe** 🆕 → [d](PROJECT/2-WORKING/GH-9001-PROBE.md) · [#9001](https://github.com/o/r/issues/9001)\n')
 (p/'states.json').write_text('{"9001":"OPEN"}')
 (p/'branches').write_text('')
 contract={'target':'utils/py/claude-turn.py','gate':'true','fix_probes':[{'type':'path_absent','path':'missing'}],'artifacts':['missing']}
 (p/'PROJECT/2-WORKING/GH-9001-PROBE.md').write_text('---\ntitle: probe\ncomplexity: 1\nrisk: 1\neffort: 1\n---\n## Preflight Contract\n```json\n'+json.dumps(contract)+'\n```\n')
 env=dict(os.environ, QUEUE_PLAN_ROOT=d,QUEUE_PLAN_ROADMAP=str(p/'ROADMAP.md'),QUEUE_PLAN_GH_STATE_FILE=str(p/'states.json'),QUEUE_PLAN_BRANCHES_FILE=str(p/'branches'))
 r=subprocess.run([sys.executable,str(root/'utils/py/marathon_plan.py'),'--format','json'],env=env,text=True,capture_output=True)
 print('command: marathon_plan.py --format json with string target fixture; rc=',r.returncode);print(r.stdout);print(r.stderr)
 if 'AttributeError' not in r.stderr: raise SystemExit('old-code red control not witnessed')
