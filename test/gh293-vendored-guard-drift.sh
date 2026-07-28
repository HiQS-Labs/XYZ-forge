#!/usr/bin/env bash
# GH-293 — a vendored copy may carry a safety-critical behavioral guard even when its registry
# provenance is unknown, and fleet update must never fan out from a dirty/non-canonical source
# unless the operator explicitly opts in.
source "$(dirname "$0")/_setup.sh" gh293-vendored-guard-drift

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
SYNC="$ROOT/relay-automation/xyz-sync.sh"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"

make_update_harness() {
  HARNESS="$WORK/update-harness"
  mkdir -p "$HARNESS/relay-automation" "$HARNESS/src"
  cp "$SYNC" "$HARNESS/relay-automation/xyz-sync.sh"
  cat > "$HARNESS/relay-automation/xyz-vendor.sh" <<'VENDOR'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$XYZ_VENDOR_LOG"
VENDOR
  chmod +x "$HARNESS/relay-automation/xyz-sync.sh" "$HARNESS/relay-automation/xyz-vendor.sh"
  printf "export const SCHEMA_VERSION = 'test';\n" > "$HARNESS/src/events.js"
  printf 'tracked\n' > "$HARNESS/README.md"
  git init -q "$HARNESS"
  git -C "$HARNESS" config user.email test@xyz
  git -C "$HARNESS" config user.name test
  git -C "$HARNESS" add .
  git -C "$HARNESS" commit -q -m seed
  git -C "$HARNESS" branch -M main
}

make_update_target() {
  local name="$1"
  local repo="$WORK/$name"
  mkdir -p "$repo/.xyz"
  git init -q "$repo"
  printf '%s\n' "$(cd -P "$repo" && pwd)"
}

make_update_harness
UPDATE_SYNC="$HARNESS/relay-automation/xyz-sync.sh"
export XYZ_VENDOR_LOG="$WORK/vendor.log"
export XYZ_REGISTRY="$WORK/update-registry.tsv"
REPO1="$(make_update_target update-repo1)"
REPO2="$(make_update_target update-repo2)"
printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' > "$XYZ_REGISTRY"
printf '%s\ttest\ttest\ttest\t%s\n' "$REPO1/.xyz" "$REPO1" >> "$XYZ_REGISTRY"
printf '%s\ttest\ttest\ttest\t%s\n' "$REPO2/.xyz" "$REPO2" >> "$XYZ_REGISTRY"

# A clean canonical source may update every selected target.
: > "$XYZ_VENDOR_LOG"
"$UPDATE_SYNC" update --all >/dev/null 2>&1 || fail "clean canonical source should permit update --all"
[ "$(wc -l < "$XYZ_VENDOR_LOG" | tr -d ' ')" = 2 ] \
  && pass "clean canonical source updates all selected vendored repos" \
  || fail "clean canonical source did not invoke both vendor updates"

# A dirty source stops before the first target; the documented override is intentionally explicit.
printf 'dirty\n' >> "$HARNESS/README.md"
: > "$XYZ_VENDOR_LOG"
out="$("$UPDATE_SYNC" update --all 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass "dirty source refuses update --all" || fail "dirty source unexpectedly updated --all"
printf '%s\n' "$out" | grep -Fq 'harness source is dirty' \
  && pass "dirty-source refusal names the safety reason" || fail "dirty-source refusal was opaque: $out"
printf '%s\n' "$out" | grep -Fq 'XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1' \
  && pass "dirty-source refusal documents the explicit override" || fail "dirty-source override missing: $out"
[ ! -s "$XYZ_VENDOR_LOG" ] && pass "dirty source blocks before any fleet target is touched" \
  || fail "dirty source reached a target before refusing"
XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 "$UPDATE_SYNC" update --all >/dev/null 2>&1 \
  && pass "dirty source permits the explicit override" || fail "dirty-source override did not permit update"

git -C "$HARNESS" checkout -q -- README.md
git -C "$HARNESS" checkout -q -b feature
: > "$XYZ_VENDOR_LOG"
out="$("$UPDATE_SYNC" update --all 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass "non-canonical branch refuses update --all" || fail "non-canonical branch unexpectedly updated --all"
printf '%s\n' "$out" | grep -Fq 'is not canonical' \
  && pass "branch refusal names the safety reason" || fail "branch refusal was opaque: $out"
[ ! -s "$XYZ_VENDOR_LOG" ] && pass "non-canonical branch blocks before any fleet target is touched" \
  || fail "non-canonical branch reached a target before refusing"
XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 "$UPDATE_SYNC" update --all >/dev/null 2>&1 \
  && pass "non-canonical branch permits the explicit override" || fail "branch override did not permit update"

# `check` reads the vendored copy, not only source_commit. Simulate a pre-GH-245 copy whose
# provenance is unknown and whose target-root containment refusal is absent.
export XYZ_REGISTRY="$WORK/check-registry.tsv"
mkdir -p "$WORK/check-repo"; git init -q "$WORK/check-repo"
CHECK_REPO="$(cd -P "$WORK/check-repo" && pwd)"
"$VENDOR" "$CHECK_REPO" >/dev/null 2>&1 || fail "setup vendor for guard-manifest check exited non-zero"
# Derive the marker from xyz-sync.sh's own manifest rather than restating it here (agy review of
# PR #318, [Should]). A duplicated literal is the same fragility the manifest was criticised for:
# change the manifest and this fixture keeps stripping a line that no longer means anything, so the
# test passes while the guard check is dead. Reading the array is the only way the two cannot drift.
guard_pat="$(sed -n '/^SAFETY_GUARD_PATTERNS=(/,/^)/p' "$SYNC" \
  | sed -n "s/^[[:space:]]*'\(.*\)'[[:space:]]*\$/\1/p" | head -1)"
[ -n "$guard_pat" ] && pass "guard marker extracted from xyz-sync.sh's manifest ($guard_pat)" \
  || fail "could not read SAFETY_GUARD_PATTERNS out of $SYNC"
tmp="$WORK/relay-drive-without-guard.sh"
grep -Fv -- "$guard_pat" "$CHECK_REPO/.xyz/relay-automation/relay-drive.sh" > "$tmp"
cmp -s "$tmp" "$CHECK_REPO/.xyz/relay-automation/relay-drive.sh" \
  && fail "fixture stripped nothing — marker '$guard_pat' does not appear in the vendored relay-drive.sh" \
  || pass "fixture removed the guard line the manifest looks for"
mv "$tmp" "$CHECK_REPO/.xyz/relay-automation/relay-drive.sh"
tmp="$WORK/check-registry.tmp"
awk -F'\t' 'BEGIN { OFS="\t" } /^#/ { print; next } { $4="unknown"; print }' "$XYZ_REGISTRY" > "$tmp"
mv "$tmp" "$XYZ_REGISTRY"

out="$("$SYNC" check "$CHECK_REPO" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "check remains report-only when a safety guard is missing" \
  || fail "check returned $rc for missing safety guard"
printf '%s\n' "$out" | grep -Fq "SAFETY GUARD MISSING $CHECK_REPO/.xyz (relay-target-root-containment)" \
  && pass "check distinguishes the missing GH-245 safety guard from ordinary drift" \
  || fail "missing guard was not identified: $out"
printf '%s\n' "$out" | grep -Fq 'source_commit=unknown does not establish guard coverage' \
  && pass "guard inspection remains meaningful when source_commit is unknown" \
  || fail "unknown source_commit handling was not explicit: $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
