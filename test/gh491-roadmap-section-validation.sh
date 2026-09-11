#!/usr/bin/env bash
# GH-491: real CLI writes, shared renderer vocabulary, and witnessed red controls.
# No git operations: isolated .git directories provide only the app's lock/journal storage.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 - "$HERE/.." <<'PY'
import ast
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile

source = Path(sys.argv[1]).resolve()
app = source / "utils/py/releases_app.py"
env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
for key in ("RELEASES_APP_CRASH_AT", "RELEASES_APP_NOW"):
    env.pop(key, None)


def run(argv, cwd, extra_env=None):
    return subprocess.run(argv, cwd=cwd, env={**env, **(extra_env or {})},
                          text=True, capture_output=True)


def cli(root, *args, script=app):
    return run([sys.executable, str(script), "--root", str(root), *args], root)


def success(result):
    assert result.returncode == 0, (result.returncode, result.stdout, result.stderr)
    return result.stdout


def refused(result):
    assert result.returncode == 3, ("expected section refusal", result)
    assert "rule=invalid-section" in result.stderr, result.stderr


def row(root):
    with sqlite3.connect(root / "releases.db") as conn:
        rows = conn.execute("SELECT global_id, section, raw_text FROM roadmap_items WHERE gh_number = 491").fetchall()
        assert len(rows) == 1, rows
        return rows[0]


def snapshot(root):
    files = {str(p.relative_to(root)): p.read_bytes() for p in root.rglob("*") if p.is_file()}
    assert files and "releases.db" in files and "releases.sql" in files
    assert files["releases.db"] and files["releases.sql"]
    return files


def fixture(root):
    (root / ".git").mkdir(parents=True)
    success(cli(root, "init", "--slug", "gh491"))
    success(cli(root, "roadmap", "add", "--issue-num", "491",
                "--issue-url", "https://github.com/example/test/issues/491",
                "--title", "section validation", "--created", "2026-09-07",
                "--doc-path", "PROJECT/1-INBOX/GH-491.md"))


def assert_rendered(result, output, sections):
    success(result)
    assert output.is_file() and output.stat().st_size, "empty render"
    text = output.read_text()
    assert set(re.findall(r"^### (.+)$", text, re.M)) == set(sections), text
    for i in range(len(sections)):
        assert f"GH-{49100 + i} · section probe" in text, text


