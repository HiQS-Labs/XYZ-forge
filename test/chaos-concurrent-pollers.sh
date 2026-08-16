#!/usr/bin/env bash
# Concurrent-poller safety: two pollers race to claim the same available turn
# token. The O_EXCL claim lock serialises them — exactly one wins, the other
# stands down — across N=20 independent trials.
source "$(dirname "$0")/_setup.sh" chaos-concurrent-pollers

N=20

tick_a init >/dev/null

for i in $(seq 1 $N); do
  TASK="CHAOS-$(printf '%03d' "$i")"

  # Seed exactly one claimable task for this trial.
  tick_a log task.created "$TASK" --agent dispatcher --priority 10 \
    --paths "src/chaos/**" >/dev/null

  OUT_A="$WORK/trial-${i}-a.out"
  OUT_B="$WORK/trial-${i}-b.out"

  # Launch two concurrent claimers as background subshells — a genuine race.
  # Back-to-back & launches minimise the gap to stress the O_EXCL lock.
  tick_a claim "$TASK" --agent poller-a --paths "src/chaos/**" >"$OUT_A" 2>&1 &
  tick_a claim "$TASK" --agent poller-b --paths "src/chaos/**" >"$OUT_B" 2>&1 &
  wait

  WINS_A=0; WINS_B=0
  grep -q "^won:" "$OUT_A" && WINS_A=1
  grep -q "^won:" "$OUT_B" && WINS_B=1
  TOTAL_WINS=$(( WINS_A + WINS_B ))

  if [[ "$TOTAL_WINS" -ne 1 ]]; then
    fail "trial $i: expected exactly 1 winner, got $TOTAL_WINS (poller-a: $(cat "$OUT_A") | poller-b: $(cat "$OUT_B"))"
  fi

  if [[ "$WINS_A" -eq 1 ]]; then WINNER="poller-a"; else WINNER="poller-b"; fi
  pass "trial $i: exactly one winner ($WINNER)"

  # Release the winning claim so the next trial starts with a clean cap.
  tick_a done "$TASK" --agent "$WINNER" >/dev/null 2>&1
done

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
