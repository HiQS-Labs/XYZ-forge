#!/usr/bin/env bash
# test/gh376-relay-drive-lock-parity.sh — GH-376.
#
# marathon-drive.sh:195-196 asserts, in prose, that a marathon driver and a relay driver "still
# mutually exclude in one clone" because they share one lock NAME. From a normal clone that was true.
# From a LINKED WORKTREE it was false: .git is a FILE, marathon-drive followed it to the git COMMON
# dir, and relay-drive's own inline 2-branch guess (.git is a dir -> .git/…, ELSE a hidden lock beside
# the scripts) had no case for that at all — so it locked inside the worktree instead. Two top-level
# drivers could each hold what they believed was THE mutex, against the same tree, invisible to each
# other. That topology is not exotic: it is the one swarm-preflight's own recommended invocation
# creates via RELAY_WORKTREE_ISOLATION=1.
#
# The fix routes both relay-drive twins through GH-448's shared resolver
# (relay-automation/driver-lock-lib.sh / utils/py/rtl.py::driver_lock_path), which marathon-drive's
# Python half already uses — so the two agree by construction rather than by coincidence.
#
# WHY THE OBSERVABLE IS "DOES IT REFUSE", NOT "WHAT PATH DID IT PRINT":
# the drivers never print their lock path on the happy path, and the EXIT trap removes the lock, so a
# post-hoc filesystem probe cannot see it. Holding the lock at the path MARATHON-DRIVE resolves and
# then running relay-drive is the direct test of the claim the comment makes: if relay-drive resolves
# the same path it must refuse; if it resolves anywhere else it sails past. That refusal IS the
# mutual exclusion, observed end-to-end through the real scripts rather than asserted about a string.
#
# Hermetic: a throwaway harness clone + a REAL `git worktree add`. No network, no agent, no paid turn.

set -uo pipefail

# THIS SUITE DRIVES REAL LOCK ACQUISITION, so it must own RELAY_DRIVER_LOCKED rather than inherit it.
# When validate.sh runs as a live marathon's --pre-advance-cmd, marathon_drive.py:649 has already
# exported RELAY_DRIVER_LOCKED=1 so its NESTED relay-drive skips a lock the parent already holds. The
# gate inherits that on purpose: gate_env.py deliberately does NOT scrub it (tried, landed, REVERTED
# 2026-08-07 — its docstring carries the measured 4-suite table showing neither value is right for
# the whole gate). Inherited here, every driver invocation below skips the lock block entirely and
# each "must refuse" assertion silently inverts.
#
# NOT hypothetical: this suite went 12/6 inside the Nightwatch wave-3 gate on 2026-08-11 while
# passing 18/0 standalone, and halted the marathon at phase 1 for a defect that was in this file and
# not in the phase's own work. Setting RELAY_DRIVER_LOCKED=1 and running this file reproduces it
# exactly. (Spell that invocation out rather than abbreviating the filename: test/path-integrity.sh
# reads a path-shaped token in any comment as a real reference and fails the gate on the ellipsis.)
#
# The per-suite clear is the shipped remedy for exactly this (GH-441 Phase 1), and this file is the
# fifth to need it — see test/driver-lock.sh:11, gh284-runlog-heartbeat.sh:12, gh331-cost-summary.sh:24,
# gh342-sentinel-debug-log-python.sh:27. Section F below then re-asserts the inherited=1 behaviour
# deliberately, so what cost a marathon phase is covered rather than merely avoided.
unset RELAY_DRIVER_LOCKED

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh376.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
# GH-177: guard BEFORE the physical re-capture and BEFORE the rm -rf trap is armed. A failed mktemp
# leaves $WORK empty, `cd ""` is a no-op, and `pwd -P` would then hand back the repository root
# straight into `rm -rf`. Same shape (and the same `&& exit 1` inside the braces, which the scanner
# requires in the SAME `;`-delimited segment as the `||`) as test/gh448-driver-lock-resolver.sh:37.
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
# Resolve to the PHYSICAL path first: git always reports a physical path from
# `rev-parse --path-format=absolute --git-common-dir`, and on macOS $TMPDIR lives under /var, a
# symlink to /private/var. A $TMPDIR-derived expected string would never equal git's answer.
WORK="$(cd "$WORK" && pwd -P)"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK to a physical path" >&2 && exit 1; }
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh376-relay-drive-lock-parity =="
echo "  workdir: $WORK"

