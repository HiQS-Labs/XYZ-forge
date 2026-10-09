import subprocess,sys,os,time,pathlib
child=subprocess.Popen([sys.executable,'-c',"import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(120)"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
time.sleep(.15)
pathlib.Path(sys.argv[1]).write_text(str(child.pid)+' '+str(os.getpgrp()))
child.wait()
