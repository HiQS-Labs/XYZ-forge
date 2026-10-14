# One-off manual verification input

Executed only in the disposable full gate clone with `PYTHONDONTWRITEBYTECODE=1 python3 temp/manual-1044.py`. Not a registered suite.

```python
import importlib.util, json, sqlite3, shutil, subprocess, sys, tempfile, types
from contextlib import ExitStack
from pathlib import Path
from unittest.mock import patch

root=Path.cwd().resolve(); subject=root/'skills/3-weekly/weekly-planner/scripts/planner_core.py'
spec=importlib.util.spec_from_file_location('planner_core',subject); candidate=importlib.util.module_from_spec(spec);sys.modules['planner_core']=candidate;spec.loader.exec_module(candidate)
base_source=subprocess.check_output(['git','show','b706ac89f1695a314a14c4aaba70bc0bc83d5874:skills/3-weekly/weekly-planner/scripts/planner_core.py'],text=True)
base=types.ModuleType('planner_base');base.__file__=str(subject);exec(compile(base_source,str(subject),'exec'),base.__dict__)
results=[]; repository='HiQS-Labs/XYZ-forge'
cols=['repo_id','gh_number','title','section','position','status_marker','issue_url','rating_pri','rating_sev','rating_appeal','rating_effort','rating_ovr','risk','complexity','effort','status_label','raw_text']
row={'repo_id':1,'gh_number':101,'title':'Repair work','section':'Immediate next-up','position':0,'rating_pri':80,'rating_sev':70,'rating_appeal':60,'rating_effort':90,'risk':4,'issue_url':f'https://github.com/{repository}/issues/101'}
live={101:{'number':101,'title':'Repair work','url':row['issue_url'],'assignees':[{'login':'noelsaw1'}],'labels':[]}}
milestones={'target_release':{'version':'0.6.0'},'manifest_summary':{'dialed_in_numbers':[101]}}

def fixture(rows=(), native=True, cli=False):
    holder=tempfile.TemporaryDirectory(prefix='manual1044-',dir=root/'temp');p=Path(holder.name).resolve();assert p.is_relative_to(root/'temp')
    p.joinpath('.gitignore').write_text('/temp/\n')
    if native:
        shutil.copyfile(root/'releases.db',p/'releases.db')
        c=sqlite3.connect(p/'releases.db');c.execute('DROP TABLE roadmap_items');c.execute('CREATE TABLE roadmap_items ('+', '.join(cols)+')')
        for item in rows:
            c.execute('INSERT INTO roadmap_items VALUES ('+','.join('?' for _ in cols)+')',[item.get(k) for k in cols])
        c.commit();c.close()
    if cli:
        q=p/'utils/py';q.mkdir(parents=True);q.joinpath('releases_app.py').touch()
    return holder,p

def intake(m, rows=(), issues=None, native=True, cli=False, cli_rows=None, force=False):
    holder,p=fixture(rows,native,cli)
    with holder,patch.object(m,'get_open_issues',return_value=live if issues is None else issues),patch.object(m,'get_release_milestones',return_value=milestones),patch.object(m,'run_cmd',return_value=json.dumps(cli_rows if cli_rows is not None else list((live if issues is None else issues).values()))):
        return m.ingest_weekly_intake(p,repository,fallback_mode=force)

def ready(number,title='Implementation',body='',draft=False):
    return {'number':number,'title':title,'body':body,'isDraft':draft,'reviewDecision':'APPROVED','mergeable':'MERGEABLE','headRefName':f'feature-{number}','baseRefName':'development','statusCheckRollup':[{'status':'COMPLETED','conclusion':'SUCCESS'}]}

def zero_open(m):
    x=intake(m,[row],issues={});assert x['roadmap_items']==[] and x['intake_mode']=='native_prs',x

def excluded(m):
    x=intake(m,[dict(row,title='Superseded: do not implement')]);assert x['roadmap_items']==[] and x['intake_mode']=='native_prs',x

def unavailable(m):
    with patch.object(m,'run_cmd',side_effect=RuntimeError('GitHub unavailable')):
        try:m.get_open_issues(root,repository)
        except RuntimeError:return
        raise AssertionError('GitHub failure was converted to empty success')

def receipts(m):
    x=m.detect_merge_sequence([ready(1,body='Validation: qualification receipts attached')]);assert [p['number'] for p in x['ready_to_land']]==[1],x

def dependencies(m):
    x=m.detect_merge_sequence([ready(1,title='[HOLD] prerequisite'),ready(2,body='Depends on #1'),ready(3,body='Depends on #2')]);assert not x['ready_to_land'],x
    daily=m.format_daily_markdown('2026-10-14',{'merge_sequence':x});assert '**P0 ACTION:** Land PR' not in daily,daily

for name,fn in [('live_failure',unavailable),('zero_open',zero_open),('filtered_empty',excluded),('ordinary_receipts',receipts),('held_dependencies',dependencies)]:
    try:fn(base)
    except (AssertionError,RuntimeError,ValueError) as e:results.append({'case':name,'head':'original','verdict':'EXPECTED_FAIL','detail':str(e)[:180]})
    else:raise AssertionError('Original did not witness expected failure: '+name)
    fn(candidate);results.append({'case':name,'head':'candidate','verdict':'PASS'})

x=intake(candidate,[],issues=live);assert x['roadmap_items']==[] and x['intake_mode']=='native_prs';results.append({'case':'authoritative_empty_ledger','verdict':'PASS'})
x=intake(candidate,[row]);t=x['roadmap_items'][0];assert t['prs_score']==300 and t['is_high_risk_gate'] and t['is_release_build'];assert x['teammate_assignments']['Noel']['tasks'][0]['gh_number']==101;results.append({'case':'native_scoring_risk_build_owner','verdict':'PASS'})
x=intake(candidate,native=False,cli=True,cli_rows=[dict(row,rating_ovr=340)]);t=x['roadmap_items'][0];assert t['prs_score']==340 and t['is_high_risk_gate'] and t['is_release_build'];results.append({'case':'cli_scoring_risk_build','verdict':'PASS'})
x=intake(candidate,[dict(row,title='Deferred: vision investment')]);assert not x['roadmap_items'] and x['deferred_items'][0]['gh_number']==101;results.append({'case':'visible_deferred_vision','verdict':'PASS'})
x=intake(candidate,native=False);assert x['intake_mode']=='fallback_scratch' and len(x['roadmap_items'])==1;results.append({'case':'non_native_fallback','verdict':'PASS'})
x=intake(candidate,[row],force=True);assert x['intake_mode']=='fallback_scratch' and len(x['roadmap_items'])==1;results.append({'case':'explicit_fallback','verdict':'PASS'})
for payload in ('', '{}',json.dumps([dict(live[101])]*500)):
    with patch.object(candidate,'run_cmd',return_value=payload):
        try:candidate.get_open_issues(root,repository)
        except (ValueError,RuntimeError):pass
        else:raise AssertionError('Incomplete/invalid GitHub input passed')
results.append({'case':'invalid_or_truncated_github','verdict':'PASS'})
x=candidate.detect_merge_sequence([ready(1,body='Depends on #2'),ready(2,body='Depends on #1'),ready(3)]);assert [p['number'] for p in x['ready_to_land']]==[3];results.append({'case':'cycle_not_landable','verdict':'PASS'})
x=candidate.detect_merge_sequence([ready(2,body='Depends on #1'),ready(1)]);assert [p['number'] for p in x['ready_to_land']]==[1,2];results.append({'case':'ready_dependency_order','verdict':'PASS'})
x=candidate.detect_merge_sequence([dict(ready(1,draft=True),reviewDecision='REVIEW_REQUIRED')]);assert not x['ready_pending_undraft'];results.append({'case':'draft_still_needs_review','verdict':'PASS'})
for item in ({'rating_ovr':401},{'rating_pri':101,'rating_sev':50,'rating_appeal':50,'rating_effort':50}):assert candidate.compute_prs_score(item)==(None,'')
results.append({'case':'rating_bounds','verdict':'PASS'})
# Real read-only release query, without the CLI, excludes cut releases and scopes repo rows.
holder,p=fixture([row]);
with holder,patch.object(candidate,'run_cmd',return_value=''):
    c=sqlite3.connect(p/'releases.db');ids=[r[0] for r in c.execute('SELECT id FROM releases ORDER BY id LIMIT 2')];assert len(ids)==2
    c.execute("UPDATE releases SET status='shipped'");c.execute("UPDATE releases SET status='cut',target_date='2000-01-01' WHERE id=?",(ids[0],));c.execute("UPDATE releases SET status='draft',target_date='2030-01-01' WHERE id=?",(ids[1],));c.commit();c.close()
    info=candidate.get_release_milestones(p,repository);assert info['target_release']['id']==ids[1],info
results.append({'case':'cut_release_not_target','verdict':'PASS'})
holder,p=fixture([row,dict(row,repo_id=2,title='Foreign work')])
with holder,patch.object(candidate,'get_open_issues',return_value=live),patch.object(candidate,'get_release_milestones',return_value=milestones):
    x=candidate.ingest_weekly_intake(p,repository);assert len(x['roadmap_items'])==1 and x['roadmap_items'][0]['title']=='Repair work',x
results.append({'case':'repo_scoped_roadmap','verdict':'PASS'})
holder,p=fixture([row],cli=True)
with holder,patch.object(candidate,'get_open_issues',return_value=live),patch.object(candidate,'get_release_milestones',return_value=milestones),patch.object(candidate,'run_cmd',side_effect=RuntimeError('Native CLI unavailable')):
    p.joinpath('releases.db').write_bytes(b'corrupt fixture')
    try:candidate.ingest_weekly_intake(p,repository)
    except RuntimeError:pass
    else:raise AssertionError('Unavailable native DB and CLI passed')
results.append({'case':'unavailable_native_sources','verdict':'PASS'})
# Witness assertion sensitivity by restoring the original truthiness guard in memory.
mutated=types.ModuleType('planner_mutated');mutated.__file__=str(subject)
source=subject.read_text().replace('if gh_num not in open_issues:', 'if open_issues and gh_num not in open_issues:');assert source!=subject.read_text();exec(compile(source,str(subject),'exec'),mutated.__dict__)
try:zero_open(mutated)
except (AssertionError, KeyError) as e:results.append({'case':'in_memory_truthiness_red_control','verdict':'EXPECTED_FAIL','detail':type(e).__name__})
else:raise AssertionError('Red control did not detect stale candidate')
fixture_input=(root/'TESTS-RESULTS/2026-10-14+GH-1043/manual/original-fixtures.md').read_text().split('```python\n',1)[1].rsplit('```',1)[0]
exec(compile(fixture_input,str(root/'test/test_planner_core.py'),'exec'),{'__name__':'__main__','__file__':str(root/'test/test_planner_core.py')})
results.append({'case':'original_five_fixtures_replayed_in_memory','verdict':'PASS'})
(root/'temp/manual-1044-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(results,indent=2));print('Manual checks complete:',len(results))

```