# ── fixtures ─────────────────────────────────────────────────────────────────────────────────────
# A harness clone carrying the REAL scripts. relay-drive resolves its lock from its OWN location
# (ROOT_DIR = dirname(script)/..), not from a target repo, so the thing that must live in a linked
# worktree is the HARNESS itself. Same construction as gh448's section C3.
MAIN="$WORK/harness"
mkdir -p "$MAIN"
cp -R "$REPO/relay-automation" "$REPO/utils" "$REPO/bin" "$MAIN/" 2>/dev/null
git init -q "$MAIN"
git -C "$MAIN" config user.email t@example.com
git -C "$MAIN" config user.name "gh376 test"
git -C "$MAIN" add -A >/dev/null 2>&1
git -C "$MAIN" commit -qm seed >/dev/null 2>&1
WT="$WORK/harness-wt"
git -C "$MAIN" worktree add -q "$WT" -b gh376-wt-branch

[ -f "$WT/.git" ] \
  && pass "fixture: the linked worktree's .git is a FILE (the branch that had no case)" \
  || fail "fixture setup: expected $WT/.git to be a file"

# The path MARATHON-DRIVE resolves for this worktree — the git common dir, i.e. the main clone's .git.
COMMON_LOCK="$MAIN/.git/relay-driver.lock"
# The path the PRE-FIX relay-drive resolved instead: a lock local to whichever worktree it ran in.
WORKTREE_LOCAL_LOCK="$WT/.relay-driver.lock"

RELAY="$WORK/RELAY.md"
printf 'STATUS: In progress\n' > "$RELAY"

HOLDER=""
hold_lock() {  # <lock-dir> — hold it with a genuinely LIVE pid, or the GH-42 stale-reclaim path
               # fires and the driver takes the lock for a completely different (correct) reason.
  release_lock
  rm -rf "$1"; mkdir -p "$1"
  /bin/sleep 300 & HOLDER=$!
  printf '%s\n' "$HOLDER" > "$1/pid"
}
release_lock() {
  # `wait` after `kill` reaps the job so bash does not print its own "Terminated: 15" job-control
  # line to the terminal — that notice is emitted by the shell, not by the test, and cannot be
  # silenced by redirecting the kill alone.
  [ -n "$HOLDER" ] && { kill "$HOLDER" 2>/dev/null; wait "$HOLDER" 2>/dev/null; }
  HOLDER=""
}
trap 'release_lock; rm -rf "$WORK"' EXIT

run_driver() {  # <harness-root> <lane: py|sh> — prints the driver's stderr
  local h="$1" lane="$2"
  if [ "$lane" = "py" ]; then
    python3 "$h/utils/py/relay_drive.py" \
      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
  else
    XYZ_PYTHON=0 bash "$h/relay-automation/relay-drive.sh" \
      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
  fi
}
refused() { printf '%s' "$1" | grep -q 'another driver is active in this repo'; }

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# A. THE PIN — from a linked worktree, both twins now see the lock marathon-drive holds
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- A. linked worktree: relay-drive excludes against the marathon-side lock --"

hold_lock "$COMMON_LOCK"

py_out="$(run_driver "$WT" py)"
refused "$py_out" \
  && pass "THE PIN (python): relay_drive.py refuses — it resolved the git COMMON dir, like marathon-drive" \
  || fail "THE PIN FAILED (python): did not see the held lock; got: $(printf '%s' "$py_out" | head -1)"

sh_out="$(run_driver "$WT" sh)"
refused "$sh_out" \
  && pass "THE PIN (bash): relay-drive.sh refuses — the frozen twin agrees with the Python half" \
  || fail "THE PIN FAILED (bash): did not see the held lock; got: $(printf '%s' "$sh_out" | head -1)"

# Equality ALONE is not enough, and the wave-3 gate proved it: when both lanes skipped the lock they
# emitted the same NON-refusal and this assertion passed green while the two pins beside it failed.
# Requiring that the matched line is a refusal is what makes parity mean something.
if refused "$py_out" && refused "$sh_out" \
   && [ "$(printf '%s' "$py_out" | head -1)" = "$(printf '%s' "$sh_out" | head -1)" ]; then
  pass "twin parity: both lanes emit a byte-identical REFUSAL (same path, same label, same pid)"
else
  fail "twin parity: py='$(printf '%s' "$py_out" | head -1)' sh='$(printf '%s' "$sh_out" | head -1)'"
fi

[ ! -e "$WORKTREE_LOCAL_LOCK" ] \
  && pass "neither lane left a worktree-local lock behind at \$WT/.relay-driver.lock" \
  || fail "a lane created $WORKTREE_LOCAL_LOCK — it is still resolving inside the worktree"

