import json, os, subprocess, sys, tempfile
from pathlib import Path
root=Path.cwd();sys.path.insert(0,str(root/'utils/py'))
from _marathon_plan import _unregistered_record, Engine
red='--red' in sys.argv
body='## Preflight Contract\n```json\n{"target":\n```\n'
rec=_unregistered_record(9001,'probe',body,root=root)
assert bool(rec['contractError']) != red,rec
print('PASS issue-body invalid JSON', 'red: error missing' if red else 'green: attributed')
with tempfile.TemporaryDirectory(prefix='gh1436-review-') as d:
 p=Path(d);(p/'PROJECT/2-WORKING').mkdir(parents=True);(p/'utils').mkdir()
 (p/'utils/marathon-plan-zones.default.json').write_bytes((root/'utils/marathon-plan-zones.default.json').read_bytes())
 (p/'branches').write_text('');(p/'states.json').write_text('{"9001":"OPEN"}')
 doc=p/'PROJECT/2-WORKING/GH-9001-PROBE.md';doc.write_text('---\ntitle: probe\ncomplexity: 1\nrisk: 1\neffort: 1\n---\n## Preflight Contract\n```json\n{"target":"bad"}\n```\n')
 env=dict(os.environ,QUEUE_PLAN_ROOT=d,QUEUE_PLAN_ROADMAP=str(p/'ROADMAP.md'),QUEUE_PLAN_GH_STATE_FILE=str(p/'states.json'),QUEUE_PLAN_BRANCHES_FILE=str(p/'branches'))
 for section,state in [('Completed','completed-ref'),('Deferred · vision','deferred')]:
  (p/'ROADMAP.md').write_text('## Ledger\n### '+section+'\n- **GH-9001 · probe** ✅ → [d](PROJECT/2-WORKING/GH-9001-PROBE.md) · [#9001](https://github.com/o/r/issues/9001)\n')
  e=Engine(dict(root=d,roadmap=str(p/'ROADMAP.md'),queue_dir=str(p/'PROJECT/2-WORKING'),today='2026-11-12',now='2026-11-12',policy='quick-wins',format='json',deep=False,require_gh=False,utils_dir=str(p/'utils'),gh_state_file=str(p/'states.json'),branches_file=str(p/'branches')))
  data=e.compute()
  expected='needs-contract' if red else state
  assert data['deduped'][0]['state']==expected,data
  if section=='Completed': assert any('ledger marks this Completed' in f['message'] for f in e.findings) != red,e.findings
  print('PASS',section,'state',expected,'drift retained' if not red else 'old failure witnessed')
