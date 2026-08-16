#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh441-gate-env-contract.sh (cases C4a/C4b); pre-fix revision: the same custom gate WITHOUT sourcing relay-automation/gate-env.sh, i.e. every gate in the tree before this lane; pre-fix result: the gate inherited ALLOW_PATHS and reported its parent's contamination as the change's own; post-fix result: the identical gate sourcing the helper sees a clean environment. C5a/C5b additionally observe the helper refusing to run (rc=1) when the registry is unreachable, so a silently-skipped scrub cannot read as a pass"}
# test/gh441-gate-env-contract.sh — GH-441 Phase 2.
#
# Phase 1 fixed the two variables that were biting. It did NOT make the boundary governed, so the next
# export added to a driver could reintroduce the same defect silently. THAT is what this file pins.
#
# THE POINT OF THIS FILE IS THE LOUD-FAILURE DIRECTION.
#
# A suite that only asserted "the scrubbed names are absent from gate_env()" would pass just as
# happily if someone added a new contaminating export and never classified it — which is precisely the
# hole that existed before, and the #419 shape this release is about. So C1 is the load-bearing case:
# it greps the drivers for what they actually export and fails if the registry does not cover it.
#
# Hermetic: no drivers spawned, no network, no ambient .tick writes. Fixtures under $WORK only.
source "$(dirname "$0")/_setup.sh" gh441-gate-env-contract

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GE="$ROOT/utils/py/gate_env.py"
HELPER="$ROOT/relay-automation/gate-env.sh"

[ -r "$GE" ] && pass "the contract module exists at utils/py/gate_env.py" \
             || fail "missing $GE"

# ── C1: THE LOUD FAILURE — every driver export is classified ──────────────────────────────────────
# Greps the drivers for `os.environ["NAME"] = ...` and diffs against the registry. Adding an export
# without classifying it makes this fail, which is the whole contract. Without this assertion the
# registry is just a denylist someone will forget to update.
exports="$(
  /usr/bin/grep -hoE 'os\.environ\[["'"'"'][A-Z_0-9]+["'"'"']\] *=' \
    "$ROOT/utils/py/marathon_drive.py" "$ROOT/utils/py/relay_drive.py" 2>/dev/null \
  | /usr/bin/grep -oE '[A-Z_0-9]{2,}' | LC_ALL=C sort -u
)"
[ -n "$exports" ] && pass "C1a found driver exports to check ($(printf '%s\n' "$exports" | wc -l | tr -d ' ') names)" \
                  || fail "C1a grep found no driver exports — the check would vacuously pass"

classified="$( { python3 "$GE" --list-scrubbed; python3 "$GE" --list-passed; } | LC_ALL=C sort -u )"
unclassified="$(LC_ALL=C comm -23 <(printf '%s\n' "$exports") <(printf '%s\n' "$classified"))"
[ -z "$unclassified" ] \
  && pass "C1b every variable the drivers export is classified scrub-or-pass" \
  || fail "C1b UNCLASSIFIED driver exports (add them to HARNESS_ENV in utils/py/gate_env.py): $(printf '%s' "$unclassified" | tr '\n' ' ')"

# ── C2: the scrub actually happens, and the PASS list actually survives ───────────────────────────
# Both directions matter. A contract that scrubbed everything would "pass" C2a while breaking every
# nested driver — that is the reverted commit.
probe() { # <var> <value> -> prints the value gate_env() yields, or the literal ABSENT
  env "$1=$2" python3 - "$1" <<'PY'
import os, sys
sys.path.insert(0, os.path.join(os.environ["GH441_ROOT"], "utils", "py"))
import gate_env
print(gate_env.gate_env().get(sys.argv[1], "ABSENT"))
PY
}
export GH441_ROOT="$ROOT"

[ "$(probe ALLOW_PATHS "some/path")" = ABSENT ] \
  && pass "C2a ALLOW_PATHS is scrubbed (the variable that flipped oracle-guard)" \
  || fail "C2a ALLOW_PATHS survived into the gate environment"

[ "$(probe RELAY_DRIVER_LOCKED 1)" = "1" ] \
  && pass "C2b RELAY_DRIVER_LOCKED SURVIVES — nested drivers need it; scrubbing it was reverted" \
  || fail "C2b RELAY_DRIVER_LOCKED was scrubbed — this is the 2026-08-07 regression, see gate_env.py docstring"

[ "$(probe PATH_LIKE_UNRELATED xyz)" = "xyz" ] \
  && pass "C2c an unrelated variable is untouched (the contract is not a blanket wipe)" \
  || fail "C2c the contract removed a variable it does not own"

# ── C3: the shell helper and the driver agree — no second copy of the list ────────────────────────
# The pre-fix defect was TWO lists: marathon_drive popped 3 names, validate.sh unset 6 others. If the
# helper ever inlines its own list this assertion is what catches the drift.
sh_names="$(python3 "$GE" --sh | sed 's/^unset //' | tr ' ' '\n' | LC_ALL=C sort -u)"
py_names="$(python3 "$GE" --list-scrubbed | LC_ALL=C sort -u)"
[ "$sh_names" = "$py_names" ] \
  && pass "C3a the shell helper's list is generated from the same registry as the driver's" \
  || fail "C3a shell/python scrub lists disagree — a second copy of the list has appeared"

