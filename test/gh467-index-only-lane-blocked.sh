#!/usr/bin/env bash
# GH-467: builders must not be dispatched index-only work they are forbidden to perform.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh467-index-only.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: GH-467 index-only preflight refusal =="

make_repo() {
  local name="$1"
  local contract="$2"
  local repo="$WORK/$name"
  mkdir -p "$repo/PROJECT/2-WORKING" "$repo/src" "$repo/bin"
  : >"$repo/src/index-only.txt"
  : >"$repo/bin/index-only.txt"
  printf -- '---\ntitle: %s\n---\n# %s\n## Phase 1\n- [ ] perform the declared delivery\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
    "$name" "$name" "$contract" >"$repo/PROJECT/2-WORKING/GH-467-$name.md"
  git -C "$repo" init -q -b main 2>/dev/null || { git -C "$repo" init -q; git -C "$repo" symbolic-ref HEAD refs/heads/main; }
  git -C "$repo" -c user.email=t@t -c user.name=t add -A >/dev/null
  git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
  printf '%s' "$repo"
}

run() { SWARM_PREFLIGHT_ROOT="$1" SWARM_PREFLIGHT_NOW="2026-08-11T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-11" bash "$SP" --target-root "$1" "${@:2}"; }

# The specific protective instruction is part of the contract: a later packet change must not make
# index-only dispatch look viable by silently dropping the git ban.
grep -Fq 'Do NOT run git. Do NOT touch any other file' "$ROOT/utils/py/marathon_drive.py" \
  && grep -Fq 'Do NOT run git. Do NOT touch any other file' "$ROOT/relay-automation/marathon-drive.sh" \
  && pass "builder packets retain the Do NOT run git instruction" \
  || fail "builder git ban missing from a marathon driver packet"

UNSCOPED="$(make_repo unscoped '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "bin/index-only.txt" ],
  "lanes": { "index_only": [ "bin/index-only.txt" ], "orchestrator_only": [] },
  "remediation": { "criteria": "refuse an undeclared index-only lane" }
}')"
out="$(run "$UNSCOPED" --project-doc "PROJECT/2-WORKING/GH-467-unscoped.md" --out "$UNSCOPED/packet" 2>&1)"; rc=$?
[[ $rc -eq 6 ]] && pass "undeclared index-only lane exits BLOCKED (6)" \
  || fail "undeclared index-only lane expected exit 6, got $rc: $out"
grep -Fq 'index-only  : BLOCKED' <<<"$out" \
  && grep -Fq 'bin/index-only.txt' <<<"$out" \
  && pass "BLOCKED diagnostic names the unscoped index-only path" \
  || fail "BLOCKED diagnostic lacks index-only reason/path: $out"
[[ ! -d "$UNSCOPED/packet" ]] && pass "BLOCKED index-only lane writes no packet" \
  || fail "BLOCKED index-only lane wrote a packet"

# An explicit empty list means no path is orchestrator-owned. It must not be silently replaced by
# the legacy default, which would otherwise classify this bin/ artifact as orchestrator-owned.

for lane_name in agy_safe orchestrator_only index_only; do
  for invalid_json in null 42 '"not-an-array"'; do
    label="${lane_name}-${invalid_json//\"/string}"
    INVALID="$(make_repo "invalid-$label" "{
  \"target\": { \"repo\": \".\", \"ref\": \"main\" },
  \"gate\": \"true\",
  \"fix_probes\": [ { \"type\": \"path_absent\", \"path\": \"NEW.txt\" } ],
  \"artifacts\": [ \"src/index-only.txt\" ],
  \"lanes\": { \"$lane_name\": $invalid_json },
  \"remediation\": { \"criteria\": \"reject malformed lane configuration\" }
}")"
    out="$(run "$INVALID" --project-doc "PROJECT/2-WORKING/GH-467-invalid-$label.md" --out "$INVALID/packet" 2>&1)"; rc=$?
    [[ $rc -eq 3 ]] && grep -Fq "lanes.$lane_name must be an array of non-empty strings" <<<"$out" \
      && pass "lanes.$lane_name rejects $invalid_json before planning" \
      || fail "lanes.$lane_name accepted $invalid_json or emitted the wrong error: $out"
  done
done

SCOPED="$(make_repo scoped '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "src/index-only.txt" ],
  "lanes": {
    "index_only": [ "src/index-only.txt" ],
    "orchestrator_only": [ "src/index-only.txt" ]
  },
  "remediation": { "criteria": "retain existing orchestrator-owned dispatch" }
}')"
out="$(run "$SCOPED" --project-doc "PROJECT/2-WORKING/GH-467-scoped.md" --out "$SCOPED/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "declared orchestrator-owned index-only lane remains ready" \
  || fail "declared index-only lane expected exit 0, got $rc: $out"
python3 - "$SCOPED/packet/lane-plan.json" <<'PY'
import json
import sys

lane_plan = json.load(open(sys.argv[1]))
sys.exit(0 if lane_plan["orchestrator_owned"] == ["src/index-only.txt"] and not lane_plan["codex_lane"] else 1)
PY
[[ $? -eq 0 ]] && pass "scoped index-only lane keeps its existing orchestrator assignment" \
  || fail "scoped index-only lane changed its orchestrator assignment"

echo "passed: $PASS"
if [[ $FAIL -gt 0 ]]; then
  echo "failed: $FAIL" >&2
  exit 1
fi
