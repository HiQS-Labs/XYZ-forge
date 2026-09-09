```json
{
  "decisions": [
    {
      "id": "A01",
      "decision": "HOLD",
      "reason": "The GitHub issue lacks a remediation plan; local-only plans or bug reports cannot be admitted regardless of PRS."
    },
    {
      "id": "A02",
      "decision": "ACCEPT",
      "reason": "All admission gates pass, including in-issue plan, independent review hash match, PRS, dependencies, and authorization."
    },
    {
      "id": "A03",
      "decision": "HOLD",
      "reason": "Plan content was modified after review without content-hash verification or renewed attestation."
    },
    {
      "id": "A04",
      "decision": "HOLD",
      "reason": "Parallel pair shares an unpinned serialized interface change, creating an unsafe runtime contract collision."
    },
    {
      "id": "A05",
      "decision": "ACCEPT",
      "reason": "Satisfies all admission and safety gates for a future draft proposal with disjoint write-sets and no active wave mutation."
    },
    {
      "id": "A06",
      "decision": "HOLD",
      "reason": "Issue is parked after reaching the attempt cap and cannot be automatically reset or readmitted without operator release."
    },
    {
      "id": "A07",
      "decision": "HOLD",
      "reason": "Body hash mismatch and adversarial override attempt; untrusted issue prompt injection must be rejected."
    },
    {
      "id": "A08",
      "decision": "HOLD",
      "reason": "Incomplete pagination and API failure must fail closed; unseen dependencies cannot be assumed complete."
    },
    {
      "id": "O01",
      "decision": "ACCEPT",
      "reason": "Valid turn-end boundary example with clean session partitioning, no future target leakage, and verified observation horizon."
    },
    {
      "id": "O02",
      "decision": "HOLD",
      "reason": "Input leaks future target information by including a user request that arrived after the prediction boundary."
    },
    {
      "id": "O03",
      "decision": "HOLD",
      "reason": "An expired observation horizon is censored data, not a ground-truth semantic no_action event or scoring credit."
    },
    {
      "id": "O04",
      "decision": "HOLD",
      "reason": "The comparison is unpaired over disjoint row sets and cannot support causal claims about PTQ."
    },
    {
      "id": "O05",
      "decision": "ACCEPT",
      "reason": "Valid held-out evaluation example with preserved canonical labels; inclusion for scoring is independent of prediction correctness."
    },
    {
      "id": "O06",
      "decision": "HOLD",
      "reason": "Regex extraction masks syntax errors, multiple blocks, and invalid arguments, failing the well-formed output standard."
    },
    {
      "id": "O07",
      "decision": "HOLD",
      "reason": "Race condition where an out-of-order stale prompt worker overwrites a newer prompt result due to session-only keying."
    },
    {
      "id": "O08",
      "decision": "HOLD",
      "reason": "Synthetic CLI policy probe success does not establish distribution generalization, network serving latency, or live rollout readiness."
    }
  ],
  "answers": [
    {
      "question": "Q1",
      "answer": "XYZ targets issue admission and logical grouping into Jog/Marathon proposals based on validated in-issue plans, whereas Needle targets next-observed developer action labels at turn-end boundaries over 44 canonical classes. Both can reuse the recent user request and recent action sequence, but admission requires verified plan text, review hashes, PRS ratings, and dependency DAGs, while next-action prediction strictly requires turn timestamps, prior tool sequences, and schema definitions without future events. Observational accuracy in predicting historical tool actions does not prove recommendation usefulness or developer workflow assistance.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:5-8",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:40-54",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:8-10",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:77-78",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:74-88"
      ]
    },
    {
      "question": "Q2",
      "answer": "Needle main's Stop hook only serializes context and appends a query log entry with null recommendations, whereas 710c scores previous recommendations against subsequent actions, writes pending request files, and spawns a detached inference worker. At 710c, atomic os.replace prevents torn reads but fails to prevent stale worker publication races where an earlier prompt worker finishes after a newer one and overwrites session state. To verify this without live racing, test out-of-order worker completions across prompt sequences with monotonicity fences on prompt_id and verify cancellation of superseded worker writes.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-oracle_stop_hook.py:12-18",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-oracle_stop_hook.py:74-85",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_stop_hook.py:67-90",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_infer.py:55-58",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:75"
      ]
    },
    {
      "question": "Q3",
      "answer": "Declaring 44 labels does not certify quality because native engine tool retrieval limits context to at most 5 tools, making unselected tools unreachable, while 100% parsed output in early probes was merely a regex name-extraction rate that masked malformed JSON and multiple blocks. The contract warns that semantic no_action (explicit off-topic training target yielding empty answers) must never be conflated with confidence abstention, engine failure, or censored observation horizons. A documented inconsistency exists where labels-v1.json mandates zero arguments with empty schema properties, but native model outputs and probes emit unexpected argument objects and multiple tool-call blocks.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-12.json:3-16",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-labels-v1.json:3-4",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:101-109",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:34-44"
      ]
    },
    {
      "question": "Q4",
      "answer": "Deterministic code must handle gate validation, content-hash verification of plans/reviews, PRS arithmetic and DB checks, dependency DAG traversal, write-set disjointness, preflight execution, queue mutations, and output schema validation. In cmd_jog_add (releases_app.py:3899-3915), existing terminal rows are reactivated and attempt_count is reset to 0, which deterministic admission must guard against for parked rows. Flash reasoning is strictly confined to extracting candidate remedy summaries, suggesting tentative Jog/Marathon groupings, and ranking next-action label probabilities without authority to approve plans or mutate queue state.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:40-63",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:75-79",
        "utils/py/releases_app.py:3899-3915",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:74-89",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:23-34"
      ]
    },
    {
      "question": "Q5",
      "answer": "The smallest shared preliminary experiment is an offline, paired benchmark on held-out frozen historical development sessions using fixed structured output schemas (zero-shot, no retrieval/tools) evaluated against majority baselines with strict anti-leakage and session-family isolation. Separately, XYZ must evaluate adversarial rejection of unreviewed or prompt-injected plans and grouping safety across shared contracts, while Needle must evaluate macro-recall across all 44 canonical classes (including rare governance labels), p95 network latency (<=2s), billed tokens, and explicit abstention handling. Neither experiment may allow future request leakage, cross-split session overlap, or self-graded outputs.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:80-95",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:23-45",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:68-75"
      ]
    },
    {
      "question": "Q6",
      "answer": "We should narrow Flash to semantic grouping/extraction if it exhibits false acceptances on adversarial plans, escalate to a stronger model if complex issue reasoning or rare governance labels fail, and stop if Flash cannot beat local baselines by +5pp top-1 or violates cost/latency caps. This tools-prohibited CLI trial cannot establish production guarantees because static text evaluation does not measure real-world network latency, API pricing/token charges, concurrent file race conditions under worker load, data retention compliance, or production distribution drift. Machine contracts and transactional safety must be verified by execution in disposable full clones rather than static sandbox prompts.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:96-98",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:48-53",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:68-76",
        "MACHINE-CONTRACTS.md:14-29"
      ]
    }
  ],
  "limitations": [
    "Advisory evaluation performed solely on supplied offline snapshot data without filesystem, shell, browser, or MCP tool execution.",
    "No live knowledge graph queries or empirical benchmarks were executed; direct snapshot source texts supersede stale graph metadata.",
    "Trial cannot establish production API latency, network round-trip timing, billed token costs, data retention policies, or live concurrent worker race behavior."
  ]
}
```

