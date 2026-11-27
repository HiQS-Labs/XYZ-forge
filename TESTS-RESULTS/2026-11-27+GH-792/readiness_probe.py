#!/usr/bin/env python3
"""GH-792 readiness probe (retained manual check, not a suite; GH-831).

Exit 0 only when the FIXED behavior is observed, all inside a fresh fixture directory:
  1. Overlap: make_sandbox(repo=<base>/clone, sandbox_root=<base>) raises RuntimeError with
     zero os.makedirs / shutil.rmtree / subprocess.run calls (recorded, passed through), the
     source repository (its .git and a committed sentinel) is still intact, and nothing new
     was created under <base>.
  2. Positive control: a disjoint call still returns a working clone holding the sentinel.
  3. Existing self-test shape: make_sandbox(host, <host>/inside) still raises RuntimeError.
Any other outcome, including a crash, exits nonzero, so the preflight contract
(`expect_nonzero: true`) reads it as unfixed. Today step 1 deletes the fixture source repo
first and then fails in `git clone`, which is the bug.

Isolation: local git only (no remote, no network); every path is under one mkdtemp fixture.
"""
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "utils/py"))
import gen4_campaign as g  # noqa: E402

SENTINEL = "gh792 sentinel\n"


def git(cwd, *a):
    subprocess.run(["git", "-C", str(cwd), *a], check=True, capture_output=True, text=True)


def make_repo(path: Path):
    path.mkdir(parents=True)
    git(path, "init", "-q")
    git(path, "config", "user.email", "probe@example.invalid")
    git(path, "config", "user.name", "gh792 probe")
    (path / "sentinel.txt").write_text(SENTINEL)
    git(path, "add", "sentinel.txt")
    git(path, "commit", "-qm", "sentinel")


def intact(path: Path) -> bool:
    return (path / ".git").is_dir() and (path / "sentinel.txt").is_file() and \
        (path / "sentinel.txt").read_text() == SENTINEL


def main(fx: Path) -> int:
    # 1. overlapping source: a real checkout named `clone` directly under the sandbox root
    base = fx / "base"
    src = base / "clone"
    make_repo(src)
    before = sorted(p.name for p in base.iterdir())
    calls = []
    real = (g.os.makedirs, g.shutil.rmtree, g.subprocess.run)

    def rec(name, fn):
        def wrapper(*a, **k):
            calls.append(name)
            return fn(*a, **k)
        return wrapper
    g.os.makedirs, g.shutil.rmtree, g.subprocess.run = (
        rec("makedirs", real[0]), rec("rmtree", real[1]), rec("subprocess", real[2]))
    try:
        g.make_sandbox(str(src), str(base))
        outcome = "returned"
    except RuntimeError as exc:
        outcome = f"RuntimeError: {exc}"
    except Exception as exc:  # noqa: BLE001 - today: CalledProcessError after the source is gone
        outcome = f"{exc.__class__.__name__}: {exc}"
    finally:
        g.os.makedirs, g.shutil.rmtree, g.subprocess.run = real
    after = sorted(p.name for p in base.iterdir()) if base.is_dir() else []
    src_ok = intact(src)
    print(f"overlap: {outcome}; mutation calls={calls}; source intact={src_ok}; "
          f"base entries before={before} after={after}")
    if not src_ok:
        print("UNFIXED: make_sandbox deleted the source repository before refusing (GH-792)")
        return 1
    if not outcome.startswith("RuntimeError") or calls or after != before:
        print("UNFIXED: overlapping call did not refuse before makedirs/rmtree/subprocess")
        return 1

    # 2. positive control: disjoint sandbox still clones
    other = fx / "src"
    make_repo(other)
    clone, _created = g.make_sandbox(str(other), str(fx / "sandbox"))
    if not intact(Path(clone)) or not intact(other):
        print("INVALID: disjoint sandbox no longer produces a working clone")
        return 2
    print(f"disjoint: clone ok at {clone}")

    # 3. existing self-test shape: sandbox root inside the repo still refuses
    host = fx / "host"
    make_repo(host)
    try:
        g.make_sandbox(str(host), str(host / "inside"))
        print("INVALID: descendant sandbox root was accepted")
        return 2
    except RuntimeError:
        print("descendant: refused")
    if not intact(host):
        print("INVALID: descendant refusal damaged the host repository")
        return 2
    print("FIXED: overlap refuses before any mutation; disjoint and descendant behavior kept")
    return 0


if __name__ == "__main__":
    fixture = Path(tempfile.mkdtemp(prefix="gh792-probe-")).resolve()
    try:
        code = main(fixture)
    except Exception as exc:  # noqa: BLE001
        print(f"probe error: {exc.__class__.__name__}: {exc}")
        code = 3
    finally:
        shutil.rmtree(fixture, ignore_errors=True)
    sys.exit(code)
