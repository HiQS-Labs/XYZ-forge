import json,pathlib,sys,time,signal,os,subprocess
sys.argv=[sys.argv[0],'--out',str(pathlib.Path.cwd()/'temp/gh1400-manual/review-fixes')]
s=pathlib.Path('temp/gh1400-manual/check.py').read_text();exec(s[:s.index("required=['adoption")])
required=['detached-held','resume-missing','resume-invalid','resume-mismatch','resume-original','resume-valid-retry','retry-intent-kill-resume','retry-completion']
(out/'required.json').write_text(json.dumps(required))
r,t,g,receipt=setup('detached');j.jog_set_status(str(r),901,'parked',failure_reason='controlled hold');git(t,'switch','--detach');(t/'unique.txt').write_text('unique detached work');git(t,'add','unique.txt');git(t,'commit','-m','unique detached work');head=git(t,'rev-parse','HEAD');p=wake('detached',r,t)
check('detached-held',p.returncode==2 and git(t,'rev-parse','HEAD')==head and (t/'.tick/starts').read_text()=='901\n',p.stdout+p.stderr)
for mode in ['missing','invalid','mismatch','original','valid-retry']:
 r,t,g,receipt=setup('resume-'+mode);sp=state(r,g);data=json.loads(sp.read_text());rp=sp.parent/'retry.json'
 if mode!='original':
  data['executions'][0]['gate_retries']=[{'execution_id':'gh901-exec1-gateretry1','result_path':str(rp)}];sp.write_text(json.dumps(data))
  if mode=='invalid':rp.write_text('{}')
  elif mode in ['mismatch','valid-retry']:
   receipt['execution_id']='wrong' if mode=='mismatch' else 'gh901-exec1-gateretry1';rp.write_text(json.dumps(receipt))
 p=subprocess.run([sys.executable,source/'utils/py/releases_app.py','--root',r,'jog','resume','901'],capture_output=True,text=True);(out/('resume-'+mode+'.log')).write_text(p.stdout+p.stderr);after=json.loads(sp.read_text());entry=after['executions'][0];pub=(entry.get('gate_retries') or [entry])[-1]
 good=mode in ['original','valid-retry'];check('resume-'+mode, (p.returncode==0 and bool(pub.get('committed_receipt'))) if good else (p.returncode==1 and not entry.get('committed_receipt') and 'resume held' in row(r)[0]['failure_reason']),p.stdout+p.stderr)
for mode in ['kill','complete']:
 r,t,g,receipt=setup('retry-'+mode);sp=state(r,g);data=json.loads(sp.read_text());ip=pathlib.Path(data['executions'][0]['packet_dir'])/'marathon-invocation.json';inv=json.loads(ip.read_text());worker=out/('worker-'+mode+'.py');original=out/('original-'+mode+'.json');original.write_text(json.dumps(receipt));marker=out/('started-'+mode)
 worker.write_text("import argparse,json,pathlib,time\np=argparse.ArgumentParser();p.add_argument('--execution-id');p.add_argument('--result-file');a,_=p.parse_known_args();pathlib.Path("+repr(str(marker))+").write_text('started')\n"+('time.sleep(60)\n' if mode=='kill' else '')+"r=json.loads(pathlib.Path("+repr(str(original))+").read_text());r['execution_id']=a.execution_id;pathlib.Path(a.result_file).write_text(json.dumps(r))\n")
 inv['argv']=[sys.executable,str(worker)];ip.write_text(json.dumps(inv));log=out/('retry-'+mode+'.log')
 with log.open('w') as stream:
  proc=subprocess.Popen([sys.executable,source/'utils/py/releases_app.py','--root',r,'jog','retry-gate','901','--builder','codex','--reviewer','agy'],stdout=stream,stderr=subprocess.STDOUT,start_new_session=True,env={**os.environ,'CODEX_BIN':'/usr/bin/true','AGY_BIN':'/usr/bin/true'})
  limit=time.monotonic()+15
  while not marker.exists() and proc.poll() is None and time.monotonic()<limit:time.sleep(.05)
  assert marker.exists(),log.read_text()
  if mode=='kill':
   saved=json.loads(sp.read_text())['executions'][0]['gate_retries'];assert len(saved)==1 and saved[0]['status']=='dispatched' and saved[0]['execution_id']=='gh901-exec1-gateretry1'
   os.killpg(proc.pid,signal.SIGKILL);proc.wait();p=subprocess.run([sys.executable,source/'utils/py/releases_app.py','--root',r,'jog','resume','901'],capture_output=True,text=True);(out/'retry-kill-resume.log').write_text(p.stdout+p.stderr)
   j.jog_set_status(str(r),901,'pending');p2=wake('retry-kill-wake',r,t);after=json.loads(sp.read_text())['executions'][0]
   check('retry-intent-kill-resume',p.returncode==1 and 'supervision held' in row(r)[0]['failure_reason'] and not after.get('committed_receipt') and len(after['gate_retries'])==1 and (t/'.tick/starts').read_text().count('901\n')==1,{'retry':saved,'resume':p.stdout,'wake':p2.stdout})
  else:
   rc=proc.wait(timeout=20);after=json.loads(sp.read_text())['executions'][0]['gate_retries'];check('retry-completion',rc==0 and len(after)==1 and bool(after[0].get('committed_receipt')),log.read_text())
assert len(records)==len(required) and len({x['id'] for x in records})==len(records) and {x['id'] for x in records}==set(required) and all(x['pass'] for x in records)
(out/'results.json').write_text(json.dumps(records,indent=2));print(json.dumps({'passed':len(records),'required':len(required),'source':git(source,'rev-parse','HEAD')}))
