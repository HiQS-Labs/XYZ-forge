#!/usr/bin/env bash
# GH-251: validate.sh reports python:test_python_layer.py as SKIPPED when pytest is absent,
# and keeps genuine pytest failures in FAILED.
source "$(dirname "$0")/_setup.sh" gh251-validate-pytest-skip

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VAL="$ROOT/validate.sh"
[ -x "$VAL" ] || { echo "  FAIL: validate.sh not executable: $VAL" >&2; exit 1; }

export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"

PATHS_FILE="$WORK/paths.txt"
printf 'utils/py/releases_app.py\n' > "$PATHS_FILE"

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

out="$(PATH="$FAKE_BIN:$PATH" bash "$VAL" --paths-file "$PATHS_FILE" 2>&1 || true)"
case "$out" in
  *"SKIPPED: python:test_python_layer.py (pytest not importable — install it to cover utils/py/)"*)
    pass "absent pytest outputs the documented named SKIPPED line"
    ;;
  *)
    fail "absent pytest did not output the expected SKIPPED line: $out"
    ;;
esac

case "$out" in
  *"QUARANTINED"*"python:test_python_layer.py"*)
    pass "absent pytest is tracked in the SKIPPED summary list"
    ;;
  *)
    fail "absent pytest was not listed in summary SKIPPED list: $out"
    ;;
esac

case "$out" in
  *"- python:test_python_layer.py"*)
    fail "absent pytest should not be listed under failed: $out"
    ;;
  *)
    pass "absent pytest does not land in FAILED"
    ;;
esac

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
