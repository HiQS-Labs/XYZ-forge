#!/usr/bin/env bash
# GH-218 Phase 1: hermetic regression lock for utils/hq/marathon-live.sh.
#
# Builds fixture XYZ-registry repos, seeds each with a pre-projected .tick/STATE.md + a no-op tick
# stub, and asserts marathon-live classifies the three live states — a claim WITH a held driver lock
# (live), a claim with NO lock/no recent worktree (claimed, not driving), and nothing claimed (idle) —
# without writing inside any target repo.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
LIVE="$ROOT/utils/hq/marathon-live.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-live.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: hq-marathon-live =="
echo "  workdir: $WORK"

# A fixture repo: fake .git, a no-op tick stub (STATE.md is pre-seeded, so `tick project` need only
# succeed), and a .tick dir. Prints the repo path.
make_repo() {
  local name="$1"
  local repo="$WORK/repos/$name"
  mkdir -p "$repo/.git" "$repo/bin" "$repo/.tick"
  cat >"$repo/bin/tick" <<'EOF'
#!/usr/bin/env bash
# no-op tick stub: STATE.md is pre-seeded by the fixture; `project` just succeeds.
exit 0
EOF
  chmod +x "$repo/bin/tick"
  printf '%s' "$repo"
}

seed_state() {  # <repo> <claimed-block-body-or-empty>
  local repo="$1" claimed="$2"
  {
    printf '# Coordination State\n\n## Open\n_(none)_\n\n## Claimed\n'
    if [[ -n "$claimed" ]]; then printf '%s\n' "$claimed"; else printf '_(none)_\n'; fi
    printf '\n## Done\n_(none)_\n'
  } >"$repo/.tick/STATE.md"
}

LIVE_REPO="$(make_repo live-repo)"
STALLED_REPO="$(make_repo stalled-repo)"
IDLE_REPO="$(make_repo idle-repo)"

# live-repo: a claimed marathon task AND a held driver lock -> live
seed_state "$LIVE_REPO" '- MARATHON-GH900-JOB-LIVENESS-TURN by agy'
: >"$LIVE_REPO/.git/relay-driver.lock"
# stalled-repo: a claimed task, NO lock, no marathon worktree -> claimed, not driving
seed_state "$STALLED_REPO" '- MARATHON-GH901-HEALTH-PREDICATE-TURN by codex paths: ["src/a.js"]'
# idle-repo: nothing claimed -> idle
seed_state "$IDLE_REPO" ''

XYZ_REG="$WORK/xyz.tsv"
cat >"$XYZ_REG" <<EOF
$LIVE_REPO/.xyz	2026-07-19T00:00:00Z	0.2.0	a1	$LIVE_REPO
$STALLED_REPO/.xyz	2026-07-19T00:00:00Z	0.2.0	a1	$STALLED_REPO
$IDLE_REPO/.xyz	2026-07-19T00:00:00Z	0.2.0	a1	$IDLE_REPO
EOF

OUT="$WORK/HQ-MARATHON-LIVE-2026-07-19.md"
HQ_PDDA_REGISTRY_DIR="$WORK/empty-pdda" \
HQ_REBALANCE_DB="$WORK/nonexistent.db" \
HQ_XYZ_REGISTRY="$XYZ_REG" \
HQ_SEARCH_ROOTS="$WORK/repos" \
HQ_MARATHON_LIVE_TODAY="2026-07-19" \
HQ_MARATHON_LIVE_NOW="2026-07-19T12:00:00Z" \
HQ_MARATHON_LIVE_NOW_EPOCH="1000000000" \
bash "$LIVE" --out "$OUT" >/dev/null 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "marathon-live exits 0" || fail "marathon-live rc=$rc"
[[ -f "$OUT" ]] && pass "report written" || fail "report missing"

grep -q '| live-repo | GH900-JOB-LIVENESS | MARATHON-GH900-JOB-LIVENESS-TURN | agy | 🟢 live |' "$OUT" \
  && pass "live repo (claim + held lock) reports 🟢 live with lane parsed from task id" \
  || fail "live repo not classified live: $(grep live-repo "$OUT" || echo '(no row)')"

grep -q '| stalled-repo | GH901-HEALTH-PREDICATE | MARATHON-GH901-HEALTH-PREDICATE-TURN | codex | 🟡 claimed, not driving |' "$OUT" \
  && pass "claimed-but-no-lock repo reports 🟡 claimed, not driving (claimant parsed past paths:)" \
  || fail "stalled repo misclassified: $(grep stalled-repo "$OUT" || echo '(no row)')"

grep -q '| idle-repo | — | — | — | ⚪ idle |' "$OUT" \
  && pass "repo with nothing claimed reports ⚪ idle" \
  || fail "idle repo not classified idle: $(grep idle-repo "$OUT" || echo '(no row)')"

grep -q -- '- Live claims: 1' "$OUT" \
  && grep -q -- '- Claimed but not driving: 1' "$OUT" \
  && grep -q -- '- Idle repos: 1' "$OUT" \
  && pass "summary counts match the fixture matrix (1 live / 1 stalled / 1 idle)" \
  || fail "summary counts wrong: $(grep -E '^- (Live|Claimed|Idle)' "$OUT")"

# Read-only: marathon-live must never write into a target repo (only .tick/STATE.md regen, which the
# no-op stub leaves untouched here — assert no report/aggregate leaked into any fixture repo).
if find "$WORK/repos" -name 'HQ-MARATHON-LIVE-*' | grep -q .; then
  fail "marathon-live wrote an aggregate inside a target repo"
else
  pass "marathon-live stayed read-only over target repos"
fi

echo "== hq-marathon-live: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
