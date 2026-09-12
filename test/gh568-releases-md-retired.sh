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
  for d in githooks utils relay-automation skills tools .github/workflows; do
    if [ -d "$search_root/$d" ]; then
      dirs+=("$search_root/$d")
    fi
  done

  # If explicit subdirs don't exist (e.g. in a minimal fixture), fall back to search_root itself
  if [ ${#dirs[@]} -eq 0 ]; then
    dirs=("$search_root")
  fi

  # 1. Empty-input guard: count candidate script/workflow/tool files
  local file_count
  file_count=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.js" -o -name "*.mjs" -o -name "*.ts" \) 2>/dev/null | \
    grep -v '/node_modules/' | grep -v '/dist/' | grep -v '/out/' | wc -l | tr -d ' ')
  if [ "${file_count:-0}" -eq 0 ]; then
    # Return 2 to distinguish empty-input failure from pattern match failure
    return 2
  fi

  # 2. Search for active write / redirect / stage patterns targeting RELEASES.md or RELEASES.generated.md
  # Exclude:
  # - test/ directory (not in dirs)
  # - comments (# or // or /* or * or docstrings)
  # - relay-automation/xyz-releases-onboard.sh (external onboarding tool)
  local writer_matches
  writer_matches=$(find "${dirs[@]}" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.js" -o -name "*.mjs" -o -name "*.ts" \) 2>/dev/null | \
    grep -v 'relay-automation/xyz-releases-onboard\.sh' | \
    grep -v '/node_modules/' | \
    grep -v '/dist/' | \
    grep -v '/out/' | \
    xargs grep -n -E '((\s|;)>\s*|(\s|;)>>\s*|\|\s*tee\s+|touch\s+|cp\s+.*|mv\s+.*).*RELEASES(\.generated)?\.md|open\([^)]*RELEASES(\.generated)?\.md[^)]*,\s*["\x27][wa]|(writeFileSync|writeFile|createWriteStream)\s*\(.*RELEASES(\.generated)?\.md' 2>/dev/null | \
    grep -v -E ':[0-9]+:\s*(#|//|/\*|\*|"""|\x27\x27\x27)' || true)

  if [ -n "$writer_matches" ]; then
    echo "$writer_matches" >&2
    return 1
  fi

  # 2b. Focused Python AST check: detect open() in write/append mode even with nested expressions (e.g. os.path.join)
  local py_files
  py_files=$(find "${dirs[@]}" -type f -name "*.py" 2>/dev/null | \
    grep -v 'relay-automation/xyz-releases-onboard\.sh' | \
    grep -v '/node_modules/' | \
    grep -v '/dist/' | \
    grep -v '/out/' || true)

  if [ -n "$py_files" ]; then
    local ast_matches
    ast_matches=$(echo "$py_files" | python3 -c '
import ast, sys

findings = []
for line in sys.stdin:
    path = line.strip()
    if not path:
        continue
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            tree = ast.parse(f.read(), filename=path)
    except Exception:
        continue
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            is_open = False
            if isinstance(node.func, ast.Name) and node.func.id == "open":
                is_open = True
            elif isinstance(node.func, ast.Attribute) and node.func.attr == "open":
                is_open = True
            if is_open and node.args:
                mode = None
                if len(node.args) >= 2 and isinstance(node.args[1], ast.Constant) and isinstance(node.args[1].value, str):
                    mode = node.args[1].value
                for kw in node.keywords:
                    if kw.arg == "mode" and isinstance(kw.value, ast.Constant) and isinstance(kw.value.value, str):
                        mode = kw.value.value
                if mode and any(m in mode for m in ("w", "a", "x", "+")):
                    has_retired = False
                    for child in ast.walk(node.args[0]):
                        if isinstance(child, ast.Constant) and isinstance(child.value, str):
                            if "RELEASES.md" in child.value or "RELEASES.generated.md" in child.value:
                                has_retired = True
                                break
                    if has_retired:
                        lineno = getattr(node, "lineno", 1)
                        findings.append(f"{path}:{lineno}: open() in write mode targeting retired releases file")
            elif isinstance(node.func, ast.Attribute) and node.func.attr in ("write_text", "write_bytes"):
                has_retired = False
                for child in ast.walk(node.func.value):
                    if isinstance(child, ast.Constant) and isinstance(child.value, str):
                        if "RELEASES.md" in child.value or "RELEASES.generated.md" in child.value:
                            has_retired = True
                            break
                if has_retired:
                    lineno = getattr(node, "lineno", 1)
                    findings.append(f"{path}:{lineno}: Path.write_* targeting retired releases file")
for f in findings:
    print(f)
' 2>/dev/null || true)

    if [ -n "$ast_matches" ]; then
      echo "$ast_matches" >&2
      return 1
    fi
  fi

  return 0
}

check_runtime_untouched() {
  local target_dir="$1"
  if [ ! -f "$target_dir/RELEASES.md" ] || [ "$(cat "$target_dir/RELEASES.md")" != "CANARY_LEDGER_ORIGINAL" ]; then
    return 1
  fi
  if [ ! -f "$target_dir/RELEASES.generated.md" ] || [ "$(cat "$target_dir/RELEASES.generated.md")" != "CANARY_GEN_ORIGINAL" ]; then
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

  # Control 6: Mutated runtime probe — prove check_runtime_untouched detects modified/resurrected files
  M6="$WORK/m6"
  mkdir -p "$M6"
  git init "$M6" >/dev/null 2>&1
  python3 "$root/utils/py/releases_app.py" --root "$M6" init --slug m6 >/dev/null 2>&1
  echo "CANARY_LEDGER_ORIGINAL" > "$M6/RELEASES.md"
  echo "CANARY_GEN_ORIGINAL" > "$M6/RELEASES.generated.md"
  python3 "$root/utils/py/releases_app.py" --root "$M6" add --version 1.0.0 --status draft --description "test" --tracking-issue "https://github.com/A/B/issues/1" >/dev/null 2>&1
  if check_runtime_untouched "$M6"; then
    echo "CORRUPTED_BY_WRITER" > "$M6/RELEASES.generated.md"
    if ! check_runtime_untouched "$M6"; then
      echo "WITNESS_RED_CONTROL_6: PASS (runtime probe correctly detected mutated/overwritten retired file)"
    else
      echo "WITNESS_RED_CONTROL_6: FAIL (runtime probe did not detect mutated file)"
      exit 1
    fi
  else
    echo "WITNESS_RED_CONTROL_6: FAIL (runtime write modified pre-existing retired files)"
    exit 1
  fi

  # Control 7: Mutated writer audit with JS/TS writer
  M7="$WORK/m7"
  mkdir -p "$M7/tools/vscode-cockpit"
  cat > "$M7/tools/vscode-cockpit/bad_writer.ts" <<'SUBEOF'
import * as fs from 'fs';
fs.writeFileSync("RELEASES.md", "resurrect\n");
SUBEOF
  if ! check_writer_audit "$M7" >/dev/null 2>&1; then
    echo "WITNESS_RED_CONTROL_7: PASS (correctly detected JS/TS write to RELEASES.md)"
  else
    echo "WITNESS_RED_CONTROL_7: FAIL (did not detect JS/TS write to RELEASES.md)"
    exit 1
  fi

  # Control 8: Mutated writer audit with Python nested expression write (GH-568 CodeRabbit)
  M8="$WORK/m8"
  mkdir -p "$M8/utils/py"
  cat > "$M8/utils/py/bad_nested_writer.py" <<'SUBEOF'
import os
with open(os.path.join("root", "RELEASES.md"), "w") as f:
    f.write("resurrect\n")
SUBEOF
  if ! check_writer_audit "$M8" >/dev/null 2>&1; then
    echo "WITNESS_RED_CONTROL_8: PASS (correctly detected nested expression Python write to RELEASES.md)"
  else
    echo "WITNESS_RED_CONTROL_8: FAIL (did not detect nested expression Python write)"
    exit 1
  fi

  echo "== ALL 8 RED CONTROLS WITNESSED PASSING =="
  exit 0
fi

# ── 1. Static Canary: ensure retired files do not exist in repo ──────────────

if check_canary "$root"; then
  pass "static canary: RELEASES.md and RELEASES.generated.md absent from repo root"
else
  fail "static canary: one or more retired releases files found at repo root"
fi

# ── 1b. Static artifact_paths key audit ─────────────────────────────────────

if python3 -c 'import sys; sys.path.insert(0, "'"$root/utils/py"'"); from releases_app import artifact_paths; p = artifact_paths("."); assert "gen" not in p, "gen in paths"; assert "drift" not in p, "drift in paths"; assert "ledger" not in p, "ledger in paths"'; then
  pass "artifact_paths() exposes only DB artifacts (no gen, drift, or ledger keys)"
else
  fail "artifact_paths() still exposes retired keys (gen, drift, or ledger)"
fi

# ── 1c. CLI gen command refusal audit (GH-568 CodeRabbit) ───────────────────

gen_tmp=$(mktemp -d)
set +e
gen_out=$(python3 "$root/utils/py/releases_app.py" --root "$gen_tmp" gen 2>&1)
gen_rc=$?
set -e
if [ "$gen_rc" -ne 0 ] && echo "$gen_out" | grep -q "rule=retired" && [ ! -f "$gen_tmp/RELEASES.generated.md" ] && [ ! -f "$gen_tmp/RELEASES.md" ]; then
  pass "releases_app.py gen exits nonzero ($gen_rc), reports rule=retired, and creates no retired artifacts"
else
  fail "releases_app.py gen did not refuse cleanly with rule=retired (rc=$gen_rc)"
fi
rm -rf "$gen_tmp"

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

# ── 2b. Runtime untouched probe on pre-created retired files ────────────────

RPROBE="$WORK/rprobe"
mkdir -p "$RPROBE"
git init "$RPROBE" >/dev/null 2>&1
python3 "$root/utils/py/releases_app.py" --root "$RPROBE" init --slug rprobe >/dev/null 2>&1
echo "CANARY_LEDGER_ORIGINAL" > "$RPROBE/RELEASES.md"
echo "CANARY_GEN_ORIGINAL" > "$RPROBE/RELEASES.generated.md"
python3 "$root/utils/py/releases_app.py" --root "$RPROBE" add --version 1.0.0 --status draft --description "test" --tracking-issue "https://github.com/A/B/issues/1" >/dev/null 2>&1
if check_runtime_untouched "$RPROBE"; then
  pass "runtime probe: pre-created RELEASES.md and RELEASES.generated.md are never touched by releases add"
else
  fail "runtime probe: releases add modified pre-created RELEASES.md or RELEASES.generated.md"
fi

# ── 3. Static Writer & Pipeline Audit on Production Codebase ─────────────────

prod_count=$(find "$root/githooks" "$root/utils" "$root/relay-automation" "$root/skills" "$root/tools" "$root/.github/workflows" \
  -type f \( -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.js" -o -name "*.mjs" -o -name "*.ts" \) 2>/dev/null | \
  grep -v 'relay-automation/xyz-releases-onboard\.sh' | \
  grep -v '/node_modules/' | grep -v '/dist/' | grep -v '/out/' | wc -l | tr -d ' ')

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

# Red Control 6: Mutated runtime probe detects modified file
MUT_DIR6="$WORK/mut_runtime"
mkdir -p "$MUT_DIR6"
echo "CANARY_LEDGER_ORIGINAL" > "$MUT_DIR6/RELEASES.md"
echo "CANARY_GEN_ORIGINAL" > "$MUT_DIR6/RELEASES.generated.md"
echo "CORRUPTED" > "$MUT_DIR6/RELEASES.generated.md"
if ! check_runtime_untouched "$MUT_DIR6"; then
  pass "red control 6: runtime probe correctly reported RED when retired file was modified"
else
  fail "red control 6: runtime probe failed to detect modified retired file"
fi

# Red Control 7: Mutated writer audit with JS/TS writer
MUT_DIR7="$WORK/mut_ts_writer"
mkdir -p "$MUT_DIR7/tools/vscode-cockpit"
cat > "$MUT_DIR7/tools/vscode-cockpit/bad_writer.ts" <<'SUBEOF'
import * as fs from 'fs';
fs.writeFileSync("RELEASES.md", "resurrect\n");
SUBEOF
if ! check_writer_audit "$MUT_DIR7" >/dev/null 2>&1; then
  pass "red control 7: writer audit correctly reported RED when JS/TS write was injected"
else
  fail "red control 7: writer audit failed to detect JS/TS write to RELEASES.md"
fi

# Red Control 8: Mutated writer audit with Python nested expression write
MUT_DIR8="$WORK/mut_nested_writer"
mkdir -p "$MUT_DIR8/utils/py"
cat > "$MUT_DIR8/utils/py/bad_nested_writer.py" <<'SUBEOF'
import os
with open(os.path.join("root", "RELEASES.md"), "w") as f:
    f.write("resurrect\n")
SUBEOF
if ! check_writer_audit "$MUT_DIR8" >/dev/null 2>&1; then
  pass "red control 8: writer audit correctly reported RED when nested expression Python write was injected"
else
  fail "red control 8: writer audit failed to detect nested expression Python write to RELEASES.md"
fi

echo "== GH-568 ALL PASSED =="
exit 0
