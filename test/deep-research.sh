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
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
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
grep -q '"provider":"agy"' <<<"$(echo "$out")" && pass "provider is agy" || fail "provider field wrong: $out"
grep -q '"model":"gemini"' <<<"$(echo "$out")" && pass "model field set" || fail "model field wrong: $out"
grep -q '"query":"what is deep research"' <<<"$(echo "$out")" && pass "query echoed back" || fail "query field wrong: $out"
echo "$out" | grep -q 'https://example.com/docs' && echo "$out" | grep -q 'https://example.com/blog' \
  && pass "both citations extracted from a CITATIONS section" || fail "citations missing: $out"
grep -q '"title":"Example Docs"' <<<"$(echo "$out")" && pass "citation title parsed" || fail "citation title missing: $out"
grep -q '"searchContextSize":"high"' <<<"$(echo "$out")" && pass "raw.config carries searchContextSize through" || fail "raw config missing searchContextSize: $out"

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

# ===================================================================================================
# GH-129: OpenRouter backend (Perplexity Sonar). Stub HTTP server injected via OPENROUTER_BASE_URL —
# same posture as the agy stub: request-shape capture + normalization + every failure mode, no live
# network. The agy assertions above are untouched (default provider stays byte-identical).
# ===================================================================================================
OR_SRV="$WORK/or-stub-server.mjs"
cat >"$OR_SRV" <<'OR_STUB_EOF'
import { createServer } from 'node:http';
import { writeFileSync } from 'node:fs';
const [mode, portFile, reqFile] = process.argv.slice(2);
const srv = createServer((req, res) => {
  let body = '';
  req.on('data', (d) => { body += d; });
  req.on('end', () => {
    try {
      writeFileSync(reqFile, JSON.stringify({ url: req.url, auth: req.headers.authorization || '', body: JSON.parse(body || 'null') }));
    } catch {}
    const send = (code, payload) => {
      res.writeHead(code, { 'Content-Type': 'application/json' });
      res.end(typeof payload === 'string' ? payload : JSON.stringify(payload));
    };
    switch (mode) {
      case 'good':
        send(200, {
          citations: ['https://example.com/passthrough'],
          choices: [{ message: {
            content: 'Perplexity grounded answer about deep research.',
            annotations: [{ type: 'url_citation', url_citation: { url: 'https://example.com/anno', title: 'Anno Doc' } }],
          } }],
        });
        break;
      case 'citearray':
        send(200, { citations: ['https://example.com/c1', 'https://example.com/c2'], choices: [{ message: { content: 'Answer without annotations.' } }] });
        break;
      case 'inline':
        send(200, { choices: [{ message: { content: 'Answer citing https://example.com/inline1 and https://example.com/inline2 inline.' } }] });
        break;
      case 'http500': send(500, { error: 'boom' }); break;
      case 'badjson': send(200, 'not json {'); break;
      case 'empty':   send(200, { choices: [{ message: { content: '' } }] }); break;
      case 'hang':    break; // never respond — the adapter's AbortController must fire
      default:        send(500, { error: `unknown stub mode ${mode}` });
    }
  });
});
srv.listen(0, '127.0.0.1', () => { writeFileSync(portFile, String(srv.address().port)); });
OR_STUB_EOF

OR_PID=""
or_start() {  # or_start <mode> -> sets OR_PORT; request capture lands in $WORK/or-req.json
  rm -f "$WORK/or-port" "$WORK/or-req.json"
  node "$OR_SRV" "$1" "$WORK/or-port" "$WORK/or-req.json" &
  OR_PID=$!
  for _ in $(seq 1 50); do [ -s "$WORK/or-port" ] && break; sleep 0.1; done
  OR_PORT="$(cat "$WORK/or-port" 2>/dev/null)"
}
or_stop() { [ -n "$OR_PID" ] && kill "$OR_PID" 2>/dev/null; wait "$OR_PID" 2>/dev/null; OR_PID=""; }
or_run() {  # or_run <deep-research args...> — against the running stub, with a test API key
  OPENROUTER_API_KEY="test-key" OPENROUTER_BASE_URL="http://127.0.0.1:$OR_PORT/api/v1" node "$DR" --provider openrouter "$@"
}

