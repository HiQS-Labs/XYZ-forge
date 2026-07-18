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
# GH-178 A2 non-regression: a FULL panel (both requested advisors answered) must never be stamped.
printf '%s' "$out" | grep -q "SINGLE-MODEL" && fail "full 2/2 panel wrongly stamped degraded: $out" \
  || pass "full panel is not stamped"

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
# GH-178 A2: a 2-requested/1-survived degrade must be MECHANICALLY stamped — in stdout, in the
# surviving transcript itself, and in a format-agnostic sidecar — not just left as a stdout line an
# operator could miss.
printf '%s' "$out" | grep -q "SINGLE-MODEL — NOT RECONCILED" && pass "degrade stamped on stdout" \
  || fail "stdout missing SINGLE-MODEL stamp: $out"
cfile3="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
grep -q "SINGLE-MODEL — NOT RECONCILED" "$cfile3" 2>/dev/null && pass "degrade stamped INTO the surviving transcript" \
  || fail "surviving transcript missing stamp: $cfile3"
grep -q "ANSWER from codex" "$cfile3" 2>/dev/null && pass "stamped transcript still has the real answer beneath the stamp" \
  || fail "stamping corrupted the transcript content: $cfile3"
sidecar3="$(dirname "$cfile3")/DEGRADED-SINGLE-MODEL.txt"
[ -s "$sidecar3" ] && pass "format-agnostic sidecar marker written" || fail "no sidecar marker at $sidecar3"

# --- (4) all advisors fail -> exit 5 -----------------------------------------------------------
rm -rf "$OUT"
CODEX_RC=1 GEMINI_RC=1 STUB_WRITE=0 run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "all-fail exits 5" || fail "all-fail exit=$rc (expected 5)"

# --- (5) non-git root refused (exit 3), not silently run unisolated -----------------------------
mkdir -p "$WORK/plain"
CONSULT_ROOT="$WORK/plain" CODEX_BIN="$STUB" GEMINI_BIN="$STUB" \
  bash "$CONSULT" --prompt "x" --out "$WORK/pout" --label t --models codex >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "non-git root refused (exit 3)" || fail "non-git root exit=$rc (expected 3)"

# --- (5b) GH-178 A1: advisor dispatch is a data table (ADV_NAMES/ADV_RUNFNS), not a case statement.
# An unknown model name is skipped with a warning, not treated as a fatal error, and does not stop a
# VALID model in the same --models list from still running.
rm -rf "$OUT"
out5b="$(CONSULT_ROOT="$A" CODEX_BIN="$STUB" bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models "codex,nosuchvendor" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "unknown model alongside a valid one still exits 0" || fail "unknown-model run exit=$rc (expected 0)"
printf '%s' "$out5b" | grep -q "unknown model 'nosuchvendor' — skipping" \
  && pass "unknown model name warned and skipped (not treated as a case fallthrough)" \
  || fail "missing unknown-model warning: $out5b"
[ -f "$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)" ] \
  && pass "the valid model in the list still ran despite the unknown sibling" \
  || fail "valid model did not run alongside an unknown one"

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
# GH-178 A2 non-regression: a DELIBERATE single-model request (--models aider alone) is not a
# degrade — it must never get the SINGLE-MODEL stamp.
printf '%s' "$out" | grep -q "SINGLE-MODEL" && fail "intentional single-model request wrongly stamped: $out" \
  || pass "intentional single-model request is not stamped"
grep -q "SINGLE-MODEL" "$afile" 2>/dev/null && fail "intentional single-model transcript wrongly stamped" \
  || pass "intentional single-model transcript not stamped"

# --- (8) AIDER no OPENROUTER_API_KEY -> that advisor fails fast (all-fail exit 5, with the remedy) --
rm -rf "$OUT"
out="$(env -u OPENROUTER_API_KEY CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" \
  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 5 ] && pass "aider with no OPENROUTER_API_KEY -> all-fail exit 5" || fail "no-key aider exit=$rc (expected 5)"
afile="$(ls "$OUT"/t-*/t.aider.md 2>/dev/null | head -1)"
grep -q "OPENROUTER_API_KEY not set" "$afile" 2>/dev/null && pass "aider no-key transcript states the remedy" || fail "no-key remedy missing from transcript"

