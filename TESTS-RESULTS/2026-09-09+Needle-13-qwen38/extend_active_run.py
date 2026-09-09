import os,signal,time,json,subprocess,datetime
from pathlib import Path
b=Path('TESTS-RESULTS/2026-09-09+Needle-13-qwen38')
parent=77234;child=77257
r=json.loads((b/'r1-receipt.json').read_text())
started=datetime.datetime.fromisoformat(r['started_at']).timestamp()
remaining=max(0,started+1200-time.time());deadline=time.monotonic()+remaining
p=subprocess.check_output(['ps','-p',str(parent),'-o','command='],text=True)
c=subprocess.check_output(['ps','-p',str(child),'-o','ppid=,command='],text=True)
assert 'consult.py' in p and 'qwen38' in p and str(parent) in c and 'qwen38/lmstudio_stream_adapter.py' in c
record={'authorization':'User explicitly extended this model trial to 20 minutes as a per-case exception','run':'r1','original_harness_cap_seconds':900,'authorized_cap_seconds':1200,'supervisor_pid':parent,'adapter_pid':child,'started_at':r['started_at'],'exception_applied_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'Pause only supervisor; retain active adapter/socket; enforce original-start+1200 deadline independently; resume supervisor when child exits or cap is reached.'}
def save():
 with (b/'r1-timeout-exception.json').open('w') as f:json.dump(record,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
save();paused=False
try:
 os.kill(parent,signal.SIGSTOP);paused=True
 print('Supervisor paused; active inference retained. Independent deadline remaining:',round(remaining,2),flush=True)
 while True:
  result=subprocess.run(['ps','-p',str(child),'-o','stat='],capture_output=True,text=True)
  state=result.stdout.strip()
  if result.returncode or not state or state.startswith('Z'):
   record['outcome']='adapter_exited_before_extended_cap';break
  if time.monotonic()>=deadline:
   os.kill(child,signal.SIGTERM);record['outcome']='adapter_stopped_at_authorized_1200s_cap';break
  time.sleep(1)
finally:
 if paused:
  try:os.kill(parent,signal.SIGCONT)
  except ProcessLookupError:pass
 record['finished_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
 print(record.get('outcome','watcher_failed_supervisor_resumed'),flush=True)
