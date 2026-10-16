# GH1076 — bounded historical selection study

**Finding: this sample does not establish readiness to reduce hosted Medium qualification.** It validates the known payload-consumer example, distinguishes publication/discovery failures from qualification failures, and identifies two mixed catch-up bridge failures whose root cause remains unknown. It supplies zero newly validated mapped-Medium regression/change pairs. This is an evidence limit, not a claim that reduced Medium can never be safe.

Selection comparison source: `f974fcee15647aae6551fcc81b129f5a6127120b`. During research the implementation owner advanced the shared clone to `3a129202589e0a82830fac44097f837446fe9cf4`; no implementation files were read for this follow-up or modified by this lane. Historical git diffs are queried from immutable commits. JSON includes exact paths, original log line numbers and SHA256 hashes, job URLs and all20run metadata.

## Method and limits

Read the20most recent naturally failed `wave-reconcile.yml` runs returned by GitHub at collection time, spanning September21–October14,2026UTC. Read all20job metadata records and six bounded original failed-job logs (approximately7.9MB total). Purposefully selected newest publisher failure, known payload failure, two prequalification discovery failures, and two older actual qualification failures. No workflow triggered/rerun; no suites executed, cases added, source changes, installs or implementation-owner edits. Fourteen logs were intentionally not fetched within the cost budget and remain unclassified. Twenty failed runs are **not** an eligible Medium denominator or a random sample; passing runs were not surveyed. No recall, catch-rate, or savings percentage is inferred.

Nested suite fixtures print synthetic `wave-reconcile` successes/errors and fake commit SHAs. The dataset uses the **first outer qualification invocation** plus the real suite's bounded log section; synthetic error messages are not scored as workflow failures. Event head SHA is kept distinct from actual integrated tested SHA.

## Original-job findings

| Run | Actual tested SHA / trigger | Observed failure | Selection consequence |
| --- | --- | --- | --- |
| [38611374289](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38611374289) | `aec75f1d62179b5b6a5da1dcc283dd97ab473835`,PR1056,one pending landing,tier3 | Full qualification **passed**. Publish raced development; receipt-first recovery retained receipts, then GraphQL issue960 timed out during recompute; reporting also timed out. | Publication/external API failure, no failed suite. PR1056changes relay-xyz/SKILL.md, an explicit full surface. Smaller suites do not repair publication. |
| [37723297290](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37723297290) | `e0c0bc9172d56efe54fd62f1afb44d90a18b4b8c`,PR992,one pending landing,tier3 | `gh620-skills-army-mini-sync.sh`:26pass,2fail; unexpected BOT-DAILY-HEALTH-CHECK.md and nine-payload manifest expectation. | **Known issue995**, not a newly counted Medium regression. Trigger changes merge-cleanup/SKILL.md and unmapped workhorse stop-hook: retain full. A proposed known publication-consumer edge selects gh620 for earlier GH988/GH989payload changes; trigger-only area selection cannot safely attribute inherited failures. |
| [37009287827](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37009287827) | Schedule; no qualification invocation or tested SHA | GraphQL could not resolve issue506; refused before qualification. | No suite selected/executed. Incorrect issue identity vs access remains unknown. Unknown pending scope retains full. |
| [36978963707](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36978963707) | PR900trigger; no qualification invocation or tested SHA | Same issue506 discovery error before qualification. | Not a suite miss; exact PR900scope not fetched. Unknown retains full. |
| [36087662555](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36087662555) | `0ae3452a5774c6e72b633dd61648137e80516e6b`,PR794trigger,**four** pending landings | `agent-chorus-bridge.sh`:38pass,10fail; turn2and subsequent discussion-state outputs missing. | Root cause unknown. PR794has unclaimed test edits plus merge-cleanup implementation; conservative full. Bridge is agent-chorus area, absent Small, but trigger diff alone does not recover four-member union. |
| [35552996436](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35552996436) | `5e60cb01541a4c32f59cba899aa6d77d33d29277`,PR719trigger,**twenty** pending landings | `agent-chorus-bridge.sh`:34pass,10fail; same missing turn2/subsequent state pattern. | Root cause unknown. PR719has src/flightdeck/* and unclaimed tests, requiring full. Twenty-member union not recovered; cannot call it a clean single-area miss. |

For the two bridge failures, later git commits `bfb1c84e` (ready poll instead of sleep) and `83483a54` (diagnostics and GET / poll) provide historical context. They do not prove that these exact run failures were environmental or fixed by that change. Keep attribution unknown until original diagnostics/correction evidence establishes causality.

Current baseline focused-map comparison (`utils/ci-route.sh:24-50`): gh620 belongs to skills-army-hq; bridge belongs to agent-chorus; neither is in Small. Kernel/gate/unknown/test surfaces preserve full. `:63-68` and `:380-413` cause package Markdown to contribute no area, so the known GH988/GH989 example still demonstrates a missing consumer dependency at this baseline. Adding Small to emitted areas alone cannot repair that dependency.

## Fourteen metadata-only records

The JSON lists event SHA, URL, job and failing step for each. These records remain **unknown**, not inferred product, fixture or network failures:

`36979067253`, `36970981161`, `36062581982`, `36044868273`, `36042902034`, `36041060266`, `36035559968`, `36033702443`, `36033552439`, `36025506150`, `35957506810`, `35767844928`, `35671086913`, `35623940059`.

One metadata-only run failed its publish step; metadata alone does not establish why. The rest predominantly failed reconciliation steps. They cannot contribute a failed-suite or coverage verdict without original logs.

## Concrete readiness requirements

1. Obtain naturally occurring **eligible mapped-Medium** changed ranges paired with original full-run failed suites and defensible product/payload/fixture/environment attribution. This bounded dataset contains none newly validated; the known995counterexample remains useful but must not be inflated into a new Medium case.
2. Compare candidate selections against the exact tested tree and complete pending landing union, rather than workflow event head or triggering PR alone. Unknown/member-incomplete scope retains full.
3. Check machine-consumed text and cross-area consumers explicitly. Reuse registered suites first; existing gh620 already proves the package contract. No new case approval is implied.
4. Collect shadow-selection evidence alongside naturally required full runs, preserving first failures, retries, environment identities and receipts. Do not induce failures or add runner/gate machinery without applicable authorization.
5. Require independently reviewed policy/workflow/branch-protection and receipt compatibility plus a bounded rollout/rollback contract before reduction. Existing full choice remains the evidence-backed fallback; this research grants no waiver.

The machine-readable companion is `gh1076-historical-selection-study.json`; raw metadata/log artifacts remain in the task workspace for audit. No public issue/comment was posted by this research lane.
