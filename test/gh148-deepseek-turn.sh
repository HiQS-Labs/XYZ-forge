#!/usr/bin/env bash
# GH-148: DeepSeek harness turn-taker drives a relay turn behind the
# shared safety core (relay-turn-lib.sh / rtl.py) via a STUB `dsh`.
source "$(dirname "$0")/_setup.sh" deepseek-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/deepseek-turn.sh"
PY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/utils/py/deepseek-turn.py"

tick_a init >/dev/null

mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\nbin/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

STUB="$WORK/dsh-stub"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
TICK="${TICK_BIN:-tick}"
printf '%s\n' "$*" > "$WORK/dsh-args" 2>/dev/null || true
export TICK_REPO_ROOT="$A"

if [ "${STUB_MODE:-good}" = fail ]; then
  printf 'deepseek fake failure\n'
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
  printf '\n### Round 1 · Reviewer · %s (dsh-stub-fail)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
  exit 1
fi

if [ "${STUB_MODE:-good}" = empty ]; then
  exit 0
fi

if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
fi

printf 'deepseek output for %s\n' "$RELAY_AGENT"
printf '\n### Round 1 · Reviewer · %s (dsh-stub)\n**Verdict:** Approved\n' "$RELAY_AGENT" >>"$RELAY_FILE"

if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
fi

[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
[ "${STUB_MODE:-good}" = badwt ] && printf 'off-lane\n' >>offlane.md

exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to deepseek >/dev/null; }
tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

run_shim(){
  local task="$1" agent="$2" mode="$3"; shift 3
  local log="$WORK/dsh-log-$task.log"; : >"$log"
  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" DEEPSEEK_AGENT=deepseek \
    DEEPSEEK_BIN="$STUB" DEEPSEEK_TURN_ROOT="$A" DEEPSEEK_LOG="$log" STUB_MODE="$mode" TICK_BIN="$TICK" "$@" \
    bash "$SHIM"
}

# --- 1. Existence and Executability ---
[ -f "$SHIM" ] && [ -x "$SHIM" ] && pass "deepseek-turn.sh exists and is executable" || fail "deepseek-turn.sh missing or non-executable"
[ -f "$PY_SHIM" ] && [ -x "$PY_SHIM" ] && pass "utils/py/deepseek-turn.py exists and is executable" || fail "utils/py/deepseek-turn.py missing or non-executable"

# --- 2. Window-driven Deferral ---
rc=0; run_shim T-window other good >"$WORK/out-window.log" 2>&1 || rc=$?
[ "$rc" -eq 0 ] && pass "actor != DEEPSEEK_AGENT defers cleanly (exit 0)" || fail "expected exit 0 for deferral, got $rc"
grep -q "deferring (window-driven)" "$WORK/out-window.log" && pass "deferral logged to stderr" || fail "deferral log missing"

# --- 3. Missing Parameters ---
rc=0; env RELAY_AGENT=deepseek RELAY_FILE="" RELAY_TASK="T1" DEEPSEEK_AGENT=deepseek bash "$SHIM" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && pass "missing RELAY_FILE exits 2" || fail "expected exit 2 on missing RELAY_FILE, got $rc"

# --- 4. Good Turn ---
seed_token T-good
rc=0; run_shim T-good deepseek good >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] && pass "good turn exits 0" || fail "good turn failed with $rc"
[ "$(tok_field T-good handoff-to)" = claude-a ] && pass "token handed off to claude-a" || fail "token not handed off"

# --- 5. Empty Output Fails Turn ---
seed_token T-empty
rc=0; run_shim T-empty deepseek empty >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 5 ] && pass "empty output fails turn (exit 5)" || fail "expected exit 5 on empty output, got $rc"

# --- 6. Failure from Subprocess ---
seed_token T-fail
rc=0; run_shim T-fail deepseek fail >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 5 ] && pass "failing child exits 5" || fail "expected exit 5 on failing child, got $rc"

# --- 7. Worktree Isolation & Off-lane Edits ---
seed_token T-badwt
rc=0; run_shim T-badwt deepseek badwt RELAY_WORKTREE_ISOLATION=1 >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 6 ] && pass "worktree off-lane edits fail turn (exit 6)" || fail "expected exit 6 on offlane worktree edit, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane edits in worktree were discarded from root" || fail "off-lane edits leaked into root"

# --- 8. GH-397: the provider routing table ---
# Before GH-397 the route was an if/else whose `else` swallowed EVERY unrecognised provider and
# sent it to api.deepseek.com. These assertions read the generated cordis overlay, which is the
# artifact that actually decides where the request goes -- not the variable that names it.
overlay_for(){  # <provider> -> the overlay text generate_patch_overlay() would write
  DS_PROVIDER="$1" python3 - "$PY_SHIM" <<'OVERLAY_EOF'
import importlib.util, os, sys
# the shim imports its siblings (rtl, model_alias) by bare name -- load it the way it is run
sys.path.insert(0, os.path.dirname(os.path.abspath(sys.argv[1])))
spec = importlib.util.spec_from_file_location("dst", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
path = m.generate_patch_overlay(os.environ["DS_PROVIDER"], "qwen3.8-max", None)
sys.stdout.write(open(path).read()); os.remove(path)
OVERLAY_EOF
}

ALI_OVERLAY="$(overlay_for alibaba 2>/dev/null)"
case "$ALI_OVERLAY" in
  *"token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1"*)
    pass "alibaba provider routes to the Alibaba Token Plan endpoint" ;;
  *) fail "alibaba overlay does not carry the Token Plan base URL" ;;
