#!/usr/bin/env bash
# ci-local.sh — run the tier1 CI job on this machine, step for step.
#
# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
# on every commit — not a test failure, but "the job was not started because recent account payments
# have failed". A red check that means nothing is worse than no check, because a real break looks
# identical. This runs the same steps locally so the signal keeps existing.
#
# It mirrors .github/workflows/ci.yml's `tier1` job in ORDER and CONTENT, including its two
# deliberate skips. When that workflow changes, change this — test/ci-workflow.sh is the existing
# guard over the workflow itself, and drift between the two is a real (currently unpinned) risk.
#
# ─────────────────────────────────────────────────────────────────────────────────────────────────
# THIS IS NOT A DROP-IN REPLACEMENT FOR CI, AND THE DIFFERENCES ARE NOT COSMETIC
# ─────────────────────────────────────────────────────────────────────────────────────────────────
# CI runs ubuntu-latest. Your machine is probably macOS. The workflow's own comments record what that
# has already cost: GH-232 found ~12 suite failures that existed ONLY on ubuntu, from a BSD-only
# `sed -i ''` that mis-parses under GNU sed, and from tests that stubbed CLAUDE_BIN/AGY_BIN but not
# CODEX_BIN — so they passed locally purely because a real `codex` binary sat on the developer's PATH.
# macOS also ships bash 3.2 (2007); ubuntu ships bash 5.x.
#
# So: a green run here means "no defect a laptop can see". It does NOT mean CI would be green.
# Use it to stop paying for fast feedback, not to stop caring about the platform gap.
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#
# Usage:
#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1

FAST=0
BASE=""
while (($#)); do
  case "$1" in
    --fast) FAST=1; shift ;;
    --base) BASE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '1,30p' "$0"; exit 0 ;;
    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
  esac
done

PASSED=(); FAILED=()
step() {  # <name> — everything after is the step body, run in a subshell
  local name="$1"; shift
  printf '\n\033[1m=== %s\033[0m\n' "$name"
  if "$@"; then PASSED+=("$name"); else FAILED+=("$name"); printf '\033[31mFAILED: %s\033[0m\n' "$name" >&2; fi
}

# ── 1. prerequisites ─────────────────────────────────────────────────────────────────────────────
# CI apt-installs shellcheck; locally it is the operator's to provide. Checked up front so the run
# does not get 15 minutes in before discovering a missing binary.
check_prereqs() {
  local missing=0 c
  for c in shellcheck bash node python3 npm git; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '  ok       %s\n' "$c"
    else
      printf '  MISSING  %s\n' "$c" >&2; missing=1
    fi
  done
  [ "$missing" -eq 0 ] || {
    echo "  shellcheck: brew install shellcheck   (CI apt-installs it; this is the only extra dep)" >&2
    return 1
  }
  return 0
}

# ── 2-5. the cheap static checks, verbatim from the workflow ─────────────────────────────────────
shellcheck_tracked() {
  # severity=error, matching the workflow's deliberate choice to land green before tightening.
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    shellcheck -S error "$file" || rc=1
  done < <(git ls-files -- '*.sh')
  return $rc
}

bash_syntax_tracked() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    bash -n "$file" || rc=1
  done < <(git ls-files -- '*.sh')
  return $rc
}

node_syntax_tracked() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    node --check "$file" || rc=1
  done < <(git ls-files -- 'src/*.js' 'bin/*.js')
  return $rc
}

settings_json_valid() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    python3 -m json.tool "$file" >/dev/null || rc=1
  done < <(git ls-files -- '.claude/settings*.json')
  return $rc
}

# ── 6. PDDA ──────────────────────────────────────────────────────────────────────────────────────
pdda_gate() {
  utils/pdda/pdda.sh run || return 1
  # Warn-only by contract — it reports, it never gates. Kept outside the sync-managed utils/pdda/
  # tree because a 2026-08-03 upstream sync silently deleted three of these checks.
  utils/pdda-local-checks.sh run || true
  return 0
}

