# GH-1111 — CI audit overhead experiment

Author: Codex / GPT-6 family / exact model and effort unavailable.

## Scope and frozen revisions

Base: `c9ecd0bf4c08e77765968a7bf797849658386a6e`.
Candidate: `c2d875fab7dd1bc3fb3648a2f7b94d60ed8fceb4`.
Upstream starting point: `2454a781a7bfa08ad87ccd7037b237e3d4914f3a`.
The code commit changes only `test/gh365-tier-fail-closed.sh` (16 insertions, 7 deletions). The frozen base/candidate tracked-file inventories match exactly: 7,412 paths each. No suite, assertion, path classification, runtime setting, production selector or qualification contract was removed or changed. Registry extraction now refuses a failed or empty read rather than trusting an empty cache.

Three micro-optimizations: Bash builtin output-field parsing instead of nine external text commands per path; one subsystem listing per audit invocation; builtin basename expansion in the two file loops.

## Predeclared method and observed results

Serial A/B/B/A, two independent disposable full clones, no overlapping experiment workloads. macOS arm64, ten cores, 64 GiB RAM; `/bin/bash` 3.2.57. Monotonic elapsed time includes normal fixture setup. The host is shared and heavily loaded; we did not control other sessions or cold/warm caches. Raw timestamps, load averages, command, return code, source SHA, local Git config/status/origin/worktree brackets and stdout are in `measurements.jsonl`. Only the emitted random workdir line is normalized for equality; raw hashes and text remain available. See `normalization-policy.txt` and executable method source `measure.py` (manual evidence collector, not registered gate machinery).

| Run order | Revision | Seconds | Exit | Identity intact |
|---|---|---:|---:|---|
| A1 | base | 188.768 | 0 | yes |
| B1 | candidate | 81.145 | 0 | yes |
| B2 | candidate | 77.058 | 0 | yes |
| A2 | base | 135.504 | 0 | yes |

Observed means: **162.136 s → 79.101 s**, **83.034 s / 51.213% lower**. Both candidate observations are below both base observations, but N=2 per revision and substantial base variability prevent a precise population estimate. This is an exploratory local result, not a hosted benchmark or a statistically established speedup. It does not estimate parallel critical-path savings or the whole-suite average. The three optimizations are measured as a bundle; no attribution to an individual edit is claimed.

All four normalized stdout records match byte-for-byte: **5 passed, 0 failed**; T1 totals **5,740 tier1 / 356 tier2 / 1,316 tier3** sum to the full 7,412-file inventory. Both existing T3 planted controls fire in every run.

## Regression and sensitivity controls

`controls.py` is a manual evidence recipe, never a suite or CI entry point. `controls.json` retains 22 records:

- Old/new `classify()` results match on 16 real router inputs, including empty input, unknown/deleted paths, kernel/workflow/test paths, spaces and equals signs. This is sampled field-equivalence evidence; it is not a universal arbitrary-output parser proof.
- Old/new membership functions agree on every one of the 411 `test/*.sh` files present in the frozen tree. Output hashes match and the extraction is nonempty.
- Failed and empty registry extraction both exit 1; a valid listing exits 0, using the exact candidate extraction block.
- Deliberately replace the candidate parser's tier assignment with `BROKEN`: the existing full audit exits **1**, names invalid tiers, and takes **127.798 s**. This expected red is retained separately from passing timing runs; it is not counted as a regression or speed sample. Both original and mutant blob hashes and decisive output are recorded.
- Restore saved file bytes in `finally`; the original blob hash and complete pre-mutation Git identity match afterward. The red-run identity brackets intentionally include its modified test file; they assert no additional drift, not a clean candidate checkout during the mutation.

Existing focused suites: `ci-route.sh` **4.584 s**, `gh35-test-tiers.sh` **17.717 s**, `gh306-registry-bidirectional.sh` **2.629 s**. Each exits 0 with unchanged identity. These timings are validation observations, not A/B comparisons.

## Full gate and publication

**RED: 408 passed / 1 failed / 409 total**, 406 registered shell suites, width 4. Validator start-to-summary: **1,018.258 s**; hook reported **1,019 s**; complete attempted push: **1,020.369 s**. The normal hook refused publication; no bypass was used. Identity remained unchanged, envelope rc=0/no drift, run-set=406 and suite-event consistency=yes. `full-validation.jsonl` is the complete exact-candidate parallel receipt; incomplete nested probe telemetry was excluded.

`gh648-l4-285-revalidate.sh` failed pooled and on the runner's isolated retry with `PermissionError: [Errno 1] Operation not permitted` at its process-group observation/cleanup calls. All other shell suites, Python layer and final identity/poison checks passed. The optimized audit passed in the pool. This is **not a clean full gate or merge readiness**.

Subsequent isolated comparisons both passed: base **11.244 s**, candidate **11.225 s**, with identities intact. Those observations do not establish the cause of the earlier failure. GH-1063 records the same suite/error before this spike; this is relevant antecedent evidence, not proof that this instance is harmless or unrelated. No full base run was performed, and causal attribution remains unresolved. Do not count the later isolated successes as erasing the pooled or retry failures.

Standard hook live-agent self-sufficiency opt-out (`RELAY_SELF_SUFFICIENCY_SKIP=1`) is explicit; it is not a blanket push bypass. Parallel full results are regression evidence, not sequential promotion qualification. No hosted or whole-suite speedup is claimed.

**Publication disposition:** preserve candidate `c2d875fa` and its patch, then restore the original test bytes at the report branch tip. Publish only documentation, ledger and experiment receipts through their normal classified documentation gate. This does not publish the optimization as the branch-tip implementation, waive the red runtime gate, or claim production adoption. The frozen candidate remains reachable in branch history for independent review.

## Independent QA

Pending: Agy via relay-xyz, after findings are posted to GH-1111. Reviewer will receive this report, raw structured results, exact issue report and source diff. Textual verification of retained evidence must not be described as independently rerunning the suite.

## Disposition and limits

The bounded optimization has a useful local signal without dropping coverage; production adoption is held after a red full gate. The report branch tip restores the baseline test; `candidate.patch` and the immutable candidate commit preserve the experiment. It cannot turn the measured ~64-minute hosted suite into single-digit CI. Larger selective routing or parallel qualification changes remain outside this quick-win spike. Evidence collectors are manual analysis under TESTS-RESULTS, not new gate suites, registry entries, runners or telemetry stages.

## Incomplete publication attempt

An additional documentation publication attempt unexpectedly selected full validation in the task clone. It was terminated after detection; no terminal summary exists, so it is excluded from completed gate counts and timing comparisons. `aborted-publication-validation.jsonl` and `aborted-publication-context.json` retain this event. Task HEAD/origin/configuration and tracked state remained intact. The cached integration tip was behind the advertised tip when checked; the routing cause is not independently attributed. Further publication/gate work moved to the disposable clone with a refreshed integration ref, where normal documentation routing was observed. No push bypass or runtime approval is inferred.
