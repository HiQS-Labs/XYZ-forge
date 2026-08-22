#!/usr/bin/env bash
# test/gh382-marathon-memory-telemetry.sh — GH-382 marathon memory telemetry test suite.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh382-marathon-memory-telemetry.sh; assertions verify: (1) compressor and free swap sampled at phase boundary and recorded; (2) builder and reviewer peak RSS captured separately; (3) low swap warning appears in run output; (4) tick analyze --- cost --- block includes memory section; (5) negative controls"}

source "$(dirname "$0")/_setup.sh" gh382-marathon-memory-telemetry
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/utils/py/marathon_drive.py"

ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh382@t
git -C "$ROOT" config user.name gh382
printf '.tick/\n' > "$ROOT/.gitignore"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"

# Agent stub that logs its turn and exits 0
AGENT_CMD="$WORK/turn-agent.sh"
cat > "$AGENT_CMD" << 'STUB_EOF'
#!/usr/bin/env bash
rf="$RELAY_FILE"
act="$RELAY_AGENT"
task="$RELAY_TASK"
if [ -n "$rf" ]; then
  if [ "$act" = "codex" ]; then
    python3 -c "import re; p = '$rf'; c = open(p).read(); open(p, 'w').write(re.sub(r'(?m)^STATUS:.*', 'STATUS: In Progress', c))"
    "$TICK_BIN" claim "$task" --agent codex --paths "$rf" >/dev/null 2>&1 || true
    "$TICK_BIN" release "$task" --agent codex --to agy >/dev/null 2>&1 || true
  else
    python3 -c "import re; p = '$rf'; c = open(p).read(); open(p, 'w').write(re.sub(r'(?m)^STATUS:.*', 'STATUS: Approved', c))"
    "$TICK_BIN" claim "$task" --agent agy --paths "$rf" >/dev/null 2>&1 || true
    "$TICK_BIN" done "$task" --agent agy >/dev/null 2>&1 || true
  fi
fi
exit 0
STUB_EOF
chmod +x "$AGENT_CMD"

# Builder/reviewer BINARIES need only EXIST: `marathon_drive.py` resolves them with
# `shutil.which(bin_name)` (utils/py/marathon_drive.py:315) and every turn in this suite is served
# by the stub agent above, so a real codex/agy is never invoked.
#
# Stubbing them here removes this suite's dependency on two CLIs that live in the AUTHOR's private
# PATH (`~/.local/bin`). Without this the suite FAILED — not skipped — for anyone who does not have
# them installed, which is every newcomer. Found by the public-launch gate (#563): the artifact's
# own suite went red under a scrubbed environment, and this was the cause.
#
# Stubbing is deliberately preferred to skipping. A skip would delete the memory-telemetry
# assertions on exactly the machines least likely to have been tested; these stubs keep every
# assertion running everywhere, and they also make the suite deterministic on a machine that DOES
# have the real CLIs, since the stub shadows them.
STUB_BIN="$WORK/bin"
mkdir -p "$STUB_BIN"
for _b in codex agy aider pi; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN/$_b"
  chmod +x "$STUB_BIN/$_b"
done
export PATH="$STUB_BIN:$PATH"

run_driver() {
  MARATHON_ROOT="$ROOT" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  MARATHON_AGENT_CMD="$AGENT_CMD" \
  python3 "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder codex \
    "$@"
}

# --- (1) Acceptance criterion 1: Phase boundary memory sampling in run output ---
run_driver --phase-id p1 --relay-task MARATHON-P1-TURN > "$WORK/p1.log" 2>&1 || true

grep -q "memory-telemetry: phase p1-start boundary" "$WORK/p1.log" \
  && pass "GH-382: phase start memory telemetry sampled and logged" \
  || fail "missing phase start memory telemetry in log"

grep -q "memory-telemetry: phase p1-complete boundary" "$WORK/p1.log" \
  && pass "GH-382: phase complete memory telemetry sampled and logged" \
  || { echo "=== p1.log ==="; cat "$WORK/p1.log"; fail "missing phase complete memory telemetry in log"; }

