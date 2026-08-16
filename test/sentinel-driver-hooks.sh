#!/usr/bin/env bash
# test/sentinel-driver-hooks.sh — GH-281 §1.7 acceptance for the marathon-drive.sh Tier-1 hooks.
#   #1 default-off: the append helper writes nothing when XYZ_DEBUG_LOG is unset or 0.
#   #2 on-mode:     each append emits exactly one valid JSONL finding with the right severity/check/
#                   phase/task, escaping adversarial (quote/backslash/control-byte) input.
#   wiring:         all six §1.3 hooks are present at their call sites in marathon-drive.sh.
#   #4 (mirror block byte-identity) is covered separately by test/lane-attempt-cap.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVE="$HERE/../relay-automation/marathon-drive.sh"
[[ -f "$DRIVE" ]] || { echo "FAIL: driver not found: $DRIVE" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-driver.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Extract the two helper functions and source them into a controlled shell (avoids running the
# driver's main body). The functions reference ROOT/TARGET_ROOT/PHASE_ID/RELAY_TASK/DEBUG_LOG_FILE.
sed -n '/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p' "$DRIVE" > "$WORK/helpers.sh"
grep -q 'xyz_debug_log_append' "$WORK/helpers.sh" || { echo "FAIL: could not extract helpers" >&2; exit 1; }

ROOT="$WORK"; TARGET_ROOT=""; PHASE_ID="p1"; RELAY_TASK="TASK-1"
LOG="$WORK/debug.log"; DEBUG_LOG_FILE="$LOG"
# shellcheck disable=SC1090
source "$WORK/helpers.sh"

# --- #1 default-off: unset / 0 flag → nothing written -------------------------
unset XYZ_DEBUG_LOG 2>/dev/null || true
xyz_debug_log_append error marathon.escalation "should not be written"
[[ ! -e "$LOG" ]] || { echo "FAIL: default-off (unset) wrote to debug.log" >&2; exit 1; }
XYZ_DEBUG_LOG=0 xyz_debug_log_append error marathon.escalation "still off"
[[ ! -e "$LOG" ]] || { echo "FAIL: XYZ_DEBUG_LOG=0 wrote to debug.log" >&2; exit 1; }

# --- #2 on-mode: exactly one valid JSONL line, adversarial input escaped -------
export XYZ_DEBUG_LOG=1
xyz_debug_log_append error "marathon.escalation" "$(printf 'no-progress\t"x" \\y')" "phases/p1/RELAY.md" "promote"
[[ "$(wc -l < "$LOG" | tr -d ' ')" -eq 1 ]] || { echo "FAIL: expected exactly 1 line" >&2; exit 1; }
python3 - "$LOG" <<'PY'
import json, sys, re
row = json.loads(open(sys.argv[1]).readline())
assert row["severity"] == "error" and row["check"] == "marathon.escalation", row
assert row["file"] == "phases/p1/RELAY.md" and row["action"] == "promote", row
assert row["phase"] == "p1" and row["task"] == "TASK-1", row
for v in row.values():                                   # no raw control byte survived
    assert not re.search(r"[\x00-\x1f\x7f]", v), repr(v)
assert '"x"' in row["message"] and "\\y" in row["message"], row["message"]  # quote/backslash intact
PY

# --- wiring: all six §1.3 hooks present ---------------------------------------
need=(
  ': "${XYZ_DEBUG_LOG:=0}"'                            # (0) opt-in default
  'xyz_debug_log_append() {'                           # (1) append helper
  'xyz_debug_log_append error "marathon.escalation"'   # (2) escalation hook
  'marathon.lane-park'                                 # (3) lane-park hook
  'marathon.stale-lock'                                # (4) stale-lock hook
  'SIDE FINDINGS:'                                     # (5) side-finding prompt
  'harvest-findings.sh'                                # (6) harvest hook
)
for pat in "${need[@]}"; do
  grep -qF "$pat" "$DRIVE" || { echo "FAIL: missing hook wiring: $pat" >&2; exit 1; }
done

echo "PASS: sentinel driver hooks (default-off + on-mode append + 6-hook wiring)"
