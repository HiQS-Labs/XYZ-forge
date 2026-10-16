# GH1076 historical selection study — version 2

**All 20 original failed logs are now inspected; no genuinely eligible mapped-Medium failure/change pair was established.** Keep full fallback pending consumer, receipt, compatibility and normal review evidence. This closes version 1’s 14 unread-log gap, while retaining causal/pending-scope unknowns instead of guessing. It does not prove that no bounded Medium pilot could become justified.

The original six-log JSON/report are unchanged. This version corrects one earlier omission: run 36087662555’s driver failed **gh610-claude-subscription.sh and gh123-lock-progress-bound.sh as well as agent-chorus-bridge.sh**. Use version 2’s complete driver lists for that run.

## Collection and evidence boundaries

- Same frozen20 failed-run sample as version 1, not20new failures. GitHub job metadata and all 20 original failed logs retrieved read-only, totaling 30,300,983 bytes. No workflows triggered/rerun, suites executed, new cases, installs or implementation-owner source writes.
- Sixteen runs reached qualification across 13 distinct tested snapshots:13 qualification failures, one timeout, two qualification-PASS/publication-FAIL runs. Four failed prequalification discovery. These categories describe this failed-workflow sample; they are not a Medium denominator or a recall rate.
- Repeated337813e0snapshot appears in three runs, a08f30e9in two. Do not count repeat attempts as independent regressions. Eventhead SHA, tested snapshot and trigger PR merge are separate fields.
- Exact triggering PR first-parent diffs were read from immutable git objects, avoiding GitHub’s100file-list cap. Complete multi-member pending unions were not recoverable from the retained outer log alone; they remain unknown. Current broad source reads were avoided: focused-map comparison is pinned to f974fcee15647aae6551fcc81b129f5a6127120b, not the implementation owner’s changing HEAD.
- Nested fixtures print synthetic qualifications, errors and commits. Dataset identifies first outer qualification, actual driver negative-suite entries and final outer outcome. Expected failure strings inside passing guard suites are excluded. No asserted product/environment attribution relies on a string match alone.

## Complete run inventory

| Run | Tested snapshot / pending | Real outer outcome and failed driver suites |
| --- | --- | --- |
| [38611374289](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38611374289) | `aec75f1d6217` / 1 | Full qualification passed; publication failed. |
| [37723297290](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37723297290) | `e0c0bc9172d5` / 1 | `gh620-skills-army-mini-sync.sh` |
| [37009287827](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37009287827) | No qualification | Issue506could not resolve; no suite execution. |
| [36979067253](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36979067253) | No qualification | Issue506could not resolve; no suite execution. |
| [36978963707](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36978963707) | No qualification | Issue506could not resolve; no suite execution. |
| [36970981161](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36970981161) | No qualification | Issue506could not resolve; no suite execution. |
| [36087662555](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36087662555) | `0ae3452a5774` / 4 | `gh610-claude-subscription.sh`, `agent-chorus-bridge.sh`, `gh123-lock-progress-bound.sh` |
| [36062581982](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36062581982) | `c84dc61888f2` / 3 | `gh777-inventory-ratchet.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36044868273](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36044868273) | `a08f30e92242` / 3 | `gh777-inventory-ratchet.sh`, `gh139-pipe-grep-guard.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36042902034](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36042902034) | `a08f30e92242` / 3 | `gh777-inventory-ratchet.sh`, `gh610-claude-subscription.sh`, `gh139-pipe-grep-guard.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36041060266](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36041060266) | `337813e042e5` / 3 | `gh777-inventory-ratchet.sh`, `gh610-claude-subscription.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36035559968](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36035559968) | `337813e042e5` / 3 | `gh777-inventory-ratchet.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36033702443](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36033702443) | `337813e042e5` / 3 | `gh777-inventory-ratchet.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36033552439](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36033552439) | `f1321d6dbc12` / 3 | `gh777-inventory-ratchet.sh`, `gh610-claude-subscription.sh`, `pdda-repo-contract.sh`, `gh269-roadmap-retired.sh`, `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` |
| [36025506150](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36025506150) | `83483a54fb62` / 1 | Outer full runner returned124; no completed main registry summary. |
| [35957506810](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35957506810) | `34072c861450` / 1 | `registry-lock-concurrency.sh` |
| [35767844928](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35767844928) | `44e96b77eaf0` / 1 | `agent-chorus-bridge.sh` |
| [35671086913](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35671086913) | `9c38424009f9` / 1 | `gh123-lock-progress-bound.sh` |
| [35623940059](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35623940059) | `39bb1392af05` / 1 | Full qualification passed; publication failed. |
| [35552996436](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35552996436) | `5e60cb01541a` / 20 | `agent-chorus-bridge.sh` |