with tempfile.TemporaryDirectory(prefix="gh491-sections-") as work_dir:
    work = Path(work_dir).resolve()
    # All renderer scratch stays in this test's sandbox, including when run by a relay.
    env["TMPDIR"] = str(work)
    root = work / "ledger"
    fixture(root)
    sections = json.loads(success(cli(work, "roadmap", "sections", "--json")))
    assert sections and len(set(sections)) == len(sections), sections
    assert "Completed" in sections and "Deferred · vision" in sections
    assert "Deferred / cancelled" not in sections
    assert success(cli(work, "roadmap", "sections")).splitlines() == sections

    # Exercise BOTH parsers/handlers, BOTH selectors, and real receipt-backed SQL writes.
    for verb in ("move", "update"):
        help_text = " ".join(success(cli(work, "roadmap", verb, "--help")).split())
        assert "Deferred / cancelled" not in help_text
        for section in sections:
            assert section in help_text, (section, help_text)
        for selector in (("--issue-num", "491"), ("--gid", row(root)[0])):
            for section in sections:
                before_text = row(root)[2]
                out = success(cli(root, "roadmap", verb, *selector, "--section", section))
                assert "updated " in out, out
                assert row(root)[1:] == (section, before_text)
            for bad in ("Deferred / cancelled", "Deferred", "Backlog", "", " Completed",
                        "Completed ", "completed", "Completed\n### Backlog"):
                for dry_run in ([], ["--dry-run"]):
                    before = snapshot(root)
                    result = cli(root, "roadmap", verb, *selector, "--section", bad,
                                 "--raw-text", "- **GH-491 · must not be written**", *dry_run)
                    refused(result)
                    assert all(section in result.stderr for section in sections), result.stderr
                    if bad == "Deferred / cancelled":
                        assert "legacy markdown heading; use 'Deferred · vision'" in result.stderr
                    assert snapshot(root) == before, "refusal modified ledger or lock artifacts"
        before = snapshot(root)
        success(cli(root, "roadmap", verb, "--issue-num", "491", "--section", "Completed", "--dry-run"))
        assert snapshot(root) == before, "valid dry-run wrote artifacts"
    success(cli(root, "roadmap", "update", "--issue-num", "491",
                "--raw-text", "- **GH-491 · raw-text-only update**"))
    assert row(root)[2] == "- **GH-491 · raw-text-only update**"
    success(cli(root, "check"))
    print("PASS: move/update accepted sections, refusal guidance, selectors, atomicity, dry-run, receipts")

    # Compare observed renderer headings/rows with the CLI vocabulary, not two copied lists.
    # Seed items for each section in the fixture ledger.
    for i, section in enumerate(sections):
        success(cli(root, "roadmap", "add", "--issue-num", str(49100 + i),
                    "--issue-url", f"https://github.com/example/test/issues/{49100 + i}",
                    "--title", "section probe", "--created", "2026-09-07",
                    "--doc-path", f"PROJECT/1-INBOX/GH-{49100 + i}.md"))
        success(cli(root, "roadmap", "move", "--issue-num", str(49100 + i),
                    "--section", section))
    output = work / "rendered-roadmap.md"
    result = cli(root, "roadmap", "render", "--out", str(output))
    assert_rendered(result, output, sections)
    assert "GH-491 · raw-text-only update" in output.read_text()
    print("PASS: roadmap render uses CLI vocabulary and renders all canonical sections")

    # Red control: remove ONLY section validation in a scratch copy. The same refusal
    # assertion must fail, and the actual persisted row must contain the unknown heading.
    original = app.read_text()
    tree = ast.parse(original)
    validators = [n for n in tree.body if isinstance(n, ast.FunctionDef)
                  and n.name == "validate_roadmap_section"]
    assert len(validators) == 1, "section-validator mutation anchor missing"
    node = validators[0]
    lines = original.splitlines(keepends=True)
    lines[node.lineno - 1:node.end_lineno] = ["def validate_roadmap_section(section):\n    return section\n"]
    mutant = work / "unvalidated.py"
    mutant.write_text("".join(lines))
    result = cli(root, "roadmap", "move", "--issue-num", "491",
                 "--section", "Deferred / cancelled", script=mutant)
    success(result)
    assert row(root)[1] == "Deferred / cancelled", "mutant did not reproduce verbatim write"
    try:
        refused(result)
    except AssertionError:
        print("PASS: red control — pre-fix verbatim write fails the refusal assertion")
    else:
        raise AssertionError("refusal assertion did not detect the pre-fix behavior")

    # Red control for parity: a renderer that drops one canonical section must fail
    # the SAME observed-heading/row assertion above.
    anchor = 'parts.append("\\n### %s\\n\\n" % section)'
    assert original.count(anchor) == 1, "renderer mutation anchor missing"
    mutant_text = original.replace(anchor, 'if section != "Completed": ' + anchor)
    mutant_app = work / "mutant_render_app.py"
    mutant_app.write_text(mutant_text)
    mutant_out = work / "mutant-rendered.md"
    result = cli(root, "roadmap", "render", "--out", str(mutant_out), script=mutant_app)
    success(result)
    try:
        assert_rendered(result, mutant_out, sections)
    except AssertionError:
        print("PASS: red control — renderer vocabulary drift fails parity assertion")
    else:
        raise AssertionError("parity assertion did not detect renderer drift")

print("== GH-491 ALL PASSED ==")
PY
