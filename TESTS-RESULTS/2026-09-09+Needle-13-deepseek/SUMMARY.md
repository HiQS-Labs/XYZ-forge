# DeepSeek V4 Flash0731: F for bounded answer delivery

Both actual DeepSeekHarness/OpenRouter calls ended with explicit max-tokens and no final answer. F applies to delivery under this tested6000token/high-reasoning configuration. Accuracy and technical reasoning quality are ungraded, not0/16 and not a general modelF. No additional remote calls or retuning performed.

| Observation | Run1 | Run2 |
|---|---:|---:|
| Client wall seconds |262.325465542|129.330808000|
| CLI exit |1|1|
| Harness finish reason |max-tokens|max-tokens|
| Final answer characters excluding newline |0|0|
| Returned decisions |0|0|
| Reported inputTokens |30,623|30,624|
| Reported outputTokens |6,000|6,000|
| Reported reasoningTokens |6,864|6,703|
| Reported cacheReadTokens |0|0|
| Accuracy/source-review |unavailable|unavailable|

**Counter caveat:** raw reasoningTokens exceeds outputTokens. Preserve these reported values without summing, normalizing or claiming all6,000tokens were reasoning. The decisive evidence is empty assistant content plus max-tokens finish in both sessions. No reasoning text was captured in the assistant content. Billedcost not provided in retained harnessusage; no catalog-based estimate substituted. Neither900secondwallcap nor870secondsubprocesscap was reached.

## Actual harness and model route

Installed DeepSeekHarness node apps/cli/lib/bin.js --profileheadless --patch overlay ran both calls. No directAPI replacement. Exact OpenRouter catalog model deepseek/deepseek-v4-flash-0731, canonical20260731. Both llm-deepseek route and agent-default-model explicitly pinned exactmodel. Durable request/context and assistant model-source metadata name exact0731 model under deepseek-official adapter, whose baseURL is OpenRouter. This is harnessroute metadata, not independent backendattestation; provider routing fallback is not exposed by this adapter. No alternate model configured.

Thinking enabled/high, maxTokens6000 at adapter/modelconfig, retryPolicymaxRetries0. Temperatureunset. This outputcap matches earlierHTTPtrials but differs from uncappedrecentCLItrials. Systeminstruction is userprefix plus harnesssystemcontext, not a fully controlledHTTPsystem override. No causal comparison with those other environments.

Alltool-*plugins and titleLLMdisabled, native toolmode, read-only permissionenv, approvalask; no dangerfullaccess builderpreset. Emptyexperimentsettings prevent savedmodeloverride. Projectinstructions/skillfilesystem/goaldriver disabled. Each durable session shows exactlyone request/header and one step/start; no extra titleinference. Session/title event is fallbackmetadata. No livequeue or tool action observed. Productruntime source unchanged.

## Evidence

Inputs frozen6cdf5d8 beforecalls. Promptbytes identical SHA25666ee95c9838baa2e1cfe7a018844ab301a26f68377f6df4c389fb834a56301fe; sourcepacket111980bytes SHA256dee4d8c16f2352bf4ff448aecac65d1de803d064df68c73d46e3c30c3dc41f2e. Twofreshsessions/worktrees, same16cases/sixquestions, no previousanswers/key. Both originalgrader calls reject emptyoutput; explicit gradefiles recordnullaccuracy and noanswer. Pre-run graderpositive/negative controls unchanged.

Rawcompressed session.jsonl.zstd files retained with decompressed byte-equivalent JSONL copies, stdoutnewline, stderr, receipts, composedconfig and relaytranscripts. Adapter's new_session_files field is empty because it searched*.jsonl while runtime stored*.jsonl.zstd; provenance corrects this with exactcompressedpaths/hashes. Nonempty durable receipts verify one request/step, correctmodel, emptycontent and max-tokens. Empty/missingfinish negativecontrols reject; unchangedmanifest and identicalprompt confirmed. This verifies recorded failure, not passing the modeltask.

KnownOpenRoutersecret and standardGoogle/OpenRouter/Bearer patterns absent from artifact/transcript/decompressedlogs; scan notexhaustive. Key passed through environment to actualharness provideradapter, not prompt/log/argv. No productfullsuite, privateinput, training, thirdinference, race reproduction, productionprivacy/p95/nextactionaccuracy claim. Allrequestedremote testing ends here.
