#!/usr/bin/env python3
"""GH-1421 manual verification matrix (evidence script, not a registered suite; GH-831).

Run from a disposable full clone:  python3 TESTS-RESULTS/2026-11-11+GH-1421/manual_matrix.py [--live]
Exit 0 only if every assertion holds; each assertion is on extracted, non-empty data.
`--live` adds the read-only probes against this Mac's Rebalance DB (never written).
"""
import contextlib
import importlib.util
import io
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "utils/py"))
BASE_SHA = "046b41538"
OWNER = {"project_owner": "o", "project_number": 4, "implementation_status": "available_manual"}
FAILS = []


def check(name, cond, detail=""):
    print(("PASS " if cond else "FAIL ") + name + ((" :: " + str(detail)) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


def load_module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def write_cfg(tmp, block):
    path = Path(tmp) / "device_config.json"
    path.write_text(json.dumps({"github_board_selection_policy": block}))
    os.environ["XYZ_DEVICE_CONFIG_PATH"] = str(path)


def make_db(path, gh_rows, agent_rows=None, wal=False):
    """gh_rows: (repo, '-N days', commits). agent_rows: (repo, '-N days', runs) or None (no table)."""
    conn = sqlite3.connect(path)
    if wal:
        conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("CREATE TABLE github_activity (repo_full_name TEXT, scan_date TEXT, commits INT, "
                 "prs_opened INT, prs_merged INT, issues_opened INT, issue_comments INT, reviews INT)")
    conn.executemany("INSERT INTO github_activity VALUES (?, date('now', ?), ?, 0, 0, 0, 0, 0)", gh_rows)
    if agent_rows is not None:  # migration 0010 columns that matter here, real names/types
        conn.execute("CREATE TABLE agent_session_activity (source TEXT NOT NULL, device_id TEXT NOT NULL, "
                     "repo_full_name TEXT NOT NULL, day TEXT NOT NULL, provider TEXT NOT NULL, "
                     "threads INTEGER NOT NULL DEFAULT 0, runs INTEGER NOT NULL DEFAULT 0, "
                     "scanned_at TEXT NOT NULL, PRIMARY KEY (source, device_id, repo_full_name, day, provider))")
        conn.executemany("INSERT INTO agent_session_activity (source, device_id, repo_full_name, day, provider, "
                         "threads, runs, scanned_at) VALUES ('t3-code', 'dev1', ?, date('now', ?), 'codex', 1, ?, "
                         "'2026-11-11T00:00:00Z')", agent_rows)
    conn.commit()
    if wal:
        conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    conn.close()
    if wal:  # Apple's SQLite persists empty sidecars; Rebalance's writer leaves none (live shape)
        for suffix in ("-wal", "-shm"):
            if os.path.exists(str(path) + suffix):
                os.remove(str(path) + suffix)


def make_bad_agent_db(path):
    make_db(path, [("o/a", "-1 days", 7)])
    conn = sqlite3.connect(path)
    conn.execute("CREATE TABLE agent_session_activity (repo_full_name TEXT, day TEXT)")  # no runs column
    conn.execute("INSERT INTO agent_session_activity VALUES ('o/agentonly', date('now'))")
    conn.commit()
    conn.close()


def resolve(mod, tmp, block, db):
    write_cfg(tmp, block)
    os.environ["REBALANCE_DB"] = str(db)
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
        policy, label = mod._resolve_policy_and_label(required=False)
    return policy, label, err.getvalue()


def config_out(tmp, block, db, script):
    write_cfg(tmp, block)
    env = {**os.environ, "REBALANCE_DB": str(db)}
    r = subprocess.run([sys.executable, str(script), "config"], env=env, capture_output=True, text=True, check=True)
    return r.stdout


def main():
    import board_sync as bs
    live = "--live" in sys.argv
    with tempfile.TemporaryDirectory() as tmp:
        base_py = Path(tmp) / "board_sync_base.py"
        base_py.write_text(subprocess.run(["git", "show", BASE_SHA + ":utils/py/board_sync.py"], cwd=ROOT,
                                          capture_output=True, text=True, check=True).stdout)
        # the base copy must import its siblings from this clone's utils/py
        base = load_module(base_py, "board_sync_base")

        db = Path(tmp) / "both.db"
        make_db(db, [("o/pinned", "-1 days", 9), ("o/a", "-1 days", 7), ("o/b", "-2 days", 5), ("o/both", "-1 days", 2)],
                [("o/agentonly", "-1 days", 40), ("o/agent2", "-2 days", 3), ("O/A", "-1 days", 99),
                 ("o/both", "-1 days", 500), ("o/zero", "-1 days", 0), ("o/old", "-30 days", 50)])
        src = {"type": "rebalance_active", "top_n": 8}
        off_blocks = {"key absent": {**OWNER, "repos": ["o/pinned"], "repos_source": src},
                      "key false": {**OWNER, "repos": ["o/pinned"], "repos_source": {**src, "include_agent_sessions": False}}}
        on_block = {**OWNER, "repos": ["o/pinned"], "repos_source": {**src, "include_agent_sessions": True}}

        # A1. key off: byte-identical to the base commit (resolver + config output)
        base_policy, base_label, base_err = resolve(base, tmp, off_blocks["key absent"], db)
        for name, block in off_blocks.items():
            p, lab, err = resolve(bs, tmp, block, db)
            check("A1 key off identical to base resolver (%s)" % name,
                  base_policy and json.dumps(p, sort_keys=True) == json.dumps(base_policy, sort_keys=True)
                  and lab == base_label and err == base_err, (p and p["repos"], base_policy and base_policy["repos"]))
        # config output: run base and new scripts as subprocesses
        base_script = ROOT / "utils/py" / ".gh1421_base_board_sync.py"
        base_script.write_text(base_py.read_text())
        try:
            want = config_out(tmp, off_blocks["key absent"], db, base_script)
        finally:
            base_script.unlink()
        for name, block in off_blocks.items():
            got = config_out(tmp, block, db, ROOT / "utils/py/board_sync.py")
            check("A1 key off config output byte-identical to base (%s)" % name, want and got == want)
        p_on, lab_on, err_on = resolve(bs, tmp, on_block, db)
        check("A1 red control: key on changes the repo list", p_on["repos"] != base_policy["repos"],
              p_on["repos"])

        # A2. agent-only repo joins after GitHub-active ones; ordering rules
        expect = ["o/pinned", "o/a", "o/b", "o/both", "o/agentonly", "o/agent2"]
        check("A2 key on: GitHub order kept, agent-only appended by runs DESC; zero/old/case-dup excluded",
              p_on["repos"] == expect, p_on["repos"])
        check("A2 label on success", lab_on == "explicit+rebalance_active", lab_on)
        check("A2 no warning on success", err_on == "", err_on)
        p_off, _, _ = resolve(bs, tmp, off_blocks["key absent"], db)
        check("A2 red control: key off omits the agent-only repo", "o/agentonly" not in p_off["repos"] and p_off["repos"],
              p_off["repos"])
        capped, _, _ = resolve(bs, tmp, {**on_block, "repos_source": {**on_block["repos_source"], "top_n": 4}}, db)
        check("A2 top_n cap still applies (agent repos rank last)", capped["repos"] == expect[:5], capped["repos"])
        # A2b. multi-row aggregation (final QA F1): a zero row inserted before a positive row, and a runs tie
        multi = Path(tmp) / "multi.db"
        make_db(multi, [("o/a", "-1 days", 7)], [("o/mixed", "-1 days", 0), ("o/mixed", "-2 days", 5),
                                                 ("o/tie-b", "-1 days", 5), ("o/tie-a", "-1 days", 2), ("o/tie-a", "-2 days", 3),
                                                 ("o/zeros", "-1 days", 0), ("o/zeros", "-2 days", 0)])
        p, lab, err = resolve(bs, tmp, on_block, multi)
        check("A2b multi-row repos summed (zero row first kept); runs tie broken by name; all-zero repo excluded",
              p["repos"] == ["o/pinned", "o/a", "o/mixed", "o/tie-a", "o/tie-b"] and err == "", (p["repos"], err))
        agent_only_db = Path(tmp) / "agentonly.db"
        make_db(agent_only_db, [("o/old", "-40 days", 5)], [("o/agentonly", "-1 days", 4)])
        p, lab, err = resolve(bs, tmp, on_block, agent_only_db)
        check("A2 no GitHub activity in window: agent repos still added, no empty-window warning",
              p["repos"] == ["o/pinned", "o/agentonly"] and "no repo has activity" not in err, (p["repos"], err))

        # A3. missing agent table: warn once, GitHub list, no exception
        gh_only = Path(tmp) / "ghonly.db"
        make_db(gh_only, [("o/a", "-1 days", 7)])
        p, lab, err = resolve(bs, tmp, on_block, gh_only)
        check("A3 missing table: GitHub-derived list, no exception", p["repos"] == ["o/pinned", "o/a"], p["repos"])
        check("A3 missing table: exactly one warning naming agent_session_activity",
              err.count("board_sync:") == 1 and "agent_session_activity" in err, err)
        check("A3 red control: same DB plus the table yields the agent repo", "o/agentonly" in p_on["repos"])

        # A3b. other agent-query error keeps the GitHub rows
        bad = Path(tmp) / "badagent.db"
        make_bad_agent_db(bad)
        p, lab, err = resolve(bs, tmp, on_block, bad)
        check("A3b agent table without runs: unchanged GitHub list", p["repos"] == ["o/pinned", "o/a"], p["repos"])
        check("A3b agent table without runs: one warning naming agent_session_activity",
              err.count("board_sync:") == 1 and "agent_session_activity" in err, err)

        # A4. validation
        for bad in ("yes", 1, None):
            try:
                resolve(bs, tmp, {**on_block, "repos_source": {**src, "include_agent_sessions": bad}}, db)
                msg = None
            except ValueError as exc:
                msg = str(exc)
            check("A4 ValueError: include_agent_sessions=%r" % (bad,), msg and "include_agent_sessions" in msg, msg)

        # A5. persistent-WAL DB with no sidecars (the live failure shape), fixture form
        wal = Path(tmp) / "wal.db"
        make_db(wal, [("o/a", "-1 days", 7)], [("o/agentonly", "-1 days", 4)], wal=True)
        sidecars = [x for x in (Path(str(wal) + "-wal"), Path(str(wal) + "-shm")) if x.exists()]
        check("A5 fixture is WAL with no sidecars", not sidecars and open(wal, "rb").read(20)[18:20] == b"\x02\x02",
              sidecars)
        p, lab, err = resolve(base, tmp, off_blocks["key absent"], wal)
        check("A5 red control: base reader fails with the generic unreadable warning",
              "is unreadable (unable to open database file)" in err and lab == "explicit (rebalance_active fell back)", err)
        for name, block in (("key off", off_blocks["key absent"]), ("key on", on_block)):
            p, lab, err = resolve(bs, tmp, block, wal)
            check("A5 new reader (%s): pinned fallback, one warning naming the WAL/no-sidecar cause" % name,
                  p["repos"] == ["o/pinned"] and lab == "explicit (rebalance_active fell back)"
                  and err.count("board_sync:") == 1 and "no -shm sidecar" in err, (p["repos"], err))
        check("A5 failed read created no sidecar on this build",
              not any(Path(str(wal) + x).exists() for x in ("-wal", "-shm", "-journal")))
        holder = sqlite3.connect(wal)  # a writer connection holding the DB open creates the sidecars
        holder.execute("SELECT count(*) FROM github_activity").fetchone()
        try:
            p, lab, err = resolve(bs, tmp, on_block, wal)
            check("A5 control: with a writer holding the DB open, key on reads and merges",
                  p["repos"] == ["o/pinned", "o/a", "o/agentonly"] and err == "", (p["repos"], err))
        finally:
            holder.close()

        if live:
            os.environ.pop("REBALANCE_DB", None)
            path = bs._rebalance_db_path()
            if path is None:
                print("SKIP live: no Rebalance DB on this machine")
            else:
                live_sidecars = [x for x in ("-wal", "-shm") if Path(str(path) + x).exists()]
                print("LIVE sidecars before: %s" % live_sidecars)
                for name, mod, block in (("base", base, off_blocks["key absent"]), ("new key off", bs, off_blocks["key absent"]),
                                         ("new key on", bs, on_block)):
                    write_cfg(tmp, block)
                    err = io.StringIO()
                    with contextlib.redirect_stderr(err):
                        p, lab = mod._resolve_policy_and_label(required=False)
                    print("LIVE %s: label=%s repos=%d warn=%r" % (name, lab, len(p["repos"]), err.getvalue().strip()))
                    if name == "base" and not live_sidecars:
                        check("LIVE red control: base reader gives the generic unreadable warning",
                              "is unreadable (unable to open database file)" in err.getvalue())
                    elif live_sidecars:
                        check("LIVE %s: sidecars present (Rebalance holds the DB), normal read" % name,
                              lab == "explicit+rebalance_active" and len(p["repos"]) > 1, err.getvalue())
                    else:
                        check("LIVE %s: named-cause warning, pinned fallback" % name,
                              "no -shm sidecar" in err.getvalue() and p["repos"] == ["o/pinned"], err.getvalue())
                conn = sqlite3.connect(path.resolve().as_uri() + "?mode=ro&immutable=1", uri=True)
                try:
                    n = conn.execute("SELECT count(*) FROM agent_session_activity").fetchone()[0]
                finally:
                    conn.close()
                check("LIVE recorded working mode: ?mode=ro&immutable=1 reads agent_session_activity", n > 0, n)
                print("LIVE agent_session_activity rows via immutable: %d" % n)
    print("\n%s: %d failure(s)" % ("FAIL" if FAILS else "ALL PASS", len(FAILS)))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
