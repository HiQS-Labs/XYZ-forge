#!/usr/bin/env bash
# #142 — the ATE filing chain exits with a contract: 0 filed/dry-run · 3 no-records · 1 gh-failed,
# propagated through run_variations.py so a multi-hour run cannot end at exit 0 with its final
# step failed.
#
# Negative control (recorded, not re-run here): pre-fix, Case 2 exited 0 — compile_issue.py's
# main() returned None on every path and run_variations dropped the code twice more. Observed on
# development before the fix in the PR that adds this suite.
#
# Hermetic: `gh` is a PATH-first stub that records invocations and exits with a scripted code;
# the chain case drives run_variations.py with --mock-classifier and a command_template stub —
# no LM Studio, no network, no issue created.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh142-ate-exit.XXXXXX")"
trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT
# GH-1/GH-10: shared, resolved containment for every fixture this suite creates — the guard
# fires at the USE boundary (require_fixture before the repo's first dangerous use below).
. "$ROOT/test/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

GH_STUB_DIR="$WORK/bin"
mkdir -p "$GH_STUB_DIR"
GH_CALLS="$WORK/gh-calls.log"
GH_STUB_RC="$WORK/gh-stub-rc"
cat >"$GH_STUB_DIR/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$GH_CALLS"
rc="\$(cat "$GH_STUB_RC" 2>/dev/null || echo 0)"
[ "\$rc" -eq 0 ] && printf 'https://example.invalid/issues/stub\n'
exit "\$rc"
EOF
chmod +x "$GH_STUB_DIR/gh"
echo 0 >"$GH_STUB_RC"

CI="$ROOT/utils/ate/scripts/compile_issue.py"
RV="$ROOT/utils/ate/scripts/run_variations.py"

# A log with two failing records sharing a signature (dedup shape) — run_variations-style nested
# classification, which is the shape the filing chain consumes from a real run.
LOG="$WORK/error_log.jsonl"
cat >"$LOG" <<'EOF'
{"status":"fail","exit_code":1,"command":"stub --mode fail","variation":{"mode":"fail"},"stderr":"boom","classification":{"status":"fail","severity":"medium","category":"command_error","likely_cause":"exit code 1"}}
{"status":"fail","exit_code":1,"command":"stub --mode fail","variation":{"mode":"fail"},"stderr":"boom","classification":{"status":"fail","severity":"medium","category":"command_error","likely_cause":"exit code 1"}}
{"status":"pass","exit_code":0,"command":"stub --mode ok","variation":{"mode":"ok"},"stderr":"","classification":{"status":"pass","severity":"none","category":"ok","likely_cause":"clean execution"}}
EOF

run_ci() {  # <log> -> rc in RC, output in OUT
  OUT="$(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$CI" --log "$1" --repo acme/widgets --test-name gh142 2>&1)"
  RC=$?
}

echo "== 1. filed: stub gh succeeds =="
: >"$GH_CALLS"
run_ci "$LOG"
[ "$RC" -eq 0 ] && pass "compile_issue exits 0 when gh files" || fail "filed case rc=$RC (want 0)"
[ -s "$GH_CALLS" ] && pass "gh was invoked" || fail "gh never invoked"
grep -q "Issue created" <<<"$OUT" && pass "creation reported" || fail "no Issue created line: $OUT"
[ ! -f "$WORK/issue_body.md" ] && pass "body file cleaned up after filing" || fail "issue_body.md left behind"

echo "== 2. gh-failed: nonzero, body preserved (the #142 defect: was exit 0) =="
echo 1 >"$GH_STUB_RC"
: >"$GH_CALLS"
run_ci "$LOG"
[ "$RC" -eq 1 ] && pass "compile_issue exits 1 when gh fails" || fail "gh-failed rc=$RC (want 1; pre-fix bug was 0)"
grep -q "gh issue create failed" <<<"$OUT" && pass "failure named" || fail "no failure line: $OUT"
[ -f "$WORK/issue_body.md" ] && pass "issue_body.md preserved for manual filing" || fail "body file lost"
rm -f "$WORK/issue_body.md"
echo 0 >"$GH_STUB_RC"

echo "== 3. no-records: exit 3, gh never called =="
: >"$GH_CALLS"
: >"$WORK/empty.jsonl"
run_ci "$WORK/empty.jsonl"
[ "$RC" -eq 3 ] && pass "empty log exits 3 (distinct from filed)" || fail "no-records rc=$RC (want 3)"
[ ! -s "$GH_CALLS" ] && pass "gh not invoked on empty log" || fail "gh invoked with nothing to file"

echo "== 4. dry-run: exit 0, gh never called =="
: >"$GH_CALLS"
OUT="$(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$CI" --log "$LOG" --repo acme/widgets --test-name gh142 --dry-run 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && pass "dry-run exits 0" || fail "dry-run rc=$RC"
[ ! -s "$GH_CALLS" ] && pass "dry-run never calls gh" || fail "gh invoked in dry-run"
grep -q "seen 2x" <<<"$OUT" && pass "dedup: two identical failures collapse to one bucket, seen 2x" || fail "dedup count wrong in body: $OUT"

