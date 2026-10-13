#!/usr/bin/env bash
set -euo pipefail
#
# find-harness.sh — GH-70 Phase 2: the concurrency-readiness warning in `find-harness.sh --check`.
# A foreign repo with no local .xyz/ resolves to the CENTRALIZED harness (shared global driver lock),
# so --check must WARN (fail-open, exit 0) and point at xyz-vendor.sh. A vendored repo (its own .xyz/)
# or the harness clone itself must NOT warn.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
FH="$REPO/skills/1-hourly/relay-xyz/find-harness.sh"
SKILL="$REPO/skills/1-hourly/relay-xyz/SKILL.md"
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
# `bash skills/1-hourly/relay-xyz/find-harness.sh --check`. It resolved against the caller's CWD and failed
# in every installed/foreign-CWD scenario. Pin the installed-root discovery before exercising the
# locator itself, so the documentation cannot reintroduce a path bug while this script stays green.
ok "skill front door searches the user install root" \
  "grep -q '\$HOME/.claude/skills/relay-xyz/find-harness.sh' '$SKILL'"
ok "skill front door does not prescribe the CWD-relative command" \
  "! grep -q '^bash skills/1-hourly/relay-xyz/find-harness.sh --check$' '$SKILL'"

# --- Case 1: from the harness clone itself → resolves to self, NO concurrency warning, exit 0 ---
out1="$( cd "$REPO" && bash "$FH" --check 2>&1 )"; rc1=$?
ok "harness clone: --check exits 0"                 "[ '$rc1' -eq 0 ]"
ok "harness clone: no concurrency warning"          "! grep -qi concurrency <<<\"\$out1\""

# --- Case 2: from a FOREIGN repo with NO .xyz/ → warns + vendor command, still exit 0 (fail-open) ---
FHWORK="$(mktemp -d "${TMPDIR:-/tmp}/find-harness.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$FHWORK"   # GH-10: pin the sandbox root (FR below is deleted between cases)
FR="$(mktemp -d "$FHWORK/fh-foreign.XXXXXX")"; require_fixture "$FR" "foreign fixture"  # GH-10
git -C "$FR" init -q
out2="$( cd "$FR" && bash "$FH" --check 2>&1 )"; rc2=$?
ok "foreign no-.xyz: --check still exits 0 (fail-open)"  "[ '$rc2' -eq 0 ]"
ok "foreign no-.xyz: emits the concurrency warning"      "grep -qi 'concurrency' <<<\"\$out2\""
# GH-421: the hint must use the REAL contract (target repo is the sole positional). Asserting the
# old 'xyz-vendor.sh vendor' form is what kept the broken hint alive — the test pinned the defect.
ok "foreign no-.xyz: points at xyz-vendor.sh"            "grep -q 'xyz-vendor.sh ' <<<\"\$out2\""
ok "foreign no-.xyz: hint omits the bogus vendor subcommand" "! grep -q 'xyz-vendor.sh vendor' <<<\"\$out2\""
rm -rf "$FR"

# --- Case 3: foreign repo WITH a local .xyz/ harness → resolves to it, NO concurrency warning ---
FV="$(mktemp -d "$FHWORK/fh-vendored.XXXXXX")"; require_fixture "$FV" "vendored harness fixture"  # GH-10
git -C "$FV" init -q
seed_vendored_harness "$FV"
out3="$( cd "$FV" && bash "$FH" --check 2>&1 )"; rc3=$?
ok "vendored .xyz: --check exits 0"                 "[ '$rc3' -eq 0 ]"
ok "vendored .xyz: no concurrency warning"          "! grep -qi concurrency <<<\"\$out3\""
ok "vendored .xyz: resolves to the local .xyz"      "grep -q '.xyz' <<<\"\$out3\""
rm -rf "$FV"

# --- Case 4: ignorecase=true + colliding index entries -> warn, name both paths, still exit 0 ---
FC="$(mkrepo)"
git -C "$FC" config core.ignorecase true
seed_case_collision "$FC"
out4="$( cd "$FC" && bash "$FH" --check 2>&1 )"; rc4=$?
ok "case-collision: --check still exits 0 (fail-open)" "[ '$rc4' -eq 0 ]"
ok "case-collision: emits the advisory warning"         "grep -q 'case-collision:' <<<\"\$out4\""
ok "case-collision: names both colliding paths"         "grep -q 'relay-system/x.md' <<<\"\$out4\" && grep -q 'RELAY-SYSTEM/y.md' <<<\"\$out4\""
ok "case-collision: explains the exit-6 risk + git mv remedy" "grep -q 'exit 6' <<<\"\$out4\" && grep -q 'git mv' <<<\"\$out4\""
rm -rf "$FC"

