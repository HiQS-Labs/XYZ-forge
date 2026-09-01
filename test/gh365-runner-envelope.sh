#!/usr/bin/env bash
# gh365-runner-envelope.sh — GH-365 step 1: the ONE shared scratch/identity envelope.
#
# The correctness blocker this closes: ci-local.sh (the qualifying runner, the only one that
# writes the gate record) ran the registered suites with NO harness-registry scratch, so a green
# run dirtied the tracked harnesses.db and gate-record.sh then refused to retain the record for
# exactly the run that needed it. Both runners now source test/lib/runner-envelope.sh.
#
# What this suite witnesses:
#   A. the helper's contract — scratch respected/created, clean assert passes, and the RED
#      controls: an intentional identity/tree/worktree/lock mutation under the envelope is
#      detected and classified (identity=hard fail, envelope drift=invalid evidence);
#      pre-existing dirt is tolerated (recorded, not forbidden).
#   B. the wiring — validate.sh and ci-local.sh share the ONE helper, neither carries a second
#      inline envelope, and ci-local no longer swallows a refused gate record.
#   C. the fail-closed edge — a validate.sh without the lib refuses rather than improvising.
#   D. the receipt teeth — a dirty tree still cannot retain a gate record (gate-record exit 3),
#      which is why envelope drift failing the bracket is the honest reading.
source "$(dirname "$0")/_setup.sh" gh365-runner-envelope
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
LIB="$REPO/test/lib/runner-envelope.sh"

mkclone() {  # -> prints a fixture clone path with a committed tracked file + harnesses.db
  local r
  r="$WORK/clone.$(date +%s).$RANDOM"
  mkdir -p "$r"
  require_fixture "$r" "envelope fixture clone"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  printf 'seed\n' > "$r/tracked.md"
  printf 'db\n' > "$r/harnesses.db"
  printf 'dump\n' > "$r/harnesses.sql"
  git -C "$r" add -A
  git -C "$r" commit -qm seed
  printf '%s' "$r"
}

echo "== test: gh365-runner-envelope =="

# ── A. the helper contract ───────────────────────────────────────────────────────────────────────
. "$LIB"

R="$(mkclone)"
runner_envelope_begin "$R" "suite" || fail "A1: begin failed on a healthy clone"
case "${XYZ_HARNESS_DB:-}" in
  */runner-envelope.*/harnesses.db) pass "A1: begin points XYZ_HARNESS_DB at scratch (${XYZ_HARNESS_DB##*/tmp/})" ;;
  *) fail "A1: XYZ_HARNESS_DB not at scratch (got '${XYZ_HARNESS_DB:-unset}')" ;;
esac
[ -f "$XYZ_HARNESS_DB" ] || fail "A1: scratch db copy missing"
[ "$(cat "$XYZ_HARNESS_DB")" = "db" ] || fail "A1: scratch db is not a copy of the tracked one"

# a write through the envelope lands in scratch, never in the tracked file
printf 'mutated-via-envelope\n' > "$XYZ_HARNESS_DB"
[ "$(git -C "$R" status --porcelain | wc -l | tr -d ' ')" = "0" ] \
  && pass "A2: an envelope-routed write leaves the tracked tree byte-clean" \
  || fail "A2: envelope write dirtied the tracked tree: $(git -C "$R" status --porcelain | head -3)"

# clean assert under an untouched envelope
runner_envelope_assert "$R" "suite" && pass "A3: untouched envelope asserts clean (rc 0)" \
  || fail "A3: clean envelope asserted dirty (rc $?)"

# ── A4-A7. the witnessed RED controls ────────────────────────────────────────────────────────────
rebegin() { runner_envelope_scrub; runner_envelope_begin "$R" "red" || fail "rebegin failed"; }

# A4: tracked-tree drift (untracked file appearing is drift too — porcelain lists it)
rebegin
: > "$R/untracked-scratch.txt"
runner_envelope_assert "$R" "red"; rc=$?
[ "$rc" -eq 2 ] && pass "A4: new untracked file -> envelope drift (rc 2), record invalid" \
  || fail "A4: expected rc 2 on tree drift, got $rc"
rm -f "$R/untracked-scratch.txt"

# A5: tracked-file modification
rebegin
printf 'mutated\n' >> "$R/tracked.md"
runner_envelope_assert "$R" "red"; rc=$?
[ "$rc" -eq 2 ] && pass "A5: tracked-file mutation -> envelope drift (rc 2)" \
  || fail "A5: expected rc 2 on tracked mutation, got $rc"
git -C "$R" restore tracked.md 2>/dev/null || git -C "$R" checkout -q -- tracked.md

