#!/usr/bin/env bash
# GH-49 — vendored local copy of the harness. Covers the whole surface:
#   xyz-vendor.sh (materialize + VERSION + gitignore + registry, idempotent, --no-register),
#   find-harness.sh .xyz/ preference + warn-continue staleness (default path byte-identical),
#   xyz-sync.sh list/update/delete, and the SessionStart reminder hook.
source "$(dirname "$0")/_setup.sh" xyz-vendor

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
SYNC="$ROOT/relay-automation/xyz-sync.sh"
FH="$ROOT/skills/relay-xyz/find-harness.sh"
HOOK="$ROOT/relay-automation/hooks/xyz-vendor-reminder.sh"

for f in "$VENDOR" "$SYNC" "$FH" "$HOOK"; do
  [ -f "$f" ] && bash -n "$f" 2>/dev/null && pass "parses: ${f#$ROOT/}" || fail "missing/parse-fail: ${f#$ROOT/}"
done

# Isolated registry + a scratch "foreign repo".
export XYZ_REGISTRY="$WORK/registry.tsv"
# Canonicalize via `cd && pwd` (macOS /var -> /private/var) so paths match what xyz-vendor +
# find-harness store/resolve — otherwise the symlinked mktemp dir breaks string compares.
mkdir -p "$WORK/foreign"; git init -q "$WORK/foreign"; REPO="$(cd "$WORK/foreign" && pwd -P)"

# --- vendor materializes a complete .xyz/ ---
"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "vendor exited non-zero"
relay_n=$(find "$REPO/.xyz/relay-automation" -type f 2>/dev/null | wc -l | tr -d ' ')
test_n=$(find "$REPO/.xyz/test" -type f 2>/dev/null | wc -l | tr -d ' ')
# 16 relay-pkg files (10 relay-automation + 6 test) + 4 GH-49b marathon files (in relay-automation) = 20.
[ "$((relay_n + test_n))" = 20 ] && pass "20 harness scripts vendored ($relay_n relay-automation + $test_n test)" || fail "expected 20 (16 relay-pkg + 4 marathon), got $((relay_n + test_n))"
src_repo=$(find "$ROOT/src" -name '*.js' | wc -l | tr -d ' ')
src_van=$(find "$REPO/.xyz/src" -name '*.js' 2>/dev/null | wc -l | tr -d ' ')
[ "$src_van" = "$src_repo" ] && [ "$src_van" -gt 0 ] && pass "all $src_van src/*.js vendored" || fail "src/*.js mismatch: vendored $src_van vs harness $src_repo"
[ -x "$REPO/.xyz/bin/tick" ] && pass "bin/tick vendored + executable" || fail "bin/tick missing or not executable"
[ -x "$REPO/.xyz/bin/validate-relay-block" ] && pass "bin/validate-relay-block vendored + executable" || fail "bin/validate-relay-block missing or not executable"
# GH-49b: the marathon runtime is vendored too (so the copy can run marathons, not just relays).
mcount=0
for mf in marathon-drive.sh marathon.sh marathon-agent.sh claude-turn.sh; do
  [ -f "$REPO/.xyz/relay-automation/$mf" ] && bash -n "$REPO/.xyz/relay-automation/$mf" 2>/dev/null && mcount=$((mcount+1))
done
[ "$mcount" = 4 ] && pass "GH-49b: marathon runtime vendored + parses (4 files)" || fail "marathon runtime incomplete ($mcount/4)"
vfields=$(grep -cE '^(source_commit|tick_version|vendored_utc)=' "$REPO/.xyz/VERSION" 2>/dev/null)
[ "$vfields" = 3 ] && pass "VERSION has all 3 fields" || fail "VERSION malformed ($vfields/3 fields)"
grep -Fqx '.xyz/' "$REPO/.gitignore" && pass ".xyz/ gitignored" || fail ".xyz/ not in .gitignore"
[ "$(grep -vc '^#' "$XYZ_REGISTRY")" = 1 ] && pass "registry has 1 vendored row" || fail "registry row count wrong"

# --- idempotent re-run ---
"$VENDOR" "$REPO" >/dev/null 2>&1
gi=$(grep -c '^\.xyz/$' "$REPO/.gitignore")
rr=$(grep -vc '^#' "$XYZ_REGISTRY")
[ "$gi" = 1 ] && [ "$rr" = 1 ] && pass "idempotent re-run (1 gitignore line, 1 registry row)" || fail "not idempotent (gitignore=$gi rows=$rr)"

# --- --no-register ---
mkdir -p "$WORK/foreign2"; git init -q "$WORK/foreign2"; REPO2="$(cd "$WORK/foreign2" && pwd -P)"
XYZ_REGISTRY="$WORK/reg2.tsv" "$VENDOR" --no-register "$REPO2" >/dev/null 2>&1
[ -f "$WORK/reg2.tsv" ] && fail "--no-register wrote a registry" || pass "--no-register writes no registry"

