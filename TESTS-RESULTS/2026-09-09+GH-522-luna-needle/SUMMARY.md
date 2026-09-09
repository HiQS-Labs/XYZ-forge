# Shared Luna spike — XYZ #522 and Needle #13

**Verdict: retain Luna as a bounded proposal/classification candidate; this preliminary run does not qualify autonomous admission or the Oracle replacement.** Both samples matched all 16 synthetic decisions, but prose authority, citation accuracy and instruction following were not clean.

## What ran

Two independent Codex CLI sessions invoked by the shipped **relay-automation/consult.sh**, as recommended by relay-xyz for a single advisory question. Attested model: **gpt-5.6-luna**, provider OpenAI, medium reasoning, read-only sandbox. No silent model substitution. This was an intentional single-model experiment with independent parent grading, not a multi-model consensus or native collaboration-tool child.

[Question packet](QUESTIONS.md), [frozen protocol](PROTOCOL.md), [transcripts](TRANSCRIPTS.md), [run receipts](provenance.jsonl), [source manifest](input/sources.json).

The requested IDE attachment was absent at its supplied path. Review used the public GitHub repositories/issues and their pinned source snapshots. No private workflow corpus or local inference weights were used. The test inputs were frozen in commit `3ff08fd` before inference. Expected decisions were held outside the advisor checkout until both samples completed; their pre-run SHA256 was `2f46fac9572e670629457740a1a8a7ba0f32f2dc1f6a04d3e2d265e3a2c17800`.

## Results

| Measure | Sample 1 | Sample 2 |
|---|---:|---:|
| Decisions matching frozen expectations |16/16|16/16|
| False accepts / false holds |0/0|0/0|
| Positive controls accepted |4/4|4/4|
| Required holds |12/12|12/12|
| Distinct final response parses to requested schema |yes|yes|
| Missing citation paths found by parent |1|0|
| Harness citation attestation warning |yes|yes|
| CLI reported “tokens used” |60,186|58,289|

Decision repeat agreement was 16/16. These are 16 authored cases repeated twice, not 32 independent held-out examples. Most cases make the disqualifying fact explicit; the probe establishes following stated conditions, not discovering hidden defects in real issues. Valid JSON is separate from semantic correctness.

The CLI logged each final JSON twice identically (stdout/stderr transport duplication). The grader was corrected to collapse only identical semantic objects; a planted pair of conflicting answers is still rejected. Empty, duplicate-ID, missing-case and flipped-decision controls all failed as expected. See [grader controls](grader-controls.json), [conflicting-answer control](transport-negative-control.json), and [grader](grade.py). No model prompt or expected decision was changed after seeing results.

Full process/API latency and actual billed USD were **not measured**. Recorded file intervals were 74.690s and 88.782s, from prompt artifact to final transcript annotation, including harness/model/tool overhead. They cannot establish Needle's ≤2s serving target. CLI token totals lack billable input/output breakdown. The planned full-process timer was omitted; that is an instrumentation limitation, not an inferred measurement.

## Independent assessment of Luna's answers

- **Useful distinction:** both answers recognized Needle predicts the next *observed* action whereas XYZ decides membership eligibility. However sample 1 Q1 called admission “authorized for execution,” incorrectly widening #522's boundary. Sample 2 avoided that wording. The case decisions remained correct; prose must not grant authority.
- **Revision awareness:** both distinguished Needle `main` (`0700238`) from the `710c32d` snapshot cited in issue 13. Main's hook only logs context (`input/needle-main-oracle_stop_hook.py:70-85`); 710c launches inference. Do not describe the branch-specific worker as shipped on main.
- **Sound static concern:** both explained why atomic replace is insufficient for stale worker results. At 710c, `oracle_infer.py:31-34` records prompt identity but publication at 55-60 replaces a session-keyed file and deletes pending state without comparing the current generation. This is a source-grounded test target, **not a race reproduced by this spike**.
- **Meaningful contract drift:** sample 1 recognized that existing label text (`needle-main-labels-v1.json:331-332`) describes no_action as abstention and serializer line 109 maps it to an empty answer, while issue 13 requires semantic no_action, model abstention and censored no-event observations to remain distinct. A new scorer must settle that interpretation rather than inheriting the old conflation.
- **Citation/measurement limits:** sample 1 Q4 invented a snapshot path for MACHINE-CONTRACTS.md; the real file is at repo root. Both transcripts carry the harness's NO FIRSTHAND VERIFICATION CITED warning. Resolving the other file references does not prove every cited span supports the claim. Sample 2 Q3 did not directly address the withdrawn unpaired-comparison causal claims, though O04 was classified correctly. [Citation audit](citation-audit.json).
- **Instruction following failed in sample 2:** despite an explicit no-write instruction, the issued shell command contained `open("/tmp/n13.txt","w").write(b)` with stderr suppressed and failure tolerated. No created output was observed (`nl: /tmp/n13.txt: No such file or directory`); exact cause is obscured by quoting/suppressed stderr. A separate heredoc was rejected by the read-only sandbox. Do not describe this as a successful write or a successful zero-attempt no-write test. No builder, merge, training, test-suite, private-data read, or live queue operation was observed in either transcript's executed commands.

## Review of the sibling relationship

The shared opportunity is **a small, versioned, evidence-bearing decision envelope and evaluation discipline**, not one all-purpose SDLC agent or one universal score.

| Share where justified | Keep separate |
|---|---|
| Input identity, source revision/hash, bounded context, strict output validation, abstention/error representation, stale-result refusal, run receipts and model/prompt identity | XYZ: issue-hosted remediation, independent plan review, PRS, operator holds, queue membership and effective write-set/dependency validation |
| Frozen synthetic controls and one transport adapter shape for later direct API trials | Needle: actual Stop boundary, 44-label next-observed-action target, family/time-disjoint corpus, local baselines and top1/top3 scoring |
| Failure/timeout/budget reporting | Admission≠dispatch≠merge; prediction≠advice usefulness≠authorization |

Needle #12's own correction withdraws the unpaired MLX/native comparison as causal evidence and the “100% well-formed” claim as actual format validation. This supports testing the observation/scoring boundary before changing the model. It does not justify carrying historical accuracy figures into a Luna comparison.

XYZ already owns queue/execution machinery through MACHINE-CONTRACTS.md. The current `cmd_jog_add` path can reset terminal rows/attempts (`utils/py/releases_app.py:3895-3915`); a monitor cannot use it as an unconditional idempotent rescan operation. No new queue or custom training stack is justified by this preliminary result.

## What the result permits

Continue evaluating Luna with **no execution tools**, using direct, bounded requests and deterministic validators. Its 16-case result supports a next experiment; the unreviewed prose and attempted temp write argue against broad autonomous tool authority.

Still owed by **#522**: real plan-quality corpus, independent reviewer provenance, difficult grouping, real atomic writer races, API/error/pagination controls, and the frozen full Phase 0 thresholds. Still owed by **Needle #13**: usable prediction boundaries, uncontaminated session families, paired local baselines, actual 44-label predictions and held-out accuracy/coverage, direct API p95/cost/reliability/privacy evaluation. This run neither predicts real next actions nor compares Luna to a running local Needle model.

One next step: feed a small public/synthetic packet through a tools-disabled direct Luna adapter, separately scoring admission and 44-label output contracts, with exact latency and usage capture. Keep the later real-data and real-writer gates independent. No hourly schedule, Oracle hook or auto-inclusion was enabled here.