# --- (9) AIDER truthfulness: exit 0 + auth-error transcript is counted FAILED, not a false [ok] ----
# GH-147 spike 0.4: Aider can exit 0 while printing an auth/config error. Trusting the exit code alone
# false-greened the consult; consult must fail closed on the transcript.
AIDER_BADAUTH="$WORK/aider-badauth-stub"
cat >"$AIDER_BADAUTH" <<'EOF'
#!/usr/bin/env bash
set -u
# Impersonates Aider hitting a bad key: prints a litellm auth error to stdout, then EXITS 0.
printf 'litellm.AuthenticationError: OpenAIException - Incorrect API key provided\n'
exit 0
EOF
chmod +x "$AIDER_BADAUTH"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" AIDER_BIN="$AIDER_BADAUTH" OPENROUTER_API_KEY="$FAKE_ORK" \
  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 5 ] && pass "aider exit-0 auth-error transcript -> FAILED (all-fail exit 5)" || fail "false-green auth: exit=$rc (expected 5) ($out)"
printf '%s' "$out" | grep -q "0 answered, 1 failed" && pass "aider auth-error counted as failed, not answered" || fail "auth-error miscounted: $out"

# --- (10) AIDER truthfulness: exit 0 with an EMPTY answer (reasoning-only) is counted FAILED ---------
AIDER_EMPTY="$WORK/aider-empty-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$AIDER_EMPTY"; chmod +x "$AIDER_EMPTY"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" AIDER_BIN="$AIDER_EMPTY" OPENROUTER_API_KEY="$FAKE_ORK" \
  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 5 ] && pass "aider exit-0 empty answer -> FAILED (all-fail exit 5)" || fail "empty answer: exit=$rc (expected 5) ($out)"

# --- (11) LM Studio seam: AIDER_OPENAI_API_BASE runs WITHOUT OPENROUTER_API_KEY (GH-147) -------------
rm -rf "$OUT"
out="$(env -u OPENROUTER_API_KEY CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" \
  AIDER_OPENAI_API_BASE="http://127.0.0.1:1234/v1" \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "LM Studio base URL answers with no OPENROUTER_API_KEY (exit 0)" || fail "lmstudio seam exit=$rc ($out)"
printf '%s' "$out" | grep -q "1 answered, 0 failed" && pass "LM Studio-backed aider counted answered" || fail "lmstudio not counted: $out"

# --- (12) GH-178 A4 (scoped slice): an advisor answer with ZERO file:line/quote citations anywhere ----
# gets mechanically stamped NO FIRSTHAND VERIFICATION CITED — stdout, prepended-into-transcript, and a
# per-advisor sidecar file. This is presence/absence only, not accuracy verification.
NOCITE_STUB="$WORK/nocite-stub"
cat >"$NOCITE_STUB" <<'EOF'
#!/usr/bin/env bash
printf 'ANSWER: this looks correct.\n[Pass] no issues found\nRECOMMENDATION: ship\n'
EOF
chmod +x "$NOCITE_STUB"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" CODEX_BIN="$NOCITE_STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "uncited-answer run still exits 0 (mechanical stamp only, not a failure)" || fail "uncited-answer exit=$rc"
printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" && pass "uncited answer warned on stdout" \
  || fail "stdout missing NO FIRSTHAND VERIFICATION CITED warning: $out"
ncfile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
grep -q "NO FIRSTHAND VERIFICATION CITED" "$ncfile" 2>/dev/null && pass "uncited answer stamped INTO the transcript" \
  || fail "transcript missing NO FIRSTHAND VERIFICATION CITED stamp: $ncfile"
grep -q "ANSWER: this looks correct." "$ncfile" 2>/dev/null && pass "stamping preserved the real answer beneath it" \
  || fail "stamping corrupted the transcript content: $ncfile"
sidecar4="$(dirname "$ncfile")/t.codex.NO-CITATION.txt"
[ -s "$sidecar4" ] && pass "per-advisor NO-CITATION sidecar file written" || fail "no sidecar marker at $sidecar4"

# --- (13) GH-178 A4 non-regression: an advisor answer where EVERY claim is cited near itself (quote
# or file:line) is NOT stamped. Each claim carries its OWN nearby citation (not just one citation
# somewhere in the transcript) — see test (14) below for why that distinction matters post-follow-up.
CITE_STUB="$WORK/cite-stub"
cat >"$CITE_STUB" <<'EOF'
#!/usr/bin/env bash
printf 'ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.\n[Pass] verified — see relay-automation/consult.sh:266\nRECOMMENDATION: ship\n'
EOF
chmod +x "$CITE_STUB"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" CODEX_BIN="$CITE_STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED" && fail "cited answer wrongly stamped: $out" \
  || pass "cited answer (quote + file:line) is not stamped"
