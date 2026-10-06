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
ok("skill set is exactly the eleven expected", names == ["agent-chorus", "consult", "daily-planner", "debug-mantra", "honest", "ponytail", "relay", "review-code", "skill-viewer", "unstuck", "weekly-planner"], str(names))
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

# GH-955 --check: read-only managed parity, detached-safe, refuses write flags
def run_env(env_extra, *x): return subprocess.run([sys.executable, SYNC, *x], capture_output=True, text=True, env={**os.environ, **env_extra})
git(DEST, "checkout", "-q", "--detach")
r = run("--check"); ok("check: matching detached child → exit 0", r.returncode == 0 and "managed parity" in r.stderr, r.stderr[-200:])
git(DEST, "checkout", "-q", "main")
rel = os.path.join("skills", "relay", "SKILL.md"); orig = read(os.path.join(DEST, rel))
write(os.path.join(DEST, rel), orig + "drift\n")
r = run("--check"); ok("check: one changed managed byte → exit 1 naming the path", r.returncode == 1 and rel in r.stderr, r.stderr[-200:])
write(os.path.join(DEST, rel), orig)
ip = os.path.join(DEST, "skills", "ponytail", "install.sh"); os.chmod(ip, 0o644)
r = run("--check"); ok("check: a lost executable bit → exit 1", r.returncode == 1 and "install.sh" in r.stderr, r.stderr[-200:])
os.chmod(ip, 0o755)
head0 = git(DEST, "rev-parse", "HEAD").stdout
r = run("--check", "--apply"); ok("check + --apply → exit 2, child untouched", r.returncode == 2 and git(DEST, "rev-parse", "HEAD").stdout == head0 and not git(DEST, "status", "--porcelain").stdout, r.stderr[-200:])
os.makedirs(os.path.join(WORK, "ac-empty"), exist_ok=True)
r = run_env({"XYZ_MINI_REPO": DEST, "AGENT2AGENT_STANDALONE_REPO": os.path.join(WORK, "ac-empty")}, "--target", "xyz-mini", "--target", "agent-chorus", "--check")
ok("check: matching + drifting targets → exit 1, one summary line each", r.returncode == 1 and "xyz-mini: exit 0" in r.stderr and "agent-chorus: exit 1" in r.stderr, r.stderr[-300:])

# adapted mode: the child owns each adapted entry; mini/ORIGIN.md needs an exact row per entry
def push_dest(msg): git(DEST, "add", "-A"); git(DEST, "commit", "-q", "-m", msg); git(DEST, "push", "-q", "origin", "main")
WP = os.path.join("skills", "weekly-planner"); WPS = os.path.join(WP, "SKILL.md"); WPI = os.path.join(WP, "install.sh")
def manifest_rows(): return read(os.path.join(DEST, "MANIFEST.txt")).split()
write(os.path.join(DEST, WPS), "mini-adapted\n"); write(os.path.join(DEST, WPI), "#!/bin/sh\n# mini-only\n")
push_dest("adapt + mini-only install.sh")
write(os.path.join(SRC, "skills/3-weekly/weekly-planner/SKILL.md"), "forge-never-ships\n")
write(os.path.join(SRC, "skills/3-weekly/weekly-planner", "NEW.md"), "forge addition\n"); commit_src("forge drift + addition")
r = run("--push"); ok("adapted: child bytes kept, forge drift not shipped", r.returncode == 0 and read(os.path.join(DEST, WPS)) == "mini-adapted\n", r.stderr[-200:])
ok("adapted: child-added install.sh kept and recorded in MANIFEST.txt", os.path.exists(os.path.join(DEST, WPI)) and WPI in manifest_rows())
ok("adapted: forge addition under an established entry is not shipped", not os.path.exists(os.path.join(DEST, WP, "NEW.md")))
reset_src()
o = read(os.path.join(SRC, "mini/ORIGIN.md"))
write(os.path.join(SRC, "mini/ORIGIN.md"), "".join(l for l in o.splitlines(True) if not l.lstrip().startswith("| `" + WP))
      + "\nNotes only: " + WP + "/ and `skills/...` are mentioned here, not in a table row.\n"); commit_src("undocument weekly-planner")
r = run("--apply"); ok("adapted: entry without an exact ORIGIN row → exit 2 (a Notes mention documents nothing)", r.returncode == 2 and "without an exact row" in r.stderr and WP in r.stderr, r.stderr[-200:])
reset_src()
write(os.path.join(SRC, "mini/ORIGIN.md"), o.replace("| `" + WP + "/` | adapted |", "| `" + WP + "/` | managed |")); commit_src("wrong kind")
r = run("--apply"); ok("adapted: ORIGIN row with the wrong kind → exit 2", r.returncode == 2 and "kind adapted" in r.stderr, r.stderr[-200:])
reset_src()
write(SYNC, read(SYNC).replace('("skills/3-weekly/weekly-planner", "skills/weekly-planner", "adapted")', '("skills/3-weekly/weekly-planner", "skills/weekly-planner", "managed")')); commit_src("flip to managed")
r = run("--apply"); ok("stale ORIGIN 'adapted' row for a managed entry → exit 2, mini bytes intact", r.returncode == 2 and "still marks" in r.stderr and read(os.path.join(DEST, WPS)) == "mini-adapted\n", r.stderr[-200:])
reset_src()
write(os.path.join(SRC, "mini/ORIGIN.md"), o + "\n<!-- uncommitted -->\n")
r = run("--apply", "--allow-dirty"); ok("uncommitted ORIGIN edit + --allow-dirty → exit 2", r.returncode == 2 and "uncommitted edits" in r.stderr, r.stderr[-200:])
reset_src()
git(DEST, "rm", "-q", "--", WPS); git(DEST, "commit", "-q", "-m", "drop adapted file"); git(DEST, "push", "-q", "origin", "main")
r = run("--push"); ok("adapted: a child deletion is recorded, never re-created from forge bytes", r.returncode == 0 and not os.path.exists(os.path.join(DEST, WPS)) and WPS not in manifest_rows(), r.stderr[-200:])
write(os.path.join(DEST, WPS), "mini-adapted\n"); push_dest("restore adapted")
r = run("--push"); ok("adapted: a child re-addition is recorded on the next publication", r.returncode == 0 and WPS in manifest_rows() and read(os.path.join(DEST, WPS)) == "mini-adapted\n", r.stderr[-200:])
write(SYNC, read(SYNC).replace('    ("skills/3-weekly/weekly-planner", "skills/weekly-planner", "adapted"),\n', "")); commit_src("drop weekly-planner entry")
r = run("--push"); ok("adapted: dropping the whole entry deletes it, child-only files included", r.returncode == 0 and not os.path.exists(os.path.join(DEST, WPS)) and not os.path.exists(os.path.join(DEST, WPI)), r.stderr[-200:])
reset_src()
r = run("--push"); ok("adapted: a re-added entry is seeded fresh from forge bytes", r.returncode == 0 and os.path.isfile(os.path.join(DEST, WPS)) and read(os.path.join(DEST, WPS)) == read(os.path.join(SRC, "skills/3-weekly/weekly-planner/SKILL.md")), r.stderr[-200:])

