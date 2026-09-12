#!/usr/bin/env bash
# test/gh568-releases-md-retired.sh — regression guard for complete RELEASES.md & RELEASES.generated.md retirement (GH-568)
#
# Verifies:
#   1. Static canary: RELEASES.md, RELEASES.generated.md, and RELEASES.generated.md.drift are absent from repo root.
#   2. Active tools execute cleanly without RELEASES.md:
#      - releases_app.py list
#      - releases_app.py show --version 0.7.0
#      - releases_app.py check
#      - wave_reconcile.py --help
#      - utils/release-lanes.sh --help
#   3. Static writer & pipeline audit:
#      - No active scripts or workflows in utils/, githooks/, relay-automation/, skills/, .github/workflows/
#        contain production writes, redirects, stages, or generations targeting RELEASES.md or RELEASES.generated.md.
#      - Explicitly exempts: releases.sql data rows, LEADERBOARD.md, CHANGELOG.md, historical archives,
#        and relay-automation/xyz-releases-onboard.sh (external repo migration tool).
#   4. Falsification & witnessed red controls:
#      - Mutated fixtures confirm that file presence, active write redirection, and empty search inputs
#        properly trigger failure.
#      - Supports --mutate-evidence to emit formatted witness records.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_setup.sh" "GH-568" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

MUTATE_EVIDENCE=0
if [ "${1:-}" = "--mutate-evidence" ]; then
  MUTATE_EVIDENCE=1
fi

# ── Function definitions for canary and writer audits ────────────────────────

check_canary() {
  local target_root="$1"
  if [ -f "$target_root/RELEASES.md" ]; then
    return 1
  fi
  if [ -f "$target_root/RELEASES.generated.md" ]; then
    return 1
  fi
  if [ -f "$target_root/RELEASES.generated.md.drift" ]; then
    return 1
  fi
  return 0
}

check_writer_audit() {
  local search_root="$1"
  local dirs=()
  for d in githooks utils relay-automation skills .github/workflows; do
    if [ -d "$search_root/$d" ]; then
      dirs+=("$search_root/$d")
    fi
  done

  # If explicit subdirs don't exist (e.g. in a minimal fixture), fall back to search_root itself
  if [ ${#dirs[@]} -eq 0 ]; then
    dirs=("$search_root")
  fi

  # 1. Empty-input guard: count candidate script/workflow files
  local file_count
  file_count=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l | tr -d ' ')
  if [ "${file_count:-0}" -eq 0 ]; then
    # Return 2 to distinguish empty-input failure from pattern match failure
    return 2
  fi

  # 2. Search for active write / redirect / stage patterns targeting RELEASES.md or RELEASES.generated.md
  # Exclude:
  # - test/ directory (not in dirs)
  # - comments (# or //)
  # - relay-automation/xyz-releases-onboard.sh (external onboarding tool)
  local writer_matches
  writer_matches=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | \
    grep -v 'relay-automation/xyz-releases-onboard\.sh' | \
    xargs grep -n -E '((\s|;)>\s*|(\s|;)>>\s*|\|\s*tee\s+|touch\s+|cp\s+.*|mv\s+.*).*RELEASES(\.generated)?\.md|open\([^)]*RELEASES(\.generated)?\.md[^)]*,\s*["\x27][wa]' 2>/dev/null | \
    grep -v -E ':[0-9]+:\s*(#|//|"""|\x27\x27\x27)' || true)

  if [ -n "$writer_matches" ]; then
    echo "$writer_matches" >&2
    return 1
  fi

  return 0
}

# If --mutate-evidence was requested, run only the negative controls and report evidence
if [ "$MUTATE_EVIDENCE" = "1" ]; then
  echo "== GH-568 Mutate Evidence Mode =="

  # Control 1: Mutated canary with RELEASES.md present
  M1="$WORK/m1"
  mkdir -p "$M1"
  touch "$M1/RELEASES.md"
  if ! check_canary "$M1"; then
    echo "WITNESS_RED_CONTROL_1: PASS (correctly detected RELEASES.md presence)"
  else
    echo "WITNESS_RED_CONTROL_1: FAIL (did not detect RELEASES.md presence)"
    exit 1
  fi

  # Control 2: Mutated canary with RELEASES.generated.md present
  M2="$WORK/m2"
  mkdir -p "$M2"
  touch "$M2/RELEASES.generated.md"
  if ! check_canary "$M2"; then
    echo "WITNESS_RED_CONTROL_2: PASS (correctly detected RELEASES.generated.md presence)"
  else
    echo "WITNESS_RED_CONTROL_2: FAIL (did not detect RELEASES.generated.md presence)"
    exit 1
  fi

  # Control 3: Mutated writer audit with active redirection writer
  M3="$WORK/m3"
  mkdir -p "$M3/utils"
  cat > "$M3/utils/bad_redirect.sh" <<'SUBEOF'
#!/usr/bin/env bash
echo "resurrect" > RELEASES.md
SUBEOF
  if ! check_writer_audit "$M3" >/dev/null 2>&1; then
    echo "WITNESS_RED_CONTROL_3: PASS (correctly detected write redirection to RELEASES.md)"
  else
    echo "WITNESS_RED_CONTROL_3: FAIL (did not detect write redirection)"
    exit 1
  fi

  # Control 4: Mutated writer audit with Python write
  M4="$WORK/m4"
  mkdir -p "$M4/utils/py"
  cat > "$M4/utils/py/bad_writer.py" <<'SUBEOF'
with open("RELEASES.generated.md", "w") as f:
    f.write("resurrect\n")
