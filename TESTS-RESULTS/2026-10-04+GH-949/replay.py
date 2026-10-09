"""Recorded manual oracle cancellation controls; not a registered test suite."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys
import time

p = argparse.ArgumentParser()
p.add_argument('--source', required=True)
p.add_argument('--out', required=True)
p.add_argument('--label', required=True)
p.add_argument('--repaired', action='store_true')
a = p.parse_args()
source = Path(a.source).resolve()
out = Path(a.out).resolve()
out.mkdir(parents=True, exist_ok=False)
env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')

def alive(pid):
    r = subprocess.run(['ps', '-o', 'stat=', '-p', str(pid)], capture_output=True, text=True)
    return bool(r.stdout.strip()) and not r.stdout.lstrip().startswith('Z')

rows = []
cases = ['TERM', 'cap'] + (['INT', 'resistant-TERM'] if a.repaired else [])
for module in ['domain_oracles.py', 'metamorphic_oracle.py']:
    for case in cases:
        fixture = out / (module.replace('.py', '') + '-' + case)
        fixture.mkdir()
        ready = fixture / 'ready.json'
        worker = fixture / 'worker.py'
        worker.write_text('import os,json,time,signal\nfrom pathlib import Path\n' +
            ('signal.signal(signal.SIGTERM, signal.SIG_IGN)\n' if case == 'resistant-TERM' else '') +
            f'Path({str(ready)!r}).write_text(json.dumps(dict(pid=os.getpid(),pgid=os.getpgrp())))\n' +
            'time.sleep(40)\n')
        command = shlex.join([sys.executable, str(worker)])
        argv = [sys.executable, str(source / module), '--mode', 'idempotence',
                '--cmd', command, '--cwd', str(fixture), '--repetitions', '2', '--json']
        if case == 'cap':
            argv = [sys.executable, str(source / 'proc_group.py'), '--timeout', '2', '--grace', '1', '--'] + argv
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        proc = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, start_new_session=True, env=env)
        child = None
        cleanup_verified = False
        try:
            deadline = time.monotonic() + 8
            while not ready.exists() and time.monotonic() < deadline and proc.poll() is None:
                time.sleep(.02)
            assert ready.exists() and ready.stat().st_size, 'nonempty child startup evidence required'
            child = json.loads(ready.read_text())
            assert child['pid'] > 1 and child['pgid'] > 1
            if case != 'cap':
                os.kill(proc.pid, signal.SIGINT if case == 'INT' else signal.SIGTERM)
            stdout, stderr = proc.communicate(timeout=18)
            time.sleep(.1)
            survived = alive(child['pid'])
            expected_rc = 124 if case == 'cap' else (130 if case == 'INT' else 143)
            # Popen uses negative signal status when the unfixed CLI dies directly.
            actual_rc = 128 - proc.returncode if proc.returncode < 0 else proc.returncode
            rows.append(dict(module=module, case=case, argv=argv, started_utc=started,
                             returncode=proc.returncode, conventional_rc=actual_rc,
                             expected_rc=expected_rc, child=child, child_survived=survived,
                             property_pass=not survived and actual_rc == expected_rc,
                             stdout=stdout, stderr=stderr))
        finally:
            if child:
                try: os.killpg(child['pgid'], signal.SIGKILL)
                except ProcessLookupError: pass
            try: os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError: pass
            if proc.poll() is None: proc.communicate(timeout=5)
            deadline = time.monotonic() + 3
            while child and alive(child['pid']) and time.monotonic() < deadline:
                time.sleep(.05)
            cleanup_verified = not child or not alive(child['pid'])
            assert cleanup_verified, 'owned child cleanup failed'
        rows[-1]['cleanup_verified'] = cleanup_verified
        print(f"{a.label}: {module} {case}: rc={rows[-1]['conventional_rc']} child_survived={rows[-1]['child_survived']}", flush=True)

result = dict(label=a.label, source=str(source), rows=rows,
              all_properties_pass=all(r['property_pass'] for r in rows))
(out / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
(out / 'provenance.jsonl').write_text(json.dumps(dict(
    utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    command=shlex.join([sys.executable] + sys.argv), source=str(source),
    result_file='results.json', label=a.label,
    result_sha256=__import__('hashlib').sha256((out/'results.json').read_bytes()).hexdigest())) + '\n')
raise SystemExit(0 if result['all_properties_pass'] else 1)