# --- Case 5: vendored repo + collision -> still warn from the caller repo, exit 0 ---
FVC="$(mkrepo)"
git -C "$FVC" config core.ignorecase true
seed_vendored_harness "$FVC"
seed_case_collision "$FVC"
out5="$( cd "$FVC" && bash "$FH" --check 2>&1 )"; rc5=$?
ok "vendored collision: --check exits 0"                 "[ '$rc5' -eq 0 ]"
ok "vendored collision: emits the case-collision warning" "grep -q 'case-collision:' <<<\"\$out5\""
ok "vendored collision: names both colliding paths"       "grep -q 'relay-system/x.md' <<<\"\$out5\" && grep -q 'RELAY-SYSTEM/y.md' <<<\"\$out5\""
ok "vendored collision: stays scoped to caller repo"      "grep -q 'relay harness readiness:' <<<\"\$out5\""
rm -rf "$FVC"

# --- Case 6: ordinary repo (no collision) -> no case-collision warning, still exit 0 ---
FN="$(mkrepo)"
git -C "$FN" config core.ignorecase true
seed_index_path "$FN" "docs/readme.md"
out6="$( cd "$FN" && bash "$FH" --check 2>&1 )"; rc6=$?
ok "no-collision: --check exits 0"                     "[ '$rc6' -eq 0 ]"
ok "no-collision: case-collision warning absent"       "! grep -q 'case-collision:' <<<\"\$out6\""
rm -rf "$FN"

# --- Case 7: ignorecase=false + colliding index entries -> no warning, still exit 0 ---
FS="$(mkrepo)"
git -C "$FS" config core.ignorecase false
seed_case_collision "$FS"
out7="$( cd "$FS" && bash "$FH" --check 2>&1 )"; rc7=$?
ok "ignorecase=false collision: --check exits 0"       "[ '$rc7' -eq 0 ]"
ok "ignorecase=false collision: warning absent"        "! grep -q 'case-collision:' <<<\"\$out7\""
rm -rf "$FS"

# GH-856: Skills Army copies the skill outside the harness. Use an isolated HOME
# so the bounded search cannot read a real Mac's canonical clone or config.
FHWORK="$(cd -P "$FHWORK" && pwd)"
fixture_guard_init "$FHWORK"
COPIED="$FHWORK/Deployed Skills/relay-xyz/find-harness.sh"
mkdir -p "$(dirname "$COPIED")" "$FHWORK/gh856-home" "$FHWORK/gh856-foreign"
git -C "$FHWORK/gh856-foreign" init -q
cp "$FH" "$COPIED"
GH856_HOME="$FHWORK/gh856-home"
GH856_CONFIG="$FHWORK/gh856-config"
seed_canonical() {
  _target="$1"
  mkdir -p "$_target/relay-automation" "$_target/bin"
  git -C "$_target" init -q -b development
  git -C "$_target" config user.email gh856@test
  git -C "$_target" config user.name gh856
  git -C "$_target" remote add origin https://github.com/HiQS-Labs/XYZ-forge.git
  printf '#!/usr/bin/env bash\n:\n' > "$_target/relay-automation/relay-drive.sh"
  chmod +x "$_target/relay-automation/relay-drive.sh"
  cp "$REPO/relay-automation/harness-paths.sh" "$REPO/relay-automation/driver-lock-lib.sh" "$_target/relay-automation/"
  printf '#!/usr/bin/env bash\n:\n' > "$_target/bin/tick"
  chmod +x "$_target/bin/tick"
  git -C "$_target" add .
  git -C "$_target" commit -qm seed
}
copied_run() {
  (cd "$FHWORK/gh856-foreign" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT \
    HOME="$GH856_HOME" XDG_CONFIG_HOME="$GH856_CONFIG" bash "$COPIED" "$@")
}
GH856_ROOTS=(
  "$GH856_HOME/Documents/GH Repos/XYZ-forge"
  "$GH856_HOME/Documents/GitHub/XYZ-forge"
  "$GH856_HOME/Documents/GitHub Repos/XYZ-forge"
  "$GH856_HOME/Documents/GitHub-Repos/XYZ-forge"
  "$GH856_HOME/Documents/Github/XYZ-forge"
  "$GH856_HOME/XYZ-forge"
  "$GH856_HOME/Developer/XYZ-forge"
)
_rc=0; _out="$(copied_run --check 2>&1)" || _rc=$?
if [ "$_rc" -eq 1 ] && grep -q 'attempted locations:' <<<"$_out" \
   && grep -q "XYZ_HARNESS='/path/to/XYZ-forge'" <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: copied skill gives an actionable no-candidate failure"
