#!/usr/bin/env bash
# test/gh307-gate-env-scrub.sh — GH-307: the pre-advance gate must not inherit the run's
# identity tags.
#
# marathon.sh drives each phase with XYZ_HARNESS_CONTEXT=marathon-phase and MARATHON_LANE_NS
# set, and the packet-generated invocation adds XYZ_SESSION_ID. The gate ran as a plain
# subshell/subprocess, so it inherited all three. test/xyz-harness-hooks.sh asserts on
# XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID and test/debug-mantra.sh asserts on MARATHON_LANE_NS,
# so `bash validate.sh` — the documented default gate — could never pass inside a marathon:
# phase 1 escalated `pre-advance-failed` with a correct, approved change.
#
# This file is the STRUCTURAL/parity guard. The BEHAVIOURAL proof (the gate reporting what it
# can actually see, driven through the real driver) lives in test/marathon-drive.sh §5b.
#
# Codex review round 1 (2026-07-26) rejected an earlier version of this file: its Python check
# was a bare `grep -q "\"$v\""`, which passes if a name merely appears in a comment or an unused
# tuple, and the narrowness loop inspected only the Bash twin. Both are fixed below by parsing
# the Python scrub set structurally instead of grepping for substrings.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
pass=0; fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "== test: gh307-gate-env-scrub =="

SCRUB=(XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS)
KEEP=(MARATHON_ROOT TICK_BIN TICK_REPO_ROOT)
PY="$ROOT/utils/py/marathon_drive.py"
SH="$ROOT/relay-automation/marathon-drive.sh"

# ── Python twin: parse the scrub set structurally (it is the twin that RUNS by default) ──
PY_REPORT="$(python3 - "$PY" <<'PYEOF'
import ast, re, sys
src = open(sys.argv[1]).read()

# 1. GATE_SCRUBBED_ENV must exist and be a literal tuple/list of plain strings.
m = re.search(r"^\s*GATE_SCRUBBED_ENV\s*=\s*(\(.*?\)|\[.*?\])", src, re.S | re.M)
if not m:
    print("NOSET"); raise SystemExit
try:
    names = list(ast.literal_eval(m.group(1)))
except Exception:
    print("UNPARSEABLE"); raise SystemExit
print("SET:" + ",".join(str(n) for n in names))

# 2. The pre-advance gate must actually USE it — env=_gate_env() on its subprocess.run.
g = re.search(r"def run_pre_advance_gate\(\):(.*?)(?=\n    def |\nif __name__|\Z)", src, re.S)
body = g.group(1) if g else ""
print("USESENV:" + ("yes" if re.search(r"env\s*=\s*_gate_env\(\)", body) else "no"))

# 3. _gate_env must derive from the scrub set, not a hardcoded subset.
h = re.search(r"def _gate_env\(\):(.*?)(?=\n    def |\Z)", src, re.S)
hb = h.group(1) if h else ""
print("POPSFROMSET:" + ("yes" if "GATE_SCRUBBED_ENV" in hb and ".pop(" in hb else "no"))
PYEOF
)"

py_set="$(printf '%s\n' "$PY_REPORT" | /usr/bin/sed -n 's/^SET://p')"
py_uses="$(printf '%s\n' "$PY_REPORT" | /usr/bin/sed -n 's/^USESENV://p')"
py_pops="$(printf '%s\n' "$PY_REPORT" | /usr/bin/sed -n 's/^POPSFROMSET://p')"

if [[ -z "$py_set" ]]; then
  bad "python twin: GATE_SCRUBBED_ENV missing or not a literal (report: $PY_REPORT)"
else
  want="$(printf '%s\n' "${SCRUB[@]}" | /usr/bin/sort | /usr/bin/tr '\n' ',')"
  got="$(printf '%s\n' "$py_set" | /usr/bin/tr ',' '\n' | /usr/bin/sort | /usr/bin/tr '\n' ',')"
  [[ "$want" == "$got" ]] \
    && ok "python twin scrubs EXACTLY the three tags ($py_set)" \
    || bad "python twin scrub set mismatch — want [${want%,}] got [${got%,}]"
  for v in "${KEEP[@]}"; do
    if printf '%s\n' "$py_set" | /usr/bin/tr ',' '\n' | /usr/bin/grep -qx "$v"; then
      bad "python twin wrongly scrubs $v (a gate may need it)"
    else
      ok "python twin preserves $v"
    fi
  done
fi
[[ "$py_uses" == "yes" ]] \
  && ok "python gate passes env=_gate_env() to subprocess.run" \
  || bad "python run_pre_advance_gate does not use env=_gate_env() — scrub set is inert"
[[ "$py_pops" == "yes" ]] \
  && ok "python _gate_env derives from GATE_SCRUBBED_ENV (not a hardcoded list)" \
  || bad "python _gate_env does not derive from GATE_SCRUBBED_ENV"

# ── Bash twin: same three unset INSIDE run_pre_advance_gate; the rest preserved ──
sh_body="$(/usr/bin/awk '/^run_pre_advance_gate\(\)/{f=1} f{print} f&&/^}/{exit}' "$SH")"
for v in "${SCRUB[@]}"; do
  if printf '%s\n' "$sh_body" | /usr/bin/grep -q "unset .*$v"; then
    ok "bash twin scrubs $v inside run_pre_advance_gate"
  else
    bad "bash twin does not scrub $v inside run_pre_advance_gate"
  fi
done
for v in "${KEEP[@]}"; do
  if printf '%s\n' "$sh_body" | /usr/bin/grep -q "unset .*$v"; then
    bad "bash twin wrongly scrubs $v (a gate may need it)"
  else
    ok "bash twin preserves $v"
  fi
done

echo "  gh307-gate-env-scrub: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
