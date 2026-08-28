#!/usr/bin/env bash
# gh290-ate-variation-grid.sh — GH-290: ATE variation grid for Jog machine contracts.
#
# Deterministic variation matrix covering Jog ↔ Marathon machine contracts (GH-280):
#   - Target 1: Contract loaders (load_marathon_invocation, load_marathon_result, _load_contract_json)
#               Vary: malformed JSON, schema@2+, missing keys, type confusion, nulls, non-absolute
#               argv[0], non-executable drive path, directory vs file, list-vs-dict shapes.
#               Invariant: ContractError raised on 100% of hostile inputs; no uncaught exceptions;
#               never dispatches or mutates leases.
#   - Target 2: Landing verification (jog_run.jog_land checks)
#               Vary generated receipt × PR pairs: wrong base/head/headRefOid/repo, non-MERGED PR states,
#               unreachable merge SHAs, red/absent gate evidence, unparseable PR metadata, missing PR ID.
#               Invariant: Every mismatch class refuses with exit 2 and leaves queue row untouched.
#   - Target 3: Receipt writer robustness (utils/py/marathon_drive.py: write_terminal_result)
#               Vary hostile git/gh output shapes (empty output, bare arrays, non-JSON, corrupted JSON,
#               detached HEAD, missing binaries) across approved/refused/escalated/parked/interrupted/
#               crashed/lock-contention/post-approve-failed outcomes.
#               Invariant: Never raises, never modifies exit code, always writes exactly one valid
#               marathon-drive/result@1 receipt.
source "$(dirname "$0")/_setup.sh" gh290-ate-variation-grid
unset MARATHON_LANE_NS MARATHON_ROOT MARATHON_RELAY_DRIVE MARATHON_AGENT_CMD TICK_BIN
REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ── deterministic GitHub shim: logs every call, canned PR answers ─────────────────────────────
STUB_BIN="$WORK/stub-bin"
mkdir -p "$STUB_BIN"
GH_STUB_LOG="$WORK/gh-stub-calls.log"
export GH_STUB_LOG
GH_STUB_PR_JSON="${GH_STUB_PR_JSON:-}"
export GH_STUB_PR_JSON
GH_STUB_PR_VIEW_JSON="${GH_STUB_PR_VIEW_JSON:-}"
export GH_STUB_PR_VIEW_JSON
GH_STUB_VIEW_FAIL="${GH_STUB_VIEW_FAIL:-0}"
export GH_STUB_VIEW_FAIL
GH_STUB_LIST_RAW="${GH_STUB_LIST_RAW:-}"
export GH_STUB_LIST_RAW

cat > "$STUB_BIN/gh" <<'GH_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"
if [ "${1:-}" = "auth" ]; then exit 0; fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "list" ]; then
  if [ -n "${GH_STUB_LIST_RAW:-}" ]; then
    printf '%s\n' "$GH_STUB_LIST_RAW"
    exit 0
  fi
  for a in "$@"; do
    if [ "$a" = "number,url,state" ]; then
      if [ -n "${GH_STUB_PR_JSON:-}" ] && [ -s "$GH_STUB_PR_JSON" ]; then cat "$GH_STUB_PR_JSON"; else echo "[]"; fi
      exit 0
    fi
  done
  if [ -n "${GH_STUB_PR_JSON:-}" ] && [ -s "$GH_STUB_PR_JSON" ]; then
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d[0]["url"] if d else "")' "$GH_STUB_PR_JSON"
  else
    echo ""
  fi
  exit 0
fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "view" ]; then
  if [ "${GH_STUB_VIEW_FAIL:-0}" = "1" ]; then
    echo "gh: pull request not found or connection failed" >&2
    exit 1
  fi
  if [ -n "${GH_STUB_PR_VIEW_JSON:-}" ] && [ -f "${GH_STUB_PR_VIEW_JSON:-}" ]; then
    cat "$GH_STUB_PR_VIEW_JSON"
    exit 0
  fi
  exit 1
fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "create" ]; then
  echo "https://example.invalid/pr/created-by-stub"
  exit 0
fi
exit 1
GH_EOF
chmod +x "$STUB_BIN/gh"
export PATH="$STUB_BIN:$PATH"

# json-field assertion helper
jassert() {
  python3 -c 'import json,sys,os,subprocess
d = json.load(open(sys.argv[1]))
sys.exit(0 if eval(sys.argv[2]) else 1)' "$1" "$2" 2>/dev/null \
    && pass "$3" || fail "$3 ($(head -c 400 "$1" 2>/dev/null))"
}

# fixed-substring helper
has() { printf '%s' "$1" | grep -Fq -- "$2"; }

# ═════════════════════════════════════════════════════════════════════════════════════════════
# TARGET 1: Contract Loaders (load_marathon_invocation, load_marathon_result, _load_contract_json)
# ═════════════════════════════════════════════════════════════════════════════════════════════
echo "--- Section 1: Target 1 — Contract Loaders Variation Matrix ---"

JOPY="import sys, os; sys.path.insert(0, '$REPO/utils/py')"

# Run comprehensive loader variation matrix via embedded python runner
python3 - "$REPO" "$WORK" <<'PY_TARGET1'
import sys, os, json, copy, tempfile

repo_root = sys.argv[1]
work_dir = sys.argv[2]
sys.path.insert(0, os.path.join(repo_root, "utils", "py"))

from jog_run import (
    load_marathon_invocation,
    load_marathon_result,
    _load_contract_json,
    ContractError,
    MARATHON_INVOCATION_SCHEMA,
    MARATHON_RESULT_SCHEMA,
)

# Dummy valid files and directories for invocation testing
dummy_harness_root = os.path.join(work_dir, "t1_harness_root")
dummy_target_root = os.path.join(work_dir, "t1_target_root")
dummy_packet_dir = os.path.join(work_dir, "t1_packet_dir")
os.makedirs(dummy_harness_root, exist_ok=True)
os.makedirs(dummy_target_root, exist_ok=True)
os.makedirs(dummy_packet_dir, exist_ok=True)