# A6: IDENTITY mutation — the hard GH-1 failure, on the existing machinery
rebegin
git -C "$R" config user.email mutated@t
runner_envelope_assert "$R" "red"; rc=$?
[ "$rc" -eq 1 ] && pass "A6: identity mutation -> hard failure (rc 1), run unattributable" \
  || fail "A6: expected rc 1 on identity drift, got $rc"
git -C "$R" config user.email t@t

# A7: worktree registration drift
rebegin
git -C "$R" worktree add -q "$WORK/wt-drift" -b wt-drift >/dev/null 2>&1
runner_envelope_assert "$R" "red"; rc=$?
[ "$rc" -eq 2 ] && pass "A7: registered-worktree drift detected (rc 2)" \
  || fail "A7: expected rc 2 on worktree drift, got $rc"
git -C "$R" worktree remove --force "$WORK/wt-drift" 2>/dev/null || true

# A8: driver-lock drift (a lock left held at the end of a run is a leak — GH-42/GH-528)
rebegin
_gd="$(git -C "$R" rev-parse --absolute-git-dir)"
printf 'pid 99999 stale\n' > "$_gd/relay-driver.lock"
runner_envelope_assert "$R" "red"; rc=$?
[ "$rc" -eq 2 ] && pass "A8: driver-lock appearance detected (rc 2)" \
  || fail "A8: expected rc 2 on lock drift, got $rc"
rm -f "$_gd/relay-driver.lock"

# A9: PRE-EXISTING dirt is tolerated — recorded at begin, unchanged at assert
rebegin
printf 'pre-existing\n' >> "$R/tracked.md"
runner_envelope_scrub
runner_envelope_begin "$R" "pre-dirt" || fail "A9: begin failed with pre-existing dirt"
runner_envelope_assert "$R" "pre-dirt" && pass "A9: pre-existing dirt with no further change asserts clean" \
  || fail "A9: pre-existing dirt alone must not read as drift (rc $?)"
git -C "$R" restore tracked.md

# A10: a pre-set XYZ_HARNESS_DB (operator's or hermetic suite's) is respected and wins
runner_envelope_scrub
export XYZ_HARNESS_DB="$WORK/preset-harnesses.db"
printf 'preset\n' > "$XYZ_HARNESS_DB"
runner_envelope_begin "$R" "preset"
[ "$XYZ_HARNESS_DB" = "$WORK/preset-harnesses.db" ] \
  && pass "A10: pre-set XYZ_HARNESS_DB respected (no scratch override)" \
  || fail "A10: begin overrode a pre-set XYZ_HARNESS_DB ($XYZ_HARNESS_DB)"
runner_envelope_scrub
unset XYZ_HARNESS_DB

# A11: scrub removes both scratch dirs and refuses nothing
runner_envelope_begin "$R" "scrub" >/dev/null
_s="$RUNNER_ENVELOPE_SCRATCH"; _t="$RUNNER_ENVELOPE_STATE"
runner_envelope_scrub
[ ! -d "$_s" ] && [ ! -d "$_t" ] && pass "A11: scrub removed scratch and state dirs" \
  || fail "A11: scrub left a dir behind ($_s / $_t)"

# ── B. the wiring — ONE implementation, no second copy, no swallowed refusals ────────────────────
grep -q 'test/lib/runner-envelope.sh' "$REPO/validate.sh" \
  && pass "B1: validate.sh sources the shared envelope helper" \
  || fail "B1: validate.sh does not source test/lib/runner-envelope.sh"
grep -q 'test/lib/runner-envelope.sh' "$REPO/ci-local.sh" \
  && pass "B2: ci-local.sh sources the shared envelope helper" \
  || fail "B2: ci-local.sh does not source test/lib/runner-envelope.sh"
# the OLD inline spellings must be gone from both runners (a second implementation is the
# exact drift this step exists to remove)
grep -q 'validate-harness.XXXXXX' "$REPO/validate.sh" \
  && fail "B3: validate.sh still carries the old inline harness-scratch envelope" \
  || pass "B3: validate.sh's inline envelope is gone (helper owns it)"
grep -q 'ci-local-identity.XXXXXX' "$REPO/ci-local.sh" \
  && fail "B3b: ci-local.sh still carries its private identity snapshot" \
  || pass "B3b: ci-local.sh's private identity snapshot is gone (helper owns it)"
