#!/usr/bin/env bash
# Synthetic Test: GH-101 Consult Programmatic Tool Mode, Worktree Isolation & Containment
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

# --tool-mode programmatic requires an OS sandbox backend and fail-closes without one:
#   "Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable"
# That refusal is correct, so asserting programmatic behaviour on a host that has no backend tests
# nothing and reports a containment defect that isn't there. bubblewrap is not a documented
# prerequisite (README lists Codex CLI, agy CLI, Node 18+, git, Python 3.8+), so a stock Linux box
# hits this. Skip rather than fail; the missing dependency is the finding, not this suite.
if ! command -v bwrap >/dev/null 2>&1 && ! command -v sandbox-exec >/dev/null 2>&1; then
  echo "  SKIP: gh101-consult-programmatic — no OS sandbox backend (bwrap/sandbox-exec) on this host"
  echo "== gh101-consult-programmatic: 0 passed, 0 failed =="
  exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh101-consult-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO"
git init -q "$REPO"
git -C "$REPO" -c user.email=test@test.local -c user.name=TestRunner commit -q --allow-empty -m "initial commit"
touch "$REPO/sample_code.py"
git -C "$REPO" add sample_code.py
git -C "$REPO" -c user.email=test@test.local -c user.name=TestRunner commit -q -m "add sample_code.py"

OUT_DIR="$WORK/consult_out"
mkdir -p "$OUT_DIR"

ENV_RECORD="$WORK/env_seen.txt"

# Stub codex binary that inspects environment and executes a probe
CODEX_STUB="$WORK/stub_codex.sh"
cat << STUB_EOF > "$CODEX_STUB"
#!/usr/bin/env bash
if [ -n "\${CONSULT_TOOL_MODE:-}" ]; then
  echo "RECEIVED_TOOL_MODE=\${CONSULT_TOOL_MODE}" >> "$ENV_RECORD"
fi
if [ -n "\${XYZ_CONTAINMENT_ROOT:-}" ]; then
  echo "RECEIVED_CONTAINMENT_ROOT=\${XYZ_CONTAINMENT_ROOT}" >> "$ENV_RECORD"
fi
if [ -n "\${RELAY_SCRATCH_DIR:-}" ] && [ -d "\${RELAY_SCRATCH_DIR}" ]; then
  echo "PROBE_RESULT=OK" > "\${RELAY_SCRATCH_DIR}/probe_output.txt"
fi
printf 'model: gpt-stub\nprovider: mock\nsandbox: test\n\nDirect answer: everything is verified. [Pass] "sample_code.py:1"\n'
exit 0
STUB_EOF
chmod +x "$CODEX_STUB"

# 1. Test invalid tool-mode rejection
INVALID_OUT="$(python3 "$ROOT/utils/py/consult.py" --prompt "test" --tool-mode "invalid_mode" 2>&1 || true)"
if ! grep -qF "invalid --tool-mode 'invalid_mode'" <<<"$(echo "$INVALID_OUT")"; then
  echo "FAIL: consult.py failed to reject invalid tool-mode"
  exit 1
fi

# 2. Test --help displays tool-mode
HELP_OUT="$(python3 "$ROOT/utils/py/consult.py" --help 2>&1 || true)"
if ! grep -qF "[--tool-mode standard|programmatic]" <<<"$(echo "$HELP_OUT")"; then
  echo "FAIL: consult.py --help does not document --tool-mode"
  exit 1
fi

# 3. Test programmatic consult execution with worktree containment
CONSULT_ROOT="$REPO" CODEX_BIN="$CODEX_STUB" python3 "$ROOT/utils/py/consult.py" \
  --prompt "Inspect sample_code.py" \
  --models "codex" \
  --out "$OUT_DIR" \
  --label "test_prog" \
  --tool-mode "programmatic" >/dev/null 2>&1

# Assert that programmatic environment was passed
if [ ! -f "$ENV_RECORD" ] || ! grep -qF "RECEIVED_TOOL_MODE=programmatic" "$ENV_RECORD"; then
  echo "FAIL: consult.py did not pass CONSULT_TOOL_MODE=programmatic to advisor"
  exit 1
fi

if ! grep -qF "RECEIVED_CONTAINMENT_ROOT=" "$ENV_RECORD"; then
  echo "FAIL: consult.py did not pass XYZ_CONTAINMENT_ROOT to advisor"
  exit 1
fi

# Assert that parent repo has no leaked .relay-scratch or probe files
if [ -d "$REPO/.relay-scratch" ] || [ -f "$REPO/probe_output.txt" ]; then
  echo "FAIL: scratch probe file leaked to parent repository"
  exit 1
fi

# 4. Assert advisor transcript was written and contains findings
TRANSCRIPT="$(find "$OUT_DIR" -name "test_prog.codex.md" | head -1)"
if [ -z "$TRANSCRIPT" ] || ! grep -qF "Direct answer: everything is verified" "$TRANSCRIPT"; then
  echo "FAIL: advisor transcript missing or incomplete in $OUT_DIR"
  exit 1
fi

# 5. Assert prompt snapshot was recorded
PROMPT_FILE="$(find "$OUT_DIR" -name "test_prog.PROMPT.txt" | head -1)"
if [ -z "$PROMPT_FILE" ] || ! grep -qF "Inspect sample_code.py" "$PROMPT_FILE"; then
  echo "FAIL: prompt snapshot missing"
  exit 1
fi

echo "ALL GH-101 SYNTHETIC CONSULT TESTS PASSED"
exit 0
