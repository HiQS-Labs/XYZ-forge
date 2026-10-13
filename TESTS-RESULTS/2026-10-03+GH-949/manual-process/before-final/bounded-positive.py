import sys,json,pathlib
sys.path.insert(0,'/Users/noelsaw/task-clones/ate-remediation-20261003/verify/utils/py')
from proc_group import run_bounded
a=run_bounded([sys.executable,'-c','print(123)'],timeout=2,grace=.1)
b=run_bounded([sys.executable,'-c','raise SystemExit(124)'],timeout=2,grace=.1)
c=run_bounded([sys.executable,'-c','import time;time.sleep(10)'],timeout=.2,grace=.1)
pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/bounded-positive-result.json').write_text(json.dumps({'normal':vars(a),'own124':vars(b),'timeout':vars(c)}))
