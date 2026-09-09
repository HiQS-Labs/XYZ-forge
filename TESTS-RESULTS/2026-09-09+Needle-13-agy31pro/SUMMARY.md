# Antigravity CLI Gemini 3.1 Pro (High): C for this tested advisory configuration

Both calls produced valid JSON and16/16 correct fixture decisions, zero false accepts/holds. Overall C follows the existing task-specific rubric: useful eligibility/stale-worker/authority signal, but material semantic errors and unreliable citations require independent review. It is not stronger-model qualification, a general model grade, or evidence of superiority to Flash.

**The CLI has no equivalent6000output-token cap or temperature/system override.** Reported output9,621/9,638 includes7,507/7,567 thinking tokens, exceeding the HTTP trial allowance. Advisor instruction is prefixed to userprompt; CLI supplies its own system/context. Same CLI methodology as Flash3.7, modelnames only changed in questions/selection; protocol's HTTP wording describes adaptation from earlier HTTP trials, not an additional change from Flash3.7.

| Observation | Run1 | Run2 |
|---|---:|---:|
| Correct/cases |16/16|16/16|
| Client CLI wall seconds |80.688503584|78.024181542|
| CLI reported duration seconds |75.902923|74.067824|
| Reported input tokens |47,060|47,063|
| Reported cache-read tokens |8,164|8,164|
| Reported output tokens |9,621|9,638|
| Reported thinking tokens |7,507|7,567|
| Reported total tokens |56,681|56,701|
| Turns |1|1|

Exact requested CLIidentifier gemini-3.1-pro-high, efforthigh. Live catalog verified and both logs propagate Gemini3.1Pro(High) selected backend override. This is CLI selection evidence, not independent backend identity attestation: responseJSON has no model field. Dollar cost/TTFT unavailable; token counters are reported fields, not a billing inference.

## Source review

Useful in both: clean separation of eligibility from next-observed-action prediction and usefulness from behavioral accuracy; main logging-only versus710c detached inference; atomic replacement insufficient for stale-worker protection; delayed-worker testing; parked attempt reset and deterministic gates; all16 case decisions correct.

Material errors retained rather than averaged away:
- Run1 Q3 defines semantic no_action as 'the user will do nothing' and claims model abstention means returning an empty list. This is wrong against supplied serializer109, which explicitly emits empty answers for semantic no_action. Its distinction is substantive misinformation, not merely an omitted caveat. Run2 states the categories should differ but does not repair or invalidate the earlier result.
- Run2 Q1 categorically says the projects cannot reuse context, contradicting run1's sensible shared workflow/session extraction and overlooking common contextual facts. Different decision-specific inputs do not imply zero reusable context.
- Both Q3 answers substitute invalid argument acceptance/output violation for the requested current labels331–332 abstention wording versus serializer109 contract drift.
- Many issue citations invent multiline coordinates although each original issue JSON snapshot is a single line. Source-grounding is untrustworthy despite valid evidence-array syntax.
- Preliminary experiment answers leave weaker details for frozen row/prompt pairing, coverage and explicitly paired stronger/local model baselines. R2's 'stronger baseline(local or independent manual review)' does not specify the requested stronger-model arm.
- Statements that this CLI trial makes no real network API requests are false about its execution. The CLI did invoke its service, although these measurements do not qualify production p95, privacy or database race guarantees.

## Provenance and bounds

Inputs frozen8958eb2 before calls. Two distinct conversations/worktrees with identical promptbytes71b95b9c27682064b7376e122628216162b7fd7f06202d43f3c94c7f59d9555d and unchanged sourcepacket111980bytes SHA256 dee4d8c16f2352bf4ff448aecac65d1de803d064df68c73d46e3c30c3dc41f2e. No prioranswers/key in prompt, no continuation/tuning/retry. Responses differ; temperature/runtime context not controlled.16 repeated cases are not32 independent cases.

Real agy --sandbox --mode plan --disable-slash-commands --output-format json, unique logs, CLI840/subprocess870/harness900seconds. No dangerously-skip-permissions; Qwen exception unused. Tool use prohibited in prompt but JSON/runtime logs not exhaustive tool-event streams, so actual tool use unknown. Do not convert model selfclaims or absent log markers to proof of no tools. CLI sandbox does not establish complete host isolation.

Existing consult captures relaytranscripts; codexslot is an executable override to realagy. Rawstdout/stderr/runtime logs, exact extractedanswers, receipts, usage and provenance retained. Originalgrader/key and precontrols unchanged. Nonempty exact extraction/selectedlabel checks, distinctconversations and unchangedmanifest pass. Emptyresponse/changedanswer/wrongselectedlabel controls reject. Known credential literal and standardGoogle/OpenRouter/Bearer patterns absent; not an exhaustive detector. No productruntime change/fullsuite, privateinput, training, livequeue mutation, race reproduction, realnextactionaccuracy or production qualification.
