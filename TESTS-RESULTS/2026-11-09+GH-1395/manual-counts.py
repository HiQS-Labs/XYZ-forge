"""Offline manual measurement: execute baseline or candidate AST-extracted functions.

No module import, subprocess, network, production DB access or production writes.
Counts stubbed CLI invocations, not actual HTTP calls or GitHub quota consumption.
"""
import sys
import ast
import collections
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
from types import SimpleNamespace

source = Path(sys.argv[1])
text = source.read_text()
names = {'cmd_roadmap_reconcile_state', 'read_native_issue', 'read_issue_closure_state', 'read_native_open_inventory', 'validate_native_issue'}
tree = ast.Module(body=[n for n in ast.parse(text).body if isinstance(n, ast.FunctionDef) and n.name in names], type_ignores=[])
assert len(tree.body) in (3, 5)

class Refused(Exception):
    pass

def exercise(count, mode='valid'):
    calls = collections.Counter()
    connection = sqlite3.connect(':memory:')
    connection.row_factory = sqlite3.Row
    connection.executescript('CREATE TABLE repos(id INTEGER, slug TEXT); INSERT INTO repos VALUES(1,"example/repo"); CREATE TABLE roadmap_items(global_id TEXT, repo_id INTEGER, gh_number INTEGER, issue_url TEXT, section TEXT);')
    for number in range(1, count + 1):
        connection.execute('INSERT INTO roadmap_items VALUES(?,?,?,?,?)', (str(number), 1, number, f'https://github.com/example/repo/issues/{number}', 'In progress'))

    def cli(argv, **kwargs):
        assert argv[0] == 'gh', argv
        if argv[1] == 'api':
            calls['native_rest_cli'] += 1
            if '?' in argv[2]:
                calls['inventory_pages'] += 1
                page = int(argv[2].split('page=')[2].split('&')[0])
                if mode == 'page_failure' or mode == 'second_page_failure' and page == 2:
                    return SimpleNamespace(returncode=1, stdout='', stderr='controlled page failure')
                data = [{'number': n, 'html_url': f'https://github.com/example/repo/issues/{n}', 'state': 'open', 'labels': []} for n in range(1, count + 1) if n not in (1,3)]
                data = data[(page-1)*100:page*100]
                if mode == 'sparse': data = []
                if mode == 'malformed_page': data = {}
                if mode == 'duplicate_page' and data: data.append(data[0])
                if mode == 'missing_number' and data: del data[0]['number']
                if mode == 'wrong_repo' and data: data[0]['html_url'] = 'https://github.com/other/repo/issues/2'
                if mode == 'inventory_pr' and data: data[0]['pull_request'] = {}
                if mode == 'changed_open' and data: pass
                return SimpleNamespace(returncode=0, stdout=json.dumps(data), stderr='')
            number = int(argv[2].rsplit('/', 1)[1])
            data = {'number': number, 'html_url': f'https://github.com/example/repo/issues/{number}', 'state': 'closed' if number in (1, 3) else 'open', 'state_reason': 'completed' if number == 1 else 'not_planned' if number == 3 else None, 'labels': []}
            if mode == 'pull_request':
                data['pull_request'] = {}
        else:
            assert argv[1:3] == ['issue', 'view'], argv
            calls['closure_view_cli'] += 1
            number = int(argv[3].rsplit('/', 1)[1])
            data = {'state': 'CLOSED' if number in (1, 3) else 'OPEN', 'stateReason': 'COMPLETED' if number == 1 else 'NOT_PLANNED' if number == 3 else None}
            if mode == 'unknown_reason':
                data['stateReason'] = None
            if mode == 'changed_open' and number == 2:
                data = {'state': 'CLOSED', 'stateReason': 'COMPLETED'}
            if mode == 'changed_between_reads':
                data['state'] = 'OPEN'
        return SimpleNamespace(returncode=0, stdout=json.dumps(data), stderr='')

    def refused(rule, message):
        raise Refused(rule + ': ' + message)

    def no_write(*args, **kwargs):
        raise AssertionError('dry run attempted write')

    env = {
        'os': SimpleNamespace(environ={}), 'subprocess': SimpleNamespace(run=cli, TimeoutExpired=subprocess.TimeoutExpired),
        'json': json, 'GH_ISSUE_URL_RE': re.compile(r'https://github.com/[^/]+/[^/]+/issues/[0-9]+'),
        'resolve_root': lambda x: x, 'artifact_paths': lambda x: {'db': ':memory:'},
        'connect': lambda x: connection, '_table_exists': lambda *x: True,
        'validate_roadmap_section': lambda x: x, '_origin_repo_identity': lambda x: 'example/repo',
        'resolve_roadmap_identity': lambda row, repos, origin: {'repo': 'example/repo', 'identity_valid': True},
        'refuse': refused, 'perform_write': no_write,
    }
    exec(compile(tree, str(source), 'exec'), env)
    result = 'PASS'
    output = io.StringIO()
    try:
        with contextlib.redirect_stdout(output):
            env['cmd_roadmap_reconcile_state'](SimpleNamespace(root='/unused', apply=False))
    except Refused as exc:
        result = str(exc)
    return {'rows': count, 'mode': mode, 'calls': dict(calls), 'result': result, 'output': output.getvalue()}

results = [exercise(4), exercise(90), exercise(220), exercise(90,'sparse')]
results += [exercise(90,m) for m in ('pull_request','unknown_reason','changed_between_reads','changed_open','page_failure','malformed_page','duplicate_page','wrong_repo','inventory_pr','missing_number')]
new = len(tree.body) == 5
assert results[0]['calls']['native_rest_cli'] == 4
assert results[1]['calls']['native_rest_cli'] == (3 if new else 90)
assert results[2]['calls']['native_rest_cli'] == (22 if new else 220)
assert results[3]['calls']['native_rest_cli'] == (91 if new else 90)
for r in results[4:]:
    if new or r['mode'] in ('pull_request','unknown_reason','changed_between_reads','changed_open'):
        assert r['result'].startswith('roadmap-issue-state:'), r
for count in (9,10,102,202):
    boundary = exercise(count)
    assert boundary['result'] == 'PASS'
    assert boundary['calls']['native_rest_cli'] == (count if not new or count < 10 else 3 if count < 102 else 4)
    results.append(boundary)
if new:
    second = exercise(220,'second_page_failure')
    assert second['result'].startswith('roadmap-issue-state:')
    assert second['calls']['native_rest_cli'] == 2 and 'closure_view_cli' not in second['calls']
    results.append(second)
print(json.dumps({'kind':'offline actual function execution with stubbed CLI; NOT HTTP measurement','source_sha256':hashlib.sha256(text.encode()).hexdigest(),'results':results},indent=2))
