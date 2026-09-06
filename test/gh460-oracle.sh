#!/usr/bin/env bash
# GH-460: fuzz oracle for relay-automation/resolve-model-alias.sh — structural contract enforcement.
#
# Usage: gh460-oracle.sh <model-name>        (first argument is the input; extras ignored;
#                                             absent input maps to the empty string)
#   Exit 0 = every invariant holds for the observed resolver outcome.
#   Exit 8 = setup/measurement failure (SETUP-FAIL / MEASURE-FAIL on stderr) — never treated
#            as a valid miss observation.
#   Exit 9 = contract violation (BADRC:<rc> / LEAK-STDOUT-ON-MISS / HIT-EMPTY-ON-MATCH on stderr).
#
# Contract (GH-460 plan O1-O4): byte-exact stdout capture (never command substitution — it
# strips newline-only leaks), whitespace-tolerant wc parse (macOS pads with leading spaces;
# internal whitespace/split digits are MEASURE-FAIL), resolver stderr passed through,
# MODEL_ALIASES_FILE unset so an inherited override cannot turn iterations into usage exits.
set -u
unset MODEL_ALIASES_FILE

RUNDIR="${GH460_RUN_DIR:-${TMPDIR:-/tmp}}"
t=$(mktemp "$RUNDIR/gh460-oracle.XXXXXX") || { echo "SETUP-FAIL" >&2; exit 8; }
trap 'rm -f "$t"' EXIT

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
in="${1:-}"
bash "$script_dir/../relay-automation/resolve-model-alias.sh" "$in" >"$t" 2>/dev/null
rc=$?
bytes=$(wc -c <"$t"); wc_rc=$?
if [ $wc_rc -ne 0 ] || [ -z "$bytes" ]; then echo "MEASURE-FAIL" >&2; exit 8; fi
bytes=$(printf '%s' "$bytes" | tr -d '[:space:]')
case $bytes in ''|*[!0-9]*) echo "MEASURE-FAIL" >&2; exit 8;; esac
case $rc in
  0|1|2) ;;
  *) echo "BADRC:$rc" >&2; exit 9;;
esac
[ $rc -eq 1 ] && [ "$bytes" -gt 0 ] && { echo "LEAK-STDOUT-ON-MISS" >&2; exit 9; }
[ $rc -eq 0 ] && [ "$bytes" -eq 0 ] && { echo "HIT-EMPTY-ON-MATCH" >&2; exit 9; }
exit 0
