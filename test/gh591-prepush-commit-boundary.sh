#!/usr/bin/env bash
# GH-591: witness Git's pre-push file/commit boundary with a real local bare remote.
set -eu
exec python3 -B - <<'PY'
import json
import os
from pathlib import Path
import subprocess
import tempfile

with tempfile.TemporaryDirectory(prefix='gh591-prepush-') as directory:
    work = Path(directory)
    source, remote = work/'source', work/'remote.git'
    env = {k:v for k,v in os.environ.items() if not k.startswith('GIT_')}
    config = work/'gitconfig'
    config.write_text('')
    templates = work/'empty-templates'
    templates.mkdir()
    env.update(GIT_CONFIG_GLOBAL=str(config), GIT_CONFIG_NOSYSTEM='1',
               GIT_TEMPLATE_DIR=str(templates))
    def git(*args, cwd=work):
        return subprocess.check_output(['git', *args], cwd=cwd, env=env,
                                       stderr=subprocess.DEVNULL, text=True).strip()
    git('init', '--bare', str(remote))
    git('init', str(source))
    git('config', 'user.name', 'Fixture', cwd=source)
    git('config', 'user.email', 'fixture@example.invalid', cwd=source)
    (source/'source').write_text('tested source\n')
    git('add', 'source', cwd=source)
    git('commit', '-m', 'tested source', cwd=source)
    tested = git('rev-parse', 'HEAD', cwd=source)
    hook = source/'.git/hooks/pre-push'
    hook.parent.mkdir(parents=True, exist_ok=True)
    hook.write_text('#!/bin/sh\nprintf "hook receipt\\n" > provenance.jsonl\n')
    hook.chmod(0o755)
    git('push', str(remote), 'HEAD:refs/heads/main', cwd=source)
    assert (source/'provenance.jsonl').read_text() == 'hook receipt\n'
    remote_files = git('--git-dir', str(remote), 'ls-tree', '-r', '--name-only', 'main').splitlines()
    assert remote_files == ['source'], remote_files
    assert git('--git-dir', str(remote), 'rev-parse', 'main') == tested
    # Committing the generated file is a distinct second push, not an amendment by the hook.
    git('add', 'provenance.jsonl', cwd=source)
    git('commit', '-m', 'commit generated fixture receipt', cwd=source)
    git('push', str(remote), 'HEAD:refs/heads/main', cwd=source)
    assert git('--git-dir', str(remote), 'show', 'main:provenance.jsonl') == 'hook receipt'
    print(json.dumps({'first_push_receipt_in_tree': False, 'second_push_receipt_in_tree': True,
                      'result': 'pass'}))
PY
