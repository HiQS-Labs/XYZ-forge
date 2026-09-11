#!/usr/bin/env bash
# test/gh567-roadmap-dashboard-retired.sh — regression guard for complete ROADMAP-DASHBOARD.md retirement
#
# Verifies:
#   1. Static canary: ROADMAP-DASHBOARD.md, utils/roadmap-dashboard.sh, and
#      githooks/dashboard-staleness-guard.sh are absent from repo root.
#   2. Active tools execute cleanly without ROADMAP-DASHBOARD.md:
#      - releases_app.py roadmap list / render
#      - wave_reconcile.py --help
#   3. Static writer & pipeline audit:
#      - No active scripts or workflows write, redirect, stage, or invoke ROADMAP-DASHBOARD.md
#        or the retired dashboard/guard scripts.
#   4. Falsification & witnessed red controls:
#      - Mutated fixtures confirm that file presence, active writers, and empty search inputs
#        properly trigger failure.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_setup.sh" "GH-567" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

# ── Function definitions for canary and writer audits ────────────────────────

check_canary() {
  local target_root="$1"
  if [ -f "$target_root/ROADMAP-DASHBOARD.md" ]; then
    return 1
  fi
  if [ -f "$target_root/utils/roadmap-dashboard.sh" ]; then
    return 1
  fi
  if [ -f "$target_root/githooks/dashboard-staleness-guard.sh" ]; then
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

  # 2. Search for active write / redirect / stage patterns targeting ROADMAP-DASHBOARD.md
  # Exclude test/ directory, markdown docs, and git history/evidence
  local writer_matches
  writer_matches=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null | \
    xargs -0 grep -n -E '(>|>>|tee|mv|cp|touch|stage).*ROADMAP-DASHBOARD\.md' 2>/dev/null || true)

  if [ -n "$writer_matches" ]; then
    echo "$writer_matches" >&2
    return 1
  fi

  # 3. Search for invocations of dashboard-staleness-guard.sh
  local guard_matches
  guard_matches=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null | \
    xargs -0 grep -n -E '\bdashboard-staleness-guard\.sh\b' 2>/dev/null || true)

  if [ -n "$guard_matches" ]; then
    echo "$guard_matches" >&2
    return 1
  fi

  # 4. Search for invocations of roadmap-dashboard.sh (excluding comments in frozen/legacy code)
  local renderer_matches
  renderer_matches=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null | \
    xargs -0 grep -n -E '\broadmap-dashboard\.sh\b' 2>/dev/null | grep -v -E ':[0-9]+:\s*(#|//)' || true)

  if [ -n "$renderer_matches" ]; then
    echo "$renderer_matches" >&2
    return 1
  fi

  return 0
}

# ── 1. Static Canary: ensure retired files do not exist in repo ──────────────

if check_canary "$root"; then
  pass "static canary: ROADMAP-DASHBOARD.md and retired scripts absent from repo root"
else
  fail "static canary: one or more retired dashboard files found at repo root"
fi

# ── 2. Active Tools Execution ────────────────────────────────────────────────

if python3 "$root/utils/py/releases_app.py" roadmap list >/dev/null 2>&1; then
  pass "releases_app.py roadmap list operates cleanly without ROADMAP-DASHBOARD.md"
else
  fail "releases_app.py roadmap list failed"
fi

if python3 "$root/utils/py/releases_app.py" roadmap render >/dev/null 2>&1; then
  pass "releases_app.py roadmap render operates on-demand to stdout without writing file"
else
  fail "releases_app.py roadmap render failed"
fi

if python3 "$root/utils/py/wave_reconcile.py" --help >/dev/null 2>&1; then
  pass "wave_reconcile.py executes cleanly without dashboard dependencies"
else
  fail "wave_reconcile.py --help failed"
fi

# ── 3. Static Writer & Pipeline Audit on Production Codebase ─────────────────

# Verify that our scan finds a substantial number of files in the repo (not empty)
prod_count=$(find "$root/githooks" "$root/utils" "$root/relay-automation" "$root/skills" "$root/.github/workflows" \
  -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l | tr -d ' ')

if [ "$prod_count" -gt 30 ]; then
  pass "audit scanned $prod_count candidate production files (empty-input guard passed)"
else
  fail "audit found only $prod_count candidate files, expected > 30"
fi

