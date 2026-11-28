#!/usr/bin/env python3
"""Build the GH-1662 foreign-repo fixture: `build_fixture.py <outdir> [--with-installer]`.

A bare origin plus a primary clone of a small repo ("acme/widgets", integration branch `main`) with NO
XYZ-forge files, 17 open PRs, and the scripted stand-in `gh` (fakegh.py). Commit dates are fixed so
the SHAs are reproducible. `--no-stack` makes #107 target main (no stacked PR). `--with-forks` adds #118 and #119, cross-repository PRs whose head branch is named `main`. `--with-installer` adds an empty-success `githooks/install.sh` to the base
commit (a consumer that ships its own installer); the default has none. Python 3.9 compatible.
"""
import json
import os
import shutil
import subprocess
import sys

out = os.path.abspath(sys.argv[1])
with_installer = "--with-installer" in sys.argv[2:]
with_forks = "--with-forks" in sys.argv[2:]  # two fork PRs whose head branch is named `main` (cross-repository)
no_stack = "--no-stack" in sys.argv[2:]  # #107 targets main instead of #106's branch (a queue with no stacked PR)
HERE = os.path.dirname(os.path.abspath(__file__))
ENV = dict(os.environ, GIT_AUTHOR_NAME="acme", GIT_AUTHOR_EMAIL="dev@example.invalid",
           GIT_COMMITTER_NAME="acme", GIT_COMMITTER_EMAIL="dev@example.invalid")
shutil.rmtree(out, ignore_errors=True)
os.makedirs(out + "/home")
ORIGIN, W = out + "/origin.git", out + "/builder"  # PR branches are made in a builder clone; the primary is cloned fresh at the end
_n = [0]


def git(cwd, *a, **kw):
    return subprocess.run(["git", "-C", cwd] + list(a), check=True, capture_output=True, text=True, env=kw.get("env", ENV))


def commit(cwd, msg):
    _n[0] += 1
    d = "2026-11-01T00:%02d:00Z" % _n[0]
    e = dict(ENV, GIT_AUTHOR_DATE=d, GIT_COMMITTER_DATE=d)
    git(cwd, "add", "-A")
    git(cwd, "commit", "-q", "-m", msg, env=e)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)


def lines(name, n=10):
    return "".join("%s line %d\n" % (name, i) for i in range(1, n + 1))


def edit(path, lineno, text):
    ls = open(path).read().splitlines(True)
    ls[lineno - 1] = text + "\n"
    write(path, "".join(ls))


subprocess.run(["git", "init", "-q", "--bare", "-b", "main", ORIGIN], check=True)
subprocess.run(["git", "clone", "-q", ORIGIN, W], check=True, capture_output=True)
git(W, "checkout", "-q", "-b", "main")
write(W + "/README.md", "widgets\n")
for f in ("src/core.py", "src/api.py", "src/ui.py", "src/util.py", "docs/guide.md", "docs/faq.md", "config/settings.json"):
    write(W + "/" + f, lines(f))
write(W + "/CHANGELOG.md", "# Changelog\n")
if with_installer:
    write(W + "/githooks/install.sh", "#!/bin/bash\nexit 0\n")
commit(W, "init")
c0 = git(W, "rev-parse", "HEAD").stdout.strip()
edit(W + "/config/settings.json", 4, "config/settings.json line 4 (main moved)")
commit(W, "main moves: settings")
git(W, "push", "-q", "origin", "main")

prs = []


def pr(number, branch, title, files, base="main", body="", draft=False, labels=(), checks="pass", frm=None, lineno=None, cross=False):
    """files: {path: (lineno, text)} or a path -> full text."""
    git(W, "checkout", "-q", "-B", branch, frm or ("origin/" + base if base == "main" else "origin/" + base))
    for path, spec in files.items():
        if isinstance(spec, tuple):
            edit(W + "/" + path, spec[0], spec[1])
        else:
            write(W + "/" + path, spec)
    commit(W, title)
    if cross:  # the head lives in a fork: only refs/pull/N/head exists in the origin, no branch
        git(W, "push", "-q", "origin", "HEAD:refs/pull/%d/head" % number)
    else:
        git(W, "push", "-q", "origin", branch)
    head = git(W, "rev-parse", "HEAD").stdout.strip()
    if not cross:
        subprocess.run(["git", "--git-dir=" + ORIGIN, "update-ref", "refs/pull/%d/head" % number, head], check=True)
    prs.append({"number": number, "headRefName": "main" if cross else branch, "cross": cross, "baseRefName": base, "title": title, "body": body,
                "draft": draft, "labels": list(labels), "checks": checks, "state": "OPEN",
                "createdAt": "2026-11-%02dT10:00:00Z" % (number - 90)})


