import sys,json,pathlib
sys.path.insert(0,'/Users/noelsaw/task-clones/ate-remediation-20261003/verify/utils/py')
import domain_oracles as d
data={'positive':d.check_zero_state([sys.executable,'-c','pass'],'/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-zero-work',timeout=2)}
try:
 data['result']=d.check_zero_state([sys.executable,'/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-zero-command.py'],'/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-zero-work',timeout=1)
except BaseException as exc:
 data['error']=type(exc).__name__+': '+str(exc)
pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-zero-result.json').write_text(json.dumps(data))
