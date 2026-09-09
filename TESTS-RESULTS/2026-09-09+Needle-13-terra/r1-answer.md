```json
{
  "decisions": [
    {"id":"A01","decision":"HOLD","reason":"Required remediation plan is absent from the GitHub issue; local capture is insufficient."},
    {"id":"A02","decision":"ACCEPT","reason":"The stated evidence satisfies the proposed exact-revision, readiness, and authorization gates."},
    {"id":"A03","decision":"HOLD","reason":"Post-review plan edits invalidate the cited attestation until hash comparison and renewed review."},
    {"id":"A04","decision":"HOLD","reason":"Disjoint files do not make a changed producer/consumer format safe for parallel membership."},
    {"id":"A05","decision":"ACCEPT","reason":"Future membership is independently valid, disjoint, and has no stated shared-contract collision."},
    {"id":"A06","decision":"HOLD","reason":"Park release is absent, and current jog add can reset terminal attempts."},
    {"id":"A07","decision":"HOLD","reason":"Embedded override text is untrusted data and the current review binds only the earlier body hash."},
    {"id":"A08","decision":"HOLD","reason":"A failed page leaves dependency and membership evidence incomplete; unknown must fail closed."},
    {"id":"O01","decision":"ACCEPT","reason":"It has a valid prediction boundary, no target leakage, disjoint families, valid labels, and observed target."},
    {"id":"O02","decision":"HOLD","reason":"The next request is post-boundary target leakage."},
    {"id":"O03","decision":"HOLD","reason":"No observation is censored, not semantic no_action; an empty response is not thereby correct."},
    {"id":"O04","decision":"HOLD","reason":"Different row sets make the claimed paired causal conclusion unsupported."},
    {"id":"O05","decision":"ACCEPT","reason":"This is a valid held-out row and scoring inclusion must not depend on prediction correctness."},
    {"id":"O06","decision":"HOLD","reason":"Extracting one name cannot validate multiple blocks, duplicates, or invalid arguments."},
    {"id":"O07","decision":"HOLD","reason":"Session-only publication permits an older prompt result to overwrite the current prompt's result."},
    {"id":"O08","decision":"HOLD","reason":"Synthetic CLI correctness establishes neither measured production accuracy nor service operating gates."}
  ],
  "answers": [
    {
      "question":"Q1",
      "answer":"[Should] XYZ predicts whether a proposed issue may enter a specific Jog/Marathon membership; Needle predicts the first subsequently observed action at an end-of-turn boundary. Both can reuse frozen inputs, identity/provenance, untrusted-text handling, deterministic validation, and independent labels, but admission requires current plan/review/PRS/dependency/authorization facts while prediction requires pre-boundary history and a later observed target. A workflow example may show recommendation usefulness only through a separate user-facing study; observational next-action accuracy does not establish usefulness.",
      "evidence":["needle-13.json:1","xyz-522.json:1","MACHINE-CONTRACTS.md:10-12","utils/py/releases_app.py:3895-3914"]
    },
    {
      "question":"Q2",
      "answer":"[Blocker] Main's hook only serializes and logs; it explicitly does not call a model. Revision 710c adds detached inference, pending/last records, implicit feedback, and atomic replacement, but os.replace prevents torn files only—not an old worker overwriting a newer prompt under the same session ID. Test prompt-version/CAS publication, stale-worker completion order, feedback attribution, and concurrent temp-file isolation.",
      "evidence":["needle-main-oracle_stop_hook.py:12-18","needle-710c-oracle_stop_hook.py:16-22","needle-710c-oracle_infer.py:31-34","needle-710c-oracle_infer.py:55-60","needle-710c-oracle_stop_hook.py:67-90","MACHINE-CONTRACTS.md:21-29"]
    },
    {
      "question":"Q3",
      "answer":"[Blocker] Forty-four labels and a reported 100% parsed/well-formed rate cannot certify prediction quality: Needle #12 withdraws the name-extraction interpretation and unpaired comparison. The serializer contract says labels take no arguments and encodes semantic no_action as empty answers, so no_action is a labeled target whereas an empty model response may instead be abstention/failure and must be scored separately. A current inconsistency is that the labels file calls output “ONLY a label name,” while 710c inference accepts up to three calls.",
      "evidence":["needle-12.json:1","needle-main-labels-v1.json:2-8","needle-main-labels-v1.json:230-239","needle-main-serialize.py:99-115","needle-710c-oracle_infer.py:44-49"]
    },
    {
      "question":"Q4",
      "answer":"[Should] Deterministic code must validate identity, hashes, plan/review/PRS provenance, paused or parked state, dependencies, effective write sets/shared contracts, output schema, freshness, and writer results; Terra may extract evidence and propose explanations or logical groups only. Trusted review and admission authorization remain deterministic/upstream facts, not Terra judgments. In particular, cmd_jog_add rejects pending/running duplicates but reactivates other existing rows and resets attempt_count, so scanners cannot use it to revive parked work.",
      "evidence":["xyz-522.json:1","MACHINE-CONTRACTS.md:16-29","MACHINE-CONTRACTS.md:38-40","utils/py/releases_app.py:3895-3914"]
    },
    {
      "question":"Q5",
      "answer":"[Should] The smallest shared falsification experiment is a frozen, independently labeled replay corpus with immutable row/session/family IDs, deliberate leakage and malformed-output controls, and Terra compared against a stronger/manual reviewer plus local deterministic baselines. Both projects need complete coverage and false-accept accounting, but XYZ must separately test stale/duplicate writer admission and unsafe grouping, while Needle must separately test held-out family prediction accuracy, observation horizons, abstention, and per-label support.",
      "evidence":["xyz-522.json:1","needle-13.json:1","MACHINE-CONTRACTS.md:16-24"]
    },
    {
      "question":"Q6",
      "answer":"[Should] Narrow Terra to extraction/group suggestions when it false-accepts ineligible material or misses eligibility/grouping gates; compare a stronger model on the same frozen suite; stop when trustworthy provenance, containment, or revision-bound duplicate/stale prevention is unavailable. For Needle, stop or declare inconclusive when boundaries, provenance, independent support, or locked-test evidence is inadequate. This tools-prohibited synthetic trial measures none of production accuracy, latency, billed cost, privacy/data handling, or stale-publication races.",
      "evidence":["xyz-522.json:1","needle-13.json:1","sources.json:1-7","needle-710c-oracle_infer.py:55-60"]
    }
  ],
  "limitations": [
    "Advice is based solely on the supplied source packet and synthetic cases; no files, commands, APIs, model calls, races, benchmarks, or private data were accessed.",
    "The cited 710c files are a distinct revision from Needle main; conclusions do not assert current deployment state.",
    "No empirical claim about Terra or any model’s accuracy, latency, cost, privacy, or serving behavior is made."
  ]
}
```