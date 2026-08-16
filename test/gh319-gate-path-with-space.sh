#!/usr/bin/env bash
# GH-319: the marathon pre-advance gate must survive a repo path containing a space.
#
# The driver builds its DEFAULT gate as a STRING and hands it to `bash -c`. Interpolating an
# unquoted root word-splits it, so a clone under ".../Documents/GH Repos/xyz-3-agents-swarm"
# produced `bash /Users/.../Documents/GH Repos/.../validate.sh`. On the machine where this was
# found, `~/Documents/GH` happened to exist as an unrelated 0-byte file, so bash
# executed THAT — returning 0 in 0.0s. All four phases of a 4-lane marathon logged "gate passed"
# while `bash validate.sh` was in fact RED.
#
# Two properties are pinned here:
#   (1) the gate actually runs the real validate.sh (marker written) and its FAILURE propagates
#       (driver exits 5), even when the root path contains a space;
#   (2) the "is the gate runnable?" preflight inspects the file the shell would really execute,
#       not the leading fragment of a split path.
# Case (0) reproduces the pre-fix construction directly so this file demonstrates the bug rather
# than merely asserting the fix.
source "$(dirname "$0")/_setup.sh" gh319-gate-path-with-space
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"

# ── (0) the pre-fix construction, reproduced ─────────────────────────────────────────────
# A root whose path splits at a point where a DECOY file exists. `bash <decoy>` succeeds
# silently, which is exactly how a red gate reported green.
SPLIT_PARENT="$WORK/split"
mkdir -p "$SPLIT_PARENT"
: > "$SPLIT_PARENT/GH"                      # the 0-byte decoy: `bash .../GH` exits 0, no output
SPACED_ROOT="$SPLIT_PARENT/GH Repos/proj"   # splits into ".../GH" + "Repos/proj/validate.sh"
mkdir -p "$SPACED_ROOT"
printf '#!/usr/bin/env bash\ntouch "%s/validate-ran"\nexit 1\n' "$WORK" > "$SPACED_ROOT/validate.sh"

rm -f "$WORK/validate-ran"
old_cmd="bash $SPACED_ROOT/validate.sh"                      # UNQUOTED — the pre-fix form
bash -c "$old_cmd" >/dev/null 2>&1; old_rc=$?
if [ "$old_rc" -eq 0 ] && [ ! -e "$WORK/validate-ran" ]; then
  pass "pre-fix: unquoted gate silently runs the decoy and reports 0 (the bug)"
else
  fail "pre-fix reproduction did not exhibit the bug (rc=$old_rc, marker=$([ -e "$WORK/validate-ran" ] && echo yes || echo no))"
fi

rm -f "$WORK/validate-ran"
new_cmd="bash $(printf '%q' "$SPACED_ROOT/validate.sh")"     # QUOTED — the fixed form
bash -c "$new_cmd" >/dev/null 2>&1; new_rc=$?
if [ "$new_rc" -eq 1 ] && [ -e "$WORK/validate-ran" ]; then
  pass "post-fix: quoted gate runs the real validate.sh and propagates its failure"
else
  fail "quoted gate did not run the real script (rc=$new_rc, marker=$([ -e "$WORK/validate-ran" ] && echo yes || echo no))"
fi

# ── driver fixture: a real marathon root at a path containing a space ────────────────────
# Same decoy shape as above so a regression cannot hide behind a nonexistent split prefix.
PARENT="$WORK/drv"
mkdir -p "$PARENT"
: > "$PARENT/GH"
ROOT="$PARENT/GH Repos/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh319@t
git -C "$ROOT" config user.name gh319
printf '.tick/\n' > "$ROOT/.gitignore"
# The real gate for this fixture: records that it ran, then FAILS. A driver that reports
# "gate passed" here is running something else.
printf '#!/usr/bin/env bash\ntouch "%s/gate-ran"\nexit 1\n' "$WORK" > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

# Stub relay-drive: stands in for the whole relay loop by marking the thread Approved, so the
# driver proceeds to the pre-advance gate — which is the only thing under test here.
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
rf=""
while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
exit 0
STUB_EOF
chmod +x "$STUB_RD"
STUB_BIN="$WORK/stub-bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"
chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"
printf '## Do a thing\nBody.\n' > "$BRIEF"

run_driver() {  # <extra-args…>
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  bash "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder claude \
    "$@"
}

# ── (1) the default gate is runnable at a spaced path (preflight must not misfire) ───────
out="$(run_driver --dry-run 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "dry-run at a spaced root passes the gate-runnable preflight"
else
  fail "dry-run at a spaced root failed (rc=$rc): $(printf '%s' "$out" | tail -3)"
fi
case "$out" in
  *"not runnable"*) fail "preflight wrongly called the default gate not-runnable at a spaced root" ;;
  *) pass "preflight raised no not-runnable error for the default gate" ;;
esac

# ── (2) a FAILING validate.sh must actually fail the phase, not silently pass ────────────
rm -f "$WORK/gate-ran"
drv_out="$(run_driver 2>&1)"; drc=$?

if [ -e "$WORK/gate-ran" ]; then
  pass "the real validate.sh at the spaced root actually executed"
else
  fail "gate never ran the real validate.sh — the path split again (rc=$drc): $(printf '%s' "$drv_out" | tail -5)"
fi
if [ "$drc" -eq 5 ]; then
  pass "a failing gate escalates the phase (exit 5 pre-advance-failed, not a false 0)"
else
  fail "expected exit 5 for a failing gate, got $drc: $(printf '%s' "$drv_out" | tail -5)"
fi

# ── (3) the XYZ_PYTHON=0 Bash fallback carries the same guarantee ────────────────────────
# GH-308 froze relay-automation/marathon-drive.sh and routes behavior fixes to the Python twin, but
# a silently-fake safety gate was made an explicit exception (agy review of PR #318). Pin both lanes
# so the Bash fallback cannot drift back into a false green.
# Its own --phase-id: p1's token is already `done` from case (2), and a spent lane takes the
# "already terminal, re-run only the gate" path instead of the one under test.
rm -f "$WORK/gate-ran"
bash_out="$(XYZ_PYTHON=0 run_driver --phase-id p2 2>&1)"; brc=$?
if [ -e "$WORK/gate-ran" ]; then
  pass "XYZ_PYTHON=0: the real validate.sh at the spaced root actually executed"
else
  fail "XYZ_PYTHON=0: gate never ran the real validate.sh (rc=$brc): $(printf '%s' "$bash_out" | tail -5)"
fi
if [ "$brc" -eq 5 ]; then
  pass "XYZ_PYTHON=0: a failing gate escalates the phase (exit 5)"
else
  fail "XYZ_PYTHON=0: expected exit 5, got $brc: $(printf '%s' "$bash_out" | tail -5)"
fi
case "$bash_out" in
  *"not runnable"*) fail "XYZ_PYTHON=0: preflight wrongly rejected the quoted default gate" ;;
  *) pass "XYZ_PYTHON=0: preflight accepts a quoted gate path containing a space" ;;
esac

echo "  gh319-gate-path-with-space: $PASS pass, $FAIL fail"
exit 0
