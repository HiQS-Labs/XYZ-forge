"""Recorded manual public-boundary control; no provider call or test-suite entry."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

repo = Path.cwd()
(repo / 'temp').mkdir(exist_ok=True)
work = Path(tempfile.mkdtemp(prefix='consult-admission-', dir=repo / 'temp'))
fixture = work / 'fixture'
fixture.mkdir()
subprocess.run(['git', 'init', '-q', str(fixture)], check=True)
(fixture / 'sample.py').write_text('pass\n')
subprocess.run(['git', 'add', 'sample.py'], cwd=fixture, check=True)
subprocess.run(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                'commit', '-qm', 'fixture'], cwd=fixture, check=True)
stub = work / 'advisor'
stub.write_text('''#!/usr/bin/env python3
import pathlib,sys
answer='[Pass] sample.py:1 final answer.'
if '--output-last-message' in sys.argv:
 pathlib.Path(sys.argv[sys.argv.index('--output-last-message')+1]).write_text(answer+'\\n')
print('Prompt echo [Pass]\\nTRANSCRIPT_SENTINEL\\nexec log\\ntokens used\\n123\\n'+answer)
''')
stub.chmod(0o755)
env = dict(os.environ, CONSULT_ROOT=str(fixture), CODEX_BIN=str(stub), PYTHONDONTWRITEBYTECODE='1')
out = work / 'out'
result = subprocess.run([sys.executable, str(repo / 'utils/py/consult.py'), '--prompt',
    'Inspect sample.py and cite its line.', '--models', 'codex', '--out', str(out),
    '--label', 'admission'], cwd=fixture, env=env, capture_output=True, text=True, timeout=60)
answers = list(out.rglob('answer-A.md'))
assert result.returncode == 0 and len(answers) == 1, 'nonempty successful answer required'
answer = answers[0].read_text()
assert answer.strip() == '[Pass] sample.py:1 final answer.', 'final content/citation only; no false warning'
assert any('TRANSCRIPT_SENTINEL' in p.read_text(errors='replace')
           for p in out.rglob('*') if p.is_file() and p != answers[0]), 'raw diagnostics must be retained separately'
