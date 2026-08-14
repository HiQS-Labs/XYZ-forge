#!/usr/bin/env bash
set -euo pipefail
#
# gh520-default-reviewer-stub.sh — GH-520: a marathon fixture that does not stub CODEX_BIN tests
# the reviewer-binary probe instead of the code under test, and passes locally while failing CI.
#
# `_probe_agent_bin` runs before the guards, the preflight and the dispatch, and `--reviewer codex`
# is the default in essentially every marathon fixture. On a developer machine a real `codex` is on
# PATH, so the probe passes and nobody notices; on ubuntu CI there is none, the run dies at the
# probe, and the fixture's assertions read the probe's message instead of the behaviour they were
# written for.
#
# `test/_setup.sh` now exports a default `CODEX_BIN` stub. The two assertions that matter are in
# TENSION and both are checked here, because fixing this by disabling the probe would be worse than
# the bug:
#
#   * the default exists, is executable, and survives into a sourcing fixture; and
#   * an explicitly MISSING reviewer binary STILL fails fast — the protection is intact.
#
# The second is the one that keeps this honest. GH-117 built that probe so a lane with an
# undispatchable binary dies before spending a tick token; a default stub that silently swallowed
# that would trade a loud CI failure for a spent relay task.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh520-default-reviewer-stub =="

# --- (1) the default is declared in the one file every fixture sources ------------------------
ok "_setup.sh declares a default CODEX_BIN" \
   "grep -q 'export CODEX_BIN=' '$REPO/test/_setup.sh'"
ok "_setup.sh does NOT clobber an explicit CODEX_BIN (uses :- default)" \
   "grep -q 'export CODEX_BIN=\"\${CODEX_BIN:-' '$REPO/test/_setup.sh'"

# --- (2) a fixture that sources _setup.sh really gets a usable stub ---------------------------
PROBE="$(mktemp "${TMPDIR:-/tmp}/gh520-probe.XXXXXX.sh")"
cat > "$PROBE" <<'EOF'
set -u
# shellcheck disable=SC1091
. "$REPO_UNDER_TEST/test/_setup.sh" gh520-inner >/dev/null 2>&1
printf 'CODEX_BIN=%s\n' "${CODEX_BIN:-UNSET}"
[ -x "${CODEX_BIN:-/nonexistent}" ] && printf 'EXECUTABLE=yes\n' || printf 'EXECUTABLE=no\n'
EOF
OUT="$(REPO_UNDER_TEST="$REPO" bash "$PROBE" 2>/dev/null || true)"
ok "a sourcing fixture inherits a CODEX_BIN" \
   "printf '%s' \"\$OUT\" | grep -q 'CODEX_BIN=/'"
ok "the inherited stub is executable" \
   "printf '%s' \"\$OUT\" | grep -q 'EXECUTABLE=yes'"

# --- (3) an explicit CODEX_BIN still wins -----------------------------------------------------
OUT="$(REPO_UNDER_TEST="$REPO" CODEX_BIN=/usr/bin/true bash "$PROBE" 2>/dev/null || true)"
ok "an explicit CODEX_BIN overrides the default" \
   "printf '%s' \"\$OUT\" | grep -q 'CODEX_BIN=/usr/bin/true'"
rm -f "$PROBE"

# --- (4) THE COMPANION: the probe must still fire on a genuinely missing binary ----------------
# Without this, a default stub would be indistinguishable from deleting the protection.
ok "marathon-drive still asserts a missing reviewer binary fails fast" \
   "grep -q 'missing reviewer binary exits 2' '$REPO/test/marathon-drive.sh'"
ok "marathon-drive still asserts the message names the missing binary" \
   "grep -q 'missing reviewer error names the missing binary' '$REPO/test/marathon-drive.sh'"
ok "the probe itself is still wired before dispatch" \
   "grep -q '_probe_agent_bin' '$REPO/utils/py/marathon_drive.py'"

# --- (5) the reproduction: the three named fixtures no longer depend on a real codex -----------
# GH-520's evidence is that gh402/gh514/gh388 read the probe's message on a machine without codex.
# Each must now stub it (directly or via _setup.sh) rather than inherit one from the developer.
for f in gh402-branch-enforcement gh514-write-set-trackable gh388-run-log-durability; do
  if [ -f "$REPO/test/$f.sh" ]; then
    ok "$f sources the shared setup (so it inherits the stub)" \
       "grep -qE '_setup.sh' '$REPO/test/$f.sh'"
  fi
done

echo "  gh520-default-reviewer-stub: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
