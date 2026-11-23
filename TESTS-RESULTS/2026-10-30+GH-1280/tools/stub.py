"""GH-1280 supervisor-control stub: a target whose every mutant yields one identical refusal."""
import os, sys, time

time.sleep(float(os.environ.get("STUB_SLEEP", "0")))
sys.stderr.write("factory-primitive: run root must stay under STUB\n")
sys.exit(2)
