import json,os,pathlib,signal,subprocess,sys,time
sys.argv=[sys.argv[0],'--out',str(pathlib.Path.cwd()/'temp/gh1400-manual/adjacent')]
text=pathlib.Path('temp/gh1400-manual/check.py').read_text();exec(text[:text.index("required=['adoption")])
# Original CLI behavior, with the new flag absent, is the discriminating baseline.
baseline=out/'baseline_jog.py';baseline.write_text(subprocess.check_output(['git','show','7dd85cd3a:utils/py/jog_run.py'],text=True))
r,t,g,receipt=setup('baseline');p=subprocess.run([sys.executable,str(baseline),'--root',str(r),'--target-root',str(t),'--builder','codex','--reviewer','agy','--max-tasks','2'],env={**os.environ,'PYTHONPATH':str(source/'utils/py'),'CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true'},capture_output=True,text=True,timeout=60)
s=json.loads(state(r,g).read_text());red=not s['executions'][0].get('committed_receipt');assert red
(out/'baseline.log').write_text(p.stdout+p.stderr)
records.append({'id':'unchanged-recovery-rejected','pass':red,'observed':s,'rc':p.returncode,'predicate':'recovered approved A must publish its receipt before continuation'})
r,t,g,receipt=setup('cancel');worker=t/'worker.py';worker.write_text(worker.read_text().replace("if os.environ.get('FIXTURE_SLEEP'):time.sleep(30)","if os.environ.get('FIXTURE_SLEEP'):\n (t/'.tick/worker-pid').write_text(str(os.getpid()))\n time.sleep(30)"));git(t,'add','worker.py');git(t,'commit','-m','controlled cancellation observer');git(t,'push','origin','HEAD:development')
# A remains approved at its old head: the extra observer commit would invalidate publication,
# so mark A parked; this control isolates cancellation of the independent pending B.
j.jog_set_status(str(r),901,'parked',failure_reason='fixture A held for cancellation control')
argv=[sys.executable,str(source/'utils/py/releases_app.py'),'--root',str(r),'jog','run','--target-root',str(t),'--builder','codex','--reviewer','agy','--max-tasks','1','--supervise-until',str(int(time.time()+60))]
with (out/'cancel.log').open('w') as log:
 p=subprocess.Popen(argv,stdout=log,stderr=log,env={**os.environ,'CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true','FIXTURE_SLEEP':'1'})
 end=time.monotonic()+30
 while not (t/'.tick/worker-pid').exists() and p.poll() is None and time.monotonic()<end:time.sleep(.05)
 assert (t/'.tick/worker-pid').exists(),(out/'cancel.log').read_text()
 worker_pid=int((t/'.tick/worker-pid').read_text());p.send_signal(signal.SIGTERM);rc=p.wait(timeout=20)
 try:os.kill(worker_pid,0);absent=False
 except ProcessLookupError:absent=True
 assert rc==130 and absent,(rc,absent)
 before=(t/'.tick/starts').read_text();p2=wake('cancel-restart',r,t);assert before==(t/'.tick/starts').read_text() and row(r)[1]['status']=='parked'
 records.append({'id':'cancel-stops-worker','pass':True,'rc':rc,'worker_absent':absent,'restart_rows':row(r)})
# Initialization window must not reclaim a lock lacking an owner.
r,t,g,receipt=setup('unknown-owner');lock=t/'.git/relay-driver.lock';lock.mkdir();p=wake('unknown-owner',r,t);assert p.returncode==2 and lock.exists() and (t/'.tick/starts').read_text()=='901\n'
records.append({'id':'unknown-owner-held','pass':True,'stderr':p.stderr})
# Aggregator rejects missing, duplicated, failed and empty inventories.
def aggregate(required,rows):
 return bool(required) and len(set(required))==len(required) and len(rows)==len(required) and len({r['id'] for r in rows})==len(rows) and {r['id'] for r in rows}==set(required) and all(r['pass'] for r in rows)
checks=[not aggregate(['x'],[]),not aggregate(['x'],[{'id':'x','pass':True}]*2),not aggregate(['x'],[{'id':'x','pass':False}]),not aggregate([],[]),aggregate(['x'],[{'id':'x','pass':True}])];assert all(checks)
records.append({'id':'aggregation-red-controls','pass':True,'checks':checks})
(out/'results.json').write_text(json.dumps(records,indent=2));print(json.dumps({'passed':len(records)}))
