#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"sandboxed suite payloads rejected; syntax-only and unsandboxed controls allowed"}
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/relay-automation/hooks/gh177-sandbox-test-guard.sh" <<'PY'
import json, subprocess, sys
hook = sys.argv[1]
blocked = ['./validate.sh', 'bash test/gh177-sandbox-test-guard.sh', 'command bash test/gh177-sandbox-test-guard.sh',
           'env VAR=x bash test/gh177-sandbox-test-guard.sh', 'exec ./validate.sh', 'time ./validate.sh',
           'nohup ./validate.sh', 'nice ./validate.sh', 'source test/gh177-sandbox-test-guard.sh',
           'cd test && bash gh177-sandbox-test-guard.sh']
allowed = ['bash -n test/gh177-sandbox-test-guard.sh', 'shellcheck test/gh177-sandbox-test-guard.sh',
           'grep validate.sh README.md', 'cd src && bash build.sh',
           'cd test && cd .. && bash build.sh']
for command, expected, unsandboxed in [(x, 2, False) for x in blocked] + [(x, 0, False) for x in allowed] + [('./validate.sh', 0, True)]:
    payload = {'tool_name':'Bash', 'tool_input':{'command':command, 'dangerouslyDisableSandbox':unsandboxed}}
    result = subprocess.run(['bash', hook], input=json.dumps(payload), text=True, capture_output=True)
    assert result.returncode == expected, (command, expected, result.returncode, result.stderr)
    if expected == 2:
        assert 'GH-177 guard: refusing' in result.stderr
    print('PASS', expected, command, 'unsandboxed' if unsandboxed else '')
# Pin documented fail-open parse behavior; do not imply adversarial shell completeness.
assert subprocess.run(['bash', hook], input='{invalid', text=True, capture_output=True).returncode == 0
print('PASS: 17 hook cases; example command strings were never executed')
PY
