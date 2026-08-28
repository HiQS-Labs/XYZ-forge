#!/usr/bin/env bash
# gh280-jog-marathon-adapter.sh — GH-280 Phase 1: Jog ↔ Marathon machine contracts.
#
# Exercises, with REAL Preflight → Marathon → Relay chains and deterministic agent/GitHub
# shims (never --simulate):
#   - swarm-preflight emits the additive swarm-preflight/marathon-invocation@1 artifact
#   - marathon-drive --result-file emits exactly one marathon-drive/result@1 receipt per
#     terminal exit: success, pre-dispatch refusal, builder failure, reviewer cap,
#     gate failure, timeout, lane park, protected-branch redirect, PR-publication failure
#   - jog_run's contract loaders reject unsupported schema versions and malformed artifacts
#   - both installation shapes: harness at repo ROOT and vendored under .xyz/
source "$(dirname "$0")/_setup.sh" gh280-jog-marathon-adapter
unset MARATHON_LANE_NS MARATHON_ROOT MARATHON_RELAY_DRIVE MARATHON_AGENT_CMD TICK_BIN
REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ── deterministic GitHub shim: logs every call, canned PR answers ─────────────────────────────
# Anything not understood exits 1 — the same shape as an unauthenticated/offline gh, so
# preflight's issue-state probe degrades to `unknown` instead of touching the network.
STUB_BIN="$WORK/stub-bin"
mkdir -p "$STUB_BIN"
GH_STUB_LOG="$WORK/gh-stub-calls.log"
export GH_STUB_LOG
GH_STUB_PR_JSON="${GH_STUB_PR_JSON:-}"   # optional: path to a canned `gh pr list --json` array
export GH_STUB_PR_JSON
cat > "$STUB_BIN/gh" <<'GH_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"
if [ "${1:-}" = "auth" ]; then exit 0; fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "list" ]; then
  for a in "$@"; do
    if [ "$a" = "number,url,state" ]; then
      if [ -n "${GH_STUB_PR_JSON:-}" ] && [ -s "$GH_STUB_PR_JSON" ]; then cat "$GH_STUB_PR_JSON"; else echo "[]"; fi
      exit 0
    fi
  done
  # closeout's `--json url --jq '.[0].url'` query
  if [ -n "${GH_STUB_PR_JSON:-}" ] && [ -s "$GH_STUB_PR_JSON" ]; then
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d[0]["url"] if d else "")' "$GH_STUB_PR_JSON"
  else
    echo ""
  fi
  exit 0
fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "create" ]; then
  if [ "${GH_STUB_CREATE_FAIL:-0}" = "1" ]; then exit 1; fi
  echo "https://example.invalid/pr/created-by-stub"
  exit 0
fi
exit 1
GH_EOF
chmod +x "$STUB_BIN/gh"
export PATH="$STUB_BIN:$PATH"

CANNED_PR="$WORK/canned-pr.json"
printf '[{"number":42,"url":"https://example.invalid/x/pr/42","state":"OPEN"}]\n' > "$CANNED_PR"

# ── stub relay-drive (records argv, exits RELAY_DRIVE_EXIT) ───────────────────────────────────
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/relay-drive-args"
exit "${RELAY_DRIVE_EXIT:-0}"
STUB_EOF
chmod +x "$STUB_RD"

# exit-0 agent binaries so marathon-drive's pre-dispatch binary probe passes
STUB_CODEX="$WORK/stub-codex"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CODEX"; chmod +x "$STUB_CODEX"
STUB_AGY="$WORK/stub-agy";     printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY";     chmod +x "$STUB_AGY"

GATE_PASS="$WORK/gate-pass.sh"; printf '#!/usr/bin/env bash\nexit 0\n' > "$GATE_PASS"; chmod +x "$GATE_PASS"
GATE_FAIL="$WORK/gate-fail.sh"; printf '#!/usr/bin/env bash\nexit 1\n' > "$GATE_FAIL"; chmod +x "$GATE_FAIL"

