"""Recorded manual falsifiers (GH-831); no suite/registry admission.
Run from repo root: python3 TESTS-RESULTS/2026-09-30+GH-901/manual_probe.py
Only synthetic temporary snapshots are touched.
"""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "skills/3-weekly/task-sync/scripts"
sys.path.insert(0, str(SCRIPTS))
import core
from adapters.codex import CodexAdapter

now = time.time()
row = {"id": "one", "kind": "codex", "hostId": "local", "title": "Investigate sidebar",
       "updatedAt": now}
seed = {"captured_at": now, "activity_at": {"one": now - 100}, "state": {
    "threads": [row], "pinnedThreads": [], "sections": [
        {"sectionId": "chats", "itemKeys": ["codex:thread:local:one"]}]}}
checks = []
with tempfile.TemporaryDirectory(prefix="gh901-manual-") as sandbox:
    snapshot = Path(sandbox) / "snapshot.json"
    def plan(data, **kwargs):
        snapshot.write_text(json.dumps(data))
        return CodexAdapter(str(snapshot), "heartbeat").sweep(**kwargs)
    def check(name, truth):
        assert truth, name
        checks.append(name)
    def refused(name, data):
        try:
            plan(data)
        except core.AdapterError:
            checks.append(name)
        else:
            raise AssertionError(name)
    report = plan(seed)
    check("nonempty plan renames and pins", report['swept'] == 1 and len(report['renamed']) == 1 and len(report['pinned']) == 1)
    desired = report['renamed'][0]['new']
    stamped = copy.deepcopy(seed)
    stamped['state']['threads'][0]['title'] = desired
    stamped['state']['pinnedThreads'] = stamped['state']['threads']
    stamped['state']['threads'] = []
    stamped['state']['sections'][0]['sectionId'] = 'pinned'
    repeat = plan(stamped)
    check("idempotent titles and pins", not repeat['renamed'] and not repeat['pinned'])
    long = copy.deepcopy(seed); long['state']['threads'][0]['title'] = 'A' * 150
    check("full descriptive wording retained", plan(long)['renamed'][0]['new'].endswith('A'*150))
    old = copy.deepcopy(seed); old['activity_at']['one'] = now - 90000
    check("metadata-only update cannot renew activity", plan(old)['swept'] == 0)
    check("no-pin flag", not plan(seed, pin=False)['pinned'])
    check("pin-window independent of sweep", not plan(seed, pin_hours=0.01)['pinned'])
    for kind, host in [('chatgpt','local'), ('codex','durable')]:
        excluded = copy.deepcopy(seed); excluded['state']['threads'][0].update(kind=kind,hostId=host)
        check(f"exclude {kind}/{host}", plan(excluded)['swept'] == 0)
    grouped = copy.deepcopy(seed); grouped['state']['sections'][0]['sectionId'] = 'custom'
    check("custom grouping preserved", plan(grouped)['swept'] == 0)
    excluded = copy.deepcopy(seed); excluded['state']['threads'][0]['id'] = 'heartbeat'; excluded['state']['sections'][0]['itemKeys'] = ['codex:thread:local:heartbeat']
    check("heartbeat excluded", plan(excluded)['swept'] == 0)
    bare = copy.deepcopy(seed); bare['state']['threads'][0]['title'] = '09-29'
    check("bare date never stacked", not plan(bare)['renamed'])
    for name, alter in [
        ('empty inventory refused', lambda d: d['state'].update(threads=[])),
        ('missing actual activity refused', lambda d: d.update(activity_at={})),
        ('stale capture refused', lambda d: d.update(captured_at=now-301)),
        ('duplicate ID refused', lambda d: d['state']['threads'].append(dict(row))),
        ('milliseconds refused', lambda d: d['activity_at'].update(one=now*1000)),
        ('NaN refused', lambda d: d['activity_at'].update(one=float('nan'))),
        ('boolean refused', lambda d: d['activity_at'].update(one=True)),
        ('ambiguous grouping refused', lambda d: d['state']['sections'].append({'sectionId':'other','itemKeys':['codex:thread:local:one']})),
        ('pin-state disagreement refused', lambda d: d['state']['sections'][0].update(sectionId='pinned')),
    ]:
        altered = copy.deepcopy(seed); alter(altered); refused(name, altered)
    snapshot.write_text('{')
    try:
        CodexAdapter(str(snapshot), 'heartbeat').doctor()
    except core.AdapterError:
        checks.append('invalid JSON refused')
    else:
        raise AssertionError('invalid JSON')
    # Witness a red assertion by removing the rename proposal from the guarded result.
    broken = copy.deepcopy(report); broken['renamed'] = []
    try:
        assert len(broken['renamed']) == 1
    except AssertionError:
        checks.append('red control: deleted rename trips nonempty-plan assertion')
    else:
        raise AssertionError('decorative assertion')
    for extra in [ ['--apply'], ['--set-title','one','Title'], ['--group','G'], ['--unpin-days','1'], ['--hours','nan'] ]:
        run = subprocess.run([sys.executable,str(SCRIPTS/'task_sync.py'),'--ide','zcode,codex',
                              '--codex-snapshot',str(snapshot),'--exclude-thread','heartbeat',*extra],capture_output=True,text=True)
        check(f"mixed preflight {extra[0]}", run.returncode == 2 and not run.stdout and 'Traceback' not in run.stderr)
    check('existing core default preserved', len(core.clean_base('A'*150)) == core.MAX_BASE)
print(json.dumps({'passed': len(checks), 'checks': checks}, indent=2))
