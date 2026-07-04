#!/usr/bin/env bash
# GH-87: deep-research.mjs — provider-agnostic grounded-search adapter (Agy Gemini Search backend).
# Asserts request construction reaches the agy CLI, response normalization (with and without a
# CITATIONS heading), that the adapter stays side-effect free (agy runs in a throwaway tmpdir, not
# the caller's CWD), and fail-closed behavior on a missing binary, non-zero exit, empty output, and
# timeout — never a silent fallback to a different provider.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
DR="$HERE/../relay-automation/deep-research.mjs"
WORK="$(mktemp -d -t deep-research-test.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: deep-research =="

# Stub `agy`: ignores the real CLI flags (-p <prompt> --print-timeout <n>s) and answers purely off
# STUB_MODE, mirroring test/agy-turn.sh's stub convention.
STUB="$WORK/agy"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
mode="${STUB_MODE:-good}"
[ -n "${STUB_CWD_MARKER:-}" ] && pwd > "$STUB_CWD_MARKER"
[ -n "${STUB_ARGS_MARKER:-}" ] && printf '%s\n' "$*" > "$STUB_ARGS_MARKER"
case "$mode" in
  good)
    cat <<'ANSWER'
Deep research combines grounded retrieval with generation.

CITATIONS:
- Example Docs — https://example.com/docs
- Example Blog — https://example.com/blog
ANSWER
    ;;
  noformat) printf 'Some answer mentioning https://example.com/a and https://example.com/b inline.\n' ;;
  empty)    exit 0 ;;
  nonzero)  echo "boom" >&2; exit 1 ;;
  hang)     sleep 5 ;;
  # reads stdin to EOF FIRST — blocks forever if the adapter leaves agy's stdin an open pipe (the
  # execFile-ignores-stdio bug). With spawn stdio:['ignore',…] stdin is /dev/null → immediate EOF.
  needstdin) cat >/dev/null 2>&1; printf 'answered after stdin EOF\nCITATIONS:\n- Example — https://example.com/x\n' ;;
esac
STUB_EOF
chmod +x "$STUB"

run() {  # run <stub-mode> <deep-research args...>
  local mode="$1"; shift
  STUB_MODE="$mode" AGY_BIN="$STUB" node "$DR" "$@"
}