dummy_packet_path = os.path.join(dummy_packet_dir, "packet.md")
with open(dummy_packet_path, "w") as f:
    f.write("# Dummy Packet\n")

dummy_drive_cmd = os.path.join(work_dir, "dummy_marathon_drive.sh")
with open(dummy_drive_cmd, "w") as f:
    f.write("#!/bin/sh\nexit 0\n")
os.chmod(dummy_drive_cmd, 0o755)

non_exec_drive = os.path.join(work_dir, "non_exec_drive.sh")
with open(non_exec_drive, "w") as f:
    f.write("#!/bin/sh\nexit 0\n")
os.chmod(non_exec_drive, 0o644)

dummy_result_path = os.path.join(dummy_packet_dir, "marathon-result.json")

base_valid_invocation = {
    "schema": MARATHON_INVOCATION_SCHEMA,
    "argv": [dummy_drive_cmd, "--result-file", dummy_result_path],
    "env": {
        "XYZ_HARNESS_CONTEXT": "swarm",
        "XYZ_SESSION_ID": "session-123",
        "RELAY_WORKTREE_ISOLATION": "1"
    },
    "harness_root": dummy_harness_root,
    "target_root": dummy_target_root,
    "packet_path": dummy_packet_path,
    "packet_dir": dummy_packet_dir,
    "result_path": dummy_result_path,
    "issue": "901",
    "phase": "p1",
    "lane": "p1",
    "gate": "bash test/fixture-gate.sh",
    "builder": "codex",
    "reviewer": "agy",
    "base_ref": "main",
    "artifacts": ["src/feature.js"]
}

base_valid_result = {
    "schema": MARATHON_RESULT_SCHEMA,
    "execution_id": "gh901-exec1",
    "generated_at": "2026-08-28T02:00:00Z",
    "outcome": "approved",
    "reason": "approved",
    "exit_code": 0,
    "approval_preserved": False,
    "issue": "901",
    "phase": "p1",
    "lane": "p1",
    "token": "MARATHON-P1-TURN",
    "attempt": {"count": 1, "max": 2},
    "builder": "codex",
    "reviewer": "agy",
    "target_repo": {"path": dummy_target_root, "origin_url": None},
    "base_branch": "development",
    "head_branch": "marathon/gh280-lane",
    "head_sha": "deadbeef12345678",
    "branch_redirect": True,
    "gate": {"cmd": "true", "result": "green", "exit": 0, "receipt_path": None},
    "acceptance": {"checked": False, "unmet_count": 0},
    "pr": {"number": 42, "url": "https://example.invalid/x/pr/42", "state": "OPEN"},
    "pr_note": None,
    "relay_status": "Approved",
    "timestamps": {"started_at": "2026-08-28T01:59:00Z", "finished_at": "2026-08-28T02:00:00Z"}
}

# 1. Sanity check: valid fixtures load cleanly
tmp_inv = os.path.join(work_dir, "t1_valid_inv.json")
with open(tmp_inv, "w") as f:
    json.dump(base_valid_invocation, f, indent=2)
inv_loaded = load_marathon_invocation(tmp_inv)
assert inv_loaded["issue"] == "901"
print("  PASS: T1.0 base valid marathon invocation loaded cleanly")

tmp_res = os.path.join(work_dir, "t1_valid_res.json")
with open(tmp_res, "w") as f:
    json.dump(base_valid_result, f, indent=2)
res_loaded = load_marathon_result(tmp_res)
assert res_loaded["outcome"] == "approved"
print("  PASS: T1.0 base valid marathon result loaded cleanly")

# 2. Invocation Loader Mutation Variations
inv_variations = []

# Malformed JSON
inv_variations.append(("T1.1.1 malformed JSON (truncated)", '{"schema": "swarm-preflight/marathon-invocation@1", "argv": ['))
inv_variations.append(("T1.1.2 malformed JSON (empty file)", ''))
inv_variations.append(("T1.1.3 malformed JSON (non-JSON text)", '<html><body>Not JSON</body></html>'))
inv_variations.append(("T1.1.4 malformed JSON (trailing comma)", '{"schema": "swarm-preflight/marathon-invocation@1",}'))

# Top-level shape
inv_variations.append(("T1.1.5 top-level array instead of dict", [base_valid_invocation]))
inv_variations.append(("T1.1.6 top-level string instead of dict", "some-string"))
inv_variations.append(("T1.1.7 top-level int instead of dict", 12345))

# Schema variations
def mutate_inv(fn):
    d = copy.deepcopy(base_valid_invocation)
    fn(d)
    return d

inv_variations.append(("T1.2.1 schema version @2 refused", mutate_inv(lambda d: d.update(schema="swarm-preflight/marathon-invocation@2"))))
inv_variations.append(("T1.2.2 schema version @0 refused", mutate_inv(lambda d: d.update(schema="swarm-preflight/marathon-invocation@0"))))
inv_variations.append(("T1.2.3 wrong schema name refused", mutate_inv(lambda d: d.update(schema="marathon-drive/result@1"))))
inv_variations.append(("T1.2.4 missing schema field refused", mutate_inv(lambda d: d.pop("schema"))))
inv_variations.append(("T1.2.5 null schema field refused", mutate_inv(lambda d: d.update(schema=None))))
inv_variations.append(("T1.2.6 integer schema field refused", mutate_inv(lambda d: d.update(schema=1))))
inv_variations.append(("T1.2.7 dict schema field refused", mutate_inv(lambda d: d.update(schema={"name": "v1"}))))

