# GH-1296 preliminary independent QA

Reviewer: Codex / gpt-6-astra. Candidate: feaea399335a2a4ee36386b13e423ee3cfbe066f.

Preliminary review: **two remaining correctness gaps; no final-readiness approval.** Confirmed local HEAD and read the live [issue #1296](https://github.com/HiQS-Labs/XYZ-forge/issues/1296) and [PR review comments](https://github.com/HiQS-Labs/XYZ-forge/pull/1324#discussion_r4456420042). No files changed or tests run.

1. **P2 — Normalization can falsely clear missing artifacts.** At [harness.py:1317](/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1296-packet-2026-11-07/utils/py/harness.py:1317), `normpath` collapses `missing/../existing.py` to `existing.py`. Preflight uses filesystem existence at [swarm_preflight.py:1371](/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1296-packet-2026-11-07/utils/py/swarm_preflight.py:1371), which fails when the intermediate directory is absent. Also, trimming `artifacts_new` grants exemptions that preflight’s untrimmed membership comparison does not grant. **Cheapest sound fix:** normalize harmless `./` spellings, preserve preflight’s exemption comparison, and conservatively flag parent-traversal paths unless their traversal can be established from frozen inputs.

2. **P2 — Stale-capture rejection checks the old pointer, not necessarily the capture consumed.** [harness.py:1355](/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1296-packet-2026-11-07/utils/py/harness.py:1355) hashes manifest paths, then independently reruns planner discovery. [The planner](/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1296-packet-2026-11-07/utils/py/_marathon_plan.py:998) discovers current capture filenames. For an unregistered issue, adding a different, earlier-sorting capture can change the selected contract while the original manifest document remains unchanged. **Cheapest sound fix:** compare each emitted record’s selected `docRel` and content hash with its frozen request before using its contract; reject any mismatch.

The malformed `artifacts_new` repair is sound by inspection: scalar values and non-string members become lane blockers before set construction; raw subset validation matches preflight. Ordinary edits/deletions of the original capture are now rejected before packet staging.

Scope is otherwise small and appropriate: one helper plus packet annotation and freshness checking. Checking every manifest request is conservative and can reject a packet because an unrelated capture changed; that is an availability tradeoff, not evidence of stale output being accepted.

Final acceptance replay, a freshly generated README receipt, and the full gate remain explicitly owed.

PR https://github.com/HiQS-Labs/XYZ-forge/pull/1324, head feaea399335a2a4ee36386b13e423ee3cfbe066f, checks and reviews pending.


## Publisher source-link addendum

Historical reviewer text above is preserved. Accessible sources at its exact candidate: [harness.py:1317](https://github.com/HiQS-Labs/XYZ-forge/blob/feaea399335a2a4ee36386b13e423ee3cfbe066f/utils/py/harness.py#L1317), [harness.py:1355](https://github.com/HiQS-Labs/XYZ-forge/blob/feaea399335a2a4ee36386b13e423ee3cfbe066f/utils/py/harness.py#L1355), [preflight:1371](https://github.com/HiQS-Labs/XYZ-forge/blob/feaea399335a2a4ee36386b13e423ee3cfbe066f/utils/py/swarm_preflight.py#L1371), [planner:998](https://github.com/HiQS-Labs/XYZ-forge/blob/feaea399335a2a4ee36386b13e423ee3cfbe066f/utils/py/_marathon_plan.py#L998).
