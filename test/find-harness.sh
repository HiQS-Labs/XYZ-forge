#!/usr/bin/env bash
set -euo pipefail
#
# find-harness.sh — GH-70 Phase 2: the concurrency-readiness warning in `find-harness.sh --check`.
# A foreign repo with no local .xyz/ resolves to the CENTRALIZED harness (shared global driver lock),
# so --check must WARN (fail-open, exit 0) and point at xyz-vendor.sh. A vendored repo (its own .xyz/)
# or the harness clone itself must NOT warn.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
SKILL="$REPO/skills/relay-xyz/SKILL.md"
pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
mkrepo() { _repo="$(mktemp -d "${TMPDIR:-/tmp}/fh-case.XXXXXX")"; git -C "$_repo" init -q; printf '%s\n' "$_repo"; }
seed_vendored_harness() {
  _repo="$1"
  mkdir -p "$_repo/.xyz/relay-automation" "$_repo/.xyz/bin"
  printf '#!/usr/bin/env bash\n:\n' > "$_repo/.xyz/relay-automation/relay-drive.sh"; chmod +x "$_repo/.xyz/relay-automation/relay-drive.sh"
  printf '#!/usr/bin/env bash\n:\n' > "$_repo/.xyz/bin/tick"; chmod +x "$_repo/.xyz/bin/tick"
}
seed_index_path() {
  _repo="$1"; _path="$2"
  _blob="$(printf 'fixture\n' | git -C "$_repo" hash-object -w --stdin)"
  git -C "$_repo" update-index --add --cacheinfo 100644,"$_blob","$_path"
}
seed_case_collision() {
  _repo="$1"
  seed_index_path "$_repo" "relay-system/x.md"
  seed_index_path "$_repo" "RELAY-SYSTEM/y.md"
}

echo "find-harness (GH-70 Phase 2):"
[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }

# GH-563 shakedown: the skill's mandatory first command used to be
# `bash skills/relay-xyz/find-harness.sh --check`. It resolved against the caller's CWD and failed
# in every installed/foreign-CWD scenario. Pin the installed-root discovery before exercising the
# locator itself, so the documentation cannot reintroduce a path bug while this script stays green.
ok "skill front door searches the user install root" \
  "grep -q '\$HOME/.claude/skills/relay-xyz/find-harness.sh' '$SKILL'"
ok "skill front door does not prescribe the CWD-relative command" \
  "! grep -q '^bash skills/relay-xyz/find-harness.sh --check$' '$SKILL'"

# --- Case 1: from the harness clone itself → resolves to self, NO concurrency warning, exit 0 ---
out1="$( cd "$REPO" && bash "$FH" --check 2>&1 )"; rc1=$?
ok "harness clone: --check exits 0"                 "[ '$rc1' -eq 0 ]"
ok "harness clone: no concurrency warning"          "! printf '%s' \"\$out1\" | grep -qi concurrency"

# --- Case 2: from a FOREIGN repo with NO .xyz/ → warns + vendor command, still exit 0 (fail-open) ---
FHWORK="$(mktemp -d "${TMPDIR:-/tmp}/find-harness.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$FHWORK"   # GH-10: pin the sandbox root (FR below is deleted between cases)
FR="$(mktemp -d "$FHWORK/fh-foreign.XXXXXX")"; require_fixture "$FR" "foreign fixture"  # GH-10
git -C "$FR" init -q
out2="$( cd "$FR" && bash "$FH" --check 2>&1 )"; rc2=$?
ok "foreign no-.xyz: --check still exits 0 (fail-open)"  "[ '$rc2' -eq 0 ]"
ok "foreign no-.xyz: emits the concurrency warning"      "printf '%s' \"\$out2\" | grep -qi 'concurrency'"
# GH-421: the hint must use the REAL contract (target repo is the sole positional). Asserting the
# old 'xyz-vendor.sh vendor' form is what kept the broken hint alive — the test pinned the defect.
ok "foreign no-.xyz: points at xyz-vendor.sh"            "printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh '"
ok "foreign no-.xyz: hint omits the bogus vendor subcommand" "! printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh vendor'"
rm -rf "$FR"