cfile4="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
grep -q "NO FIRSTHAND VERIFICATION CITED" "$cfile4" 2>/dev/null && fail "cited transcript wrongly stamped" \
  || pass "cited transcript not stamped"
[ -f "$(dirname "$cfile4")/t.codex.NO-CITATION.txt" ] && fail "sidecar wrongly written for a cited answer" \
  || pass "no sidecar written for a cited answer"

# --- (14) code-review follow-up on PR #184 (items 1 & 3): a SECOND, LATER claim with no citation
# nearby it now gets flagged even though the transcript cites something earlier. The original A4
# check only asked "is there a citation ANYWHERE in the whole transcript" — one early citation would
# have excused this later uncited [Pass] claim. It now correctly does not.
PARTIAL_CITE_STUB="$WORK/partial-cite-stub"
cat >"$PARTIAL_CITE_STUB" <<'EOF'
#!/usr/bin/env bash
printf 'ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.\nLater: [Pass] this other part also looks fine\nRECOMMENDATION: ship\n'
EOF
chmod +x "$PARTIAL_CITE_STUB"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" CODEX_BIN="$PARTIAL_CITE_STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" \
  && pass "a later uncited claim is flagged despite an earlier unrelated citation (per-claim, not whole-transcript)" \
  || fail "later uncited claim NOT flagged despite an earlier citation excusing it: $out"
pfile4="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
grep -q "this other part also looks fine" "$pfile4" 2>/dev/null && pass "stamping preserved the real answer beneath it" \
  || fail "stamping corrupted the transcript content: $pfile4"

# --- (15) GH-235 A4 v0 echoed-citation provenance: a cited claim whose citation already appears in
# the operator prompt is classified ECHOED, written to PROVENANCE.txt, and warned once on stdout.
ECHOED_STUB="$WORK/echoed-stub"
cat >"$ECHOED_STUB" <<'EOF'
#!/usr/bin/env bash
printf 'ANSWER: verified — see relay-automation/consult.sh:266.\n[Pass] confirmed by relay-automation/consult.sh:266\nRECOMMENDATION: ship\n'
EOF
chmod +x "$ECHOED_STUB"
rm -rf "$OUT"
echo_prompt='Review relay-automation/consult.sh:266 and tell me if it checks out.'
out="$(CONSULT_ROOT="$A" CODEX_BIN="$ECHOED_STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "$echo_prompt" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "echoed-citation run exits 0" || fail "echoed-citation exit=$rc ($out)"
printf '%s' "$out" | grep -q "prompt-trace classifier: codex echoed 2 cited claim(s)" \
  && pass "echoed-citation stdout warns once with the echoed count" \
  || fail "missing echoed-citation warning: $out"
efile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
epsnap="$(dirname "$efile")/t.PROMPT.txt"
grep -qxF "$echo_prompt" "$epsnap" 2>/dev/null && pass "prompt snapshot persisted PROMPT_TEXT only" \
  || fail "prompt snapshot missing or mutated: $epsnap"
grep -q "INDEPENDENT advisor" "$epsnap" 2>/dev/null && fail "prompt snapshot wrongly includes PREAMBLE" \
  || pass "prompt snapshot excludes PREAMBLE"
eprov="$(dirname "$efile")/t.codex.PROVENANCE.txt"
grep -q '^FIRSTHAND_COUNT=0$' "$eprov" 2>/dev/null && pass "echoed provenance counted zero firsthand claims" \
  || fail "echoed provenance missing FIRSTHAND_COUNT=0: $eprov"
grep -q '^ECHOED_COUNT=2$' "$eprov" 2>/dev/null && pass "echoed provenance counted echoed claims" \
  || fail "echoed provenance missing ECHOED_COUNT=2: $eprov"
grep -q '^ECHOED relay-automation/consult.sh:266$' "$eprov" 2>/dev/null \
  && pass "echoed provenance records the matched token" \
  || fail "echoed provenance missing matched token: $eprov"

