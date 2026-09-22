#!/usr/bin/env bash
# GH-732: exercise the exact summary block without invoking a live gate or git.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/.relay-scratch"
WORK="$(mktemp -d "$ROOT/.relay-scratch/gh732-l3.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || exit 1
awk '/^# GH-732 timing summary BEGIN/{copy=1} copy{print} /^# GH-732 timing summary END/{copy=0}' \
  "$ROOT/validate.sh" > "$WORK/render.sh"
[ -s "$WORK/render.sh" ] || { echo 'FAIL: renderer extraction empty'; exit 1; }
FIXTURE="$WORK/fixture.jsonl"
: > "$FIXTURE"
for i in 4 12 1 9 2 11 3 10 5 8 6 7; do
  case $((i % 3)) in 0) lane=pool ;; 1) lane=driver-lock ;; 2) lane=sequential ;; esac
  printf '{"event":"suite","lane":"%s","name":"suite%s.sh","duration_ms":%s,"rc":%s}\n' \
    "$lane" "$i" "$((i * 1000 + 125))" "$((i % 2))" >> "$FIXTURE"
done
cat >> "$FIXTURE" <<'JSONL'
{"event":"suite","lane":"pool","name":"suite12.sh","duration_ms":999000,"rc":9}
{"event":"suite","lane":"retry","name":"suite12.sh","duration_ms":40000,"rc":0}
{"event":"retry","lane":"retry","name":"suite12.sh","duration_ms":40000,"rc":0}
{"event":"suite","lane":"retry","name":"suite9.sh","duration_ms":20500,"rc":0}
{"event":"retry","lane":"retry","name":"suite9.sh","duration_ms":20500,"rc":0}
{"event":"summary","lane":"pool","name":"summary","duration_ms":999000,"rc":0}
{"event":"suite","lane":"stage","name":"not-a-suite","duration_ms":999000,"rc":0}
JSONL
RT_FILE="$FIXTURE" bash "$WORK/render.sh" > "$WORK/rendered.txt"
{
  printf '10 slowest suites:\n  name  duration_s  rc\n'
  for i in 12 11 10 9 8 7 6 5 4 3; do
    printf '  suite%s.sh  %s.125  %s\n' "$i" "$i" "$((i % 2))"
  done
  printf 're-run ladder: 2 suite(s), 60.500s total\n'
} > "$WORK/expected.txt"
diff -u "$WORK/expected.txt" "$WORK/rendered.txt"
for missing in "$WORK/absent.jsonl" ''; do
  RT_FILE="$missing" bash "$WORK/render.sh" > "$WORK/missing.txt"
  [ ! -s "$WORK/missing.txt" ] || { echo 'FAIL: missing file rendered output'; exit 1; }
done
: > "$WORK/empty.jsonl"
RT_FILE="$WORK/empty.jsonl" bash "$WORK/render.sh" > "$WORK/empty.txt"
[ ! -s "$WORK/empty.txt" ]
bash "$ROOT/validate.sh" --help > "$WORK/help.txt" 2>&1
grep -q '2 is the default width, not a pin' "$WORK/help.txt"
grep -q 'Run one gate at a time on a host' "$WORK/help.txt"
printf 'PASS: GH-732 first-attempt top ten, retry cost, missing/empty telemetry, help (%s)\n' "$WORK"
