#!/usr/bin/python3
"""GH-1430 manual check matrix (no new test; AGENTS.md GH-831).

Usage: /usr/bin/python3 manual_matrix.py <clone> <base-sha> <fixture-python>
  <fixture-python> writes the WAL fixture and must remove the side files on close
  (rebalanceOS's venv Python does; Apple's /usr/bin/python3 keeps -shm).
Runs board_sync._rebalance_active_repos from <base-sha> (old) and from the working tree (new),
both under this interpreter, against a non-empty WAL fixture with no side files.
"""
import hashlib, importlib.util, io, os, sqlite3, subprocess, sys, tempfile
from contextlib import redirect_stderr
from pathlib import Path

clone, base, fixture_py = Path(sys.argv[1]).resolve(), sys.argv[2], sys.argv[3]
print("interpreter:", sys.executable, sys.version.split()[0], "sqlite", sqlite3.sqlite_version)
work = Path(tempfile.mkdtemp(prefix="gh1430-"))
sys.path.insert(0, str(clone / "utils/py"))  # board_sync's sibling imports (device_config, ...)
results = []


def check(name, ok, detail):
    results.append(ok)
    print("%s  %s: %s" % ("PASS" if ok else "FAIL", name, detail))


def load(tag, src):
    spec = importlib.util.spec_from_file_location("board_sync_" + tag, src)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def make_fixture(path):
    code = (
        "import sqlite3,sys;c=sqlite3.connect(sys.argv[1]);c.execute('pragma journal_mode=wal');"
        "c.execute('create table github_activity(repo_full_name,scan_date,commits,prs_opened,prs_merged,"
        "issues_opened,issue_comments,reviews)');"
        "c.execute(\"insert into github_activity values('o/gh',date('now'),3,0,0,0,0,0)\");"
        "c.execute('create table agent_session_activity(repo_full_name,day,runs)');"
        "c.execute(\"insert into agent_session_activity values('o/agent-only',date('now'),2)\");"
        "c.commit();c.close()")
    subprocess.run([fixture_py, "-c", code, str(path)], check=True)
    mode = subprocess.run([fixture_py, "-c", "import sqlite3,sys;print(sqlite3.connect(sys.argv[1]).execute('pragma journal_mode').fetchone()[0])", str(path)],
                          check=True, capture_output=True, text=True).stdout.strip()
    sides = [s for s in ("-wal", "-shm") if Path(str(path) + s).exists()]
    return mode, sides


def run(mod, db):
    os.environ["REBALANCE_DB"] = str(db)
    err = io.StringIO()
    with redirect_stderr(err):
        out = mod._rebalance_active_repos({"since_days": 7, "include_agent_sessions": True}, 10)
    return out, err.getvalue().strip()


def stat(p):
    return hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns


old_src = work / "old" / "board_sync.py"
old_src.parent.mkdir()
old_src.write_bytes(subprocess.run(["git", "-C", str(clone), "show", base + ":utils/py/board_sync.py"],
                                   check=True, capture_output=True).stdout)
old, new = load("old", old_src), load("new", clone / "utils/py/board_sync.py")

# 1. Red control: no-side-file WAL fixture.
db = work / "red.db"
mode, sides = make_fixture(db)
check("fixture", mode == "wal" and sides == [], "journal_mode=%s side files=%s" % (mode, sides))
before = stat(db)
o_out, o_err = run(old, db)
check("red control: old code fails", o_out == [] and "unable to open database file" in o_err,
      "returned %r; stderr %r" % (o_out, o_err))
mode, sides = make_fixture(db2 := work / "green.db")
before = stat(db2)
n_out, n_err = run(new, db2)
check("new code reads", n_out == ["o/gh", "o/agent-only"], "returned %r; stderr %r" % (n_out, n_err))
after = stat(db2)
check("fixture bytes+mtime unchanged after new read", before == after,
      "sha %s.. -> %s.., mtime %s -> %s" % (before[0][:12], after[0][:12], before[1], after[1]))
print("      side files after new read:", [s for s in ("-wal", "-shm") if Path(str(db2) + s).exists()])

# 2. Write refusal on the exact connect sequence the new code uses.
src = (clone / "utils/py/board_sync.py").read_text()
check("new code uses mode=rw + query_only", '"?mode=rw"' in src and 'PRAGMA query_only=ON' in src
      and '"?mode=ro"' not in src.split("def _rebalance_active_repos")[1].split("def resolve_selection_policy")[0],
      "connect string and pragma present in _rebalance_active_repos")
before = stat(db2)
conn = sqlite3.connect(db2.resolve().as_uri() + "?mode=rw", uri=True, timeout=2)
conn.execute("PRAGMA query_only=ON")
try:
    conn.execute("insert into github_activity values('x/y',date('now'),1,0,0,0,0,0)")
    conn.commit()
    w = "write succeeded"
except sqlite3.Error as exc:
    w = str(exc)
conn.close()
check("write refused", w == "attempt to write a readonly database", w)
check("fixture unchanged after refused write", stat(db2) == before, "sha/mtime compared")

# 3. Missing file: warns, falls back, creates nothing.
missing = work / "nope" / "rebalance.db"
m_out, m_err = run(new, missing)
check("missing file falls back", m_out == [] and "not found" in m_err, "returned %r; stderr %r" % (m_out, m_err))
check("missing file not created", not missing.exists() and not missing.parent.exists(), str(missing))

# 4. Missing path that passes is_file() can't exist; also prove mode=rw itself never creates a file.
ghost = work / "ghost.db"
try:
    sqlite3.connect(ghost.as_uri() + "?mode=rw", uri=True).execute("select 1")
    g = "opened"
except sqlite3.Error as exc:
    g = str(exc)
check("mode=rw does not create a missing file", not ghost.exists(), g)

print("RESULT:", "PASS" if all(results) else "FAIL", "(%d/%d)" % (sum(results), len(results)))
sys.exit(0 if all(results) else 1)
