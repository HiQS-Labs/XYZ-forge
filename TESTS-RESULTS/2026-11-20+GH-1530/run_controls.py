#!/usr/bin/env python3
"""GH-1530 manual controls: express.py honors CHANGELOG_WRITES.

Drives express.cmd_docs and express.is_doc_path against a throwaway repo (gh stubbed) for each
mode source (env off/landing/branch, .pdda-mode, default) and writes logs + provenance.jsonl here.
"""
import argparse, datetime, hashlib, json, os, subprocess, sys, tempfile, types
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "utils" / "py"))
import express  # noqa: E402

REV = subprocess.check_output(["git", "-C", str(REPO), "rev-parse", "HEAD"], text=True).strip()
express.gh = lambda *a, **k: types.SimpleNamespace(
    stdout=json.dumps({"state": "OPEN", "title": "Demo docs", "url": "https://example.invalid/1530"}))
express.normalize_suite = getattr(express, "normalize_suite", lambda s: s)
rows = []


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def run_docs(env_mode, file_mode):
    """Return (changelog_changed, doc_written, stdout) for one cmd_docs run."""
    os.environ.pop("CHANGELOG_WRITES", None)
    if env_mode is not None:
        os.environ["CHANGELOG_WRITES"] = env_mode
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "CHANGELOG.md").write_text("# Changelog\n\n## [Unreleased] - 2026-01-01\n\n### Fixed\n- old\n")
        if file_mode is not None:
            (Path(tmp) / ".pdda-mode").write_text("full\nCHANGELOG_WRITES=%s\n" % file_mode)
        before = sha(Path(tmp) / "CHANGELOG.md")
        args = argparse.Namespace(root=tmp, issue=1530, suite="test/gh267-express-skill.sh", slug="demo",
                                  summary="s", repo="H/H", docs_only=True, dry_run=False)
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            express.cmd_docs(args)
        doc = (Path(tmp) / "PROJECT" / "2-WORKING" / "GH-1530-demo-docs.md").exists() or any(
            (Path(tmp) / "PROJECT" / "2-WORKING").glob("GH-1530-*.md"))
        gate = express.is_doc_path(tmp, 1530, "CHANGELOG.md")
        return sha(Path(tmp) / "CHANGELOG.md") != before, doc, buf.getvalue().strip(), gate


CASES = [
    (1, "default off (no env, no file)", None, None, False),
    (2, "env off", "off", None, False),
    (3, "env landing", "landing", None, False),
    (4, "env branch", "branch", None, True),
    (5, ".pdda-mode branch", None, "branch", True),
    (6, ".pdda-mode landing", None, "landing", False),
    (7, "env off overrides .pdda-mode branch", "off", "branch", False),
]
allpass = True
for n, name, env_mode, file_mode, expect_changed in CASES:
    changed, doc, out, gate = run_docs(env_mode, file_mode)
    ok = (changed == expect_changed) and doc and (gate == expect_changed)
    allpass &= ok
    log = HERE / ("control_%d.log" % n)
    log.write_text("# control %d: %s\n# env CHANGELOG_WRITES=%r .pdda-mode=%r\n# CHANGELOG.md changed=%s (expected %s); "
                   "capture doc written=%s; is_doc_path(CHANGELOG.md)=%s\n# stdout: %s\n# status: %s\n"
                   % (n, name, env_mode, file_mode, changed, expect_changed, doc, gate, out, "PASS" if ok else "FAIL"))
    rows.append({"control": n, "name": name, "command": "express.cmd_docs --docs-only (gh stubbed) in tmp repo",
                 "candidate_revision": REV, "status": "PASS" if ok else "FAIL",
                 "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                 "log": log.name, "log_sha256": sha(log)})
    print("[%s] %d %s" % ("PASS" if ok else "FAIL", n, name))
(HERE / "provenance.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
sys.exit(0 if allpass else 1)
