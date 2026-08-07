#!/usr/bin/env bash
# test/gh343-gate-program-target-root.sh — target-relative gate programs and scripts are evaluated
# from the contract target, regardless of the preflight caller's cwd (GH-343).
#
# Observed baseline (2026-08-06, pre-fix revision 3b37072):
#   Reproducer: from a directory other than the target, invoke the default Python lane with
#   `--target-root <target>` for a contract whose gate is `bin/gate-program`.
#   Pre-fix result: exit 5, `command 'bin/gate-program' not found in PATH`.
#   Post-fix result: exit 0 and `verdict     : ready` from both the target and foreign cwds.
# This fixture preserves the record and proves the corrected, target-root result without depending
# on historical checkout availability.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh343-gate-program-target-root.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh343-gate-program-target-root =="
echo "  workdir: $WORK"
export SWARM_PREFLIGHT_NOW="2026-08-06T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-06"

TARGET="$WORK/target"
FOREIGN="$WORK/foreign-cwd"
mkdir -p "$TARGET/PROJECT/2-WORKING" "$TARGET/scripts" "$TARGET/bin" "$FOREIGN"
TARGET_REAL="$(cd "$TARGET" && pwd -P)"
printf '%s\n' '#!/usr/bin/env sh' 'exit 0' >"$TARGET/scripts/gate.sh"
printf '%s\n' '#!/usr/bin/env sh' 'exit 0' >"$TARGET/bin/gate-program"
chmod 755 "$TARGET/scripts/gate.sh" "$TARGET/bin/gate-program"

for name in shell program; do
  gate='bash scripts/gate.sh'
  [ "$name" = program ] && gate='bin/gate-program'
  cat >"$TARGET/PROJECT/2-WORKING/GH-343-$name.md" <<EOF
---
title: GH-343 $name fixture
---
# GH-343 $name fixture
## Swarm Preflight Contract
\`\`\`json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "$gate",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "scripts/gate.sh", "bin/gate-program" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
}
\`\`\`
## Phase 1
- [ ] build it
EOF
done

git -C "$TARGET" init -q -b main 2>/dev/null || {
  git -C "$TARGET" init -q
  git -C "$TARGET" symbolic-ref HEAD refs/heads/main
}
git -C "$TARGET" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$TARGET" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

run_preflight() {
  local cwd="$1" doc="$2"
  (
    cd "$cwd" || exit 1
    SWARM_PREFLIGHT_ROOT="$TARGET" bash "$SP" --target-root "$TARGET" --project-doc "$doc" --dry-run
  ) 2>&1
}

expect_ready_from_both_cwds() {
  local label="$1" doc="$2" out rc
  for cwd in "$TARGET" "$FOREIGN"; do
    out="$(run_preflight "$cwd" "$doc")"; rc=$?
    [ "$rc" -eq 0 ] && grep -q 'verdict     : ready' <<<"$out" \
      && pass "$label is READY from $(basename "$cwd")" \
      || fail "$label should be READY from $cwd (rc=$rc): $out"
  done
}

expect_not_ready_from_both_cwds() {
  local label="$1" doc="$2" out rc
  for cwd in "$TARGET" "$FOREIGN"; do
    out="$(run_preflight "$cwd" "$doc")"; rc=$?
    [ "$rc" -eq 5 ] && grep -q 'verdict     : NOT-READY' <<<"$out" \
      && pass "$label is NOT-READY from $(basename "$cwd")" \
      || fail "$label should be NOT-READY from $cwd (rc=$rc): $out"
  done
}

SHELL_DOC="PROJECT/2-WORKING/GH-343-shell.md"
PROGRAM_DOC="PROJECT/2-WORKING/GH-343-program.md"
expect_ready_from_both_cwds "target-relative shell script" "$SHELL_DOC"
expect_ready_from_both_cwds "target-relative executable program" "$PROGRAM_DOC"

rm "$TARGET/scripts/gate.sh"
expect_not_ready_from_both_cwds "deleted shell script" "$SHELL_DOC"
shell_missing="$(run_preflight "$FOREIGN" "$SHELL_DOC")"; shell_missing_rc=$?
grep -Fq "target root '$TARGET_REAL'" <<<"$shell_missing" \
  && pass "missing shell script names the searched target root" \
  || fail "missing shell script did not name target root (rc=$shell_missing_rc): $shell_missing"

printf '%s\n' '#!/usr/bin/env sh' 'exit 0' >"$TARGET/scripts/gate.sh"
chmod 644 "$TARGET/scripts/gate.sh"
expect_not_ready_from_both_cwds "non-executable shell script" "$SHELL_DOC"
shell_nonexec="$(run_preflight "$FOREIGN" "$SHELL_DOC")"; shell_nonexec_rc=$?
grep -Fq "not executable at target root '$TARGET_REAL'" <<<"$shell_nonexec" \
  && pass "non-executable shell script names the searched target root" \
  || fail "non-executable shell script diagnostic is incomplete (rc=$shell_nonexec_rc): $shell_nonexec"

rm "$TARGET/bin/gate-program"
expect_not_ready_from_both_cwds "deleted executable program" "$PROGRAM_DOC"
program_missing="$(run_preflight "$FOREIGN" "$PROGRAM_DOC")"; program_missing_rc=$?
grep -Fq "target root '$TARGET_REAL'" <<<"$program_missing" \
  && ! grep -Fq 'not found in PATH' <<<"$program_missing" \
  && pass "missing target-relative program names target root rather than PATH" \
  || fail "missing program diagnostic is wrong (rc=$program_missing_rc): $program_missing"

printf '%s\n' '#!/usr/bin/env sh' 'exit 0' >"$TARGET/bin/gate-program"
chmod 644 "$TARGET/bin/gate-program"
expect_not_ready_from_both_cwds "non-executable program" "$PROGRAM_DOC"
program_nonexec="$(run_preflight "$FOREIGN" "$PROGRAM_DOC")"; program_nonexec_rc=$?
grep -Fq "not executable at target root '$TARGET_REAL'" <<<"$program_nonexec" \
  && pass "non-executable program names the searched target root" \
  || fail "non-executable program diagnostic is incomplete (rc=$program_nonexec_rc): $program_nonexec"

echo "  gh343-gate-program-target-root: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
