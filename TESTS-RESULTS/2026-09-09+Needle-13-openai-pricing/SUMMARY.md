# OpenAI candidates: current price comparison

Scope: evaluated candidates in this Needle spike, not unmetered orchestration. Luna Medium, Terra Medium and Terra Low represent two model IDs. Current Standard short-context API rates (USD per1M tokens, checked2026-09-09):

| Candidate | Input | Cached input | Output | Grade |
|---|---:|---:|---:|---|
| GPT-5.6 Luna Medium |$0.20|$0.02|$1.20|C|
| GPT-5.6 Terra Medium |$2.00|$0.20|$12.00|B provisional|
| GPT-5.6 Terra Low |$2.00|$0.20|$12.00|B provisional|

[Official Standard prices](https://developers.openai.com/api/docs/pricing). Cache-write rates are$0.25/M forLuna and$2.50/M forTerra; Terra runs recorded zero cachewrites. Long-context rates differ above272K input; these Terra prompts are~55K. No Batch/Flex/Fast/regional modifier applied. Luna costs one-tenth as much at equal token mix; low versus medium does not change Terra's model tariff. Reasoning is billed at output rates and is included in API output-token usage, not added a second time. [Reasoning usage and billing](https://developers.openai.com/api/docs/guides/reasoning).

| Configuration | Run1 API-equivalent estimate | Run2 estimate | Both | Both assuming all input uncached |
|---|---:|---:|---:|---:|
| Luna Medium |Unavailable|Unavailable|Unavailable|Unavailable|
| Terra Medium |$0.1118656|$0.1135116|$0.2253772|$0.2650060|
| Terra Low |$0.1272012|$0.1210956|$0.2482968|$0.2639640|

These are **illustrative counter-based API estimates, not observed Codex charges**. Assumes CLI input/cache/output fields follow API accounting (cachedinput subset, reasoning already inoutput). Formula: ((input-cached)*inputrate + cached*cacherate + output*outputrate)/1M. No tool costs/subscriptions/taxes. Luna retained only aggregate tokens_used60186/58289, insufficient to split input/output/cache, so no comparable Luna runcost is invented. Orchestrator usage was not metered.

Low's estimated total is about10.17% higher with observed caches, despite324reasoning tokens versus Medium500. Low got8704cached input versus Medium22016. With cache removed equally, Low is only~0.39% cheaper; this is arithmetic, not controlled causal savings. Two runs do not establish stable speed/quality/cost differences. Both settings16/16twice and provisionalB; Low still makes an unsupported call-object-versus-no-arguments inconsistency claim even while identifying real contractdrift.

Normalized illustration:10K uncached input+1K output costs Luna$0.0032 and Terra$0.032 perrequest. At one such request/hour for30days, that is$2.304 versus$23.04 in API inference only. This is a hypothetical small-request workload, not measured schedulerproduction or subscriptionbilling.
