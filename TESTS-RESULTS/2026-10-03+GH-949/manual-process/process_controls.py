#!/usr/bin/env python3
"""GH949 manual witness, not a registered suite. All mutable fixtures belong to --out."""
import argparse
import datetime
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False


def kill_group(pgid):
    if pgid <= 1 or pgid == os.getpgrp():
        raise RuntimeError('refuse unowned supervisor group')
    try:
        os.killpg(pgid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def wait_file(path, proc, seconds=12):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if path.exists() and path.stat().st_size:
            return
        if proc.poll() is not None:
            raise RuntimeError(f'early exit {proc.returncode}: {path}')
        time.sleep(.03)
    raise RuntimeError(f'no readiness witness: {path}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    repo = Path(args.repo).resolve()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=False)
    sha = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
    results = []

    def record(name, command, started, data):
        data.update(case=name, command=command, source_sha=sha, started_utc=started, finished_utc=utc())
        (out / f'{name}.json').write_text(json.dumps(data, indent=2) + '\n')
        with (out / 'provenance.jsonl').open('a') as f:
            f.write(json.dumps(data) + '\n')
        results.append(data)
        print(json.dumps(data), flush=True)

    worker = out / 'cancel_worker.py'
    worker.write_text("import subprocess,sys,os,time,pathlib\n"
                      "child=subprocess.Popen([sys.executable,'-c',\"import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(120)\"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)\n"
                      "time.sleep(.15)\n"
                      "pathlib.Path(sys.argv[1]).write_text(str(child.pid)+' '+str(os.getpgrp()))\n"
                      "child.wait()\n")
    for mode, sig in [('term', signal.SIGTERM), ('int', signal.SIGINT)]:
        started = utc()
        scratch = out / f'{mode}-scratch'
        scratch.mkdir()
        subprocess.run(['git', 'init', '-q', str(scratch)], check=True)
        pidfile = out / f'{mode}.pid'
        log = out / f'{mode}.jsonl'
        prior = json.dumps({'run_id': 'prior-control', 'status': 'pass'}) + '\n'
        log.write_text(prior)
        grid = out / f'{mode}-grid.json'
        grid.write_text(json.dumps(dict(model='unused', message='offline', expects_edits=False,
            variation_keys=['case_id'], case_id=['cancel-probe'],
            command_template=[sys.executable, str(worker), str(pidfile)])))
        cmd = [sys.executable, str(repo / 'utils/ate/scripts/run_variations.py'), '--repo', str(scratch),
               '--variations', str(grid), '--log', str(log), '--control', str(out / f'{mode}-control.json'),
               '--minutes', '1', '--per-variation-timeout', '90', '--mock-classifier']
        p = None
        data = {}
        with (out / f'{mode}.log').open('w') as stream:
            try:
                p = subprocess.Popen(cmd, cwd=repo, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                wait_file(pidfile, p)
                child, pgid = map(int, pidfile.read_text().split())
                data.update(child_pid=child, worker_pgid=pgid, child_live_before=alive(child))
                p.send_signal(sig)
                rc = p.wait(timeout=18)
                rows = [json.loads(line) for line in log.read_text().splitlines() if line]
                inflight = rows[1:]
                data.update(returncode=rc, prior_bytes_preserved=log.read_bytes().startswith(prior.encode()),
                            rows=rows, child_live_after=alive(child))
                data['correct_properties'] = dict(nonzero_exit=rc != 0, prior_preserved=data['prior_bytes_preserved'],
                    child_reaped=not data['child_live_after'], one_interrupted_row=len(inflight) == 1 and
                    (inflight[0].get('classification', {}).get('category') == 'interrupted' or inflight[0].get('interrupted') is True))
            except Exception as exc:
                data['probe_error'] = repr(exc)
            finally:
                if pidfile.exists():
                    child, pgid = map(int, pidfile.read_text().split())
                    kill_group(pgid)
                if p:
                    kill_group(p.pid)
                    p.wait(timeout=4)
                time.sleep(.25)
                data['independent_cleanup_child_absent'] = not pidfile.exists() or not alive(int(pidfile.read_text().split()[0]))
        record(f'ate-cancel-{mode}', cmd, started, data)

    started = utc()
    sentinel = out / 'missing-timeout-sentinel'
    cmd = [sys.executable, str(repo / 'utils/py/proc_group.py'), '--pgid-file', str(out / 'missing-timeout.pgid'), '--',
           sys.executable, '-c', "import pathlib,time; pathlib.Path(%r).write_text('spawned'); time.sleep(120)" % str(sentinel)]
    with (out / 'missing-timeout.log').open('w') as stream:
        p = subprocess.Popen(cmd, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            rc = p.wait(timeout=8)
            time.sleep(.25)
            data = dict(returncode=rc, sentinel_exists=sentinel.exists(),
                        correct_properties=dict(refused=rc != 0, no_spawn=not sentinel.exists()))
        finally:
            pgidfile = out / 'missing-timeout.pgid'
            if pgidfile.exists():
                kill_group(int(pgidfile.read_text()))
            kill_group(p.pid)
            p.wait(timeout=4)
    record('missing-timeout', cmd, started, data)

    # Isolate each oracle observer in its own session. Old implementation children share it;
    # corrected helper children have their own published PGID. Both are independently reaped.
    for kind in ['zero', 'idempotence']:
        started = utc()
        work = out / f'oracle-{kind}-work'
        work.mkdir()
        (work / 'sentinel').write_text('nonempty baseline\n')
        pidfile = out / f'oracle-{kind}.pid'
        marker = work / 'late-write'
        counter = out / f'oracle-{kind}.counter'
        command_file = out / f'oracle-{kind}-command.py'
        child_code = "import pathlib,time; time.sleep(3); pathlib.Path(%r).write_text('late write')" % str(marker)
        command_file.write_text("import pathlib,subprocess,sys,time,os\n"
            + ("counter=pathlib.Path(%r)\nif not counter.exists():\n counter.write_text('first'); sys.exit(0)\n" % str(counter) if kind == 'idempotence' else '')
            + "c=subprocess.Popen([sys.executable,'-c',%r],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)\n" % child_code
            + "pathlib.Path(%r).write_text(str(c.pid)+' '+str(os.getpgid(c.pid)))\ntime.sleep(120)\n" % str(pidfile))
        output = out / f'oracle-{kind}-result.json'
        observer = out / f'oracle-{kind}-observer.py'
        observer.write_text("import sys,json,pathlib\nsys.path.insert(0,%r)\nimport domain_oracles as d\n" % str(repo / 'utils/py')
            + "data={'positive':d.check_zero_state([sys.executable,'-c','pass'],%r,timeout=2)}\ntry:\n" % str(work)
            + (" data['result']=d.check_zero_state([sys.executable,%r],%r,timeout=1)\n" % (str(command_file), str(work)) if kind == 'zero' else
               " data['result']=d.check_idempotence_oracle([sys.executable,%r],%r,repetitions=3,timeout=1)\n" % (str(command_file), str(work)))
            + "except BaseException as exc:\n data['error']=type(exc).__name__+': '+str(exc)\n"
            + "pathlib.Path(%r).write_text(json.dumps(data))\n" % str(output))
        cmd = [sys.executable, str(observer)]
        data = {}
        with (out / f'oracle-{kind}.log').open('w') as stream:
            p = subprocess.Popen(cmd, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                rc = p.wait(timeout=20)
                data = json.loads(output.read_text())
                # Observe the delayed mutation beyond the child's declared deadline.
                time.sleep(3.3)
                data.update(returncode=rc, late_write=marker.exists())
                data['correct_properties'] = dict(positive_pass=data['positive']['passed'], no_late_write=not marker.exists(),
                    incomplete_not_pass=data.get('result', {}).get('passed') is False,
                    structured_result='result' in data)
            except Exception as exc:
                data['probe_error'] = repr(exc)
            finally:
                if pidfile.exists():
                    child, pgid = map(int, pidfile.read_text().split())
                    kill_group(pgid)
                kill_group(p.pid)
                p.wait(timeout=4)
                time.sleep(.25)
                data['independent_cleanup_child_absent'] = not pidfile.exists() or not alive(int(pidfile.read_text().split()[0]))
        record(f'oracle-{kind}', cmd, started, data)
    started = utc()
    positive_script = out / 'bounded-positive.py'
    positive_output = out / 'bounded-positive-result.json'
    positive_script.write_text("import sys,json,pathlib\nsys.path.insert(0,%r)\nfrom proc_group import run_bounded\n" % str(repo / 'utils/py')
        + "a=run_bounded([sys.executable,'-c','print(123)'],timeout=2,grace=.1)\n"
        + "b=run_bounded([sys.executable,'-c','raise SystemExit(124)'],timeout=2,grace=.1)\n"
        + "c=run_bounded([sys.executable,'-c','import time;time.sleep(10)'],timeout=.2,grace=.1)\n"
        + "pathlib.Path(%r).write_text(json.dumps({'normal':vars(a),'own124':vars(b),'timeout':vars(c)}))\n" % str(positive_output))
    cmd = [sys.executable, str(positive_script)]
    with (out / 'bounded-positive.log').open('w') as stream:
        subprocess.run(cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=8, check=True)
    data = json.loads(positive_output.read_text())
    data['correct_properties'] = dict(normal=data['normal']['rc'] == 0 and not data['normal']['timed_out'],
        own124_not_timeout=data['own124']['rc'] == 124 and not data['own124']['timed_out'],
        real_timeout=data['timeout']['rc'] is None and data['timeout']['timed_out'])
    record('bounded-positive', cmd, started, data)
    (out / 'summary.json').write_text(json.dumps(results, indent=2) + '\n')


if __name__ == '__main__':
    main()