else fail=$((fail+1)); echo "  FAIL: copied skill gives an actionable no-candidate failure (rc=$_rc)"; fi
seed_canonical "$GH856_HOME/Documents/GH Repos/XYZ-forge-gh123"
_rc=0; _ignored="$(copied_run --root 2>&1)" || _rc=$?
if [ "$_rc" -eq 1 ]; then
  pass=$((pass+1)); echo "  PASS: similarly named task clone cannot win discovery"
else fail=$((fail+1)); echo "  FAIL: similarly named task clone cannot win discovery"; fi
require_fixture "$GH856_HOME/Documents/GH Repos/XYZ-forge-gh123" "GH-856 task clone"
rm -rf "$GH856_HOME/Documents/GH Repos/XYZ-forge-gh123"
seed_canonical "${GH856_ROOTS[0]}"
git -C "${GH856_ROOTS[0]}" remote set-url origin https://github.com/other/XYZ-forge.git
_rc=0; _ignored="$(copied_run --root 2>&1)" || _rc=$?
if [ "$_rc" -eq 1 ]; then
  pass=$((pass+1)); echo "  PASS: wrong-origin XYZ-forge cannot win discovery"
else fail=$((fail+1)); echo "  FAIL: wrong-origin XYZ-forge cannot win discovery"; fi
require_fixture "${GH856_ROOTS[0]}" "GH-856 wrong-origin clone"
rm -rf "${GH856_ROOTS[0]}"
for _root in "${GH856_ROOTS[@]}"; do
  if grep -Fq "$_root" <<<"$_out"; then
    pass=$((pass+1)); echo "  PASS: no-candidate diagnostic lists $_root"
  else fail=$((fail+1)); echo "  FAIL: no-candidate diagnostic omits $_root"; fi
  seed_canonical "$_root"
  _rc=0; _found="$(copied_run --root 2>&1)" || _rc=$?
  _found_path="${_found##*$'\n'}"
  if [ "$_rc" -eq 0 ] && [ "$_found_path" -ef "$_root" ] \
     && grep -q 'via=search' <<<"$_found"; then
    pass=$((pass+1)); echo "  PASS: copied skill searches $_root"
  else fail=$((fail+1)); echo "  FAIL: copied skill searches $_root (rc=$_rc, out=$_found)"; fi
  require_fixture "$_root" "GH-856 searched clone"
  rm -rf "$_root"
done

# Exact-name and origin filters; two equal canonical candidates must be named.
seed_canonical "${GH856_ROOTS[0]}"
seed_canonical "${GH856_ROOTS[1]}"
_rc=0; _out="$(copied_run --root 2>&1)" || _rc=$?
if [ "$_rc" -eq 1 ] && grep -q 'multiple canonical candidates:' <<<"$_out" \
   && grep -Fq "${GH856_ROOTS[0]}" <<<"$_out" && grep -Fq "${GH856_ROOTS[1]}" <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: equally qualified clones cause a named refusal"
else fail=$((fail+1)); echo "  FAIL: equally qualified clones cause a named refusal"; fi
git -C "${GH856_ROOTS[1]}" switch -qc topic
_out="$(copied_run --root 2>&1)"
if grep -Fq "HARNESS=${GH856_ROOTS[0]}" <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: unique development clone wins"
else fail=$((fail+1)); echo "  FAIL: unique development clone wins"; fi
require_fixture "${GH856_ROOTS[1]}" "GH-856 alternate clone"
rm -rf "${GH856_ROOTS[1]}"

# An override-selected canonical clone prints an executable per-device config
# command. The second run must resolve from that file without an override.
_hint="$(cd "$FHWORK/gh856-foreign" && XYZ_HARNESS="${GH856_ROOTS[0]}" \
  HOME="$GH856_HOME" XDG_CONFIG_HOME="$GH856_CONFIG" bash "$COPIED" --check \
  | sed -n 's/^  save this harness on this Mac: //p')"
if [ -n "$_hint" ] && bash -c "$_hint" \
   && [ "$(cat "$GH856_CONFIG/xyz/harness")" = "${GH856_ROOTS[0]}" ]; then
  pass=$((pass+1)); echo "  PASS: --check config hint writes the chosen path"