# --- find-harness.sh: default (no .xyz) path byte-identical to a baseline copy ---
# Baseline = the same script run where CWD has no .xyz. Compare --root/--env from a neutral non-.xyz
# git repo: resolution must be the live harness (script-relative), identical whether or not .xyz logic exists.
NOXYZ="$WORK/plain"; mkdir -p "$NOXYZ"; git init -q "$NOXYZ"
( cd "$NOXYZ" && "$FH" --env >"$WORK/plain.env" 2>"$WORK/plain.enverr" )
# --env uses printf %q (paths with spaces get escaped), so eval rather than grep the raw line.
( unset HARNESS; eval "$(cat "$WORK/plain.env")"; [ "$HARNESS" = "$ROOT" ] ) \
  && pass "no-.xyz: resolves to the live harness (default path intact)" || fail "no-.xyz default resolution changed"
[ ! -s "$WORK/plain.enverr" ] && pass "no-.xyz: no stderr banner" || fail "no-.xyz emitted stderr: $(cat "$WORK/plain.enverr")"

# --- find-harness.sh: prefers .xyz/ when standing in the vendored repo ---
got="$( cd "$REPO" && "$FH" --root 2>/dev/null )"
[ "$got" = "$REPO/.xyz" ] && pass ".xyz/ preferred when present" || fail "expected $REPO/.xyz, got $got"
# env override still wins
got="$( cd "$REPO" && XYZ_HARNESS="$ROOT" "$FH" --root 2>/dev/null )"
[ "$got" = "$ROOT" ] && pass "XYZ_HARNESS still wins over a present .xyz/" || fail "env override lost to .xyz/ (got $got)"

# --- staleness: current = silent, behind = stderr banner + exit 0 + clean stdout ---
HEAD="$(git -C "$ROOT" rev-parse HEAD)"
ANCESTOR="$(git -C "$ROOT" rev-list --max-parents=0 HEAD | tail -1)"
printf 'source_commit=%s\ntick_version=x\nvendored_utc=x\n' "$HEAD" > "$REPO/.xyz/VERSION"
( cd "$REPO" && "$FH" --root 2>"$WORK/cur.err" >/dev/null )
[ ! -s "$WORK/cur.err" ] && pass "staleness: current copy is silent" || fail "current copy warned: $(cat "$WORK/cur.err")"
printf 'source_commit=%s\ntick_version=x\nvendored_utc=x\n' "$ANCESTOR" > "$REPO/.xyz/VERSION"
( cd "$REPO" && "$FH" --env 2>"$WORK/beh.err" >"$WORK/beh.out" ); rc=$?
[ "$rc" = 0 ] && pass "staleness: behind copy still exits 0 (never blocks)" || fail "behind copy exited $rc"
grep -qi 'behind' "$WORK/beh.err" && pass "staleness: behind copy warns on stderr" || fail "no behind-banner on stderr"
if grep -q '^export HARNESS=' "$WORK/beh.out" && ! grep -qvE '^export ' "$WORK/beh.out"; then
  pass "staleness: --env stdout stays pure export lines"
else
  fail "banner leaked into --env stdout"
fi

# --- xyz-sync list/update/delete ---
"$SYNC" list 2>/dev/null | grep -q "$REPO/.xyz" && pass "xyz-sync list shows the vendored copy" || fail "xyz-sync list missed the copy"
echo "source_commit=deadbeef" > "$REPO/.xyz/VERSION"
"$SYNC" update "$REPO" >/dev/null 2>&1
grep -q "^source_commit=$HEAD$" "$REPO/.xyz/VERSION" && pass "xyz-sync update restamps VERSION to live HEAD" || fail "xyz-sync update didn't restamp"
"$SYNC" delete "$REPO" >/dev/null 2>&1
[ -d "$REPO/.xyz" ] && pass "xyz-sync delete dry-runs by default (.xyz survives)" || fail "delete removed .xyz without --yes"
"$SYNC" delete "$REPO" --yes >/dev/null 2>&1
[ ! -d "$REPO/.xyz" ] && [ -d "$REPO" ] && pass "xyz-sync delete --yes removes .xyz/ but keeps the repo" || fail "delete --yes wrong effect"
[ "$(grep -c "$REPO/.xyz" "$XYZ_REGISTRY" 2>/dev/null)" = 0 ] && pass "xyz-sync delete --yes drops the registry row" || fail "registry row survived delete"

# --- reminder hook: fires when a copy exists, silent when none ---
"$VENDOR" "$REPO" >/dev/null 2>&1   # re-vendor so a copy exists
out="$(printf '{}' | "$HOOK" 2>/dev/null)"
printf '%s' "$out" | grep -q "$REPO/.xyz" && pass "reminder hook lists an existing vendored copy" || fail "reminder hook silent when a copy exists"
out="$(printf '{}' | XYZ_NO_VENDOR_REMINDER=1 "$HOOK" 2>/dev/null)"
[ -z "$out" ] && pass "reminder hook honors XYZ_NO_VENDOR_REMINDER" || fail "reminder hook ignored opt-out"
"$SYNC" delete "$REPO" --yes >/dev/null 2>&1
out="$(printf '{}' | "$HOOK" 2>/dev/null)"
[ -z "$out" ] && pass "reminder hook silent when no copy on disk" || fail "reminder hook nagged with no copy"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
