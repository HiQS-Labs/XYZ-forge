#!/usr/bin/env bash
# #141 Phase 1 — ONE selector owns the synthetic suites.
#
# Before: validate.sh's TESTS registry gated the suites while fuzz-loop.sh re-derived its own
# membership with a private `find` over the same directory — two selectors that can silently
# disagree (a suite gated but never fuzzed, or the reverse). After: fuzz-loop consumes the
# authoritative registry (validate.sh --list, wrappers resolved), and this suite pins all three
# properties the phase's acceptance names:
#   (a) every test/synthetic/*.sh is registry-reachable (set equality, both directions)
#   (b) fuzz-loop's derived selection IS the registry's synthetic subset (no second opinion)
#   (c) the divergence detector fires: a suite dropped in place but NOT registered is caught —
#       pre-#141 the private find silently picked it up while the gate never ran it.
# Introspection goes through fuzz-loop.sh --print-selection — the REAL resolver, not a copy.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
FUZZ="$ROOT/utils/fuzzing/fuzz-loop.sh"
SYN="$ROOT/test/synthetic"

PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

[ -x "$FUZZ" ] || { echo "gh141: fuzz-loop.sh missing" >&2; exit 1; }
[ -d "$SYN" ] || { echo "gh141: test/synthetic missing" >&2; exit 1; }

sel="$(bash "$FUZZ" --print-selection)"
[ -n "$sel" ] || { echo "gh141: empty selection — registry consumption broken" >&2; exit 1; }

# (a)+(b): set equality between the directory and the registry-derived selection.
on_disk="$(ls "$SYN"/*.sh | LC_ALL=C sort)"
selected="$(printf '%s\n' "$sel" | LC_ALL=C sort)"
if [ "$on_disk" = "$selected" ]; then
  pass "every test/synthetic suite is registry-reachable, and the selection is exactly that set ($(printf '%s\n' "$sel" | wc -l | tr -d ' ') suites)"
else
  only_dir="$(comm -23 <(printf '%s\n' "$on_disk") <(printf '%s\n' "$selected") | tr '\n' ' ')"
  only_sel="$(comm -13 <(printf '%s\n' "$on_disk") <(printf '%s\n' "$selected") | tr '\n' ' ')"
  fail "selection != directory (unregistered on disk: ${only_dir:-none}; selected but missing: ${only_sel:-none})"
fi

# The registry itself must know the direct entries (spot-check one of the ten Phase-1 additions).
listed="$(bash "$ROOT/validate.sh" --list)"
case "$listed" in
  *"test/synthetic/gh102-telemetry-schema.sh"*) pass "registry carries the direct synthetic entries" ;;
  *) fail "registry lost a direct synthetic entry (gh102)" ;;
esac

# (c): the divergence detector. A probe suite dropped into the directory WITHOUT registration
# must break set equality — proving the directory and the registry cannot silently disagree
# again. (It must also NOT be selected: membership follows the registry, not the filesystem.)
PROBE="$SYN/zz-gh141-unregistered-probe.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$PROBE"
probe_detected=0
sel2="$(bash "$FUZZ" --print-selection)"
case "$sel2" in
  *zz-gh141-unregistered-probe*) fail "unregistered probe was SELECTED — selection follows the filesystem, not the registry" ;;
  *) pass "unregistered probe is not selected (membership follows the registry)" ;;
esac
if [ "$sel2" = "$sel" ]; then
  # selection unchanged is correct behavior; the DETECTOR is the set-equality check above, which
  # the probe must trip when re-evaluated. Verify it does.
  on_disk2="$(ls "$SYN"/*.sh | LC_ALL=C sort)"
  if [ "$on_disk2" = "$sel2" ]; then
    fail "probe present but set-equality detector did NOT trip — divergence would be silent again"
  else
    pass "probe trips the set-equality detector (a dropped-in unregistered suite is caught)"
    probe_detected=1
  fi
fi
rm -f "$PROBE"
[ "$probe_detected" -eq 1 ] || fail "detector verification skipped — investigate"

# Wrapper resolution: suites registered via root wrappers (GH-124/#145 forms) must be reachable.
case "$sel" in
  *gh124-closeout-suite.sh*) pass "wrapper-registered suites resolve to their synthetic targets (gh124)" ;;
  *) fail "gh124-closeout-suite.sh missing from selection — wrapper resolution broken" ;;
esac

# One direct entry really executes under the runner's own invocation shape (bash test/<entry>).
if (cd "$ROOT" && bash test/synthetic/synthetic-pi-model-unset.sh >/tmp/gh141-smoke.log 2>&1); then
  pass "a direct registry entry executes via 'bash test/<entry>' (synthetic-pi-model-unset)"
  rm -f /tmp/gh141-smoke.log
else
  fail "direct entry failed to execute: $(tail -2 /tmp/gh141-smoke.log 2>/dev/null)"
fi

echo "gh141-synthetic-registry: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