else fail=$((fail+1)); echo "  FAIL: --check config hint writes the chosen path"; fi
_out="$(copied_run --root 2>&1)"
if grep -Fq "HARNESS=${GH856_ROOTS[0]}" <<<"$_out" && grep -q 'via=config' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: copied skill resolves the saved config"
else fail=$((fail+1)); echo "  FAIL: copied skill resolves the saved config"; fi
_env="$(copied_run --env 2>/dev/null)"
_env_check='test "$HARNESS" = "$1" && test "$TICK_REPO_ROOT" = "$1" && test "$RELAY_HAS_TICK" = 1 && test "${TICK:-}" = "$1/bin/tick" && test -x "${TICK:-/nonexistent}"'
if bash -c "$_env"$'\n'"$_env_check" _ "${GH856_ROOTS[0]}"; then
  pass=$((pass+1)); echo "  PASS: copied skill --env exports usable harness, repo root, and tick"
else fail=$((fail+1)); echo "  FAIL: copied skill --env exports usable harness, repo root, and tick"; fi
git -C "${GH856_ROOTS[0]}" switch -qc topic
_out="$(copied_run --check 2>&1)"
if grep -q 'harness clone is on topic, expected development' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: copied skill warns on a non-development branch"
else fail=$((fail+1)); echo "  FAIL: copied skill warns on a non-development branch"; fi
git -C "${GH856_ROOTS[0]}" switch -q development
printf '/missing/XYZ-forge\n' > "$GH856_CONFIG/xyz/harness"
_out="$(copied_run --root 2>&1)"
if grep -q 'ignoring invalid config' <<<"$_out" && grep -q 'via=search' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: invalid config falls through to canonical search"
else fail=$((fail+1)); echo "  FAIL: invalid config falls through to canonical search"; fi
bash -c "$_hint"

# The library must come from the selected harness; lock and cached-upstream
# warnings are advisory and require no network access.
mkdir -p "${GH856_ROOTS[0]}/.git/relay-driver.lock"
printf '%s\n' "$$" > "${GH856_ROOTS[0]}/.git/relay-driver.lock/pid"
git -C "${GH856_ROOTS[0]}" config branch.development.remote origin
git -C "${GH856_ROOTS[0]}" config branch.development.merge refs/heads/development
_base="$(git -C "${GH856_ROOTS[0]}" rev-parse HEAD)"
printf 'new\n' > "${GH856_ROOTS[0]}/new"
git -C "${GH856_ROOTS[0]}" add new
git -C "${GH856_ROOTS[0]}" commit -qm newer
_new="$(git -C "${GH856_ROOTS[0]}" rev-parse HEAD)"
git -C "${GH856_ROOTS[0]}" update-ref refs/remotes/origin/development "$_new"
git -C "${GH856_ROOTS[0]}" reset -q --hard "$_base"
printf 'cached fetch\n' > "${GH856_ROOTS[0]}/.git/FETCH_HEAD"
_rc=0; _out="$(copied_run --check 2>&1)" || _rc=$?
if [ "$_rc" -eq 0 ] && grep -q 'driver lock is currently HELD' <<<"$_out" \
   && grep -q '1 commits behind origin/development (last fetch ' <<<"$_out" \
   && ! grep -q 'command not found' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: copied skill reports held lock and cached-upstream lag"
else fail=$((fail+1)); echo "  FAIL: copied skill reports held lock and cached-upstream lag (rc=$_rc, out=$_out)"; fi
sleep 0.01 & _dead_pid=$!
wait "$_dead_pid"
printf '%s\n' "$_dead_pid" > "${GH856_ROOTS[0]}/.git/relay-driver.lock/pid"
_out="$(copied_run --check 2>&1)"
if grep -q 'stale driver lock' <<<"$_out" && ! grep -q 'driver lock is currently HELD' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: dead holder is reported as a stale lock"
else fail=$((fail+1)); echo "  FAIL: dead holder is reported as a stale lock"; fi
git -C "${GH856_ROOTS[0]}" reset -q --hard "$_new"
seed_vendored_harness "$FHWORK/gh856-foreign"
printf 'source_commit=%s\n' "$_base" > "$FHWORK/gh856-foreign/.xyz/VERSION"
_out="$(copied_run --check 2>&1)"
if grep -q 'vendored .xyz harness is behind the live harness' <<<"$_out"; then
  pass=$((pass+1)); echo "  PASS: copied skill compares vendored drift with configured live harness"
else fail=$((fail+1)); echo "  FAIL: copied skill compares vendored drift with configured live harness"; fi
require_fixture "$FHWORK/Deployed Skills" "GH-856 copied skill"
require_fixture "$GH856_HOME" "GH-856 isolated HOME"
require_fixture "$GH856_CONFIG" "GH-856 isolated config"
rm -rf "$FHWORK/Deployed Skills" "$GH856_HOME" "$GH856_CONFIG" "$FHWORK/gh856-foreign"

echo "  find-harness: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
