#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh417-turn-root-symlink-prefix.sh. GH-261's both-sides canonicalization is reverted inside the fixture, in a COPY of relay-turn-lib.sh, and the same Python turn is re-driven. Pre-fix result: exit 6, 'OFF-ALLOWLIST change: relay.md -- reverting' -- the turn's own relay-file append is rejected as off-lane. Post-fix result: exit 0, both the relay append and the ALLOW_PATHS artifact edit survive. The same reverted copy driven with ROOT pinned to the LOGICAL form exits 0, which is what makes ROOT's symlink form -- not the fixture -- the thing the failure turns on. All three observed in one run."}
# GH-417: `git rev-parse --show-toplevel` is SAFE as utils/py/rtl.py:resolve_turn_root's default,
# and this file is the evidence for that sentence.
#
# The tree used to assert both halves of a contradiction. resolve_turn_root() deliberately defaults
# ROOT to `--show-toplevel` (GH-296, so a shim invoked from inside a same-repo vendored .xyz/ roots at
# the TRUE target repo). relay-turn-lib.sh's GH-160 collapse carried a comment calling that same
# construct the bug, "caught live." Nothing reconciled them and no test could tell them apart.
#
# Both statements are true, of DIFFERENT things, and the difference is one commit:
#
#   `--show-toplevel` returns the PHYSICAL path (/private/var/... on macOS) while a caller builds the
#   relay-file path from its own $PWD (logical, /var/...). rtl_init strips RTL_ROOT's prefix off each
#   absolute allowlist entry to get a repo-relative path. Mismatched forms => the strip is a silent
#   no-op => the entry survives absolute => it fails its own off-lane match => the whole turn is
#   reverted as a containment violation, exit 6.
#
#   GH-261 (312a2c3, 2026-07-21) fixed that by canonicalizing BOTH sides to physical form before
#   stripping. That commit names test/marathon-drive.sh's GH-171/GH-172 cases in its own message; they
#   are the failures Marathon Plan K measured on 2026-07-19 and never explained. Plan K's Wave 1 read
#   the un-reconciled comment, blamed `--show-toplevel`, and was two days early.
#
#   So the GH-160 comment is right about the GH-160 collapse -- that collapse must not change
#   RTL_ROOT's symlink form, because it runs BEFORE this normalization. It was never a verdict on
#   resolve_turn_root's default, which runs on the other side of the fix that makes either form work.
#
# Pinned here:
#   (1) a Python turn shim with its *_TURN_ROOT UNSET, driven from a repo reached through a symlinked
#       prefix, does not exit 6 for a legitimately in-allowlist edit
#   (2) the fixture actually presents that shape -- asserted, not assumed, so this cannot pass vacuously
#       on a filesystem where the logical and physical paths coincide
#   (3) the PYTHON lane really executed -- the frozen Bash twins are not certified as a proxy for it
#   (4) removing GH-261's canonicalization reproduces the exit-6 failure  <- the discriminating control
#   (5) in that same reverted tree, a LOGICAL-form ROOT still passes  <- names ROOT's symlink form as
#       the axis, which is the state the issue asked this test to distinguish
#   (6) the two halves of the tree still agree  <- criterion 4, enforced instead of merely edited once
#
# (5) is worth the extra case. Without it, (4) only proves "some change to relay-turn-lib.sh breaks
# this." With it, the pre-fix tree is shown to pass and fail purely on which symlink form ROOT arrives
# in -- the exact discrimination the issue specified, demonstrated in the state where it is visible.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" gh417-turn-root-symlink-prefix
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ── the fixture: a repo whose path reaches it through a symlinked prefix ───────────────────
# Built explicitly rather than leaning on $TMPDIR's shape. macOS gives /var -> /private/var for free,
# but Linux CI does not, and a sandbox can rewrite $TMPDIR to an already-physical path -- in either
# case the discriminating shape would silently vanish and every assertion below would pass for the
# wrong reason. An owned symlink makes the shape a property of the test.
mk_fixture() {  # <dir> -> echoes "<logical-repo-path>"
  local base="$1"
  rm -rf "$base"; mkdir -p "$base/phys/repo"
  ln -s "$base/phys" "$base/link"
  local phys="$base/phys/repo"
  git init -q "$phys"
  git -C "$phys" config user.email gh417@t
  git -C "$phys" config user.name gh417
  printf 'STATUS: Open\nNEXT: Producer\n# relay body\n' > "$phys/relay.md"
  printf '.tick/\n' > "$phys/.gitignore"
  printf 'seed\n' > "$phys/artifact.md"
  git -C "$phys" add relay.md .gitignore artifact.md >/dev/null 2>&1
  git -C "$phys" commit -q -m seed
  printf '%s/link/repo' "$base"
}

