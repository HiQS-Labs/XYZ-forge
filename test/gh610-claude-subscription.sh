#!/usr/bin/env bash
# GH-610: account routing and result validation; no real account or API calls.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONPATH="$ROOT/utils/py${PYTHONPATH:+:$PYTHONPATH}" python3 - <<'PYTEST'
import json, tempfile, unittest, os, subprocess, sys
from pathlib import Path
from unittest.mock import patch
from proc_group import BoundedResult
from claude_cli import preflight, read_result, resolve_binary

class ClaudeSubscription(unittest.TestCase):
    def probe(self, data=None, rc=0, timed_out=False):
        if data is None: data=dict(loggedIn=True,authMethod="claude.ai",apiProvider="firstParty",subscriptionType="max")
        return BoundedResult(rc, json.dumps(data), "private diagnostic", timed_out, 1, 0.01)
    def test_subscription_account(self):
        with patch('claude_cli.run_bounded',return_value=self.probe()) as run:
            preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription'},'/repo')
            self.assertEqual(run.call_args.args[0],['/cli','auth','status'])
            self.assertEqual(run.call_args.kwargs['cwd'],'/repo')
    def test_missing_binary(self):
        with self.assertRaisesRegex(ValueError,'binary not found'):
            preflight('',{'CLAUDE_AUTH_MODE':'subscription'},'/repo')
    def test_bad_accounts(self):
        good=dict(loggedIn=True,authMethod='claude.ai',apiProvider='firstParty',subscriptionType='max')
        for key,value in [('loggedIn',False),('authMethod','api_key_helper'),('apiProvider','bedrock'),('subscriptionType',None)]:
            with self.subTest(key=key),patch('claude_cli.run_bounded',return_value=self.probe({**good,key:value})):
                with self.assertRaisesRegex(ValueError,'subscription'): preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription'},'/repo')
    def test_overrides_rejected_before_probe(self):
        for key in ('ANTHROPIC_API_KEY','ANTHROPIC_AUTH_TOKEN','ANTHROPIC_BASE_URL','CLAUDE_CODE_USE_BEDROCK','CLAUDE_CODE_USE_VERTEX','CLAUDE_CODE_USE_FOUNDRY'):
            with self.subTest(key=key),patch('claude_cli.run_bounded') as run:
                with self.assertRaises(ValueError): preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription',key:'private-value'},'/repo')
                run.assert_not_called()
    def test_probe_failures(self):
        for result in (self.probe(rc=1),self.probe(timed_out=True),self.probe([]),self.probe('garbage')):
            with patch('claude_cli.run_bounded',return_value=result):
                with self.assertRaises(ValueError): preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription'},'/repo')
        with patch('claude_cli.run_bounded',side_effect=OSError('private diagnostic')):
            with self.assertRaisesRegex(ValueError,'auth status'): preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription'},'/repo')
    def test_legacy_and_invalid_mode(self):
        with patch('claude_cli.run_bounded') as run:
            preflight('/cli',{},'/repo'); run.assert_not_called()
            with self.assertRaises(ValueError): preflight('/cli',{'CLAUDE_AUTH_MODE':'typo'},'/repo')
    def test_results(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'result.json'
            for value,ok in [({'type':'result','is_error':False,'subtype':'success','result':'answer'},True),({'type':'result','is_error':True,'result':'quota exceeded'},False),({'type':'result','is_error':False,'subtype':'error_max_turns','result':'partial'},False),({'type':'result','is_error':False,'result':'partial'},False),({'type':'result','subtype':'success','result':'partial'},False),({'type':'result','result':''},False),([],False)]:
                p.write_text(json.dumps(value))
                if ok: self.assertEqual(read_result(str(p)),'answer')
                else:
                    with self.assertRaises(ValueError): read_result(str(p))
            p.write_text('not json')
            with self.assertRaises(ValueError): read_result(str(p))
    def test_real_probe_and_consult_dispatch(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); repo=root/'repo';repo.mkdir()
            env={k:v for k,v in os.environ.items() if not k.startswith(('ANTHROPIC_','CLAUDE_','CONSULT_'))}
            env.update(HOME=d,CLAUDE_AUTH_MODE='subscription',CONSULT_TIMEOUT='20',CONSULT_IDLE_S='0',XYZ_HARNESS_LOGGING='0',XYZ_WRITE_OPS_LOG='0',CONSULT_ROOT=str(repo),XYZ_DEVICE_CONFIG_PATH='/dev/null')
            for cmd in (['git','init','-q'],['git','config','user.name','Fixture'],['git','config','user.email','fixture@example.invalid']):
                subprocess.run(cmd,cwd=repo,check=True,capture_output=True)
            (repo/'README.md').write_text('fixture\n')
            subprocess.run(['git','add','README.md'],cwd=repo,check=True)
            subprocess.run(['git','commit','-qm','seed'],cwd=repo,check=True)
            cli=root/'claude'; env['CLAUDE_BIN']=str(cli)
            cli.write_text('#!'+sys.executable+'\nimport sys,json,os\n'
                +'if sys.argv[1:]==["auth","status"]: print('+repr(json.dumps(dict(loggedIn=True,authMethod='claude.ai',apiProvider='firstParty',subscriptionType='max')))+')\n'
                +'else:\n assert "Read,Grep,Glob" in sys.argv and "--strict-mcp-config" in sys.argv\n print("workspace trust warning",file=sys.stderr)\n print(json.dumps(dict(type="result",is_error=os.getenv("STUB_ERROR")=="1",subtype="success",result="README.md:1 contains fixture")))\n')
            cli.chmod(0o755)
            preflight(str(cli),env,str(repo))
            import claude_cli
            consult=Path(claude_cli.__file__).with_name('consult.py')
            for error,expected in [('0',0),('1',5)]:
                env['STUB_ERROR']=error
                result=subprocess.run([sys.executable,str(consult),'--models','claude','--prompt','Read README.md','--out',str(root/('out'+error))],cwd=repo,env=env,capture_output=True,text=True,timeout=30)
                self.assertEqual(result.returncode,expected,result.stdout+result.stderr)
            self.assertEqual((repo/'README.md').read_text(),'fixture\n')

unittest.main(verbosity=2)
PYTEST

source "$ROOT/test/_setup.sh" gh610-claude-subscription
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
export CLAUDE_AUTH_MODE=subscription XYZ_PYTHON=1
printf 'STATUS: Open\n' > "$A/relay.md"
git -C "$A" add relay.md
git -C "$A" commit -qm 'seed subscription relay'
tick_a init >/dev/null
cat > "$WORK/claude" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = auth ]; then
  [ "${STUB_MODE:-}" = authfail ] && exit 1
  printf '{"loggedIn":true,"authMethod":"claude.ai","apiProvider":"firstParty","subscriptionType":"max"}\n'
  exit 0
