#!/usr/bin/env bash
# #139 — static inventory guard: NO NEW `| grep -q` pipes under test/.
#
# The shape is nondeterministic red under `set -o pipefail`: `grep -q` exits the instant it
# matches, the producer still writing gets SIGPIPE, and the pipeline reports the producer's 141
# — a match that SUCCEEDED reads as a failure. GH-460 pinned the mechanism (and fixed its one
# production site); Wave 1 reintroduced the shape in a fresh suite with full knowledge of the
# lesson (PR #134's gh131, observed live), which is the strongest argument for a guard rather
# than vigilance. This sweep converted the convertible mass to the capture-then-match form
#   cmd | grep -q PAT ctx  ->  grep -q PAT <<<"$(cmd)" ctx
# (the command substitution completes before grep starts; a here-string is fed from a file, so
# no reader can vanish under a writer). What could not be proven safe by the mechanical pass —
# function bodies, grouped/multi-pipe conditions, quoted text that only LOOKS like the shape —
# is inventoried in test/baselines/GH-139-pipe-grep-baseline.txt and may only SHRINK.
#
# This suite fails when any file's count grows past its baseline entry or a new file carries
# the shape. Shrinking counts are reported as INFO with the invitation to regenerate the
# baseline in the same PR (the ratchet only turns one way).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
BASELINE="$ROOT/test/baselines/GH-139-pipe-grep-baseline.txt"
SELF_REL="test/gh139-pipe-grep-guard.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

[ -f "$BASELINE" ] || { echo "gh139: baseline missing: $BASELINE" >&2; exit 1; }

# Current per-file counts of the pipe-into-grep -q shape (the guard itself excluded — its own
# body contains the shape in prose/patterns). `||` is stripped first: `a || grep -q x` chains a
# grep WITHOUT a pipe and must not count (the repaired gh284/gh322 lines carry exactly that
# shape and false-positived the first gate run).
CURRENT="$(mktemp -t gh139-current.XXXXXX)"
trap '[ -n "$CURRENT" ] && rm -f "$CURRENT"' EXIT
for f in "$ROOT"/test/*.sh "$ROOT"/test/synthetic/*.sh "$ROOT"/test/fixtures/*/*.sh "$ROOT"/test/lib/*.sh; do
  [ -f "$f" ] || continue
  rel="${f#"$ROOT"/}"
  [ "$rel" = "$SELF_REL" ] && continue
  c="$(sed 's/||//g' "$f" | grep -c "| grep -q")"
  [ "$c" -gt 0 ] && printf '%s %s\n' "$c" "$rel"
done | sort -k2 >"$CURRENT"

# 1. nothing may exceed its baseline count; new files may not carry the shape at all
violations=0
while read -r count path; do
  [ -n "$count" ] && [ "$count" -gt 0 ] || continue
  base="$(awk -v p="$path" '$2 == p {print $1}' "$BASELINE")"
  base="${base:-0}"
  if [ "$count" -gt "$base" ]; then
    fail "$path grew from $base to $count pipe-into-grep -q site(s) — use capture-then-match: grep -q PAT <<<\"\$(cmd)\""
    violations=$((violations+1))
  fi
done <"$CURRENT"
[ "$violations" -eq 0 ] && pass "no file exceeded its baseline pipe-into-grep -q inventory"

# 2. shrunk counts: report and invite the ratchet forward (never a failure)
shrunk=0
while read -r base path; do
  [ -n "$base" ] && [ "$base" -gt 0 ] || continue
  cur="$(awk -v p="$path" '$2 == p {print $1}' "$CURRENT")"
  cur="${cur:-0}"
  if [ "$cur" -lt "$base" ]; then
    echo "  INFO: $path shrank $base -> $cur — regenerate the baseline in this PR (GH-139 ratchet)"
    shrunk=$((shrunk+1))
  fi
done <"$BASELINE"
[ "$shrunk" -eq 0 ] && pass "baseline is tight (no shrink owed)"

# 3. the baseline itself must not reference files that no longer exist (stale inventory)
stale=0
while read -r base path; do
  [ -f "$ROOT/$path" ] || { fail "baseline references missing file: $path"; stale=$((stale+1)); }
done <"$BASELINE"
[ "$stale" -eq 0 ] && pass "baseline has no stale entries"

echo "gh139: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
