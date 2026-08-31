#!/bin/bash
# test/gh204-sed-portability.sh — GH-204: in-place edits must be portable AND proven to land.
#
# The defect class: the BSD-only `sed -i ''` idiom rewrites a file UNCHANGED under GNU sed, and the
# Python lane's re.sub() does the same on a no-match — while the caller still reports success off
# the exit code. Exit code is exactly what masks the loss, so every assertion here diffs the
# destination file's CONTENT before and after, never the return status.
set -eu
source test/_setup.sh "GH-204" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"
F="$WORK/fixture"; mkdir -p "$F"

sed_flavour="bsd"; sed --version >/dev/null 2>&1 && sed_flavour="gnu"
echo "  sed flavour on this host: $sed_flavour"

# ── 1. Negative control — the OLD idiom loses the write under GNU sed ────────────────────────────
printf 'STATUS: Open\nbody line\n' > "$F/control.md"
before="$(cat "$F/control.md")"
set +e
sed -i '' 's/^STATUS:.*/STATUS: Escalated/' "$F/control.md" 2>/dev/null
old_rc=$?
set -e
after="$(cat "$F/control.md")"
if [ "$sed_flavour" = "gnu" ]; then
  [ "$before" = "$after" ] \
    || fail "control: the BSD-only form changed content under GNU sed — this probe no longer models the bug"
  pass "control: \`sed -i ''\` left CONTENT unchanged under GNU sed (rc=$old_rc) — the silently lost write"
else
  pass "control: skipped — on BSD sed the old form works; the defect is GNU/Linux-only"
fi

# ── 2. The portable idiom changes content on either flavour ──────────────────────────────────────
printf 'STATUS: Open\nbody line\n' > "$F/fixed.md"
before="$(cat "$F/fixed.md")"
sed -i.bak 's/^STATUS:.*/STATUS: Escalated/' "$F/fixed.md"; rm -f "$F/fixed.md.bak"
after="$(cat "$F/fixed.md")"
[ "$before" != "$after" ] || fail "portable idiom did not change destination CONTENT"
grep -q '^STATUS: Escalated$' "$F/fixed.md" || fail "portable idiom wrote the wrong STATUS"
[ ! -e "$F/fixed.md.bak" ] || fail "portable idiom left a .bak turd behind"
pass "portable \`sed -i.bak\` changed destination CONTENT (before != after) and cleaned its backup"

# ── 3. Python lane — re.sub() on a no-match is byte-identical; the guard must catch it ───────────
printf 'no status line here\nbody\n' > "$F/nostatus.md"
python3 - "$F/nostatus.md" <<'PY' || fail "python content-diff probe failed"
import re, sys, io
p = sys.argv[1]
before = io.open(p, encoding="utf-8").read()
# the OLD shape: silent no-op, file rewritten identically
after_old = re.sub(r'^STATUS:\s*.*$', 'STATUS: Escalated', before, flags=re.MULTILINE)
assert after_old == before, "probe invalid: re.sub changed content on a file with no STATUS: line"
# the NEW shape: subn reports 0 substitutions, so the caller can refuse to claim success
after_new, n = re.subn(r'^STATUS:\s*.*$', 'STATUS: Escalated', before, flags=re.MULTILINE)
assert n == 0, "probe invalid: expected 0 substitutions, got %d" % n
print("  PASS: re.sub() no-match is byte-identical; re.subn() reports n=0 so the write can be verified")
PY

# ── 4. Production code shape — the fixes are actually in the tree ────────────────────────────────
grep -q 're\.subn(' "$root/utils/py/relay_drive.py" \
  || fail "relay_drive.py no longer uses re.subn() for the escalation write (GH-204 regression)"
grep -q 'refusing to report an escalation that was never written' "$root/utils/py/relay_drive.py" \
  || fail "relay_drive.py lost its escalation content assertion (GH-204 regression)"
pass "relay_drive.py escalation write is content-asserted and fails loudly"

grep -q 'sed -i\.bak "s|\${REDACT_HOME}|\${REDACT_WITH}|g"' "$root/utils/build-launch-artifact.sh" \
  || fail "build-launch-artifact.sh redaction is not the portable idiom (GH-204 regression)"
grep -q 'REDACTION FAILED' "$root/utils/build-launch-artifact.sh" \
  || fail "build-launch-artifact.sh cannot report a redaction failure distinguishably from 'nothing to redact'"
grep -q 'REDACT_USER=' "$root/utils/build-launch-artifact.sh" \
  || fail "build-launch-artifact.sh residual sweep still depends on a hardcoded username"
pass "build-launch-artifact.sh redacts portably, reports failure distinguishably, derives the username"

grep -q "sed -i\.bak '/secret-notes/d'" "$root/test/meter-release.sh" \
  || fail "meter-release.sh fixture scrub is not the portable idiom (GH-204 regression)"
pass "meter-release.sh fixture scrub is portable"

# ── 5. Repo-wide sweep — no executable BSD-only call site outside the FROZEN twin ────────────────
# relay-automation/relay-drive.sh is the GH-308 frozen Bash twin: Python is authoritative and the
# twin is documented, not patched. Comment lines are excluded — several files discuss the idiom.
# This suite is excluded too: its negative control at §1 must actually RUN the old form to prove
# the write is lost, and its grep patterns quote the idiom verbatim.
#
# `.tick/` is excluded because it is gitignored runtime state, not source. Its `orphan-backups/`
# holds the relay's pre-revert copies — by design, the version of a file as it was BEFORE a fix.
# Scanning it makes this guard report a defect that was already fixed, and report it forever, since
# the backup is never supposed to change. That is a false red, and a permanently red gate is worse
# than no gate: it teaches everyone to reach for --no-verify.
residual="$(grep -rn "sed -i ''" \
    --include='*.sh' --include='*.py' --include='*.yml' --include='*.yaml' "$root" 2>/dev/null \
  | grep -v '/\.git/' \
  | grep -v '/\.tick/' \
  | grep -v '^[^:]*:[0-9]*: *#' \
  | grep -v 'relay-automation/relay-drive\.sh' \
  | grep -v 'test/gh204-sed-portability\.sh' || true)"
if [ -n "$residual" ]; then
  echo "$residual" >&2
  fail "executable BSD-only \`sed -i ''\` call sites remain (listed above)"
fi
pass "no executable \`sed -i ''\` call site outside the GH-308 frozen twin"

echo "== GH-204 ALL PASSED =="
