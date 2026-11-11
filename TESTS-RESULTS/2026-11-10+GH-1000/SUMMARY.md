# GH-1000 manual check: reconstruct one resumed task from committed records

Manual check for [#1000](https://github.com/HiQS-Labs/XYZ-forge/issues/1000), recorded under
AGENTS.md "No new tests" (GH-831). `walk.py.txt` is the exact command text that was run; it is a
receipt, not a tool, suite or gate, and nothing invokes it.

- **Tree:** `b71bde38e` (branch `docs/XYZ-forge-gh1000-evidence-linked-consolidation-2026-11-10`,
  base `68367d668`).
- **Commands:** `python3 TESTS-RESULTS/2026-11-10+GH-1000/walk.py.txt 1254` and the same with
  `1064`, run from the repo root. Read-only: committed files and `git log`.
- **Input:** the issue number only.

## Results

| Run | File | Verdict |
|---|---|---|
| Main path, GH-1254 | `walk-gh1254.txt` | PARTIAL: 6 attempts discovered, 0 with every cell resolved |
| Red control, GH-1064 (no execution records) | `walk-gh1064-control.txt` | UNKNOWN: zero attempts; not reported as a reconstruction |
| First run, kept as a witnessed false pass | `walk-gh1254-first-run-red.txt` | Marked the approved attempt's attestation RESOLVED because the machine-local temp path still exists on this host, and found 0 invocations because of a schema-prefix mismatch. The temp-directory prefix in that file is redacted to `<machine-local-temp>` |

## What the walk shows

- Committed `work_events` for GH-1254 carry no execution ID (0 of 10).
- Five of six attempts are discoverable only through hand-copied jog-ledger snapshots; two have
  no committed result at all.
- Transcripts join to results only through `head_sha` equalling the transcript commit; two
  transcripts join to nothing.
- The approved attempt's attestation record is outside the repo.
- One attempt's result (gate red) conflicts with a later committed receipt for the same SHA
  (exit 0).

Interpretation is in `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md`, Phase 2.