release_lock

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# B. NEGATIVE CONTROL (per #419) — the pre-fix logic, replayed against the SAME fixture
#
# Replaying the OLD resolution must be shown to sail straight past the held lock, or section A is
# only evidence that a lock can be held at all. The Python replay restores the removed 2-branch block
# verbatim. The Bash replay swaps the sourced resolver for one carrying the old body — behaviourally
# identical to the inline block relay-drive.sh used to own, at the same call site.
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- B. negative control: pre-fix resolution does NOT exclude --"

PRE="$WORK/harness-prefix-wt"
cp -R "$WT/" "$PRE/" 2>/dev/null

python3 - "$PRE/utils/py/relay_drive.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = ('        if os.path.isdir(os.path.join(root_dir, ".git")):\n'
       '            lock_dir = os.path.join(root_dir, ".git", "relay-driver.lock")\n'
       '            lock_label = ".git/relay-driver.lock"\n'
       '        else:\n'
       '            lock_dir = os.path.join(root_dir, ".relay-driver.lock")\n'
       '            lock_label = ".relay-driver.lock"\n')
new = "        lock_dir, lock_label = driver_lock_path(root_dir)\n"
if new not in s:
    sys.exit("gh376 replay: the post-fix call site was not found — this control is vacuous")
open(p, "w").write(s.replace(new, old, 1))
PY
[ $? -eq 0 ] || fail "negative control: could not build the python pre-fix replay"

cat > "$PRE/relay-automation/driver-lock-lib.sh" <<'EOF'
#!/usr/bin/env bash
set -u
driver_lock_path_for_repo() {
  local repo="$1"
  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
  else printf '%s/.relay-driver.lock' "$repo"; fi
}
EOF

# The replay runs against the ORIGINAL worktree's common dir: $PRE is a copy of the worktree, so its
# own .git file still points at $MAIN. Hold the same lock the real drivers just honoured.
hold_lock "$COMMON_LOCK"

pre_py="$(run_driver "$PRE" py)"
refused "$pre_py" \
  && fail "negative control (python) is VACUOUS: the pre-fix logic also refused — the fixture is not exercising the worktree branch" \
  || pass "negative control (python): pre-fix 2-branch logic sails past the held lock — the defect, reproduced"

pre_sh="$(run_driver "$PRE" sh)"
refused "$pre_sh" \
  && fail "negative control (bash) is VACUOUS: the pre-fix logic also refused" \
  || pass "negative control (bash): pre-fix 2-branch logic sails past the held lock"

release_lock

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# C. CONTROL — a normal clone must behave EXACTLY as before
#
# The fix is worthless if it bought the worktree case at the cost of the common one. Run from $MAIN,
# where .git is a directory: the resolved path is unchanged, so exclusion must still hold.
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- C. control: a normal clone (.git is a directory) is unchanged --"

hold_lock "$COMMON_LOCK"

refused "$(run_driver "$MAIN" py)" \
  && pass "CONTROL (python): a normal clone still excludes at .git/relay-driver.lock" \
  || fail "CONTROL (python): the fix broke the ordinary single-clone case"
refused "$(run_driver "$MAIN" sh)" \
  && pass "CONTROL (bash): a normal clone still excludes at .git/relay-driver.lock" \
  || fail "CONTROL (bash): the fix broke the ordinary single-clone case"

release_lock

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# D. CONTROL — a vendored .xyz/ copy (no .git anywhere) still falls back beside the scripts
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- D. control: a vendored copy with no .git falls back to .relay-driver.lock --"

VEND="$WORK/vendored"
mkdir -p "$VEND"
cp -R "$MAIN/relay-automation" "$MAIN/utils" "$MAIN/bin" "$VEND/" 2>/dev/null
rm -rf "$VEND/.git"

hold_lock "$VEND/.relay-driver.lock"

vend_py="$(run_driver "$VEND" py)"
grep -q '\.relay-driver\.lock' <<<"$(refused "$vend_py" && printf '%s' "$vend_py")" \
  && pass "CONTROL (python): vendored copy resolves the hidden lock beside the scripts" \
  || fail "CONTROL (python): vendored fallback changed; got: $(printf '%s' "$vend_py" | head -1)"
vend_sh="$(run_driver "$VEND" sh)"
grep -q '\.relay-driver\.lock' <<<"$(refused "$vend_sh" && printf '%s' "$vend_sh")" \
  && pass "CONTROL (bash): vendored copy resolves the hidden lock beside the scripts" \
  || fail "CONTROL (bash): vendored fallback changed; got: $(printf '%s' "$vend_sh" | head -1)"

