#!/usr/bin/env bash
# run-tests.sh — lightweight self-verify entry point for a vendored (foreign-repo) install.
#
# GH-110 P2b: `validate.sh` is the canonical suite runner, but it is a repo-root file that does NOT
# travel with a vendored copy (xyz-vendor.sh mirrors relay-automation/bin/src/utils/test/skills only —
# see relay-automation/xyz-vendor.sh:250). A consumer standing in a vendored copy has no obvious "how
# do I self-verify" path. This script fills that gap without assuming any repo-root file exists:
# individual tests that DO need a root-only file (e.g. ROADMAP-DASHBOARD.md, .github/workflows/ci.yml,
# validate.sh itself) already self-skip via their own skip() guards, so this runner just needs to find
# and invoke test/*.sh — it makes no assumption about what lives above test/.
#
# Exit 0 = all discovered tests passed (or self-skipped); Exit 1 = at least one failed.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$HERE/test"

if [ ! -d "$TEST_DIR" ]; then
  echo "run-tests.sh: no test/ directory found under $HERE — nothing to run." >&2
  exit 1
fi

# Files this deliberately does NOT run:
#   - leading-underscore files (_setup.sh, _scratch-repo.sh) — sourced helpers, not standalone tests.
#   - fixtures/gamma-poison/verify-fixture.sh — deliberately excluded from validate.sh too: it drives
#     the whole validate.sh itself, so nesting it here would recurse (see validate.sh's own comment).
#   - test-agy-isolation.sh / test-agy-standalone-repo.sh / relay-uncited-findings.sh — present in
#     test/ but not wired into validate.sh's own TESTS array either (unvetted for unattended/foreign
#     runs); skip here too so this runner's pass/fail matches the canonical suite's coverage.
SKIP_BASENAMES=" test-agy-isolation.sh test-agy-standalone-repo.sh relay-uncited-findings.sh "

PASSED=()
FAILED=()

while IFS= read -r -d '' t; do
  base="$(basename "$t")"
  case "$base" in
    _*) continue ;;
  esac
  case "$SKIP_BASENAMES" in
    *" $base "*) continue ;;
  esac
  rel="${t#"$TEST_DIR"/}"
  echo
  echo "==============================="
  echo "Running $rel"
  echo "==============================="
  if bash "$t"; then
    PASSED+=("$rel")
  else
    FAILED+=("$rel")
  fi
done < <(find "$TEST_DIR" -maxdepth 1 -name '*.sh' -print0 | sort -z)

# GH-40 canary fixtures: verify-fixture.sh under each fixtures/<name>/ IS part of the suite (mirrors
# validate.sh), except gamma-poison (recursion hazard — see comment above).
while IFS= read -r -d '' t; do
  case "$t" in
    *gamma-poison*) continue ;;
  esac
  rel="${t#"$TEST_DIR"/}"
  echo
  echo "==============================="
  echo "Running $rel"
  echo "==============================="
  if bash "$t"; then
    PASSED+=("$rel")
  else
    FAILED+=("$rel")
  fi
done < <(find "$TEST_DIR/fixtures" -mindepth 2 -maxdepth 2 -name 'verify-fixture.sh' -print0 2>/dev/null | sort -z)

if command -v python3 >/dev/null 2>&1 && [ -f "$TEST_DIR/test_python_layer.py" ]; then
  echo
  echo "==============================="
  echo "Running python3 -m pytest test/test_python_layer.py"
  echo "==============================="
  if python3 -m pytest "$TEST_DIR/test_python_layer.py"; then
    PASSED+=("python:test_python_layer.py")
  else
    FAILED+=("python:test_python_layer.py")
  fi
fi

echo
echo "==============================="
echo "Summary"
echo "==============================="
TOTAL=$(( ${#PASSED[@]} + ${#FAILED[@]} ))
echo "passed: ${#PASSED[@]} / ${TOTAL}"
for t in "${PASSED[@]}"; do echo "  + $t"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
  exit 1
fi
exit 0