pr(101, "feat/guide", "docs: guide", {"docs/guide.md": (2, "guide line 2 (rewritten)")})
pr(102, "feat/api-v2", "feat: api v2", {"src/core.py": (3, "core line 3 (api v2)"), "src/api.py": (2, "api line 2 (v2)")})
pr(103, "feat/core-refactor", "refactor: core", {"src/core.py": (3, "core line 3 (refactor)")})
pr(104, "feat/ui-polish", "feat: ui polish", {"src/ui.py": (2, "ui line 2 (polish)")})
pr(105, "feat/hub", "feat: hub rework (touches core, api, ui)",
   {"src/core.py": (3, "core line 3 (hub)"), "src/api.py": (2, "api line 2 (hub)"), "src/ui.py": (2, "ui line 2 (hub)")})
pr(106, "feat/faq", "docs: faq", {"docs/faq.md": (2, "faq line 2 (rewritten)")}, body="Depends on #109")
pr(107, "feat/faq-extra", "docs: faq extra (stacked on #106)", {"docs/faq-extra.md": "extra\n"}, base="main" if no_stack else "feat/faq")
pr(108, "wip/settings-ui", "wip: settings ui", {"config/settings.json": (8, "config/settings.json line 8 (wip)")}, draft=True)
pr(109, "feat/changelog", "docs: changelog entry", {"CHANGELOG.md": "# Changelog\n- entry\n"})
pr(110, "feat/util-fix", "fix: util", {"src/util.py": (6, "src/util.py line 6 (fix)")}, checks="fail")
pr(111, "feat/cycle-a", "docs: cycle a", {"docs/cycle-a.md": "a\n"}, body="Depends on #112")
pr(112, "feat/cycle-b", "docs: cycle b", {"docs/cycle-b.md": "b\n"}, body="Depends on #111")
pr(113, "feat/needs-cycle", "docs: needs the cycle", {"docs/needs-cycle.md": "n\n"}, body="Depends on #111")
pr(114, "chore/held", "chore: held PR", {"docs/held.md": "h\n"}, labels=("do not merge",))
pr(115, "feat/stale-settings", "feat: settings (branched before main moved)",
   {"config/settings.json": (4, "config/settings.json line 4 (stale branch)")}, frm=c0)
pr(117, "feat/changelog-2", "docs: another changelog entry", {"CHANGELOG.md": "# Changelog\n- other entry\n"})
pr(116, "feat/uses-util", "feat: uses util", {"src/util2.py": "u\n"}, body="Depends on #110")
if with_forks:  # the head lives in a fork, so only refs/pull/N/head exists in the origin
    pr(118, "fork-118", "docs: a fork contribution", {"docs/fork-one.md": "one\n"}, cross=True)
    pr(119, "fork-119", "docs: another fork contribution", {"docs/fork-two.md": "two\n"}, cross=True)
git(W, "checkout", "-q", "main")
subprocess.run(["git", "clone", "-q", ORIGIN, out + "/primary"], check=True, capture_output=True)
shutil.rmtree(W)

with open(out + "/ghstate.json", "w") as fh:
    json.dump({"prs": prs}, fh, indent=1)
os.makedirs(out + "/bin")
shim = out + "/bin/gh"
with open(shim, "w") as fh:
    fh.write('#!/bin/sh\nexec python3 "%s/fakegh.py" "$@"\n' % HERE)
os.chmod(shim, 0o755)
print(json.dumps({"fixture": out, "primary": out + "/primary", "prs": len(prs), "installer": with_installer, "stack": not no_stack, "forks": with_forks}))
