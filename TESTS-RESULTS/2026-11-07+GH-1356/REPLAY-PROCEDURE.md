# Reproduce the retained-stream CLI replay

Run from repository root at the candidate SHA in provenance.jsonl:

```sh
python3 TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py --contract TESTS-RESULTS/2026-10-30+GH-1280/contracts/contract-long.json --replay-telemetry TESTS-RESULTS/2026-10-30+GH-1280/runs/long/telemetry.jsonl.gz
```

This replay launches no campaign or canary commands. It reads the committed compressed stream and contract, records the first hypothetical stop, and continues through all 10,000 events for reporting. Expected: 23 usage signatures, first stop 500, streak threshold 1,892. Full stdout: replay-cli.json. SHA-256 hashes of script, contract, compressed input and output are in the appended provenance record. The prior baseline Tracker red control remains recorded separately; the baseline CLI has different replay/reporting behavior. This supplements, not replaces, that control.
