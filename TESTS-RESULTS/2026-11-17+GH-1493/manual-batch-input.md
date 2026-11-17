# GH-1493 manual batch check — recorded input

Manual check (AGENTS.md *No new tests*): not a registered suite. Run as
`python3 probe.py <merge-cleanup scripts dir at a revision> <empty workdir>` with the source below
saved to a scratch file (sha256 `148fda0003090bec6e4ded95cc3e6a068574b79ac7d0b12453f07b4b49822ed0`).
Scripts dirs came from `git archive 9331cec67` (base) and `git archive 0d1ccf8fa` (candidate).

```python
"""GH-1493 manual batch check: one call, three ineligible paths before one eligible path.

Usage: python3 gh1493_batch_probe.py <merge-cleanup scripts dir> <workdir>
Downstream inspection/refresh/teardown are patched to record calls (delegation, not retirement).
"""
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch

scripts, work = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
sys.path.insert(0, str(scripts))
import merge_cleanup as mc  # noqa: E402

CANON = "https://github.com/HiQS-Labs/XYZ-forge.git"


def repo(path, origin):
    path.mkdir(parents=True)
    subprocess.run(["git", "init", "-q", str(path)], check=True)
    if origin:
        subprocess.run(["git", "-C", str(path), "remote", "add", "origin", origin], check=True)
    return path


primary = repo(work / "XYZ-forge", CANON)
b = repo(work / "XYZ-forge-gh9-x-2026-11-17-gate", str(work / "XYZ-forge-gh9-x-2026-11-17"))
c = repo(work / "other-repo-clone", "https://github.com/other/repo.git")
d = work / "not-a-git-dir"
d.mkdir()
a = repo(work / "XYZ-forge-gh9-x-2026-11-17", CANON)

calls = []


def fake_inspect(path, **kw):
    calls.append(("inspect", str(path), kw.get("published_pr")))
    return {"path": str(path), "disposition": "SAFE_PUBLISHED_PR"}


def fake_refresh(infos, primary, **kw):
    calls.append(("refresh", infos[0]["path"], kw.get("published_pr")))
    return infos


def fake_teardown(info, dry_run, **kw):
    calls.append(("teardown", info["path"], dry_run))
    return True


with patch.object(mc, "inspect_checkout", fake_inspect), \
        patch.object(mc, "refresh_for_teardown", fake_refresh), \
        patch.object(mc, "teardown_checkout", fake_teardown), \
        patch.object(mc, "format_scan_table", lambda infos: f"[table {infos[0]['path']}]"):
    rc = mc.retire_published_checkouts(primary, [str(b), str(c), str(d), str(a)], 9,
                                       "development", execute=False)
print(f"EXIT {rc}")
for call in calls:
    print("CALL", *call)
print(f"CALLS {len(calls)}")
```
