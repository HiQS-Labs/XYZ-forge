import pathlib,subprocess,sys,time,os
counter=pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-idempotence.counter')
if not counter.exists():
 counter.write_text('first'); sys.exit(0)
c=subprocess.Popen([sys.executable,'-c',"import pathlib,time; time.sleep(3); pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-idempotence-work/late-write').write_text('late write')"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
pathlib.Path('/Users/noelsaw/task-clones/ate-remediation-20261003/manual-process/before-final/oracle-idempotence.pid').write_text(str(c.pid)+' '+str(os.getpgid(c.pid)))
time.sleep(120)
