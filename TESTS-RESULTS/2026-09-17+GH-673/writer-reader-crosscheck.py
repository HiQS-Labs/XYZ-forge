"""Bounded synthetic comparison; no live GitHub or source ledgers."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time

reader = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(reader))
from src.flightdeck.connectors import read_xyz_work
from src.flightdeck.contract import ConnectorConfig

parser = argparse.ArgumentParser()
parser.add_argument('--writer-root', required=True)
args = parser.parse_args()
writer = Path(args.writer_root).resolve()
spec = importlib.util.spec_from_file_location('writer_fixture', writer / 'test/gh646_status_label.py')
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
case = fixture.StatusLabelTests()
case.setUp()
try:
    config = ConnectorConfig(None, None, None, None, None, frozenset(), xyz_roots=(Path(case.fx.root),))
    def observe(expected, cleanup=False, label=None):
        db = Path(case.fx.db)
        before = db.read_bytes()
        batch = read_xyz_work(config, time.monotonic() + 3)
        assert db.read_bytes() == before
        assert batch['source']['availability'] == 'ok', batch['source']
        assert len(batch['issues']) == 1, batch['issues']
        native = case.native.issue()
        issue = {'number': 646, 'state': native['state'], 'state_reason': native.get('state_reason'),
                 'labels': [label['name'] for label in native['labels']], 'native_identity_valid': True,
                 'fetched_at': fixture.app.now_iso(), 'work_evidence': batch['issues'][0]['work_evidence']}
        program = "import {issueStatus} from './web/flightdeck/issue-context.mjs'; let text=''; for await(const chunk of process.stdin) text+=chunk; console.log(JSON.stringify(issueStatus(JSON.parse(text))));"
        result = subprocess.run(['node', '--input-type=module', '-e', program], cwd=reader,
                                input=json.dumps(issue), text=True, capture_output=True, check=True)
        status = json.loads(result.stdout)
        assert status['kind'] == expected, status
        if label:
            assert status['label'] == label, status
        if cleanup:
            assert 'cleanup pending' in status['reason'], status
        print(json.dumps({'phase': expected, 'label': status['label'], 'reason': status['reason'],
                          'nonempty_rows': len(batch['issues']), 'source_bytes_unchanged': True}))
    case.start()
    case.project()
    observe('in-progress')
    case.native.issue()['state'] = 'closed'
    case.native.issue()['state_reason'] = 'completed'
    observe('closed', cleanup=True, label='Completed')
    case.fx.update(section='Completed')
    case.project()
    observe('closed', label='Completed')
    case.native.issue()['state'] = 'open'
    case.project()
    observe('context')
    case.start()
    case.project()
    observe('in-progress')
    case.native.issue()['state'] = 'closed'
    case.native.issue()['state_reason'] = 'not_planned'
    observe('closed', cleanup=True, label='Cancelled')
    case.fx.update(section='Deferred · vision')
    case.project()
    observe('closed', label='Cancelled')
finally:
    case.tearDown()
