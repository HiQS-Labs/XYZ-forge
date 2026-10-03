import argparse,json,os,signal,subprocess,sys,time
from pathlib import Path
from process_controls import utc,alive,kill_group,wait_file
ap=argparse.ArgumentParser();ap.add_argument('--repo',required=True);ap.add_argument('--out',required=True);a=ap.parse_args()
repo=Path(a.repo).resolve();out=Path(a.out).resolve();out.mkdir(parents=True,exist_ok=False)
sha=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip();rows=[]
def record(name,cmd,start,data):
 data.update(case=name,command=cmd,source_sha=sha,started_utc=start,finished_utc=utc());rows.append(data)
 (out/(name+'.json')).write_text(json.dumps(data,indent=2)+'\n')
 with (out/'provenance.jsonl').open('a') as f:f.write(json.dumps(data)+'\n')
 print(json.dumps(data),flush=True)
worker=out/'worker.py';worker.write_text("import subprocess,sys,time,pathlib,os\nc=subprocess.Popen([sys.executable,'-c','import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(120)'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)\ntime.sleep(.15)\npathlib.Path(sys.argv[1]).write_text(str(c.pid)+' '+str(os.getpgrp()))\nc.wait()\n")
for mode,first in [('term',signal.SIGTERM),('int',signal.SIGINT)]:
 start=utc();pidfile=out/(mode+'.pid');pgfile=out/(mode+'.pgid');ack=out/(mode+'.ack')
 cmd=[sys.executable,str(repo/'utils/py/proc_group.py'),'--timeout','60','--grace','1','--pgid-file',str(pgfile),'--ack-file',str(ack),'--ack-wait','30','--',sys.executable,str(worker),str(pidfile)]
 data={}
 with (out/(mode+'.log')).open('w') as f:
  p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
  try:
   wait_file(pidfile,p);wait_file(pgfile,p);child,pgid=map(int,pidfile.read_text().split());data['child_live_before']=alive(child);data['ack_absent']=not ack.exists()
   p.send_signal(first);time.sleep(.2)
   data['live_during_cleanup']=p.poll() is None
   for sig in [signal.SIGTERM,signal.SIGINT,signal.SIGTERM]:
    if p.poll() is None:p.send_signal(sig)
    time.sleep(.08)
   data['returncode']=p.wait(timeout=8);data['child_live_after']=alive(child)
   data['correct_properties']={'ack_wait_exercised':data['ack_absent'],'repeated_signals_exercised':data['live_during_cleanup'],'first_signal_status':data['returncode']==128+first,'child_reaped':not data['child_live_after']}
  except Exception as exc:data['probe_error']=repr(exc)
  finally:
   if pidfile.exists():kill_group(int(pidfile.read_text().split()[1]))
   kill_group(p.pid);p.wait(timeout=3);time.sleep(.2)
   data['independent_cleanup_child_absent']=not pidfile.exists() or not alive(int(pidfile.read_text().split()[0]))
 record('ack-repeated-'+mode,cmd,start,data)
# Actual SystemExit injected from a timed signal after child readiness, without production monkeypatches.
for kind in ['base-exception','normal-background']:
 start=utc();pidfile=out/(kind+'.pid');result=out/(kind+'-result.json');probe=out/(kind+'.py')
 if kind=='base-exception':
  code="import sys,os,signal,pathlib,json\nsys.path.insert(0,%r)\nfrom proc_group import run_bounded\n"%str(repo/'utils/py')
  code+="def stop(sig,frame): raise SystemExit(77)\nsignal.signal(signal.SIGUSR1,stop)\ntry:\n run_bounded([sys.executable,%r,%r],timeout=60,grace=.2)\nexcept BaseException as exc:\n pathlib.Path(%r).write_text(json.dumps({'exception':type(exc).__name__,'code':getattr(exc,'code',None)}))\n"%(str(worker),str(pidfile),str(result))
 else:
  child="import time;time.sleep(120)"
  command="import subprocess,sys,pathlib,os; c=subprocess.Popen([sys.executable,'-c',%r],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);pathlib.Path(%r).write_text(str(c.pid)+' '+str(os.getpgrp()))"%(child,str(pidfile))
  code="import sys,json,pathlib\nsys.path.insert(0,%r)\nfrom proc_group import run_bounded\nr=run_bounded([sys.executable,'-c',%r],timeout=3,grace=.2)\npathlib.Path(%r).write_text(json.dumps(vars(r)))\n"%(str(repo/'utils/py'),command,str(result))
 probe.write_text(code);cmd=[sys.executable,str(probe)];data={}
 with (out/(kind+'.log')).open('w') as f:
  p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,start_new_session=True)
  try:
   if kind=='base-exception':wait_file(pidfile,p);p.send_signal(signal.SIGUSR1)
   data['returncode']=p.wait(timeout=10);data['result']=json.loads(result.read_text());child,pgid=map(int,pidfile.read_text().split());data['child_live_after']=alive(child)
   data['correct_properties']=({'exception_preserved':data['result']=={'exception':'SystemExit','code':77},'child_reaped':not data['child_live_after']} if kind=='base-exception' else {'successful_result':data['result']['rc']==0 and not data['result']['timed_out'],'background_policy_unchanged':data['child_live_after']})
  except Exception as exc:data['probe_error']=repr(exc)
  finally:
   if pidfile.exists():kill_group(int(pidfile.read_text().split()[1]))
   kill_group(p.pid);p.wait(timeout=3);time.sleep(.2);data['independent_cleanup_child_absent']=not pidfile.exists() or not alive(int(pidfile.read_text().split()[0]))
 record(kind,cmd,start,data)
(out/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
