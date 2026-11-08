# Agent-assisted Batch 2 continuation

Baseline: cf5bfe6881ef3bd66bc062727e49ef99969311b3. Batch 2 remains incomplete; no #1358 rehearsal or overnight qualification performed.

## GH-1288 diagnosis and campaign disposition

Clean init succeeded both inside and outside the campaign sandbox. Inside, tick failed with its own receipt: `sandbox-exec: sandbox_apply: Operation not permitted`. Outside, tick completed. `utils/py/harness.py:_run_tool` invokes sandbox-exec for the actual tool; the nested sandbox application is the observed denied operation, not an inferred file-write denial. No sandbox rules were loosened. The archived profile was relocated to the disposable clone root with otherwise identical rules.

Stateful campaign plan: retain the exclusion of tick/state sequences under the outer GH-1280 profile. Do not remove either sandbox to make the campaign pass. Any future stateful campaign needs an independently reviewed containment design resolving nested sandbox application; this run does not qualify it. Ordinary tick outside the campaign outer sandbox still applies its own tool sandbox.

First diagnostic invocation used an invalid run-root location and was refused (results.json). Correcting the invocation to temp/factory-primitive reproduced the issue (results-correct-root.json). One setup correction; no product repair, no exhausted historical counters reset. Disposable clone retained at primary/temp/gh1356-1288-diagnosis. Python 3.13.15 with requests/yaml/pytest verified; clone hooks installed. No full gate run or production edit.

## GH-1287 independent acceptance review

Independent Codex/gpt-6-astra reviewer coverage_qa reviewed landed PR1361 head 50b60b19901254a6da50ef550ee4a6283c9d9bcf (merge 4a82bb8fe9bbc2590d1ef6e58c555bbad58bdecc). All three acceptance bullets supported: committed replay-cli.json records 10,000 events, 23 usage signatures versus 2,302 baseline, and configured 500-case streak reached at event 1,892. Production/harness code unchanged. Reviewer independently matched supervisor, contract, compressed-input and replay-output hashes against committed provenance. No fresh test execution claimed; historic receipts unchanged. Closure warranted by new acceptance review, not exact approval ancestry.

## Remaining work

GH-1296: existing PR1324 head 08ff07de0ce882136ae6d751ef42f4befa4b6b6f targets development; unresolved review findings and same-wave acceptance replay/full gate remain. Do not duplicate. GH-1344 partial delivery via PR1350, earlier attempts exhausted; no new attempt launched. GH-1254 open; not dispatched. Primary Jog also contains stale pending GH-1345; inspect completion before dispatching the queue. No merges authorized to this worker.
