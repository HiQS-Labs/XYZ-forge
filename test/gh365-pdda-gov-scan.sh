#!/usr/bin/env bash
# gh365-pdda-gov-scan.sh — GH-365 step 4: the per-doc governance reference scanner.
#
# The hot path this closes: check_governance extracted references one LINE at a time (four
# printf|grep|sed pipelines per line, every doc scanned twice — ~78% of an 87s `pdda.sh run` on
# macOS). utils/py/pdda_gov_scan.py does ONE in-process scan per doc; check_governance caches the
# "<lineno>\t<ref>" list per doc and both passes read the cache, with the legacy per-line path
# kept as a fail-safe fallback.
#
# What this suite witnesses:
#   A. EQUIVALENCE on the real governance docs — the scanner's output is byte-identical to the
#      LIVE legacy functions (extracted from pdda.sh by name, so a legacy edit re-witnesses
#      equivalence) over every doc of PDDA_GOVERNANCE_DOCS_DEFAULT present in this repo.
#   B. Synthetic corpus — one line per pattern shape (markdown link, anchored link, code span,
#      command-position at line start and after a backtick, each interpreter wrapper, and the
#      negatives: exempt-fence mention, blockquote mention, GH-*.md names, deploy.sh.bak,
#      bash -c). Both paths must agree AND the scanner must get every shape right.
#   C. RED control — a fixture doc with a genuinely dead .md reference makes check_governance
#      emit the dead-reference warn on BOTH the scanner path and the forced-legacy path
#      (PDDA_GOV_SCAN pointed at a nonexistent file), with identical findings text.
#   D. PDDA_TIMINGS smoke — PDDA_TIMINGS=1 prints at least one "PDDA_TIMING <check> <ms>" line
#      to stderr and leaves stdout byte-identical; without it, zero timing lines.
#   E. Speed — the scanner runs at most once per doc per run (PATH-shim invocation counter over
#      a two-doc fixture), and a real-repo `pdda.sh governance` completes under a generous 30s
#      ceiling (observed ~5s post-change, ~72s pre-change; recorded in the commit message — the
#      ceiling is flake headroom, not the claim).
source "$(dirname "$0")/_setup.sh" gh365-pdda-gov-scan
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PDDA="$REPO/utils/pdda/pdda.sh"
SCANNER="$REPO/utils/py/pdda_gov_scan.py"

[ -f "$SCANNER" ] || fail "A0: scanner missing at $SCANNER"
[ -f "$PDDA" ] || fail "A0: pdda.sh missing at $PDDA"

# The LIVE legacy functions, extracted from pdda.sh by name markers (they have no pdda-lib
# dependencies — pure awk/grep/sed). Extracting the live text (rather than pinning a copy here)
# is the point: if someone edits the legacy path, this suite re-witnesses equivalence against it.
LEGACY="$WORK/gov-legacy-funcs.sh"
awk '/^_pdda_gov_scannable_lines\(\) \{/{grab=1} /^_pdda_gov_glob_escape\(\) \{/{grab=0} grab' \
  "$PDDA" > "$LEGACY"
[ "$(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")" -eq 2 ] \
  || fail "A0: expected exactly 2 legacy _pdda_gov_* functions between the markers, got $(grep -c '^_pdda_gov_[a-z_]*() {' "$LEGACY")"

# The legacy driver — EXACTLY check_governance's pre-GH-365 nested loops (scannable lines, then
# per-line extraction), emitting the same "<lineno>\t<ref>" stream the scanner produces.
cat > "$WORK/legacy-driver.sh" <<'DRV'
run_legacy() {
  local abs_file="$1" line_no text ref
  while IFS=$'\t' read -r line_no text; do
    [ -n "$line_no" ] || continue
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      printf '%s\t%s\n' "$line_no" "$ref"
    done <<< "$(_pdda_gov_extract_refs "$text")"
  done < <(_pdda_gov_scannable_lines "$abs_file")
}
DRV

legacy_scan() {  # <abs-doc> -> "<lineno>\t<ref>" lines via the live legacy functions
  (
    . "$LEGACY"
    . "$WORK/legacy-driver.sh"
    run_legacy "$1"
  )
}

echo "== test: gh365-pdda-gov-scan =="

# ── A. equivalence on the real governance docs ──────────────────────────────────────────────────
for doc in ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md PROJECT/PDDA.md utils/pdda/PDDA-INSTALL.md; do
  abs="$REPO/$doc"
  if [ ! -f "$abs" ]; then
    pass "A: $doc absent in this repo — skipped (CLAUDE.md is optional by design)"
    continue
  fi
  legacy_scan "$abs" > "$WORK/a-leg.txt"
  python3 "$SCANNER" "$abs" > "$WORK/a-scan.txt"
  if cmp -s "$WORK/a-leg.txt" "$WORK/a-scan.txt"; then
    pass "A: $doc — scanner byte-identical to legacy ($(wc -l < "$WORK/a-scan.txt" | tr -d ' ') refs)"
  else
    fail "A: $doc — scanner/legacy differ:"$'\n'"$(diff "$WORK/a-leg.txt" "$WORK/a-scan.txt" | head -10)"
  fi
