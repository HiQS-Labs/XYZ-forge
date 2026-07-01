#!/usr/bin/env bash
set -euo pipefail
#
# find-harness.sh — GH-70 Phase 2: the concurrency-readiness warning in `find-harness.sh --check`.
# A foreign repo with no local .xyz/ resolves to the CENTRALIZED harness (shared global driver lock),
# so --check must WARN (fail-open, exit 0) and point at xyz-vendor.sh. A vendored repo (its own .xyz/)
# or the harness clone itself must NOT warn.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "find-harness (GH-70 Phase 2):"
[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }

# --- Case 1: from the harness clone itself → resolves to self, NO concurrency warning, exit 0 ---
out1="$( cd "$REPO" && bash "$FH" --check 2>&1 )"; rc1=$?
ok "harness clone: --check exits 0"                 "[ '$rc1' -eq 0 ]"
ok "harness clone: no concurrency warning"          "! printf '%s' \"\$out1\" | grep -qi concurrency"

# --- Case 2: from a FOREIGN repo with NO .xyz/ → warns + vendor command, still exit 0 (fail-open) ---
FR="$(mktemp -d "${TMPDIR:-/tmp}/fh-foreign.XXXXXX")"; git -C "$FR" init -q
out2="$( cd "$FR" && bash "$FH" --check 2>&1 )"; rc2=$?
ok "foreign no-.xyz: --check still exits 0 (fail-open)"  "[ '$rc2' -eq 0 ]"
ok "foreign no-.xyz: emits the concurrency warning"      "printf '%s' \"\$out2\" | grep -qi 'concurrency'"
ok "foreign no-.xyz: points at xyz-vendor.sh"            "printf '%s' \"\$out2\" | grep -q 'xyz-vendor.sh vendor'"
rm -rf "$FR"

# --- Case 3: foreign repo WITH a local .xyz/ harness → resolves to it, NO concurrency warning ---
FV="$(mktemp -d "${TMPDIR:-/tmp}/fh-vendored.XXXXXX")"; git -C "$FV" init -q
mkdir -p "$FV/.xyz/relay-automation" "$FV/.xyz/bin"
printf '#!/usr/bin/env bash\n:\n' > "$FV/.xyz/relay-automation/relay-drive.sh"; chmod +x "$FV/.xyz/relay-automation/relay-drive.sh"
printf '#!/usr/bin/env bash\n:\n' > "$FV/.xyz/bin/tick"; chmod +x "$FV/.xyz/bin/tick"
out3="$( cd "$FV" && bash "$FH" --check 2>&1 )"; rc3=$?
ok "vendored .xyz: --check exits 0"                 "[ '$rc3' -eq 0 ]"
ok "vendored .xyz: no concurrency warning"          "! printf '%s' \"\$out3\" | grep -qi concurrency"
ok "vendored .xyz: resolves to the local .xyz"      "printf '%s' \"\$out3\" | grep -q '.xyz'"
rm -rf "$FV"

echo "  find-harness: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