fi
printf 'workspace trust warning\n' >&2
printf '\n### Builder\n[Pass] relay.md:1 read.\n' >> "$RELAY_FILE"
if [ "${STUB_MODE:-}" = error ]; then
  printf '{"type":"result","is_error":true,"result":"rate limited"}\n'
else
  printf '{"type":"result","is_error":false,"subtype":"success","result":"relay.md:1 updated"}\n'
fi
STUB
chmod +x "$WORK/claude"
for mode in good error authfail; do
  task="RELAY-subscription-$mode"
  tick_a log task.created "$task" --agent operator >/dev/null
  tick_a claim "$task" --agent operator --paths relay.md >/dev/null
  tick_a release "$task" --agent operator --to claude-builder >/dev/null
  rc=0
  RELAY_AGENT=claude-builder CLAUDE_AGENT=claude-builder RELAY_PEER=operator \
    RELAY_FILE="$A/relay.md" RELAY_TASK="$task" CLAUDE_TURN_ROOT="$A" \
    CLAUDE_LOG="$WORK/$mode.json" CLAUDE_BIN="$WORK/claude" STUB_MODE="$mode" \
    bash "$ROOT/relay-automation/claude-turn.sh" >"$WORK/$mode.log" 2>&1 || rc=$?
  expected=5; [ "$mode" = good ] && expected=0
  [ "$rc" -eq "$expected" ] || fail "$mode expected $expected, got $rc: $(cat "$WORK/$mode.log")"
  info="$(tick_a info "$task")"
  if grep -Eq '^claimer:[[:space:]]+claude-builder$' <<<"$info"; then fail "$mode orphaned claim"; fi
  grep -q '^handoff-to: operator$' <<<"$info" || fail "$mode missing operator handoff: $info"
  pass "$mode produces exit $expected and cleans up the claimed turn"
done