esac
case "$ALI_OVERLAY" in
  *"apiKeyEnv: ALIBABA_TOKEN_PLAN_API_KEY"*)
    pass "alibaba provider reads its own key variable" ;;
  *) fail "alibaba overlay does not name the Alibaba key variable" ;;
esac
# The pre-GH-397 bug is exactly this: alibaba fell through to DeepSeek's endpoint.
case "$ALI_OVERLAY" in
  *"api.deepseek.com"*) fail "alibaba overlay still falls through to the DeepSeek endpoint" ;;
  *) pass "alibaba does NOT fall through to the DeepSeek endpoint" ;;
esac

OR_OVERLAY="$(overlay_for openrouter 2>/dev/null)"
case "$OR_OVERLAY" in
  *"openrouter.ai/api/v1"*) pass "openrouter route unchanged by the table rewrite" ;;
  *) fail "openrouter route regressed" ;;
esac

# --- 9. GH-397: an unknown provider refuses, and refuses BEFORE claiming ---
seed_token T-badprov
rm -f "$WORK/dsh-args"
rc=0; run_shim T-badprov deepseek good DEEPSEEK_PROVIDER=not-a-provider >"$WORK/out-badprov.log" 2>&1 || rc=$?
[ "$rc" -eq 2 ] && pass "unknown DEEPSEEK_PROVIDER exits 2" || fail "expected exit 2 on unknown provider, got $rc"
BADPROV_ERR="$(cat "$WORK/out-badprov.log" 2>/dev/null)"
case "$BADPROV_ERR" in
  *"unknown DEEPSEEK_PROVIDER"*) pass "unknown provider names the offending variable on stderr" ;;
  *) fail "unknown provider gave no diagnostic naming the variable" ;;
esac
[ ! -f "$WORK/dsh-args" ] && pass "unknown provider never launched the CLI" || fail "unknown provider still launched the CLI"
[ "$(tok_field T-badprov handoff-to)" = deepseek ] \
  && pass "unknown provider left the relay token where it was - no stranded claim" \
  || fail "unknown provider disturbed the relay token"

# --- 10. GH-397: the key-file fallback ---
# The Token Plan key is issued as a file, not a variable. The fallback must load it, and must not
# print the path (turn stderr lands in relay transcripts, which are committed).
KEYDIR="$WORK/keys"; mkdir -p "$KEYDIR"
KEYPATH="$KEYDIR/token-plan-fixture.txt"
KEYVAR=ALIBABA_TOKEN_PLAN_API_KEY
printf 'fixture-value-not-a-credential\n' >"$KEYPATH"
KEYOUT="$(env -u "$KEYVAR" "${KEYVAR}_FILE=$KEYPATH" DS_PROVIDER=alibaba DS_KEYVAR="$KEYVAR" \
  python3 - "$PY_SHIM" 2>"$WORK/keyerr.log" <<'KEY_EOF'
import importlib.util, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(sys.argv[1])))
spec = importlib.util.spec_from_file_location("dst", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.load_provider_key(os.environ["DS_PROVIDER"], os.environ["DS_KEYVAR"])
print(os.environ.get(os.environ["DS_KEYVAR"], ""))
KEY_EOF
)"
[ "$KEYOUT" = "fixture-value-not-a-credential" ] \
  && pass "key-file fallback populates the provider key variable" \
  || fail "key-file fallback did not populate the key variable (got '$KEYOUT')"
# The path-leak check has to run against a path that actually PRODUCES a diagnostic. On the happy
# path the fallback prints nothing at all, so asserting "the path is absent" there cannot fail --
# it would be green no matter what the failure branches say. Drive both failure branches instead.
key_diag(){  # <key file path> -> stderr from load_provider_key
  env -u "$KEYVAR" "${KEYVAR}_FILE=$1" DS_PROVIDER=alibaba DS_KEYVAR="$KEYVAR" \
    python3 - "$PY_SHIM" >/dev/null 2>"$WORK/keyerr.log" <<'DIAG_EOF'
import importlib.util, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(sys.argv[1])))
spec = importlib.util.spec_from_file_location("dst", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.load_provider_key(os.environ["DS_PROVIDER"], os.environ["DS_KEYVAR"])
DIAG_EOF
  cat "$WORK/keyerr.log" 2>/dev/null
}

: >"$KEYDIR/empty-fixture.txt"
for _case in "$KEYDIR/absent-fixture.txt" "$KEYDIR/empty-fixture.txt"; do
  _diag="$(key_diag "$_case")"
  case "$_diag" in
    *"$KEYVAR"*) pass "unusable key file ($(basename "$_case")) reports a diagnostic naming the variable" ;;
    *) fail "unusable key file ($(basename "$_case")) produced no diagnostic" ;;
  esac
  case "$_diag" in
    *"$KEYDIR"*) fail "key-file diagnostic ($(basename "$_case")) leaked the key file path" ;;
    *) pass "key-file diagnostic ($(basename "$_case")) never prints the key file path" ;;
  esac
done

echo "  gh148-deepseek-turn: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
