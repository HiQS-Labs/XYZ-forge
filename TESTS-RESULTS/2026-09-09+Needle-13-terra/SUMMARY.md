# Codex GPT-5.6 Terra Medium: B on this bounded advisory trial

Both fresh requests return16/16 correct decisions with zero false accepts/holds. Overall B follows the existing post-hoc rubric: mostly reliable technical analysis with limited corrections. It is provisional on16 authored cases repeated twice, not production qualification, independent32caseevidence or an A-level unseen-demanding evaluation.

| Observation | Run1 | Run2 |
|---|---:|---:|
| Correct/cases |16/16|16/16|
| Client CLI wall seconds |37.348102833|38.011297541|
| Reported input tokens |55,076|55,077|
| Cached input tokens |11,008|11,008|
| Cache-write input tokens |0|0|
| Output tokens |1,794|1,931|
| Reasoning output tokens |191|309|

These are raw CLI counter names; no inferred cost or accounting equivalence to Agy. Exact requested gpt-5.6-terra with model_reasoning_effort=medium, supported by localcatalog and fetched officialmodelpage. Final JSONL lacks backendmodel attestation, so model identity is requestedselection only. No TTFT or billedcost measured.

## Technical review

Both correctly distinguish admission from next-observed-action prediction, common validation/provenance from task-specific facts, usefulness from accuracy, atomic replacement from stale publication, parked attempt resets from legitimate queue insertion, and deterministic authority from model suggestions. They propose out-of-order/prompt-version/feedback tests and frozen independent replay/negative controls, alongside task-specific evaluation. Issue citations use actual original :1 coordinates rather than invented lines, substantially improving grounding.

Run2 identifies a valid alternative current code/documentation drift: inference45 says v0top1 while inference48 keeps up to3 calls. The configured systemprompt also requires SINGLE BEST nextaction at serializer51–52, imported by oracle_config30. This is a grounded finding; it need not match our initially anticipated labels-abstention drift to count. Labels230 is valid no_action control metadata. Both Q3 answers correctly recognize serializer109 encoding semanticno_action as emptyanswers and separate censored observations from target labels.

Narrow corrections: run1's singular 'ONLY a label name' text alone is weaker evidence about output cardinality than run2's actual top1/singlebest contract. Run2 O03's short reason says an empty prediction 'is abstention' too categorically; empty output is ambiguous without outcome/provenance, including the documented semanticno_action encoding. Its fullerQ3 explicitly recognizes that encoding, and its HOLD correctly rejects fabricated groundtruth. Do not extrapolate the16/16 to all admission failures or next-action prediction accuracy. The stronger/manual-review wording should be made explicit as separate arms in a real experiment.

## Evidence and limitations

Inputs frozen c0d943c before inference. Promptbytes identical SHA2564b70abaa30ee73eb37638ce0c80c4f4f058fae28be6a7593e87f736e84398dc7; sourcepacket111980bytes SHA256dee4d8c16f2352bf4ff448aecac65d1de803d064df68c73d46e3c30c3dc41f2e. Different ephemeral threads, no continuation or repair/retry. Answers differ; no temperaturecontrol. No6000output ceiling or systemoverride claimed, though observed outputcounts are below6000. Advisorinstruction is a userprefix.

Real Codex0.153.4 exec -m gpt-5.6-terra -c model_reasoning_effort=medium -c approval_policy=never -s read-only --ephemeral --ignore-user-config --json. No sandboxbypass/ignore-rules. Userconfig suppressed but projectcontext still loaded: stderr reports AGENTS.md truncated at32KBbudget and stateDBwarnings. These are captured confounds, not proof of failed inference. Compared with originalLuna, full inline packet replaces adaptive source reading and userconfig suppression differs. Compared with Agy, runtime/system/context/toolobservability differs. Equalmodelbudget causal comparisons are not supported.

Both JSONL streams contain only threadstarted, turnstarted, one completed agentmessage and turncompleted; no command/filechange/MCP/web toolitems observed. That supports absence of tool events in these captured streams, not universal host-isolation guarantees. NativeCLI lastmessage bytes match eventtext after terminalwhitespace normalization. Frozenmanifest, distinctthreads, originalgrader/key/precontrols pass. Emptyevents, changedanswer and missingturncompletion negative controls reject. Rawstderr and all logs retained; run2consult prompt-trace classifier flagged four echoed citedclaims, retained as a harnesswarning rather than independent evidence or automaticmodel failure.

Provenance, rawJSONL/lastmessage/stderr, prompts, receipts, catalog and relaytranscripts saved. KnownOpenRouter literal and standardGoogle/OpenRouter/Bearer patterns absent; not exhaustive secret detection. No productruntime change/fullsuite, privateinput, training, livequeue action, race reproduction, productionp95/privacy or nextactionaccuracy qualification. Candidate selfstatements about notmakingmodelcalls describe advisory behavior, not the outer CLI transport.

Official model reference fetched: https://developers.openai.com/api/docs/models/gpt-5.6-terra
