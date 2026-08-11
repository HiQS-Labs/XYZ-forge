#!/bin/bash

# Check if marathon-drive is already running
if [ -d ".git/relay-driver.lock" ]; then
    echo "Driver lock is held. A previous run is still active. Skipping this cycle."
    exit 0
fi

if [ ! -s fuzz_queue.txt ]; then
    echo "Fuzz queue is empty."
    exit 0
fi

# Pop the first issue from the queue
NEXT_ISSUE=$(head -n 1 fuzz_queue.txt)
tail -n +2 fuzz_queue.txt > fuzz_queue.tmp && mv fuzz_queue.tmp fuzz_queue.txt

echo "Popped issue $NEXT_ISSUE from queue. Starting Agy fuzz run..."
./fuzz-agy-plan.sh "$NEXT_ISSUE"
