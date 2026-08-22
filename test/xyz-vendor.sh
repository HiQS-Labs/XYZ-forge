#!/usr/bin/env bash
# GH-49 — vendored local copy of the harness. Covers the whole surface:
#   xyz-vendor.sh (materialize + VERSION + gitignore + registry, idempotent, --no-register),
#   find-harness.sh .xyz/ preference + warn-continue staleness (default path byte-identical),
#   xyz-sync.sh list/update/delete, and the SessionStart reminder hook.
source "$(dirname "$0")/_setup.sh" xyz-vendor

# -P: physical/canonical, matching find-harness.sh's own `cd -P` self-resolution — a worktree
# under /tmp or /var (macOS symlinks to /private/...) would otherwise compare a logical ROOT
# against find-harness.sh's canonical HARNESS and false-fail the "default path intact" assertion.
ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
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
# The vendor mirrors whole dirs VERBATIM (VENDOR_DIRS="relay-automation bin src test skills"), so
# assert the vendored copy MATCHES the harness — like the src/*.js check below — not a magic count.
# The old `== 20` was for the curated relay-pkg manifest; the full-mirror change (5972ef4) ships every
# harness script, so a fixed number is wrong. Count *.sh so transient fixture/data files can't flake it.
relay_repo=$(find "$ROOT/relay-automation" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
relay_van=$(find "$REPO/.xyz/relay-automation" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
test_repo=$(find "$ROOT/test" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
test_van=$(find "$REPO/.xyz/test" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
{ [ "$relay_van" = "$relay_repo" ] && [ "$test_van" = "$test_repo" ] && [ "$relay_van" -gt 0 ]; } \
  && pass "full mirror matches harness ($relay_van relay-automation + $test_van test *.sh)" \
  || fail "vendor mirror incomplete: relay-automation $relay_van/$relay_repo, test $test_van/$test_repo"
src_repo=$(find "$ROOT/src" -name '*.js' | wc -l | tr -d ' ')
src_van=$(find "$REPO/.xyz/src" -name '*.js' 2>/dev/null | wc -l | tr -d ' ')
[ "$src_van" = "$src_repo" ] && [ "$src_van" -gt 0 ] && pass "all $src_van src/*.js vendored" || fail "src/*.js mismatch: vendored $src_van vs harness $src_repo"
utils_repo=$(find "$ROOT/utils" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
utils_van=$(find "$REPO/.xyz/utils" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
{ [ "$utils_van" = "$utils_repo" ] && [ "$utils_van" -gt 0 ]; } \
  && pass "utils/ vendored ($utils_van *.sh)" \
  || fail "utils/ vendor incomplete: vendored $utils_van vs harness $utils_repo"
[ -f "$REPO/.xyz/utils/swarm-preflight.sh" ] && bash -n "$REPO/.xyz/utils/swarm-preflight.sh" 2>/dev/null \
  && pass "vendored swarm-preflight.sh parses" || fail "vendored swarm-preflight.sh missing or parse-fail"
[ -f "$REPO/.xyz/utils/marathon-plan.sh" ] && bash -n "$REPO/.xyz/utils/marathon-plan.sh" 2>/dev/null \
  && pass "vendored marathon-plan.sh parses" || fail "vendored marathon-plan.sh missing or parse-fail"
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
grep -Fqx '/.tick/' "$REPO/.gitignore" && pass "/.tick/ gitignored (GH-440)" || fail "/.tick/ not in .gitignore"
[ "$(grep -vc '^#' "$XYZ_REGISTRY")" = 1 ] && pass "registry has 1 vendored row" || fail "registry row count wrong"

# --- GH-314/GH-440: BOTH directions of the one ignore invariant --------------------------------
# The seam is a single invariant with two halves, and treating them as two independent append paths
# is how it survived 51 days: GH-440 was "fixed" by adding a second `printf >> .gitignore`, which
# left GH-314's half — a pre-existing rule BLOCKING a path the harness must commit — entirely absent.
# Both halves are asserted here, in one place, so neither can ship without the other again.
mkignore_repo() {  # <ignore-line> -> prints a fresh repo whose .gitignore carries that rule
  local rule="$1" d
  d="$(mktemp -d "$WORK/blocked.XXXXXX")"
  git init -q "$d"
  printf '%s\n' "$rule" > "$d/.gitignore"
  ( cd "$d" && pwd -P )
}

for rule in '/relay-system' 'phases' '/phases/'; do
  BR="$(mkignore_repo "$rule")"
  before="$(cat "$BR/.gitignore")"
  out="$( "$VENDOR" "$BR" 2>&1 )"; rc=$?
  [ "$rc" = 6 ] \
    && pass "GH-314: REFUSES to vendor into a repo ignoring '$rule' (exit 6)" \
    || fail "GH-314: vendored into a repo ignoring '$rule' anyway (exit $rc)"
  grep -q "$rule" <<<"$(printf '%s' "$out")" \
    && pass "  and names the rule in the way" \
    || fail "  but did not name '$rule' in its refusal"
  # A refusal must leave the target EXACTLY as it was — no half-install, no edited .gitignore.
  # Refusing while having already mutated the repo is worse than either outcome alone.
  [ "$before" = "$(cat "$BR/.gitignore")" ] \
    && pass "  and left the target's .gitignore untouched" \
    || fail "  but edited the target's .gitignore while refusing"
  [ ! -d "$BR/.xyz" ] \
    && pass "  and left no half-installed .xyz/" \
    || fail "  but left .xyz/ behind after refusing"
done

# It must NOT auto-un-ignore: doing so would publish builder/reviewer transcripts the repo chose to
# withhold, irreversibly on a public target. This assertion is what stops a future "helpful" fix.
BR="$(mkignore_repo '/relay-system')"
"$VENDOR" "$BR" >/dev/null 2>&1 || true
! grep -q '^!' "$BR/.gitignore" 2>/dev/null \
  && pass "GH-314: never writes a negation rule to un-ignore for you" \
  || fail "GH-314: silently un-ignored a path the target deliberately excluded"

# NEGATIVE CONTROL — the pre-fix behavior, so this suite proves it detects the bug and not merely
# the fix. An append-only ensure_gitignore sails straight past a blocking rule.
BR="$(mkignore_repo '/relay-system')"
( cd "$BR" && printf 'x\n' > f && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm s >/dev/null 2>&1 )
git -C "$BR" check-ignore -q relay-system \
  && pass "  control: the fixture repo really does ignore relay-system" \
  || fail "  control: fixture is not actually blocking — the refusal assertions prove nothing"

# An unrelated ignore rule must NOT trip the refusal: over-refusing makes vendoring unusable.
# --no-register so this fixture does not add a row the registry-count assertions below would see.
OK_REPO="$(mkignore_repo 'node_modules/')"
"$VENDOR" "$OK_REPO" --no-register >/dev/null 2>&1 \
  && pass "an unrelated ignore rule does NOT block vendoring" \
  || fail "over-refused: an unrelated ignore rule blocked the vendor"

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
# The BEHIND state needs a commit that is an ancestor of HEAD and is not HEAD itself —
# find-harness.sh decides it with `merge-base --is-ancestor` (skills/relay-xyz/find-harness.sh:164).
# In a repository with a SINGLE commit the root commit IS HEAD, so that state is structurally
# unobservable rather than merely absent, and the assertions below would fail for a reason that says
# nothing about the code.
#
# That is not hypothetical: the public launch artifact has exactly one commit BY DESIGN (#563 —
# fresh history is what makes sanitization complete by construction), and this suite went red in it.
# Report the gap rather than failing on it: a suite that goes red on a newcomer's clone, for a
# condition their repository cannot express, teaches them to stop reading it — which is #460.
if [ "$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 0)" -lt 2 ]; then
  echo "  SKIP: staleness behind-state — repo has a single commit, so an ancestor that is not HEAD"
  echo "        cannot exist. Structurally unobservable here, not a passing assertion."
else
  printf 'source_commit=%s\ntick_version=x\nvendored_utc=x\n' "$ANCESTOR" > "$REPO/.xyz/VERSION"
  ( cd "$REPO" && "$FH" --env 2>"$WORK/beh.err" >"$WORK/beh.out" ); rc=$?
  [ "$rc" = 0 ] && pass "staleness: behind copy still exits 0 (never blocks)" || fail "behind copy exited $rc"
  grep -qi 'behind' "$WORK/beh.err" && pass "staleness: behind copy warns on stderr" || fail "no behind-banner on stderr"
  if grep -q '^export HARNESS=' "$WORK/beh.out" && ! grep -qvE '^export ' "$WORK/beh.out"; then
    pass "staleness: --env stdout stays pure export lines"
  else
    fail "banner leaked into --env stdout"
  fi
fi

# --- xyz-sync list/update/delete ---
grep -q "$REPO/.xyz" <<<"$("$SYNC" list 2>/dev/null)" && pass "xyz-sync list shows the vendored copy" || fail "xyz-sync list missed the copy"
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
grep -q "$REPO/.xyz" <<<"$(printf '%s' "$out")" && pass "reminder hook lists an existing vendored copy" || fail "reminder hook silent when a copy exists"
out="$(printf '{}' | XYZ_NO_VENDOR_REMINDER=1 "$HOOK" 2>/dev/null)"
[ -z "$out" ] && pass "reminder hook honors XYZ_NO_VENDOR_REMINDER" || fail "reminder hook ignored opt-out"
"$SYNC" delete "$REPO" --yes >/dev/null 2>&1
out="$(printf '{}' | "$HOOK" 2>/dev/null)"
[ -z "$out" ] && pass "reminder hook silent when no copy on disk" || fail "reminder hook nagged with no copy"

# --- collision safety: target repo with pre-existing src/, utils/, bin/ is untouched ---
# The vendor writes ONLY under .xyz/ — never into the target's own top-level dirs.
mkdir -p "$WORK/collide"; git init -q "$WORK/collide"
CREPO="$(cd "$WORK/collide" && pwd -P)"
mkdir -p "$CREPO/src" "$CREPO/utils" "$CREPO/bin"
printf 'app-source\n' > "$CREPO/src/app.js"
printf 'app-util\n'   > "$CREPO/utils/helper.sh"
printf 'app-bin\n'    > "$CREPO/bin/myapp"
"$VENDOR" "$CREPO" >/dev/null 2>&1 || fail "collision-repo vendor exited non-zero"
[ "$(cat "$CREPO/src/app.js")"     = "app-source" ] && pass "collision: target src/ untouched"   || fail "collision: target src/ was modified"
[ "$(cat "$CREPO/utils/helper.sh")" = "app-util"  ] && pass "collision: target utils/ untouched" || fail "collision: target utils/ was modified"
[ "$(cat "$CREPO/bin/myapp")"      = "app-bin"    ] && pass "collision: target bin/ untouched"   || fail "collision: target bin/ was modified"
[ -d "$CREPO/.xyz/relay-automation" ] && pass "collision: harness landed under .xyz/" || fail "collision: .xyz/relay-automation missing"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
