#!/usr/bin/env bash
# consult.sh test — the cross-model CONSULT fan-out (relay-automation/consult.sh).
# Uses a STUB that impersonates both codex (`exec` first arg) and gemini (`--yolo` first arg), so no
# network/real CLI is needed. Focuses on the safety properties the dogfood flagged as Blockers:
#   - operator WIP is preserved (advisors run in a throwaway worktree, never the real tree)
#   - an advisor that WRITES cannot leak into the operator's tree
#   - graceful per-model degrade (one fails -> still exit 0); all-fail -> exit 5
#   - non-git root is refused (exit 3) rather than running unisolated
source "$(dirname "$0")/_setup.sh" consult
CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"

# Fixture: a tracked file, committed, then left DIRTY (uncommitted operator WIP).
printf 'original\n' >"$A/tracked.txt"
git -C "$A" add tracked.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed tracked" >/dev/null 2>&1
printf 'WIP\n' >"$A/tracked.txt"   # operator's uncommitted work — must survive a consult

# One stub for both advisors: detects which it is by argv, picks its RC, optionally writes (in CWD,
# which consult sets to the throwaway worktree — so any write must NOT reach $A).
STUB="$WORK/advisor-stub"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = "exec" ]; then who=codex; rc="${CODEX_RC:-0}"; else who=gemini; rc="${GEMINI_RC:-0}"; fi
printf 'ANSWER from %s stub\n[Pass] looks fine\nRECOMMENDATION: ship\n' "$who"
if [ "${STUB_WRITE:-0}" = 1 ]; then
  printf 'pwned by %s\n' "$who" > "pwned-by-$who.txt" 2>/dev/null || true   # CWD = worktree
  [ -f tracked.txt ] && printf 'advisor was here\n' >> tracked.txt 2>/dev/null || true
fi
exit "$rc"
STUB_EOF
chmod +x "$STUB"

OUT="$WORK/cout"   # transcripts OUTSIDE $A, so $A stays clean for the safety assertion
run() { # env passthrough: CODEX_RC, GEMINI_RC, STUB_WRITE set by caller
  CONSULT_ROOT="$A" CODEX_BIN="$STUB" GEMINI_BIN="$STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex,gemini "$@"
}

# --- (1) happy path: both answer, transcripts captured ------------------------------------------
out="$(STUB_WRITE=0 run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "happy path exits 0" || fail "happy path exit=$rc ($out)"
cfile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
gfile="$(ls "$OUT"/t-*/t.gemini.md 2>/dev/null | head -1)"
{ [ -s "$cfile" ] && grep -q "ANSWER from codex" "$cfile"; } && pass "codex transcript captured" || fail "no codex transcript"
{ [ -s "$gfile" ] && grep -q "ANSWER from gemini" "$gfile"; } && pass "gemini transcript captured" || fail "no gemini transcript"

# --- (2) SAFETY: advisor writes cannot leak; operator WIP preserved -----------------------------
rm -rf "$OUT"
STUB_WRITE=1 run >/dev/null 2>&1 || true
[ "$(cat "$A/tracked.txt")" = "WIP" ] && pass "operator WIP preserved (tracked.txt still WIP)" \
  || fail "operator WIP clobbered: $(cat "$A/tracked.txt")"
if find "$A" -name 'pwned-by-*.txt' 2>/dev/null | grep -q .; then
  fail "advisor write leaked into operator tree"
else
  pass "advisor writes did NOT leak into operator tree"
fi
porc="$(git -C "$A" status --porcelain)"
[ "$porc" = " M tracked.txt" ] && pass "tree shows ONLY the operator's WIP, no advisor churn" \
  || fail "unexpected tree state: [$porc]"
