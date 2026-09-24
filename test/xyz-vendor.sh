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
FH="$ROOT/skills/1-hourly/relay-xyz/find-harness.sh"
HOOK="$ROOT/relay-automation/hooks/xyz-vendor-reminder.sh"

for f in "$VENDOR" "$SYNC" "$FH" "$HOOK"; do
  [ -f "$f" ] && bash -n "$f" 2>/dev/null && pass "parses: ${f#$ROOT/}" || fail "missing/parse-fail: ${f#$ROOT/}"
done

# Isolated registry + a scratch "foreign repo".
export XYZ_REGISTRY="$WORK/registry.tsv"
# Canonicalize via `cd && pwd` (macOS /var -> /private/var) so paths match what xyz-vendor +
# find-harness store/resolve — otherwise the symlinked mktemp dir breaks string compares.
mkdir -p "$WORK/foreign"; git init -q "$WORK/foreign"; REPO="$(cd "$WORK/foreign" && pwd -P)"
# GH-742: a consumer can be an ESM package. The vendored harness remains CommonJS regardless of
# the target's package boundary.
printf '{\n  "type": "module"\n}\n' > "$REPO/package.json"

# --- vendor materializes a complete .xyz/ ---
"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "vendor exited non-zero"
grep -Fqx '  "type": "commonjs"' "$REPO/.xyz/package.json" \
  && pass "GH-742: vendor writes a CommonJS package boundary" \
  || fail "GH-742: .xyz/package.json missing type=commonjs"
grep -Fqx '  "type": "module"' "$REPO/package.json" \
  && pass "GH-742: target ESM package.json remains untouched" \
  || fail "GH-742: vendor changed the target package.json"
TICK_REPO_ROOT="$REPO" "$REPO/.xyz/bin/tick" --help >/dev/null 2>&1 \
  && pass "GH-742: vendored tick runs inside an ESM target" \
  || fail "GH-742: vendored tick inherited the target's ESM mode"
mv "$REPO/.xyz/package.json" "$WORK/vendored-package.json"
if TICK_REPO_ROOT="$REPO" "$REPO/.xyz/bin/tick" --help >/dev/null 2>&1; then
  fail "GH-742 control: tick still ran without the vendored CommonJS boundary"
else
  pass "GH-742 control: removing .xyz/package.json reproduces the ESM failure"
