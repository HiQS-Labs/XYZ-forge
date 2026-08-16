#!/usr/bin/env bash
# GH-195 review follow-up: deterministic coverage for the git helpers added to
# utils/ate/scripts/run_variations.py (the ATE Aider variation fuzzer):
#   - ensure_base_commit: no crash on a 0-commit `git init` repo (the review blocker)
#   - assert_disposable_repo: refuses the harness repo + a remote-having repo (destructive-reset guard)
#   - reset_repo: rewinds tracked state but preserves the keep=log/control files
#   - detect_edit: true after a real edit, false on a clean no-op
#   - _clear_stale_index_lock: removes a planted .git/index.lock so reset can't wedge the loop
#
# The module top-imports `requests`/`yaml` (runtime deps not needed by these helpers), so the
# Python driver stubs them in sys.modules before importing — keeping this test network-free and
# dependency-free, consistent with the rest of validate.sh.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: ate-run-variations =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ate-run-variations.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export ATE_SCRIPT_DIR="$ROOT/utils/ate/scripts"
export ATE_HARNESS_ROOT="$ROOT"
export ATE_WORK="$WORK"

python3 - <<'PY'
import os, sys, types, subprocess, tempfile

# Stub the runtime deps the helpers don't use so the module imports without them.
for mod in ("requests", "yaml"):
    if mod not in sys.modules:
        sys.modules[mod] = types.ModuleType(mod)

sys.path.insert(0, os.environ["ATE_SCRIPT_DIR"])
import run_variations as rv  # noqa: E402

WORK = os.environ["ATE_WORK"]
HARNESS = os.environ["ATE_HARNESS_ROOT"]
rc = 0

def ok(cond, label):
    global rc
    print(f"  PASS: {label}" if cond else f"  FAIL: {label}", file=sys.stderr if not cond else sys.stdout)
    if not cond:
        rc = 1

def git(repo, *args, check=True):
    return subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True, check=check)

def scratch(name, with_commit=False, with_remote=False):
    d = os.path.join(WORK, name)
    os.makedirs(d, exist_ok=True)
    git(d, "init", "-q")
    git(d, "config", "user.email", "t@example.com")
    git(d, "config", "user.name", "T")
    with open(os.path.join(d, "sample.py"), "w") as f:
        f.write("def foo():\n    return 42\n")
    if with_commit:
        git(d, "add", "-A")
        git(d, "commit", "-qm", "init")
    if with_remote:
        git(d, "remote", "add", "origin", "https://example.invalid/x.git")
    return d

# 1. ensure_base_commit on a 0-commit repo does NOT crash and yields a usable base sha (blocker).
d = scratch("zero-commit")
try:
    sha = rv.ensure_base_commit(d, keep=["error_log.jsonl", "control.json"])
    ok(len(sha) == 40, "ensure_base_commit: 0-commit repo auto-commits a base (no crash)")
    ok(git(d, "rev-parse", "HEAD").stdout.strip() == sha, "ensure_base_commit: returned sha == HEAD")
except SystemExit as e:
    ok(False, f"ensure_base_commit crashed on 0-commit repo: {e}")

# 1b. keep files are NOT tracked in the auto base commit (so reset can't truncate the log later).
d = scratch("zero-commit-keep")
open(os.path.join(d, "error_log.jsonl"), "w").write('{"iteration":0}\n')
rv.ensure_base_commit(d, keep=["error_log.jsonl", "control.json"])
tracked = git(d, "ls-files").stdout.split()
ok("error_log.jsonl" not in tracked, "ensure_base_commit: keep file excluded from base commit")

# 2. ensure_base_commit on an already-committed repo returns HEAD unchanged.
d = scratch("has-commit", with_commit=True)
head = git(d, "rev-parse", "HEAD").stdout.strip()
ok(rv.ensure_base_commit(d, keep=[]) == head, "ensure_base_commit: existing HEAD returned as-is")

# 3. assert_disposable_repo refuses the harness repo itself (unconditional).
try:
    rv.assert_disposable_repo(HARNESS, HARNESS, allow_destructive=True)
    ok(False, "assert_disposable_repo: harness repo should be refused even with --allow-destructive")
