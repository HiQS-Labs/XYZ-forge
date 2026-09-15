#!/usr/bin/env bash
# GH-610: account routing and result validation; no real account or API calls.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONPATH="$ROOT/utils/py${PYTHONPATH:+:$PYTHONPATH}" python3 - <<'PYTEST'
import json, tempfile, unittest, os, subprocess, sys, time, signal, importlib.util, shutil
from pathlib import Path
from unittest.mock import patch
from proc_group import BoundedResult
from claude_cli import preflight, read_result, resolve_binary, effort_flags

class ClaudeSubscription(unittest.TestCase):
    def test_legacy_subscription_refused(self):
        import claude_cli
        root=Path(claude_cli.__file__).resolve().parents[2]
        for shim in ('claude-turn.sh','consult.sh'):
            for runtime in ('0','', '1'):
                with self.subTest(shim=shim,runtime=runtime),tempfile.TemporaryDirectory() as d:
                    env=dict(os.environ,CLAUDE_AUTH_MODE='subscription',XYZ_PYTHON=runtime)
                    if runtime=='1': env['PATH']=d  # unavailable Python fallback
                    r=subprocess.run(['/bin/bash',str(root/'relay-automation'/shim)],env=env,capture_output=True,text=True,timeout=5)
                    self.assertEqual(r.returncode,5,r.stderr)
                    self.assertIn('subscription requires the Python runtime',r.stderr)
    def test_effort_and_resolution(self):
        self.assertEqual(effort_flags({}), [])
        for effort in ('low','medium','high','xhigh','max'):
            self.assertEqual(effort_flags({'CLAUDE_REASONING_EFFORT':effort}), ['--effort',effort])
        with self.assertRaises(ValueError): effort_flags({'CLAUDE_REASONING_EFFORT':'typo'})
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'not-executable'; p.write_text('not a CLI')
            self.assertEqual(resolve_binary({'CLAUDE_BIN':str(p)}), '')

    def test_restricted_probe_uses_request_settings(self):
        flags=['--restricted','--strict-mcp-config']
        with patch('claude_cli.run_bounded',return_value=self.probe()) as run:
            preflight('/cli',{'CLAUDE_AUTH_MODE':'subscription'},'/repo',cli_flags=flags)
            self.assertEqual(run.call_args.args[0], ['/cli',*flags,'auth','status'])

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
                +'assert "--restricted" in sys.argv and "--strict-mcp-config" in sys.argv\n'
                +'if sys.argv[-2:]==["auth","status"]: print('+repr(json.dumps(dict(loggedIn=True,authMethod='claude.ai',apiProvider='firstParty',subscriptionType='max')))+')\n'
                +'else:\n assert "Read,Grep,Glob" in sys.argv\n assert ("--effort" in sys.argv)==bool(os.getenv("CLAUDE_REASONING_EFFORT"))\n if "--effort" in sys.argv: assert sys.argv[sys.argv.index("--effort")+1]==os.environ["CLAUDE_REASONING_EFFORT"]\n print("workspace trust warning",file=sys.stderr)\n if os.getenv("STUB_HANG"): exec(open(os.environ["STUB_HANG"]).read())\n if os.getenv("STUB_RC"): sys.exit(int(os.environ["STUB_RC"]))\n print(json.dumps(dict(type="result",is_error=os.getenv("STUB_ERROR")=="1",subtype="success",result="README.md:1 contains fixture")))\n')
            cli.chmod(0o755)
            preflight(str(cli),env,str(repo),cli_flags=['--restricted','--strict-mcp-config'])
            import claude_cli
            consult=Path(claude_cli.__file__).with_name('consult.py')
            for error,expected in [('0',0),('1',5)]:
                env['STUB_ERROR']=error
                env['CLAUDE_REASONING_EFFORT']='high' if error=='1' else ''
                result=subprocess.run([sys.executable,str(consult),'--models','claude','--prompt','Read README.md','--out',str(root/('out'+error))],cwd=repo,env=env,capture_output=True,text=True,timeout=30)
                self.assertEqual(result.returncode,expected,result.stdout+result.stderr)
            env.update(STUB_RC='3',STUB_ERROR='0')
            out=root/'nonzero'
            result=subprocess.run([sys.executable,str(consult),'--models','claude','--prompt','Read README.md','--out',str(out)],cwd=repo,env=env,capture_output=True,text=True,timeout=30)
            self.assertEqual(result.returncode,5,result.stdout+result.stderr)
            answers=list(out.rglob('*.claude.md')); self.assertEqual(len(answers),1)
            self.assertIn('CLI diagnostics:',answers[0].read_text())
            self.assertIn('workspace trust warning',Path(str(answers[0])+'.stderr').read_text())
            # Drive the entire consult command through wall and actual idle detection.
            hang=root/'hang.py'
            child='import os,signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); open(os.environ["STUB_PIDFILE"],"w").write(str(os.getpid())); time.sleep(60)'
            hang.write_text('import subprocess,time\n'
                +'subprocess.Popen([sys.executable,"-c",'+repr(child)+'])\ntime.sleep(60)\n')
            env.update(STUB_RC='',STUB_HANG=str(hang))
            for mode,wall,idle in [('wall','2','0'),('idle','20','1')]:
                pidfile=root/(mode+'.pid'); out=root/('timeout-'+mode)
                env.update(STUB_PIDFILE=str(pidfile),CONSULT_TIMEOUT=wall,CONSULT_IDLE_S=idle)
                try:
                    result=subprocess.run([sys.executable,str(consult),'--models','claude','--prompt','Read README.md','--out',str(out)],cwd=repo,env=env,capture_output=True,text=True,timeout=35)
                    self.assertEqual(result.returncode,5,result.stdout+result.stderr)
                    self.assertIn('0 answered, 1 failed',result.stdout)
                    self.assertTrue(pidfile.exists(),'child never announced readiness')
                    child_pid=int(pidfile.read_text())
                    status=subprocess.run(['ps','-o','stat=','-p',str(child_pid)],capture_output=True,text=True).stdout.strip()
                    self.assertTrue(not status or status.startswith('Z'),'consult child still running')
                    answers=list(out.rglob('*.claude.md')); self.assertEqual(len(answers),1)
                    self.assertIn('IDLE' if mode=='idle' else 'exceeded the 2s cap',answers[0].read_text())
                    trees=subprocess.check_output(['git','worktree','list','--porcelain'],cwd=repo,text=True)
                    self.assertEqual(trees.count('worktree '),1)
                finally:
                    if pidfile.exists():
                        try: os.kill(int(pidfile.read_text()),signal.SIGKILL)
                        except ProcessLookupError: pass
            env.pop('STUB_HANG')
            env.update(CONSULT_TIMEOUT='20',CONSULT_IDLE_S='0')
            # Force only Git's cleanup operation to fail; preserve the linked tree.
            real_git=shutil.which('git'); fakebin=root/'fakebin'; fakebin.mkdir()
            fakegit=fakebin/'git'
            fakegit.write_text('#!'+sys.executable+'\nimport os,sys\n'
                +'if "worktree" in sys.argv and "remove" in sys.argv: sys.exit(1)\n'
                +'os.execv('+repr(real_git)+',['+repr(real_git)+']+sys.argv[1:])\n')
            fakegit.chmod(0o755)
            env.update(PATH=str(fakebin)+os.pathsep+env['PATH'],STUB_RC='')
            result=subprocess.run([sys.executable,str(consult),'--models','claude','--prompt','Read README.md','--out',str(root/'cleanup-failure')],cwd=repo,env=env,capture_output=True,text=True,timeout=30)
            trees=subprocess.check_output([real_git,'worktree','list','--porcelain'],cwd=repo,text=True)
            retained=[line[9:] for line in trees.splitlines() if line.startswith('worktree ') and Path(line[9:]).resolve()!=repo.resolve()]
            try:
                self.assertEqual(result.returncode,5,result.stdout+result.stderr)
                self.assertIn('preserved at',result.stderr)
                self.assertEqual(len(retained),1)
                self.assertTrue(Path(retained[0]).is_dir())
                self.assertNotIn('1 answered',result.stdout)
            finally:
                for tree in retained:
                    subprocess.run([real_git,'worktree','remove','--force',tree],cwd=repo,check=True,capture_output=True)
            self.assertEqual((repo/'README.md').read_text(),'fixture\n')
            worktrees=subprocess.check_output(['git','worktree','list','--porcelain'],cwd=repo,text=True)
            self.assertEqual(worktrees.count('worktree '),1)

    def test_wall_and_idle_kill_descendants(self):
        import claude_cli
        spec=importlib.util.spec_from_file_location('gh613_consult',Path(claude_cli.__file__).with_name('consult.py'))
        consult=importlib.util.module_from_spec(spec); spec.loader.exec_module(consult)
        class Idle:
            def __init__(self,**kwargs): pass
            def start(self): pass
            def stop(self): pass
            def idle_seconds(self): return 2
            def classify(self): return ('idle','fixture idle')
        for mode in ('wall','idle'):
            with self.subTest(mode=mode),tempfile.TemporaryDirectory() as d:
                pidfile=Path(d)/'child.pid'; log=str(Path(d)/'answer')
                # Child announces readiness only after installing its TERM handler.
                child='import os,signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); open('+repr(str(pidfile))+',"w").write(str(os.getpid())); time.sleep(60)'
                parent='import subprocess,sys,time; subprocess.Popen([sys.executable,"-c",'+repr(child)+']); time.sleep(60)'
                proc=consult.guarded_with_timeout([sys.executable,'-c',parent],d,log,3,own_group=True)
                self.assertIsNotNone(proc)
                child_pid=None
                try:
                    deadline=time.monotonic()+5
                    while not pidfile.exists() and time.monotonic()<deadline: time.sleep(.02)
                    self.assertTrue(pidfile.exists(),'child never started')
                    child_pid=int(pidfile.read_text())
                    self.assertEqual(os.getpgid(child_pid),proc.pid)
                    with patch.dict(os.environ,{'CONSULT_IDLE_S':'1' if mode=='idle' else '0'}),patch.object(consult,'TurnDiagnostics',Idle):
                        if mode=='wall':
                            with self.assertRaises(subprocess.TimeoutExpired): consult.wait_with_idle_bound(proc,log,.1)
                            consult._kill_advisor_group(proc)
                        else:
                            self.assertTrue(consult.wait_with_idle_bound(proc,log,3))
                            self.assertIn('IDLE',Path(log).read_text())
                    self.assertIsNotNone(proc.poll())
                    deadline=time.monotonic()+3
                    while time.monotonic()<deadline:
                        status=subprocess.run(['ps','-o','stat=','-p',str(child_pid)],capture_output=True,text=True).stdout.strip()
                        if not status or status.startswith('Z'): break
                        time.sleep(.05)
                    self.assertTrue(not status or status.startswith('Z'),'descendant survived kill')
                finally:
                    try: os.killpg(proc.pid,signal.SIGKILL)
                    except ProcessLookupError: pass
                    proc.wait(timeout=5)

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
printf '%s\n' "$@" > "$WORK/claude-request-args"
printf '\n### Builder\n[Pass] relay.md:1 read.\n' >> "$RELAY_FILE"
if [ "${STUB_MODE:-}" = error ]; then
  printf '{"type":"result","is_error":true,"result":"rate limited"}\n'
