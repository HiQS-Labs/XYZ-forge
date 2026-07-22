#!/usr/bin/env bash
# test/sentinel-network-guard.sh — hermetic bad/clean fixture coverage for the network guard.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/../relay-automation/hooks/sentinel-network-guard.sh"

[[ -x "$GUARD" ]] || { echo "FAIL: not executable: $GUARD" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-network.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

BAD_DIR="$WORK/bad-bundle"
CLEAN_DIR="$WORK/clean-bundle"
mkdir -p "$BAD_DIR" "$CLEAN_DIR"

cat > "$BAD_DIR/capture.sh" <<'EOF'
#!/usr/bin/env bash
curl example.invalid/debug
EOF

cat > "$CLEAN_DIR/capture.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "local debug capture"
EOF

BAD_RC=0
bash "$GUARD" "$BAD_DIR" >"$WORK/bad.stdout" 2>"$WORK/bad.stderr" || BAD_RC=$?
[[ "$BAD_RC" -ne 0 ]] || { echo "FAIL: bad fixture should trip the guard" >&2; exit 1; }
grep -q "SENTINEL NETWORK:" "$WORK/bad.stderr" || {
  echo "FAIL: bad fixture should print findings to stderr" >&2
  exit 1
}

bash "$GUARD" "$CLEAN_DIR" >"$WORK/clean.stdout" 2>"$WORK/clean.stderr" || {
  echo "FAIL: clean fixture should pass" >&2
  cat "$WORK/clean.stderr" >&2
  exit 1
}
[[ ! -s "$WORK/clean.stderr" ]] || {
  echo "FAIL: clean fixture should not print findings" >&2
  cat "$WORK/clean.stderr" >&2
  exit 1
}

echo "PASS: sentinel network guard"
