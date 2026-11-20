# Kickstart run 1 — 2026-11-19 22:34Z → 2026-11-20 05:45Z (session a6590cb2)

Published for #1541 KS-15: the durable run record, used as the baseline for KS-18 and KS-19.

- `run-record.md`: the queue, the authority grant (and its amendments), the PARENT lines and the child's progress log, exactly as kept during the run. Home and temp paths are redacted.
- `handback.md`: the child's hand-back table.

## Outcome
- 12 PRs merged: #1525 #1501 #1526 #1529 #1507 #1460 #1531 #1534 #1495 #1496 #1533 #1532.
- #1539 (#1508) was stranded mid-landing. A merge-cleanup run was killed by the host's 10-minute tool timeout during B1; nothing was pushed. The parent settled the attempt record (`attempt_record.py finish`, outcome `aborted-tool-timeout-no-push`) and resumed the landing.
- Final QA: tier 1 plus full `./validate.sh` in a disposable clone, green on 0a87e686d and again on 04979701a, 408/408.
- Parked: item 5b (#1417 #1467 #1471 #1497, Codex sequence review FAIL), #1500 (digest migration), item 12 (7 stale batch issues), #1024 (operator). Blocked: #1480–#1483.

## Parent interventions (baseline = 7)
Definition (#1541): a parent action that changed what the child did and that the child should have done itself under its authority.

- INTERVENTION 1: the parent closed #1518 by hand; the queue builder had kept a decided issue in the decide hold (→ KS-02, #1535).
- INTERVENTION 2: the parent told the child to switch QA to agy after misreading a 3-round relay cap as Codex quota (→ KS-06).
- INTERVENTION 3: the parent withdrew intervention 2 (→ KS-06).
- INTERVENTION 4: a CodeRabbit-advisory amendment was not applied, because the child did not re-read the run record (→ KS-07).
- INTERVENTION 5: a reminder about #1532 was not applied, for the same reason (→ KS-07).
- INTERVENTION 6: the parent sent a direct steering message to deliver 4 and 5 (→ KS-07).
- INTERVENTION 7: the parent settled #1539's stale attempt and resumed its landing (→ KS-08, KS-13).

## Operator decisions (4)
#1508 design (committed file that extends the default list); #1519 accepted at the round cap; CodeRabbit made advisory with a 30-minute wait; pre-push own-diff routing approved (#1537).
