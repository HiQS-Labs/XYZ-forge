#!/usr/bin/env bash
# GH-413 — a copied launch-artifact marker must never authorize recursive deletion.
set -euo pipefail
source test/_setup.sh "GH-413" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"
builder="$root/utils/build-launch-artifact.sh"

refuse() { # <destination> <expected diagnostic>
  local dest="$1" needle="$2" output
  if output="$(bash "$builder" "$dest" 2>&1)"; then
    fail "expected destination '$dest' to be refused"
  fi
  printf '%s\n' "$output" | grep -qF -- "$needle" \
    || fail "refusal for '$dest' did not name '$needle': $output"
}

# A non-git directory containing only the public marker used to pass the marker branch and reach
# `find ... -exec rm -rf`. It must now fail before the source-tree cleanliness check or any delete.
marker_only="$WORK/marker-only"
mkdir -p "$marker_only"
printf 'keep this payload\n' > "$marker_only/payload.txt"
printf 'copied marker is not authority\n' > "$marker_only/.xyz-launch-artifact"
require_fixture "$marker_only" "marker-only destination"
refuse "$marker_only" "is not empty and is not a git repository"
[ -f "$marker_only/payload.txt" ] || fail "marker-only refusal deleted payload.txt"
[ -f "$marker_only/.xyz-launch-artifact" ] || fail "marker-only refusal deleted the copied marker"
pass "marker-only non-git destination is refused before its contents can be cleared"

# A previous artifact is exactly one commit; more history is an explicit destructive choice.
history="$WORK/history"
mkdir -p "$history"
require_fixture "$history" "history destination"
git init -q -b main "$history"
git -C "$history" -c user.email=fixture@t -c user.name=fixture commit -q --allow-empty -m initial
printf 'must survive refusal\n' > "$history/history.txt"
git -C "$history" add history.txt
git -C "$history" -c user.email=fixture@t -c user.name=fixture commit -q -m second
refuse "$history" "refusing to discard history without --discard-history"
grep -q '^must survive refusal$' "$history/history.txt" \
  || fail "multi-commit refusal deleted history.txt"
pass "multi-commit destination requires --discard-history and remains intact when omitted"

# The explicit flag is the opt-in: it must reach the build, recreate fresh history, omit the legacy
# marker, and retain both launch decision records that the artifact documents cite.
if ! bash "$builder" "$history" --discard-history --no-commit >"$WORK/discard-history.out" 2>&1; then
  cat "$WORK/discard-history.out" >&2
  fail "--discard-history did not permit rebuilding the multi-commit destination"
fi
[ ! -e "$history/.xyz-launch-artifact" ] \
  || fail "rebuilt artifact still ships the legacy destruction marker"
for decision in \
  decisions/2026-08-10-marathon-gate-baseline-strategy.md \
  PROJECT/2-WORKING/GH-563-PUBLIC-LAUNCH.md
do
  [ -f "$history/$decision" ] || fail "rebuilt artifact lost cited decision record: $decision"
done
pass "explicit history discard rebuilds without a marker and retains both cited decision records"

grep -q '^# Red control' "$root/test/baselines/GH-413-negative-control.md" \
  || fail "GH-413 needs its recorded pre-fix marker-destruction control"
pass "recorded pre-fix control accompanies the executable destination guard"

echo "== GH-413 ALL PASSED =="
