#!/usr/bin/env bash
# test/gh4-ungated-clone-warning.sh — GH-4 regression.
#
# validate.sh must surface an ungated clone in-band, on the documented first-run path, WITHOUT
# blocking local validation (a prior driven-marathon attempt at this fix put a hard `exit` before
# argument parsing, breaking the documented "only pushing is affected" promise and failing
# non-executing uses like --print-mode in an otherwise-valid ungated clone — codex's review caught
# it; see test/baselines/GH-4-negative-control.md's design note). This pins BOTH directions in an
# isolated scratch clone: the warning fires (non-fatally) when ungated, and stays silent when gated.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh4-ungated-clone-warning =="

W="$(mktemp -d -t gh4-ungated-clone-warning.XXXXXX)" || { echo "  FAIL: mktemp failed" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$W"   # GH-10: pin the sandbox root
case "$W" in "") echo "  FAIL: mktemp returned EMPTY — refusing" >&2; exit 1 ;; esac
trap 'rm -rf "$W"' EXIT

# A file-copy isolation, deliberately not `git clone`: a clone reads committed history and would
# miss this suite's own uncommitted edits when run pre-commit. cp -R mirrors the working tree as it
# actually is, then this suite forcibly clears the copy's hook state for Scenario A regardless of
# what the source clone currently has installed.
CLONE="$W/clone"
mkdir -p "$CLONE"
if ! cp -R "$REPO"/. "$CLONE"/ 2>/dev/null; then
  fail "could not create a scratch copy of this repo for isolation"
  echo "  gh4-ungated-clone-warning: $PASS pass, $FAIL fail"
  exit 1
fi
rm -f "$CLONE/.git/hooks/pre-push"

# ---- Scenario A: ungated — the warning fires, non-fatally --------------------------------------
OUT_A="$(cd "$CLONE" && bash validate.sh --print-mode 2>&1)"; RC_A=$?
[ "$RC_A" = 0 ] && pass "ungated clone: --print-mode still exits 0 (non-fatal)" \
  || fail "ungated clone: --print-mode exited $RC_A, expected 0 — the warning must not block local validation"
printf '%s' "$OUT_A" | /usr/bin/grep -q "NOT INSTALLED in this clone" \
  && pass "ungated clone: warning names the missing gate" \
  || fail "ungated clone: no 'NOT INSTALLED' warning in output: $OUT_A"
printf '%s' "$OUT_A" | /usr/bin/grep -q "Fix: bash githooks/install.sh" \
  && pass "ungated clone: warning names the one-command fix" \
  || fail "ungated clone: warning does not name the fix"
printf '%s' "$OUT_A" | /usr/bin/grep -q "continuing WITHOUT the push gate installed" \
  && pass "ungated clone: validate.sh states it is continuing anyway (non-fatal, in-band)" \
  || fail "ungated clone: validate.sh did not state it is continuing"

# ---- Scenario B: gated — silent, no warning -----------------------------------------------------
( cd "$CLONE" && bash githooks/install.sh >/dev/null 2>&1 )
OUT_B="$(cd "$CLONE" && bash validate.sh --print-mode 2>&1)"; RC_B=$?
[ "$RC_B" = 0 ] && pass "gated clone: --print-mode exits 0" \
  || fail "gated clone: --print-mode exited $RC_B, expected 0"
if printf '%s' "$OUT_B" | /usr/bin/grep -q "NOT INSTALLED in this clone"; then
  fail "gated clone: the ungated-clone warning fired even though the hook IS installed"
else
  pass "gated clone: no ungated-clone warning — silent when properly wired"
fi

echo "  gh4-ungated-clone-warning: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