! /usr/bin/grep -qE '^[[:space:]]*unset[[:space:]]+[A-Z]' "$HELPER" \
  && pass "C3b gate-env.sh does not hardcode variable names (single source of truth)" \
  || fail "C3b gate-env.sh inlines an unset list — that is the defect this replaces"

# gate-env.sh must not reach the same result via `eval` on generated text: the GH-64 security gate
# flags that as eval-unsanitized, and it caught exactly this on the first draft of this file.
! /usr/bin/grep -qE '^[^#]*eval[[:space:]]' "$HELPER" \
  && pass "C3c gate-env.sh applies the list without eval (GH-64 eval-unsanitized)" \
  || fail "C3c gate-env.sh uses eval — the security gate will reject it"

# C3d THE DRIFT GUARD. marathon_drive.py keeps its own LITERAL copy of the scrub set, deliberately:
# GH-307's guard statically requires a literal there so the set is auditable by reading the driver,
# and marathon_drive.py is loaded via importlib from a bare `<stdin>` by gh322-runlog-python-lane, so
# it cannot `import gate_env` (ModuleNotFoundError takes the whole driver down — measured, not
# guessed). Two copies are therefore correct; two copies that can DRIFT are not. This is what makes
# them safe.
driver_literal="$(python3 - "$ROOT/utils/py/marathon_drive.py" <<'PY'
import ast, re, sys
src = open(sys.argv[1]).read()
m = re.search(r"^\s*GATE_SCRUBBED_ENV\s*=\s*(\(.*?\))", src, re.S | re.M)
print("\n".join(sorted(ast.literal_eval(m.group(1)))) if m else "NOLITERAL")
PY
)"
[ "$driver_literal" = "$py_names" ] \
  && pass "C3d the driver's literal is EXACTLY the registry (the two copies cannot drift)" \
  || fail "C3d driver literal != gate_env.py registry — one side was changed alone. driver=[$(printf '%s' "$driver_literal" | tr '\n' ' ')]"

# ── C4: A CUSTOM GATE using the helper is immune to the contamination that broke the real one ─────
# This is the acceptance criterion in its live form: a hand-written --pre-advance-cmd must be able to
# obtain the clean environment WITHOUT copying validate.sh's prologue. The control is the same gate
# without the helper — which is exactly the script that failed on 2026-08-07.
cat >"$WORK/gate-with-helper.sh" <<EOF
#!/usr/bin/env bash
. "$HELPER"
printf 'ALLOW_PATHS=[%s]\n' "\${ALLOW_PATHS-UNSET}"
EOF
cat >"$WORK/gate-without-helper.sh" <<'EOF'
#!/usr/bin/env bash
printf 'ALLOW_PATHS=[%s]\n' "${ALLOW_PATHS-UNSET}"
EOF
chmod +x "$WORK/gate-with-helper.sh" "$WORK/gate-without-helper.sh"

with_out="$(ALLOW_PATHS="contaminated/**" bash "$WORK/gate-with-helper.sh" 2>/dev/null)"
without_out="$(ALLOW_PATHS="contaminated/**" bash "$WORK/gate-without-helper.sh" 2>/dev/null)"

[ "$with_out" = "ALLOW_PATHS=[UNSET]" ] \
  && pass "C4a a custom gate sourcing the helper sees a CLEAN environment" \
  || fail "C4a custom gate still inherited ALLOW_PATHS: $with_out"

[ "$without_out" = "ALLOW_PATHS=[contaminated/**]" ] \
  && pass "C4b NEGATIVE CONTROL: the same gate without the helper IS contaminated" \
  || fail "C4b control did not reproduce the contamination — C4a proves nothing: $without_out"

# ── C5: the helper refuses to run silently when it cannot read the registry ───────────────────────
# A gate whose scrub silently no-ops reports its parent's failures as the change's own. That must be
# loud, not quiet — the #419 principle applied to this file's own failure mode.
cp "$HELPER" "$WORK/orphan-helper.sh"   # copied away from the harness, so utils/py/ is unreachable
set +e
orphan_out="$(cd "$WORK" && bash ./orphan-helper.sh 2>&1)"; orphan_rc=$?
set -e
[ "$orphan_rc" -ne 0 ] \
  && pass "C5a the helper FAILS (rc=$orphan_rc) when it cannot resolve the registry" \
  || fail "C5a helper exited 0 with no scrub applied — a silently ungoverned gate"
printf '%s' "$orphan_out" | /usr/bin/grep -q "GH-441" \
  && pass "C5b the failure names the contract so it is diagnosable in one read" \
  || fail "C5b failure message did not reference GH-441: $orphan_out"

# ── C6: validate.sh consumes the contract instead of carrying its own list ────────────────────────
/usr/bin/grep -q "gate-env.sh" "$ROOT/validate.sh" \
  && pass "C6a validate.sh sources the shared helper" \
  || fail "C6a validate.sh does not source gate-env.sh"
! /usr/bin/grep -qE '^unset ALLOW_PATHS RELAY_FILE' "$ROOT/validate.sh" \
  && pass "C6b validate.sh no longer hardcodes its own prologue" \
  || fail "C6b validate.sh still carries the duplicated unset line"

printf '  gh441-gate-env-contract: %s pass, %s fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
