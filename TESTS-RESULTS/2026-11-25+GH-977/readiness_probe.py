"""GH-977 readiness probe (preparation receipt, not a test suite; retained manual check, GH-831).

Exit 0 ONLY when the FIXED behavior is positively observed through the real CLI; any other outcome
(bug still present, harness error, crash) exits nonzero.  The contract pairs it with
`expect_nonzero: true`, so Preflight reads "unfixed" unless this script succeeds.

Fixed behavior (issue #977 "Ask" 1): `roadmap update --raw-text` with a bullet that carries NO
`rated` token must not wipe the row's saved ratings -- it preserves them (or refuses naming the
rating it would drop).  Either way all five stored fields, including the override, are intact
afterwards.  An explicit `rated` token in the new text must still replace the scores.

All writes are confined to one resolved temp directory; the real ledger is never opened.
"""
import os
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
APP = Path("utils/py/releases_app.py").resolve()
URL = "https://github.com/org/repo/issues/977"
COLS = "rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr"


def app(repo, *args):
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    return subprocess.run([sys.executable, "-B", str(APP), "--root", str(repo), *args],
                          cwd=repo, env=env, capture_output=True, text=True, timeout=60)


def ratings(repo):
    conn = sqlite3.connect(str(repo / "releases.db"))
    try:
        return conn.execute(f"SELECT {COLS} FROM roadmap_items WHERE gh_number = 977").fetchall()
    finally:
        conn.close()


def main():
    with tempfile.TemporaryDirectory(prefix="gh977-probe-") as raw:
        repo = Path(raw).resolve() / "repo"
        (repo / "PROJECT" / "1-INBOX").mkdir(parents=True)
        (repo / "PROJECT" / "1-INBOX" / "GH-977-probe.md").write_text("probe\n")
        (repo / ".pdda-mode").write_text("ROADMAP_SOURCE=releases\n")
        subprocess.run(["git", "init", "-q", str(repo)], check=True, capture_output=True)
        for cmd in (["init", "--slug", "probe-repo"],
                    ["roadmap", "add", "--issue-num", "977", "--issue-url", URL, "--title", "probe 977",
                     "--created", "2026-11-25", "--doc-path", "PROJECT/1-INBOX/GH-977-probe.md",
                     "--raw-text", f"- **GH-977 · probe** 🆕 (rated 80/70/90/60 ovr 320) — [#977]({URL})"]):
            run = app(repo, *cmd)
            assert run.returncode == 0, (cmd, run.returncode, run.stdout, run.stderr)
        assert ratings(repo) == [(80, 70, 90, 60, 320)], ("fixture must start rated", ratings(repo))

        # the defect: a text-only update (no rated token) must leave all five fields intact
        text_only = app(repo, "roadmap", "update", "--issue-num", "977",
                        "--raw-text", f"- **GH-977 · probe retitled** 🆕 — [#977]({URL})")
        assert ratings(repo) == [(80, 70, 90, 60, 320)], ("text-only update dropped the saved rating",
                                                          ratings(repo), text_only.stdout, text_only.stderr)
        if text_only.returncode != 0:  # the refuse shape is allowed, but it must name the rating
            assert "rat" in (text_only.stdout + text_only.stderr).lower(), (text_only.stdout, text_only.stderr)

        # control: an explicit rated token still replaces the scores
        explicit = app(repo, "roadmap", "update", "--issue-num", "977",
                       "--raw-text", f"- **GH-977 · probe rescored** 🆕 (rated 10/20/30/40) — [#977]({URL})")
        assert explicit.returncode == 0, (explicit.returncode, explicit.stdout, explicit.stderr)
        assert ratings(repo)[0][:4] == (10, 20, 30, 40), ("explicit rated token must still apply", ratings(repo))
        print("text-only roadmap update preserves saved ratings; explicit rated token still replaces them")


if __name__ == "__main__":
    main()