## Attribution and selection implications

**Publication/discovery, six runs:** four October 2 runs could not resolve issue 506before qualification (GraphQL issue identity versus access remains unknown). Run 35623940059 passed full then publication push was rejected(fetch first). Run 38611374289 passed full, hit a push race, retained receipts through receipt-first recovery, then issue 960GraphQL connection timed out during recompute; reporting also failed. Smaller suite selections do not repair these failures and must not erase qualification PASS or publication FAIL.

**Known payload, one run:**37723297290fails existing gh620 payload/manifest expectations for BOT-DAILY-HEALTH-CHECK.md. This is the already verified GH995 express fix, not a new Medium regression. Trigger PR992 has full merge-cleanup/SKILL.md and unmapped stop-hook inputs. Its failure inherited the earlier GH988/GH989 package change, showing why trigger-only routing cannot substitute for full pending/baseline attribution. Existing skills-army consumer selection covers gh620; docs precedence at the pinned baseline does not emit that area for the historical Markdown payload.

**Small-like historical triggers, two examples:** PR776 is intake/ledger/documentation only, yet full qualification found registry-lock-concurrency losing/corrupting rows(2 pass, 2 fail). PR739 changes debug-mantra Markdown/ledger, yet full found gh123 lock timing failure and later reports the re-arm probe did not exercise its intended condition. Neither establishes a mapped-Medium regression. Introduced-by-change causality is unproven; suppressing them by omitting suites is not fixing a failure. Historical pre-frequency skill paths also need semantic normalization before claiming comparison against today’s glob layout.

**Safety/global/mixed failures:** PR723 includes releases code but also ci-route.sh, validate.sh, test/ci-route.sh, unmapped express implementation and numerous unclaimed tests; it is full, not an eligible releases-only Medium example. Its pending integrated snapshots include gh777 inventory rejection of new work_connectors/github_labels.py (Small already includes gh777) and gh139’s explicit ten new pipe-into-grep-q sites in test/gh798-status-skill.sh (Small includes gh139). gh436/gh674merge-cleanup failures and global Python-layer import/parity failures also recur. Unknown full pending unions prevent assigning every failure to the triggering area.

**Bridge/probe/concurrency root causes remain bounded unknowns:** bridge failures report missing turn 2 and subsequent discussion states. Later ready-poll/diagnostic commits are contextual evidence, not proof these exact failures were environmental. gh610 subscription assertions, gh123 timing failures and registry concurrency failures likewise retain actual observed messages without asserting a product-versus-host cause. The timeout run 36025506150 returned 124 and cannot be assigned to one suite or scored as passing uncompleted suites.

At pinned f974: gh777, gh139, gh674, pdda-repo-contract and gh269 are in Small; gh620 is skills-army-hq; agent-chorus-bridge is agent-chorus; gh610, gh123, gh436 and registry-lock-concurrency have no focused-area/Small membership. **Membership is not detection proof.** Adding area unions is only meaningful after actual scope and consumer ownership are established.

## Readiness decision and actionable next evidence

No covered failure/change pair in this sample justifies a general reduced-Medium claim. The missing 14 logs were straightforward to retrieve; they are no longer an excuse to stop research. What remains is a substantive qualification condition: all identified examples are known payload, Small-like, explicit full/global/test surfaces, incomplete catch-up unions, prequalification/publish failures or root-cause unknowns.

A bounded area pilot still needs a complete eligible mapped-Medium scope, original full-run failures, identified direct/downstream consumer suites, independently reviewed receipt/policy/workflow/protection compatibility and a rollback contract. Prefer comparing proposed selections against naturally required full runs; preserve exact SHAs, first failures/retries and classification. Do not infer safe reduction from a passing selector, a chosen failed suite, an already-green full snapshot, or an arbitrary zero-miss denominator. Unknown/global/safety changes continue full.

Machine-readable version 2 includes all 20 run records, precise original log line pointers, log SHA256s, job URLs, exact trigger merge diffs, area membership and unresolved scope/attribution notes. Version1 remains available as the historical narrower study. No issue/comment posted by this read-only lane.
