#!/usr/bin/env bash
# GH-620: one detached-package/publisher smoke. All writes stay in a guarded temporary fixture.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh620-skills-army.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || exit 1
WORK="$(cd "$WORK" && pwd -P)"
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
    text = text.replace('    ("skills/skills-army-hq", "", "managed"),\n', "")
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
    "SKILL.md", "references/recovery.md", "references/targets.md", "scripts/intake.py", "scripts/sync.py",
}
actual = set(filter(None, git(dest, "ls-files").stdout.splitlines()))
ok("literal inclusion-only payload set", actual == expected, f"missing={sorted(expected-actual)} extra={sorted(actual-expected)}")
manifest = set(pathlib.Path(dest, "MANIFEST.txt").read_text().splitlines())
ok("manifest names exactly the nine managed payloads", manifest == expected - {"MANIFEST.txt", ".xyz-forge-revision"})
canonical_readme = pathlib.Path(src, "skills/skills-army-hq/README.md").read_bytes()
ok("root README matches its canonical package source",
   pathlib.Path(dest, "README.md").read_bytes() == canonical_readme)
if MUTANT == "1":
    print(f"gh620-skills-army-mini-sync mutant: {P} passed, {F} failed")
    sys.exit(1 if F else 0)
source_sha = git(src, "rev-parse", "HEAD").stdout.strip()
ok("revision records exact parent commit", f"source_sha={source_sha}" in pathlib.Path(dest, ".xyz-forge-revision").read_text())
head = git(dest, "rev-parse", "HEAD").stdout.strip()
r = publish("--push")
ok("republication is idempotent", r.returncode == 0 and git(dest, "rev-parse", "HEAD").stdout.strip() == head)

# A failed push leaves one exact publisher commit: rerun may push it, but an amended extra file may not.
landing = pathlib.Path(src, "skills/skills-army-hq/README.md")
landing.write_text(landing.read_text() + "\nRetry fixture.\n")
git(src, "add", str(landing)); git(src, "commit", "-qm", "publisher retry fixture")
bad = os.path.join(WORK, "bad-retry"); git(WORK, "clone", "-q", bare, bad)
r = sh(sys.executable, sync, "--target", "skills-army-mini", "--dest", bad, "--apply")
pathlib.Path(bad, "UNRELATED.md").write_text("must not travel\n")
git(bad, "add", "UNRELATED.md"); git(bad, "commit", "--amend", "--no-edit", "-q")
bad_before = git(bad, "rev-parse", "HEAD").stdout.strip()
r = sh(sys.executable, sync, "--target", "skills-army-mini", "--dest", bad, "--apply")
ok("matching metadata plus unrelated amended file is not an exact retry", r.returncode == 2 and git(bad, "rev-parse", "HEAD").stdout.strip() == bad_before, r.stderr[-200:])
r = publish("--apply")
retry_head = git(dest, "rev-parse", "HEAD").stdout.strip()
r = publish("--push")
ok("exact retained publisher commit retries push", r.returncode == 0 and git(bare, "rev-parse", "refs/heads/main").stdout.strip() == retry_head, r.stderr[-300:])

# A previously managed path dropped by the new profile must be absent in an exact retry.
drop_src = os.path.join(WORK, "drop-src"); git(WORK, "clone", "-q", src, drop_src)
drop_sync = os.path.join(drop_src, "utils/py/xyz_mini_sync.py")
drop_text = pathlib.Path(drop_sync).read_text().replace('    ("skills/skills-army-hq", "", "managed"),\n', "")
pathlib.Path(drop_sync).write_text(drop_text); git(drop_src, "add", drop_sync); git(drop_src, "commit", "-qm", "drop prior managed path")
drop_dest = os.path.join(WORK, "drop-dest"); git(WORK, "clone", "-q", bare, drop_dest)
r = sh(sys.executable, drop_sync, "--target", "skills-army-mini", "--dest", drop_dest, "--apply")
pathlib.Path(drop_dest, "README.md").write_text("malicious restore\n")
git(drop_dest, "add", "README.md"); git(drop_dest, "commit", "--amend", "--no-edit", "-q")
drop_before = git(drop_dest, "rev-parse", "HEAD").stdout.strip()
r = sh(sys.executable, drop_sync, "--target", "skills-army-mini", "--dest", drop_dest, "--apply")
ok("retry refuses a restored previously managed deletion", r.returncode == 2 and git(drop_dest, "rev-parse", "HEAD").stdout.strip() == drop_before, r.stderr[-200:])