# Argv variations
inv_variations.append(("T1.3.1 missing argv refused", mutate_inv(lambda d: d.pop("argv"))))
inv_variations.append(("T1.3.2 empty argv list refused", mutate_inv(lambda d: d.update(argv=[]))))
inv_variations.append(("T1.3.3 non-list argv refused", mutate_inv(lambda d: d.update(argv="marathon-drive.sh"))))
inv_variations.append(("T1.3.4 argv with integer item refused", mutate_inv(lambda d: d.update(argv=[dummy_drive_cmd, 123]))))
inv_variations.append(("T1.3.5 argv with empty string item refused", mutate_inv(lambda d: d.update(argv=[dummy_drive_cmd, ""]))))
inv_variations.append(("T1.3.6 relative argv[0] refused", mutate_inv(lambda d: d.update(argv=["relay-automation/marathon-drive.sh"]))))
inv_variations.append(("T1.3.7 dot-relative argv[0] refused", mutate_inv(lambda d: d.update(argv=["./marathon-drive.sh"]))))
inv_variations.append(("T1.3.8 nonexistent argv[0] refused", mutate_inv(lambda d: d.update(argv=["/nonexistent/drive/path.sh"]))))
inv_variations.append(("T1.3.9 non-executable argv[0] refused", mutate_inv(lambda d: d.update(argv=[non_exec_drive]))))
inv_variations.append(("T1.3.10 directory argv[0] refused", mutate_inv(lambda d: d.update(argv=[dummy_harness_root]))))

# Env variations
inv_variations.append(("T1.4.1 missing env refused", mutate_inv(lambda d: d.pop("env"))))
inv_variations.append(("T1.4.2 non-dict env refused", mutate_inv(lambda d: d.update(env=["XYZ_VAR=1"]))))
inv_variations.append(("T1.4.3 env with non-string value refused", mutate_inv(lambda d: d.update(env={"XYZ_VAR": 123}))))
inv_variations.append(("T1.4.4 env with null value refused", mutate_inv(lambda d: d.update(env={"XYZ_VAR": None}))))

# Path resolution and directory variations
inv_variations.append(("T1.5.1 missing harness_root refused", mutate_inv(lambda d: d.pop("harness_root"))))
inv_variations.append(("T1.5.2 empty harness_root refused", mutate_inv(lambda d: d.update(harness_root=""))))
inv_variations.append(("T1.5.3 nonexistent harness_root refused", mutate_inv(lambda d: d.update(harness_root="/nonexistent/harness_root"))))
inv_variations.append(("T1.5.4 file harness_root refused (must be dir)", mutate_inv(lambda d: d.update(harness_root=dummy_packet_path))))
inv_variations.append(("T1.5.5 path traversal non-resolving harness_root refused", mutate_inv(lambda d: d.update(harness_root="/tmp/../../nonexistent/path"))))

inv_variations.append(("T1.5.6 missing target_root refused", mutate_inv(lambda d: d.pop("target_root"))))
inv_variations.append(("T1.5.7 empty target_root refused", mutate_inv(lambda d: d.update(target_root=""))))
inv_variations.append(("T1.5.8 nonexistent target_root refused", mutate_inv(lambda d: d.update(target_root="/nonexistent/target_root"))))
inv_variations.append(("T1.5.9 file target_root refused (must be dir)", mutate_inv(lambda d: d.update(target_root=dummy_packet_path))))

inv_variations.append(("T1.5.10 missing packet_path refused", mutate_inv(lambda d: d.pop("packet_path"))))
inv_variations.append(("T1.5.11 empty packet_path refused", mutate_inv(lambda d: d.update(packet_path=""))))
inv_variations.append(("T1.5.12 nonexistent packet_path refused", mutate_inv(lambda d: d.update(packet_path="/nonexistent/packet.md"))))
inv_variations.append(("T1.5.13 directory packet_path refused (must be file)", mutate_inv(lambda d: d.update(packet_path=dummy_packet_dir))))

# Required fields missing one-by-one
for req_field in ("issue", "phase", "lane", "gate", "builder", "reviewer", "base_ref", "result_path", "packet_dir"):
    inv_variations.append((f"T1.6 missing required field {req_field!r} refused", mutate_inv(lambda d, f=req_field: d.pop(f))))

# Artifacts variations
inv_variations.append(("T1.7.1 missing artifacts refused", mutate_inv(lambda d: d.pop("artifacts"))))
inv_variations.append(("T1.7.2 non-list artifacts refused", mutate_inv(lambda d: d.update(artifacts="src/feature.js"))))
inv_variations.append(("T1.7.3 null artifacts refused", mutate_inv(lambda d: d.update(artifacts=None))))

# Run invocation variations
inv_pass_count = 0
inv_fail_count = 0
soft_fail = os.environ.get("TEST_SOFT_FAIL") == "1"

for label, payload in inv_variations:
    tmp_path = os.path.join(work_dir, "t1_inv_mutation.json")
    if isinstance(payload, str):
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(payload)
    else:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(payload, f)
    try:
        load_marathon_invocation(tmp_path)
        print(f"  FAIL: {label} (unexpectedly succeeded!)", file=sys.stderr)
        inv_fail_count += 1
        if not soft_fail:
            sys.exit(1)
    except ContractError:
        inv_pass_count += 1
        print(f"  PASS: {label}")
    except Exception as exc:
        print(f"  FAIL: {label} (raised unexpected exception {exc.__class__.__name__}: {exc})", file=sys.stderr)
        inv_fail_count += 1
        if not soft_fail:
            sys.exit(1)


# 3. Result Loader Mutation Variations
def mutate_res(fn):
    d = copy.deepcopy(base_valid_result)
    fn(d)
    return d

res_variations = []

