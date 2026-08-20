#!/usr/bin/env bash
set -euo pipefail
#
# gh536-evidence-detail.sh — GH-536: the gate-evidence record must let a reader tell
# "the suite ran and passed" from "someone stamped green".
#
# Before this, the record was six lines whose only claim about the run was `result: green` — a bare
# assertion about output that no longer exists by the time anyone reads it. Two additions fix that:
# an `output-sha256` over the suite transcript, and the per-suite verdicts.
#
# WHAT THIS DELIBERATELY DOES NOT DO, and the suite asserts it: raise the trust level. GH-536 argued
# that an automated pipeline which hashes its own results is "a meaningfully different trust level"
# and the NOT-promotion-evidence disclaimer could soften. It cannot. A hash computed on your own
# machine over output you produced proves diligence, not provenance — someone can stub a suite and
# hash the doctored result just as easily. The hash makes the record TAMPER-EVIDENT (edit the
# transcript later and it stops matching); it does not make it ATTESTED. Those are different
# properties and only the second is what promotion turns on, which is why the disclaimer is pinned
# below rather than merely left alone.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
GR="$REPO/utils/gate-record.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh536-evidence-detail =="

# Fixtures live OUTSIDE the repo under test on purpose: gate-record refuses on a dirty tree, so a
# transcript written inside it would trip the refusal instead of exercising the record.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh536.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root

mkrepo() {
  _r="$(mktemp -d "$WORK/repo.XXXXXX")"
  require_fixture "$_r" "record fixture"  # GH-10
  git -C "$_r" init -q
  git -C "$_r" config user.email t@t
  git -C "$_r" config user.name t
  printf 'x\n' > "$_r/a.txt"
  git -C "$_r" add a.txt
  git -C "$_r" commit -qm seed
  printf '%s' "$_r"
}

LOGS="$(mktemp -d "$WORK/gh536-logs.XXXXXX")"
require_fixture "$LOGS" "log fixture"  # GH-10
printf '=== foo.sh ===\n  PASS: something\n' > "$LOGS/suite.log"
printf 'foo.sh\tpass\nbar.sh\tpass\nbaz.sh\tskip\n' > "$LOGS/verdicts.txt"
EXPECT="$(shasum -a 256 "$LOGS/suite.log" | awk '{print $1}')"

# --- (1) the enriched record ------------------------------------------------------------------
R="$(mkrepo)"
bash "$GR" --repo "$R" --suite-log "$LOGS/suite.log" --verdicts "$LOGS/verdicts.txt" >/dev/null 2>&1
REC="$(ls "$R"/.gate-evidence/*.txt 2>/dev/null | head -1)"

ok "a record was written" "[ -n '$REC' ] && [ -f '$REC' ]"
ok "carries output-sha256 of the transcript" "grep -q 'output-sha256: $EXPECT' '$REC'"
ok "carries the transcript byte count" "grep -qE '^output-bytes: [0-9]+' '$REC'"
ok "carries a per-suite verdict section" "grep -q 'per-suite verdicts' '$REC'"
ok "names an individual suite verdict" "grep -qE '^foo\.sh[[:space:]]+pass' '$REC'"
ok "distinguishes skipped suites from passing ones" "grep -qE '^baz\.sh[[:space:]]+skip' '$REC'"
ok "counts the suites recorded" "grep -q 'suites: 3 recorded' '$REC'"

# THE PIN. #536 proposed this change as grounds to treat local evidence as more trustworthy.
# It is not, and a future edit that quietly drops the disclaimer should fail here.
ok "STILL declares itself NOT promotion evidence" "grep -q 'NOT-promotion-evidence' '$REC'"
ok "STILL says self-reported" "grep -q 'self-reported' '$REC'"

# --- (2) tamper-evidence is the actual property gained ----------------------------------------
printf 'TAMPERED\n' >> "$LOGS/suite.log"
NEW="$(shasum -a 256 "$LOGS/suite.log" | awk '{print $1}')"
ok "editing the transcript changes the hash (record is tamper-EVIDENT)" "[ '$NEW' != '$EXPECT' ]"
ok "the already-written record still holds the ORIGINAL hash" "grep -q '$EXPECT' '$REC'"
rm -rf "$R"

# --- (3) degrade honestly when a caller passes nothing -----------------------------------------
# A missing line would read as an older record format. Saying "unavailable" cannot be mistaken for
# a record that had the transcript.
R2="$(mkrepo)"
bash "$GR" --repo "$R2" >/dev/null 2>&1
REC2="$(ls "$R2"/.gate-evidence/*.txt 2>/dev/null | head -1)"
ok "no-flags call still records (backward compatible)" "[ -f '$REC2' ]"
ok "states the transcript was unavailable rather than omitting the field" \
   "grep -q 'output-sha256: unavailable' '$REC2'"
ok "states the verdicts were not recorded" "grep -q 'suites: not recorded' '$REC2'"
rm -rf "$R2"

# --- (4) the refusal that carries the whole integrity story is unchanged -----------------------
R3="$(mkrepo)"
printf 'uncommitted\n' > "$R3/dirty.txt"
set +e
bash "$GR" --repo "$R3" --suite-log "$LOGS/suite.log" --verdicts "$LOGS/verdicts.txt" >/dev/null 2>&1
rc=$?
set -e
ok "still REFUSES on a dirty tree even with a transcript in hand (exit 3)" "[ '$rc' -eq 3 ]"
ok "and writes no record when it refuses" \
   "[ -z \"\$(ls '$R3'/.gate-evidence/*.txt 2>/dev/null || true)\" ]"
rm -rf "$R3"

# --- (5) ci-local actually passes them through --------------------------------------------------
ok "ci-local.sh passes --suite-log to gate-record" \
   "grep -q 'gate-record.sh --suite-log' '$REPO/ci-local.sh'"
ok "ci-local.sh captures per-suite verdicts" "grep -q 'GATE_VERDICTS' '$REPO/ci-local.sh'"
ok "ci-local.sh reads PIPESTATUS so tee cannot mask a failing suite" \
   "grep -q 'PIPESTATUS\[0\]' '$REPO/ci-local.sh'"

rm -rf "$LOGS"
echo "  gh536-evidence-detail: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
