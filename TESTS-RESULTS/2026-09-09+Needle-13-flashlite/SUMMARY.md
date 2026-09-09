# Gemini 2.5 Flash-Lite: F for this tested admission/evaluation advisory configuration

Both fresh requests returned identical valid JSON but only 11/16 decisions correct: four false acceptances and one false hold per run. This is a task-specific post-hoc grade, not a general model grade. It fails the safety-sensitive screening task even on explicit authored fixtures; it is not qualified for auto-inclusion. These are 16 repeated cases, not 32 independent cases or production accuracy.

| Observation | Run 1 | Run 2 |
|---|---:|---:|
| Correct / cases | 11/16 | 11/16 |
| False ACCEPT / false HOLD | 4 / 1 | 4 / 1 |
| Client full request seconds | 12.034253042 | 12.929966791 |
| Client first answer content seconds | 1.496823083 | 2.438203583 |
| Prompt / completion tokens | 34,196 / 3,529 | 34,196 / 3,529 |
| Reported reasoning tokens | 0 | 0 |
| OpenRouter reported request cost USD | 0.0048312 | 0.0048312 |
| Provider / model | Google / google/gemini-2.5-flash-lite | same |

Total reported inference cost: $0.0096624. These are provider-reported request charges, not independently audited billing or total harness/operating cost. Two latency observations do not establish production p95.

## Exact decision failures

- A05 incorrectly HOLDs authorized future draft membership because no active wave changes are allowed; confuses limited admission with execution authority.
- O02 ACCEPTs a next user request included after the prediction boundary. It explicitly calls future leakage a valid evaluation scenario.
- O03 ACCEPTs an observation-ending/censored row whose ground truth was fabricated as no_action.
- O04 ACCEPTs the unsupported PTQ claim; its reason calls the comparison paired although the case specifies unmatched experimental conditions.
- O08 ACCEPTs promotion/accuracy claims supported only by synthetic policy classification and parseability.

## Technical answer review

Useful observations: Q1 distinguishes admission from next-action prediction at the headline level; Q2 correctly says main hook logs only and atomic replace alone cannot prevent stale publication; Q4 correctly recognizes terminal-row/attempt resets in cmd_jog_add at the supplied 3876–3936 excerpt.

Material errors: Q5 substitutes privacy for temporal leakage ('Leakage would be tested by ensuring no private data is used'), consistent with O02's unsafe acceptance. It substitutes simple/rule-based/human comparison for the requested stronger-model/local baselines. Q3 conflates no_action with abstention and treats differences between two revisions as a current documentation/code inconsistency rather than naming the supplied label-description versus serializer contract drift (labels 331–332, serializer 109). Q2 proposes checking file creation/content after one worker, which cannot falsify a stale-worker publication race. Q1 links recommendation usefulness to prediction accuracy and does not maintain their separate evidence requirements.

Citations are unreliable: needle-13.json is a single original line, yet repeated citations claim :13; needle-12.json is likewise one line, yet citations claim :10/:17/:21. xyz-522:19/:30 also invents coordinates against the single-line issue snapshot. Labels :230/:235 are not the actual no_action definition at331–332. Thus syntactically valid evidence arrays do not establish grounding.

## Provenance and limits

Existing consult.sh captured two separate raw transcripts; its codex slot is an executable-override transport, not Codex inference. Gemini/Agy CLI help was inspected; HTTP preserves explicit system instruction, temperature and output cap without tools. The supplied Google credential failed a model-availability request (API_KEY_INVALID), before inference. User-authorized OpenRouter paid fallback completed with exact model identity; provider fallback disabled. No substitution, retries, or tuned second prompt.

Requests are byte-identical. Both use unchanged 6,000 output-token ceiling, temperature0, no reasoning field and baseline 900-second cap. Qwen's 20-minute exception was not borrowed. Official Google/OpenRouter docs describe Flash-Lite default thinking off; receipts report zero reasoning tokens. Runtime/provider/hardware differ from local models.

The inherited question preamble incorrectly says 'local LM Studio API' and Q6 says 'local API'. This wording was retained for model-name-only prompt parity and disclosed rather than silently repaired for run2; actual cloud transport/usage receipts are authoritative. Consequently do not treat the candidate's transport/cost comments as informed observations. The frozen packet contains only the previously approved public/synthetic source material. No private files or credentials were given to the model.

Inputs/protocol were prepared before requests, but not committed before inference; provenance records this explicitly, birth timestamp and hashes, without claiming a preregistration commit. Original grader/key unchanged. Positive/negative grader controls passed after the calls; stream reconstruction verifies nonempty input, exact events/model/content and terminal DONE. Empty, missing-DONE and changed-answer negative controls all reject. Raw SSE blank separators retained. Credential scan found no literal OpenRouter key in artifact/transcript files. No runtime source changes, full product suite, private-data test, live issue admission, training, race reproduction or production qualification occurred.

Official API sources: https://openrouter.ai/google/gemini-2.5-flash-lite/api ; https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request ; https://ai.google.dev/gemini-api/docs/generate-content/thinking
