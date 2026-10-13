import sys,json,pathlib
sys.path.insert(0,'/Users/noelsaw/task-clones/ate-remediation-20261003/verify/utils/py')
from proc_group import run_bounded
r=run_bounded([sys.executable,'-c',"import subprocess,sys,pathlib,os; c=subprocess.Popen([sys.executable,'-c','import time;time.sleep(120)'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/compat-after/normal-background.pid').write_text(str(c.pid)+' '+str(os.getpgrp()))"],timeout=3,grace=.2)
pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/compat-after/normal-background-result.json').write_text(json.dumps(vars(r)))
