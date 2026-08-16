#!/usr/bin/env bash
# test/gh308-swarm-gate-path.sh — GH-308 audit: swarm-preflight.sh NOT-READYs a candidate whose gate
# PROGRAM is not installed (swarm-preflight.sh:774, `command -v "$g0"`). swarm_preflight.py — the lane
# that actually runs since GH-264 — exempted node/npm/python3 from that PATH check, so a contract whose
# gate runner (e.g. `npm test`) was NOT installed got green-lit as marathon-ready (exit 0) on the live
# lane instead of refused NOT-READY (exit 5). This drives the DEFAULT (Python) lane.
#
# Standalone (mirrors test/swarm-preflight.sh — the planner needs no tick/relay harness).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh308-swarm-gate-path.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh308-swarm-gate-path =="
echo "  workdir: $WORK"
export SWARM_PREFLIGHT_NOW="2026-06-25T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-06-25"

# Fixture: an otherwise-READY contract whose gate program is `npm` (a member of the old exemption list).
R="$WORK/repo"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src"
: >"$R/src/a.js"
cat >"$R/PROJECT/2-WORKING/GH-900-npmgate.md" <<'EOF'
---
title: npmgate
---
# npmgate
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "npm test",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
}
```
## Phase 1
- [ ] build it
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

run_default() { SWARM_PREFLIGHT_ROOT="$R" bash "$SP" --target-root "$R" --project-doc "PROJECT/2-WORKING/GH-900-npmgate.md" --dry-run 2>&1; }

# (0) Baseline: with npm ON the real PATH the fixture is genuinely READY — so a later NOT-READY is
#     attributable to npm's ABSENCE, not to some other contract defect.
if command -v npm >/dev/null 2>&1; then
  out0="$(run_default)"; rc0=$?
  [ "$rc0" -eq 0 ] && grep -q 'verdict     : ready' <<<"$out0" \
    && pass "baseline: with npm on PATH the npm-gate contract reads ready (exit 0)" \
    || fail "baseline: expected ready/exit 0 with npm present; got rc=$rc0 — $out0"
else
  pass "baseline skipped: npm not installed in this environment (the absence case below still holds)"
fi

# Build a curated PATH that has everything swarm-preflight.py needs (python3 to route the shim, git,
# bash, coreutils) but DELIBERATELY excludes npm/node — so the gate program `npm` is not resolvable.
BINDIR="$WORK/curated-bin"; mkdir -p "$BINDIR"
for tool in python3 git bash sh env sed grep awk cat cut tr wc head tail sort uniq \
            mktemp dirname basename date rm mkdir ls cp mv find printf test lsof realpath; do
  real="$(command -v "$tool" 2>/dev/null)" || continue
  [ -n "$real" ] && ln -sf "$real" "$BINDIR/$tool"
done
# Sanity: the curated PATH must route to Python (python3 present) yet hide npm (the whole point).
if PATH="$BINDIR" command -v python3 >/dev/null 2>&1 && ! PATH="$BINDIR" command -v npm >/dev/null 2>&1; then
  pass "curated PATH keeps python3 (shim routes to the Python lane) and hides npm"
else
  fail "curated PATH is wrong: python3=$(PATH="$BINDIR" command -v python3 || echo none) npm=$(PATH="$BINDIR" command -v npm || echo none)"
fi

# (1) THE FIX: default (Python) lane with npm absent must NOT-READY (exit 5), not green-light it.
#     Pre-change this returned exit 0 / verdict ready because node/npm/python3 were exempted.
out="$(PATH="$BINDIR" SWARM_PREFLIGHT_ROOT="$R" bash "$SP" --target-root "$R" \
        --project-doc "PROJECT/2-WORKING/GH-900-npmgate.md" --dry-run 2>&1)"; rc=$?
[ "$rc" -eq 5 ] \
  && pass "default lane: an uninstalled npm gate program is refused NOT-READY (exit 5)" \
  || fail "default lane: expected exit 5 for an uninstalled gate program, got rc=$rc — $out"
grep -qi "not found in PATH\|not on PATH" <<<"$out" \
  && pass "default lane: the verdict names the missing gate program" \
  || fail "default lane: NOT-READY reason did not cite the missing PATH program: $out"

echo "  gh308-swarm-gate-path: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
