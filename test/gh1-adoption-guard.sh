#!/usr/bin/env bash
set -uo pipefail
#
# gh1-adoption-guard.sh — GH-10: every fixture-creating suite carries require_fixture adoption.
#
# The derivation is COMPUTED FROM SOURCE on every run (the DRIVER_LOCK_LANE approach): any
# test/*.sh that creates mktemp fixtures AND drives git through them must either
#   (a) source test/lib/fixture-guard.sh itself,
#   (b) source test/_setup.sh — which performs the adoption centrally for its sourcers, or
#   (c) carry an explicit, reason-bearing exemption marker line:
#         # gh1-adoption-guard: exempt — <reason>
# Anything else is an unaudited suite with the GH-564 failure mode still live in it, and this
# suite fails naming it. The ledger (test/baselines/GH-1-adoption-ledger.md) is the human record;
# THIS is the enforcement. A hand-maintained exception list that never shrinks is the exact
# failure shape of the 2026-08-17 marathon attempt — enforcement without adoption — so the list
# here is derived, and exemptions must live in the exempt file where a reviewer trips over them.
#
# WHY _setup.sh SOURCING COUNTS: _setup.sh creates the shared $WORK sandbox and performs
# fixture_guard_init at source time, so every suite sourcing it runs with the guard armed and
# its shared fixtures ($A/$B/$REMOTE) guarded. Suites with their OWN mktemp sites still carry
# per-site require_fixture calls — which is what the adoption pass added.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi }

echo "== test: gh1-adoption-guard =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh1-adoption.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

EXEMPT_MARKER='gh1-adoption-guard: exempt'

# Derive the offenders live. The pattern is the issue's step 1: mktemp AND (git -C | cd), minus
# adopted, minus declared exemptions. Read-only against the repo's own tree.
setup_adopts() {  # <setup-path> — central adoption is REAL: a source statement plus an init call
  grep -qE '^\s*(\.|source)\s.*fixture-guard\.sh' "$1" 2>/dev/null \
    && grep -q 'fixture_guard_init' "$1" 2>/dev/null
}

