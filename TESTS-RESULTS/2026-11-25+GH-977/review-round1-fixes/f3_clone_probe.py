import json, os, subprocess, sys, tempfile
from pathlib import Path
root = Path.cwd().resolve()
probe = root / os.environ["PROBE_REL"]
assert probe.is_file()
scratch = root / 'temp'
scratch.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='qa977-connectors-', dir=scratch) as raw:
    work = Path(raw).resolve()
    assert work.is_relative_to(root)
    home = work / 'home'; home.mkdir()
    config = work / 'device.json'
    config.write_text(json.dumps({'work_connectors': {'github_board': {
        'enabled': True, 'project_owner': 'offline', 'project_number': 1,
        'repos': ['offline/fixture']}}}))
    log = work / 'events.jsonl'
    fake = work / 'offline_connector.py'
    fake.write_text('import json,os,sys\n'
        'batch=json.load(sys.stdin)\n'
        'with open(os.environ["QA977_LOG"],"a") as f: f.write(json.dumps(batch)+"\\n")\n'
        'print("advanced_to: %s" % max(e["id"] for e in batch["events"]))\n')
    empty_git_config = work / 'gitconfig'; empty_git_config.write_text('')
    env = {'PATH': os.environ['PATH'], 'HOME': str(home), 'TMPDIR': str(work),
        'PYTHONDONTWRITEBYTECODE': '1', 'XYZ_DEVICE_CONFIG_PATH': str(config),
        'XYZ_WORK_CONNECTORS': '1', 'QA977_LOG': str(log),
        'XYZ_WORK_CONNECTORS_REGISTRY': json.dumps({'github_board': str(fake)}),
        'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': str(empty_git_config),
        'GIT_TERMINAL_PROMPT': '0', 'GH_CONFIG_DIR': str(home / 'gh')}
    run = subprocess.run([sys.executable, '-B', str(probe)], cwd=root,
        env=env, capture_output=True, text=True, timeout=120)
    events = [e for line in (log.read_text().splitlines() if log.exists() else [])
        for e in json.loads(line)['events']]
    print('readiness_rc=', run.returncode, 'connector_events=', len(events), [e.get('gh_number') for e in events][:5])
    print(run.stdout[-200:], run.stderr[-300:])
    raise SystemExit(1 if events else 0)
