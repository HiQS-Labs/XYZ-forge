# Kickstart run 1 — 2026-11-19 22:34Z → 2026-11-20 05:45Z (session a6590cb2)

Published for #1541 KS-15: the durable run record, used as the baseline for KS-18 and KS-19.

- `run-record.md`: the queue, the authority grant (and its amendments), the PARENT lines and the child's progress log, exactly as kept during the run. Home and temp paths are redacted.
- `handback.md`: the child's hand-back table.

## Outcome
- 12 PRs merged: #1525 #1501 #1526 #1529 #1507 #1460 #1531 #1534 #1495 #1496 #1533 #1532.
- #1539 (#1508) was stranded mid-landing. A merge-cleanup run was killed by the host's 10-minute tool timeout during B1; nothing was pushed. The child's record ends with the item parked and the attempt `in_progress` (run-record.md, item 11). After handback, the parent settled the attempt record (`attempt_record.py finish`, outcome `aborted-tool-timeout-no-push`) and resumed the landing.
- Final QA: tier 1 plus full `./validate.sh` in a disposable clone: green on 0a87e686d (rc=0, 0 failing) and again on 04979701a (408/408).
- Parked: item 5b (#1417 #1467 #1471 #1497, Codex sequence review FAIL), #1500 (digest migration), item 12 (7 stale batch issues), #1024 (operator). Blocked: #1480–#1483.

## Parent interventions (baseline: 3 interventions + 4 no-effect supervision actions)
Definition (#1541): an **intervention** is a parent action that changed what the child did and that the child should have done itself under its authority. A **supervision action** is a parent note or amendment that did not change the child's behaviour (wrong, withdrawn or unapplied). KS-18 counts both; the run-2 target is zero of each in run 1's classes. Relaying a genuine operator decision counts as neither.

- INTERVENTION I-1: the parent closed #1518 by hand; the queue builder had kept a decided issue in the decide hold (→ KS-02, #1535).
- INTERVENTION I-6: a direct steering message to the child; only then did it apply the CodeRabbit-advisory amendment and the #1532 reminder (→ KS-03, KS-06).
- INTERVENTION I-7: after handback, the parent settled #1539's stale attempt and resumed its landing, which landed as 70480a188 (→ KS-07, KS-08).
- SUPERVISION S-2: the parent told the child to switch QA to agy, after misreading a 3-round relay cap as Codex quota; the child did not act on it (→ KS-05).
- SUPERVISION S-3: the parent withdrew S-2 (→ KS-05).
- SUPERVISION S-4: the operator's CodeRabbit-advisory amendment was written to the run record but not applied until I-6 (→ KS-03, KS-06).
- SUPERVISION S-5: the parent's #1532 reminder was written but not applied until I-6 (→ KS-06).

## Operator decisions (4)
#1508 design (committed file that extends the default list); #1519 accepted at the round cap; CodeRabbit made advisory with a 30-minute wait; pre-push own-diff routing approved (#1537).
