#!/usr/bin/env python3
"""Synthetic test suite for the rpr skill (scan.py + write_rules.py).

Hermetic: every test runs the real scripts via subprocess inside a throwaway
sandbox with HOME and CWD redirected, so the suite never reads or writes the
caller's real ~/.claude. Run it from anywhere:

    python3 utils/rpr/tests/run_tests.py

Exit code 0 = all passed, 1 = at least one failure.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
SKILL_DIR = os.path.dirname(HERE)
FIXTURES = os.path.join(HERE, "fixtures")
SCAN_PY = os.path.join(SKILL_DIR, "scan.py")
WRITE_PY = os.path.join(SKILL_DIR, "write_rules.py")

_results = []


def check(name, ok, detail=""):
    _results.append((name, bool(ok), detail))


def slug_for(path):
    """Mirror scan.py's project-dir slug exactly."""
    return re.sub(r"[^a-zA-Z0-9]", "-", path)


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)


# --------------------------------------------------------------------------
# scan.py — analysis of a synthetic transcript
# --------------------------------------------------------------------------
def test_scan(sandbox):
    home = os.path.join(sandbox, "home")
    proj = os.path.realpath(os.path.join(sandbox, "proj"))
    os.makedirs(proj, exist_ok=True)

    # Settings across all three sources scan.py reads.
    shutil.copy(os.path.join(FIXTURES, "home-settings.json"),
                _ensure(os.path.join(home, ".claude", "settings.json")))
    shutil.copy(os.path.join(FIXTURES, "home-settings.local.json"),
                _ensure(os.path.join(home, ".claude", "settings.local.json")))
    shutil.copy(os.path.join(FIXTURES, "project-settings.local.json"),
                _ensure(os.path.join(proj, ".claude", "settings.local.json")))

    # Drop the fixture transcript at the exact path scan.py computes from CWD.
    proj_slug = slug_for(proj)
    tdir = os.path.join(home, ".claude", "projects", proj_slug)
    os.makedirs(tdir, exist_ok=True)
    shutil.copy(os.path.join(FIXTURES, "transcript.jsonl"),
                os.path.join(tdir, "session.jsonl"))

    env = dict(os.environ)
    env["HOME"] = home
    proc = subprocess.run([sys.executable, SCAN_PY, "session"],
                          cwd=proj, env=env, capture_output=True, text=True)

    if proc.returncode != 0:
        check("scan: exits cleanly", False, proc.stderr.strip())
        return
    try:
        report = json.loads(proc.stdout)
    except ValueError as e:
        check("scan: emits valid JSON", False, f"{e}: {proc.stdout[:200]}")
        return
    check("scan: emits valid JSON", True)

    results = report.get("results", [])
    by_cmd = {r["command"]: r for r in results if r["tool"] == "Bash"}
    by_tool = {r["tool"]: r for r in results}

    # Filtering: already-allowed commands from all three settings sources are dropped.
    check("scan: ls -la filtered (global allow)", "ls -la" not in by_cmd)
    check("scan: pwd filtered (~/.claude/settings.local.json — B4)", "pwd" not in by_cmd)
    check("scan: git log filtered (project-local allow)", "git log --oneline -5" not in by_cmd)

    # Non-Bash/non-mcp tool calls and malformed/garbage lines are ignored.
    check("scan: count is exactly the 10 unique un-allowed calls",
          report.get("analyzed_count") == 10 and len(results) == 10,
          f"analyzed_count={report.get('analyzed_count')} len={len(results)}")

    # Dedup: two identical `git status` calls collapse to one.
    gs = [r for r in results if r["command"] == "git status"]
    check("scan: duplicate git status deduped to one", len(gs) == 1, f"found {len(gs)}")

    # Safe command -> two-word prefix rule, not dangerous.
    r = by_cmd.get("git status", {})
    a = r.get("analysis", {})
    check("scan: git status -> Bash(git status:*), safe",
          a.get("is_dangerous") is False and a.get("proposed_rules") == ["Bash(git status:*)"],
          str(a.get("proposed_rules")))

    # Dangerous -> exact-match rule, never a wildcard.
    a = by_cmd.get("rm -rf build", {}).get("analysis", {})
    check("scan: rm -rf build -> dangerous exact match",
          a.get("is_dangerous") is True and a.get("proposed_rules") == ["Bash(rm -rf build)"],
          str(a.get("proposed_rules")))

    # Compound but no env vars -> flagged compound, NOT a wrapper.
    a = by_cmd.get("cd app && npm run build", {}).get("analysis", {})
    check("scan: compound (no env) flagged, rules per segment",
          a.get("is_compound") is True and a.get("recommendation", "") == ""
          and a.get("proposed_rules") == ["Bash(cd:*)", "Bash(npm run:*)"],
          str(a.get("proposed_rules")))

    # Env vars + compound pipeline -> wrapper required, no raw rules proposed.
    a = by_cmd.get("FOO=bar BAZ=qux ./run.sh | tee log.txt", {}).get("analysis", {})
    check("scan: env+compound -> wrapper, no rules",
          a.get("has_env_vars") is True
          and a.get("recommendation", "").startswith("WRAPPER")
          and a.get("proposed_rules") == [],
          str(a.get("recommendation")))

    # Regression (B2): `npm init` must NOT be mistaken for `npm install`/`npm i`.
    a = by_cmd.get("npm init -y", {}).get("analysis", {})
    check("scan: npm init NOT dangerous (B2 regression)",
          a.get("is_dangerous") is False and a.get("proposed_rules") == ["Bash(npm init:*)"],
          str(a.get("proposed_rules")))

    # Regression (B2): `pip3 install` must be caught like `pip install`.
    a = by_cmd.get("pip3 install requests", {}).get("analysis", {})
    check("scan: pip3 install IS dangerous (B2 regression)",
          a.get("is_dangerous") is True
          and a.get("proposed_rules") == ["Bash(pip3 install requests)"],
          str(a.get("proposed_rules")))

    # MCP tool -> proposed as a bare tool-name allow.
    r = by_tool.get("mcp__github__create_issue", {})
    check("scan: mcp tool -> bare tool-name rule",
          r.get("analysis", {}).get("proposed_rules") == ["mcp__github__create_issue"],
          str(r.get("analysis", {}).get("proposed_rules")))

    # Fix 1: a compound line whose FIRST segment is covered (Bash(cd:*) is in the
    # project-local allowlist) must still surface — the npm half isn't covered, so
    # Claude would still prompt. The old whole-line startswith check wrongly hid it.
    check("scan: compound surfaced despite Bash(cd:*) on first segment (Fix 1)",
          "cd app && npm run build" in by_cmd,
          "compound was dropped — startswith over-matched the allow rule")

    # Fix 2: destructive verbs are caught even behind leading options (no broad wildcard).
    a = by_cmd.get("git -C repo push", {}).get("analysis", {})
    check("scan: git -C repo push IS dangerous, exact match (Fix 2)",
          a.get("is_dangerous") is True
          and a.get("proposed_rules") == ["Bash(git -C repo push)"],
          str(a.get("proposed_rules")))

    a = by_cmd.get("npm --prefix app install", {}).get("analysis", {})
    check("scan: npm --prefix app install IS dangerous, exact match (Fix 2)",
          a.get("is_dangerous") is True
          and a.get("proposed_rules") == ["Bash(npm --prefix app install)"],
          str(a.get("proposed_rules")))

    # Fix 2: an option-prefixed SAFE subcommand can't be safely wildcarded
    # (`Bash(git --no-pager:*)` would also cover `git --no-pager push`) -> exact match.
    a = by_cmd.get("git --no-pager log", {}).get("analysis", {})
    check("scan: git --no-pager log -> exact match + needs_exact_match (Fix 2)",
          a.get("is_dangerous") is False and a.get("needs_exact_match") is True
          and a.get("proposed_rules") == ["Bash(git --no-pager log)"],
          str(a.get("proposed_rules")))


