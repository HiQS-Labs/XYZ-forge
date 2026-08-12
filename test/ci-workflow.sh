#!/usr/bin/env bash
# test/ci-workflow.sh — regression lock for the additive GH-61 Tier 1 GitHub Actions workflow.
#
# Dependency-free by default: validates the workflow's required markers with grep/sed only.
# If python3 has PyYAML available, it also parses the workflow as YAML; otherwise that sub-check
# self-skips so the test stays green on stock machines.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/ci.yml"
VALIDATE="$ROOT/validate.sh"

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $*"; SKIP=$((SKIP + 1)); }

require_marker() {
  local marker="$1"
  local label="$2"
  if grep -Fq "$marker" "$WORKFLOW"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "== test: ci-workflow =="
echo "  workflow: $WORKFLOW"

if [ -s "$WORKFLOW" ]; then
  pass "workflow exists and is non-empty"
else
  fail "workflow missing or empty"
fi

if grep -Eq '^[[:space:]]*runs-on:[[:space:]]*ubuntu-latest[[:space:]]*$' "$WORKFLOW"; then
  pass "workflow runs on ubuntu-latest"
else
  fail "workflow must declare runs-on: ubuntu-latest"
fi

if grep -Eq '^[[:space:]]*push:[[:space:]]*$' "$WORKFLOW" && grep -Eq '^[[:space:]]*pull_request:[[:space:]]*$' "$WORKFLOW"; then
  pass "workflow triggers on push and pull_request"
else
  fail "workflow must trigger on push and pull_request"
fi

# Both long-lived integration branches must be gated. `development` is the WIP
# branch every PR targets (GH-216); it was omitted here originally, so PRs into
# it ran no CI at all. Assert each trigger's branch list names both.
branch_list_count="$(grep -Ec '^[[:space:]]*branches:[[:space:]]*\[[^]]*\bmain\b[^]]*\bdevelopment\b[^]]*\]' "$WORKFLOW")"
if [ "${branch_list_count:-0}" -ge 2 ]; then
  pass "workflow scopes both triggers to main and development"
else
  fail "workflow must scope push and pull_request to main and development"
fi

require_marker "shellcheck" "workflow references shellcheck"
require_marker "bash -n" "workflow references bash -n"
require_marker "node --check" "workflow references node --check"
require_marker ".claude/settings" "workflow references .claude/settings JSON validation"
require_marker "utils/pdda/pdda.sh run" "workflow references utils/pdda/pdda.sh run"
require_marker "utils/ci-route.sh pull_request" "workflow delegates PR routing to the tested classifier"
require_marker "steps.route.outputs.pdda_needed == 'true'" "PDDA is path-routed instead of unconditional"
require_marker "steps.route.outputs.route == 'fast'" "workflow declares the fast PR route"
require_marker "steps.route.outputs.route == 'full'" "workflow declares the full integration route"
require_marker 'CHANGED_TESTS: ${{ steps.route.outputs.changed_tests }}' "fast route consumes changed-area tests"
require_marker 'github.event_name }}-${{ github.event.pull_request.number || github.ref' "concurrency is scoped by event and PR/branch"
require_marker "cancel-in-progress: true" "superseded runs are cancelled"

if grep -Eq '^[[:space:]]*schedule:[[:space:]]*$' "$WORKFLOW"; then
  fail "workflow must not add an automatic daily full-suite minute burn"
else
  pass "full-suite fallback is manual rather than an automatic daily burn"
fi

skip_block="$(sed -n '/^[[:space:]]*SKIP_TESTS=(/,/^[[:space:]]*)/p' "$WORKFLOW")"
skips_pdda_fixture=false
if grep -Fq 'pdda-local-checks.sh' <<<"$skip_block"; then
  skips_pdda_fixture=true
fi
if grep -Fq 'pdda-roadmap-coverage.sh' <<<"$skip_block"; then
  skips_pdda_fixture=true
fi
if [[ "$skips_pdda_fixture" == true ]]; then
  fail "full gate must retain PDDA fixture/negative-control tests"
else
  pass "full gate retains PDDA fixture/negative-control tests"
fi

if grep -Fq 'steps.filter.outputs' "$WORKFLOW"; then
  fail "legacy docs-only filter references must not survive the route classifier"
else
  pass "legacy docs-only filter references are gone"
fi

if grep -Eq 'ci-workflow\.sh' "$VALIDATE"; then
  pass "validate.sh wires ci-workflow.sh"
else
  fail "validate.sh must wire ci-workflow.sh"
fi

if grep -Eq 'ci-route\.sh' "$VALIDATE"; then
  pass "validate.sh wires ci-route.sh"
else
  fail "validate.sh must wire ci-route.sh"
fi

if command -v python3 >/dev/null 2>&1 && python3 - <<'PY' >/dev/null 2>&1
import yaml
PY
then
  if python3 - "$WORKFLOW" <<'PY' >/dev/null
import sys
import yaml

with open(sys.argv[1], "r") as fh:
    yaml.safe_load(fh)
PY
  then
    pass "workflow parses as YAML when PyYAML is available"
  else
    fail "workflow must parse as YAML when PyYAML is available"
  fi
else
  skip "PyYAML unavailable; YAML parse check skipped"
fi

# ── ci-local.sh must not drift from the workflow it mirrors ──────────────────────────────────────
# `ci-local.sh` reproduces this job step-for-step so the signal survives a metered/blocked Actions
# account. A mirror with nothing pinning it to its original is the exact failure this repo keeps
# paying for — frozen Bash twins, and a packaged tarball that staled the moment its source changed.
# So pin the two things that would silently diverge and change WHICH tests run.
CI_LOCAL="$ROOT/ci-local.sh"

if [ -f "$CI_LOCAL" ]; then
  # (1) The TESTS-parsing expression. Both read validate.sh's array; if one is edited to parse
  # differently, the two run different suites while both still look correct in isolation.
  wf_parse="$(grep -F "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$WORKFLOW" | tr -d ' ')"
  cl_parse="$(grep -F "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$CI_LOCAL" | tr -d ' ')"
  if [ -n "$wf_parse" ] && [ "$wf_parse" = "$cl_parse" ]; then
    pass "ci-local.sh parses validate.sh's TESTS with the same expression as the workflow"
  else
    fail "ci-local.sh and ci.yml disagree on how TESTS is parsed — they will run different suites"
  fi

  # (2) The skip list. A test skipped in CI but run locally (or the reverse) makes a green run in one
  # place mean something different from a green run in the other — which is worse than no mirror.
  for skipped in "acorn-extract.sh" "registry-lock-concurrency.sh"; do
    if grep -qF "\"$skipped\"" "$WORKFLOW" && grep -qF "\"$skipped\"" "$CI_LOCAL"; then
      pass "ci-local.sh carries the workflow's documented skip: $skipped"
    else
      fail "skip drift on $skipped — present in one of ci.yml/ci-local.sh but not the other"
    fi
  done

  # (3) The honesty notice. A green local run is NOT a green ubuntu run (GH-232 found ~12 failures
  # that existed only on ubuntu). If that caveat is ever edited out, the script starts overclaiming.
  if grep -q "NOT equivalent to a green ubuntu CI run" "$CI_LOCAL"; then
    pass "ci-local.sh still states that a local pass is not a CI pass"
  else
    fail "ci-local.sh dropped its ubuntu-divergence caveat — it now overclaims what a green run means"
  fi
else
  skip "ci-local.sh not present; mirror-drift checks skipped"
fi

echo
echo "Summary"
echo "  passed: $PASS"
echo "  failed: $FAIL"
echo "  skipped: $SKIP"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