release_lock

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# E. SOURCE GUARDS — the resolver is REUSED, not reimplemented
#
# Sections A-D would all stay green if someone re-inlined a correct 3-branch copy into each twin.
# That is the bug class GH-448 exists to kill (a fourth and fifth construction site to drift), so it
# is pinned directly rather than left to review.
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- E. source guards: the shared resolver is called, not copied --"

grep -q 'from rtl import driver_lock_path' "$REPO/utils/py/relay_drive.py" \
  && grep -q 'lock_dir, lock_label = driver_lock_path(root_dir)' "$REPO/utils/py/relay_drive.py" \
  && pass "relay_drive.py imports and calls the shared resolver" \
  || fail "relay_drive.py no longer routes through rtl.driver_lock_path"

grep -q 'driver_lock_path_for_repo "\$ROOT_DIR"' "$REPO/relay-automation/relay-drive.sh" \
  && grep -q 'driver-lock-lib.sh' "$REPO/relay-automation/relay-drive.sh" \
  && pass "relay-drive.sh sources and calls the shared resolver" \
  || fail "relay-drive.sh no longer routes through driver-lock-lib.sh"

grep -q 'git rev-parse' "$REPO/utils/py/relay_drive.py" \
  && fail "relay_drive.py resolves a git dir itself — the resolver is being reimplemented" \
  || pass "relay_drive.py contains no git-dir resolution of its own"

# marathon-drive's own resolution is a non-goal for this lane; assert it was left alone.
grep -q 'lock_dir, lock_label = driver_lock_path(root)' "$REPO/utils/py/marathon_drive.py" \
  && pass "non-goal held: marathon_drive.py's own lock resolution is untouched" \
  || fail "marathon_drive.py's lock resolution changed — out of scope for GH-376"

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# F. THE INHERITED-FLAG CASE — pinned, not merely avoided
#
# The `unset` at the top of this file is why sections A-D are honest. But an unset alone would leave
# the behaviour it works around untested, and that behaviour is exactly what halted a marathon: with
# RELAY_DRIVER_LOCKED=1 the driver skips lock acquisition ENTIRELY and proceeds, which is correct for
# a NESTED driver whose parent already holds the lock (marathon_drive.py:649) and catastrophic for an
# assertion that assumes otherwise. Pin both directions against the SAME held lock.
# ═══════════════════════════════════════════════════════════════════════════════════════════════
echo "-- F. the inherited RELAY_DRIVER_LOCKED=1 case (nested driver, by design) --"

hold_lock "$COMMON_LOCK"

nested_py="$(RELAY_DRIVER_LOCKED=1 python3 "$WT/utils/py/relay_drive.py" \
  --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1)"
refused "$nested_py" \
  && fail "F (python): a NESTED driver must skip the lock its parent holds, but it refused" \
  || pass "F (python): RELAY_DRIVER_LOCKED=1 skips acquisition — the nested-driver contract holds"

nested_sh="$(RELAY_DRIVER_LOCKED=1 XYZ_PYTHON=0 bash "$WT/relay-automation/relay-drive.sh" \
  --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1)"
refused "$nested_sh" \
  && fail "F (bash): a NESTED driver must skip the lock its parent holds, but it refused" \
  || pass "F (bash): RELAY_DRIVER_LOCKED=1 skips acquisition on the frozen twin too"

# And the guard that would have caught the wave-3 failure at its source: with the flag cleared, the
# SAME invocation against the SAME lock must refuse. If these two ever agree, this file is inherited-
# flag-poisoned again and every "must refuse" assertion above is vacuous.
cleared_py="$(env -u RELAY_DRIVER_LOCKED python3 "$WT/utils/py/relay_drive.py" \
  --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1)"
refused "$cleared_py" \
  && pass "F: clearing the flag flips the SAME invocation back to refusing — sections A-D are honest" \
  || fail "F: flag cleared and it STILL did not refuse — A-D are vacuous, do not trust this run"

release_lock

# ── syntax ───────────────────────────────────────────────────────────────────────────────────────
echo "-- syntax check --"
bash -n "$REPO/relay-automation/relay-drive.sh" 2>/dev/null \
  && pass "syntax OK: relay-drive.sh" || fail "syntax error in relay-drive.sh"
bash -n "$HERE/gh376-relay-drive-lock-parity.sh" 2>/dev/null \
  && pass "syntax OK: gh376-relay-drive-lock-parity.sh" || fail "syntax error in this test"
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$REPO/utils/py/relay_drive.py" 2>/dev/null \
  && pass "syntax OK: relay_drive.py" || fail "syntax error in relay_drive.py"

printf '\ngh376-relay-drive-lock-parity: %d pass, %d fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
