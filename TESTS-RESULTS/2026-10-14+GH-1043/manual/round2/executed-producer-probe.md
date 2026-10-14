# Actual producer/consumer manual verification

Executed with `PYTHONDONTWRITEBYTECODE=1 python3 temp/producer-contract-1044.py` in a disposable full clone.

```python
from pathlib import Path
from types import ModuleType
from unittest.mock import patch
import hashlib,json,sqlite3,subprocess
root=Path.cwd();p=root/'skills/3-weekly/weekly-planner/scripts/planner_core.py';m=ModuleType('planner_contract');m.__file__=str(p);exec(compile(p.read_text(),str(p),'exec'),m.__dict__)
live={i['number']:i for i in json.loads(Path('TESTS-RESULTS/2026-10-14+GH-1043/manual/open-issues-snapshot.json').read_text())}
def hashes():return {n:hashlib.sha256(Path(n).read_bytes()).hexdigest() for n in ('releases.db','releases.sql')}
before=hashes();cli_out=subprocess.check_output(['python3','utils/py/releases_app.py','roadmap','list','--json'],text=True);rows=json.loads(cli_out);assert rows and all(k in rows[0] for k in (*m.RATING_COLUMNS,'risk')) if hasattr(m,'RATING_COLUMNS') else rows and 'rating_pri' in rows[0] and 'risk' in rows[0]
with patch.object(m,'get_open_issues',return_value=live):
 milestones=m.get_release_milestones(root,'HiQS-Labs/XYZ-forge');db=m.ingest_weekly_intake(root,'HiQS-Labs/XYZ-forge')
with patch.object(m,'get_open_issues',return_value=live),patch.object(m,'get_release_milestones',return_value=milestones),patch.object(m,'run_cmd',return_value=cli_out),patch.object(sqlite3,'connect',side_effect=sqlite3.OperationalError('controlled direct-reader failure')):
 cli=m.ingest_weekly_intake(root,'HiQS-Labs/XYZ-forge')
for result in (db,cli):
 assert {920,974} <= {i['gh_number'] for i in result['deferred_items']}
 assert not ({920,974} & {i['gh_number'] for i in result['roadmap_items']})
db_map={i['gh_number']:(i['prs_score'],i.get('risk'),i['is_high_risk_gate'],i['is_release_build']) for i in db['roadmap_items']};cli_map={i['gh_number']:(i['prs_score'],i.get('risk'),i['is_high_risk_gate'],i['is_release_build']) for i in cli['roadmap_items']};assert db_map==cli_map,(db_map,cli_map);assert db_map[418][0]==321
# Red controls: remove real producer fields, then remove the canonical deferred-state checks in memory.
bare=[{k:v for k,v in row.items() if k not in {'rating_pri','rating_sev','rating_appeal','rating_effort','rating_ovr','risk'}} for row in rows]
assert any(m.compute_prs_score(row)[0] is not None for row in rows);assert all(m.compute_prs_score(row)[0] is None for row in bare)
mutated=ModuleType('planner_prior');mutated.__file__=str(p);source=p.read_text().replace('section.startswith("deferred") or marker.startswith("⏸")','False');assert source!=p.read_text();exec(compile(source,str(p),'exec'),mutated.__dict__)
with patch.object(mutated,'get_open_issues',return_value=live),patch.object(mutated,'get_release_milestones',return_value=milestones): prior=mutated.ingest_weekly_intake(root,'HiQS-Labs/XYZ-forge')
assert {920,974} <= {i['gh_number'] for i in prior['roadmap_items']},'Deferred red control did not recreate the bug'
assert before==hashes(),'Read-only producer/consumer verification mutated ledger'
out={'verdict':'PASS','actual_cli_rows':len(rows),'exported_metadata_keys':sorted(set(rows[0]) & {'rating_pri','rating_sev','rating_appeal','rating_effort','rating_ovr','risk'}),'db_and_cli_active_count':len(db_map),'db_and_cli_scored_count':sum(v[0] is not None for v in db_map.values()),'GH418_score':db_map[418][0],'canonical_deferred_920_974':'parked in both readers','red_controls':['producer field removal removes scores','canonical-state guard removal returns deferred issues to active work'],'unchanged_ledger_hashes':before};Path('temp/producer-contract-results.json').write_text(json.dumps(out,indent=2)+'\n');Path('temp/actual-roadmap-cli.json').write_text(cli_out);print(json.dumps(out,indent=2))

```