except rv.RepoGuardError:
    ok(True, "assert_disposable_repo: refuses the harness repo (even with override)")

# 4. assert_disposable_repo refuses a remote-having repo unless allow_destructive.
d = scratch("has-remote", with_commit=True, with_remote=True)
try:
    rv.assert_disposable_repo(d, HARNESS, allow_destructive=False)
    ok(False, "assert_disposable_repo: remote repo should be refused without override")
except rv.RepoGuardError:
    ok(True, "assert_disposable_repo: refuses a remote-having repo without --allow-destructive")
try:
    rv.assert_disposable_repo(d, HARNESS, allow_destructive=True)
    ok(True, "assert_disposable_repo: remote repo allowed WITH --allow-destructive")
except rv.RepoGuardError:
    ok(False, "assert_disposable_repo: override should permit a remote repo")

# 5. assert_disposable_repo allows a plain scratch repo (no remote).
d = scratch("plain-scratch", with_commit=True)
try:
    rv.assert_disposable_repo(d, HARNESS, allow_destructive=False)
    ok(True, "assert_disposable_repo: plain scratch repo allowed with no override")
except rv.RepoGuardError:
    ok(False, "assert_disposable_repo: plain scratch repo should be allowed")

# 6. reset_repo rewinds a dirty tree but preserves the keep=log/control files.
d = scratch("reset-keep", with_commit=True)
base = git(d, "rev-parse", "HEAD").stdout.strip()
open(os.path.join(d, "sample.py"), "w").write("def foo():\n    '''doc'''\n    return 42\n")  # dirty edit
open(os.path.join(d, "error_log.jsonl"), "w").write("line1\nline2\n")                        # keep file
open(os.path.join(d, "stray.txt"), "w").write("junk")                                        # off-lane
rv.reset_repo(d, base, keep=["error_log.jsonl", "control.json"])
sample = open(os.path.join(d, "sample.py")).read()
ok("doc" not in sample, "reset_repo: dirty tracked edit rewound to base")
ok(not os.path.exists(os.path.join(d, "stray.txt")), "reset_repo: stray untracked file cleaned")
ok(os.path.exists(os.path.join(d, "error_log.jsonl")), "reset_repo: keep log file preserved")
ok(open(os.path.join(d, "error_log.jsonl")).read() == "line1\nline2\n",
   "reset_repo: keep log contents intact (not truncated)")

# 7. detect_edit: true after a real edit, false on a clean no-op.
d = scratch("detect-edit", with_commit=True)
base = git(d, "rev-parse", "HEAD").stdout.strip()
ok(rv.detect_edit(d, base, keep=[]) is False, "detect_edit: clean tree -> False")
open(os.path.join(d, "sample.py"), "a").write("# changed\n")
ok(rv.detect_edit(d, base, keep=[]) is True, "detect_edit: dirty working tree -> True")
git(d, "add", "-A"); git(d, "commit", "-qm", "edit")  # auto-commit style
ok(rv.detect_edit(d, base, keep=[]) is True, "detect_edit: moved HEAD (auto-commit) -> True")
# a keep-only change is not counted as an edit
d = scratch("detect-edit-keep", with_commit=True)
base = git(d, "rev-parse", "HEAD").stdout.strip()
open(os.path.join(d, "error_log.jsonl"), "w").write("x")
ok(rv.detect_edit(d, base, keep=["error_log.jsonl"]) is False,
   "detect_edit: only keep file changed -> False (not counted as an edit)")

# 8. _clear_stale_index_lock removes a planted lock so a subsequent reset can proceed.
d = scratch("stale-lock", with_commit=True)
open(os.path.join(d, ".git", "index.lock"), "w").write("")
rv._clear_stale_index_lock(d)
ok(not os.path.exists(os.path.join(d, ".git", "index.lock")), "_clear_stale_index_lock: removes stale lock")
rv._clear_stale_index_lock(d)  # no-op when absent, must not raise
ok(True, "_clear_stale_index_lock: no-op (no raise) when lock absent")

sys.exit(rc)
PY
prc=$?

if [ "$prc" -eq 0 ]; then
  echo "  ate-run-variations: all checks passed"
else
  echo "  ate-run-variations: FAILURES (python driver exit $prc)" >&2
fi
exit "$prc"
