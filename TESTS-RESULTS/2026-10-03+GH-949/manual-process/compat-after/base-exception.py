import sys,os,signal,pathlib,json
sys.path.insert(0,'/Users/noelsaw/task-clones/ate-remediation-20261003/verify/utils/py')
from proc_group import run_bounded
def stop(sig,frame): raise SystemExit(77)
signal.signal(signal.SIGUSR1,stop)
try:
 run_bounded([sys.executable,'/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/compat-after/worker.py','/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/compat-after/base-exception.pid'],timeout=60,grace=.2)
except BaseException as exc:
 pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/compat-after/base-exception-result.json').write_text(json.dumps({'exception':type(exc).__name__,'code':getattr(exc,'code',None)}))