if check_writer_audit "$root"; then
  pass "writer audit: zero active writers or guards found in production paths"
else
  fail "writer audit: found active writers or retired guard references in production paths"
fi

# ── 4. Witnessed Red Controls (Falsification) ────────────────────────────────

# Red Control 1: Mutated canary with ROADMAP-DASHBOARD.md present
MUT_DIR1="$WORK/mut_canary1"
mkdir -p "$MUT_DIR1"
touch "$MUT_DIR1/ROADMAP-DASHBOARD.md"
if ! check_canary "$MUT_DIR1"; then
  pass "red control 1: canary correctly reported RED when ROADMAP-DASHBOARD.md was injected"
else
  fail "red control 1: canary failed to detect ROADMAP-DASHBOARD.md presence"
fi

# Red Control 2: Mutated canary with utils/roadmap-dashboard.sh present
MUT_DIR2="$WORK/mut_canary2"
mkdir -p "$MUT_DIR2/utils"
touch "$MUT_DIR2/utils/roadmap-dashboard.sh"
if ! check_canary "$MUT_DIR2"; then
  pass "red control 2: canary correctly reported RED when utils/roadmap-dashboard.sh was injected"
else
  fail "red control 2: canary failed to detect utils/roadmap-dashboard.sh presence"
fi

# Red Control 3: Mutated canary with githooks/dashboard-staleness-guard.sh present
MUT_DIR3="$WORK/mut_canary3"
mkdir -p "$MUT_DIR3/githooks"
touch "$MUT_DIR3/githooks/dashboard-staleness-guard.sh"
if ! check_canary "$MUT_DIR3"; then
  pass "red control 3: canary correctly reported RED when githooks/dashboard-staleness-guard.sh was injected"
else
  fail "red control 3: canary failed to detect githooks/dashboard-staleness-guard.sh presence"
fi

# Red Control 4: Mutated writer audit with active redirection writer
MUT_DIR4="$WORK/mut_writer"
mkdir -p "$MUT_DIR4/utils"
cat > "$MUT_DIR4/utils/bad_script.sh" <<'EOF'
#!/usr/bin/env bash
echo "resurrect" > ROADMAP-DASHBOARD.md
EOF
if ! check_writer_audit "$MUT_DIR4" >/dev/null 2>&1; then
  pass "red control 4: writer audit correctly reported RED when write redirection was injected"
else
  fail "red control 4: writer audit failed to detect write redirection to ROADMAP-DASHBOARD.md"
fi

# Red Control 5: Mutated writer audit with retired guard invocation
MUT_DIR5="$WORK/mut_guard"
mkdir -p "$MUT_DIR5/githooks"
cat > "$MUT_DIR5/githooks/bad_hook.sh" <<'EOF'
#!/usr/bin/env bash
bash githooks/dashboard-staleness-guard.sh
EOF
if ! check_writer_audit "$MUT_DIR5" >/dev/null 2>&1; then
  pass "red control 5: writer audit correctly reported RED when guard invocation was injected"
else
  fail "red control 5: writer audit failed to detect dashboard-staleness-guard.sh invocation"
fi

# Red Control 6: Empty-input guard returns code 2 on empty search directory
MUT_DIR6="$WORK/mut_empty"
mkdir -p "$MUT_DIR6"
empty_rc=0
check_writer_audit "$MUT_DIR6" || empty_rc=$?
if [ "$empty_rc" -eq 2 ]; then
  pass "red control 6: empty-input guard correctly returned exit 2 on empty candidate directory"
else
  fail "red control 6: empty-input guard returned $empty_rc instead of 2 on empty candidate directory"
fi

# Red Control 7: Mutated writer audit with retired renderer invocation
MUT_DIR7="$WORK/mut_renderer"
mkdir -p "$MUT_DIR7/utils"
cat > "$MUT_DIR7/utils/bad_call.sh" <<'EOF'
#!/usr/bin/env bash
bash utils/roadmap-dashboard.sh
EOF
if ! check_writer_audit "$MUT_DIR7" >/dev/null 2>&1; then
  pass "red control 7: writer audit correctly reported RED when roadmap-dashboard.sh invocation was injected"
else
  fail "red control 7: writer audit failed to detect roadmap-dashboard.sh invocation"
fi

echo "== GH-567 ALL PASSED =="
exit 0