# --- (1) usage errors: missing/invalid args -> exit 2, no stdout ----------------------------------
out="$(run good 2>/dev/null)"; rc=$?
{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "missing --query -> usage (exit 2)" || fail "rc=$rc out='$out'"

out="$(run good --query q --search-context-size huge 2>/dev/null)"; rc=$?
{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "bad --search-context-size -> usage (exit 2)" || fail "rc=$rc out='$out'"

out="$(run good --query q --temperature nope 2>/dev/null)"; rc=$?
{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "non-numeric --temperature -> usage (exit 2)" || fail "rc=$rc out='$out'"

# --- (2) good turn: request construction + response normalization --------------------------------
out="$(run good --query "what is deep research" --search-context-size high --temperature 0.2 --max-tokens 500)"; rc=$?
[ "$rc" -eq 0 ] && pass "good turn exits 0" || fail "good turn rc=$rc"
echo "$out" | grep -q '"provider":"agy"' && pass "provider is agy" || fail "provider field wrong: $out"
echo "$out" | grep -q '"model":"gemini"' && pass "model field set" || fail "model field wrong: $out"
echo "$out" | grep -q '"query":"what is deep research"' && pass "query echoed back" || fail "query field wrong: $out"
echo "$out" | grep -q 'https://example.com/docs' && echo "$out" | grep -q 'https://example.com/blog' \
  && pass "both citations extracted from a CITATIONS section" || fail "citations missing: $out"
echo "$out" | grep -q '"title":"Example Docs"' && pass "citation title parsed" || fail "citation title missing: $out"
echo "$out" | grep -q '"searchContextSize":"high"' && pass "raw.config carries searchContextSize through" || fail "raw config missing searchContextSize: $out"

# --- (3) fallback citation extraction: no CITATIONS heading, bare inline URLs ---------------------
out="$(run noformat --query q)"; rc=$?
[ "$rc" -eq 0 ] && pass "noformat turn exits 0" || fail "noformat rc=$rc"
echo "$out" | grep -q 'https://example.com/a' && echo "$out" | grep -q 'https://example.com/b' \
  && pass "fallback extraction finds bare inline URLs" || fail "fallback citations missing: $out"

# --- (4) side-effect free: agy runs in a throwaway tmpdir, not the caller's CWD, cleaned up after --
marker="$WORK/cwd-marker"
( cd "$WORK" && STUB_CWD_MARKER="$marker" STUB_MODE=good AGY_BIN="$STUB" node "$DR" --query q >/dev/null )
invoked_cwd="$(cat "$marker" 2>/dev/null)"
{ [ -n "$invoked_cwd" ] && [ "$invoked_cwd" != "$WORK" ] && [ ! -d "$invoked_cwd" ]; } \
  && pass "agy invoked from a throwaway tmpdir, cleaned up after (side-effect free)" \
  || fail "expected a cleaned-up tmpdir distinct from \$WORK, got '$invoked_cwd'"

# --- (4b) non-interactive: agy is invoked with --dangerously-skip-permissions so print mode can't
# block on a tool-permission prompt and hang until --print-timeout (real-agy fix, 2026-07-04) -------
amarker="$WORK/args-marker"
STUB_ARGS_MARKER="$amarker" STUB_MODE=good AGY_BIN="$STUB" node "$DR" --query q >/dev/null 2>&1
grep -q -- '--dangerously-skip-permissions' "$amarker" 2>/dev/null \
  && pass "agy invoked with --dangerously-skip-permissions (no interactive hang in print mode)" \
  || fail "expected --dangerously-skip-permissions in agy args, got: $(cat "$amarker" 2>/dev/null)"

# --- (4c) agy's stdin is EOF'd, so a backend that reads stdin doesn't block (regression for the
# execFile-ignores-stdio hang where stdin stayed an open pipe until --print-timeout, 2026-07-04) ----
out="$(DEEP_RESEARCH_TIMEOUT_MS=8000 run needstdin --query q 2>/dev/null)"; rc=$?
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q 'example.com/x'; } \
  && pass "agy stdin closed (a stdin-reading backend returns; no open-pipe hang)" \
  || fail "expected exit 0 with output (stdin not EOF'd -> hang), rc=$rc out='$out'"

# --- (5) fail-closed: empty output (agy exits 0, prints nothing) -> exit 1, typed error, no fallback
out="$(run empty --query q 2>"$WORK/err")"; rc=$?
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "empty output -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"empty_output"' "$WORK/err" && pass "empty output -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"

# --- (6) fail-closed: agy exits non-zero -> exit 1, typed error, no fallback -----------------------
out="$(run nonzero --query q 2>"$WORK/err")"; rc=$?
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "non-zero exit -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"backend_error"' "$WORK/err" && pass "non-zero exit -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"

# --- (7) fail-closed: binary missing -> exit 1, typed error, no fallback ---------------------------
out="$(AGY_BIN="$WORK/does-not-exist" node "$DR" --query q 2>"$WORK/err")"; rc=$?
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "missing binary -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"binary_missing"' "$WORK/err" && pass "missing binary -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"

# --- (8) fail-closed: timeout -> exit 1, typed error, never a silent fallback ----------------------
out="$(STUB_MODE=hang AGY_BIN="$STUB" DEEP_RESEARCH_TIMEOUT_MS=500 node "$DR" --query q 2>"$WORK/err")"; rc=$?
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "timeout -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"timeout"' "$WORK/err" && pass "timeout -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"

echo "  deep-research: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