derive_offenders() {  # <test-dir> -> prints offending suite basenames
  local d="$1" f central=0
  # PR #89 review, finding 2: the _setup.sh indirection is TRUSTED ONLY AFTER verifying
  # _setup.sh itself, live, on every run — stripping the two central lines must re-flag
  # every consumer, not silently classify them as adopted.
  [ -f "$d/_setup.sh" ] && setup_adopts "$d/_setup.sh" && central=1
  for f in "$d"/*.sh; do
    [ -f "$f" ] || continue
    grep -q "mktemp" "$f" || continue
    grep -qE 'git -C| cd ' "$f" || continue
    # (a) direct adoption: a REAL source statement plus an init call — a comment that
    #     merely mentions the lib's name satisfies neither (review finding 2).
    if grep -qE '^\s*(\.|source)\s.*fixture-guard\.sh' "$f" && grep -q 'fixture_guard_init' "$f"; then
      continue
    fi
    # (b) central adoption via _setup.sh, honored only while (b) is verified above.
    if [ "$central" -eq 1 ] && grep -qE '^\s*(\.|source)\s.*_setup\.sh' "$f"; then
      continue
    fi
    grep -q "$EXEMPT_MARKER" "$f" && continue
    printf '%s\n' "$(basename "$f")"
  done
}

offenders="$(derive_offenders "$HERE")"
if [ -z "$offenders" ]; then
  pass_count=$((pass + 1))
  echo "  PASS: zero unaudited fixture-creating suites (every match adopted or declared-exempt)"
else
  fail=$((fail + 1))
  echo "  FAIL: unaudited suites with the GH-564 failure mode still live:"
  printf '%s\n' "$offenders" | sed 's/^/    /'
fi

ok "the adoption ledger exists and records ZERO unaudited suites" \
   "grep -q 'Unaudited suites: 0' '$REPO/test/baselines/GH-1-adoption-ledger.md'"

ok "the ledger names every declared exemption with a reason (currently: the static audit)" \
   "grep -q 'mktemp-trap-guard.sh' '$REPO/test/baselines/GH-1-adoption-ledger.md'"
EXEMPT_COUNT="$(grep -c "$EXEMPT_MARKER" "$HERE/mktemp-trap-guard.sh" || true)"
ok "mktemp-trap-guard.sh carries the in-file exemption marker the derivation honors" \
   "[ \"$EXEMPT_COUNT\" -ge 1 ]"

# ── negative controls: the guard must FIRE, not merely pass on a compliant tree ───────────────────
# A guard that never triggers passes a naive test (the lesson pinned all over this repo). Both
# controls run the SAME derivation against a fixture copy of test/ where exactly one sin is
# introduced; each must be named.
CTRL_DIR="$WORK/ctrl-test"
mkdir -p "$CTRL_DIR"

# Control A — a NEW suite with mktemp fixtures and git usage, unguarded: must be detected.
cat > "$CTRL_DIR/ctrl-unguarded.sh" <<'EOF'
#!/usr/bin/env bash
W="$(mktemp -d "${TMPDIR:-/tmp}/ctrl.XXXXXX")"
git -C "$W" init -q
EOF
ctrl_a="$(derive_offenders "$CTRL_DIR")"
ok "CONTROL A: an unguarded new suite is DETECTED (not waved through)" \
   "printf '%s' \"\$ctrl_a\" | grep -q 'ctrl-unguarded.sh'"

# Control B — an adopted suite whose guard lines are STRIPPED: must be detected. Uses a real
# adopted suite so the control proves the derivation reads what it claims to read.
cp "$HERE/hq-park.sh" "$CTRL_DIR/hq-park.sh"
sed '/fixture-guard.sh/d; /fixture_guard_init/d; /require_fixture/d' "$CTRL_DIR/hq-park.sh" > "$CTRL_DIR/hq-park.stripped" && mv "$CTRL_DIR/hq-park.stripped" "$CTRL_DIR/hq-park.sh"
ctrl_b="$(derive_offenders "$CTRL_DIR")"
ok "CONTROL B: an adopted suite with its guard stripped is DETECTED" \
   "printf '%s' \"\$ctrl_b\" | grep -q 'hq-park.sh'"
ok "  and Control A's file is still named alongside it (both sins in one pass)" \
   "printf '%s' \"\$ctrl_b\" | grep -q 'ctrl-unguarded.sh'"

# Control D (review finding 2) — the _setup.sh indirection is VERIFIED, not trusted: with an
# intact _setup.sh a consumer is adopted; strip the two central lines from the _setup COPY and
# the consumer must reappear on the offenders list. Uses take.sh, a real _setup sourcer.
mkdir -p "$CTRL_DIR/setupd"
cp "$HERE/_setup.sh" "$CTRL_DIR/setupd/_setup.sh"
cp "$HERE/gh331-cost-summary.sh" "$CTRL_DIR/setupd/gh331-cost-summary.sh"
ctrl_d_intact="$(derive_offenders "$CTRL_DIR/setupd" | grep -c 'gh331-cost-summary.sh' || true)"
ok "CONTROL D: an _setup consumer is adopted while central adoption is INTACT" \
   "[ \"\$ctrl_d_intact\" -eq 0 ]"
sed '/fixture-guard\.sh/d; /fixture_guard_init/d' "$CTRL_DIR/setupd/_setup.sh" > "$CTRL_DIR/setupd/_setup.stripped" \
  && mv "$CTRL_DIR/setupd/_setup.stripped" "$CTRL_DIR/setupd/_setup.sh"
ctrl_d_stripped="$(derive_offenders "$CTRL_DIR/setupd" | grep -c 'gh331-cost-summary.sh' || true)"
ok "  and stripping _setup.sh's central adoption RE-FLAGS the consumer" \
   "[ \"\$ctrl_d_stripped\" -ge 1 ]"

# Control E — a comment mentioning the lib is NOT adoption: a file whose only "adoption" is
# a comment must stay on the offenders list (the pre-fix derivation let it through).
cat > "$CTRL_DIR/ctrl-comment-only.sh" <<'EOF'
#!/usr/bin/env bash
# we totally source test/lib/fixture-guard.sh somewhere else, honest
W="$(mktemp -d "${TMPDIR:-/tmp}/ctrl2.XXXXXX")"
git -C "$W" init -q
EOF
ctrl_e="$(derive_offenders "$CTRL_DIR" | grep -c 'ctrl-comment-only.sh' || true)"
ok "CONTROL E: a comment naming the lib does NOT count as adoption" "[ \"\$ctrl_e\" -ge 1 ]"

# Control C — the exemption marker is honored ONLY with the marker present; removing it from an
# otherwise-exempt file must put the file back on the offenders list.
cat > "$CTRL_DIR/ctrl-exempt.sh" <<EOF
#!/usr/bin/env bash
# $EXEMPT_MARKER — control: static audit shape, no fixtures created
W="pattern mentions mktemp and git -C but creates nothing"
EOF
ctrl_c_with="$(derive_offenders "$CTRL_DIR" | grep -c 'ctrl-exempt.sh' || true)"
ok "CONTROL C: a declared exemption is honored (file NOT flagged)" "[ \"$ctrl_c_with\" -eq 0 ]"
sed "s/$EXEMPT_MARKER/exempt-marker-removed/" "$CTRL_DIR/ctrl-exempt.sh" > "$CTRL_DIR/ctrl-exempt.sh.new" && mv "$CTRL_DIR/ctrl-exempt.sh.new" "$CTRL_DIR/ctrl-exempt.sh"
ctrl_c_without="$(derive_offenders "$CTRL_DIR" | grep -c 'ctrl-exempt.sh' || true)"
ok "  and removing the marker puts it BACK on the offenders list" "[ \"$ctrl_c_without\" -ge 1 ]"

echo "  gh1-adoption-guard: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
