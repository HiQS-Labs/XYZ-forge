#!/usr/bin/env bash
# GH-255 — the blocked-before-dispatch refusal must offer the remedy that FITS what is blocked.
#
# GH-514 made the refusal actionable. It offered two remedies: --target-root, and un-ignore. It
# never mentioned XYZ_ARCHIVE_ROOT, which GH-30 built for exactly the repo the refusal fires on —
# one that deliberately ignores relay-system/. Observed cost on a real consuming repo: the message
# steered three consecutive launch attempts into dead ends (--target-root produced relay-drive
# exit 2, whose own remedy is to drop --target-root), and the knob that would have worked was
# never surfaced by any failure. An LLM agent follows the error text literally, so a message that
# omits the right answer does not merely fail to help — it misdirects.
#
# The correction is NOT "always recommend XYZ_ARCHIVE_ROOT". It redirects the TRANSCRIPT write-set
# only; _phase_write_set (RELAY.md / ESCALATION.md) is untouched by it. Recommending it for a
# phase-file block would send the operator into a second failure — the same defect one level down.
# So both directions need pinning, and the second assertion is the one that keeps the fix honest.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  ok  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A repo that ignores BOTH kinds, so one fixture drives both branches and the only thing that
# varies between them is which write-set the check is handed.
git init -q "$WORK/repo"
printf 'relay-system/\nmarathon-system/\n' > "$WORK/repo/.gitignore"

run_case() {  # <transcripts-only:0|1>
  python3 - "$ROOT" "$WORK/repo" "$1" <<'PY'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
import marathon_drive as md
repo = sys.argv[2]
transcripts = [os.path.join(repo, "relay-system", "2026-01-01", "t.md")]
phases      = [os.path.join(repo, "marathon-system", "p1", "RELAY.md")]
paths = transcripts if sys.argv[3] == "1" else phases + transcripts
try:
    md.preflight_write_set_trackable(repo, paths, transcript_paths=transcripts)
except SystemExit:
    pass
PY
}

echo "-- case 1: ONLY transcripts blocked → XYZ_ARCHIVE_ROOT is the primary remedy"
out="$(run_case 1 2>&1)"
case "$out" in
  *XYZ_ARCHIVE_ROOT*) pass "the refusal names XYZ_ARCHIVE_ROOT" ;;
  *) fail "GH-255: transcripts-only block does not mention XYZ_ARCHIVE_ROOT — output was: $out" ;;
esac
case "$out" in
  *"export XYZ_ARCHIVE_ROOT="*) pass "it gives a runnable export line, not just the variable name" ;;
  *) fail "GH-255: the remedy names the knob but not how to set it" ;;
esac
# Ordering, not mere presence: a remedy buried under the one that fails is the original defect.
# Anchor on the EXPORT LINE, not the bare name: the phase-file branch also mentions
# XYZ_ARCHIVE_ROOT (to say it will not help), so matching the name alone is satisfied by the
# wrong branch and the assertion stops discriminating. The negative control proved that.
pre_archive="${out%%export XYZ_ARCHIVE_ROOT=*}"; pre_target="${out%%--target-root*}"
if [ "${#pre_archive}" -lt "${#pre_target}" ]; then
  pass "XYZ_ARCHIVE_ROOT is offered BEFORE --target-root"
else
  fail "GH-255: --target-root still leads for a transcripts-only block"
fi

echo "-- case 2: a PHASE file is blocked → XYZ_ARCHIVE_ROOT must NOT lead (it cannot fix this)"
out2="$(run_case 0 2>&1)"
case "$out2" in
  *"1. Run with --target-root"*) pass "--target-root stays the primary remedy" ;;
  *) fail "GH-255: phase-file block no longer leads with --target-root — output was: $out2" ;;
esac
# THE discriminating assertion. Offering the archive knob here is the fix overshooting into the
# same class of misdirection it was written to remove.
case "$out2" in
  *"XYZ_ARCHIVE_ROOT will NOT clear this"*) pass "it says plainly that XYZ_ARCHIVE_ROOT will not help here" ;;
  *) fail "GH-255: phase-file block does not warn that XYZ_ARCHIVE_ROOT is insufficient" ;;
esac

echo "-- case 3: the un-ignore remedy survives in both"
for o in "$out" "$out2"; do
  case "$o" in
    *"un-ignore the path"*) : ;;
    *) fail "GH-255: the un-ignore remedy was dropped"; break ;;
  esac
done
[ "$FAIL" -eq 0 ] && pass "un-ignore is still offered as the last resort"

echo "gh255-remedy-ordering: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
