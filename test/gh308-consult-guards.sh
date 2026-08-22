#!/usr/bin/env bash
# test/gh308-consult-guards.sh — GH-308 audit: two consult.sh behaviors were missing from consult.py
# (the lane that runs since GH-264), so they were silently dead on the default lane:
#   1. [Missing guard] the GH-178 B1 agy isolation-breach detector — a successful agy run whose
#      transcript cited the REAL repo root (grounding escaped its throwaway worktree) must FAIL the
#      advisor (Bash `return 5`). Python counted the breached run as a clean cross-model answer.
#   2. [Inert feature] the codex ATTESTATION provenance header (which model/provider/sandbox actually
#      answered), prepended to every codex transcript.
# Both cases drive the DEFAULT (Python) lane with stub advisor binaries — no real API calls.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CONSULT="$ROOT/relay-automation/consult.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh308-consult-guards.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh308-consult-guards =="
echo "  workdir: $WORK"

REPO="$WORK/repo"; git init -q "$REPO"
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
OUT="$WORK/out"; mkdir -p "$OUT"

# codex stub: emit the provenance lines consult parses, plus an answer.
CODEX="$WORK/codex.sh"
cat >"$CODEX" <<'EOF'
#!/usr/bin/env bash
printf 'model: gpt-stub-9\nprovider: openai-stub\nsandbox: read-only\n\nHere is the answer. [Pass] verified via "a quoted span".\n'
exit 0
EOF
chmod +x "$CODEX"

# agy stub: `whoami` passes the auth pre-flight; the real turn prints a line citing the REAL repo root
# (an isolation breach — grounding read outside the throwaway worktree).
AGY="$WORK/agy.sh"
cat >"$AGY" <<'EOF'
#!/usr/bin/env bash
case "$1" in whoami) echo "agystub"; exit 0 ;; esac
printf 'I inspected files under %s and here is my take. [Pass] confirmed.\n' "$CONSULT_ROOT"
exit 0
EOF
chmod +x "$AGY"

find_transcript() { find "$OUT" -name "$1" | head -1; }

# ── (1) codex ATTESTATION header on the default lane ─────────────────────────────────────
CONSULT_ROOT="$REPO" CODEX_BIN="$CODEX" bash "$CONSULT" --prompt "q" --models codex --out "$OUT" --label cx >/dev/null 2>&1; rc_cx=$?
cx="$(find_transcript 'cx.codex.md')"
if grep -qF '> **ATTESTATION**' <<<"$([ -n "$cx" ] && head -1 "$cx")" \
   && grep -qF '> Model: gpt-stub-9' "$cx" && grep -qF '> Provider: openai-stub' "$cx" && grep -qF '> Sandbox: read-only' "$cx"; then
  pass "consult default lane: codex transcript is stamped with the ATTESTATION provenance header"
else
  fail "consult default lane: codex ATTESTATION header missing (rc=$rc_cx): $([ -n "$cx" ] && head -3 "$cx" || echo '<no transcript>')"
fi

# ── (2) agy isolation-breach detector on the default lane ────────────────────────────────
out_ay="$(CONSULT_ROOT="$REPO" AGY_BIN="$AGY" bash "$CONSULT" --prompt "q" --models agy --out "$OUT" --label ay 2>&1)"; rc_ay=$?
ay="$(find_transcript 'ay.agy.md')"
# With only agy consulted and its single answer failed by the breach detector, consult reports all
# advisors failed → exit 5. Pre-port the breach was undetected → the answer counted → exit 0.
[ "$rc_ay" -eq 5 ] \
  && pass "consult default lane: a breached agy run is counted FAILED (all-advisors-failed, exit 5)" \
  || fail "consult default lane: expected exit 5 for a breached agy advisor, got rc=$rc_ay — $out_ay"
if [ -n "$ay" ] && grep -qF 'agy transcript cited the real repo root' "$ay"; then
  pass "consult default lane: the breach is stamped into the agy transcript"
else
  fail "consult default lane: breach FAIL line missing from the agy transcript: $([ -n "$ay" ] && cat "$ay" || echo '<no transcript>')"
fi

# ── (3) NO false positive: an agy run that does NOT cite the real root is a normal answer ──
CLEAN_AGY="$WORK/agy-clean.sh"
cat >"$CLEAN_AGY" <<'EOF'
#!/usr/bin/env bash
case "$1" in whoami) echo "agystub"; exit 0 ;; esac
printf 'Reviewed the worktree copy. [Pass] verified via "the quoted span at line 4".\n'
exit 0
EOF
chmod +x "$CLEAN_AGY"
out_clean="$(CONSULT_ROOT="$REPO" AGY_BIN="$CLEAN_AGY" bash "$CONSULT" --prompt "q" --models agy --out "$OUT" --label ayc 2>&1)"; rc_clean=$?
ayc="$(find_transcript 'ayc.agy.md')"
[ "$rc_clean" -eq 0 ] && [ -n "$ayc" ] && ! grep -qF 'isolation breach' "$ayc" \
  && pass "consult default lane: a clean agy run (no real-root citation) is NOT flagged (exit 0)" \
  || fail "consult default lane: a clean agy run was wrongly flagged (rc=$rc_clean): $out_clean"

echo "  gh308-consult-guards: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
