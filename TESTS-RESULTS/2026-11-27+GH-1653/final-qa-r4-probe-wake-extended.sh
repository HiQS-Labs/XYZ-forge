PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PROBE'
from pathlib import Path

path = Path("TESTS-RESULTS/2026-11-27+GH-1653/final-qa-r3-probe-wake.sh")
first, *body, last = path.read_text().splitlines()
assert first.endswith("<<'PROBE'") and last == "PROBE"
source = "\n".join(body)
before = "assert release.wait(10)"
start = "        b.start()"
assert source.count(before) == 1 and source.count(start) == 1
source = "import time\n" + source.replace(before, "assert release.wait(30)")
source = source.replace(start, "        time.sleep(11)\n" + start)
exec(compile(source, str(path), "exec"))
PROBE
