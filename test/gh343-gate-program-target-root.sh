#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh343-gate-program-target-root.sh; pre-fix revision: executable copy with the pre-GH-343 shutil.which path branch; pre-fix result: target-relative program from a foreign cwd exited 5; post-fix result: both cwd checks exit 0, deletion exits 5, and a non-executable direct program exits 5"}
# GH-343 — direct, target-relative gate programs must be resolved from target_root, never this test's cwd.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh343-gate-program-target-root.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh343-gate-program-target-root =="
echo "  workdir: $WORK"
export SWARM_PREFLIGHT_NOW="2026-08-08T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-08"

R="$WORK/target"
FOREIGN="$WORK/foreign-cwd"
mkdir -p "$R/PROJECT/2-WORKING" "$R/src" "$R/scripts" "$R/.venv/bin" "$FOREIGN"
: >"$R/src/artifact.py"
printf '#!/usr/bin/env sh\nexit 0\n' >"$R/scripts/check.sh"
printf '#!/usr/bin/env sh\nexit 0\n' >"$R/.venv/bin/gate-python"
chmod 644 "$R/scripts/check.sh"
chmod 755 "$R/.venv/bin/gate-python"

capture() { # <path> <gate>
  cat >"$1" <<EOF
---
title: GH-343 fixture
---

## Phase 1

- [ ] prove target-root gate lookup

## Swarm Preflight Contract

\`\`\`json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "$2",
  "fix_probes": [ { "type": "path_absent", "path": "new-file.txt" } ],
  "artifacts": [ "src/artifact.py" ],
  "remediation": { "source": "fixture", "criteria": "Phase 1" }
}
\`\`\`
EOF
}
capture "$R/PROJECT/2-WORKING/GH-343-script.md" "bash scripts/check.sh"
capture "$R/PROJECT/2-WORKING/GH-343-program.md" ".venv/bin/gate-python"

git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm fixture >/dev/null 2>&1
TARGET_ROOT="$(cd "$R" && pwd -P)"

run_from() { # <cwd> <python-source> <project-doc>
  (cd "$1" && SWARM_PREFLIGHT_ROOT="$R" python3 "$2" --target-root "$R" --project-doc "$3" --dry-run 2>&1)
}
expect_rc() { # <expected> <label> <command output... is supplied through globals>
  if [ "$rc" -eq "$1" ]; then pass "$2"; else fail "$2 (expected exit $1, got $rc — $out)"; fi
}

# Interpreter scripts are target-root-relative but do not need execute permission: bash reads them.
for cwd in "$R" "$FOREIGN"; do
  out="$(run_from "$cwd" "$PY" "PROJECT/2-WORKING/GH-343-script.md")"; rc=$?
  expect_rc 0 "mode-644 bash script is READY from $(basename "$cwd")"
done

# The new direct-path branch must be correct in both locations, not merely agree in the wrong one.
for cwd in "$R" "$FOREIGN"; do
  out="$(run_from "$cwd" "$PY" "PROJECT/2-WORKING/GH-343-program.md")"; rc=$?
  expect_rc 0 "target-relative executable program is READY from $(basename "$cwd")"
done

# Negative control: replay the old cwd/PATH lookup in an executable copy of the real Python lane.
PREFIX="$WORK/swarm_preflight.pre-gh343.py"
cp "$PY" "$PREFIX"
python3 - "$PREFIX" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
old = '''            elif os.path.sep in g0 or (os.path.altsep and os.path.altsep in g0):
                # A direct program path is executed with cwd=target_root by marathon-drive.  Checking it
                # with shutil.which() instead makes a target-relative path depend on the operator's cwd.
                program_path = os.path.join(target_root, g0)
                if not os.path.isfile(program_path):
                    ready, ready_next = 0, (
                        f"gate program not found under target_root {target_root}: {g0}")
                elif not os.access(program_path, os.X_OK):
                    ready, ready_next = 0, (
                        f"gate program is not executable under target_root {target_root}: {g0}")
'''
if old not in source:
    raise SystemExit("could not construct the exact pre-GH-343 control branch")
path.write_text(source.replace(old, ""), encoding="utf-8")
PY
out="$(run_from "$FOREIGN" "$PREFIX" "PROJECT/2-WORKING/GH-343-program.md")"; rc=$?
expect_rc 5 "pre-GH-343 control rejects the target-relative program from a foreign cwd"
grep -q "not found in PATH" <<<"$out" \
  && pass "pre-GH-343 control took the old cwd/PATH failure path" \
  || fail "pre-GH-343 control did not expose the old failure path: $out"

rm "$R/.venv/bin/gate-python"
out="$(run_from "$FOREIGN" "$PY" "PROJECT/2-WORKING/GH-343-program.md")"; rc=$?
expect_rc 5 "missing target-relative program is NOT-READY"
grep -Fq "target_root $TARGET_ROOT" <<<"$out" \
  && pass "missing program diagnostic names the searched target_root" \
  || fail "missing program diagnostic omitted target_root: $out"

printf '#!/usr/bin/env sh\nexit 0\n' >"$R/.venv/bin/gate-python"
chmod 644 "$R/.venv/bin/gate-python"
out="$(run_from "$FOREIGN" "$PY" "PROJECT/2-WORKING/GH-343-program.md")"; rc=$?
expect_rc 5 "non-executable direct program is NOT-READY"
grep -Fq "not executable under target_root $TARGET_ROOT" <<<"$out" \
  && pass "non-executable direct-program diagnostic names target_root" \
  || fail "non-executable direct-program diagnostic omitted target_root: $out"

rm "$R/scripts/check.sh"
out="$(run_from "$FOREIGN" "$PY" "PROJECT/2-WORKING/GH-343-script.md")"; rc=$?
expect_rc 5 "missing interpreter script is NOT-READY"
grep -Fq "target_root $TARGET_ROOT" <<<"$out" \
  && pass "missing script diagnostic names the searched target_root" \
  || fail "missing script diagnostic omitted target_root: $out"

echo "  gh343-gate-program-target-root: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
