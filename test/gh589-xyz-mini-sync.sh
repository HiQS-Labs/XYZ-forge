#!/usr/bin/env bash
# gh589-xyz-mini-sync.sh — the six GH-589 acceptance criteria for utils/py/xyz_mini_sync.py plus
# the one ownership guard and a secret-scan red control. Throwaway source clone + bare remote only.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
echo "== test: gh589-xyz-mini-sync =="
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh589-sync.XXXXXX")"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
require_forge_root .git mini   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
fixture_guard_init "$WORK"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
unset XYZ_MINI_REPO

python3 - "$REPO" "$WORK" <<'PY'
import os, re, subprocess, sys, json
REPO, WORK = sys.argv[1], sys.argv[2]
P = F = 0
def ok(name, cond, detail=""):
    global P, F
    if cond: P += 1; print(f"  PASS: {name}")
    else: F += 1; print(f"  FAIL: {name} {detail}".rstrip())
def sh(*cmd): return subprocess.run(list(cmd), capture_output=True, text=True)
def git(repo, *a): return sh("git", "-C", repo, *a)
def read(p, mode="r"):
    with open(p, mode) as fh: return fh.read()
def write(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as fh: fh.write(s)

SRC = os.path.join(WORK, "src"); git(WORK, "clone", "-q", REPO, SRC); git(SRC, "checkout", "-q", "-b", "t")
SYNC = os.path.join(SRC, "utils/py/xyz_mini_sync.py")
BARE = os.path.join(WORK, "remote.git"); git(WORK, "init", "-q", "--bare", BARE); git(BARE, "symbolic-ref", "HEAD", "refs/heads/main")
DEST = os.path.join(WORK, "dest"); git(WORK, "clone", "-q", BARE, DEST); git(DEST, "symbolic-ref", "HEAD", "refs/heads/main")
BASE = git(SRC, "rev-parse", "HEAD").stdout.strip()
def run(*x): return sh(sys.executable, SYNC, "--dest", DEST, *x)
def commit_src(msg): git(SRC, "add", "-A"); git(SRC, "commit", "-q", "-m", msg)
def reset_src(): git(SRC, "reset", "-q", "--hard", BASE)  # throwaway clone only
def count(): return git(DEST, "rev-list", "--count", "HEAD").stdout.strip()
def remote(): return git(BARE, "rev-parse", "-q", "--verify", "refs/heads/main").stdout.strip()

r = run(); ok("preview exits 0 and writes nothing", r.returncode == 0 and os.listdir(DEST) == [".git"] and remote() == "", r.stderr[-200:])

# criterion 2: missing source → nonzero, nothing pushed
git(SRC, "mv", "LICENSE", "LICENSE.moved"); commit_src("rename")
r = run("--push"); ok("2. missing manifest source → exit 2, no push", r.returncode == 2 and remote() == "", r.stderr[-200:])
reset_src()

# secret plant → exit 4 before any write; red control: matching disabled lets it through
write(os.path.join(SRC, "mini/README.md"), read(os.path.join(SRC, "mini/README.md")) + "\nghp_" + "A" * 36 + "\n"); commit_src("plant")
r = run("--apply"); ok("secret in a shipped file → exit 4, nothing written", r.returncode == 4 and os.listdir(DEST) == [".git"], r.stderr[-200:])
write(SYNC, read(SYNC).replace("            if rx.search(data):", "            if False and rx.search(data):")); commit_src("mutant")
r = run(); ok("red control: scan disabled → the same plant passes preview", r.returncode == 0, r.stderr[-200:])
reset_src()

# first publication with push (criterion 6 + licences + debug-mantra pin + scope)
r = run("--push"); ok("first publication --push exits 0", r.returncode == 0, r.stderr[-300:])
h = git(DEST, "rev-parse", "HEAD").stdout.strip(); ok("remote main == local HEAD", bool(h) and remote() == h)
names = sorted(os.listdir(os.path.join(DEST, "skills")))
ok("skill set is exactly the eight expected", names == ["agent-chorus", "consult", "debug-mantra", "honest", "ponytail", "relay", "skill-viewer", "unstuck"], str(names))
v = sh(sys.executable, os.path.join(DEST, "skills/skill-viewer/scripts/list_skills.py"), "--json")
vn = sorted(x["name"] for x in json.loads(v.stdout)["skills"]) if v.returncode == 0 else []
ok("6. viewer names == skills on disk", vn == names, str(vn))
ok("5. debug-mantra ships without issues/419 or SOP.md", not re.findall(r"issues/419|SOP\.md", read(os.path.join(DEST, "skills/debug-mantra/SKILL.md"))))
for lic in ("LICENSE", "LICENSE-COMMERCIAL.md"):
    ok(f"{lic} byte-identical", read(os.path.join(DEST, lic), "rb") == read(os.path.join(SRC, lic), "rb"))
ok("install.sh keeps its executable bit", os.access(os.path.join(DEST, "skills/ponytail/install.sh"), os.X_OK))
ok("agent-chorus standalone pipeline did not ship", not os.path.exists(os.path.join(DEST, "skills/agent-chorus/standalone")))

# criterion 1: idempotent
c = count(); r = run("--push"); ok("1. second run: exit 0, no new commit, remote unchanged", r.returncode == 0 and count() == c and remote() == h, r.stderr[-200:])

# criterion 3: inclusion-only
write(os.path.join(SRC, "skills", "zz-unlisted", "SKILL.md"), "---\nname: zz-unlisted\ndescription: x\n---\n"); commit_src("unlisted")
r = run("--apply"); ok("3. unlisted skill never ships", r.returncode == 0 and not os.path.exists(os.path.join(DEST, "skills", "zz-unlisted")))
reset_src()

# mirror: dropped entry deleted; operator TODO.md (seed) and unrelated file survive
write(os.path.join(DEST, "TODO.md"), "my edits\n"); write(os.path.join(DEST, "NOTES.local"), "mine\n")
git(DEST, "add", "-A"); git(DEST, "commit", "-q", "-m", "operator"); git(DEST, "push", "-q", "origin", "main")
write(SYNC, read(SYNC).replace('    ("skills/honest", "skills/honest", "managed"),\n', "")); commit_src("drop honest")
r = run("--apply"); ok("dropped entry is deleted from mini", r.returncode == 0 and not os.path.exists(os.path.join(DEST, "skills/honest")), r.stderr[-200:])
ok("seeded TODO.md and unrelated NOTES.local survive", read(os.path.join(DEST, "TODO.md")) == "my edits\n" and read(os.path.join(DEST, "NOTES.local")) == "mine\n")

# the one ownership guard
write(os.path.join(DEST, "skills/honest/SKILL.md"), "operator\n"); git(DEST, "add", "-A"); git(DEST, "commit", "-q", "-m", "operator honest")
reset_src()
r = run("--apply"); ok("ownership guard: unpublished existing file → exit 2, bytes intact", r.returncode == 2 and read(os.path.join(DEST, "skills/honest/SKILL.md")) == "operator\n", r.stderr[-200:])

print(f"gh589-xyz-mini-sync: {P} passed, {F} failed"); sys.exit(1 if F else 0)
PY
