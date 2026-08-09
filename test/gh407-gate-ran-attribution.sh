#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh407-gate-ran-attribution.sh. The pre-fix revision is replayed inside the fixture by patching the driver copy back to its old single-expression form (reason = pre-advance-failed whenever no timeout reason was recorded, with no gate: line in ESCALATION.md). Pre-fix result: a phase whose builder never produced work escalated as pre-advance-failed and the record carried no statement of whether the gate ran. Post-fix result: the same phase escalates as relay-failed-before-gate with gate: not-run, while a genuinely red gate still escalates as pre-advance-failed with gate: red. Both observed in one run."}
# GH-407: `pre-advance-failed` asserts that the gate RAN and found a defect in the change.
#
# Several unrelated failures reach the same relay exit 5 — a builder shim that failed to start, a
# builder that exhausted its turn cap, a reviewer turn discarded by containment — and all of them
# were reported with that label. Observed three times in one 10-lane marathon on 2026-08-02, wrong
# all three times; in one case the relay file read STATUS: Approved while the phase was escalated as
# though the gate had rejected the work.
#
# Why the mislabel costs real time: the reason is the operator's entry point into a failed run.
# `pre-advance-failed` sends them to read the diff and the test output. When the gate never ran there
# is no test output, and nothing in the escalation record said so — confirming it required checking
# whether any pytest output existed anywhere after the phase started.
#
# Pinned here:
#   (1) a relay failure that never reached the gate does NOT claim a gate verdict
#   (2) every escalation states whether the gate ran, on every reason
#   (3) a genuinely red gate still reports pre-advance-failed with gate: red  <- anti-overcorrection
#   (4) the reason for the no-gate case names no cause it cannot determine
#
# (3) is the assertion that protects against the cheap fix. Reserving `pre-advance-failed` is easy to
# over-apply: relabel every exit 5 and criteria 1, 2 and 4 all pass while real gate failures stop
# being reported as gate failures — the same defect pointing the other way.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" gh407-gate-ran-attribution
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"

ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh407@t
git -C "$ROOT" config user.name gh407
printf '.tick/\n' > "$ROOT/.gitignore"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"

# Stub relay-drive, exit 5 WITHOUT approving: this is the shape the issue describes — the relay
# failed (builder never produced work), so the driver never reaches its own gate.
RD_FAIL="$WORK/relay-drive-fail.sh"
cat > "$RD_FAIL" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
exit 5
STUB_EOF
chmod +x "$RD_FAIL"

# Stub relay-drive that DOES approve, so the driver runs its gate and the gate decides.
RD_OK="$WORK/relay-drive-ok.sh"
cat > "$RD_OK" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
rf=""
while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
exit 0
STUB_EOF
chmod +x "$RD_OK"

run_driver() {  # <relay-drive-stub> <extra-args…>
  local rd="$1"; shift
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$rd" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  bash "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder claude \
    "$@"
}
esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }

# ── (1)(2)(4) the relay failed before the gate ────────────────────────────────────────────
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
run_driver "$RD_FAIL" --phase-id no-gate > "$WORK/no-gate.log" 2>&1 && rc=0 || rc=$?
reason="$(esc_field no-gate reason)"
gate="$(esc_field no-gate gate)"

[ "$reason" != "pre-advance-failed" ] \
  && pass "a relay failure that never reached the gate does NOT claim pre-advance-failed (got: $reason)" \
  || fail "the gate never ran, yet the phase was reported as pre-advance-failed"

[ "$reason" = "relay-failed-before-gate" ] \
  && pass "the no-gate case reports relay-failed-before-gate — states what is known, names no cause it cannot determine" \
  || fail "expected relay-failed-before-gate, got '$reason'"

[ "$gate" = "not-run" ] \
  && pass "ESCALATION.md records gate: not-run — the one line that resolves the ambiguity" \
  || fail "expected 'gate: not-run' in the escalation record, got '$gate'"

# ── (3) anti-overcorrection: a real gate failure is still a gate failure ──────────────────
printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/validate.sh"
run_driver "$RD_OK" --phase-id red-gate > "$WORK/red-gate.log" 2>&1 && rc=0 || rc=$?
reason="$(esc_field red-gate reason)"
gate="$(esc_field red-gate gate)"

[ "$reason" = "pre-advance-failed" ] \
  && pass "a gate that RAN and failed is still pre-advance-failed — the fix does not relabel real failures" \
  || fail "a real gate failure was reported as '$reason' — GH-407 pointing the other way"

[ "$gate" = "red" ] \
  && pass "ESCALATION.md records gate: red, so the record distinguishes a verdict from a non-run" \
  || fail "expected 'gate: red', got '$gate'"

# ── the pre-fix replay (#419): the old single-expression form, inside the fixture ──────────
# Replayed against a COPY of the driver so the working tree is never mutated. The copy is patched
# back to the pre-fix behaviour and driven through the same no-gate case, which must produce the old
# wrong answer. If it does not, this whole file is asserting something that was never broken.
FIXH="$WORK/prefix-harness"
mkdir -p "$FIXH"
for d in relay-automation utils bin src; do
  [ -e "$ROOT_REPO/$d" ] && cp -R "$ROOT_REPO/$d" "$FIXH/$d"
done
PRE_MD="$FIXH/utils/py/marathon_drive.py"
python3 - "$PRE_MD" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]); s = p.read_text()

# revert the escalation record: drop the gate: line
before = s
s = s.replace("reason: {reason}\ngate: {run_gate_result[0]}\n", "reason: {reason}\n", 1)
assert s != before, "could not revert the gate: line — pre-fix replay would be vacuous"

# revert the reason choice to the old unconditional form
i = s.index("        gate_ran = run_gate_result[0] != \"not-run\"")
j = s.index("        escalate(reason, 5)", i)
s = s[:i] + (
'        reason = timeout_reason[0] if timeout_reason[0] != "turn-timeout-or-hang" else "pre-advance-failed"\n'
'        emit = timeout_emit[0] if timeout_reason[0] != "turn-timeout-or-hang" else "halted"\n'
'        log("relay escalated: pre-advance gate failed")\n'
) + s[j:]
p.write_text(s)
print("PATCHED")
PY

PRE_DRIVER="$FIXH/relay-automation/marathon-drive.sh"
PRE_ROOT="$WORK/target-prefix"
cp -R "$ROOT" "$PRE_ROOT"
rm -rf "$PRE_ROOT/phases"
MARATHON_ROOT="$PRE_ROOT" \
MARATHON_RELAY_DRIVE="$RD_FAIL" \
MARATHON_AGENT_CMD="$WORK/noop-agent" \
TICK_REPO_ROOT="$PRE_ROOT" TICK_BIN="$TICK" \
CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
    --reviewer agy --builder claude --phase-id no-gate > "$WORK/prefix.log" 2>&1 && rc=0 || rc=$?

pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"

[ "$pre_reason" = "pre-advance-failed" ] \
  && pass "control: the pre-fix revision reports pre-advance-failed for a gate that never ran (the defect, observed)" \
  || fail "control: pre-fix replay did not reproduce the defect — got reason '$pre_reason', so the post-fix assertions prove nothing"

[ -z "$pre_gate" ] \
  && pass "control: the pre-fix record carries NO statement of whether the gate ran" \
  || fail "control: pre-fix record unexpectedly had 'gate: $pre_gate'"

echo "gh407-gate-ran-attribution: $PASS pass, $FAIL fail"
