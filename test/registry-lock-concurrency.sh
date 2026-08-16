#!/usr/bin/env bash
set -euo pipefail
#
# registry-lock-concurrency.sh — GH-72 regression. N concurrent install.sh writers hammering ONE
# shared registry must not lose a row. Exercises the REAL locked read-modify-write in install.sh
# (advisory mkdir lock + the empty-pid-TOCTOU fix + ownership-checked release).
#
# The pre-fix lock had a TOCTOU: a loser reading $lockdir/pid before the winner wrote it judged the
# fresh lock stale and rm -rf'd it, defeating mutual exclusion -> a lost row. This test drives many
# concurrent writers (each a distinct install target -> a distinct registry row) and asserts every
# row survives. It also runs a second round to confirm the lock/ownership fix is re-entrant.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

N=16
echo "registry-lock-concurrency (GH-72): $N concurrent writers -> 1 registry"

run_round() { # <reg> — fire N concurrent install.sh, all writing the same registry
  local reg="$1" i pids=""
  for i in $(seq 1 "$N"); do
    # XYZ_LOCK_WAIT_S generous so no writer fail-opens/skips even on a loaded machine — this asserts
    # PURE mutual exclusion (every row lands via the lock). Fail-open (skip) is correct behavior but
    # would make the count non-deterministic under CPU starvation; the deadline removes that noise.
    # XYZ_GITPULSE_DIR must point at a NON-git dir to truly disable the projection follow-on — empty
    # "" means "auto-discover git-pulse" (which finds a real ~/git-pulse-sync on some hosts), NOT
    # disabled (codex review r3). This isolates the test to registry mutual exclusion.
    ( XYZ_REGISTRY="$reg" XYZ_GITPULSE_DIR="$TMP/no-git-pulse" XYZ_LOCK_WAIT_S=60 \
        "$REPO/install.sh" --repo "-" "$TMP/t$i" >/dev/null 2>&1 ) &
    pids="$pids $!"
  done
  for p in $pids; do wait "$p" 2>/dev/null || true; done
}

count_rows()    { grep -cE '^/' "$1" 2>/dev/null || printf 0; }                         # data rows start with an abs path
count_distinct(){ awk -F'\t' '/^\// {print $1}' "$1" 2>/dev/null | sort -u | wc -l | tr -d ' '; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh72.XXXXXX")"
REG="$TMP/registry.tsv"

run_round "$REG"
rows="$(count_rows "$REG")"; distinct="$(count_distinct "$REG")"
echo "  round 1: rows=$rows distinct=$distinct expected=$N"
ok "all $N concurrent rows present (no lost row / TOCTOU)" "[ '$distinct' -eq '$N' ]"
ok "no duplicate or corrupt rows"                          "[ '$rows' -eq '$N' ]"
ok "no lock dir leaked after the round"                    "[ ! -e '$TMP/registry.lock' ]"

# Round 2 (same targets, latest-wins): still exactly N rows, proves re-entrant lock + clean release.
run_round "$REG"
distinct2="$(count_distinct "$REG")"; rows2="$(count_rows "$REG")"
echo "  round 2: rows=$rows2 distinct=$distinct2 expected=$N"
ok "round 2 idempotent — still exactly $N rows"            "[ '$distinct2' -eq '$N' ] && [ '$rows2' -eq '$N' ]"

rm -rf "$TMP"
echo "  registry-lock-concurrency: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