# Stub `agy`: performs the real turn-taker contract -- claim, append to the relay file (always
# allowlisted), edit the ALLOW_PATHS artifact (a legitimate builder edit), release.
STUB="$WORK/agy"
cat > "$STUB" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
{ [ "${1:-}" = whoami ] || [ "${1:-}" = models ]; } && { printf 'agy@example.test\n'; exit 0; }
[ "${1:-}" = models ] && { printf 'Gemini 3.5 Flash\n'; exit 0; }
printf 'agy-stub: model response for %s\n' "$RELAY_AGENT"
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s (agy-stub)\n' "$RELAY_AGENT" >> "$RELAY_FILE"
printf 'builder-edit\n' >> "$GH417_REPO/artifact.md"
"$TICK_BIN" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

# A `python3` that records that it ran, then execs the real one. This is how (3) is proven: the Bash
# entry point is what a real run invokes, and it `exec`s python3 only on the Python branch -- so the
# marker file existing is the Python lane having executed, not an assumption that the default held.
REAL_PY="$(command -v python3)"
PYSHIM_DIR="$WORK/pybin"; mkdir -p "$PYSHIM_DIR"
PYMARK="$WORK/python-lane-ran"
cat > "$PYSHIM_DIR/python3" << PYSHIM_EOF
#!/usr/bin/env bash
printf 'ran\n' >> "$PYMARK"
exec "$REAL_PY" "\$@"
PYSHIM_EOF
chmod +x "$PYSHIM_DIR/python3"

# Drive one turn. <harness-root> <logical-repo> <explicit-root-or-empty> <out-prefix> -> exit code.
drive_turn() {
  local harness="$1" repo="$2" explicit="$3" out="$4"
  local tick="$harness/bin/tick"
  TICK_REPO_ROOT="$repo" "$tick" init >/dev/null 2>&1 || true
  TICK_REPO_ROOT="$repo" "$tick" log task.created GH417 --agent claude-a >/dev/null
  TICK_REPO_ROOT="$repo" "$tick" claim GH417 --agent claude-a --paths "z/**" >/dev/null
  TICK_REPO_ROOT="$repo" "$tick" release GH417 --agent claude-a --to agy >/dev/null
  : > "$out.turnlog"
  local rc=0
  # env -u cannot be used to clear AGY_TURN_ROOT and call a shell function, so the unset happens in
  # this subshell; CWD is the LOGICAL path, which is what makes resolve_turn_root's git call diverge.
  (
    cd "$repo" || exit 99
    unset AGY_TURN_ROOT
    [ -n "$explicit" ] && export AGY_TURN_ROOT="$explicit"
    PATH="$PYSHIM_DIR:$PATH" \
    RELAY_AGENT=agy RELAY_FILE="$repo/relay.md" RELAY_TASK=GH417 AGY_AGENT=agy \
    ALLOW_PATHS="artifact.md" GH417_REPO="$repo" \
    AGY_BIN="$STUB" AGY_LOG="$out.turnlog" TICK_BIN="$harness/bin/tick" \
    TICK_REPO_ROOT="$repo" XYZ_PYTHON=1 \
    bash "$harness/relay-automation/agy-turn.sh"
  ) > "$out.out" 2>&1 || rc=$?
  return "$rc"
}

# ── (2) the fixture presents the shape, before anything is concluded from it ───────────────
REPO="$(mk_fixture "$WORK/fix-main")"
TOP="$(cd "$REPO" && git rev-parse --show-toplevel)"
[ "$TOP" != "$REPO" ] \
  && pass "the fixture reaches the repo through a symlinked prefix — --show-toplevel ($TOP) differs from the invocation path ($REPO)" \
  || fail "the fixture is not discriminating: --show-toplevel returned the invocation path, so nothing below tests a symlink-form mismatch"

# ── (1)(3) the live default: *_TURN_ROOT unset, Python lane, symlinked prefix ───────────────
rc=0; drive_turn "$ROOT_REPO" "$REPO" "" "$WORK/main" || rc=$?
PHYS_REPO="$(cd "$REPO" && pwd -P)"

[ "$rc" -ne 6 ] \
  && pass "AGY_TURN_ROOT unset + symlinked prefix: the turn is NOT reverted as a containment violation (exit $rc)" \
  || fail "exit 6 — a legitimately in-allowlist edit was reverted as off-lane, the GH-171/GH-172 failure shape"
[ "$rc" -eq 0 ] \
  && pass "the turn completes cleanly (exit 0)" \
  || fail "expected exit 0, got $rc — see $WORK/main.out"