echo "== 5. chain: run_variations propagates the filing outcome =="
REPO="$WORK/scratch"
git init -q "$REPO" && git -C "$REPO" config user.email t@t && git -C "$REPO" config user.name t
require_fixture "$REPO" "chain scratch repo"   # GH-567: guard at the use boundary
printf 'x\n' >"$REPO/seed.txt" && git -C "$REPO" add -A && git -C "$REPO" commit -qm seed

FAILSTUB="$WORK/fail-cmd"
printf '#!/usr/bin/env bash\nexit 1\n' >"$FAILSTUB" && chmod +x "$FAILSTUB"
cat >"$WORK/variations.yaml" <<EOF
command_template: ["$FAILSTUB", "{mode}"]
variation_keys: [mode]
mode: [fail]
model: stub
message: probe
EOF

echo 1 >"$GH_STUB_RC"
CHAIN_OUT="$(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$RV" \
  --repo "$REPO" --variations "$WORK/variations.yaml" --mock-classifier \
  --log "$WORK/chain.jsonl" --control "$WORK/chain-control.json" \
  --gh-repo acme/widgets --test-name gh142 --minutes 0.01 2>&1)"; CRC=$?
[ "$CRC" -eq 1 ] && pass "run_variations exits 1 when the chained filing fails" \
  || fail "chain rc=$CRC (want 1; pre-fix the whole run exited 0) :: $(grep -m2 'filing\|exited' <<<"$CHAIN_OUT")"
grep -q "compile_issue.py exited 1" <<<"$CHAIN_OUT" && pass "chain names the child failure" || fail "no child-failure line"

echo 0 >"$GH_STUB_RC"
CHAIN_OUT2="$(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$RV" \
  --repo "$REPO" --variations "$WORK/variations.yaml" --mock-classifier \
  --log "$WORK/chain2.jsonl" --control "$WORK/chain2-control.json" \
  --gh-repo acme/widgets --test-name gh142 --minutes 0.01 2>&1)"; CRC2=$?
[ "$CRC2" -eq 0 ] && pass "run_variations exits 0 when the chained filing succeeds" \
  || fail "healthy chain rc=$CRC2 :: $(grep -m2 'filing\|exited' <<<"$CHAIN_OUT2")"
[ -s "$WORK/chain2.jsonl" ] && pass "chain run logged records (fixture really exercised)" || fail "no records logged"

echo "== 6. #141 Phase 5: labels default-neutral and flow end-to-end =="
# Default: neutral 'bug' only — a generalized soak must never file Aider-labelled issues.
GH_ARGS="$(cat "$GH_CALLS")"
case "$GH_ARGS" in
  *"--label bug"*) pass "default rollup label is the neutral 'bug'" || true ;;
  *) fail "default label missing: $GH_ARGS" ;;
esac
if grep -q "aider-pipeline" <<<"$GH_ARGS"; then
  fail "aider-pipeline leaked into a non-Aider run's labels: $GH_ARGS"
else
  pass "no aider-pipeline on a non-Aider grid (default-neutral)"
fi

# Explicit passthrough: --issue-label wins end-to-end (run entry point -> compiler -> gh).
: >"$GH_CALLS"
CHAIN_OUT3="$(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$RV" \
  --repo "$REPO" --variations "$WORK/variations.yaml" --mock-classifier \
  --log "$WORK/chain3.jsonl" --control "$WORK/chain3-control.json" \
  --gh-repo acme/widgets --test-name gh142 --minutes 0.01 --issue-label turn-shim-soak 2>&1)"; CRC3=$?
GH_ARGS3="$(cat "$GH_CALLS")"
[ "$CRC3" -eq 0 ] && pass "labelled chain run healthy" || fail "labelled chain rc=$CRC3"
case "$GH_ARGS3" in
  *"--label turn-shim-soak"*) pass "--issue-label flows run -> compiler -> gh" ;;
  *) fail "--issue-label lost on the way to gh: $GH_ARGS3" ;;
esac
if grep -q "aider-pipeline" <<<"$GH_ARGS3"; then
  fail "aider-pipeline present alongside explicit labels"
else
  pass "explicit labels replace, not augment, the default"
fi

# Grid-declared labels: the Aider preset opts back in from variations.yaml (issue_labels key).
OKSTUB="$WORK/ok-cmd"
printf '#!/usr/bin/env bash\nexit 0\n' >"$OKSTUB" && chmod +x "$OKSTUB"
cat >"$WORK/variations-aider.yaml" <<EOF
command_template: ["$OKSTUB", "{mode}"]
variation_keys: [mode]
mode: [ok]
model: stub
message: probe
issue_labels: [bug, aider-pipeline]
EOF
: >"$GH_CALLS"
(cd "$WORK" && PATH="$GH_STUB_DIR:$PATH" python3 "$RV" \
  --repo "$REPO" --variations "$WORK/variations-aider.yaml" --mock-classifier \
  --log "$WORK/chain4.jsonl" --control "$WORK/chain4-control.json" \
  --gh-repo acme/widgets --test-name gh142 --minutes 0.01 >/dev/null 2>&1)