# Malformed JSON & Shapes
res_variations.append(("T1.8.1 result malformed JSON (truncated)", '{"schema": "marathon-drive/result@1", "outcome": '))
res_variations.append(("T1.8.2 result malformed JSON (empty)", ''))
res_variations.append(("T1.8.3 result malformed JSON (non-JSON)", 'Error: process died unexpectedly'))
res_variations.append(("T1.8.4 result top-level array instead of dict", [base_valid_result]))
res_variations.append(("T1.8.5 result top-level string instead of dict", "result-as-string"))

# Schema variations
res_variations.append(("T1.9.1 result schema @2 refused", mutate_res(lambda d: d.update(schema="marathon-drive/result@2"))))
res_variations.append(("T1.9.2 result schema @0 refused", mutate_res(lambda d: d.update(schema="marathon-drive/result@0"))))
res_variations.append(("T1.9.3 result wrong schema name refused", mutate_res(lambda d: d.update(schema="swarm-preflight/marathon-invocation@1"))))
res_variations.append(("T1.9.4 result missing schema field refused", mutate_res(lambda d: d.pop("schema"))))
res_variations.append(("T1.9.5 result null schema field refused", mutate_res(lambda d: d.update(schema=None))))

# Execution ID variations
res_variations.append(("T1.10.1 missing execution_id refused", mutate_res(lambda d: d.pop("execution_id"))))
res_variations.append(("T1.10.2 empty execution_id refused", mutate_res(lambda d: d.update(execution_id=""))))
res_variations.append(("T1.10.3 integer execution_id refused", mutate_res(lambda d: d.update(execution_id=123))))
res_variations.append(("T1.10.4 null execution_id refused", mutate_res(lambda d: d.update(execution_id=None))))

# Exit code variations (bool confusion, string, float, null)
res_variations.append(("T1.11.1 missing exit_code refused", mutate_res(lambda d: d.pop("exit_code"))))
res_variations.append(("T1.11.2 boolean exit_code (True) refused", mutate_res(lambda d: d.update(exit_code=True))))
res_variations.append(("T1.11.3 boolean exit_code (False) refused", mutate_res(lambda d: d.update(exit_code=False))))
res_variations.append(("T1.11.4 string exit_code ('0') refused", mutate_res(lambda d: d.update(exit_code="0"))))
res_variations.append(("T1.11.5 float exit_code (0.0) refused", mutate_res(lambda d: d.update(exit_code=0.0))))
res_variations.append(("T1.11.6 null exit_code refused", mutate_res(lambda d: d.update(exit_code=None))))
res_variations.append(("T1.11.7 list exit_code refused", mutate_res(lambda d: d.update(exit_code=[0]))))

# Outcome variations
res_variations.append(("T1.12.1 missing outcome refused", mutate_res(lambda d: d.pop("outcome"))))
res_variations.append(("T1.12.2 empty outcome refused", mutate_res(lambda d: d.update(outcome=""))))
res_variations.append(("T1.12.3 integer outcome refused", mutate_res(lambda d: d.update(outcome=0))))
res_variations.append(("T1.12.4 null outcome refused", mutate_res(lambda d: d.update(outcome=None))))

# Required fields missing one-by-one (17 required keys in load_marathon_result)
for req_field in (
    "execution_id", "outcome", "reason", "exit_code", "issue", "phase", "lane", "token", "attempt",
    "target_repo", "base_branch", "head_branch", "head_sha", "gate", "acceptance", "pr", "timestamps"
):
    res_variations.append((f"T1.13 missing result required field {req_field!r} refused", mutate_res(lambda d, f=req_field: d.pop(f))))

# Object type enforcement for dict fields
for obj_field in ("target_repo", "gate", "attempt", "pr", "timestamps"):
    res_variations.append((f"T1.14.1 {obj_field} as string refused", mutate_res(lambda d, f=obj_field: d.update({f: "not-a-dict"}))))
    res_variations.append((f"T1.14.2 {obj_field} as list refused", mutate_res(lambda d, f=obj_field: d.update({f: []}))))
    res_variations.append((f"T1.14.3 {obj_field} as integer refused", mutate_res(lambda d, f=obj_field: d.update({f: 123}))))
    res_variations.append((f"T1.14.4 {obj_field} as null refused", mutate_res(lambda d, f=obj_field: d.update({f: None}))))

# Run result variations
res_pass_count = 0
res_fail_count = 0
for label, payload in res_variations:
    tmp_path = os.path.join(work_dir, "t1_res_mutation.json")
    if isinstance(payload, str):
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(payload)
    else:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(payload, f)
    try:
        load_marathon_result(tmp_path)
        print(f"  FAIL: {label} (unexpectedly succeeded!)", file=sys.stderr)
        res_fail_count += 1
        if not soft_fail:
            sys.exit(1)
    except ContractError:
        res_pass_count += 1
        print(f"  PASS: {label}")
    except Exception as exc:
        print(f"  FAIL: {label} (raised unexpected exception {exc.__class__.__name__}: {exc})", file=sys.stderr)
        res_fail_count += 1
        if not soft_fail:
            sys.exit(1)

total_failures = inv_fail_count + res_fail_count
if total_failures > 0:
    print(f"Target 1 Loader Matrix had {total_failures} failure(s).", file=sys.stderr)
    sys.exit(1)

print(f"Target 1 Loader Matrix Complete: {inv_pass_count} invocation variations + {res_pass_count} result variations passed.")
PY_TARGET1
[ $? -eq 0 ] && pass "Target 1 contract loaders variation matrix passed 100%" || fail "Target 1 contract loaders variation matrix failed"


# ═════════════════════════════════════════════════════════════════════════════════════════════
# TARGET 2: Landing Verification (jog_run.jog_land checks)
# ═════════════════════════════════════════════════════════════════════════════════════════════
echo "--- Section 2: Target 2 — Landing Verification Matrix ---"