# ci-local must source the helper BEFORE validate_suite runs (order in the file)
_lin="$(grep -n 'runner-envelope.sh' "$REPO/ci-local.sh" | head -1 | cut -d: -f1)"
_sui="$(grep -n 'RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite"' "$REPO/ci-local.sh" | head -1 | cut -d: -f1)"
[ -n "$_lin" ] && [ -n "$_sui" ] && [ "$_lin" -lt "$_sui" ] \
  && pass "B4: ci-local sources the helper before the suite step" \
  || fail "B4: helper source (line $_lin) not before validate_suite (line $_sui)"
# a refused gate record must now fail the qualifying run (the old `|| true` swallowed it)
grep -q 'gate-record.sh --suite-log' "$REPO/ci-local.sh" \
  && pass "B5: ci-local still passes --suite-log to gate-record (GH-536 pin)" \
  || fail "B5: ci-local lost the --suite-log handoff"
if grep -Eq 'gate-record\.sh.*\|\| true' "$REPO/ci-local.sh"; then
  fail "B6: ci-local still swallows gate-record refusals (|| true)"
else
  pass "B6: a refused gate record fails the qualifying run (no || true)"
fi
grep -q 'runner-envelope.sh' "$REPO/test/gh35-test-tiers.sh" \
  && pass "B7: gh35 fixtures copy the shared lib (tier-2 fixture runs need it)" \
  || fail "B7: gh35 mkfixture does not copy runner-envelope.sh"

# ── C. fail-closed edge: a validate.sh without the lib refuses, never improvises ─────────────────
# Same fixture shape as gh35-test-tiers' mkfixture (ci-route + gate_env + stubbed gates), with
# runner-envelope.sh deliberately NOT copied — the lib is load-bearing on every tier that runs
# suites. Tier 1 (no suites) must still pass; the tier-2 envelope path must refuse, naming it.
CB="$WORK/ci-fixture"
mkdir -p "$CB/test/lib" "$CB/utils/pdda" "$CB/utils/py" "$CB/utils/hq" "$CB/relay-automation" "$CB/githooks"
require_fixture "$CB" "fail-closed fixture"
git -C "$CB" init -q; git -C "$CB" config user.email t@t; git -C "$CB" config user.name t
cp "$REPO/validate.sh" "$CB/validate.sh"; chmod +x "$CB/validate.sh"
cp "$REPO/test/lib/clone-identity.sh" "$CB/test/lib/clone-identity.sh"
cp "$REPO/relay-automation/gate-env.sh" "$CB/relay-automation/gate-env.sh"
cp "$REPO/utils/ci-route.sh" "$CB/utils/ci-route.sh"; chmod +x "$CB/utils/ci-route.sh"
cp "$REPO/utils/py/gate_env.py" "$CB/utils/py/gate_env.py"
printf '#!/usr/bin/env bash\necho stub-pdda ran\nexit 0\n' > "$CB/utils/pdda/pdda.sh"; chmod +x "$CB/utils/pdda/pdda.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CB/utils/hq/hq.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CB/test/hq.sh"; chmod +x "$CB/test/hq.sh"
git -C "$CB" add -A >/dev/null 2>&1; git -C "$CB" commit -qm base >/dev/null 2>&1
out="$(cd "$CB" && bash validate.sh --tier 1 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q "stub-pdda ran" \
  && pass "C1 CONTROL: tier 1 (no suites) still runs green without the lib" \
  || fail "C1 CONTROL: tier 1 broke without the lib (rc=$rc): $(printf '%s' "$out" | tail -2)"
printf 'utils/hq/hq.sh\n' > "$CB/paths.txt"
out="$(cd "$CB" && bash validate.sh --paths-file "$CB/paths.txt" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "runner-envelope.sh is missing"; then
  pass "C2: envelope path without the lib REFUSES, naming it (exit $rc)"
else
  fail "C2: a validate.sh missing the lib must refuse the envelope path (rc=$rc): $(printf '%s' "$out" | tail -2)"
fi

# ── D. the receipt teeth: dirty tree cannot retain a record (why drift must fail the bracket) ────
out="$(bash "$REPO/utils/gate-record.sh" --suite-log /dev/null --verdicts /dev/null 2>&1)"; rc=$?
# From the REPO (a clean tree) this records; the refusal shape is exercised by gh509 against a
# fixture. What THIS suite pins is the ci-local side: the refusal is no longer swallowed (B6).
[ "$rc" -eq 0 ] && pass "D1 CONTROL: gate-record records from a clean tree (this clone)" \
  || { [ "$rc" -eq 3 ] && pass "D1: gate-record refuses a dirty tree (exit 3) — the teeth exist" \
       || fail "D1: unexpected gate-record rc=$rc: $out"; }

echo "== gh365-runner-envelope: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