# criterion 3: inclusion-only
write(os.path.join(SRC, "skills", "zz-unlisted", "SKILL.md"), "---\nname: zz-unlisted\ndescription: x\n---\n"); commit_src("unlisted")
r = run("--apply"); ok("3. unlisted skill never ships", r.returncode == 0 and not os.path.exists(os.path.join(DEST, "skills", "zz-unlisted")))
reset_src()

# mirror: dropped entry deleted; operator TODO.md (seed) and unrelated file survive
write(os.path.join(DEST, "TODO.md"), "my edits\n"); write(os.path.join(DEST, "NOTES.local"), "mine\n")
git(DEST, "add", "-A"); git(DEST, "commit", "-q", "-m", "operator"); git(DEST, "push", "-q", "origin", "main")
write(SYNC, read(SYNC).replace('    ("skills/3-weekly/honest", "skills/honest", "managed"),\n', "")); commit_src("drop honest")
r = run("--apply"); ok("dropped entry is deleted from mini", r.returncode == 0 and not os.path.exists(os.path.join(DEST, "skills/honest")), r.stderr[-200:])
ok("seeded TODO.md and unrelated NOTES.local survive", read(os.path.join(DEST, "TODO.md")) == "my edits\n" and read(os.path.join(DEST, "NOTES.local")) == "mine\n")

# the one ownership guard
write(os.path.join(DEST, "skills/honest/SKILL.md"), "operator\n"); git(DEST, "add", "-A"); git(DEST, "commit", "-q", "-m", "operator honest")
reset_src()
r = run("--apply"); ok("ownership guard: unpublished existing file → exit 2, bytes intact", r.returncode == 2 and read(os.path.join(DEST, "skills/honest/SKILL.md")) == "operator\n", r.stderr[-200:])

# GH-955 multi-target: dedup, --dest guard, keep going past a refused target, worst exit wins
r = run_env({}, "--target", "all", "--target", "xyz-mini", "--print-manifest")
ok("print-manifest: `all` (deduplicated) lists every profile once", r.returncode == 0 and sorted(json.loads(r.stdout)) == ["agent-chorus", "skills-army-mini", "xyz-mini"], r.stdout[:200])
r = run_env({}, "--target", "xyz-mini", "--target", "agent-chorus", "--dest", DEST)
ok("--dest with two targets → exit 2", r.returncode == 2 and "exactly one --target" in r.stderr, r.stderr[-200:])
AC_BARE = os.path.join(WORK, "ac.git"); git(WORK, "init", "-q", "--bare", AC_BARE); git(AC_BARE, "symbolic-ref", "HEAD", "refs/heads/main")
AC = os.path.join(WORK, "ac"); git(WORK, "clone", "-q", AC_BARE, AC); git(AC, "symbolic-ref", "HEAD", "refs/heads/main")
write(os.path.join(DEST, "uncommitted.txt"), "dirty\n")  # the first target in profile order (xyz-mini) refuses
r = run_env({"XYZ_MINI_REPO": DEST, "AGENT2AGENT_STANDALONE_REPO": AC}, "--target", "agent-chorus", "--target", "xyz-mini", "--push")
ok("multi-target: refused first target does not stop the next; worst exit wins", r.returncode == 2 and os.path.isfile(os.path.join(AC, "MANIFEST.txt")) and "xyz-mini: exit 2" in r.stderr and "agent-chorus: exit 0" in r.stderr, r.stderr[-300:])
os.remove(os.path.join(DEST, "uncommitted.txt"))
ok("agent-chorus: the 13 payload paths shipped, no legacy TSV", sorted(read(os.path.join(AC, "MANIFEST.txt")).split()) == sorted(d for _, d, _m in json.loads(run_env({}, "--target", "agent-chorus", "--print-manifest").stdout)) and len(read(os.path.join(AC, "MANIFEST.txt")).split()) == 13 and not os.path.exists(os.path.join(AC, "skills", "agent-chorus", "publish-manifest.tsv")))
r = run_env({"AGENT2AGENT_STANDALONE_REPO": AC}, "--target", "agent-chorus", "--check"); ok("agent-chorus: published child passes --check", r.returncode == 0, r.stderr[-200:])

print(f"gh589-xyz-mini-sync: {P} passed, {F} failed"); sys.exit(1 if F else 0)
PY
