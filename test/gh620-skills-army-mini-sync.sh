#!/usr/bin/env bash
# GH-620: one detached-package/publisher smoke. All writes stay in a guarded temporary fixture.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh620-skills-army.XXXXXX")"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

python3 - "$REPO" "$WORK" "${GH620_DROP_REQUIRED:-0}" <<'PY'
import hashlib, json, os, pathlib, shutil, subprocess, sys
REPO, WORK, MUTANT = sys.argv[1:]
P = F = 0
def ok(name, cond, detail=""):
    global P, F
    if cond: P += 1; print(f"  PASS: {name}")
    else: F += 1; print(f"  FAIL: {name} {detail}".rstrip())
def sh(*cmd, env=None): return subprocess.run(list(cmd), capture_output=True, text=True, env=env)
def git(repo, *args): return sh("git", "-C", repo, *args)
def tree(root):
    root = pathlib.Path(root)
    if not root.exists(): return None
    out = {}
    for path in sorted(root.rglob("*")):
        rel = str(path.relative_to(root))
        out[rel] = ("link:" + os.readlink(path)) if path.is_symlink() else ("file:" + hashlib.sha256(path.read_bytes()).hexdigest()) if path.is_file() else "dir"
    return out

src = os.path.join(WORK, "src")
assert git(WORK, "clone", "-q", REPO, src).returncode == 0
assert git(src, "checkout", "-q", "-b", "fixture").returncode == 0
sync = os.path.join(src, "utils/py/xyz_mini_sync.py")
if MUTANT == "1":
    text = pathlib.Path(sync).read_text()
    text = text.replace('    ("skills/skills-army-hq", "skills-army-hq", "managed"),\n', "")
    pathlib.Path(sync).write_text(text)
    git(src, "add", sync); git(src, "commit", "-qm", "drop required payload")

bare = os.path.join(WORK, "child.git")
dest = os.path.join(WORK, "child")
git(WORK, "init", "-q", "--bare", bare); git(bare, "symbolic-ref", "HEAD", "refs/heads/main")
git(WORK, "clone", "-q", bare, dest); git(dest, "symbolic-ref", "HEAD", "refs/heads/main")
def publish(*extra): return sh(sys.executable, sync, "--target", "skills-army-mini", "--dest", dest, *extra)

r = publish("--push")
ok("first publication pushes and reads back", r.returncode == 0, r.stderr[-300:])
expected = {
    ".gitignore", ".xyz-forge-revision", "LICENSE", "LICENSE-COMMERCIAL.md", "MANIFEST.txt", "README.md",
    "skills-army-hq/README.md", "skills-army-hq/SKILL.md",
    "skills-army-hq/references/recovery.md", "skills-army-hq/references/targets.md",
    "skills-army-hq/scripts/intake.py", "skills-army-hq/scripts/sync.py",
}
actual = set(filter(None, git(dest, "ls-files").stdout.splitlines()))
ok("literal inclusion-only payload set", actual == expected, f"missing={sorted(expected-actual)} extra={sorted(actual-expected)}")
manifest = set(pathlib.Path(dest, "MANIFEST.txt").read_text().splitlines())
ok("manifest names exactly the ten managed payloads", manifest == expected - {"MANIFEST.txt", ".xyz-forge-revision"})
source_sha = git(src, "rev-parse", "HEAD").stdout.strip()
ok("revision records exact parent commit", f"source_sha={source_sha}" in pathlib.Path(dest, ".xyz-forge-revision").read_text())
head = git(dest, "rev-parse", "HEAD").stdout.strip()
r = publish("--push")
ok("republication is idempotent", r.returncode == 0 and git(dest, "rev-parse", "HEAD").stdout.strip() == head)

# Detached real-work smoke: every mutation is confined to WORK.
collection = os.path.join(WORK, "collection")
target = os.path.join(WORK, "target"); os.mkdir(target)
home = os.path.join(WORK, "home"); os.mkdir(home)
env = {**os.environ, "HOME": home, "PYTHONDONTWRITEBYTECODE": "1"}
intake = os.path.join(dest, "skills-army-hq/scripts/intake.py")
sync_child = os.path.join(dest, "skills-army-hq/scripts/sync.py")
def cli(script, *args): return sh(sys.executable, "-B", script, "--root", collection, *args, env=env)
r = cli(intake, "init")
ok("init preview leaves absent collection untouched", r.returncode == 0 and not os.path.exists(collection), r.stderr)
r = cli(intake, "--apply", "init")
ok("init apply creates copied manager", r.returncode == 0 and os.path.isfile(os.path.join(collection, "skills-army-hq/SKILL.md")), r.stderr)
fixture_repo = os.path.join(WORK, "fixture-repo"); fixture = os.path.join(fixture_repo, "skills/sample")
os.makedirs(fixture)
pathlib.Path(fixture, "SKILL.md").write_text("---\nname: sample\ndescription: fixture\n---\n")
git(fixture_repo, "init", "-q"); git(fixture_repo, "add", "."); git(fixture_repo, "commit", "-qm", "fixture")
before = tree(collection)
r = cli(intake, "add", fixture)
ok("add preview is non-mutating", r.returncode == 0 and tree(collection) == before, r.stderr)
r = cli(intake, "--apply", "add", fixture)
ok("add apply catalogs fixture", r.returncode == 0 and os.path.isfile(os.path.join(collection, "sample/SKILL.md")), r.stderr)
before = tree(collection)
r = cli(intake, "targets", "--id", "fixture", "--path", target, "--consumer", "Fixture")
ok("target preview is non-mutating", r.returncode == 0 and tree(collection) == before, r.stderr)
r = cli(intake, "--apply", "targets", "--id", "fixture", "--path", target, "--consumer", "Fixture")
ok("target apply stays in temporary collection", r.returncode == 0, r.stderr)
before_collection, before_target = tree(collection), tree(target)
r = cli(sync_child)
ok("sync preview is non-mutating", r.returncode == 0 and tree(collection) == before_collection and tree(target) == before_target, r.stderr)
r = cli(sync_child, "--apply")
link = pathlib.Path(target, "sample")
ok("sync apply creates readable fixture link", r.returncode == 0 and link.is_symlink() and pathlib.Path(link, "SKILL.md").is_file(), r.stderr)
ok("catalog and link read-through identify fixture", "sample" in pathlib.Path(collection, "catalog.md").read_text() and "name: sample" in pathlib.Path(link, "SKILL.md").read_text())

# Remote advances independently: publisher must refuse before changing managed bytes.
other = os.path.join(WORK, "other"); git(WORK, "clone", "-q", bare, other)
pathlib.Path(other, "REMOTE.md").write_text("remote advance\n"); git(other, "add", "REMOTE.md"); git(other, "commit", "-qm", "remote advance"); git(other, "push", "-q", "origin", "main")
before_readme, before_head = pathlib.Path(dest, "README.md").read_bytes(), git(dest, "rev-parse", "HEAD").stdout.strip()
r = publish("--apply")
ok("stale destination refuses before writes", r.returncode == 2 and pathlib.Path(dest, "README.md").read_bytes() == before_readme and git(dest, "rev-parse", "HEAD").stdout.strip() == before_head, r.stderr[-200:])

print(f"gh620-skills-army-mini-sync: {P} passed, {F} failed")
sys.exit(1 if F else 0)
PY