# A retry may not use its replacement manifest to claim an operator-owned remote path.
owner_bare = os.path.join(WORK, "owner.git"); git(WORK, "clone", "-q", "--bare", bare, owner_bare)
owner_remote = os.path.join(WORK, "owner-remote"); git(WORK, "clone", "-q", owner_bare, owner_remote)
owner_manifest = pathlib.Path(owner_remote, "MANIFEST.txt")
owner_manifest.write_text("\n".join(p for p in owner_manifest.read_text().splitlines() if p != "README.md") + "\n")
pathlib.Path(owner_remote, "README.md").write_text("operator-owned remote README\n")
git(owner_remote, "add", "MANIFEST.txt", "README.md"); git(owner_remote, "commit", "-qm", "operator owns README"); git(owner_remote, "push", "-q", "origin", "main")
owner_retry = os.path.join(WORK, "owner-retry"); git(WORK, "clone", "-q", owner_bare, owner_retry)
shutil.copy(os.path.join(src, "skills/skills-army-hq/README.md"), os.path.join(owner_retry, "README.md"))
owner_manifest = pathlib.Path(owner_retry, "MANIFEST.txt")
owner_manifest.write_text("\n".join(sorted(expected - {"MANIFEST.txt", ".xyz-forge-revision"})) + "\n")
git(owner_retry, "add", "MANIFEST.txt", "README.md")
owner_message = f"sync: XYZ-forge@{git(src, 'rev-parse', 'HEAD').stdout.strip()[:12]} (fixture)"
git(owner_retry, "commit", "-qm", owner_message)
owner_before = git(owner_retry, "rev-parse", "HEAD").stdout.strip()
r = sh(sys.executable, sync, "--target", "skills-army-mini", "--dest", owner_retry, "--apply")
ok("retry refuses takeover of an unmanifested operator-owned path", r.returncode == 2 and git(owner_retry, "rev-parse", "HEAD").stdout.strip() == owner_before, r.stderr[-300:])

# Shared default profile: when a publisher retry newly restores an absent seed, it remains exact.
mini_bare = os.path.join(WORK, "mini.git"); mini_dest = os.path.join(WORK, "mini")
git(WORK, "init", "-q", "--bare", mini_bare); git(mini_bare, "symbolic-ref", "HEAD", "refs/heads/main")
git(WORK, "clone", "-q", mini_bare, mini_dest); git(mini_dest, "symbolic-ref", "HEAD", "refs/heads/main")
def mini_publish(dest_path, *extra): return sh(sys.executable, sync, "--dest", dest_path, *extra)
mini_publish(mini_dest, "--push")
seed_drop = os.path.join(WORK, "seed-drop"); git(WORK, "clone", "-q", mini_bare, seed_drop)
git(seed_drop, "rm", "-q", "TODO.md"); git(seed_drop, "commit", "-qm", "remove seed"); git(seed_drop, "push", "-q", "origin", "main")
seed_retry = os.path.join(WORK, "seed-retry"); git(WORK, "clone", "-q", mini_bare, seed_retry)
mini_publish(seed_retry, "--apply"); seed_head = git(seed_retry, "rev-parse", "HEAD").stdout.strip()
r = mini_publish(seed_retry, "--push")
ok("default-profile retry may restore an absent seed", r.returncode == 0 and git(mini_bare, "rev-parse", "refs/heads/main").stdout.strip() == seed_head, r.stderr[-300:])
seed_owner = os.path.join(WORK, "seed-owner"); git(WORK, "clone", "-q", mini_bare, seed_owner)
pathlib.Path(seed_owner, "TODO.md").write_text("child-owned seed\n")
git(seed_owner, "add", "TODO.md"); git(seed_owner, "commit", "-qm", "child owns seed"); git(seed_owner, "push", "-q", "origin", "main")
seed_bad = os.path.join(WORK, "seed-bad"); git(WORK, "clone", "-q", mini_bare, seed_bad)
shutil.copy(os.path.join(src, "mini/TODO.md"), os.path.join(seed_bad, "TODO.md"))
git(seed_bad, "add", "TODO.md")
seed_message = f"sync: XYZ-forge@{git(src, 'rev-parse', 'HEAD').stdout.strip()[:12]} (fixture)"
git(seed_bad, "commit", "-qm", seed_message)
seed_bad_before = git(seed_bad, "rev-parse", "HEAD").stdout.strip()
r = mini_publish(seed_bad, "--apply")
ok("retry refuses replacement of an existing child-owned seed", r.returncode == 2 and git(seed_bad, "rev-parse", "HEAD").stdout.strip() == seed_bad_before, r.stderr[-300:])

# Detached real-work smoke: every mutation is confined to WORK.
collection = os.path.join(WORK, "collection")
target = os.path.join(WORK, "target"); os.mkdir(target)
home = os.path.join(WORK, "home"); os.mkdir(home)
env = {**os.environ, "HOME": home, "PYTHONDONTWRITEBYTECODE": "1"}
intake = os.path.join(dest, "scripts/intake.py")
sync_child = os.path.join(dest, "scripts/sync.py")
def cli(script, *args): return sh(sys.executable, "-B", script, "--root", collection, *args, env=env)
r = cli(intake, "init")
ok("init preview leaves absent collection untouched", r.returncode == 0 and not os.path.exists(collection), r.stderr)
r = cli(intake, "--apply", "init")
ok("init apply creates copied manager", r.returncode == 0 and os.path.isfile(os.path.join(collection, "skills-army-hq/SKILL.md")), r.stderr)
ok("init excludes checkout metadata from the installed manager",
   r.returncode == 0 and not os.path.exists(os.path.join(collection, "skills-army-hq/.git")))
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