grep -q 'agy-stub' "$PHYS_REPO/relay.md" \
  && pass "the relay-file append survived — the turn's own always-allowlisted edit was not stripped" \
  || fail "the relay block is missing: the append was reverted"
grep -q 'builder-edit' "$PHYS_REPO/artifact.md" \
  && pass "the ALLOW_PATHS artifact edit survived — a legitimate builder edit is not collateral" \
  || fail "the artifact edit was reverted despite being on ALLOW_PATHS"
[ -s "$PYMARK" ] \
  && pass "the PYTHON lane executed (utils/py/agy-turn.py), so this certifies the code that runs by default — not its frozen Bash twin" \
  || fail "python3 was never invoked: the Bash fallback ran and criterion 3 is unmet"

# ── (6) the two halves of the tree agree, and stay agreeing ────────────────────────────────
# Criterion 4 asked for the disagreement to be resolved in the tree. Resolving it with one edit lasts
# until someone reverses either half; asserting it keeps them tied together. If resolve_turn_root ever
# stops using --show-toplevel, this fails and forces the comment to be updated in the same change.
grep -Fq '"--show-toplevel"' "$ROOT_REPO/utils/py/rtl.py" \
  && pass "utils/py/rtl.py:resolve_turn_root still defaults ROOT to --show-toplevel (the GH-296 design)" \
  || fail "resolve_turn_root no longer uses --show-toplevel — relay-turn-lib.sh's GH-417 note now describes code that is gone"
grep -q 'GH-417' "$ROOT_REPO/relay-automation/relay-turn-lib.sh" \
  && pass "relay-turn-lib.sh carries the GH-417 reconciliation, so the 'caught live' warning cannot be read as a verdict on resolve_turn_root" \
  || fail "the GH-417 reconciliation is gone from relay-turn-lib.sh — the tree asserts both halves again"

# ── (4) the discriminating control: revert GH-261, replay the same turn ────────────────────
# Against a COPY, so the working tree is never mutated.
CTL="$WORK/ctl-harness"
mkdir -p "$CTL"
for d in relay-automation utils bin src; do
  [ -e "$ROOT_REPO/$d" ] && cp -R "$ROOT_REPO/$d" "$CTL/$d"
done
python3 - "$CTL/relay-automation/relay-turn-lib.sh" << 'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]); s = p.read_text()
i = s.index('  local _rtl_root_phys\n')
j = s.index('  RTL_ALLOW=("${_n[@]}")', i)
s = s[:i] + '  local _n=() a\n  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done\n' + s[j:]
p.write_text(s)
PY
grep -q '_rtl_root_phys' "$CTL/relay-automation/relay-turn-lib.sh" \
  && fail "control: GH-261's canonicalization is still present in the copy — the replay below would be vacuous" \
  || pass "control: GH-261's both-sides canonicalization reverted in the fixture copy"

CREPO="$(mk_fixture "$WORK/fix-ctl")"
rc=0; drive_turn "$CTL" "$CREPO" "" "$WORK/ctl" || rc=$?
CPHYS="$(cd "$CREPO" && pwd -P)"
[ "$rc" -eq 6 ] \
  && pass "control: without GH-261 the same turn exits 6 — the defect reproduces, so the assertions above are not vacuous" \
  || fail "control: pre-fix replay did not reproduce the failure (exit $rc) — this file proves nothing"
grep -q 'OFF-ALLOWLIST change: relay.md' "$WORK/ctl.out" \
  && pass "control: the reverted turn rejects its OWN relay-file append as off-lane — the GH-171/GH-172 symptom, in words" \
  || fail "control: exit 6 for some other reason — see $WORK/ctl.out"
grep -q 'agy-stub' "$CPHYS/relay.md" \
  && fail "control: the relay block survived a turn that was supposed to be reverted" \
  || pass "control: the completed turn was thrown away, which is the cost the fix avoids"

# ── (5) same reverted tree, ROOT pinned to the LOGICAL form → passes ───────────────────────
# This is what makes ROOT's symlink form the axis. In the pre-fix state the identical fixture, stub
# and allowlist pass or fail purely on which form ROOT arrives in.
LREPO="$(mk_fixture "$WORK/fix-ctl-logical")"
rc=0; drive_turn "$CTL" "$LREPO" "$LREPO" "$WORK/ctl-logical" || rc=$?
[ "$rc" -eq 0 ] \
  && pass "control: the SAME reverted tree exits 0 when ROOT is pinned to the logical form — ROOT's symlink form is the axis, exactly as #417 specified" \
  || fail "control: logical-form ROOT also failed (exit $rc) — the exit 6 above is not attributable to ROOT's form"

echo "gh417-turn-root-symlink-prefix: $PASS pass, $FAIL fail"