# ── 7. frozen twin guard — PR-only in CI, so opt-in here ─────────────────────────────────────────
frozen_twin_guard() {
  bash test/gh308-frozen-twin-guard.sh --check --base "$BASE" --allow-exceptions
}

# ── 8. npm + acorn-extract ───────────────────────────────────────────────────────────────────────
# A fresh clone has no node_modules, so acorn-extract dies with MODULE_NOT_FOUND. CI proves the
# README Quickstart path from scratch (GH-230); the same install is what makes a fresh checkout
# gate-ready at all — a marathon has already halted on exactly this.
npm_and_acorn() {
  npm ci || return 1
  bash test/acorn-extract.sh
}

# ── 9. the suite ─────────────────────────────────────────────────────────────────────────────────
# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
# on WHICH tests run — only on the environment they run in.
#
# NOTE: `git config --global` is what CI does before this step, to supply the user identity and
# init.defaultBranch that fixture-driven tests assume. That is deliberately NOT done here: a dev
# machine already has both, and silently rewriting an operator's global git config is not something
# a test runner should do. If a fixture test fails on a bare machine, set them yourself.
validate_suite() {
  local skip_tests=(
    "acorn-extract.sh"                # already run above (needs npm ci first)
    "registry-lock-concurrency.sh"    # GH-72/GH-232: flaky under load, 16 concurrent tick writers
  )
  local all_tests=() line t s skip rc=0
  while IFS= read -r line; do
    [ -n "$line" ] && all_tests+=("$line")
  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')

  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
  echo "  ${#all_tests[@]} suites declared in validate.sh"

  for t in "${all_tests[@]}"; do
    skip=0
    for s in "${skip_tests[@]}"; do [ "$t" = "$s" ] && { skip=1; break; }; done
    [ "$skip" -eq 1 ] && { echo "SKIP (GH-232): $t"; continue; }
    echo "=== $t ==="
    bash "test/$t" || { rc=1; echo "  ^^ FAILED: $t" >&2; }
  done
  return $rc
}

# ── run ──────────────────────────────────────────────────────────────────────────────────────────
printf '\033[1mci-local — mirroring .github/workflows/ci.yml tier1\033[0m\n'
printf 'repo: %s\n' "$HERE"
printf 'HEAD: %s\n' "$(git log --oneline -1 2>/dev/null)"
[ "$FAST" -eq 1 ] && printf '\033[33mmode: --fast (full validate.sh suite SKIPPED)\033[0m\n'

step "prerequisites"                check_prereqs
step "shellcheck tracked scripts"   shellcheck_tracked
step "bash syntax"                  bash_syntax_tracked
step "node syntax"                  node_syntax_tracked
step "settings JSON"                settings_json_valid
step "PDDA deterministic gate"      pdda_gate
if [ -n "$BASE" ]; then
  step "frozen twin guard"          frozen_twin_guard
else
  printf '\n\033[33mSKIP: frozen twin guard — CI runs it on pull_request only. Pass --base <ref> to run it.\033[0m\n'
fi
step "npm ci + acorn-extract"       npm_and_acorn
if [ "$FAST" -eq 0 ]; then
  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
fi

# ── report ───────────────────────────────────────────────────────────────────────────────────────
printf '\n\033[1m─── ci-local summary ───\033[0m\n'
for s in "${PASSED[@]}"; do printf '  \033[32m+\033[0m %s\n' "$s"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  for s in "${FAILED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$s"; done
  printf '\n\033[31mci-local: %d step(s) failed\033[0m\n' "${#FAILED[@]}"
  printf 'Remember: a failure here is real, but a PASS here is not a promise CI would be green —\n'
  printf 'CI runs ubuntu-latest with GNU sed and bash 5.x. See the header.\n'
  exit 1
fi
printf '\n\033[32mci-local: all steps passed\033[0m\n'
printf 'This means no defect a laptop can see. It is NOT equivalent to a green ubuntu CI run.\n'
exit 0