CAPTURE_DOC_NAME="GH-901-FIXTURE-LANE.md"
write_capture_doc() {  # <path>
  cat > "$1" <<DOC_EOF
---
gh_issue: 901
source: https://github.com/example/example/issues/901
title: "GH-280 fixture lane"
status: "Active"
created: 2026-08-27
updated: 2026-08-27
owner: test
doc_type: bugfix
---

# GH-901 fixture lane

## Acceptance
- [ ] artifact updated and gate green

## Swarm Preflight Contract
\`\`\`json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/fixture-gate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "notes/landing-note.txt" } ],
  "artifacts": [ "src/feature.js" ]
}
\`\`\`
DOC_EOF
}

# ── fixture: a real git clone (origin/HEAD resolvable) with the harness installed ──────────────
# <root> <relative harness prefix: "" for root install, ".xyz/" for vendored>
setup_fixture() {
  local root="$1" prefix="$2"
  git clone -q "$REMOTE" "$root"
  git -C "$root" config user.email gh280@test.invalid
  git -C "$root" config user.name gh280
  mkdir -p "$root/$prefix"
  for d in relay-automation bin src utils; do
    cp -R "$REPO/$d" "$root/$prefix$d"
  done
  mkdir -p "$root/src" "$root/test" "$root/PROJECT/2-WORKING"
  printf 'module.exports = 1\n' > "$root/src/feature.js"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$root/test/fixture-gate.sh"
  write_capture_doc "$root/PROJECT/2-WORKING/$CAPTURE_DOC_NAME"
  if [ -z "$prefix" ]; then
    printf '.tick/\n.xyz/\n__pycache__/\n' > "$root/.gitignore"
  else
    printf '.tick/\n%s.tick/\n__pycache__/\n' "$prefix" > "$root/.gitignore"
  fi
  python3 "$REPO/utils/py/releases_app.py" --root "$root" init >/dev/null 2>&1
  python3 "$REPO/utils/py/releases_app.py" --root "$root" jog add 901 >/dev/null 2>&1
  git -C "$root" add -A >/dev/null 2>&1
  git -C "$root" commit -q -m "fixture init" >/dev/null 2>&1
}

FR="$WORK/root-install";  setup_fixture "$FR" ""
FV="$WORK/vendor-install"; setup_fixture "$FV" ".xyz/"
INIT_HEAD_R="$(git -C "$FR" rev-parse HEAD)"

cleanup_root_fixture() {
  rm -rf "$FR/.tick" "$FR/marathon-system" "$FR/relay-system"
  git -C "$FR" checkout -q main >/dev/null 2>&1 || true
  git -C "$FR" reset -q --hard "$INIT_HEAD_R" >/dev/null 2>&1 || true
  git -C "$FR" clean -qfd -e .xyz >/dev/null 2>&1 || true
  rm -f "$WORK/relay-drive-args"
}

# json-field assertion helper: jassert <file> <python-expr over d> <label>
jassert() {
  python3 -c 'import json,sys,os,subprocess
d = json.load(open(sys.argv[1]))
sys.exit(0 if eval(sys.argv[2]) else 1)' "$1" "$2" 2>/dev/null \
    && pass "$3" || fail "$3 ($(head -c 400 "$1" 2>/dev/null))"
}

# fixed-substring helper (jog-queue.sh has one; this suite is standalone)
has() { printf '%s' "$1" | grep -Fq -- "$2"; }

run_md_root() {  # <extra-args…> — drive in the ROOT fixture with the stub relay-drive
  (cd "$FR" && MARATHON_RELAY_DRIVE="$STUB_RD" \
    CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
    bash "$FR/relay-automation/marathon-drive.sh" \
      --phases-dir "$FR/marathon-system" \
      --phase-brief "$WORK/brief.md" \
      --reviewer agy --builder codex \
      --pre-advance-cmd "bash $GATE_PASS" \
      "$@")
}

printf '## Implement a hello-world function\nWrite a function that returns "hello".\n' > "$WORK/brief.md"

# ═══ A. Preflight emits the structured invocation artifact (root install) ══════════════════════
PK="$WORK/packet-root"
PF_OUT="$(cd "$FR" && python3 "$FR/utils/py/swarm_preflight.py" --gh-issue 901 --out "$PK" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "A1 root preflight exits 0 (candidate ready)" || fail "A1 root preflight exit=$rc: $PF_OUT"
for f in run-candidate.json lane-plan.json freshness.json readiness.json marathon-invocation.txt packet.md marathon-invocation.json; do
  [ -f "$PK/$f" ] && pass "A2 packet still carries $f (additive)" || fail "A2 packet missing $f"
done
INV="$PK/marathon-invocation.json"
jassert "$INV" 'd["schema"]=="swarm-preflight/marathon-invocation@1"' "A3 invocation artifact schema is marathon-invocation@1"
jassert "$INV" 'd["argv"][0]=="'"$FR"'/relay-automation/marathon-drive.sh" and os.path.isfile(d["argv"][0]) and os.access(d["argv"][0], os.X_OK)' "A4 argv[0] is the absolute executable drive path"
jassert "$INV" 'd["env"]["XYZ_HARNESS_CONTEXT"]=="swarm" and d["env"]["XYZ_SESSION_ID"] and d["env"]["RELAY_WORKTREE_ISOLATION"]=="1"' "A5 env entries carry swarm/session/isolation"
jassert "$INV" 'd["packet_path"]=="'"$PK"'/packet.md" and os.path.isfile(d["packet_path"])' "A6 packet_path resolves"
jassert "$INV" 'd["result_path"]=="'"$PK"'/marathon-result.json"' "A7 result_path is beside the packet"
jassert "$INV" 'd["issue"]=="901" and d["base_ref"]=="main" and d["builder"]=="codex" and d["reviewer"]=="agy"' "A8 identity fields: issue/base_ref/builder/reviewer"
jassert "$INV" 'd["phase"]==d["lane"] and d["phase"] and d["gate"]=="bash test/fixture-gate.sh" and "src/feature.js" in d["artifacts"]' "A9 phase/lane/gate/artifacts carried"
jassert "$INV" '"--result-file" in d["argv"] and d["argv"][d["argv"].index("--result-file")+1]==d["result_path"]' "A10 argv embeds --result-file with result_path"
jassert "$INV" '"--phase-brief" in d["argv"] and d["argv"][d["argv"].index("--phase-brief")+1]==d["packet_path"]' "A11 argv embeds --phase-brief with packet_path"
jassert "$PK/run-candidate.json" 'd["schema"]=="swarm-preflight/run-candidate@1"' "A12 run-candidate@1 unchanged (compat)"
grep -q '^XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=[^ ]* RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh' <<<"$(head -1 "$PK/marathon-invocation.txt")" \
  && pass "A13 text invocation hint unchanged (compat)" || fail "A13 text invocation drifted"

# ═══ B. jog_run contract loaders reject bad contracts before dispatch ═════════════════════════
JOPY="import sys; sys.path.insert(0, '$REPO/utils/py')"
python3 -c "$JOPY
from jog_run import load_marathon_invocation
inv = load_marathon_invocation('$INV')
assert inv['issue'] == '901'
" && pass "B1 load_marathon_invocation accepts the real artifact" || fail "B1 loader rejected the real artifact"
python3 -c "$JOPY
import json
from jog_run import load_marathon_invocation, ContractError
d = json.load(open('$INV')); d['schema'] = 'swarm-preflight/marathon-invocation@2'
json.dump(d, open('$WORK/inv-bad-schema.json', 'w'))
try:
    load_marathon_invocation('$WORK/inv-bad-schema.json')
    sys.exit(1)
except ContractError as e:
    sys.exit(0 if 'supports only' in str(e) else 1)
" && pass "B2 unsupported schema version refused" || fail "B2 schema @2 was not refused"
python3 -c "$JOPY
import json
from jog_run import load_marathon_invocation, ContractError
d = json.load(open('$INV')); d['argv'][0] = '/nonexistent/marathon-drive.sh'
json.dump(d, open('$WORK/inv-bad-drive.json', 'w'))
try:
    load_marathon_invocation('$WORK/inv-bad-drive.json'); sys.exit(1)
except ContractError:
    sys.exit(0)
" && pass "B3 non-executable argv[0] refused" || fail "B3 bogus drive path accepted"

# ═══ C. marathon-drive terminal receipts (root install, stub relay-drive) ═════════════════════
RES="$WORK/md-result.json"

# C1 success
rm -f "$RES"
RELAY_DRIVE_EXIT=0 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "C1 approved run exits 0" || fail "C1 approved run exit=$rc"
[ -f "$RES" ] && pass "C1 receipt written" || fail "C1 no receipt at $RES"
jassert "$RES" 'd["schema"]=="marathon-drive/result@1" and d["outcome"]=="approved" and d["exit_code"]==0' "C1 receipt outcome approved / exit 0"
jassert "$RES" 'd["phase"]=="p1" and d["lane"]=="p1" and d["token"]=="MARATHON-P1-TURN"' "C1 receipt carries phase/lane/token"
jassert "$RES" 'd["issue"] is None' "C1 unreached issue is an explicit null"
jassert "$RES" 'd["gate"]["result"]=="green" and d["gate"]["exit"]==0 and d["gate"]["receipt_path"] and os.path.isfile(d["gate"]["receipt_path"])' "C1 gate green + gate receipt path resolves"
jassert "$RES" 'd["head_sha"] and d["head_sha"]==subprocess.check_output(["git","-C","'"$FR"'","rev-parse","HEAD"]).decode().strip()' "C1 head_sha matches repo HEAD"
jassert "$RES" 'd["head_branch"]=="main" and d["base_branch"] is None and d["branch_redirect"]==False' "C1 no branch redirect recorded"
jassert "$RES" 'd["timestamps"]["started_at"] and d["timestamps"]["finished_at"]' "C1 timestamps present"
jassert "$RES" 'd["attempt"]["count"] is not None and d["attempt"]["max"]==2' "C1 attempt count/max recorded"
python3 -c "$JOPY
from jog_run import load_marathon_result
r = load_marathon_result('$RES')
assert r['outcome'] == 'approved'
" && pass "C1 load_marathon_result accepts the real receipt" || fail "C1 receipt failed Jog-side validation"

# C2 pre-dispatch refusal: default gate missing (fixture has no validate.sh, no --pre-advance-cmd)
cleanup_root_fixture
rm -f "$RES"
rm -f "$WORK/relay-drive-args"
(cd "$FR" && MARATHON_RELAY_DRIVE="$STUB_RD" CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
  bash "$FR/relay-automation/marathon-drive.sh" \
    --phases-dir "$FR/marathon-system" --phase-brief "$WORK/brief.md" \
    --reviewer agy --builder codex --result-file "$RES") >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "C2 missing gate refuses pre-dispatch (exit 2)" || fail "C2 missing-gate exit=$rc (expected 2)"
[ -f "$RES" ] && pass "C2 refusal still writes a receipt" || fail "C2 refusal wrote no receipt"
jassert "$RES" 'd["outcome"]=="refused" and d["reason"]=="pre-advance-gate-not-runnable"' "C2 receipt outcome refused + reason"
jassert "$RES" 'd["gate"]["result"]=="not-run"' "C2 gate result not-run"
[ ! -f "$WORK/relay-drive-args" ] && pass "C2 nothing dispatched (no builder/reviewer turn spent)" || fail "C2 relay-drive was invoked before the refusal"

# C3 gate failure after approval
cleanup_root_fixture; rm -f "$RES"
(cd "$FR" && RELAY_DRIVE_EXIT=0 MARATHON_RELAY_DRIVE="$STUB_RD" \
  CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
  bash "$FR/relay-automation/marathon-drive.sh" \
    --phases-dir "$FR/marathon-system" --phase-brief "$WORK/brief.md" \
    --reviewer agy --builder codex --pre-advance-cmd "bash $GATE_FAIL" \
    --result-file "$RES") >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "C3 gate failure exits 5" || fail "C3 gate-failure exit=$rc"
jassert "$RES" 'd["outcome"]=="escalated" and d["reason"]=="pre-advance-failed" and d["gate"]["result"]=="red"' "C3 receipt escalated/pre-advance-failed/gate red"

# C4 builder no-progress (relay-drive exit 3)
cleanup_root_fixture; rm -f "$RES"
RELAY_DRIVE_EXIT=3 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "C4 no-progress exits 3" || fail "C4 no-progress exit=$rc"
jassert "$RES" 'd["outcome"]=="escalated" and d["reason"]=="no-progress"' "C4 receipt reason no-progress"

# C5 reviewer cap / close mismatch (relay-drive exit 4)
cleanup_root_fixture; rm -f "$RES"
RELAY_DRIVE_EXIT=4 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "C5 cap escalation exits 4" || fail "C5 cap exit=$rc"
jassert "$RES" 'd["outcome"]=="escalated" and d["reason"]=="cap-or-close-mismatch"' "C5 receipt reason cap-or-close-mismatch"

# C6 timeout with no artifact (relay-drive exit 7)
cleanup_root_fixture; rm -f "$RES"
RELAY_DRIVE_EXIT=7 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 7 ] && pass "C6 timeout exits 7" || fail "C6 timeout exit=$rc"
jassert "$RES" 'd["outcome"]=="escalated" and d["reason"]=="timeout-no-artifact"' "C6 receipt reason timeout-no-artifact"

# C7 relay failed before the gate ran (relay-drive exit 5, gate untouched)
cleanup_root_fixture; rm -f "$RES"
RELAY_DRIVE_EXIT=5 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "C7 relay-failure exits 5" || fail "C7 relay-failure exit=$rc"
jassert "$RES" 'd["outcome"]=="escalated" and d["reason"]=="relay-failed-before-gate" and d["gate"]["result"]=="not-run"' "C7 receipt reason relay-failed-before-gate, gate not-run"

# C8 lane parked at the attempt cap (exit 8) — attempt state visible in the receipt
cleanup_root_fixture; rm -f "$RES"
mkdir -p "$FR/.tick/attempts"
printf 'fire\nfire\n' > "$FR/.tick/attempts/p1"
RELAY_DRIVE_EXIT=0 run_md_root --result-file "$RES" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 8 ] && pass "C8 lane parked at attempt cap exits 8" || fail "C8 attempt-cap exit=$rc"
jassert "$RES" 'd["outcome"]=="parked" and d["reason"] and "attempt" in d["reason"]' "C8 receipt outcome parked, reason names the cap"
jassert "$RES" 'd["attempt"]["count"]==2 and d["attempt"]["max"]==2' "C8 receipt attempt count 2/2"

# C9 no --result-file → identical exit, no receipt, no new observable output
cleanup_root_fixture
rm -f "$RES"
RELAY_DRIVE_EXIT=0 run_md_root >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "C9 run without --result-file keeps exit 0" || fail "C9 no-option run exit=$rc"
[ ! -f "$RES" ] && pass "C9 no receipt written when option unused" || fail "C9 receipt appeared without the option"

# C10 malformed result path refused before dispatch
cleanup_root_fixture; rm -f "$WORK/relay-drive-args"
run_md_root --result-file "$FR/no/such/dir/r.json" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "C10 malformed --result-file refuses (exit 2)" || fail "C10 malformed path exit=$rc"
[ ! -f "$WORK/relay-drive-args" ] && pass "C10 malformed path dispatches nothing" || fail "C10 dispatched despite malformed path"

# C11 invalid execution id refused
cleanup_root_fixture
run_md_root --result-file "$RES" --execution-id "bad id with spaces" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "C11 invalid --execution-id refuses (exit 2)" || fail "C11 bad execution-id exit=$rc"

# C12 custom execution id + one-file re-run (atomic replace, still valid)
cleanup_root_fixture; rm -f "$RES"
RELAY_DRIVE_EXIT=0 run_md_root --result-file "$RES" --execution-id "gh280-exec-0001" >/dev/null 2>&1
jassert "$RES" 'd["execution_id"]=="gh280-exec-0001"' "C12 caller execution id recorded"
RELAY_DRIVE_EXIT=0 run_md_root --result-file "$RES" --execution-id "gh280-exec-0002" >/dev/null 2>&1
jassert "$RES" 'd["execution_id"]=="gh280-exec-0002"' "C12 re-run atomically replaces the receipt"

# ═══ D. protected-branch redirect + PR identity (root install) ════════════════════════════════
# The fixture checks out `development` (the integration branch the branch guard protects and
# marathon-closeout requires as PR base) — the same shape as this repo: origin/HEAD → main,
# work landing via development.
# D1: guard redirects development → lane branch, stub gh reports PR 42 → receipt carries identity
cleanup_root_fixture; rm -f "$RES"
git -C "$FR" checkout -q -b development
( cd "$FR" && GH_STUB_PR_JSON="$CANNED_PR" RELAY_DRIVE_EXIT=0 \
    env -u MARATHON_ALLOW_TRUNK_COMMIT SP_SUGGESTED_BRANCH="marathon/gh280-lane" \
    MARATHON_RELAY_DRIVE="$STUB_RD" CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
    bash "$FR/relay-automation/marathon-drive.sh" \
      --phases-dir "$FR/marathon-system" --phase-brief "$WORK/brief.md" \
      --reviewer agy --builder codex --pre-advance-cmd "bash $GATE_PASS" \
      --result-file "$RES" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "D1 redirected run exits 0" || fail "D1 redirected run exit=$rc"
git -C "$FR" show-ref --verify --quiet refs/heads/marathon/gh280-lane \
  && pass "D1 lane branch marathon/gh280-lane exists" || fail "D1 lane branch missing"
jassert "$RES" 'd["branch_redirect"]==True and d["base_branch"]=="development" and d["head_branch"]=="marathon/gh280-lane"' "D1 receipt records redirect base/head"
jassert "$RES" 'd["pr"]["number"]==42 and d["pr"]["state"]=="OPEN" and d["pr"]["url"]' "D1 receipt carries verified PR identity"
jassert "$RES" 'd["pr_note"] is None' "D1 no PR note on successful publication"

# D2: PR publication fails → phase stays green, PR identity explicit null + visible note
cleanup_root_fixture; rm -f "$RES"
git -C "$FR" checkout -q -b development
( cd "$FR" && GH_STUB_CREATE_FAIL=1 RELAY_DRIVE_EXIT=0 \
    env -u MARATHON_ALLOW_TRUNK_COMMIT SP_SUGGESTED_BRANCH="marathon/gh280-lane-2" \
    MARATHON_RELAY_DRIVE="$STUB_RD" CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
    bash "$FR/relay-automation/marathon-drive.sh" \
      --phases-dir "$FR/marathon-system" --phase-brief "$WORK/brief.md" \
      --reviewer agy --builder codex --pre-advance-cmd "bash $GATE_PASS" \
      --result-file "$RES" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "D2 PR-publication failure keeps the phase green (exit 0)" || fail "D2 best-effort PR failure changed the exit: $rc"
jassert "$RES" 'd["outcome"]=="approved" and d["pr"]["number"] is None' "D2 receipt approved with explicit null PR"
jassert "$RES" 'd["pr_note"] and "pr-publication-failed" in d["pr_note"]' "D2 receipt notes the failed publication"

# ═══ E. vendored .xyz installation shape ══════════════════════════════════════════════════════
PKV="$WORK/packet-vendored"
PFV_OUT="$(cd "$FV" && python3 "$FV/.xyz/utils/py/swarm_preflight.py" --gh-issue 901 --out "$PKV" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "E1 vendored preflight exits 0" || fail "E1 vendored preflight exit=$rc: $PFV_OUT"
INVV="$PKV/marathon-invocation.json"
jassert "$INVV" 'd["harness_home"]=="'"$FV"'/.xyz" and d["argv"][0]=="'"$FV"'/.xyz/relay-automation/marathon-drive.sh"' "E2 vendored artifact points inside .xyz"
jassert "$INVV" 'os.path.realpath(d["target_root"])==os.path.realpath("'"$FV"'")' "E3 vendored target_root is the consumer repo"

RESV="$WORK/md-result-vendored.json"; rm -f "$RESV"
( cd "$FV" && RELAY_DRIVE_EXIT=0 MARATHON_RELAY_DRIVE="$STUB_RD" \
    CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
    bash "$FV/.xyz/relay-automation/marathon-drive.sh" \
      --phases-dir "$FV/marathon-system" --phase-brief "$WORK/brief.md" \
      --reviewer agy --builder codex --pre-advance-cmd "bash $GATE_PASS" \
      --result-file "$RESV" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "E4 vendored drive exits 0 with receipt" || fail "E4 vendored drive exit=$rc"
jassert "$RESV" 'd["outcome"]=="approved" and os.path.realpath(d["target_repo"]["path"])==os.path.realpath("'"$FV"'")' "E5 vendored receipt target_repo is the consumer repo"

# E6 vendored pre-dispatch refusal receipt
rm -f "$RESV"
( cd "$FV" && MARATHON_RELAY_DRIVE="$STUB_RD" CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
    bash "$FV/.xyz/relay-automation/marathon-drive.sh" \
      --phases-dir "$FV/marathon-system" --phase-brief "$WORK/brief.md" \
      --reviewer agy --builder codex --result-file "$RESV" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "E6 vendored refusal exits 2" || fail "E6 vendored refusal exit=$rc"
jassert "$RESV" 'd["outcome"]=="refused"' "E7 vendored refusal receipt written"

# ═══ F. real Preflight → Marathon → Relay chain with deterministic agent stubs ════════════════
# The packet's own argv is executed verbatim (minus PATH control): REAL relay-drive, REAL
# marathon-agent routing, stubbed codex/agy CLIs that approve — never --simulate.
cleanup_root_fixture
AGENT_BIN="$WORK/agent-stubs"; mkdir -p "$AGENT_BIN"
cat > "$AGENT_BIN/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '\n### Round 1 · Builder · %s (stub)\nImplemented: test builder update\n' "$RELAY_AGENT" >> "$PWD/marathon-system/p1/RELAY.md"
printf 'module.exports = 2\n' > "$PWD/src/feature.js"
exit 0
EOF
cat > "$AGENT_BIN/agy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  whoami|models) printf 'agy-stub\n'; exit 0 ;;
esac
printf 'agy review stub\n'
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$PWD/marathon-system/p1/RELAY.md"; rm -f "$PWD/marathon-system/p1/RELAY.md.bak"
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/marathon-system/p1/RELAY.md"
exit 0
EOF
chmod +x "$AGENT_BIN/codex" "$AGENT_BIN/agy"
RESF="$PK/marathon-result.json"; rm -f "$RESF"
( cd "$FR" && PATH="$AGENT_BIN:$PATH" CODEX_BIN="$AGENT_BIN/codex" AGY_BIN="$AGENT_BIN/agy" \
    python3 - "$INV" <<'PY'
import json, os, subprocess, sys
inv = json.load(open(sys.argv[1]))
env = dict(os.environ)
# The packet suggests RELAY_WORKTREE_ISOLATION=1; this case pins the CONTRACT (argv is
# executable as data), so it runs the proven non-isolated stub-agent shape from
# test/marathon-drive.sh cases 17/18b. The isolated dispatch is exercised by the relay
# suites; adding it here would make the stubs' in-tree relay edits containment bait.
env.update({k: v for k, v in inv["env"].items() if k != "RELAY_WORKTREE_ISOLATION"})
rc = subprocess.run(inv["argv"], cwd=inv["target_root"], env=env).returncode
sys.exit(rc)
PY
) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "F1 real packet argv chain exits 0 (Preflight → Marathon → Relay)" || fail "F1 packet argv chain exit=$rc"
grep -q 'module.exports = 2' "$FR/src/feature.js" \
  && pass "F2 stub builder landed the declared artifact" || fail "F2 artifact not built by the chain"
[ -f "$RESF" ] && pass "F3 chain wrote the packet's result receipt" || fail "F3 no receipt at the packet's result_path"
jassert "$RESF" 'd["outcome"]=="approved" and d["relay_status"]=="Approved"' "F4 receipt approved with relay STATUS Approved"
jassert "$RESF" 'd["gate"]["result"]=="green"' "F5 gate ran green inside the chain"
find "$FR/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"codex"' >/dev/null 2>&1 \
  && pass "F6 builder claim event in the fixture tick log" || fail "F6 missing builder claim event"
find "$FR/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"agy"' >/dev/null 2>&1 \
  && pass "F7 reviewer claim event in the fixture tick log" || fail "F7 missing reviewer claim event"

# ═══ G. Phase 2: `releases jog run --executor marathon` (root install) ════════════════════════
# Deterministic agent stubs that discover the relay file rather than hardcoding a phase dir —
# the marathon executor dispatches the packet's slug as the phase id.
JOG_AGENTS="$WORK/jog-agent-stubs"; mkdir -p "$JOG_AGENTS"
cat > "$JOG_AGENTS/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
relay="$(find "$PWD/marathon-system" -name RELAY.md -type f | head -1)"
printf '\n### Round 1 · Builder · %s (stub)\nImplemented: test builder update\n' "$RELAY_AGENT" >> "$relay"
printf 'module.exports = 2\n' > "$PWD/src/feature.js"
exit 0
EOF
cat > "$JOG_AGENTS/agy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  whoami|models) printf 'agy-stub\n'; exit 0 ;;
esac
relay="$(find "$PWD/marathon-system" -name RELAY.md -type f | head -1)"
printf 'agy review stub\n'
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$relay"; rm -f "$relay.bak"
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$relay"
exit 0
EOF
cat > "$JOG_AGENTS/agy-refuse" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  whoami|models) printf 'agy-stub\n'; exit 0 ;;
esac
relay="$(find "$PWD/marathon-system" -name RELAY.md -type f | head -1)"
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Changes requested\nBasis: test reviewer refusal\n' "$RELAY_AGENT" >> "$relay"
exit 0
EOF
chmod +x "$JOG_AGENTS/codex" "$JOG_AGENTS/agy" "$JOG_AGENTS/agy-refuse"

queue_status() {  # <root> → "status|reason|attempt_count"
  sqlite3 "$1/releases.db" "SELECT status || '|' || COALESCE(failure_reason,'') || '|' || COALESCE(attempt_count,0) FROM jog_queue WHERE gh_number = 901;"
}

jog_run_root() {  # <extra-args…> — jog run against the ROOT fixture's own releases_app
  ( cd "$FR" && PATH="$JOG_AGENTS:$PATH" CODEX_BIN="$JOG_AGENTS/codex" \
    python3 "$FR/utils/py/releases_app.py" --root "$FR" jog run "$@" )
}

# G1-G3: reviewer validation fails BEFORE lease mutation (row untouched)
cleanup_root_fixture
rm -rf "$FR/.tick/jog"
OUT_G1="$(jog_run_root --executor marathon --builder codex 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "G1 marathon executor without --reviewer refuses (exit 2)" || fail "G1 exit=$rc: $OUT_G1"
grep -q "required with --executor marathon" <<<"$OUT_G1" && pass "G1 refusal names the reviewer policy" || fail "G1 refusal message drifted: $OUT_G1"
has "$(queue_status "$FR")" "pending||0" && pass "G1 row untouched (pending, attempt_count 0)" || fail "G1 row mutated: $(queue_status "$FR")"
OUT_G2="$(jog_run_root --executor marathon --builder codex --reviewer codex 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$(queue_status "$FR")" "pending||0" \
  && pass "G2 reviewer == builder refused before lease" || fail "G2 exit=$rc row=$(queue_status "$FR")"
OUT_G3="$(AGY_BIN="$WORK/no-such-agy-bin" jog_run_root --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$(queue_status "$FR")" "pending||0" \
  && pass "G3 unavailable reviewer binary refused before lease" || fail "G3 exit=$rc row=$(queue_status "$FR")"

# G4: full happy path — Preflight → Marathon (real relay-drive, isolated) → receipt → projection
cleanup_root_fixture
git -C "$FR" checkout -q -b development
GID="$(sqlite3 "$FR/releases.db" "SELECT global_id FROM jog_queue WHERE gh_number = 901;")"
G4_OUT="$(GH_STUB_PR_JSON="$CANNED_PR" \
  env -u MARATHON_ALLOW_TRUNK_COMMIT SP_SUGGESTED_BRANCH="marathon/gh280-jog-lane" \
  PATH="$JOG_AGENTS:$PATH" CODEX_BIN="$JOG_AGENTS/codex" AGY_BIN="$JOG_AGENTS/agy" \
  python3 "$FR/utils/py/releases_app.py" --root "$FR" jog run \
    --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "G4 marathon executor queue run exits 0" || fail "G4 queue run exit=$rc: $G4_OUT"
has "$(queue_status "$FR")" "parked|awaiting-landing (PR #42" \
  && pass "G4 row parked awaiting-landing with receipt PR identity" || fail "G4 row: $(queue_status "$FR")"
GSTATE="$FR/.tick/jog/$GID/state.json"
[ -f "$GSTATE" ] && pass "G4 execution ledger exists under .tick/jog/<gid>" || fail "G4 no ledger at $GSTATE"
jassert "$GSTATE" 'len(d["executions"])==1 and d["executions"][0]["status"]=="projected-parked" and d["executions"][0]["outcome"]=="approved"' "G4 ledger records one approved, projected execution"
GRES="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["executions"][0]["result_path"])' "$GSTATE")"
jassert "$GRES" 'd["outcome"]=="approved" and d["pr"]["number"]==42 and d["branch_redirect"]==True and d["head_branch"]=="marathon/gh280-jog-lane"' "G4 receipt approved, PR 42, redirected lane branch"
grep -q 'module.exports = 2' "$FR/src/feature.js" \
  && pass "G4 stub builder landed the artifact through the real chain" || fail "G4 artifact not built"

# G5: controlled failure — reviewer refuses every round → escalated receipt → row failed, queue stops
cleanup_root_fixture
python3 "$FR/utils/py/releases_app.py" --root "$FR" jog retry 901 >/dev/null 2>&1
G5_OUT="$(env -u MARATHON_ALLOW_TRUNK_COMMIT SP_SUGGESTED_BRANCH="marathon/gh280-jog-lane-5" \
  PATH="$JOG_AGENTS:$PATH" CODEX_BIN="$JOG_AGENTS/codex" AGY_BIN="$JOG_AGENTS/agy-refuse" \
  python3 "$FR/utils/py/releases_app.py" --root "$FR" jog run \
    --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
QS="$(queue_status "$FR")"
case "$QS" in
  failed\|marathon\ escalated:*) pass "G5 refusing reviewer → row failed with marathon escalation" ;;
  *) fail "G5 unexpected row state: $QS" ;;
esac
G5_RES="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["executions"][0]["result_path"])' "$GSTATE" 2>/dev/null)"
[ -n "$G5_RES" ] && jassert "$G5_RES" 'd["outcome"]=="escalated"' "G5 receipt outcome escalated"

# G6: cold start after dispatch with NO result → parked, never a silent refire
cleanup_root_fixture
GID="$(sqlite3 "$FR/releases.db" "SELECT global_id FROM jog_queue WHERE gh_number = 901;")"
mkdir -p "$FR/.tick/jog/$GID"
cat > "$FR/.tick/jog/$GID/state.json" <<JSEOF
{"schema": "jog/execution-state@1", "gid": "$GID", "gh_number": 901,
 "executions": [{"execution_id": "gh901-exec1", "mode": "run", "started_at": "2026-08-28T00:00:00Z",
                 "status": "dispatched", "packet_dir": "$FR/.tick/jog/$GID/gh901-exec1/preflight",
                 "result_path": "$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json"}]}
JSEOF
sqlite3 "$FR/releases.db" "UPDATE jog_queue SET status = 'running', lease_pid = 999999 WHERE gh_number = 901;"
G6_OUT="$(jog_run_root --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
QS="$(queue_status "$FR")"
case "$QS" in
  parked\|cold-start:*) pass "G6 cold-start without result parks (never refires)" ;;
  *) fail "G6 unexpected row state: $QS" ;;
esac
jassert "$GSTATE" 'len(d["executions"])==1' "G6 no second execution fired on cold start"

# G7: cold start with a valid terminal result → idempotent re-projection, no new turn
# (state is re-fabricated as dispatched: G6 legitimately moved it to cold-start-paused)
mkdir -p "$FR/.tick/jog/$GID/gh901-exec1/preflight"
cat > "$FR/.tick/jog/$GID/state.json" <<JSEOF
{"schema": "jog/execution-state@1", "gid": "$GID", "gh_number": 901,
 "executions": [{"execution_id": "gh901-exec1", "mode": "run", "started_at": "2026-08-28T00:00:00Z",
                 "status": "dispatched", "packet_dir": "$FR/.tick/jog/$GID/gh901-exec1/preflight",
                 "result_path": "$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json"}]}
JSEOF
cat > "$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json" <<JREOF
{"schema": "marathon-drive/result@1", "execution_id": "gh901-exec1", "generated_at": "2026-08-28T00:00:01Z",
 "outcome": "approved", "reason": "approved, gate passed", "exit_code": 0, "approval_preserved": false,
 "issue": "901", "phase": "p", "lane": "p", "token": "T", "attempt": {"count": 1, "max": 2},
 "builder": "codex", "reviewer": "agy",
 "target_repo": {"path": "$FR", "origin_url": null},
 "base_branch": "development", "head_branch": "marathon/x", "head_sha": "deadbeef",
 "branch_redirect": true,
 "gate": {"cmd": "true", "result": "green", "exit": 0, "receipt_path": null},
 "acceptance": {"checked": false, "unmet_count": 0},
 "pr": {"number": 7, "url": "https://example.invalid/x/pr/7", "state": "OPEN"},
 "pr_note": null, "relay_status": "Approved",
 "timestamps": {"started_at": "2026-08-28T00:00:00Z", "finished_at": "2026-08-28T00:00:01Z"}}
JREOF
sqlite3 "$FR/releases.db" "UPDATE jog_queue SET status = 'running', lease_pid = 999999 WHERE gh_number = 901;"
G7_OUT="$(jog_run_root --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
has "$(queue_status "$FR")" "parked|awaiting-landing (PR #7" \
  && pass "G7 cold-start re-projects the terminal result idempotently" || fail "G7 row: $(queue_status "$FR")"
jassert "$GSTATE" 'len(d["executions"])==1' "G7 re-projection fired no new execution"

# G8: preflight refusal parks the row with the preflight exit
cleanup_root_fixture
rm -f "$FR/PROJECT/2-WORKING/$CAPTURE_DOC_NAME"
git -C "$FR" add -A >/dev/null 2>&1; git -C "$FR" commit -qm "remove capture doc" >/dev/null 2>&1
G8_OUT="$(jog_run_root --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
QS="$(queue_status "$FR")"
case "$QS" in
  parked\|preflight-refused\ \(exit\ 6\)*) pass "G8 preflight refusal parks with exit code" ;;
  *) fail "G8 unexpected row state: $QS" ;;
esac

# ═══ H. Phase 2 vendored: jog run --executor marathon from a foreign cwd ══════════════════════
H_CWD="$WORK/foreign-cwd"; mkdir -p "$H_CWD"
GIDV="$(sqlite3 "$FV/releases.db" "SELECT global_id FROM jog_queue WHERE gh_number = 901;")"
H_OUT="$( cd "$H_CWD" && PATH="$JOG_AGENTS:$PATH" CODEX_BIN="$JOG_AGENTS/codex" AGY_BIN="$JOG_AGENTS/agy" \
  python3 "$FV/.xyz/utils/py/releases_app.py" --root "$FV" jog run \
    --executor marathon --builder codex --reviewer agy 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "H1 vendored marathon queue run exits 0 from a foreign cwd" || fail "H1 exit=$rc: $H_OUT"
QS="$(queue_status "$FV")"
case "$QS" in
  parked\|awaiting-landing\ \(no\ PR\ yet*) pass "H2 vendored row parked awaiting-landing (green, no PR)" ;;
  *) fail "H2 unexpected vendored row state: $QS" ;;
esac
HSTATE="$FV/.tick/jog/$GIDV/state.json"
[ -f "$HSTATE" ] && pass "H3 vendored execution ledger lives in the consumer repo" || fail "H3 no ledger at $HSTATE"
HRES="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["executions"][0]["result_path"])' "$HSTATE" 2>/dev/null)"
[ -n "$HRES" ] && [ -f "$HRES" ] && jassert "$HRES" 'd["outcome"]=="approved" and os.path.realpath(d["target_repo"]["path"])==os.path.realpath("'"$FV"'")' "H4 vendored receipt approved, target is the consumer repo"
[ ! -d "$H_CWD/marathon-system" ] && [ ! -d "$H_CWD/relay-system" ] && [ ! -d "$H_CWD/.tick" ] \
  && pass "H5 foreign cwd stayed clean (no root-relative lookups — GH-279 #2)" \
  || fail "H5 foreign cwd grew harness output dirs"

# ═══ I. legacy relay default unchanged ════════════════════════════════════════════════════════
cleanup_root_fixture
python3 "$FR/utils/py/releases_app.py" --root "$FR" jog add 902 >/dev/null 2>&1
I_OUT="$(jog_run_root --simulate --auto-merge --max-tasks 1 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && has "$I_OUT" "simulated single-phase drive on GH-901" \
  && pass "I1 default executor (relay) simulate path unchanged" || fail "I1 legacy simulate path drifted: $(printf '%s' "$I_OUT" | head -3)"
sqlite3 "$FR/releases.db" "SELECT status FROM jog_queue WHERE gh_number = 901;" | grep -q completed \
  && pass "I1b simulated auto-merge completes the processed row" || fail "I1b row 901 not completed"
[ ! -d "$FR/.tick/jog" ] && pass "I2 legacy run leaves no marathon execution state" || fail "I2 marathon state created without --executor marathon"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