# --- Case 3: foreign repo WITH a local .xyz/ harness → resolves to it, NO concurrency warning ---
FV="$(mktemp -d "$FHWORK/fh-vendored.XXXXXX")"; require_fixture "$FV" "vendored harness fixture"  # GH-10
git -C "$FV" init -q
seed_vendored_harness "$FV"
out3="$( cd "$FV" && bash "$FH" --check 2>&1 )"; rc3=$?
ok "vendored .xyz: --check exits 0"                 "[ '$rc3' -eq 0 ]"
ok "vendored .xyz: no concurrency warning"          "! printf '%s' \"\$out3\" | grep -qi concurrency"
ok "vendored .xyz: resolves to the local .xyz"      "printf '%s' \"\$out3\" | grep -q '.xyz'"
rm -rf "$FV"

# --- Case 4: ignorecase=true + colliding index entries -> warn, name both paths, still exit 0 ---
FC="$(mkrepo)"
git -C "$FC" config core.ignorecase true
seed_case_collision "$FC"
out4="$( cd "$FC" && bash "$FH" --check 2>&1 )"; rc4=$?
ok "case-collision: --check still exits 0 (fail-open)" "[ '$rc4' -eq 0 ]"
ok "case-collision: emits the advisory warning"         "printf '%s' \"\$out4\" | grep -q 'case-collision:'"
ok "case-collision: names both colliding paths"         "printf '%s' \"\$out4\" | grep -q 'relay-system/x.md' && printf '%s' \"\$out4\" | grep -q 'RELAY-SYSTEM/y.md'"
ok "case-collision: explains the exit-6 risk + git mv remedy" "printf '%s' \"\$out4\" | grep -q 'exit 6' && printf '%s' \"\$out4\" | grep -q 'git mv'"
rm -rf "$FC"

# --- Case 5: vendored repo + collision -> still warn from the caller repo, exit 0 ---
FVC="$(mkrepo)"
git -C "$FVC" config core.ignorecase true
seed_vendored_harness "$FVC"
seed_case_collision "$FVC"
out5="$( cd "$FVC" && bash "$FH" --check 2>&1 )"; rc5=$?
ok "vendored collision: --check exits 0"                 "[ '$rc5' -eq 0 ]"
ok "vendored collision: emits the case-collision warning" "printf '%s' \"\$out5\" | grep -q 'case-collision:'"
ok "vendored collision: names both colliding paths"       "printf '%s' \"\$out5\" | grep -q 'relay-system/x.md' && printf '%s' \"\$out5\" | grep -q 'RELAY-SYSTEM/y.md'"
ok "vendored collision: stays scoped to caller repo"      "printf '%s' \"\$out5\" | grep -q 'relay harness readiness:'"
rm -rf "$FVC"

# --- Case 6: ordinary repo (no collision) -> no case-collision warning, still exit 0 ---
FN="$(mkrepo)"
git -C "$FN" config core.ignorecase true
seed_index_path "$FN" "docs/readme.md"
out6="$( cd "$FN" && bash "$FH" --check 2>&1 )"; rc6=$?
ok "no-collision: --check exits 0"                     "[ '$rc6' -eq 0 ]"
ok "no-collision: case-collision warning absent"       "! printf '%s' \"\$out6\" | grep -q 'case-collision:'"
rm -rf "$FN"

# --- Case 7: ignorecase=false + colliding index entries -> no warning, still exit 0 ---
FS="$(mkrepo)"
git -C "$FS" config core.ignorecase false
seed_case_collision "$FS"
out7="$( cd "$FS" && bash "$FH" --check 2>&1 )"; rc7=$?
ok "ignorecase=false collision: --check exits 0"       "[ '$rc7' -eq 0 ]"
ok "ignorecase=false collision: warning absent"        "! printf '%s' \"\$out7\" | grep -q 'case-collision:'"
rm -rf "$FS"

echo "  find-harness: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