# --- (16) GH-235 A4 v0 firsthand-citation provenance: a cited claim whose citation is NOT in the
# prompt is classified FIRSTHAND, sidecar-only, with no echoed warn line.
FIRSTHAND_STUB="$WORK/firsthand-stub"
cat >"$FIRSTHAND_STUB" <<'EOF'
#!/usr/bin/env bash
printf 'ANSWER: verified — see relay-automation/consult.sh:266.\n[Pass] confirmed by relay-automation/consult.sh:266\nRECOMMENDATION: ship\n'
EOF
chmod +x "$FIRSTHAND_STUB"
rm -rf "$OUT"
out="$(CONSULT_ROOT="$A" CODEX_BIN="$FIRSTHAND_STUB" CODEX_FLAGS=" " \
  bash "$CONSULT" --prompt "Review relay-automation/consult.sh carefully." --out "$OUT" --label t --models codex 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "firsthand-citation run exits 0" || fail "firsthand-citation exit=$rc ($out)"
printf '%s' "$out" | grep -q "prompt-trace classifier:" \
  && fail "firsthand-citation run wrongly warned echoed provenance: $out" \
  || pass "firsthand-citation run emits no echoed warning"
ffile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
fprov="$(dirname "$ffile")/t.codex.PROVENANCE.txt"
grep -q '^FIRSTHAND_COUNT=2$' "$fprov" 2>/dev/null && pass "firsthand provenance counted firsthand claims" \
  || fail "firsthand provenance missing FIRSTHAND_COUNT=2: $fprov"
grep -q '^ECHOED_COUNT=0$' "$fprov" 2>/dev/null && pass "firsthand provenance counted zero echoed claims" \
  || fail "firsthand provenance missing ECHOED_COUNT=0: $fprov"
grep -q '^ECHOED ' "$fprov" 2>/dev/null && fail "firsthand provenance wrongly recorded echoed tokens" \
  || pass "firsthand provenance records no echoed tokens"


# --- (17) GH-215: XYZ_PYTHON=1 parity — the Python port must stamp SINGLE-MODEL — NOT RECONCILED
# the same way Bash does. GH-172's prior audit found the tick-root/cost-routing fix landed in
# utils/py/consult.py but the degraded-panel stamp (GH-178 A2) was never ported, so a Python-mode
# consult run under a single-advisor-answered condition silently reported as if reconciled. This
# forces XYZ_PYTHON=1 explicitly (independent of how the rest of this file is invoked) so the
# regression is caught even under a plain `bash test/consult.sh` run.
rm -rf "$OUT"
out="$(XYZ_PYTHON=1 CODEX_RC=0 GEMINI_RC=1 STUB_WRITE=0 run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "XYZ_PYTHON=1 one-model failure still exits 0 (graceful degrade)" \
  || fail "XYZ_PYTHON=1 degrade exit=$rc"
printf '%s' "$out" | grep -q "SINGLE-MODEL — NOT RECONCILED" && pass "XYZ_PYTHON=1 degrade stamped on stdout" \
  || fail "XYZ_PYTHON=1 stdout missing SINGLE-MODEL stamp: $out"
cfile15="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
grep -q "SINGLE-MODEL — NOT RECONCILED" "$cfile15" 2>/dev/null \
  && pass "XYZ_PYTHON=1 degrade stamped INTO the surviving transcript" \
  || fail "XYZ_PYTHON=1 surviving transcript missing stamp: $cfile15"
grep -q "ANSWER from codex" "$cfile15" 2>/dev/null \
  && pass "XYZ_PYTHON=1 stamped transcript still has the real answer beneath the stamp" \
  || fail "XYZ_PYTHON=1 stamping corrupted the transcript content: $cfile15"
sidecar15="$(dirname "$cfile15")/DEGRADED-SINGLE-MODEL.txt"
[ -s "$sidecar15" ] && pass "XYZ_PYTHON=1 format-agnostic sidecar marker written" \
  || fail "XYZ_PYTHON=1 no sidecar marker at $sidecar15"

# --- (18) GH-215 non-regression: XYZ_PYTHON=1 must NOT stamp a full 2/2 panel as degraded ----------
rm -rf "$OUT"
out="$(XYZ_PYTHON=1 STUB_WRITE=0 run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "XYZ_PYTHON=1 happy path exits 0" || fail "XYZ_PYTHON=1 happy path exit=$rc ($out)"
printf '%s' "$out" | grep -q "SINGLE-MODEL" \
  && fail "XYZ_PYTHON=1 full 2/2 panel wrongly stamped degraded: $out" \
  || pass "XYZ_PYTHON=1 full panel is not stamped"

echo "  consult: $PASS passed, $FAIL failed"
exit 0
