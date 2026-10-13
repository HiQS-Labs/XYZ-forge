import pathlib,subprocess,os,time,json,tempfile,fcntl
root=pathlib.Path.cwd();work=pathlib.Path(tempfile.mkdtemp(prefix='handoff-',dir=root/'temp/gh909'))
s=(root/'utils/telemetry/append-xyz-completion.sh').read_text().replace('import sys, json, os, tempfile, fcntl, time, uuid', 'import sys, json, os, tempfile, fcntl, time, uuid, pathlib')
s=s.replace('    except BlockingIOError:\n','    except BlockingIOError:\n        if os.environ.get("ROLE") == "W" and not (pathlib.Path(os.environ["BARRIER"])/"W-seen").exists():\n            q=pathlib.Path(os.environ["BARRIER"]); (q/"W-seen").touch()\n            while not (q/"W-go").exists(): time.sleep(.01)\n')
s=s.replace('os.ftruncate(lock_fd, 32)\n','os.ftruncate(lock_fd, 32)\nimport pathlib\nif os.environ.get("ROLE") == "A":\n    q=pathlib.Path(os.environ["BARRIER"]); (q/"A-held").touch()\n    while not (q/"A-go").exists(): time.sleep(.01)\n')
s=s.replace('records.insert(0, {','if os.environ.get("ROLE") == "B":\n    q=pathlib.Path(os.environ["BARRIER"]); (q/"B-read").touch()\n    while not (q/"B-go").exists(): time.sleep(.01)\nrecords.insert(0, {')
writer=work/'writer.sh';writer.write_text(s)
def wait(name):
 end=time.monotonic()+10
 while not (work/name).exists():
  assert time.monotonic()<end,name
  time.sleep(.01)
def launch(role):
 env=os.environ.copy();env.update(ROLE=role,BARRIER=str(work),XYZ_JSON_PATH=str(work/'records.json'))
 return subprocess.Popen(['bash',str(writer),'relay',role,'green',role,role],env=env)
a=launch('A');wait('A-held');w=launch('W');wait('W-seen');(work/'A-go').touch();assert a.wait(timeout=10)==0
b=launch('B');wait('B-read');inode=(work/'records.json.lock').stat().st_ino;(work/'W-go').touch();time.sleep(.3);assert w.poll() is None
with open(work/'records.json.lock','r+') as f:
 try: fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB);raise AssertionError('B lock lost')
 except BlockingIOError: pass
assert (work/'records.json.lock').stat().st_ino==inode
(work/'B-go').touch();assert b.wait(timeout=10)==0 and w.wait(timeout=10)==0
records=json.loads((work/'records.json').read_text());assert {r['sessionId'] for r in records}=={'A','W','B'}
# Crash releases the OS lock; the sidecar inode remains.
holder=subprocess.Popen(['python3','-c','import fcntl,sys,time; f=open(sys.argv[1],"r+"); fcntl.flock(f,fcntl.LOCK_EX); print("held",flush=True); time.sleep(30)',str(work/'records.json.lock')],stdout=subprocess.PIPE,text=True)
assert holder.stdout.readline().strip()=='held';holder.kill();holder.wait();assert launch('C').wait(timeout=10)==0
# Legacy directory refusal leaves its owner metadata untouched.
legacy=work/'legacy.json';(work/'legacy.json.lock').mkdir();(work/'legacy.json.lock/pid').write_text('old-owner')
r=subprocess.run(['bash',str(root/'utils/telemetry/append-xyz-completion.sh'),'relay','legacy','green','T','D'],env={**os.environ,'XYZ_JSON_PATH':str(legacy)},capture_output=True,text=True)
assert r.returncode!=0 and not legacy.exists() and (work/'legacy.json.lock/pid').read_text()=='old-owner'
result={'sha':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'writer_rcs':[a.returncode,w.returncode,b.returncode],'records':[r['sessionId'] for r in records],'successor_inode_preserved':True,'waiter_blocked_during_successor':True,'crash_release':True,'legacy_refusal_rc':r.returncode,'fixture':str(work),'instrumentation':'scheduling barriers only'}
(root/'temp/gh909/manual-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
