# Consult (tie-break): are the open reviewer findings on the GH-1315 lane real and blocking?

Repository: this clone, branch `marathon/gh-1315-legacy-preview-parity-2026-11-26`, pinned HEAD `7f61d64d45c39a097492442a2eab2bf7de4dbd94`, base `a54cfabe4a4edab4dfe8d933ee0db89a22be7874` (`git diff a54cfabe4 HEAD` is the pinned diff). Advisory only: do not modify anything outside your scratch; answer from the files and from commands you run here.

Task under test (issue #1315): `--migrate-legacy` preview passed but apply refused "Invalid retirement" for an unadopted skill. The fix is the 4-line guard in `skills/3-weekly/skills-army-hq/scripts/sync.py` (reconcile) so preview refuses with the same reason and names the adoption remedy; evidence lives under `TESTS-RESULTS/2026-11-25+GH-1315/`. The lane stopped because the relay round cap (2 TURNS = one build + one review) was reached after one reviewer turn, TWICE (two attempts), so the builder never answered the reviewer. The builder's only block (Round 1, `marathon-system/gh-1315-legacy-preview-parity/RELAY.md` lines 132-143) is its rebuttal/position: it kept the existing verified guard, says the retained readiness probe already uses `intake.py --apply catalog`, and claims it appended two fresh hash-bound results to `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl`.

Open reviewer findings (agy, `RELAY.md` lines 145-176, verbatim summary):
1. [Blocker] A recursive duplicate nested directory `TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/` (36 stale files incl. a conflicting 11-row `provenance.jsonl` and a `git`-based `readiness_probe.py`) is committed in the artifact tree and would land if approved.
2. [Blocker] The builder's Round 1 says two fresh receipts were appended to `provenance.jsonl`, but only 13 rows exist, the last two stamped 2026-11-26T17:20:36Z, which is 23 minutes before the packet was generated (17:43:29Z); the claim and the disk disagree.
The reviewer found NO defect in `sync.py` itself and reproduced preview/apply parity.

Questions. For EACH finding answer, with a command you ran and its output as evidence:
(a) Is the finding factually correct at the pinned HEAD? (b) Is it blocking for a PR that delivers the #1315 fix (would landing it do harm or mislead)? (c) What is the smallest repair, if any?
Then give one overall verdict line, exactly one of: `CONSULT: FINDINGS-WRONG-OR-NONBLOCKING`, `CONSULT: FINDINGS-REAL-REPAIR-NEEDED`, or `CONSULT: SAFETY-OR-AUTHORITY-ISSUE` (the last only for a safety/authority problem, e.g. a destructive or out-of-scope change), with a two-sentence basis.