fi
mv "$WORK/vendored-package.json" "$REPO/.xyz/package.json"
# The vendor mirrors whole dirs VERBATIM (VENDOR_DIRS="relay-automation bin src test skills"), so
# assert the vendored copy MATCHES the harness — like the src/*.js check below — not a magic count.
# The old `== 20` was for the curated relay-pkg manifest; the full-mirror change (5972ef4) ships every
# harness script, so a fixed number is wrong. Count *.sh so transient fixture/data files can't flake it.
relay_repo=$(find "$ROOT/relay-automation" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
relay_van=$(find "$REPO/.xyz/relay-automation" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
test_repo=$(find "$ROOT/test" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
test_van=$(find "$REPO/.xyz/test" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
# Under GH-197 Tier 1 excludes xyz-releases-onboard.sh from relay-automation/
expected_relay_sh=$((relay_repo - 1))
{ [ "$relay_van" = "$expected_relay_sh" ] && [ "$test_van" = "$test_repo" ] && [ "$relay_van" -gt 0 ]; } \
  && pass "full mirror matches harness ($relay_van relay-automation + $test_van test *.sh, excluding 1 overlay script)" \
  || fail "vendor mirror incomplete: relay-automation $relay_van/$expected_relay_sh, test $test_van/$test_repo"
src_repo=$(find "$ROOT/src" -name '*.js' | wc -l | tr -d ' ')
src_van=$(find "$REPO/.xyz/src" -name '*.js' 2>/dev/null | wc -l | tr -d ' ')
[ "$src_van" = "$src_repo" ] && [ "$src_van" -gt 0 ] && pass "all $src_van src/*.js vendored" || fail "src/*.js mismatch: vendored $src_van vs harness $src_repo"
utils_repo=$(find "$ROOT/utils" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
utils_van=$(find "$REPO/.xyz/utils" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
# Under GH-197 Tier 1 excludes the 2 overlay scripts (releases-merge-resolve.sh, release-lanes.sh)
expected_utils_sh=$((utils_repo - 2))
{ [ "$utils_van" = "$expected_utils_sh" ] && [ "$utils_van" -gt 0 ]; } \
  && pass "Tier 1 utils/*.sh vendored ($utils_van *.sh, excluding 2 overlay scripts)" \
  || fail "utils/ vendor incomplete: vendored $utils_van vs expected $expected_utils_sh (repo total $utils_repo)"
[ -f "$REPO/.xyz/utils/swarm-preflight.sh" ] && bash -n "$REPO/.xyz/utils/swarm-preflight.sh" 2>/dev/null \
  && pass "vendored swarm-preflight.sh parses" || fail "vendored swarm-preflight.sh missing or parse-fail"
[ -f "$REPO/.xyz/utils/marathon-plan.sh" ] && bash -n "$REPO/.xyz/utils/marathon-plan.sh" 2>/dev/null \
  && pass "vendored marathon-plan.sh parses" || fail "vendored marathon-plan.sh missing or parse-fail"
[ -f "$REPO/.xyz/utils/py/rtl.py" ] && pass "utils/py/rtl.py vendored in Tier 1" || fail "utils/py/rtl.py missing in Tier 1"
[ -f "$REPO/.xyz/utils/py/marathon_plan.py" ] && pass "utils/py/marathon_plan.py vendored in Tier 1" || fail "utils/py/marathon_plan.py missing in Tier 1"
[ ! -e "$REPO/.xyz/relay-automation/xyz-releases-onboard.sh" ] && pass "Tier 1: xyz-releases-onboard.sh excluded" || fail "Tier 1: xyz-releases-onboard.sh unexpectedly present"
[ ! -e "$REPO/.xyz/utils/py/releases_app.py" ] && pass "Tier 1: releases_app.py excluded" || fail "Tier 1: releases_app.py unexpectedly present"
[ ! -e "$REPO/.xyz/utils/py/releases_cycle.py" ] && pass "Tier 1: releases_cycle.py excluded" || fail "Tier 1: releases_cycle.py unexpectedly present"
[ ! -e "$REPO/.xyz/utils/releases-merge-resolve.sh" ] && pass "Tier 1: releases-merge-resolve.sh excluded" || fail "Tier 1: releases-merge-resolve.sh unexpectedly present"
[ ! -e "$REPO/.xyz/utils/release-lanes.sh" ] && pass "Tier 1: release-lanes.sh excluded" || fail "Tier 1: release-lanes.sh unexpectedly present"
[ ! -e "$REPO/.xyz/utils/timeline" ] && pass "Tier 1: utils/timeline excluded" || fail "Tier 1: utils/timeline unexpectedly present"
[ ! -e "$REPO/.xyz/RELEASES-DB-FAQS.md" ] && pass "Tier 1: RELEASES-DB-FAQS.md excluded" || fail "Tier 1: RELEASES-DB-FAQS.md unexpectedly present"
grep -Fqx 'tier=1' "$REPO/.xyz/VERSION" && pass "Tier 1: stamped tier=1 in VERSION" || fail "Tier 1: missing or wrong tier in VERSION"
[ -x "$REPO/.xyz/bin/tick" ] && pass "bin/tick vendored + executable" || fail "bin/tick missing or not executable"
[ -x "$REPO/.xyz/bin/validate-relay-block" ] && pass "bin/validate-relay-block vendored + executable" || fail "bin/validate-relay-block missing or not executable"
# GH-49b: the marathon runtime is vendored too (so the copy can run marathons, not just relays).
mcount=0
for mf in marathon-drive.sh marathon.sh marathon-agent.sh claude-turn.sh; do
  [ -f "$REPO/.xyz/relay-automation/$mf" ] && bash -n "$REPO/.xyz/relay-automation/$mf" 2>/dev/null && mcount=$((mcount+1))
done
[ "$mcount" = 4 ] && pass "GH-49b: marathon runtime vendored + parses (4 files)" || fail "marathon runtime incomplete ($mcount/4)"
vfields=$(grep -cE '^(source_commit|tick_version|vendored_utc|tier)=' "$REPO/.xyz/VERSION" 2>/dev/null)
[ "$vfields" = 4 ] && pass "VERSION has all 4 fields (incl. tier)" || fail "VERSION malformed ($vfields/4 fields)"
grep -Fqx '.xyz/' "$REPO/.git/info/exclude" && pass ".xyz/ excluded (GH-642: repo-local exclude)" || fail ".xyz/ not in info/exclude"
grep -Fqx '/.tick/' "$REPO/.git/info/exclude" && pass "/.tick/ excluded (GH-440/GH-642)" || fail "/.tick/ not in info/exclude"
! grep -Fqx '.xyz/' "$REPO/.gitignore" 2>/dev/null && pass "target .gitignore untouched by vendor (GH-642)" || fail "vendor modified the target .gitignore"
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
  out="$( "$VENDOR" --no-register "$BR" 2>&1 )"; rc=$?
  [ "$rc" = 0 ] \
    && pass "GH-226: VENDORS into a repo ignoring '$rule' (exit 0, marathon check deferred to runtime)" \
    || fail "GH-226: failed to vendor into a repo ignoring '$rule' (exit $rc)"
  grep -Fq "$rule" <<<"$(printf '%s' "$out")" \
    && pass "  and names the rule in the way" \
    || fail "  but did not name '$rule' in its warning"
  grep -Fq "WARNING" <<<"$(printf '%s' "$out")" \
    && pass "  and emitted the advisory warning banner" \
    || fail "  but did not emit WARNING banner"
  # Vendoring must preserve the original rule and add .xyz/ and /.tick/ to .gitignore, never un-ignore.
  grep -Fqx "$rule" "$BR/.gitignore" \
    && pass "  and preserved original ignore rule '$rule'" \
    || fail "  but original rule '$rule' was lost from .gitignore"
  grep -Fqx '.xyz/' "$BR/.git/info/exclude" \
    && pass "  and added .xyz/ to the repo-local exclude (GH-642)" \
    || fail "  but .xyz/ was not added to info/exclude"
  grep -Fqx '/.tick/' "$BR/.git/info/exclude" \
    && pass "  and added /.tick/ to the repo-local exclude (GH-642)" \
    || fail "  but /.tick/ was not added to info/exclude"
  ! grep -q '^!' "$BR/.gitignore" 2>/dev/null \
    && pass "  and left ignored paths un-negated (never un-ignores for you)" \
    || fail "  but wrote a negation rule to un-ignore '$rule'"
  [ -d "$BR/.xyz" ] \
    && pass "  and successfully materialized .xyz/" \
    || fail "  but failed to materialize .xyz/"
done

# GH-644: the append must not fuse onto a last line that has no trailing newline. The fixture
# above always writes `\n`, which is the one shape where the fusion cannot happen — a check that
# could not fail (AGENTS.md §6). Write the exclude WITHOUT a trailing newline and assert the
# original rule survives as its own exact line and `.xyz/` lands as its own exact line.
NL="$(mkignore_repo '/relay-system')"
printf '%s' '*.cact' > "$NL/.git/info/exclude"      # no trailing newline, hand-edited shape
"$VENDOR" --no-register "$NL" >/dev/null 2>&1 \
  && pass "GH-644: vendors into a repo whose info/exclude lacks a trailing newline" \
  || fail "GH-644: vendor failed on a no-trailing-newline info/exclude"
grep -Fqx '*.cact' "$NL/.git/info/exclude" \
  && pass "  and the last rule '*.cact' survived as its own line (no fusion)" \
  || fail "  but the last rule was fused: $(tail -n 3 "$NL/.git/info/exclude" | tr '\n' '|')"
! grep -q 'cact\.xyz/' "$NL/.git/info/exclude" \
  && pass "  and no '*.cact.xyz/' fused line exists" \
  || fail "  but a fused '*.cact.xyz/' line exists"
[ "$(grep -Fcx '.xyz/' "$NL/.git/info/exclude")" = 1 ] \
  && pass "  and .xyz/ was appended exactly once as its own line" \
  || fail "  but .xyz/ count is $(grep -Fcx '.xyz/' "$NL/.git/info/exclude")"

# GH-644 part B: a target that DELIBERATELY tracks .xyz/ (turnkey consumer, GH-642) must not get
# the whole directory re-ignored on every run. An ignore rule never untracks indexed files, so the
# harm is quieter than the issue first claimed: NEW harness files from a re-vendor are silently
# not staged (the tracked copy drifts) and the operator fights a reappearing rule. Ignore only the
# runtime-state subpaths there — the half of the #314 invariant that is actually about runtime
# state — and leave harness code trackable. Every other target keeps the blanket `.xyz/` rule.
mktracked_repo() {  # prints a fresh repo that has COMMITTED a stub .xyz/bin/tick
  local d
  d="$(mktemp -d "$WORK/tracked.XXXXXX")"
  git init -q "$d"
  mkdir -p "$d/.xyz/bin"; printf 'stub\n' > "$d/.xyz/bin/tick"; printf 'x\n' > "$d/README"
  ( cd "$d" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm vendored >/dev/null 2>&1 )
  ( cd "$d" && pwd -P )
}
TR="$(mktracked_repo)"
cp "$TR/.git/info/exclude" "$WORK/tracked.exclude.before" 2>/dev/null || : > "$WORK/tracked.exclude.before"
"$VENDOR" --no-register "$TR" >/dev/null 2>&1 \
  && pass "GH-644B: vendors into a repo that already tracks .xyz/" \
  || fail "GH-644B: vendor failed on a repo that tracks .xyz/"
"$VENDOR" --no-register "$TR" >/dev/null 2>&1 || fail "GH-644B: second vendor run failed"
! grep -Fqx '.xyz/' "$TR/.git/info/exclude" \
  && pass "  and did NOT add the blanket .xyz/ rule to the exclude (harness code stays trackable)" \
  || fail "  but re-asserted the blanket .xyz/ rule on a repo that tracks .xyz/"
[ ! -e "$TR/.gitignore" ] \
  && pass "  and left .gitignore untouched" \
  || fail "  but wrote a .gitignore: $(cat "$TR/.gitignore" | tr '\n' '|')"
_b_ok=1
for _rp in relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json; do
  n="$(grep -Fcx ".xyz/$_rp" "$TR/.git/info/exclude")"
  [ "$n" = 1 ] || { _b_ok=0; fail "  runtime path .xyz/$_rp appears $n times in the exclude (want exactly 1)"; }
done
[ "$_b_ok" = 1 ] && pass "  and every runtime subpath is ignored exactly once (idempotent across two runs)"
[ "$(grep -Fcx '/.tick/' "$TR/.git/info/exclude")" = 1 ] \
  && pass "  and /.tick/ at the target root is still ignored exactly once" \
  || fail "  but /.tick/ count is $(grep -Fcx '/.tick/' "$TR/.git/info/exclude")"
# Observable consequence: new harness code stages, runtime state never does, tracked code stays.
printf 'new\n' > "$TR/.xyz/bin/new-harness-file"
mkdir -p "$TR/.xyz/relay-system" "$TR/.xyz/.tick" "$TR/.xyz/XYZ.json.lock"
for _s in relay-system/s.md .tick/s.log XYZ.json.lock/s; do printf 'x\n' > "$TR/.xyz/$_s"; done
for _s in .relay-driver.lock XYZ.json XYZ.heartbeat.json; do printf 'x\n' > "$TR/.xyz/$_s"; done
( cd "$TR" && git add -A >/dev/null 2>&1 )
staged="$(git -C "$TR" diff --cached --name-only)"
git -C "$TR" ls-files --error-unmatch -- .xyz/bin/tick >/dev/null 2>&1 \
  && pass "  and the previously committed .xyz/bin/tick is still tracked" \
  || fail "  but .xyz/bin/tick fell out of the index"
grep -Fqx '.xyz/bin/new-harness-file' <<<"$staged" \
  && pass "  and a NEW harness file under .xyz/ stages on git add -A" \
  || fail "  but the new harness file did not stage (blanket ignore still in effect)"
! grep -q '^\.xyz/\(relay-system\|\.tick\|\.relay-driver\.lock\|XYZ\.json\|XYZ\.heartbeat\.json\)' <<<"$staged" \
  && pass "  and no runtime-state sentinel staged" \
  || fail "  but runtime state staged: $(grep '^\.xyz/' <<<"$staged" | tr '\n' '|')"

# Guard 1: an operator-owned blanket `.xyz/` line already in the exclude is NEVER removed (the
# append has always been additive-only) — it is reported, with the remediation, and left alone.
TR2="$(mktracked_repo)"
printf '.xyz/\n' > "$TR2/.git/info/exclude"
out="$( "$VENDOR" --no-register "$TR2" 2>&1 )"; rc=$?
[ "$rc" = 0 ] && pass "GH-644B: vendors (exit 0) when a tracked-.xyz/ repo already carries a blanket .xyz/ rule" \
  || fail "GH-644B: exit $rc on a tracked-.xyz/ repo with a pre-existing blanket rule"
grep -Fqx '.xyz/' "$TR2/.git/info/exclude" \
  && pass "  and left the operator's blanket .xyz/ line in place (never deletes an ignore rule)" \
  || fail "  but removed the operator's .xyz/ line"
grep -Fq 'WARNING' <<<"$out" && grep -Fq '.xyz/' <<<"$out" \
  && pass "  and WARNED that the blanket rule will hide new harness files" \
  || fail "  but emitted no WARNING about the blanket rule: $(printf '%s' "$out" | tail -n 3 | tr '\n' '|')"

# Guard 2: tracked RUNTIME content (someone committed .xyz/.tick/) passes the tracked-.xyz/ probe
# but is not evidence the harness was deliberately vendored — warn, naming the path, and still
# apply the subpath ignores.
TR3="$(mktracked_repo)"
mkdir -p "$TR3/.xyz/.tick"; printf 'x\n' > "$TR3/.xyz/.tick/events.log"
( cd "$TR3" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm tick >/dev/null 2>&1 )
out="$( "$VENDOR" --no-register "$TR3" 2>&1 )"
grep -Fq 'WARNING' <<<"$out" && grep -Fq '.xyz/.tick' <<<"$out" \
  && pass "GH-644B: WARNS when tracked .xyz/ content intersects the runtime paths (names .xyz/.tick)" \
  || fail "GH-644B: no WARNING naming tracked runtime content .xyz/.tick"
grep -Fqx '.xyz/.tick' "$TR3/.git/info/exclude" \
  && pass "  and still wrote the runtime subpath ignores" \
  || fail "  but skipped the runtime subpath ignores"

# NEGATIVE CONTROL for part B: a repo that does NOT track .xyz/ still gets the blanket rule, so the
# subpath branch cannot silently become the default.
NT="$(mkignore_repo 'node_modules/')"
"$VENDOR" --no-register "$NT" >/dev/null 2>&1 || true
grep -Fqx '.xyz/' "$NT/.git/info/exclude" && ! grep -Fqx '.xyz/relay-system' "$NT/.git/info/exclude" \
  && pass "  control: a non-tracking repo still gets the blanket .xyz/ rule and no subpath rules" \
  || fail "  control: non-tracking repo lost the blanket .xyz/ rule or gained subpath rules"

# It must NOT auto-un-ignore: doing so would publish builder/reviewer transcripts the repo chose to
# withhold, irreversibly on a public target. This assertion is what stops a future "helpful" fix.
BR="$(mkignore_repo '/relay-system')"
"$VENDOR" --no-register "$BR" >/dev/null 2>&1 || true
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
gi=$(grep -c '^\.xyz/$' "$REPO/.git/info/exclude")
rr=$(grep -vc '^#' "$XYZ_REGISTRY")
[ "$gi" = 1 ] && [ "$rr" = 1 ] && pass "idempotent re-run (1 exclude line, 1 registry row)" || fail "not idempotent (exclude=$gi rows=$rr)"

# --- --no-register ---
mkdir -p "$WORK/foreign2"; git init -q "$WORK/foreign2"; REPO2="$(cd "$WORK/foreign2" && pwd -P)"
XYZ_REGISTRY="$WORK/reg2.tsv" "$VENDOR" --no-register "$REPO2" >/dev/null 2>&1
[ -f "$WORK/reg2.tsv" ] && fail "--no-register wrote a registry" || pass "--no-register writes no registry"

# --- find-harness.sh: default (no .xyz) path byte-identical to a baseline copy ---
# Baseline = the same script run where CWD has no .xyz. Compare --root/--env from a neutral non-.xyz
# git repo: resolution must be the live harness (script-relative), identical whether or not .xyz logic exists.
NOXYZ="$WORK/plain"; mkdir -p "$NOXYZ"; git init -q "$NOXYZ"
( cd "$NOXYZ" && "$FH" --quiet --env >"$WORK/plain.env" 2>"$WORK/plain.enverr" )
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
( cd "$REPO" && "$FH" --quiet --root 2>"$WORK/cur.err" >/dev/null )
[ ! -s "$WORK/cur.err" ] && pass "staleness: current copy is silent" || fail "current copy warned: $(cat "$WORK/cur.err")"
# The BEHIND state needs a commit that is an ancestor of HEAD and is not HEAD itself —
# find-harness.sh decides it with `merge-base --is-ancestor` (skills/1-hourly/relay-xyz/find-harness.sh:164).
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
