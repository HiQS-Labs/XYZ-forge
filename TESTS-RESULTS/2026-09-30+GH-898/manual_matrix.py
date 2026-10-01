#!/usr/bin/env python3
"""GH-898 manual verification matrix (evidence script, not a registered suite).

Run from a disposable full clone:  python3 TESTS-RESULTS/2026-09-30+GH-898/manual_matrix.py [--only fallback]
Exit 0 only if every assertion holds. Each assertion is on extracted, non-empty data.
`--only fallback` runs just the pinned-list-on-failure assertions (used for the red control).
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
BASE_SHA = "c42044d2"
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


def make_db(path, rows, table=True):
    conn = sqlite3.connect(path)
    if table:
        conn.execute("CREATE TABLE github_activity (repo_full_name TEXT, scan_date TEXT, commits INT, "
                     "prs_opened INT, prs_merged INT, issues_opened INT, issue_comments INT, reviews INT)")
        conn.executemany("INSERT INTO github_activity VALUES (?, date('now', ?), ?, 0, 0, 0, 0, 0)", rows)
    conn.commit()
    conn.close()


def resolve(bs, tmp, block, db=None):
    write_cfg(tmp, block)
    if db is None:
        os.environ.pop("REBALANCE_DB", None)
    else:
        os.environ["REBALANCE_DB"] = str(db)
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
        policy, label = bs._resolve_policy_and_label(required=False)
    return policy, label, err.getvalue()


def raises(bs, tmp, block, db=None):
    try:
        resolve(bs, tmp, block, db)
    except ValueError as exc:
        return str(exc)
    return None


def fallback_matrix(bs, tmp):
    pinned = ["o/pinned"]
    src = {"type": "rebalance_active", "top_n": 3}
    cases = {
        "missing DB": Path(tmp) / "nope.db",
        "empty file (no github_activity table)": Path(tmp) / "empty.db",
        "table present, zero in-window rows": Path(tmp) / "zero.db",
    }
    sqlite3.connect(cases["empty file (no github_activity table)"]).close()
    make_db(cases["table present, zero in-window rows"], [("o/old", "-40 days", 5)])
    msgs = {}
    for name, db in cases.items():
        policy, label, err = resolve(bs, tmp, {**OWNER, "repos": pinned, "repos_source": src}, db)
        check("fallback keeps pinned list: " + name, policy is not None and policy["repos"] == pinned,
              policy and policy["repos"])
        check("fallback warns: " + name, "repos_source:" in err, err)
        check("fallback label: " + name, label == "explicit (rebalance_active fell back)", label)
        msgs[name] = err
    check("schema-absent vs zero-score warnings differ",
          msgs["empty file (no github_activity table)"] != msgs["table present, zero in-window rows"])


def main():
    only_fallback = "--only" in sys.argv and "fallback" in sys.argv
    import board_sync as bs
    with tempfile.TemporaryDirectory() as tmp:
        if not only_fallback:
            # 1. absent-source compatibility against the base commit's resolver
            base = Path(tmp) / "board_sync_base.py"
            base.write_text(subprocess.run(["git", "show", BASE_SHA + ":utils/py/board_sync.py"], cwd=ROOT,
                                           capture_output=True, text=True, check=True).stdout)
            base_mod = load_module(base, "board_sync_base")
            for label, block in (("repo-only", {**OWNER, "repo": "o/r"}), ("repos-only", {**OWNER, "repos": ["o/r", "o/s"]})):
                write_cfg(tmp, block)
                os.environ.pop("REBALANCE_DB", None)
                new, lab = bs._resolve_policy_and_label()
                old = base_mod.resolve_selection_policy()
                check("absent source identical to base: " + label,
                      old is not None and json.dumps(new, sort_keys=True) == json.dumps(old, sort_keys=True) and lab is None)
            # 2. live-shaped DB: pinned first, dedupe, cap, stable order, tie-break
            db = Path(tmp) / "act.db"
            make_db(db, [("O/Pinned", "-1 days", 9), ("o/a", "-1 days", 7), ("o/b", "-2 days", 7), ("o/c", "-3 days", 5),
                         ("o/d", "-1 days", 3), ("o/zero", "-1 days", 0)])
            block = {**OWNER, "repos": ["o/pinned"], "repos_source": {"type": "rebalance_active", "top_n": 2}}
            p1, l1, _ = resolve(bs, tmp, block, db)
            p2, _, _ = resolve(bs, tmp, block, db)
            check("pinned first, case-insensitive dedupe, capped, tie-break by name",
                  p1["repos"] == ["o/pinned", "o/a", "o/b"], p1["repos"])
            check("order stable across runs", p1["repos"] == p2["repos"])
            check("label on success", l1 == "explicit+rebalance_active", l1)
            check("repos_source not in policy dict", "repos_source" not in p1)
            # 3. validation
            for name, src in (("top_n 0", {"type": "rebalance_active", "top_n": 0}),
                              ("top_n string", {"type": "rebalance_active", "top_n": "x"}),
                              ("top_n bool", {"type": "rebalance_active", "top_n": True}),
                              ("since_days 0", {"type": "rebalance_active", "since_days": 0}),
                              ("unknown type", {"type": "other"}),
                              ("top_n over SQLite int", {"type": "rebalance_active", "top_n": 2 ** 63}),
                              ("top_n + pin over SQLite int", {"type": "rebalance_active", "top_n": 2 ** 63 - 1}),
                              ("non-object", "rebalance_active")):
                err = raises(bs, tmp, {**OWNER, "repos": ["o/r"], "repos_source": src}, db)
                check("ValueError: " + name, err is not None, err)
            check("ValueError: repo + repos_source",
                  "use repos[] with repos_source" in (raises(bs, tmp, {**OWNER, "repo": "o/r", "repos_source": {"type": "rebalance_active"}}, db) or ""))
            os.environ["XYZ_GITHUB_BOARD_POLICY_REPOS_SOURCE"] = "rebalance_active"
            write_cfg(tmp, {**OWNER, "repos": ["o/r"]})
            check("ValueError: env string for repos_source", "must be an object" in (raises(bs, tmp, {**OWNER, "repos": ["o/r"]}, db) or ""))
            os.environ.pop("XYZ_GITHUB_BOARD_POLICY_REPOS_SOURCE")
            # 4. config subcommand output
            def config_out(block):
                write_cfg(tmp, block)
                env = {**os.environ, "REBALANCE_DB": str(db)}
                return json.loads(subprocess.run([sys.executable, str(ROOT / "utils/py/board_sync.py"), "config"],
                                                 env=env, capture_output=True, text=True, check=True).stdout)
            on, off = config_out(block), config_out({**OWNER, "repo": "o/r"})
            check("config shows resolved list + label only when source set",
                  on.get("selection_policy_repos") == {"repos": ["o/pinned", "o/a", "o/b"], "repos_source": "explicit+rebalance_active"}
                  and "selection_policy_repos" not in off, (on.get("selection_policy_repos"), list(off)[:3]))
            # 5. restore identity recovery (real resolver, not a hand-built result)
            dbb = Path(tmp) / "act2.db"
            make_db(dbb, [("o/x", "-1 days", 9), ("o/y", "-1 days", 8)])
            saved, _, _ = resolve(bs, tmp, {**OWNER, "repos": ["o/pinned"], "repos_source": {"type": "rebalance_active", "top_n": 2}}, db)
            drifted, _, _ = resolve(bs, tmp, {**OWNER, "repos": ["o/pinned"], "repos_source": {"type": "rebalance_active", "top_n": 2}}, dbb)
            check("membership drift makes restore refuse (policy != saved)", drifted != saved)
            recovered, lab, _ = resolve(bs, tmp, {**OWNER, "repos": saved["repos"]}, db)
            check("documented recovery reproduces the saved policy exactly", recovered == saved and lab is None,
                  (recovered["repos"], saved["repos"]))
            other, _, _ = resolve(bs, tmp, {**OWNER, "project_number": 5, "repos": saved["repos"]}, db)
            check("different board owner/number still differs", other != saved)
            # 6. live DB (skipped, and recorded as skipped, when absent)
            os.environ.pop("REBALANCE_DB", None)
            live = bs._rebalance_db_path()
            if live is None:
                print("SKIP live DB probe: no rebalanceOS DB on this machine")
            else:
                p, lab, err = resolve(bs, tmp, {**OWNER, "repos": ["o/pinned"], "repos_source": {"type": "rebalance_active", "top_n": 5}})
                check("live DB: pinned first, non-empty, owner/name shaped",
                      p["repos"][0] == "o/pinned" and len(p["repos"]) > 1 and all("/" in r for r in p["repos"]), (p["repos"], err))
                print("LIVE repos:", p["repos"])
        fallback_matrix(bs, tmp)
    print("RESULT:", "FAIL " + ", ".join(FAILS) if FAILS else "ALL PASS")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
