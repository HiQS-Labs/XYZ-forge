#!/usr/bin/env bash
# test/sentinel-network-guard.sh — coverage for the Tier-1 zero-network guard.
#   (a) WIRING: the guard, run with no args over its REAL default set (the bundled capture scripts),
#       exits 0 — so a future network primitive added to a real capture script fails the suite.
#   (b) Per-primitive bad fixtures: every promised primitive trips the guard (security-scan.sh style).
#   (c) Directory traversal: a bad bundle trips; a clean bundle passes with no stderr.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/../relay-automation/hooks/sentinel-network-guard.sh"

[[ -x "$GUARD" ]] || { echo "FAIL: not executable: $GUARD" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-network.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# --- (a) WIRING: real default set must be clean -------------------------------
# This is what actually enforces the invariant on the shipped capture scripts — not just fixtures.
if ! bash "$GUARD" >"$WORK/real.stdout" 2>"$WORK/real.stderr"; then
  echo "FAIL: guard tripped over the REAL bundled capture scripts — a network primitive leaked in" >&2
  cat "$WORK/real.stderr" >&2
  exit 1
fi
[[ ! -s "$WORK/real.stderr" ]] || { echo "FAIL: real-defaults scan should be silent" >&2; cat "$WORK/real.stderr" >&2; exit 1; }

# --- (b) Per-primitive bad fixtures -------------------------------------------
# One line per promised primitive; each must trip the guard on its own.
PRIMS=('curl example.invalid/x' 'wget example.invalid/x' 'nc example.invalid 80' 'gh issue list' 'cat </dev/tcp/host/80' 'echo http://example.invalid')
i=0
for line in "${PRIMS[@]}"; do
  i=$((i + 1))
  d="$WORK/prim-$i"; mkdir -p "$d"
  printf '#!/usr/bin/env bash\n%s\n' "$line" > "$d/capture.sh"
  rc=0; bash "$GUARD" "$d/capture.sh" >/dev/null 2>"$WORK/prim-$i.stderr" || rc=$?
  [[ "$rc" -ne 0 ]] || { echo "FAIL: primitive not caught: '$line'" >&2; exit 1; }
  grep -q "SENTINEL NETWORK:" "$WORK/prim-$i.stderr" || { echo "FAIL: no finding on stderr for: '$line'" >&2; exit 1; }
done

# --- (c) Directory traversal: bad trips, clean passes -------------------------
BAD_DIR="$WORK/bad-bundle"; CLEAN_DIR="$WORK/clean-bundle"
mkdir -p "$BAD_DIR" "$CLEAN_DIR"
printf '#!/usr/bin/env bash\ncurl example.invalid/debug\n' > "$BAD_DIR/capture.sh"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "local debug capture"\n' > "$CLEAN_DIR/capture.sh"

BAD_RC=0
bash "$GUARD" "$BAD_DIR" >"$WORK/bad.stdout" 2>"$WORK/bad.stderr" || BAD_RC=$?
[[ "$BAD_RC" -ne 0 ]] || { echo "FAIL: bad fixture should trip the guard" >&2; exit 1; }
grep -q "SENTINEL NETWORK:" "$WORK/bad.stderr" || { echo "FAIL: bad fixture should print findings to stderr" >&2; exit 1; }

bash "$GUARD" "$CLEAN_DIR" >"$WORK/clean.stdout" 2>"$WORK/clean.stderr" || {
  echo "FAIL: clean fixture should pass" >&2; cat "$WORK/clean.stderr" >&2; exit 1
}
[[ ! -s "$WORK/clean.stderr" ]] || { echo "FAIL: clean fixture should not print findings" >&2; cat "$WORK/clean.stderr" >&2; exit 1; }

echo "PASS: sentinel network guard (real-defaults wiring + $i primitives + dir traversal)"
