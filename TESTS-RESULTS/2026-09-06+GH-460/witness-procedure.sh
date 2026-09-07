#!/usr/bin/env bash
# GH-460 R2 mutation witnesses — SAFE procedure (round-6 remediation).
#
# Safety contract (plan R2): restoration handlers (EXIT/INT/TERM) installed BEFORE the first
# mutation; the resolver backup lives in an owned unique work directory; every mutation is
# verified to replace exactly the intended site (HIT-EMPTY mutates exactly ONE of the four tier
# sites); any interruption restores the production resolver. Run from the repo root.
set -u
R="relay-automation/resolve-model-alias.sh"
O="test/gh460-oracle.sh"
PASS=0; FAILN=0
ok(){ echo "  WITNESS PASS: $*"; PASS=$((PASS+1)); }
bad(){ echo "  WITNESS FAIL: $*" >&2; FAILN=$((FAILN+1)); }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/gh460-witness.XXXXXX") || { echo "witness: no work dir" >&2; exit 1; }
cp "$R" "$WORK/resolver.bak"
restore(){ cp "$WORK/resolver.bak" "$R"; }
trap 'restore; rm -rf "$WORK"' EXIT INT TERM

# --- (a) rc-3: terminal miss exit 1 -> exit 3 (exact one-site, last line) ---
input="totally-unknown-model-xyz"
err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "rc-3 baseline green" || bad "rc-3 baseline: rc=$rc err='$err'"
restore
before=$(grep -c "^exit 1$" "$R")
sed '$s/^exit 1$/exit 3/' "$R" > "$R.tmp" && mv "$R.tmp" "$R"
after=$(grep -c "^exit 3$" "$R")
{ [ "$before" = "1" ] && [ "$after" = "1" ]; } && ok "rc-3 exact one-site mutation verified" || bad "rc-3 mutation count before=$before after=$after"
err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "BADRC:3"; } && ok "rc-3 red: BADRC:3 exit 9" || bad "rc-3 red: rc=$rc err='$err'"
restore
bash "$O" "$input" >/dev/null 2>&1 && ok "rc-3 restored green" || bad "rc-3 restore not green"

# --- (b) LEAK and (c) NEWLINE-ONLY-LEAK: one-site terminal-miss mutations ---
for MODE in LEAK NEWLINE; do
  input="totally-unknown-model-xyz"
  label=$([ "$MODE" = "LEAK" ] && echo "LEAK" || echo "NEWLINE-ONLY-LEAK")
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "$label baseline green" || { bad "$label baseline: rc=$rc err='$err'"; continue; }
  restore
  # deterministic mutation via python (sed \n replacement semantics are platform-ambiguous)
  python3 - "$R" "$MODE" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text().rstrip("\n")
assert t.endswith("exit 1"), "terminal miss line not found"
repl = 'printf "LEAK\\n"; exit 1' if sys.argv[2] == "LEAK" else "printf '\\n'; exit 1"
p.write_text(t[: -len("exit 1")] + repl + "\n")
PY
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "LEAK-STDOUT-ON-MISS"; } && ok "$label red: LEAK-STDOUT-ON-MISS exit 9" || bad "$label red: rc=$rc err='$err'"
  restore
  bash "$O" "$input" >/dev/null 2>&1 && ok "$label restored green" || bad "$label restore not green"
done

# --- (d) HIT-EMPTY: EXACT ONE-SITE mutation of the tier-1 hit printf (4 sites exist) ---
input="glm-5.2"
err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "HIT-EMPTY baseline green" || { bad "HIT-EMPTY baseline: rc=$rc err='$err'"; exit 0; }
restore
python3 - "$R" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
site = "printf '%s\\n' \"${canonicals[$i]}\""
assert t.count(site) == 4, f"site count {t.count(site)} != 4"
p.write_text(t.replace(site, ":", 1))   # mutate ONLY the first (tier-1) site
print("mutated exactly 1 of 4 sites", file=sys.stderr)
PY
[ $? -eq 0 ] && ok "HIT-EMPTY exact one-site mutation verified (1 of 4)" || bad "HIT-EMPTY one-site mutation failed"
err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 9 ] && printf '%s' "$err" | grep -q "HIT-EMPTY-ON-MATCH"; } && ok "HIT-EMPTY red: HIT-EMPTY-ON-MATCH exit 9" || bad "HIT-EMPTY red: rc=$rc err='$err'"
restore
bash "$O" "$input" >/dev/null 2>&1 && ok "HIT-EMPTY restored green" || bad "HIT-EMPTY restore not green"

# --- (e) MEASURE-FAIL family: PATH-shim wc (no resolver mutation) ---
mkdir -p "$WORK/fakebin"
wit_mf(){
  local name="$1" shimbody="$2" input="glm-5.2"
  err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "$name baseline green" || { bad "$name baseline: rc=$rc err='$err'"; return; }
  printf '%s\n' "$shimbody" > "$WORK/fakebin/wc"; chmod +x "$WORK/fakebin/wc"
  err=$(PATH="$WORK/fakebin:$PATH" bash "$O" "$input" 2>&1 >/dev/null); rc=$?
  { [ $rc -eq 8 ] && printf '%s' "$err" | grep -q "MEASURE-FAIL"; } && ok "$name red: MEASURE-FAIL exit 8" || bad "$name red: rc=$rc err='$err'"
  rm -f "$WORK/fakebin/wc"
  bash "$O" "$input" >/dev/null 2>&1 && ok "$name restored green" || bad "$name restore not green"
}
wit_mf "MEASURE-FAIL(failed wc)"  "exit 1"
wit_mf "MEASURE-FAIL(split digits)" "printf '1 2'"
wit_mf "MEASURE-FAIL(empty output)" "printf ''"
wit_mf "MEASURE-FAIL(alphabetic)"   "printf 'abc'"
wit_mf "MEASURE-FAIL(negative)"     "printf '-5'"

# --- padded-valid acceptance control (macOS-style padded count accepted) ---
input="glm-5.2"
err=$(bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 0 ] && [ -z "$err" ]; } && ok "padded-valid baseline green" || { bad "padded-valid baseline: rc=$rc err='$err'"; exit 0; }
printf '#!/usr/bin/env bash\nprintf "       7"\n' > "$WORK/fakebin/wc"; chmod +x "$WORK/fakebin/wc"
err=$(PATH="$WORK/fakebin:$PATH" bash "$O" "$input" 2>&1 >/dev/null); rc=$?
{ [ $rc -eq 0 ] && ! printf '%s' "$err" | grep -q "MEASURE-FAIL"; } && ok "padded-valid accepted: exit 0, no MEASURE-FAIL" || bad "padded-valid: rc=$rc err='$err'"
rm -rf "$WORK/fakebin"
bash "$O" "$input" >/dev/null 2>&1 && ok "padded-valid restored green" || bad "padded-valid restore not green"

restore
echo "WITNESSES: $PASS passed, $FAILN failed"
[ $FAILN -eq 0 ]
