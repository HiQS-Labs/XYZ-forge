#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"pre_fix_revision":"3b37072","reproducer":"bash test/gh343-gate-program-target-root.sh","pre_fix_result":"target-relative program from an external cwd exits 5 with a PATH diagnostic","post_fix_result":"the identical fixture exits 0 and reports READY from both cwd values"}
# GH-343 — gate programs containing a path separator must be resolved against the target root,
# exactly like bash/sh script gates.  This test keeps the historical Python implementation as an
# executable negative control: it observes the pre-fix target-relative program fail from outside
# the target before asserting the current default shim reports READY in both locations.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"
PRE_FIX_REV="3b37072"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh343-gate-program-target-root.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh343-gate-program-target-root =="
echo "  workdir: $WORK"
export SWARM_PREFLIGHT_NOW="2026-08-06T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-06"

R="$WORK/target"
mkdir -p "$R/PROJECT/2-WORKING" "$R/scripts" "$R/bin" "$R/src" "$WORK/outside"
: >"$R/src/artifact.txt"
printf '#!/usr/bin/env sh\nexit 0\n' >"$R/scripts/gate.sh"
printf '#!/usr/bin/env sh\nexit 0\n' >"$R/bin/gate-program"
chmod +x "$R/scripts/gate.sh" "$R/bin/gate-program"
cat >"$R/PROJECT/2-WORKING/GH-900-gh343.md" <<'EOF'
---
title: gh343 fixture
---
# GH-343 fixture
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bin/gate-program",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/artifact.txt" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
}
```
## Phase 1
- [ ] build it
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
TARGET_ROOT="$(git -C "$R" rev-parse --show-toplevel)"

# Keep the fixture contract static for the replay.  Each run derives a one-off document so command
# replacement cannot change an unrelated part of the candidate.
run_gate() {
  local runner="$1" program="$2" cwd="$3" gate="$4" doc="$R/PROJECT/2-WORKING/GH-900-gh343-run.md"
  sed "s#\"gate\": \"bin/gate-program\"#\"gate\": \"$gate\"#" \
    "$R/PROJECT/2-WORKING/GH-900-gh343.md" >"$doc"
  (
    cd "$cwd" || exit 99
    SWARM_PREFLIGHT_ROOT="$R" "$runner" "$program" --target-root "$R" \
      --project-doc "PROJECT/2-WORKING/GH-900-gh343-run.md" --dry-run
  )
}

PRE_FIX="$WORK/swarm_preflight-3b37072.py"
if git -C "$ROOT" show "$PRE_FIX_REV:utils/py/swarm_preflight.py" >"$PRE_FIX" 2>/dev/null; then
  out="$(run_gate python3 "$PRE_FIX" "$WORK/outside" "bin/gate-program" 2>&1)"; rc=$?
  if [ "$rc" -eq 5 ] && grep -Fq "command 'bin/gate-program' not found in PATH" <<<"$out"; then
    pass "pre-fix replay ($PRE_FIX_REV): external cwd rejects the target-relative program with exit 5"
  else
    fail "pre-fix replay ($PRE_FIX_REV): expected PATH-based NOT-READY exit 5; rc=$rc — $out"
  fi
else
  fail "pre-fix replay: revision $PRE_FIX_REV is unavailable; the negative control cannot be witnessed"
fi

for gate in "bash scripts/gate.sh" "bin/gate-program"; do
  for cwd in "$R" "$WORK/outside"; do
    out="$(run_gate bash "$SP" "$cwd" "$gate" 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ] && grep -q 'verdict     : ready' <<<"$out"; then
      pass "$(basename "$cwd"): $gate resolves at target root and is READY"
    else
      fail "$(basename "$cwd"): expected $gate READY/exit 0; rc=$rc — $out"
    fi
  done
done

chmod -x "$R/scripts/gate.sh"
out="$(run_gate bash "$SP" "$WORK/outside" "bash scripts/gate.sh" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -Fq "not executable at target root $TARGET_ROOT: scripts/gate.sh" <<<"$out"; then
  pass "non-executable shell script is NOT-READY and names target root"
else
  fail "non-executable shell script: expected target-root NOT-READY exit 5; rc=$rc — $out"
fi
chmod +x "$R/scripts/gate.sh"

chmod -x "$R/bin/gate-program"
out="$(run_gate bash "$SP" "$WORK/outside" "bin/gate-program" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -Fq "not executable at target root $TARGET_ROOT: bin/gate-program" <<<"$out"; then
  pass "non-executable target-relative program is NOT-READY and names target root"
else
  fail "non-executable target-relative program: expected target-root NOT-READY exit 5; rc=$rc — $out"
fi
chmod +x "$R/bin/gate-program"

rm "$R/scripts/gate.sh"
out="$(run_gate bash "$SP" "$WORK/outside" "bash scripts/gate.sh" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -Fq "not found at target root $TARGET_ROOT: scripts/gate.sh" <<<"$out"; then
  pass "missing shell script is NOT-READY and names target root"
else
  fail "missing shell script: expected target-root NOT-READY exit 5; rc=$rc — $out"
fi

rm "$R/bin/gate-program"
out="$(run_gate bash "$SP" "$WORK/outside" "bin/gate-program" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -Fq "not found at target root $TARGET_ROOT: bin/gate-program" <<<"$out"; then
  pass "missing target-relative program is NOT-READY and names target root"
else
  fail "missing target-relative program: expected target-root NOT-READY exit 5; rc=$rc — $out"
fi

out="$(run_gate bash "$SP" "$WORK/outside" "gh343-definitely-missing-bare-command" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -Fq "command 'gh343-definitely-missing-bare-command' not found in PATH" <<<"$out"; then
  pass "bare missing command keeps the accurate PATH diagnostic"
else
  fail "bare missing command: expected PATH NOT-READY exit 5; rc=$rc — $out"
fi

echo "  gh343-gate-program-target-root: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