# --- (2) Acceptance criterion 2: cost.memory events emitted to tick ---
TICK_REPO_ROOT="$ROOT" "$TICK" cost MARATHON-P1-TURN --agent codex --peak-rss-mb 128 >/dev/null
TICK_REPO_ROOT="$ROOT" "$TICK" cost MARATHON-P1-TURN --agent agy --peak-rss-mb 64 >/dev/null
TICK_REPO_ROOT="$ROOT" "$TICK" cost MARATHON-P1-TURN --agent marathon --compressor-mb 256 --swap-free-mb 4096 >/dev/null

analysis="$(TICK_REPO_ROOT="$ROOT" "$TICK" analyze)"
grep -q "memory:" <<<"$(printf '%s\n' "$analysis")" \
  && pass "GH-382: tick analyze includes memory section" \
  || { echo "=== analysis ==="; printf '%s\n' "$analysis"; fail "tick analyze missing memory section"; }

grep -qE "compressor peak: [0-9]+MB" <<<"$(printf '%s\n' "$analysis")" \
  && pass "GH-382: tick analyze reports compressor peak" \
  || fail "tick analyze missing compressor peak"

grep -qE "swap free min: [0-9]+MB" <<<"$(printf '%s\n' "$analysis")" \
  && pass "GH-382: tick analyze reports swap free min" \
  || fail "tick analyze missing swap free min"

grep -q "codex: 128MB peak RSS" <<<"$(printf '%s\n' "$analysis")" \
  && pass "GH-382: builder and reviewer peak RSS reported separately (codex)" \
  || fail "tick analyze missing codex peak RSS"

grep -q "agy: 64MB peak RSS" <<<"$(printf '%s\n' "$analysis")" \
  && pass "GH-382: builder and reviewer peak RSS reported separately (agy)" \
  || fail "tick analyze missing agy peak RSS"

# --- (3) Acceptance criterion 3: Low swap warning in output ---
# Test low swap warning by invoking memory sampler directly under low swap
low_swap_out="$(python3 -c "
import sys, os
sys.path.insert(0, '$ROOT_REPO/utils/py')
import marathon_drive
orig_run = marathon_drive.subprocess.run
class FakeRes:
    stdout = 'total = 3072.00M used = 2560.00M free = 512.00M (encrypted)'
marathon_drive.subprocess.run = lambda *a, **kw: FakeRes()
marathon_drive._phase_memory_sample('test-low-swap')
")"

grep -q "warn: host free swap is critically low (512MB < 1024MB)" <<<"$(printf '%s\n' "$low_swap_out")" \
  && pass "GH-382: low-swap warning logged when free swap is below threshold" \
  || fail "low-swap warning missing when free swap is low"

# --- (4) Acceptance criterion 4: Negative controls ---
# Empty repo without memory events must omit memory section
EMPTY_WORK="$WORK/empty_target"
mkdir -p "$EMPTY_WORK"
git init -q "$EMPTY_WORK"
git -C "$EMPTY_WORK" config user.email empty@t
git -C "$EMPTY_WORK" config user.name empty
printf '.tick/\n' > "$EMPTY_WORK/.gitignore"
git -C "$EMPTY_WORK" add .gitignore
git -C "$EMPTY_WORK" commit -q -m init
TICK_REPO_ROOT="$EMPTY_WORK" "$TICK" claim T1 --agent codex --paths foo >/dev/null
TICK_REPO_ROOT="$EMPTY_WORK" "$TICK" done T1 --agent codex >/dev/null
empty_analysis="$(TICK_REPO_ROOT="$EMPTY_WORK" "$TICK" analyze)"

if grep -q "memory:" <<<"$(printf '%s\n' "$empty_analysis")"; then
  fail "negative control failed: empty repo analyze unexpectedly contained memory section"
else
  pass "GH-382 (negative control): analyze omits memory section when no memory telemetry recorded"
fi

pass "GH-382: all marathon memory telemetry tests passed"
exit 0