else
  printf '{"type":"result","is_error":false,"subtype":"success","result":"relay.md:1 updated"}\n'
fi
STUB
chmod +x "$WORK/claude"
for mode in good error authfail inherit-error; do
  task="RELAY-subscription-$mode"
  tick_a log task.created "$task" --agent operator >/dev/null
  tick_a claim "$task" --agent operator --paths relay.md >/dev/null
  tick_a release "$task" --agent operator --to claude-builder >/dev/null
  rc=0
  auth=subscription; stub_mode="$mode"
  if [ "$mode" = inherit-error ]; then auth=inherit; stub_mode=error; fi
  RELAY_AGENT=claude-builder CLAUDE_AGENT=claude-builder RELAY_PEER=operator \
    RELAY_FILE="$A/relay.md" RELAY_TASK="$task" CLAUDE_TURN_ROOT="$A" \
    CLAUDE_LOG="$WORK/$mode.json" CLAUDE_BIN="$WORK/claude" STUB_MODE="$stub_mode" \
    CLAUDE_AUTH_MODE="$auth" CLAUDE_REASONING_EFFORT=high \
    bash "$ROOT/relay-automation/claude-turn.sh" >"$WORK/$mode.log" 2>&1 || rc=$?
  expected=5; [ "$mode" = good ] && expected=0
  [ "$rc" -eq "$expected" ] || fail "$mode expected $expected, got $rc: $(cat "$WORK/$mode.log")"
  info="$(tick_a info "$task")"
  if grep -Eq '^claimer:[[:space:]]+claude-builder$' <<<"$info"; then fail "$mode orphaned claim"; fi
  grep -q '^handoff-to: operator$' <<<"$info" || fail "$mode missing operator handoff: $info"
  pass "$mode produces exit $expected and cleans up the claimed turn"
done
grep -q '^--effort$' "$WORK/claude-request-args" || fail 'relay omitted effort flag'
grep -q '^high$' "$WORK/claude-request-args" || fail 'relay omitted effort level'
stderr_path="$(sed -n 's/^claude-turn: CLI diagnostics: //p' "$WORK/good.log")"
[ -s "$stderr_path" ] || fail 'relay omitted durable stderr transcript'
grep -q 'workspace trust warning' "$stderr_path" || fail 'relay lost stderr diagnostics' 