# no leftover worktrees
[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "isolation worktree cleaned up" \
  || fail "worktree left behind: $(git -C "$A" worktree list)"

# --- (3) graceful degrade: gemini fails, codex still answers ------------------------------------
rm -rf "$OUT"
out="$(CODEX_RC=0 GEMINI_RC=1 STUB_WRITE=0 run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "one-model failure still exits 0 (graceful degrade)" || fail "degrade exit=$rc"
printf '%s' "$out" | grep -q "1 answered, 1 failed" && pass "degrade reported honestly (1 answered, 1 failed)" \
  || fail "degrade not reported: $out"

# --- (4) all advisors fail -> exit 5 -----------------------------------------------------------
rm -rf "$OUT"
CODEX_RC=1 GEMINI_RC=1 STUB_WRITE=0 run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "all-fail exits 5" || fail "all-fail exit=$rc (expected 5)"

# --- (5) non-git root refused (exit 3), not silently run unisolated -----------------------------
mkdir -p "$WORK/plain"
CONSULT_ROOT="$WORK/plain" CODEX_BIN="$STUB" GEMINI_BIN="$STUB" \
  bash "$CONSULT" --prompt "x" --out "$WORK/pout" --label t --models codex >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "non-git root refused (exit 3)" || fail "non-git root exit=$rc (expected 3)"

# --- (6) per-advisor timeout: a hung advisor is killed and counted as failed -------------------
# Slow stub sleeps past a 1s cap; single-model run must end (not hang) and exit 5 (its only advisor died).
SLOW="$WORK/slow-stub"
printf '#!/usr/bin/env bash\nsleep 30\n' >"$SLOW"; chmod +x "$SLOW"
rm -rf "$OUT"
start=$(date +%s)
CONSULT_ROOT="$A" CODEX_BIN="$SLOW" CODEX_FLAGS=" " CONSULT_TIMEOUT=1 \
  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models codex >/dev/null 2>&1; rc=$?
elapsed=$(( $(date +%s) - start ))
[ "$rc" -eq 5 ] && pass "hung advisor times out -> all-fail exit 5" || fail "timeout exit=$rc (expected 5)"
[ "$elapsed" -lt 20 ] && pass "timeout actually fired (${elapsed}s < 20s, not the 30s sleep)" \
  || fail "timeout did not fire: waited ${elapsed}s"

# --- (7) AIDER advisor: answers via a stub, transcript captured (Aider↔OpenRouter lane) ----------
# Non-secret key via a var (not a literal) so the security-scan credential rule's variable exclusion applies.
FAKE_ORK="orkey-not-real"
AIDER_STUB="$WORK/aider-stub"
cat >"$AIDER_STUB" <<'EOF'
#!/usr/bin/env bash
set -u
# Aider advisory stub: prints an answer to stdout (consult captures it). Ignores flags; never edits.
printf 'ANSWER from aider stub\n[Pass] looks fine\nRECOMMENDATION: ship\n'
exit "${AIDER_RC:-0}"
EOF
chmod +x "$AIDER_STUB"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" OPENROUTER_API_KEY="$FAKE_ORK" \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "aider advisor answers (exit 0)" || fail "aider exit=$rc ($out)"
afile="$(ls "$OUT"/t-*/t.aider.md 2>/dev/null | head -1)"
{ [ -s "$afile" ] && grep -q "ANSWER from aider" "$afile"; } && pass "aider transcript captured" || fail "no aider transcript"
printf '%s' "$out" | grep -q "1 answered, 0 failed" && pass "aider counted as an answered advisor" || fail "aider not counted answered: $out"

# --- (8) AIDER no OPENROUTER_API_KEY -> that advisor fails fast (all-fail exit 5, with the remedy) --
rm -rf "$OUT"
out="$(env -u OPENROUTER_API_KEY CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" \
  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 5 ] && pass "aider with no OPENROUTER_API_KEY -> all-fail exit 5" || fail "no-key aider exit=$rc (expected 5)"
afile="$(ls "$OUT"/t-*/t.aider.md 2>/dev/null | head -1)"
grep -q "OPENROUTER_API_KEY not set" "$afile" 2>/dev/null && pass "aider no-key transcript states the remedy" || fail "no-key remedy missing from transcript"

echo "  consult: $PASS passed, $FAIL failed"
exit 0
