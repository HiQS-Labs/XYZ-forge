#!/usr/bin/env bash
# GH-460 R2 witnesses — each: baseline (direct oracle pass) -> red (mutation, exact diagnostic) -> restored green.
set -u
R="relay-automation/resolve-model-alias.sh"
O="test/gh460-oracle.sh"
EV="${GH460_EV:-/tmp/gh460-evidence/witnesses2}"
mkdir -p "$EV"
PASS=0; FAILN=0
ok(){ echo "  WITNESS PASS: $*"; PASS=$((PASS+1)); }
bad(){ echo "  WITNESS FAIL: $*" >&2; FAILN=$((FAILN+1)); }
cp "$R" /tmp/gh460-resolver.bak
restore(){ cp /tmp/gh460-resolver.bak "$R"; }

wit(){ # wit <name> <input> <expect-diagnostic> <expect-exit>
  local name="$1" input="$2" diag="$3" wantexit="$4" err rc
  # baseline: restored resolver -> oracle passes
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "$name baseline green" || { bad "$name baseline: rc=$rc err='$err'"; restore; return; }
  # red: mutated resolver -> exact diagnostic + exit
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?   # placeholder replaced below per witness
  :
}
# --- (a) rc-3 ---
wit_rc3(){
  local input="totally-unknown-model-xyz"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "rc-3 baseline green" || { bad "rc-3 baseline: rc=$rc err='$err'"; return; }
  sed -i '' '$s/^exit 1$/exit 3/' "$R"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "BADRC:3"; } && ok "rc-3 red: BADRC:3 exit 9" || bad "rc-3 red: rc=$rc err='$err'"
  restore
  bash "$O" "$input" >/dev/null 2>&1 && ok "rc-3 restored green" || bad "rc-3 restore not green"
}
wit_rc3
# --- (b) LEAK ---
wit_leak(){
  local input="totally-unknown-model-xyz"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "LEAK baseline green" || { bad "LEAK baseline: rc=$rc err='$err'"; return; }
  sed -i '' '$s/^exit 1$/printf "LEAK\\n"; exit 1/' "$R"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "LEAK-STDOUT-ON-MISS"; } && ok "LEAK red: LEAK-STDOUT-ON-MISS exit 9" || bad "LEAK red: rc=$rc err='$err'"
  restore
  bash "$O" "$input" >/dev/null 2>&1 && ok "LEAK restored green" || bad "LEAK restore not green"
}
wit_leak
# --- (c) NEWLINE-ONLY-LEAK ---
wit_nl(){
  local input="totally-unknown-model-xyz"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "NEWLINE-ONLY baseline green" || { bad "NEWLINE-ONLY baseline: rc=$rc err='$err'"; return; }
  sed -i '' '$s/^exit 1$/printf "\\n"; exit 1/' "$R"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "LEAK-STDOUT-ON-MISS"; } && ok "NEWLINE-ONLY red: LEAK-STDOUT-ON-MISS exit 9" || bad "NEWLINE-ONLY red: rc=$rc err='$err'"
  restore
  bash "$O" "$input" >/dev/null 2>&1 && ok "NEWLINE-ONLY restored green" || bad "NEWLINE-ONLY restore not green"
}
wit_nl
# --- (d) HIT-EMPTY ---
wit_he(){
  local input="glm-5.2"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "HIT-EMPTY baseline green" || { bad "HIT-EMPTY baseline: rc=$rc err='$err'"; return; }
  python3 - "$R" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
t = p.read_text()
n = t.count("printf '%s\\n' \"${canonicals[$i]}\"")
p.write_text(t.replace("printf '%s\\n' \"${canonicals[$i]}\"", ":"))
print(f"mutated {n} tier printf sites", file=sys.stderr)
PY
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "HIT-EMPTY-ON-MATCH"; } && ok "HIT-EMPTY red: HIT-EMPTY-ON-MATCH exit 9" || bad "HIT-EMPTY red: rc=$rc err='$err'"
  restore
  bash "$O" "$input" >/dev/null 2>&1 && ok "HIT-EMPTY restored green" || bad "HIT-EMPTY restore not green"
}
wit_he
# --- (e) MEASURE-FAIL family (PATH-shim wc; no resolver mutation) ---
mkdir -p /tmp/gh460-fakebin
wit_mf(){
  local name="$1" shimbody="$2" input="glm-5.2"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "$name baseline green" || { bad "$name baseline: rc=$rc err='$err'"; return; }
  printf '%s\n' "$shimbody" > /tmp/gh460-fakebin/wc; chmod +x /tmp/gh460-fakebin/wc
  err=$(PATH="/tmp/gh460-fakebin:$PATH" bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 8 ] && printf '%s' "$err" | grep -q "MEASURE-FAIL"; } && ok "$name red: MEASURE-FAIL exit 8" || bad "$name red: rc=$rc err='$err'"
  rm -f /tmp/gh460-fakebin/wc
  bash "$O" "$input" >/dev/null 2>&1 && ok "$name restored green" || bad "$name restore not green"
}
wit_mf "MEASURE-FAIL(failed wc)"  "exit 1"
wit_mf "MEASURE-FAIL(split digits)" "printf '1 2'"
wit_mf "MEASURE-FAIL(empty output)" "printf ''"
# abc / -5 measurement witnesses (non-numeric wc outputs)
for BADVAL in abc -5; do
  input="glm-5.2"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "MEASURE-FAIL($BADVAL) baseline green" || { bad "MEASURE-FAIL($BADVAL) baseline: rc=$rc err='$err'"; continue; }
  mkdir -p /tmp/gh460-fakebin
  printf '#!/usr/bin/env bash\nprintf "%s" "%s"\n' "$BADVAL" > /tmp/gh460-fakebin/wc; chmod +x /tmp/gh460-fakebin/wc
  err=$(PATH="/tmp/gh460-fakebin:$PATH" bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 8 ] && printf '%s' "$err" | grep -q "MEASURE-FAIL"; } && ok "MEASURE-FAIL($BADVAL) red: MEASURE-FAIL exit 8" || bad "MEASURE-FAIL($BADVAL) red: rc=$rc err='$err'"
  rm -f /tmp/gh460-fakebin/wc
  bash "$O" "$input" >/dev/null 2>&1 && ok "MEASURE-FAIL($BADVAL) restored green" || bad "MEASURE-FAIL($BADVAL) restore not green"
done
# padded-valid acceptance control
wit_pv(){
  local input="glm-5.2"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "padded-valid baseline green" || { bad "padded-valid baseline: rc=$rc err='$err'"; return; }
  printf '#!/usr/bin/env bash\nprintf "       7"\n' > /tmp/gh460-fakebin/wc; chmod +x /tmp/gh460-fakebin/wc
  err=$(PATH="/tmp/gh460-fakebin:$PATH" bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && ! printf '%s' "$err" | grep -q "MEASURE-FAIL"; } && ok "padded-valid red-accept: exit 0, no MEASURE-FAIL" || bad "padded-valid: rc=$rc err='$err'"
  rm -f /tmp/gh460-fakebin/wc
  bash "$O" "$input" >/dev/null 2>&1 && ok "padded-valid restored green" || bad "padded-valid restore not green"
}
wit_pv
rm -rf /tmp/gh460-fakebin
restore
echo "WITNESSES: $PASS passed, $FAILN failed"
[ $FAILN -eq 0 ]
