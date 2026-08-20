#!/usr/bin/env bash
# Close-out verification for one marathon run.
#   evidence/_env/verify-run.sh <run-number> <slug-prefix> <first-render-sha>
# e.g. evidence/_env/verify-run.sh 2 run2 9ab28b5
#
# Proves the run did what its exit code claims: gate green, every phase terminal,
# no escalations, containment held, no push, events emitted, transcripts written.
T="$HOME/marathon-target"; H="$HOME/XYZ-forge"
cd "$T" || exit 1
. "$H/evidence/_env/prelude.sh"

N="${1:?run number}"; PFX="${2:?slug prefix}"; FROM="${3:-}"
EV="$H/evidence/marathons/run-$N"

echo "=== 1. exit code + wall clock (the LOGGED one, not a notification) ==="
cat "$EV/04-wallclock.txt" 2>/dev/null
grep -hE 'MARATHON_FULLRUN_RC|^EXIT_CODE:|marathon: HALT|marathon: all|duration :' "$EV"/*.log 2>/dev/null | tail -6

echo
echo "=== 2. the gate, run independently now ==="
npm test 2>&1 | grep -E '^# (tests|pass|fail)'
echo "NPM_TEST_RC=${PIPESTATUS[0]}"

echo
echo "=== 3. every phase's terminal STATUS and round count ==="
for d in marathon-system/"$PFX"*/; do
  [ -d "$d" ] || continue
  printf '  %-42s %-20s rounds=%s\n' "$(basename "$d")" \
    "$(grep -m1 '^STATUS:' "$d/RELAY.md" 2>/dev/null || echo '<none>')" \
    "$(grep -c '^### Round' "$d/RELAY.md" 2>/dev/null)"
done

echo
echo "=== 4. escalations / interruptions ==="
find marathon-system -path "*$PFX*" \( -name 'ESCALATION.md' -o -name 'PHASE-INTERRUPTED.md' \) | sort
echo "  count: $(find marathon-system -path "*$PFX*" \( -name 'ESCALATION.md' -o -name 'PHASE-INTERRUPTED.md' \) | wc -l)"

echo
echo "=== 5. containment: any commit touching a path outside its lane? ==="
if [ -n "$FROM" ]; then
  git log --format='%H %s' "$FROM..HEAD" | while read -r sha subj; do
    case "$subj" in *"$(echo "$PFX" | tr 'a-z' 'A-Z')"*|*"$PFX"*) ;; *) continue ;; esac
    phase=$(printf '%s' "$subj" | grep -oE '[Rr][0-9]+[Pp][0-9]+' | head -1 | tr 'A-Z' 'a-z')
    [ -n "$phase" ] || continue
    for f in $(git show --name-only --format= "$sha" | grep -v '^$'); do
      case "$f" in
        *"$phase"*|relay-system/*|.tick/*) ;;
        src/*|test/*)
          # artifact writes are lane-scoped; check the file belongs to this phase
          grep -qE "artifact:.*$(basename "$f")" "PROJECT/2-WORKING/"*/MARATHON.yaml 2>/dev/null \
            || echo "  OFF-LANE? $sha ($subj) wrote $f" ;;
        *) echo "  OFF-LANE? $sha ($subj) wrote $f" ;;
      esac
    done
  done
  echo "  (no OFF-LANE? lines above = containment held)"
else
  echo "  (skipped: no from-sha given)"
fi

echo
echo "=== 6. no push; branch/HEAD ==="
echo "  target : $(git branch --show-current) @ $(git rev-parse --short HEAD)"
echo "  harness: $(git -C "$H" branch --show-current) @ $(git -C "$H" rev-parse --short HEAD)"
echo "  remotes: $(git remote -v | wc -l) configured"
git reflog --format='%gs' 2>/dev/null | grep -ci push | sed 's/^/  push entries in reflog: /'

echo
echo "=== 7. tick events for this run ==="
grep -ho '"type":"[^"]*"' .tick/events/*"$(echo "$PFX" | tr 'a-z' 'A-Z')"* 2>/dev/null | sort | uniq -c | sort -rn | head -12
echo "  exit-code-bearing events (6=containment 7=watchdog 8=parked 108=gate-killed):"
grep -hoE '"(exit_code|rc)":[0-9]+' .tick/events/*.jsonl 2>/dev/null | sort | uniq -c | head

echo
echo "=== 8. transcripts ==="
find relay-system -name "marathon-${PFX/run/r}*.md" 2>/dev/null | sort
find relay-system -name 'marathon-r*.md' -newermt '-3 hours' 2>/dev/null | sort | sed 's/^/  /'

echo
echo "=== 9. cost / token telemetry ==="
grep -hoE '"(tokens_in|tokens_out|total_tokens|cost_usd)":[0-9.]+' .tick/events/*.jsonl 2>/dev/null | sort | uniq -c | head
tail -20 "$EV"/*.log 2>/dev/null | grep -A6 'cost summary' | head -12
