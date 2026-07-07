#!/usr/bin/env bash
# utils/hq/hourly-global-scan.sh — scheduled wrapper for utils/hq/marathon-scan.sh (GH-158's follow-on).
#
# Runs the read-only cross-repo marathon scan and writes ONE fixed-name report,
# PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md — always overwritten in place, never date-stamped, so there is
# exactly one copy at any time (unlike utils/hq/marathon-scan.sh's own default HQ-MARATHON-<date>.md
# naming, which this wrapper always overrides via --out).
#
# Invoked hourly by the launchd agent installed via utils/hq/install-hourly-scan.sh — see that script
# for the plist. Can also be run by hand for an on-demand refresh.
#
# A simple mkdir-lock guards against two overlapping runs (a slow scan outliving the hour, or a manual
# run colliding with the scheduled one) — never two writers racing the same output file.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md"
LOCK="${TMPDIR:-/tmp}/hq-hourly-global-scan.lock"

if ! mkdir "$LOCK" 2>/dev/null; then
  # Self-heal a stale lock left by a killed/crashed prior run (same pattern as this repo's own
  # .git/relay-driver.lock) — never let one dead process wedge every future hourly tick.
  _holder="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
    printf 'hourly-global-scan: another run holds %s (pid %s) — skipping this tick\n' "$LOCK" "$_holder" >&2
    exit 0
  fi
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || { printf 'hourly-global-scan: could not acquire lock after reclaiming a stale one\n' >&2; exit 1; }
fi
printf '%s\n' "$$" >"$LOCK/pid"
trap 'rm -rf "$LOCK" 2>/dev/null || true' EXIT

cd "$ROOT" || exit 1
bash "$HERE/marathon-scan.sh" --out "$OUT"
