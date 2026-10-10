#!/usr/bin/env python3
"""GH-1016 manual check (recorded under TESTS-RESULTS per AGENTS.md *No new tests*; not a suite).

Usage: python3 identity_check.py <dir containing releases_app.py, wave_reconcile.py, harness_paths.py>

Builds throwaway AEGIS-shaped ledgers in a temp dir and prints one JSON line per case and a final
summary line. The exit status is 0 only when every case matches the GH-1016 acceptance. Run it against
the pre-fix tree as a red control: that run must exit 1.
"""
import contextlib, io, json, os, sqlite3, subprocess, sys, tempfile

APP_DIR = os.path.abspath(sys.argv[1])
sys.path.insert(0, APP_DIR)
import releases_app as app  # noqa: E402
import wave_reconcile as wave  # noqa: E402

ORIGIN = "HiQS-Labs/AEGIS-Sleuth-Slackbot"
results = []


def git(root, *args):
    subprocess.run(["git", "-C", root, *args], check=True, capture_output=True)


def cli(root, *args):
    return subprocess.run([sys.executable, os.path.join(APP_DIR, "releases_app.py"), "--root", root, *args],
                          capture_output=True, text=True)


def fixture(base, folder, origin_url, slug=None):
    root = os.path.join(base, folder)
    os.makedirs(root)
    git(root, "init", "-q")
    if origin_url:
        git(root, "remote", "add", "origin", origin_url)
    proc = cli(root, "init", *(["--slug", slug] if slug else []))
    assert proc.returncode == 0, proc.stderr
    return root


def add_row(root, number, url):
    # A temp fixture only: rows are inserted directly so a foreign URL can exist beside an owned one.
    conn = sqlite3.connect(os.path.join(root, "releases.db"))
    repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()[0]
    conn.execute("INSERT INTO roadmap_items(global_id, repo_id, gh_number, title, section, position, "
                 "issue_url, raw_text, first_seen, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)",
                 (app.new_gid("rmi-"), repo_id, number, "fixture", "In progress", number, url,
                  "- **GH-%d · fixture** — x" % number, "2026-10-10T00:00:00Z", "2026-10-10T00:00:00Z"))
    conn.commit()
    conn.close()


def identities(root):
    conn = app.connect(os.path.join(root, "releases.db"))
    repos = {r["id"]: r["slug"] for r in conn.execute("SELECT id, slug FROM repos")}
    origin = app._origin_repo_identity(root)
    out = {r["gh_number"]: app.resolve_roadmap_identity(r, repos, origin)
           for r in conn.execute("SELECT * FROM roadmap_items")}
    conn.close()
    return out


def record(case, ok, observed):
    results.append(ok)
    print(json.dumps({"case": case, "pass": ok, "observed": observed}, sort_keys=True))


def reconcile(root, number):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        moved = wave.update_roadmap_entry(root, number, "a" * 40, "2026-10-10", dry_run=True)
    return moved, "No qualified owned roadmap row" in buf.getvalue()


with tempfile.TemporaryDirectory(prefix="gh1016-") as base:
    # 1. Legacy AEGIS shape: bare folder-name slug, differently cased/hyphenated GitHub name.
    legacy = fixture(base, "aegis-sleuth-slack-bot", "https://github.com/%s.git" % ORIGIN,
                     slug="aegis-sleuth-slack-bot")
    add_row(legacy, 221, "https://github.com/%s/issues/221" % ORIGIN)
    add_row(legacy, 300, "https://github.com/Other-Org/AEGIS-Sleuth-Slackbot/issues/300")  # same name, other owner
    add_row(legacy, 301, "https://github.com/HiQS-Labs/XYZ-forge/issues/301")              # other repo
    ids = identities(legacy)
    record("legacy-bare-own-row-valid", ids[221]["identity_valid"] and ids[221]["repo"] == ORIGIN, ids[221])
    record("legacy-foreign-same-name-other-owner-invalid", not ids[300]["identity_valid"], ids[300])
    record("legacy-foreign-other-repo-invalid", not ids[301]["identity_valid"], ids[301])
    moved, skipped = reconcile(legacy, 221)
    record("wave-reconcile-moves-own-row", moved and not skipped, {"moved": moved, "logged_skip": skipped})
    moved, skipped = reconcile(legacy, 300)
    record("wave-reconcile-skips-foreign-row", not moved and skipped, {"moved": moved, "logged_skip": skipped})

    # 2. A second repos row disables the tolerant bare match (exact match only, as before).
    conn = sqlite3.connect(os.path.join(legacy, "releases.db"))
    conn.execute("INSERT INTO repos(global_id, slug, updated_at) VALUES (?, 'other/x', '2026-10-10T00:00:00Z')",
                 (app.new_gid("repo-"),))
    conn.commit()
    conn.close()
    ids = identities(legacy)
    record("multi-repo-ledger-keeps-exact-match", not ids[221]["identity_valid"], ids[221])

    # 3. New ledgers: init records the github owner/name slug; non-github origins keep the basename.
    def slugs(root):
        conn = sqlite3.connect(os.path.join(root, "releases.db"))
        try:
            return (conn.execute("SELECT slug FROM repos").fetchall(),
                    conn.execute("SELECT value FROM settings WHERE key='repo_slug'").fetchone())
        finally:
            conn.close()

    fresh = fixture(base, "aegis-fresh-folder", "git@github.com:%s.git" % ORIGIN)
    repos, setting = slugs(fresh)
    record("init-records-origin-owner-name", repos == [(ORIGIN,)] and setting == (ORIGIN,),
           {"repos": repos, "repo_slug": list(setting)})
    add_row(fresh, 221, "https://github.com/%s/issues/221" % ORIGIN)
    record("init-fresh-own-row-valid", identities(fresh)[221]["identity_valid"], identities(fresh)[221])
    local = fixture(base, "local-origin-clone", os.path.join(base, "aegis-sleuth-slack-bot"))
    record("init-local-path-origin-keeps-basename", slugs(local)[0] == [("local-origin-clone",)], slugs(local)[0])
    bare = fixture(base, "no-origin-repo", None)
    record("init-no-origin-keeps-basename", slugs(bare)[0] == [("no-origin-repo",)], slugs(bare)[0])
    explicit = fixture(base, "explicit-slug", "https://github.com/%s.git" % ORIGIN, slug="chosen")
    record("init-explicit-slug-wins", slugs(explicit)[0] == [("chosen",)], slugs(explicit)[0])

summary = {"summary": True, "passed": sum(results), "total": len(results), "app_dir": APP_DIR}
print(json.dumps(summary, sort_keys=True))
sys.exit(0 if results and all(results) else 1)
