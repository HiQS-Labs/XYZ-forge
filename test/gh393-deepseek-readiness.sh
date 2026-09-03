#!/usr/bin/env bash
set -euo pipefail
#
# gh393-deepseek-readiness.sh — GH-396 Phase 0 / #393: RELAY_HAS_DEEPSEEK must agree with the shim.
#
# The #393 defect, correctly diagnosed (orchestrator correction B on the GH-396 plan): the readiness
# flag in find-harness.sh (:204-206, `command -v dsh`) and the runtime binary resolution in
# utils/py/deepseek-turn.py (:19-28, default_deepseek_bin(): $DEEPSEEK_BIN → a hardcoded path →
# `which dsh`) use DIFFERENT rules. On a machine where the hardcoded path exists, the check says 0
# while the turn runs; on a machine with `dsh` but no API key, the check says 1 and the turn dies.
#
# So the honest pin is PARITY, not a fixed value:
#   RELAY_HAS_DEEPSEEK == ( python3 >= 3.8 ) && ( the shim's own rule resolves to an existing file )
#                                             && ( OPENROUTER_API_KEY or DEEPSEEK_API_KEY is set )
# evaluated in the same environment. Two negative controls make the flag fall to 0 by removing one
# leg at a time. Whether the hardcoded-path leg should exist at all is #398, not this suite.
#
# Arrives RED: the current flag ignores API keys entirely and probes the binary by a different rule.
#
# Two lessons this file's first draft taught, kept as comments so they are not re-learned:
#   1. No `( … )` subshells around cases — pass/fail counters incremented inside one are lost, and
#      the suite printed two FAIL lines then reported "0 fail, exit 0". Cases run with env prefixes
#      on the single call that needs them instead.
#   2. deepseek-turn.py runs its main at module level (it reads RELAY_AGENT and dies), so the oracle
#      cannot import it. It ast-extracts default_deepseek_bin() and executes only that.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd -P)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
SHIM="$REPO/utils/py/deepseek-turn.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh393-ready.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
pass=0; fail=0
ok()  { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail + 1)); }

echo "gh393 deepseek readiness parity:"
[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }
[ -f "$SHIM" ] || { echo "  FAIL: shim missing at $SHIM"; exit 1; }

# The shim's OWN rule, asked directly, without running the shim. Prints 1 iff default_deepseek_bin()
# names an existing file in the CALLER's environment. Takes the shim path as $1 so a case can point
# it at a rewritten copy.
ORACLE="$WORK/oracle.py"
cat > "$ORACLE" <<'PY'
import ast, os, sys
src = open(sys.argv[1]).read()
tree = ast.parse(src)
fn = next((n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "default_deepseek_bin"), None)
if fn is None:
    print(0); sys.exit(0)
ns = {}
mod = ast.Module(body=[ast.Import(names=[ast.alias(name="os", asname=None)]),
                       ast.Import(names=[ast.alias(name="shutil", asname=None)]), fn],
                 type_ignores=[])
exec(compile(ast.fix_missing_locations(mod), sys.argv[1], "exec"), ns)
try:
    b = ns["default_deepseek_bin"]()
    print(1 if (b and os.path.exists(b)) else 0)
except Exception:
    print(0)
PY
shim_bin_exists() { python3 "$ORACLE" "${1:-$SHIM}" 2>/dev/null || echo 0; }
py_ok()  { python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null && echo 1 || echo 0; }
key_ok() { { [ -n "${OPENROUTER_API_KEY:-}" ] || [ -n "${DEEPSEEK_API_KEY:-}" ]; } && echo 1 || echo 0; }
expected_flag() {  # expected_flag [shim-path]
  if [ "$(py_ok)" = 1 ] && [ "$(shim_bin_exists "${1:-$SHIM}")" = 1 ] && [ "$(key_ok)" = 1 ]; then echo 1; else echo 0; fi
}
actual_flag() {
  _out="$(cd "$REPO" && bash "$FH" --env 2>/dev/null || true)"
  _line="$(grep -E '^export RELAY_HAS_DEEPSEEK=' <<<"$_out" || true)"
  printf '%s' "${_line#export RELAY_HAS_DEEPSEEK=}"
}

# Control on the oracle itself: with DEEPSEEK_BIN pointing at an existing file it must say 1, and
# at a missing file it must say 0. If either fails the rest of this suite is meaningless.
_probe="$WORK/probe"; printf ':\n' > "$_probe"
_o1="$(DEEPSEEK_BIN="$_probe" shim_bin_exists)"; _o0="$(DEEPSEEK_BIN="$WORK/missing" shim_bin_exists)"
if [ "$_o1" = 1 ] && [ "$_o0" = 0 ]; then ok "control: oracle reads the shim's rule (existing→1, missing→0)"
else bad "control: oracle reads the shim's rule (existing→$_o1, missing→$_o0) — cannot trust the rest"; exit 1; fi