def _ensure(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


# --------------------------------------------------------------------------
# write_rules.py — merging approved rules into a settings file
# --------------------------------------------------------------------------
def run_writer(sandbox, name, rules, settings_path):
    rules_file = os.path.join(sandbox, f"{name}.json")
    with open(rules_file, "w") as f:
        json.dump(rules, f)
    return subprocess.run([sys.executable, WRITE_PY, rules_file, settings_path],
                          capture_output=True, text=True)


def test_write_rules(sandbox):
    sp = os.path.join(sandbox, "w", ".claude", "settings.local.json")

    # Fresh file is created with both rules.
    run_writer(sandbox, "w1", ["Bash(git status:*)", "Read"], sp)
    data = json.load(open(sp))
    allow = data.get("permissions", {}).get("allow", [])
    check("write: creates file with new rules",
          allow == ["Bash(git status:*)", "Read"], str(allow))

    # Re-run: dedup existing, append only the new one.
    run_writer(sandbox, "w2", ["Bash(git status:*)", "Bash(npm run:*)"], sp)
    allow = json.load(open(sp)).get("permissions", {}).get("allow", [])
    check("write: idempotent merge (no dupes, appends new)",
          allow == ["Bash(git status:*)", "Read", "Bash(npm run:*)"], str(allow))

    # Special characters survive because the rules arrive via a file, not the shell.
    tricky = "Bash(node -e \"console.log('ok')\":*)"
    run_writer(sandbox, "w3", [tricky], sp)
    allow = json.load(open(sp)).get("permissions", {}).get("allow", [])
    check("write: special chars (quotes/parens) preserved verbatim",
          tricky in allow, str(allow))

    # Legacy allowedTools shape is honored rather than clobbered.
    legacy = os.path.join(sandbox, "legacy", "settings.json")
    write_json(legacy, {"allowedTools": ["Bash(ls:*)"]})
    run_writer(sandbox, "w4", ["Read"], legacy)
    data = json.load(open(legacy))
    check("write: legacy allowedTools honored (no permissions key added)",
          data.get("allowedTools") == ["Bash(ls:*)", "Read"] and "permissions" not in data,
          str(data))

    # Bad input (not a JSON array of strings) is rejected non-zero.
    bad = os.path.join(sandbox, "bad.json")
    with open(bad, "w") as f:
        json.dump({"not": "an array"}, f)
    proc = subprocess.run([sys.executable, WRITE_PY, bad, sp],
                          capture_output=True, text=True)
    check("write: rejects non-array input (exit 1)",
          proc.returncode == 1 and "array" in proc.stderr.lower(),
          f"rc={proc.returncode} err={proc.stderr.strip()}")


def main():
    sandbox = tempfile.mkdtemp(prefix="rpr-test-")
    try:
        test_scan(sandbox)
        test_write_rules(sandbox)
    finally:
        shutil.rmtree(sandbox, ignore_errors=True)

    passed = sum(1 for _, ok, _ in _results if ok)
    failed = len(_results) - passed
    for name, ok, detail in _results:
        mark = "PASS" if ok else "FAIL"
        line = f"  [{mark}] {name}"
        if not ok and detail:
            line += f"\n         -> {detail}"
        print(line)
    print(f"\n{passed}/{len(_results)} passed" + (f", {failed} FAILED" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
