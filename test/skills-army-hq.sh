#!/usr/bin/env bash
# GH-487: the tier-2 registry's currency is bash suites registered in validate.sh's TESTS array,
# so the skills-army-hq dedicated pytest (test/test_deploy_skills.py) is carried through this
# wrapper — one selection mechanism, no parallel registry kind. The pytest file is self-contained:
# it importlib-loads the skill scripts and writes only to its own temp fixtures.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PYTEST_FILE="$HERE/test_deploy_skills.py"
[ -f "$PYTEST_FILE" ] || { echo "  FAIL: test_deploy_skills.py not found beside this wrapper" >&2; exit 1; }
if ! python3 -c "import pytest" >/dev/null 2>&1; then
  # gh251 convention: a named skip, never a silent green.
  echo "  SKIPPED: python:test_deploy_skills.py (pytest not importable — install it to cover skills/skills-army-hq)"
  exit 0
fi
exec python3 -m pytest "$PYTEST_FILE"
