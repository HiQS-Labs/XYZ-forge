## Answer

One finding blocks landing GH-1315. Pinned HEAD `7f61d64d` would add 72 files in two nested copies of the evidence directory. The two fresh receipts are already committed in the top-level provenance file.

## Findings

1. **[Blocker] The duplicate evidence tree is real, and it grew after review.** I set `d=TESTS-RESULTS/2026-11-25+GH-1315` and `n="$d/2026-11-25+GH-1315"`. `git ls-tree -r --name-only HEAD -- "$n" | wc -l` returned `72`. The same command at reviewer commit `e6d89792c` returned `36`. `git diff --name-status a54cfabe4 HEAD -- "$n"` reported 72 additions. At HEAD, the first nested copy has 13 receipts and uses `catalog`. The deepest copy has 11 receipts and uses Git plus `intake.py --apply add` (`readiness_probe.py:107–111` in that copy). Landing both would leave readers with three versions of the same evidence. Every nested file has a top-level counterpart, and both nested provenance files are exact prefixes of the top-level file. **Smallest repair:** remove the tracked subtree at `$n`, then verify the same `ls-tree` command returns zero. `marathon-system/gh-1315-legacy-preview-parity/RELAY.md:160–167`.

2. **[Pass] The missing-receipts finding was accurate at review time and is resolved at pinned HEAD.** `git show <rev>:"$d/provenance.jsonl" | wc -l` returned `13` at reviewer commit `e6d89792c`, `15` at escalation commit `40d32085e`, and `15` at HEAD. Parsing the last two HEAD rows returned `2026-11-26T17:45:28Z relay-cli-red-control 1 562b4111` and `2026-11-26T17:45:28Z relay-cli-candidate 0 68955508`. Both timestamps follow packet generation at `17:43:29Z`. I verified the full source hashes against the base and HEAD `sync.py` blobs, and both rows carry the pinned probe’s SHA-256. **Smallest repair:** close the finding with the commit and row references. The committed receipts already support the builder’s claim. `marathon-system/gh-1315-legacy-preview-parity/RELAY.md:11`, `:135`, `:169–172`; `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl:14–15`.

## Recommendation

Remove the nested subtree, close the receipt finding with the committed evidence, and submit the four-line guard for final review and the pending harness gate. I verified the Git objects and hashes for this consult. The harness gate was not run (`marathon-system/gh-1315-legacy-preview-parity/ESCALATION.md:7`).

CONSULT: FINDINGS-REAL-REPAIR-NEEDED

The pinned diff adds 72 nested files that would leave conflicting copies of the test evidence. The canonical provenance already contains both fresh hash-bound receipts, so the repair is limited to removing the nested subtree.