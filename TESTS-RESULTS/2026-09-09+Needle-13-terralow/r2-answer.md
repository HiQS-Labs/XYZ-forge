```json
{
  "decisions": [
    {"id":"A01","decision":"HOLD","reason":"A local plan cannot satisfy the required remediation plan in the GitHub issue."},
    {"id":"A02","decision":"ACCEPT","reason":"The stated evidence satisfies the proposed admission, freshness, review, PRS, dependency, and authorization gates."},
    {"id":"A03","decision":"HOLD","reason":"The reviewed plan hash is stale; cosmetic intent is not a renewed attestation."},
    {"id":"A04","decision":"HOLD","reason":"Disjoint filenames do not make a changed producer/consumer serialization contract safe for parallel membership."},
    {"id":"A05","decision":"ACCEPT","reason":"This is future-only, independently valid work with disjoint effective write-sets and no shared-contract collision."},
    {"id":"A06","decision":"HOLD","reason":"A parked item needs operator release; `jog add` can reactivate it and reset its attempts."},
    {"id":"A07","decision":"HOLD","reason":"Embedded override text is untrusted data, and the independent review binds only the earlier body hash."},
    {"id":"A08","decision":"HOLD","reason":"Incomplete pagination makes dependency and membership state unknown; unknown state must fail closed."},
    {"id":"O01","decision":"ACCEPT","reason":"The frozen, family-disjoint, boundary-correct row has a valid observed target and is eligible for locked evaluation."},
    {"id":"O02","decision":"HOLD","reason":"The future user request leaks post-boundary information into prediction input."},
    {"id":"O03","decision":"HOLD","reason":"No observed action is censored, not semantic `no_action`; an empty response is abstention, not automatically correct."},
    {"id":"O04","decision":"HOLD","reason":"Different row sets make the comparison unpaired and cannot establish PTQ causality."},
    {"id":"O05","decision":"ACCEPT","reason":"A valid held-out row belongs in scoring regardless of prediction correctness; rare labels retain supported coverage."},
    {"id":"O06","decision":"HOLD","reason":"Extracting one valid name does not validate the complete output contract or reject duplicate/multiple blocks/arguments."},
    {"id":"O07","decision":"HOLD","reason":"Session-only publication permits an old prompt result to overwrite the current prompt's result and misattribute feedback."},
    {"id":"O08","decision":"HOLD","reason":"Synthetic policy-case correctness in a tools-prohibited CLI session cannot establish production accuracy, API latency, cost, or serving readiness."}
  ],
  "answers": [
    {
      "question":"Q1",
      "answer":"XYZ predicts an admission decision for issue/work membership under deterministic policy; Needle predicts the first subsequently observed action at an end-of-turn boundary. Both can reuse frozen identity, timestamped context, provenance, output validation, and held-out evaluation discipline. Admission additionally needs plan/review/PRS/freshness/dependency/write-set facts; prediction additionally needs only pre-boundary history, an observation horizon, and independently observed labels. A workflow example may show recommendation usefulness only through a later user-facing study; observational prediction accuracy alone does not establish it.",
      "evidence":["xyz-522.json:1","needle-13.json:1","MACHINE-CONTRACTS.md:10","needle-main-serialize.py:74"]
    },
    {
      "question":"Q2",
      "answer":"Needle main's hook only serializes and logs context; it explicitly does not call a model. Revision 710c adds detached pending/inference/last-result flow and implicit feedback. `os.replace` prevents torn-file reads but not stale publication: workers are keyed and published by `session_id`, so p17 may overwrite p18. Test overlapping prompt workers, out-of-order completion, prompt-bound compare-and-publish, pending deletion, and feedback attribution.",
      "evidence":["needle-main-oracle_stop_hook.py:12","needle-main-oracle_stop_hook.py:74","needle-710c-oracle_stop_hook.py:67","needle-710c-oracle_stop_hook.py:112","needle-710c-oracle_infer.py:21","needle-710c-oracle_infer.py:55"]
    },
    {
      "question":"Q3",
      "answer":"Neither 44 labels nor a 100% parsed/name-extraction result certifies quality. Issue #12 withdraws the claimed well-formedness and causal conclusions; the serializer contract requires one label with no arguments, while `no_action` is represented as an empty answer list and must remain distinct from an output abstention. A current inconsistency is that the label contract says labels take no arguments, yet the 710c inference code accepts call objects and emits up to three recommendations despite its top-1 comment.",
      "evidence":["needle-12.json:1","needle-main-labels-v1.json:4","needle-main-labels-v1.json:230","needle-main-serialize.py:101","needle-710c-oracle_infer.py:44"]
    },
    {
      "question":"Q4",
      "answer":"Deterministic code must enforce eligibility, hashes/review binding, paused or parked status, queue membership, PRS preservation, dependency and shared-contract/write-set safety, schema/output validation, and final writer locking. Terra may summarize evidence, propose semantic grouping, explain holds, and escalate ambiguity; it must not approve itself or override contracts. Trusted plan review is revision-bound, and PRs are delivery/conflict evidence rather than issue candidates. `cmd_jog_add` refuses pending/running duplicates but reactivates another existing row as pending and resets `attempt_count`, so it cannot be used automatically for parked work.",
      "evidence":["xyz-522.json:1","MACHINE-CONTRACTS.md:16","MACHINE-CONTRACTS.md:38","MACHINE-CONTRACTS.md:104","utils/py/releases_app.py:3895","utils/py/releases_app.py:3912"]
    },
    {
      "question":"Q5",
      "answer":"Use one frozen, independently labeled replay corpus of provenance-preserving rows/snapshots with immutable IDs, family/session grouping, and planted invalid controls. It can falsify whether Terra follows bounded schemas and safely distinguishes obvious eligible/ineligible or valid/invalid predictions. XYZ must still evaluate false acceptance, stale/duplicate admission, grouping and writer races separately; Needle must still evaluate leakage-free next-action accuracy, label coverage, calibration/abstention, and stronger-model/local-baseline comparisons on the same held-out rows.",
      "evidence":["xyz-522.json:1","needle-13.json:1","MACHINE-CONTRACTS.md:16"]
    },
    {
      "question":"Q6",
      "answer":"Narrow Terra to extraction/group suggestions if it falsely accepts invalid admission cases, misses eligibility thresholds, or cannot preserve output contracts; use a stronger independent reviewer for ambiguous or failed frozen cases. Stop/replan when provenance, independent labels, deterministic writer safety, or reliable prediction boundaries are unavailable. This tools-prohibited CLI trial has neither real API calls nor production workers, so it cannot establish accuracy, p95 latency, dollar cost, privacy/data-retention behavior, or race guarantees.",
      "evidence":["xyz-522.json:1","needle-13.json:1","sources.json:7"]
    }
  ],
  "limitations": [
    "Advice is based only on the supplied snapshot evidence; no files, commands, API calls, benchmarks, race runs, or private data were accessed.",
    "The cited source revisions differ; main and 710c behavior are intentionally treated as separate snapshots."
  ]
}
```