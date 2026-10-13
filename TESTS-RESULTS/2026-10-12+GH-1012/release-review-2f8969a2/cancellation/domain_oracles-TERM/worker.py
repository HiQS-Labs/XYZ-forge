import os,json,time,signal
from pathlib import Path
Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/release-review/cancellation/domain_oracles-TERM/ready.json').write_text(json.dumps(dict(pid=os.getpid(),pgid=os.getpgrp())))
time.sleep(40)
