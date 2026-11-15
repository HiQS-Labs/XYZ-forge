#!/usr/bin/env bash
# GH-251 / GH-1437: healthy Python reaches pytest; absent dependencies fail before suites.
source "$(dirname "$0")/_setup.sh" gh251-validate-pytest-skip

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
require_forge_root validate.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
VAL="$ROOT/validate.sh"
[ -x "$VAL" ] || { echo "  FAIL: validate.sh not executable: $VAL" >&2; exit 1; }

export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"

PATHS_FILE="$WORK/paths.txt"
# GH-808: the suite only needs --paths-file to classify tier 2 with T2_PYTEST=1 (any
# *.py path sets it) — naming releases_app.py routed both nested runs at the ~24-suite
# releases lane and made this suite ~22% of the full gate. skills-army-hq is the
# smallest measured .py-bearing lane (2 suites).
printf 'skills/3-weekly/skills-army-hq/scripts/sync.py\n' > "$PATHS_FILE"

# 1. Normal run when pytest is present — runs and passes test_python_layer.py
if python3 -c "import pytest" >/dev/null 2>&1; then
  out="$(bash "$VAL" --paths-file "$PATHS_FILE" 2>&1 || true)"
  case "$out" in
    *"Running python3 -m pytest test/test_python_layer.py"*)
      pass "validate.sh invokes pytest when pytest is importable"
      ;;
    *)
      fail "validate.sh did not invoke pytest when importable: $out"
      ;;
  esac
  case "$out" in
    *"+ python:test_python_layer.py"*)
      pass "python:test_python_layer.py is reported passed"
      ;;
    *)
      fail "python:test_python_layer.py was not reported in passed list: $out"
      ;;
  esac
fi

# 2. Absent pytest simulation — python3 shims out pytest import
FAKE_BIN="$WORK/fake-bin"
mkdir -p "$FAKE_BIN"
REAL_PY="$(command -v python3)"
cat >"$FAKE_BIN/python3" <<PYSH
#!/usr/bin/env bash
if [ "\$#" -ge 2 ] && [ "\$1" = "-c" ] && [ "\$2" = "import pytest" ]; then
  exit 1
fi
if [ "\$#" -ge 2 ] && [ "\$1" = "-m" ] && [ "\$2" = "pytest" ]; then
  echo "No module named pytest" >&2
  exit 1
fi
exec "$REAL_PY" "\$@"
PYSH
chmod +x "$FAKE_BIN/python3"

out="$(PATH="$FAKE_BIN:$PATH" bash "$VAL" --paths-file "$PATHS_FILE" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && [ -n "$out" ] \
  && grep -Fq "ENVIRONMENT FAULT: python3 ($FAKE_BIN/python3) version" <<<"$out" \
  && grep -Fq 'missing modules: pytest' <<<"$out" \
  && ! grep -Fq 'Running python3 -m pytest' <<<"$out" \
  && pass "absent pytest is an environment refusal before suite execution" \
  || fail "absent pytest did not fail early (exit $rc): $out"

# GH-732: a different interpreter without PyYAML must name itself and the repair PATH.
YAML_BIN="$WORK/no-yaml"; mkdir -p "$YAML_BIN"
cat > "$YAML_BIN/python3" <<PYSH
#!/usr/bin/env bash
if [ "\$#" -ge 2 ] && [ "\$1" = "-c" ] && [ "\$2" = "import yaml" ]; then
  exit 1
fi
exec "$REAL_PY" "\$@"
PYSH
chmod +x "$YAML_BIN/python3"
out="$(PATH="$YAML_BIN:$PATH" bash "$VAL" --print-mode 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && [ -n "$out" ] \
  && grep -Fq "ENVIRONMENT FAULT: python3 ($YAML_BIN/python3) version" <<<"$out" \
  && grep -Fq 'missing modules: yaml' <<<"$out" \
  && grep -Fq 'PATH="$HOME/.cache/xyz-forge-test-venv/bin:$PATH" bash validate.sh' <<<"$out" \
  && grep -Fq 'NOT promotion evidence (GH-732)' <<<"$out" \
  && pass "missing yaml names the interpreter, repair PATH, and evidence limit" \
  || fail "missing yaml diagnostic regressed (exit $rc): $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
