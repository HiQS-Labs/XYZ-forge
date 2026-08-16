#!/usr/bin/env bash
# archive-writers.sh — GH-30 Phase 2: the transcript writers honor the rtl_transcript_root resolver.
#
# Behavioral (end-to-end through a REAL writer, consult.sh, with stub advisors):
#   - XYZ_ARCHIVE_ROOT unset       → transcript lands in "$ROOT/relay-system/<date>/…" (byte-for-byte)
#   - XYZ_ARCHIVE_ROOT set (git)   → lands in "$archive/relay-system/<slug>/<date>/…" (namespaced)
#   - explicit --out               → wins, and the resolver/archive is NOT consulted
#   - XYZ_ARCHIVE_ROOT set-invalid → the writer fails LOUD (non-zero), no transcript, no silent fallback
# Structural (regression lock for all four writers — marathon-drive/relay-drive drive full relay loops
#   that need codex/agy + network, so they are covered structurally + by the resolver's own unit test
#   test/archive-root.sh, not re-run end-to-end here):
#   - each sources relay-turn-lib.sh AND calls rtl_transcript_root
#   - none retains a hardcoded "$ROOT[_DIR]/relay-system/…" transcript default that bypasses the resolver
source "$(dirname "$0")/_setup.sh" archive-writers

ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
CONSULT="$ROOT_REPO/relay-automation/consult.sh"

# $A is a git clone whose origin remote is the bare "$REMOTE" (…/remote.git) → slug "remote".
SLUG_A="remote"

# One stub impersonating an advisor: codex is detected by `exec` as argv[1] (consult's codex form).
STUB="$WORK/advisor-stub"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf 'ANSWER from stub\n[Pass] fine\nRECOMMENDATION: ship\n'
exit 0
STUB_EOF
chmod +x "$STUB"

run_consult() { # env: XYZ_ARCHIVE_ROOT (optional); args: extra consult flags
  CONSULT_ROOT="$A" CODEX_BIN="$STUB" AGY_BIN="$STUB" GEMINI_BIN="$STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "review please" --label t --models codex "$@"
}

# --- (1) unset → transcript under $A/relay-system/<date>/ (byte-for-byte today's path) -----------
unset XYZ_ARCHIVE_ROOT
run_consult >/dev/null 2>&1 || fail "consult (unset) exited non-zero"
found="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | head -1)"
[ -n "$found" ] || fail "unset: no transcript under \$A/relay-system/<date>/t-*"
pass "consult, XYZ_ARCHIVE_ROOT unset → \$ROOT/relay-system/<date>/ (regression-safe)"

# --- (2) set to a git archive → namespaced under $archive/relay-system/<slug>/<date>/ ------------
ARCHIVE="$WORK/archive"; git init -q "$ARCHIVE"
XYZ_ARCHIVE_ROOT="$ARCHIVE" run_consult >/dev/null 2>&1 || fail "consult (archive) exited non-zero"
found="$(ls -d "$ARCHIVE"/relay-system/"$SLUG_A"/*/t-* 2>/dev/null | head -1)"
[ -n "$found" ] || fail "archive: no transcript under \$ARCHIVE/relay-system/$SLUG_A/<date>/t-*"
pass "consult, XYZ_ARCHIVE_ROOT set → \$archive/relay-system/<slug>/<date>/ (namespaced)"

# --- (3) explicit --out wins; the archive is NOT consulted (fresh archive stays empty) -----------
ARCHIVE2="$WORK/archive2"; git init -q "$ARCHIVE2"
NAMED="$WORK/named-out"
XYZ_ARCHIVE_ROOT="$ARCHIVE2" run_consult --out "$NAMED" >/dev/null 2>&1 || fail "consult (--out) exited non-zero"
[ -n "$(ls -d "$NAMED"/t-* 2>/dev/null | head -1)" ] || fail "override: no transcript under \$NAMED/t-*"
[ -z "$(ls -d "$ARCHIVE2"/relay-system 2>/dev/null)" ] || fail "override: archive was written despite explicit --out"
pass "consult, explicit --out wins and skips the archive redirect"

# --- (4) set-but-invalid archive → writer FAILS LOUD, no silent fallback into $A -----------------
before="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | wc -l | tr -d ' ')"
XYZ_ARCHIVE_ROOT="$WORK/does-not-exist" run_consult >/dev/null 2>&1; rc=$?
[ "$rc" != 0 ] || fail "invalid-archive: consult should exit non-zero, got 0"
after="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | wc -l | tr -d ' ')"
[ "$before" = "$after" ] || fail "invalid-archive: a transcript leaked into \$A/relay-system (silent fallback)"
pass "consult, set-but-invalid XYZ_ARCHIVE_ROOT → hard fail, no fallback into the target repo"

# --- (5) structural: every writer sources the resolver, calls it, and drops the hardcoded default -
check_writer() {  # <path> <root-var-used-in-old-default>
  local f="$ROOT_REPO/$1" rootvar="$2" base; base="$(basename "$f")"
  grep -q 'source .*relay-turn-lib.sh' "$f" || fail "$base: does not source relay-turn-lib.sh"
  grep -q 'rtl_transcript_root' "$f"        || fail "$base: does not call rtl_transcript_root"
  # the hardcoded transcript default this phase replaced must be gone (quote optional — agy nit)
  if grep -Eq "\"?\\\$$rootvar/relay-system/\\\$\\(date|\"?\\\$$rootvar/relay-system/preflight" "$f"; then
    fail "$base: still has a hardcoded \$$rootvar/relay-system transcript default (bypasses resolver)"
  fi
  # fail-loud lint: the resolver must be captured in its OWN assignment, never combined with a second
  # command substitution — "$(rtl_transcript_root ...)/$(date ...)" masks the resolver's exit status so
  # `|| exit 1` never fires (the Codex Blocker on relay-drive.sh:323). Assert that anti-pattern is gone.
  if grep -Eq '\$\(rtl_transcript_root[^)]*\)/[^"]*\$\(' "$f"; then
    fail "$base: resolver combined with a 2nd command substitution — masks its rc (fail-loud broken)"
  fi
  pass "$base: sources + calls rtl_transcript_root, no hardcoded default, resolver rc not masked"
}
check_writer "relay-automation/consult.sh"       ROOT
check_writer "relay-automation/marathon-drive.sh" ROOT
check_writer "relay-automation/relay-drive.sh"    ROOT_DIR
check_writer "utils/swarm-preflight.sh"           ROOT

echo "== archive-writers: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