GH_ARGS4="$(cat "$GH_CALLS")"
case "$GH_ARGS4" in
  *"--label aider-pipeline"*) pass "the Aider preset opts back into aider-pipeline via issue_labels" ;;
  *) fail "grid-declared issue_labels did not reach gh: $GH_ARGS4" ;;
esac

echo "== 7. #141 Phase 5: the classifier oracle is decoupled from the Aider edit assumption =="
python3 - "$ROOT" <<'PY' || fail "prompt-rule decoupling broken"
import os, sys, types

# Stub the runtime deps the prompt constants don't use, keeping the import hermetic.
for mod in ("requests", "yaml"):
    if mod not in sys.modules:
        sys.modules[mod] = types.ModuleType(mod)
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "ate", "scripts"))
import run_variations as rv

assert "DIAGNOSTIC probe" in rv._EDIT_RULE_DIAGNOSTIC, "diagnostic rule missing"
assert "no_edit" in rv._EDIT_RULE_EXPECTS, "edit-expecting rule lost its no_edit contract"
# The #146 failure shape: a diagnostic grid's prompt must NOT carry the edit-oracle coercion.
assert "fail\"/\"no_edit" not in rv.CLASSIFY_PROMPT.format(
    pipeline_name="p", edit_rule=rv._EDIT_RULE_DIAGNOSTIC,
    command="c", exit_code=0, edit_applied=False, stdout="", stderr=""), \
    "diagnostic prompt still coerces no-edit to fail"
assert "fail\"/\"no_edit" in rv.CLASSIFY_PROMPT.format(
    pipeline_name="p", edit_rule=rv._EDIT_RULE_EXPECTS,
    command="c", exit_code=0, edit_applied=False, stdout="", stderr=""), \
    "edit grid lost its no-edit coercion"
print("  PASS: expects_edits selects the classifier rule (diagnostic grids pass no-edit runs)")
PY

# And the mock classifier path already grades exit-0 no-edit runs as pass on a diagnostic grid
# (the rule the #146 soak needed); the prompt half is pinned above for the LM Studio path.
grep -q '"status": "pass"' "$WORK/chain4.jsonl" && pass "mock classifier passes an exit-0 no-edit variation" \
  || fail "mock classifier failed an exit-0 no-edit run"

echo "== 8. review turn 3: launch failure and hang land in the gh-failed class, loudly =="
# Missing gh: exit 1 with a CLEAN message (pre-hardening: Python traceback, coincidentally rc 1).
# The stripped PATH still resolves python3 (a lone symlink) so the interpreter runs while gh cannot.
rm -f "$WORK/issue_body.md"
mkdir -p "$WORK/nothingbin"
ln -sf "$(command -v python3)" "$WORK/nothingbin/python3"
MISSING_OUT="$(cd "$WORK" && PATH="$WORK/nothingbin" python3 "$CI" --log "$LOG" \
  --repo acme/widgets --test-name gh142 2>&1)"; MRC=$?
[ "$MRC" -eq 1 ] && pass "missing gh exits 1 (gh-failed class)" || fail "missing-gh rc=$MRC (want 1)"
case "$MISSING_OUT" in
  *"was not found on PATH"*) pass "missing gh named cleanly" ;;
  *) fail "missing-gh message wrong: $MISSING_OUT" ;;
esac
if grep -q "Traceback" <<<"$MISSING_OUT"; then fail "missing gh leaked a traceback"; else pass "no traceback on launch failure"; fi
[ -f "$WORK/issue_body.md" ] && pass "body preserved on launch failure" || fail "body lost on launch failure"
rm -f "$WORK/issue_body.md"

# Hanging gh: the call is capped (ATE_GH_TIMEOUT_S), exit 1, no indefinite hold.
mkdir -p "$WORK/hangbin"
cat >"$WORK/hangbin/gh" <<'EOF'
#!/usr/bin/env bash
sleep 30
EOF
chmod +x "$WORK/hangbin/gh"
HANG_OUT="$(cd "$WORK" && PATH="$WORK/hangbin:$PATH" ATE_GH_TIMEOUT_S=2 python3 "$CI" \
  --log "$LOG" --repo acme/widgets --test-name gh142 2>&1)"; HRC=$?
[ "$HRC" -eq 1 ] && pass "hanging gh exits 1 via the timeout cap" || fail "hang rc=$HRC (want 1)"
case "$HANG_OUT" in
  *"did not answer within 2s"*) pass "timeout named with the cap and the override" ;;
  *) fail "hang message wrong: $HANG_OUT" ;;
esac
[ -f "$WORK/issue_body.md" ] && pass "body preserved on hang" || fail "body lost on hang"
rm -f "$WORK/issue_body.md"

echo "gh142-ate-exit-contract: $PASS passed, $FAIL failed"