CAPTURE_DOC_NAME="GH-901-FIXTURE-LANE.md"
write_capture_doc() {
  cat > "$1" <<'DOC_EOF'
---
gh_issue: 901
source: https://github.com/example/example/issues/901
title: "GH-290 fixture lane"
status: "Active"
created: 2026-08-28
updated: 2026-08-28
owner: test
doc_type: bugfix
---

# GH-901 fixture lane

## Acceptance
- [ ] artifact updated and gate green

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/fixture-gate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "notes/landing-note.txt" } ],
  "artifacts": [ "src/feature.js" ]
}
```
DOC_EOF
}

setup_fixture() {
  local root="$1" prefix="$2"
  git clone -q "$REMOTE" "$root"
  git -C "$root" config user.email gh290@test.invalid
  git -C "$root" config user.name gh290
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

FR="$WORK/fixture-root"
setup_fixture "$FR" ""

# Build development branch and lane tip commit
git -C "$FR" branch -M development
git -C "$FR" checkout -q -b marathon/gh290-lane development
printf 'module.exports = 2\n' > "$FR/src/feature.js"
git -C "$FR" add -A >/dev/null 2>&1
git -C "$FR" commit -q -m "lane work" >/dev/null 2>&1
LANE_TIP="$(git -C "$FR" rev-parse HEAD)"

# Merge into development to create merge commit
git -C "$FR" checkout -q development
git -C "$FR" merge -q --no-ff marathon/gh290-lane -m "Merge pull request #42 from marathon/gh290-lane" >/dev/null 2>&1
MERGE_SHA="$(git -C "$FR" rev-parse HEAD)"

# Create an unrelated commit on an orphaned branch for unreachable SHA testing
git -C "$FR" checkout -q -b unrelated-branch
printf 'unrelated\n' > "$FR/unrelated.txt"
git -C "$FR" add -A >/dev/null 2>&1
git -C "$FR" commit -q -m "unrelated commit" >/dev/null 2>&1
UNRELATED_SHA="$(git -C "$FR" rev-parse HEAD)"
git -C "$FR" checkout -q development
git -C "$FR" branch -q -D unrelated-branch >/dev/null 2>&1

GID="$(sqlite3 "$FR/releases.db" "SELECT global_id FROM jog_queue WHERE gh_number = 901;")"
mkdir -p "$FR/.tick/jog/$GID/gh901-exec1/preflight"

jog_verb() {  # <verb> <extra-args…>
  local verb="$1"; shift
  ( cd "$FR" && python3 "$FR/utils/py/releases_app.py" jog "$verb" "$@" )
}

# Helper to build valid/mutated marathon-result.json
make_test_receipt() {  # <dest_path> <overrides_json>
  python3 - "$1" "$2" "$FR" "$LANE_TIP" <<'PY'
import json, sys
dest, overrides_raw, fr, lane_tip = sys.argv[1:5]
overrides = json.loads(overrides_raw) if overrides_raw else {}

receipt = {
    "schema": "marathon-drive/result@1",
    "execution_id": "gh901-exec1",
    "generated_at": "2026-08-28T02:00:00Z",
    "outcome": "approved",
    "reason": "approved",
    "exit_code": 0,
    "approval_preserved": False,
    "issue": "901",
    "phase": "p1",
    "lane": "p1",
    "token": "MARATHON-P1-TURN",
    "attempt": {"count": 1, "max": 2},
    "builder": "codex",
    "reviewer": "agy",
    "target_repo": {"path": fr, "origin_url": None},
    "base_branch": "development",
    "head_branch": "marathon/gh290-lane",
    "head_sha": lane_tip,
    "branch_redirect": True,
    "gate": {"cmd": "true", "result": "green", "exit": 0, "receipt_path": None},
    "acceptance": {"checked": False, "unmet_count": 0},
    "pr": {"number": 42, "url": "https://example.invalid/x/pr/42", "state": "OPEN"},
    "pr_note": None,
    "relay_status": "Approved",
    "timestamps": {"started_at": "2026-08-28T01:59:00Z", "finished_at": "2026-08-28T02:00:00Z"}
}

def deep_update(d, u):
    for k, v in u.items():
        if isinstance(v, dict) and k in d and isinstance(d[k], dict):
            deep_update(d[k], v)
        else:
            d[k] = v

deep_update(receipt, overrides)
with open(dest, "w") as f:
    json.dump(receipt, f, indent=2)
PY
}

# Helper to build PR view JSON
make_pr_view() {  # <dest_path> <state> <base> <head> <headRefOid> <mergeCommitOid|null>
  python3 - "$@" <<'PY'
import json, sys
dest, state, base, head, head_oid, merge_oid = sys.argv[1:7]
pr = {
    "number": 42,
    "url": "https://example.invalid/x/pr/42",
    "state": state,
    "baseRefName": base,
    "headRefName": head,
    "headRefOid": head_oid,
    "mergedAt": "2026-08-28T01:00:00Z" if state == "MERGED" else None,
    "title": "GH-901 fixture PR",
    "body": "Closes #901"
}
if merge_oid != "null" and merge_oid != "":
    pr["mergeCommit"] = {"oid": merge_oid}
else:
    pr["mergeCommit"] = None
with open(dest, "w") as f:
    json.dump(pr, f, indent=2)
PY
}

queue_status() {
  sqlite3 "$FR/releases.db" "SELECT status || '|' || COALESCE(failure_reason,'') || '|' || COALESCE(attempt_count,0) FROM jog_queue WHERE gh_number = 901;"
}

reset_jog_state() {
  sqlite3 "$FR/releases.db" "UPDATE jog_queue SET status = 'parked', failure_reason = 'awaiting-landing (PR #42)', attempt_count = 0 WHERE gh_number = 901;"
  cat > "$FR/.tick/jog/$GID/state.json" <<JSEOF
{"schema": "jog/execution-state@1", "gid": "$GID", "gh_number": 901,
 "executions": [{"execution_id": "gh901-exec1", "mode": "run", "started_at": "2026-08-28T02:00:00Z",
                 "status": "projected-parked", "packet_dir": "$FR/.tick/jog/$GID/gh901-exec1/preflight",
                 "result_path": "$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json"}]}
JSEOF
}

VIEW="$WORK/t2-pr-view.json"
RES_FILE="$FR/.tick/jog/$GID/gh901-exec1/preflight/marathon-result.json"

# Target 2 Variation 1: Wrong PR base branch
reset_jog_state
make_test_receipt "$RES_FILE" '{}'
make_pr_view "$VIEW" MERGED "main" "marathon/gh290-lane" "$LANE_TIP" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "base development" \
  && pass "T2.1 wrong PR base branch refused (exit 2)" || fail "T2.1 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.1 queue row status untouched" || fail "T2.1 row mutated: $(queue_status)"

# Target 2 Variation 2: Wrong PR head branch
reset_jog_state
make_pr_view "$VIEW" MERGED "development" "marathon/wrong-lane" "$LANE_TIP" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "head marathon/gh290-lane" \
  && pass "T2.2 wrong PR head branch refused (exit 2)" || fail "T2.2 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.2 queue row status untouched" || fail "T2.2 row mutated: $(queue_status)"

# Target 2 Variation 3: Mismatched headRefOid
reset_jog_state
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "0000000000000000000000000000000000000000" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "head SHA" \
  && pass "T2.3 mismatched head SHA refused (exit 2)" || fail "T2.3 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.3 queue row status untouched" || fail "T2.3 row mutated: $(queue_status)"

# Target 2 Variation 4: PR state OPEN (unmerged)
reset_jog_state
make_pr_view "$VIEW" OPEN "development" "marathon/gh290-lane" "$LANE_TIP" "null"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "state MERGED" \
  && pass "T2.4 unmerged PR (OPEN) refused (exit 2)" || fail "T2.4 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.4 queue row status untouched" || fail "T2.4 row mutated: $(queue_status)"

# Target 2 Variation 5: PR state CLOSED (unmerged)
reset_jog_state
make_pr_view "$VIEW" CLOSED "development" "marathon/gh290-lane" "$LANE_TIP" "null"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "state MERGED" \
  && pass "T2.5 unmerged PR (CLOSED) refused (exit 2)" || fail "T2.5 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.5 queue row status untouched" || fail "T2.5 row mutated: $(queue_status)"

# Target 2 Variation 6: Receipt naming a foreign repository
reset_jog_state
make_test_receipt "$RES_FILE" '{"target_repo": {"path": "/definitely/foreign/repo/path"}}'
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "$LANE_TIP" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "receipt repo is this repo" \
  && pass "T2.6 foreign repository in receipt refused (exit 2)" || fail "T2.6 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.6 queue row status untouched" || fail "T2.6 row mutated: $(queue_status)"

# Target 2 Variation 7: Unreachable merge commit SHA
reset_jog_state
make_test_receipt "$RES_FILE" '{}'
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "$LANE_TIP" "$UNRELATED_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "not reachable" \
  && pass "T2.7 unreachable merge commit SHA refused (exit 2)" || fail "T2.7 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.7 queue row status untouched" || fail "T2.7 row mutated: $(queue_status)"

# Target 2 Variation 8: Missing merge commit object
reset_jog_state
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "$LANE_TIP" "null"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "merge commit present" \
  && pass "T2.8 missing merge commit in PR metadata refused (exit 2)" || fail "T2.8 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.8 queue row status untouched" || fail "T2.8 row mutated: $(queue_status)"

# Target 2 Variation 9: Red gate evidence in receipt
reset_jog_state
make_test_receipt "$RES_FILE" '{"gate": {"result": "red", "exit": 1}}'
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "$LANE_TIP" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "gate green on the landed head" \
  && pass "T2.9 red gate evidence refused (exit 2)" || fail "T2.9 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.9 queue row status untouched" || fail "T2.9 row mutated: $(queue_status)"

# Target 2 Variation 10: Not-run gate evidence in receipt
reset_jog_state
make_test_receipt "$RES_FILE" '{"gate": {"result": "not-run", "exit": null}}'
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "gate green on the landed head" \
  && pass "T2.10 not-run gate evidence refused (exit 2)" || fail "T2.10 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.10 queue row status untouched" || fail "T2.10 row mutated: $(queue_status)"

# Target 2 Variation 11: Gate receipt path specified but absent on disk
reset_jog_state
make_test_receipt "$RES_FILE" '{"gate": {"result": "green", "exit": 0, "receipt_path": "/nonexistent/receipt.json"}}'
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "gate green on the landed head" \
  && pass "T2.11 absent gate receipt path on disk refused (exit 2)" || fail "T2.11 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.11 queue row status untouched" || fail "T2.11 row mutated: $(queue_status)"

# Target 2 Variation 12: gh pr view command failure
reset_jog_state
make_test_receipt "$RES_FILE" '{}'
OUT="$(GH_STUB_VIEW_FAIL=1 jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "could not verify PR" \
  && pass "T2.12 gh pr view failure refused (exit 2)" || fail "T2.12 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.12 queue row status untouched" || fail "T2.12 row mutated: $(queue_status)"

# Target 2 Variation 13: gh pr view unparseable JSON output
reset_jog_state
printf 'Not valid JSON' > "$VIEW"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "unparseable JSON" \
  && pass "T2.13 unparseable JSON from gh pr view refused (exit 2)" || fail "T2.13 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.13 queue row status untouched" || fail "T2.13 row mutated: $(queue_status)"

# Target 2 Variation 14: Invalid --pr argument syntax
reset_jog_state
OUT="$(jog_verb land 901 --pr "not-a-valid-pr" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "expects a PR number" \
  && pass "T2.14 invalid --pr format refused (exit 2)" || fail "T2.14 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.14 queue row status untouched" || fail "T2.14 row mutated: $(queue_status)"

# Target 2 Variation 15: Missing PR identity in receipt and no --pr argument
reset_jog_state
make_test_receipt "$RES_FILE" '{"pr": {"number": null, "url": null, "state": null}}'
OUT="$(jog_verb land 901 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "has no PR identity" \
  && pass "T2.15 missing PR identity without explicit --pr flag refused (exit 2)" || fail "T2.15 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.15 queue row status untouched" || fail "T2.15 row mutated: $(queue_status)"

# Target 2 Variation 16: No approved execution in ledger
reset_jog_state
make_test_receipt "$RES_FILE" '{"outcome": "escalated", "reason": "no-progress"}'
make_pr_view "$VIEW" MERGED "development" "marathon/gh290-lane" "$LANE_TIP" "$MERGE_SHA"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "no approved Marathon execution to land" \
  && pass "T2.16 non-approved execution outcome refused (exit 2)" || fail "T2.16 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.16 queue row status untouched" || fail "T2.16 row mutated: $(queue_status)"

# Target 2 Variation 17: Issue not in queue
OUT="$(jog_verb land 999 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "not in the jog queue" \
  && pass "T2.17 non-existent queue item refused (exit 2)" || fail "T2.17 exit=$rc: $OUT"

# Target 2 Variation 18: Composition of multiple mismatches (state OPEN + wrong base + red gate + foreign repo)
reset_jog_state
make_test_receipt "$RES_FILE" '{"gate": {"result": "red"}, "target_repo": {"path": "/foreign/repo"}}'
make_pr_view "$VIEW" OPEN "main" "marathon/wrong-lane" "0000000000000000000000000000000000000000" "null"
OUT="$(GH_STUB_PR_VIEW_JSON="$VIEW" jog_verb land 901 --pr 42 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && has "$OUT" "state MERGED" && has "$OUT" "base development" && has "$OUT" "head marathon/gh290-lane" \
  && has "$OUT" "head SHA" && has "$OUT" "receipt repo is this repo" && has "$OUT" "gate green on the landed head" \
  && pass "T2.18 composite multi-mismatch reported all failed predicates (exit 2)" || fail "T2.18 exit=$rc: $OUT"
has "$(queue_status)" "parked|" && pass "T2.18 composite failure left queue row untouched" || fail "T2.18 row mutated: $(queue_status)"


# ═════════════════════════════════════════════════════════════════════════════════════════════
# TARGET 3: Receipt Writer Robustness (utils/py/marathon_drive.py: write_terminal_result)
# ═════════════════════════════════════════════════════════════════════════════════════════════
echo "--- Section 3: Target 3 — Receipt Writer Robustness Matrix ---"

python3 - "$REPO" "$WORK" <<'PY_TARGET3'
import sys, os, json, tempfile, shutil

repo_root = sys.argv[1]
work_dir = sys.argv[2]
sys.path.insert(0, os.path.join(repo_root, "utils", "py"))

import marathon_drive
import jog_run

t3_root = os.path.join(work_dir, "t3_root")
os.makedirs(t3_root, exist_ok=True)
receipt_file = os.path.join(t3_root, "terminal-result.json")

def arm_writer(execution_id="exec-t3", root=t3_root, **kwargs):
    marathon_drive._RESULT.clear()
    params = {
        "armed": True,
        "path": receipt_file,
        "execution_id": execution_id,
        "started_at": "2026-08-28T00:00:00Z",
        "phase": "p1",
        "lane": "p1",
        "builder": "codex",
        "reviewer": "agy",
        "root": root,
        "target_repo_path": root,
        "attempt_max": 2,
        "brief_name": "GH-901-BRIEF.md"
    }
    params.update(kwargs)
    marathon_drive._RESULT.update(params)

def verify_receipt(expected_outcome, expected_exit_code, expected_reason_substr=None):
    assert os.path.isfile(receipt_file), "Receipt file was not written"
    receipt = jog_run.load_marathon_result(receipt_file)
    assert receipt["outcome"] == expected_outcome, f"Outcome mismatch: got {receipt['outcome']!r}, expected {expected_outcome!r}"
    assert receipt["exit_code"] == expected_exit_code, f"Exit code mismatch: got {receipt['exit_code']!r}, expected {expected_exit_code!r}"
    if expected_reason_substr:
        assert expected_reason_substr in str(receipt.get("reason", "")), f"Reason {receipt.get('reason')!r} missing {expected_reason_substr!r}"
    return receipt

# 1. Exit Codes & Outcome Vocabulary Coverage
test_matrix_exits = [
    ("T3.1.1 exit 0 -> outcome approved", 0, {}, "approved", 0, "approved"),
    ("T3.1.2 exit 2 -> outcome refused", 2, {}, "refused", 2, "usage or configuration error"),
    ("T3.1.3 exit 2 (explicit reason) -> outcome refused", 2, {"reason": "pre-advance-gate-not-runnable"}, "refused", 2, "pre-advance-gate-not-runnable"),
    ("T3.1.4 exit 3 -> outcome escalated (no-progress)", 3, {}, "escalated", 3, "no-progress"),
    ("T3.1.5 exit 4 -> outcome escalated (cap-or-close-mismatch)", 4, {}, "escalated", 4, "round-cap or close-mismatch"),
    ("T3.1.6 exit 5 -> outcome escalated (pre-advance gate failure)", 5, {}, "escalated", 5, "pre-advance gate failed"),
    ("T3.1.7 exit 7 -> outcome escalated (timeout)", 7, {}, "escalated", 7, "turn timeout"),
    ("T3.1.8 exit 8 -> outcome parked (max attempts)", 8, {}, "parked", 8, "lane parked at the attempt cap"),
    ("T3.1.9 exit 1 (bare) -> outcome lock-contention", 1, {}, "lock-contention", 1, "driver lock contention"),
    ("T3.1.10 exit 1 (with reason) -> outcome escalated", 1, {"reason": "tick failed to initialize"}, "escalated", 1, "tick failed to initialize"),
    ("T3.1.11 exit 130 -> outcome interrupted", 130, {}, "interrupted", 130, "exit 130"),
    ("T3.1.12 exit 137 -> outcome interrupted", 137, {}, "interrupted", 137, "exit 137"),
    ("T3.1.13 exit 143 -> outcome interrupted", 143, {}, "interrupted", 143, "exit 143"),
    ("T3.1.14 crashed flag -> outcome crashed", 1, {"crashed": True, "reason": "unhandled driver exception"}, "crashed", 1, "unhandled driver exception"),
    ("T3.1.15 post-approve-failed -> approval_preserved True", 9, {"post_approve_failed": True, "gate_result": "green"}, "post-approve-failed", 9, None),
    ("T3.1.16 already-satisfied reason preserved", 0, {"reason": "already-satisfied"}, "approved", 0, "already-satisfied"),
]

t3_fail_count = 0
soft_fail = os.environ.get("TEST_SOFT_FAIL") == "1"

for label, exit_code, extra_params, expected_outcome, expected_exit, reason_sub in test_matrix_exits:
    if os.path.exists(receipt_file):
        os.remove(receipt_file)
    try:
        arm_writer(execution_id=f"exec-{exit_code}", **extra_params)
        marathon_drive.write_terminal_result(exit_code)
        rec = verify_receipt(expected_outcome, expected_exit, reason_sub)
        if expected_outcome == "post-approve-failed":
            assert rec["approval_preserved"] is True
        print(f"  PASS: {label}")
    except Exception as exc:
        print(f"  FAIL: {label} ({exc.__class__.__name__}: {exc})", file=sys.stderr)
        t3_fail_count += 1
        if not soft_fail:
            sys.exit(1)


# 2. Hostile gh pr list Output Shapes (parsed via json.loads in _write_terminal_result_inner)
# Test through mock _result_cmd_out / environment
orig_cmd_out = marathon_drive._result_cmd_out

hostile_gh_cases = [
    ("T3.2.1 empty output from gh pr list", ""),
    ("T3.2.2 bare empty array [] from gh pr list", "[]"),
    ("T3.2.3 bare array with single item from gh pr list", '[{"number": 42, "url": "https://example.invalid/pr/42", "state": "OPEN"}]'),
    ("T3.2.4 bare array with multiple items from gh pr list", '[{"number": 42, "url": "https://example.invalid/pr/42", "state": "OPEN"}, {"number": 43, "url": "https://example.invalid/pr/43", "state": "OPEN"}]'),
    ("T3.2.5 non-JSON string from gh pr list", "error: network unreachable"),
    ("T3.2.6 truncated JSON from gh pr list", '{"number": 42, "state":'),
    ("T3.2.7 non-digit number in gh pr list object", '{"number": "forty-two", "url": "https://example.invalid/pr/42", "state": "OPEN"}'),
    ("T3.2.8 null properties in gh pr list object", '{"number": null, "url": null, "state": null}'),
    ("T3.2.9 bare scalar number from gh pr list", "42"),
    ("T3.2.10 bare boolean from gh pr list", "true"),
]

for label, gh_mock_output in hostile_gh_cases:
    if os.path.exists(receipt_file):
        os.remove(receipt_file)
    def mock_cmd_out(cmd, **kwargs):
        if cmd[0] == "gh" and "list" in cmd:
            return gh_mock_output
        return orig_cmd_out(cmd, **kwargs)
    marathon_drive._result_cmd_out = mock_cmd_out
    try:
        arm_writer(execution_id="exec-gh-test")
        marathon_drive.write_terminal_result(0)
        verify_receipt("approved", 0)
        print(f"  PASS: {label}")
    except Exception as exc:
        print(f"  FAIL: {label} ({exc.__class__.__name__}: {exc})", file=sys.stderr)
        t3_fail_count += 1
        if not soft_fail:
            sys.exit(1)
    finally:
        marathon_drive._result_cmd_out = orig_cmd_out


# 3. Hostile git / environment anomalies
hostile_git_cases = [
    ("T3.3.1 detached HEAD (symbolic-ref failure)", lambda cmd, **kw: None if "symbolic-ref" in cmd else orig_cmd_out(cmd, **kw)),
    ("T3.3.2 rev-parse HEAD failure", lambda cmd, **kw: None if "rev-parse" in cmd else orig_cmd_out(cmd, **kw)),
    ("T3.3.3 remote get-url origin failure", lambda cmd, **kw: None if "get-url" in cmd else orig_cmd_out(cmd, **kw)),
]

for label, mock_func in hostile_git_cases:
    if os.path.exists(receipt_file):
        os.remove(receipt_file)
    marathon_drive._result_cmd_out = mock_func
    try:
        arm_writer(execution_id="exec-git-test")
        marathon_drive.write_terminal_result(0)
        rec = verify_receipt("approved", 0)
        print(f"  PASS: {label}")
    except Exception as exc:
        print(f"  FAIL: {label} ({exc.__class__.__name__}: {exc})", file=sys.stderr)
        t3_fail_count += 1
        if not soft_fail:
            sys.exit(1)
    finally:
        marathon_drive._result_cmd_out = orig_cmd_out

if t3_fail_count > 0:
    print(f"Target 3 Receipt Writer Matrix had {t3_fail_count} failure(s).", file=sys.stderr)
    sys.exit(1)

print("Target 3 Receipt Writer Robustness Matrix Complete: all variations passed.")
PY_TARGET3
[ $? -eq 0 ] && pass "Target 3 receipt writer robustness variation matrix passed 100%" || fail "Target 3 receipt writer robustness variation matrix failed"

echo ""
echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
