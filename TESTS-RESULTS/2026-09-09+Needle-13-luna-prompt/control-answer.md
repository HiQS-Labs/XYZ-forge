```json
{
  "decisions": [
    {"id":"A01","decision":"HOLD","reason":"A bug report and high PRS do not replace a substantive remediation plan in the GitHub issue."},
    {"id":"A02","decision":"ACCEPT","reason":"All identity, plan, review, PRS, freshness, dependency, and admission checks match."},
    {"id":"A03","decision":"HOLD","reason":"Editing the plan invalidates the content-bound review until the revision is re-attested."},
    {"id":"A04","decision":"HOLD","reason":"A shared serialized interface creates an unpinned producer-consumer contract collision; parallel membership is unsafe."},
    {"id":"A05","decision":"ACCEPT","reason":"The requested future draft membership is independently valid with disjoint effective write-sets and no shared-contract collision."},
    {"id":"A06","decision":"HOLD","reason":"A parked attempt-capped item requires explicit operator release; jog add can reset terminal status and attempts."},
    {"id":"A07","decision":"HOLD","reason":"The issue contains untrusted bypass text and the review covers only an earlier body hash."},
    {"id":"A08","decision":"HOLD","reason":"Incomplete pagination leaves dependencies and membership unknown; unseen evidence cannot be presumed complete."},
    {"id":"O01","decision":"ACCEPT","reason":"The prediction boundary, family-disjoint split, target-free input, valid labels, and observed in-horizon target satisfy inclusion."},
    {"id":"O02","decision":"HOLD","reason":"The input contains information arriving after the prediction boundary, causing temporal leakage."},
    {"id":"O03","decision":"HOLD","reason":"No observed action within the horizon is censored/unknown, not automatically semantic no_action; an empty response is not proof of correctness."},
    {"id":"O04","decision":"HOLD","reason":"The engine and MLX results use different rows and cannot support a paired causal claim about PTQ."},
    {"id":"O05","decision":"ACCEPT","reason":"Valid held-out coverage and exact row identity support inclusion; correctness is scored separately from eligibility."},
    {"id":"O06","decision":"HOLD","reason":"Regex name extraction does not validate multiple blocks, duplicate labels, or argument-shape violations."},
    {"id":"O07","decision":"HOLD","reason":"Last-finished publication keyed only by session can let an old worker overwrite current state and misattribute feedback."},
    {"id":"O08","decision":"HOLD","reason":"Sixteen synthetic successes cannot establish production accuracy, latency, or serving readiness."}
  ],
  "answers": [
    {
      "question":"Q1",
      "answer":"XYZ predicts admission eligibility and proposed Jog/Marathon grouping, while Needle predicts the next observed action label at a defined end-of-turn boundary; neither target is what the developer should do. Both can reuse current request/history context, canonical labels, provenance, and deterministic serialization, but XYZ must retain issue-plan/review/PRS/dependency/queue freshness facts, whereas Needle must retain session identity, temporal boundary, observed target, horizon, and label mapping. One workflow example can show recommendation usefulness only indirectly; predictive accuracy and user-facing recommendation benefit require separate evidence.",
      "evidence":["xyz-522.json:1","needle-13.json:1","needle-main-serialize.py:1"]
    },
    {
      "question":"Q2",
      "answer":"Needle main only reconstructs and logs serialized context and does not call a model; the 710c revision adds detached inference, pending/last records, feedback, and model output. Atomic os.replace prevents torn files but not stale-worker overwrites, because publication is keyed by session_id without a prompt-generation or monotonic revision check. Test delayed old/new workers, concurrent writers, restart, stale feedback attribution, and current-display identity.",
      "evidence":["needle-main-oracle_stop_hook.py:12","needle-710c-oracle_stop_hook.py:12","needle-710c-oracle_infer.py:31","needle-710c-oracle_infer.py:55"]
    },
    {
      "question":"Q3",
      "answer":"Neither 44 labels nor 100% parsed/name-extracted outputs certifies quality: coverage, leakage, target correctness, malformed structures, abstentions, and per-label support still matter. The serializer contract makes no_action an empty answer while labels take no arguments, so an abstention must not be conflated with an observed no_action target; #12 explicitly withdraws the 100% well-formed and unpaired/PTQ claims. A current inconsistency is that the 710c inference path can emit up to three recommendations while the main label/output contract says the model predicts one label.",
      "evidence":["needle-main-labels-v1.json:3","needle-main-labels-v1.json:230","needle-main-serialize.py:96","needle-710c-oracle_infer.py:44","needle-12.json:1"]
    },
    {
      "question":"Q4",
      "answer":"Deterministic code should enforce issue identity, plan/review/PRS hashes, freshness, dependency and effective-write-set checks, parked/paused holds, trusted plan review, PRS preservation, queue revisions, contract validation, idempotent writes, and output validation; Luna should explain or suggest eligibility and grouping only. Jog owns queue/lease state while Marathon owns execution, review, gates, and PR identity, and machine contracts require schema validation, explicit nulls, and refusal of unknown versions. cmd_jog_add refuses pending/running duplicates but reactivates terminal rows and resets attempt_count, so a rescanner must not use it to release parked work.",
      "evidence":["xyz-522.json:1","MACHINE-CONTRACTS.md:10","MACHINE-CONTRACTS.md:112","releases_app.py:3895","releases_app.py:3912"]
    },
    {
      "question":"Q5",
      "answer":"The smallest shared experiment is a frozen, read-only replay suite with paired rows covering valid and adversarial cases, deterministic validators, leakage and overlap controls, malformed outputs, stale responses, and stronger-model/local baselines. Both projects must separately evaluate their own target labels, coverage, false acceptance, independent session/family identity, and operational failure policy; admission additionally needs race/duplicate/parked-state writer tests, while Needle needs prediction-boundary, horizon, no_action, and next-event censoring tests. Any result must use immutable manifests, independent labels, nonempty splits, no future data, and report unsupported classes and abstentions rather than silently dropping them.",
      "evidence":["xyz-522.json:1","needle-13.json:1","MACHINE-CONTRACTS.md:16"]
    },
    {
      "question":"Q6",
      "answer":"Narrow Luna to extraction/group suggestions when it misses eligibility or grouping bars, produces false accepts, requires frequent human repair, or cannot handle adversarial/stale evidence; compare a stronger model on the same frozen suite. Stop or replan when provenance, containment, atomic writer guarantees, privacy/retention approval, or reliable labels cannot be established; do not enable automatic admission or live advice on synthetic correctness alone. This tools-prohibited trial measured none of production accuracy, latency, cost, privacy, reliability, or race behavior, so those remain unestablished.",
      "evidence":["xyz-522.json:1","needle-13.json:1","needle-710c-oracle_infer.py:55"]
    }
  ],
  "limitations": [
    "This is a source-packet review only; no files, tools, tests, model calls, races, benchmarks, or production systems were executed.",
    "The supplied packet does not establish live API entitlement, current pricing, retention behavior, latency, dollar cost, or production accuracy.",
    "The 710c atomic publication path is inspected statically; stale-worker behavior remains a test requirement, not an observed race result."
  ]
}
```