# ── Case 1: this machine, as-is ────────────────────────────────────────────────────────────────
_want="$(expected_flag)"; _got="$(actual_flag)"
if [ "$_got" = "$_want" ]; then ok "ambient: RELAY_HAS_DEEPSEEK=$_got matches shim rule + key"
else bad "ambient: RELAY_HAS_DEEPSEEK=$_got but shim rule + key says $_want (shim_bin=$(shim_bin_exists) key=$(key_ok) py=$(py_ok))"; fi

# ── Case 2: binary present (fake dsh on PATH), NO key → must be 0 ─────────────────────────────
FAKEBIN="$WORK/bin"; mkdir -p "$FAKEBIN"
printf '#!/usr/bin/env bash\n:\n' > "$FAKEBIN/dsh"; chmod +x "$FAKEBIN/dsh"
_got="$(env -u OPENROUTER_API_KEY -u DEEPSEEK_API_KEY -u DEEPSEEK_BIN PATH="$FAKEBIN:$PATH" bash -c "$(declare -f actual_flag); REPO='$REPO'; FH='$FH'; actual_flag")"
if [ "$_got" = 0 ]; then ok "binary on PATH, no API key: flag is 0"
else bad "binary on PATH, no API key: flag is 0 (got $_got — the check ignores the key)"; fi

# ── Case 3: key present, binary UNRESOLVABLE by the shim's rule → must be 0 ───────────────────
# Strip PATH of dsh, unset DEEPSEEK_BIN, and neutralise the hardcoded leg by pointing the oracle at
# a copy of the shim whose hardcoded path is rewritten to a nonexistent file. That is the only way
# to make "unresolvable" true on a machine where the hardcoded path happens to exist (#398).
NOSHIM="$WORK/deepseek-turn.py"
sed -E 's#default_path = "[^"]*"#default_path = "'"$WORK"'/nonexistent/bin.js"#' "$SHIM" > "$NOSHIM"
if grep -q "$WORK/nonexistent/bin.js" "$NOSHIM"; then ok "control: hardcoded-path leg neutralised in the shim copy"
else bad "control: hardcoded-path leg neutralised in the shim copy — sed did not match; see #398"; fi
_shim_says="$(PATH=/usr/bin:/bin DEEPSEEK_BIN= shim_bin_exists "$NOSHIM")"
if [ "$_shim_says" = 0 ]; then ok "control: PATH stripped + hardcoded leg removed → the shim's rule resolves nothing"
else bad "control: PATH stripped + hardcoded leg removed → the shim's rule resolves nothing (got $_shim_says)"; fi
_got="$(PATH=/usr/bin:/bin DEEPSEEK_BIN= OPENROUTER_API_KEY=x actual_flag)"
# NB: actual_flag runs the REAL find-harness.sh, which today probes only `dsh`/$DEEPSEEK_BIN, so
# with PATH stripped it already says 0 here — this case is green today and pins the fixed
# behaviour, not the defect. The defect is Cases 2 and 4.
if [ "$_got" = 0 ]; then ok "key present, no resolvable binary: flag is 0"
else bad "key present, no resolvable binary: flag is 0 (got $_got)"; fi

# ── Case 4: DEEPSEEK_BIN set to an existing file + key → must be 1, and parity must hold ───────
_want="$(DEEPSEEK_BIN="$FAKEBIN/dsh" OPENROUTER_API_KEY=x expected_flag)"
_got="$(DEEPSEEK_BIN="$FAKEBIN/dsh" OPENROUTER_API_KEY=x actual_flag)"
if [ "$_want" = 1 ]; then ok "control: shim rule + key say 1 for an explicit DEEPSEEK_BIN"
else bad "control: shim rule + key say 1 for an explicit DEEPSEEK_BIN (got $_want)"; fi
if [ "$_got" = 1 ]; then ok "explicit DEEPSEEK_BIN + key: flag is 1"
else bad "explicit DEEPSEEK_BIN + key: flag is 1 (got $_got)"; fi

# ── Case 5: DEEPSEEK_BIN set to an existing file, NO key → parity requires 0 ─────────────────
_got="$(env -u OPENROUTER_API_KEY -u DEEPSEEK_API_KEY DEEPSEEK_BIN="$FAKEBIN/dsh" bash -c "$(declare -f actual_flag); REPO='$REPO'; FH='$FH'; actual_flag")"
if [ "$_got" = 0 ]; then ok "explicit DEEPSEEK_BIN, no key: flag is 0"
else bad "explicit DEEPSEEK_BIN, no key: flag is 0 (got $_got — the check ignores the key)"; fi

echo "  gh393-deepseek-readiness: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