SUBEOF
  if ! check_writer_audit "$M4" >/dev/null 2>&1; then
    echo "WITNESS_RED_CONTROL_4: PASS (correctly detected Python write to RELEASES.generated.md)"
  else
    echo "WITNESS_RED_CONTROL_4: FAIL (did not detect Python write)"
    exit 1
  fi

  # Control 5: Empty-input guard
  M5="$WORK/m5"
  mkdir -p "$M5"
  rc5=0
  check_writer_audit "$M5" || rc5=$?
  if [ "$rc5" -eq 2 ]; then
    echo "WITNESS_RED_CONTROL_5: PASS (empty-input guard returned code 2 on empty search root)"
  else
    echo "WITNESS_RED_CONTROL_5: FAIL (empty-input guard returned $rc5 instead of 2)"
    exit 1
  fi

  echo "== ALL 5 RED CONTROLS WITNESSED PASSING =="
  exit 0
fi

# ── 1. Static Canary: ensure retired files do not exist in repo ──────────────

if check_canary "$root"; then
  pass "static canary: RELEASES.md and RELEASES.generated.md absent from repo root"
else
  fail "static canary: one or more retired releases files found at repo root"
fi

# ── 2. Active Tools Execution ────────────────────────────────────────────────

if python3 "$root/utils/py/releases_app.py" list >/dev/null 2>&1; then
  pass "releases_app.py list operates cleanly without RELEASES.md"
else
  fail "releases_app.py list failed"
fi

if python3 "$root/utils/py/releases_app.py" show --version 0.7.0 >/dev/null 2>&1; then
  pass "releases_app.py show operates cleanly without RELEASES.md"
else
  fail "releases_app.py show failed"
fi

if python3 "$root/utils/py/releases_app.py" check >/dev/null 2>&1; then
  pass "releases_app.py check operates cleanly without RELEASES.md"
else
  fail "releases_app.py check failed"
fi

if python3 "$root/utils/py/wave_reconcile.py" --help >/dev/null 2>&1; then
  pass "wave_reconcile.py executes cleanly without RELEASES.generated.md"
else
  fail "wave_reconcile.py --help failed"
fi

if bash "$root/utils/release-lanes.sh" --help >/dev/null 2>&1; then
  pass "utils/release-lanes.sh executes cleanly without RELEASES.md"
else
  fail "utils/release-lanes.sh --help failed"
fi

# ── 3. Static Writer & Pipeline Audit on Production Codebase ─────────────────

prod_count=$(find "$root/githooks" "$root/utils" "$root/relay-automation" "$root/skills" "$root/.github/workflows" \
  -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l | tr -d ' ')

if [ "$prod_count" -gt 30 ]; then
  pass "audit scanned $prod_count candidate production files (empty-input guard passed)"
else
  fail "audit found only $prod_count candidate files, expected > 30"
fi

if check_writer_audit "$root"; then
  pass "writer audit: zero active writers or redirects found in production paths"
else
  fail "writer audit: found active writers or redirects targeting retired release files in production paths"
fi

# ── 4. Witnessed Red Controls (Falsification) ────────────────────────────────

# Red Control 1: Mutated canary with RELEASES.md present
MUT_DIR1="$WORK/mut_canary1"
mkdir -p "$MUT_DIR1"
touch "$MUT_DIR1/RELEASES.md"
if ! check_canary "$MUT_DIR1"; then
  pass "red control 1: canary correctly reported RED when RELEASES.md was injected"
else
  fail "red control 1: canary failed to detect RELEASES.md presence"
fi

# Red Control 2: Mutated canary with RELEASES.generated.md present
MUT_DIR2="$WORK/mut_canary2"
mkdir -p "$MUT_DIR2"
touch "$MUT_DIR2/RELEASES.generated.md"
if ! check_canary "$MUT_DIR2"; then
  pass "red control 2: canary correctly reported RED when RELEASES.generated.md was injected"
else
  fail "red control 2: canary failed to detect RELEASES.generated.md presence"
fi

# Red Control 3: Mutated writer audit with active redirection writer
MUT_DIR3="$WORK/mut_writer"
mkdir -p "$MUT_DIR3/utils"
cat > "$MUT_DIR3/utils/bad_script.sh" <<'SUBEOF'
#!/usr/bin/env bash
echo "resurrect" > RELEASES.md
SUBEOF
if ! check_writer_audit "$MUT_DIR3" >/dev/null 2>&1; then
  pass "red control 3: writer audit correctly reported RED when write redirection was injected"
else
  fail "red control 3: writer audit failed to detect write redirection to RELEASES.md"
fi

# Red Control 4: Mutated writer audit with Python write
MUT_DIR4="$WORK/mut_py_writer"
mkdir -p "$MUT_DIR4/utils/py"
cat > "$MUT_DIR4/utils/py/bad_script.py" <<'SUBEOF'
with open("RELEASES.generated.md", "w") as f:
    f.write("resurrect\n")
SUBEOF
if ! check_writer_audit "$MUT_DIR4" >/dev/null 2>&1; then
  pass "red control 4: writer audit correctly reported RED when Python write was injected"
else
  fail "red control 4: writer audit failed to detect Python write to RELEASES.generated.md"
fi

# Red Control 5: Empty-input guard returns code 2 on empty search directory
MUT_DIR5="$WORK/mut_empty"
mkdir -p "$MUT_DIR5"
empty_rc=0
check_writer_audit "$MUT_DIR5" || empty_rc=$?
if [ "$empty_rc" -eq 2 ]; then
  pass "red control 5: empty-input guard correctly returned exit 2 on empty candidate directory"
else
  fail "red control 5: empty-input guard returned $empty_rc instead of 2 on empty candidate directory"
fi

echo "== GH-568 ALL PASSED =="
exit 0