done

# ── B. synthetic corpus — every pattern shape, positives and negatives ──────────────────────────
CORPUS="$WORK/corpus.md"
cat > "$CORPUS" <<'EOF'
# GH-365 synthetic corpus — one line per pattern shape

Links: [router](ROUTER.md) and [script](utils/x.sh) and [anchored](scripts/run.sh#setup).
Code spans: `deploy.md` and `lib/run.sh`.
utils/pdda/pdda-sync.sh push --force
After a backtick: `.xyz/utils/marathon-plan.sh --help`
bash utils/x.sh
sudo ./install.sh
env FOO=1 ./run.sh
sh setup.sh
bash -c "echo deploy.sh"

```console
fence-hidden.sh run
```

> quote-hidden.sh run

Filtered GH names: [one](GH-123-EXAMPLE.md) and `GH-456-y.md`.
deploy.sh.bak at line start must not extract.
A mid-sentence deploy.sh.bak stays silent too.
EOF

legacy_scan "$CORPUS" > "$WORK/b-leg.txt"
python3 "$SCANNER" "$CORPUS" > "$WORK/b-scan.txt"
cmp -s "$WORK/b-leg.txt" "$WORK/b-scan.txt" \
  && pass "B1: synthetic corpus — scanner byte-identical to legacy ($(wc -l < "$WORK/b-scan.txt" | tr -d ' ') refs)" \
  || fail "B1: synthetic corpus — scanner/legacy differ:"$'\n'"$(diff "$WORK/b-leg.txt" "$WORK/b-scan.txt" | head -10)"

# The hand-derived expectation: exactly these refs, nothing else. Line numbers are deliberately
# not pinned here — A already witnesses lineno fidelity; this pins the extracted ref SET.
awk -F'\t' '{print $2}' "$WORK/b-scan.txt" | LC_ALL=C sort -u > "$WORK/b-refs.txt"
cat > "$WORK/b-want.txt" <<'EOF'
.xyz/utils/marathon-plan.sh
ROUTER.md
deploy.md
install.sh
lib/run.sh
run.sh
scripts/run.sh#setup
setup.sh
utils/pdda/pdda-sync.sh
utils/x.sh
EOF
cmp -s "$WORK/b-refs.txt" "$WORK/b-want.txt" \
  && pass "B2: every pattern shape extracted exactly (10 refs)" \
  || fail "B2: ref set mismatch:"$'\n'"$(diff "$WORK/b-want.txt" "$WORK/b-refs.txt")"

# Negative controls, named one by one so a regression reads as its shape, not "set differs".
! grep -qx 'fence-hidden.sh' "$WORK/b-refs.txt" \
  && pass "B3: console-fence mention NOT extracted (exempt fence)" \
  || fail "B3: fence mention extracted — exempt-fence filter broken"
! grep -qx 'quote-hidden.sh' "$WORK/b-refs.txt" \
  && pass "B4: blockquote mention NOT extracted" \
  || fail "B4: blockquote mention extracted — blockquote filter broken"
! grep -Eq '^GH-[0-9]+-' "$WORK/b-refs.txt" \
  && pass "B5: GH-<n>-*.md illustrative names filtered" \
  || fail "B5: a GH-*.md name survived the filter"
! grep -qx 'deploy.sh' "$WORK/b-refs.txt" \
  && pass "B6: deploy.sh.bak does NOT yield deploy.sh (trailing . is not a terminator)" \
  || fail "B6: deploy.sh extracted from deploy.sh.bak"
grep -qx 'utils/x.sh' "$WORK/b-refs.txt" \
  && pass "B7: interpreter-wrapped bash utils/x.sh recovered" \
  || fail "B7: interpreter-wrapped extraction missing"

# ── C. RED control — a dead .md reference warns on BOTH the scanner and legacy paths ────────────
F="$WORK/fixture-root"
mkdir -p "$F"
require_fixture "$F" "governance red-control fixture root"
printf '# fixture index\n\nRead [guide](guide.md) and the missing [dead](dead-walkthrough.md).\n' > "$F/ROUTER.md"
printf '# guide\n\nBack to [router](ROUTER.md).\n' > "$F/guide.md"

run_gov() {  # <scanner-path> — check_governance against the fixture root
  PDDA_REPO_ROOT="$F" PDDA_GOVERNANCE_DOCS="ROUTER.md" PDDA_GOVERNANCE_INDEX="ROUTER.md" \
    PDDA_ACTIVITY_LOG=/dev/null PDDA_GOV_SCAN="$1" bash "$PDDA" governance
}

run_gov "$SCANNER" > "$WORK/c-scan.out" 2>&1
grep -q "dead reference 'dead-walkthrough.md'" "$WORK/c-scan.out" \
  && pass "C1: dead reference warns on the scanner path" \
  || fail "C1: scanner path stayed silent about the dead reference:"$'\n'"$(cat "$WORK/c-scan.out")"

run_gov "$WORK/no-such-scanner.py" > "$WORK/c-leg.out" 2>&1   # scanner file absent -> legacy fallback
grep -q "dead reference 'dead-walkthrough.md'" "$WORK/c-leg.out" \
  && pass "C2: dead reference warns on the forced-legacy fallback path" \
  || fail "C2: legacy fallback stayed silent about the dead reference:"$'\n'"$(cat "$WORK/c-leg.out")"

cmp -s "$WORK/c-scan.out" "$WORK/c-leg.out" \
  && pass "C3: both paths emit byte-identical governance findings" \
  || fail "C3: scanner/legacy findings differ on the fixture:"$'\n'"$(diff "$WORK/c-leg.out" "$WORK/c-scan.out")"

# ── D. PDDA_TIMINGS smoke — stderr-only decoration, zero stdout drift ───────────────────────────
TF="$WORK/timing-root"
mkdir -p "$TF"
require_fixture "$TF" "PDDA_TIMINGS fixture root"
PDDA_REPO_ROOT="$TF" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" run > "$WORK/d-off.out" 2> "$WORK/d-off.err"
PDDA_REPO_ROOT="$TF" PDDA_ACTIVITY_LOG=/dev/null PDDA_TIMINGS=1 bash "$PDDA" run > "$WORK/d-on.out" 2> "$WORK/d-on.err"
[ "$(grep -c '^PDDA_TIMING ' "$WORK/d-on.err")" -ge 1 ] \
  && pass "D1: PDDA_TIMINGS=1 prints $(grep -c '^PDDA_TIMING ' "$WORK/d-on.err") PDDA_TIMING lines to stderr" \
  || fail "D1: PDDA_TIMINGS=1 printed no PDDA_TIMING lines:"$'\n'"$(cat "$WORK/d-on.err")"
[ "$(grep -c '^PDDA_TIMING ' "$WORK/d-off.err")" -eq 0 ] \
  && pass "D2: without PDDA_TIMINGS, zero timing lines (default OFF)" \
  || fail "D2: timing lines appeared without PDDA_TIMINGS:"$'\n'"$(cat "$WORK/d-off.err")"
cmp -s "$WORK/d-off.out" "$WORK/d-on.out" \
  && pass "D3: stdout byte-identical with and without PDDA_TIMINGS (zero output drift)" \
  || fail "D3: PDDA_TIMINGS changed stdout:"$'\n'"$(diff "$WORK/d-off.out" "$WORK/d-on.out" | head -6)"

# ── E. speed — once per doc per run, and a real-repo ceiling ────────────────────────────────────
# E1: invocation count via a PATH shim that tallies every python3 call during ONE governance run
# over the two-doc fixture. The shim execs the real interpreter resolved BEFORE the shim PATH is
# prepended, so it cannot recurse, and the PATH change is scoped to this single invocation so the
# suite's own python3 calls (fixture guard) are not tallied.
SHIM="$WORK/pyshim"
mkdir -p "$SHIM"
REAL_PY="$(command -v python3)"
printf '#!/usr/bin/env bash\nn=$(( $(cat "%s/count" 2>/dev/null || echo 0) + 1 ))\nprintf %%s "$n" > "%s/count"\nexec "%s" "$@"\n' \
  "$SHIM" "$SHIM" "$REAL_PY" > "$SHIM/python3"
chmod +x "$SHIM/python3"
: > "$SHIM/count"
PDDA_REPO_ROOT="$F" PDDA_GOVERNANCE_DOCS="ROUTER.md guide.md" PDDA_GOVERNANCE_INDEX="ROUTER.md" \
  PDDA_ACTIVITY_LOG=/dev/null PATH="$SHIM:$PATH" bash "$PDDA" governance > "$WORK/e1.out" 2>&1
calls="$(cat "$SHIM/count")"
[ "$calls" -le 2 ] \
  && pass "E1: scanner invoked $calls time(s) for 2 docs in one run (cache retains across passes)" \
  || fail "E1: scanner invoked $calls times for 2 docs — the per-doc cache is not retaining"

# E2: real-repo governance under a generous ceiling. Pre-change this measured ~72s on macOS; the
# post-change run is ~5s. The assert is flake headroom (<30s), NOT the speed claim — the honest
# number is recorded in the step-4 commit message.
t0="$(perl -MTime::HiRes -e 'print int(Time::HiRes::time()*1000)')"
PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance > "$WORK/e2.out" 2>&1
t1="$(perl -MTime::HiRes -e 'print int(Time::HiRes::time()*1000)')"
ms=$((t1 - t0))
[ "$ms" -lt 30000 ] \
  && pass "E2: real-repo governance completed in ${ms}ms (< 30000ms ceiling; pre-change ~72000ms)" \
  || fail "E2: real-repo governance took ${ms}ms — over the 30000ms ceiling"

echo "== gh365-pdda-gov-scan: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