# --- (9) usage: unknown --provider -> exit 2, no stdout --------------------------------------------
out="$(node "$DR" --provider sonar --query q 2>/dev/null)"; rc=$?
{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "unknown --provider -> usage (exit 2)" || fail "rc=$rc out='$out'"

# --- (10) fail-closed: OPENROUTER_API_KEY missing -> exit 1, typed error, no network attempt --------
out="$(OPENROUTER_API_KEY="" node "$DR" --provider openrouter --query q 2>"$WORK/err")"; rc=$?
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "openrouter: missing API key -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"missing_api_key"' "$WORK/err" && pass "openrouter: missing key -> typed missing_api_key error" || fail "missing typed error: $(cat "$WORK/err")"

# --- (11) good turn: request construction + normalization (annotations first, then passthrough) -----
or_start good
out="$(or_run --query "what is deep research" --search-context-size low --temperature 0.3 --max-tokens 256)"; rc=$?
or_stop
[ "$rc" -eq 0 ] && pass "openrouter: good turn exits 0" || fail "openrouter good turn rc=$rc"
grep -q '"provider":"openrouter"' <<<"$(echo "$out")" && pass "openrouter: provider field" || fail "provider field wrong: $out"
grep -q '"model":"perplexity/sonar"' <<<"$(echo "$out")" && pass "openrouter: default model perplexity/sonar" || fail "model field wrong: $out"
grep -q '"url":"https://example.com/anno","title":"Anno Doc"' <<<"$(echo "$out")" && pass "openrouter: annotation citation with title" || fail "annotation citation missing: $out"
grep -q 'https://example.com/passthrough' <<<"$(echo "$out")" && pass "openrouter: citations[] passthrough merged" || fail "passthrough citation missing: $out"
grep -q '"url":"/api/v1/chat/completions"' "$WORK/or-req.json" && pass "openrouter: POSTs to <base>/chat/completions" || fail "request url wrong: $(cat "$WORK/or-req.json")"
grep -q '"auth":"Bearer test-key"' "$WORK/or-req.json" && pass "openrouter: Authorization bearer header" || fail "auth header wrong: $(cat "$WORK/or-req.json")"
grep -q '"model":"perplexity/sonar"' "$WORK/or-req.json" && pass "openrouter: request body carries model" || fail "request model wrong: $(cat "$WORK/or-req.json")"
grep -q '"web_search_options":{"search_context_size":"low"}' "$WORK/or-req.json" && pass "openrouter: --search-context-size -> web_search_options" || fail "web_search_options wrong: $(cat "$WORK/or-req.json")"
grep -q '"max_tokens":256' "$WORK/or-req.json" && pass "openrouter: --max-tokens -> max_tokens" || fail "max_tokens missing: $(cat "$WORK/or-req.json")"

# --- (12) model override via DEEP_RESEARCH_OPENROUTER_MODEL ----------------------------------------
or_start good
out="$(DEEP_RESEARCH_OPENROUTER_MODEL="perplexity/sonar-pro" or_run --query q)"; rc=$?
or_stop
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q '"model":"perplexity/sonar-pro"'; } \
  && grep -q '"model":"perplexity/sonar-pro"' "$WORK/or-req.json" \
  && pass "openrouter: DEEP_RESEARCH_OPENROUTER_MODEL overrides model (result + request)" \
  || fail "model override failed: rc=$rc out='$out' req=$(cat "$WORK/or-req.json" 2>/dev/null)"

# --- (13) citations[] passthrough only (no annotations) --------------------------------------------
or_start citearray
out="$(or_run --query q)"; rc=$?
or_stop
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q 'https://example.com/c1' && echo "$out" | grep -q 'https://example.com/c2'; } \
  && pass "openrouter: citations[] passthrough extracted without annotations" || fail "citearray failed: rc=$rc out='$out'"

# --- (14) bare-URL fallback when neither annotations nor citations[] present -----------------------
or_start inline
out="$(or_run --query q)"; rc=$?
or_stop
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q 'https://example.com/inline1' && echo "$out" | grep -q 'https://example.com/inline2'; } \
  && pass "openrouter: bare-URL scan fallback" || fail "inline fallback failed: rc=$rc out='$out'"

# --- (15) fail-closed: non-200 -> exit 1, typed backend_error, no fallback -------------------------
or_start http500
out="$(or_run --query q 2>"$WORK/err")"; rc=$?
or_stop
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "openrouter: HTTP 500 -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"backend_error"' "$WORK/err" && pass "openrouter: HTTP 500 -> typed backend_error" || fail "missing typed error: $(cat "$WORK/err")"

# --- (16) fail-closed: malformed JSON body -> backend_error ----------------------------------------
or_start badjson
out="$(or_run --query q 2>"$WORK/err")"; rc=$?
or_stop
{ [ "$rc" -eq 1 ] && grep -q '"error":"backend_error"' "$WORK/err"; } \
  && pass "openrouter: non-JSON body -> typed backend_error" || fail "rc=$rc err=$(cat "$WORK/err")"

# --- (17) fail-closed: empty answer content -> empty_output ----------------------------------------
or_start empty
out="$(or_run --query q 2>"$WORK/err")"; rc=$?
or_stop
{ [ "$rc" -eq 1 ] && grep -q '"error":"empty_output"' "$WORK/err"; } \
  && pass "openrouter: empty content -> typed empty_output" || fail "rc=$rc err=$(cat "$WORK/err")"

# --- (18) fail-closed: gateway never responds -> AbortController timeout ---------------------------
or_start hang
out="$(DEEP_RESEARCH_TIMEOUT_MS=500 or_run --query q 2>"$WORK/err")"; rc=$?
or_stop
{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "openrouter: timeout -> exit 1, no stdout" || fail "rc=$rc out='$out'"
grep -q '"error":"timeout"' "$WORK/err" && pass "openrouter: timeout -> typed timeout error" || fail "missing typed error: $(cat "$WORK/err")"

# ===================================================================================================
# GH-124: opt-in real-agy smoke test. Gated on DEEP_RESEARCH_LIVE=1; self-skips by default (no real
# agy call, no network) printing a clear reason, mirroring test/relay-self-sufficiency.sh's skip
# convention. Runs ONE real, small deep-research.mjs query against the actual `agy` CLI and asserts a
# real answer + at least one citation come back within DEEP_RESEARCH_TIMEOUT_MS. Never part of the
# default validate.sh required-green set — same opt-in posture as relay-self-sufficiency.sh. When
# skipped it does not touch $PASS/$FAIL, so the tally above stays exactly 45/45 non-live.
# ===================================================================================================
echo ""
echo "== test: deep-research-real-agy (GH-124, opt-in) =="

if [ "${DEEP_RESEARCH_LIVE:-0}" != "1" ]; then
  echo "  SKIPPED: DEEP_RESEARCH_LIVE=1 not set (opt-in real-agy smoke test — set DEEP_RESEARCH_LIVE=1 to run one real, billed agy call)"
  echo "  deep-research-real-agy: 0 pass, 0 fail (skipped)"
else
  LIVE_AGY_BIN="${AGY_BIN:-}"
  if [ -z "$LIVE_AGY_BIN" ] && command -v agy >/dev/null 2>&1; then
    LIVE_AGY_BIN="agy"
  fi
  if [ -z "$LIVE_AGY_BIN" ]; then
    echo "  SKIPPED: no real agy binary found (DEEP_RESEARCH_LIVE=1 was set, but agy is not on PATH; set AGY_BIN to override)"
    echo "  deep-research-real-agy: 0 pass, 0 fail (skipped)"
  else
    LIVE_PASS=0; LIVE_FAIL=0
    live_pass(){ echo "  PASS: $*"; LIVE_PASS=$((LIVE_PASS+1)); }
    live_fail(){ echo "  FAIL: $*" >&2; LIVE_FAIL=$((LIVE_FAIL+1)); }

    echo "  agy: $LIVE_AGY_BIN"
    echo "  (live API call — requires network + credentials; up to ${DEEP_RESEARCH_TIMEOUT_MS:-120000}ms)"

    live_out="$(AGY_BIN="$LIVE_AGY_BIN" node "$DR" --query "What year was the Eiffel Tower completed?" --search-context-size low 2>"$WORK/live-err")"
    live_rc=$?

    if [ "$live_rc" -eq 0 ]; then
      live_pass "real agy turn exits 0 within DEEP_RESEARCH_TIMEOUT_MS"
    else
      live_fail "real agy turn rc=$live_rc: $(cat "$WORK/live-err" 2>/dev/null)"
    fi

    if grep -q '"answer":""' <<<"$(echo "$live_out")"; then
      live_fail "real agy answer field empty: $live_out"
    elif grep -q '"answer":"' <<<"$(echo "$live_out")"; then
      live_pass "real agy returned a non-empty answer"
    else
      live_fail "real agy answer field missing: $live_out"
    fi

    if grep -q '"citations":\[\]' <<<"$(echo "$live_out")"; then
      live_fail "real agy returned zero citations: $live_out"
    elif grep -q '"citations":\[' <<<"$(echo "$live_out")"; then
      live_pass "real agy returned at least one citation"
    else
      live_fail "real agy citations field missing: $live_out"
    fi

    echo ""
    echo "  deep-research-real-agy: $LIVE_PASS pass, $LIVE_FAIL fail"
    PASS=$((PASS+LIVE_PASS)); FAIL=$((FAIL+LIVE_FAIL))
  fi
fi

echo "  deep-research: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
