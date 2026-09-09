```json
{
  "decisions": [
    {
      "id": "A01",
      "decision": "HOLD",
      "reason": "[Blocker] Reject admission on this fixture: despite PRS, reproducible bug evidence is only in local capture and the GitHub issue body has no remediation plan, so it violates the required issue-body plan gate."
    },
    {
      "id": "A02",
      "decision": "ACCEPT",
      "reason": "[Pass] Treat as admissible-in-principle: allowlisted issue, concrete plan and repro, trusted review tied to the exact hash, and matching dependency/queue/rules evidence are present."
    },
    {
      "id": "A03",
      "decision": "HOLD",
      "reason": "[Blocker] The admission content changed after review and no re-attested hash exists, so previous review/PRS binding cannot be trusted for execution."
    },
    {
      "id": "A04",
      "decision": "HOLD",
      "reason": "[Should] Parallel membership must be denied until there is an explicit pinned shared format/integration contract; changed serialized producer/consumer formats without an interface agreement are not safe to co-membership."
    },
    {
      "id": "A05",
      "decision": "ACCEPT",
      "reason": "[Pass] The second issue is structurally valid and disjoint-write-set/contract-safe relative to A02; future-draft status means advisory grouping only until membership policy is activated."
    },
    {
      "id": "A06",
      "decision": "HOLD",
      "reason": "[Blocker] Parked/attempt-capped work must stay parked: `jog add` reset behavior can unpause/rewind terminal state and attempts if automatically rescanned."
    },
    {
      "id": "A07",
      "decision": "HOLD",
      "reason": "[Blocker] A policy-override instruction in issue text is untrusted relative to independent review; review evidence is bound to earlier content only."
    },
    {
      "id": "A08",
      "decision": "HOLD",
      "reason": "[Should] Missing dependency/membership inventory from partial API responses invalidates deterministic inclusion; treating unknown dependencies as complete is unsafe for admission correctness."
    },
    {
      "id": "O01",
      "decision": "ACCEPT",
      "reason": "[Pass] This is a valid locked-evaluation example: disjoint train/dev/test family context and complete next-observed-action target support inclusion for scoring."
    },
    {
      "id": "O02",
      "decision": "HOLD",
      "reason": "[Blocker] Boundary leak: including the next request (arrived after prediction boundary) invalidates this as a strict next-action prediction fixture."
    },
    {
      "id": "O03",
      "decision": "HOLD",
      "reason": "[Should] Semantic no_action credit on empty response is an adjudication decision, not an automatic model-quality proxy; this should not be accepted as baseline-equivalent correctness without explicit abstention policy handling."
    },
    {
      "id": "O04",
      "decision": "HOLD",
      "reason": "[Blocker] The claimed PTQ-vs-MLX comparison is not a paired row-matched claim and therefore cannot prove root cause by itself."
    },
    {
      "id": "O05",
      "decision": "ACCEPT",
      "reason": "[Pass] Include this held-out family in scoring regardless of top-1 label because row IDs and held-out support are canonical and stable."
    },
    {
      "id": "O06",
      "decision": "HOLD",
      "reason": "[Blocker] Duplicate/invalid argument payloads and two-block output are parser-validity hazards; a single-name regex match is insufficient for quality-safe acceptance."
    },
    {
      "id": "O07",
      "decision": "HOLD",
      "reason": "[Should] Out-of-order completions across workers with same session id can display stale results under current attribution rules; this requires explicit freshness handling before acceptance."
    },
    {
      "id": "O08",
      "decision": "HOLD",
      "reason": "[Should] Sixteen synthetic policy cases do not establish live-next-action uplift, p95 service latency, or production readiness by themselves."
    }
  ],
  "answers": [
    {
      "question": "Q1",
      "answer": "The projects differ on targets: XYZ admission predicts whether an issue should pass deterministic gates into Jog/Marathon, while Oracle predicts the next in-session action label for the current stop-turn. Reusable minimum context is versioned provenance and serialization/version discipline (session/issue identity, label schema version, and deterministic query framing), while admission-specific facts include explicit issue remediation plan, review hash, PRS binding, dependency freshness, and queue revision checks. A valid Oracle scoring example does not automatically prove advisory usefulness: O01 is a locked-evaluation pattern, but O02 explicitly violates the boundary by including post-boundary request context, so the same artifact cannot be used as both recommendation-utility and predictive-accuracy evidence.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:1",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:33",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:43",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:48",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:74",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_stop_hook.py:13"
      ]
    },
    {
      "question": "Q2",
      "answer": "Needle main stop-hook only rebuilds context and appends a serialized query record; it does not call a predictor yet. The 710c path writes `pending/<session>.json`, spawns detached inference, and persists recommendations to `last/<session>.json` after inference. `os.replace` in 710c prevents torn writes but does not prevent stale publication; it only guarantees atomic file replacement, so ordering and freshness must be enforced separately. Recommended tests: (1) same-session old/new worker race with out-of-order completion, (2) prompt_id/session_id mismatch rejection, (3) restart/crash around worker writes, and (4) duplicate stop events from unchanged transcript snapshots.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-oracle_stop_hook.py:12",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-oracle_stop_hook.py:15",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_stop_hook.py:20",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_stop_hook.py:112",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_infer.py:55",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-710c-oracle_infer.py:58",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:75"
      ]
    },
    {
      "question": "Q3",
      "answer": "No—44 labels and a parser-looking 100% score are not sufficient evidence of quality. #12 explicitly retracts prior claims and clarifies that its earlier \"well-formed\" phrasing was a name-extraction rate, not a proof of correctness, and O06 shows malformed/multi-block outputs with unexpected arguments still being treated as parseable. The label contract says labels should be names (no arguments), while `no_action` is a dedicated control label represented as empty answers in training rows, so abstention/transport failure must remain a separate state from an explicit `no_action` recommendation.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-12.json:1",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-labels-v1.json:4",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-labels-v1.json:230",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:101",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-main-serialize.py:109",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:70"
      ]
    },
    {
      "question": "Q4",
      "answer": "Deterministic code should own all gate decisions and state transitions; Spark should only propose and never own authority. For XYZ that means deterministic admission validation (issue identity, plan-research integrity, PRS review hash, dependency and grouping checks, and queue/lease state) plus contract-safe queue writes; for Oracle that means shared serializer/stop reconstruction and artifact format validation, with model output treated as untrusted suggestions. Parked-work handling is especially deterministic: `cmd_jog_add` can reset non-pending rows (including previously parked entries) by reactivating them and zeroing attempt counts, so advisory LLM output cannot be allowed to bypass pause/hold semantics; contract-driven receipts and schema validation from machine contracts remain the output boundary."
      ,
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/xyz-522.json:33",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:10",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:28",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/utils/py/releases_app.py:3895",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/MACHINE-CONTRACTS.md:16",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/MACHINE-CONTRACTS.md:31"
      ]
    },
    {
      "question": "Q5",
      "answer": "Smallest shared falsification experiment: a frozen, tiny paired fixture (for both projects) with independent labels, fixed IDs, and hard negative controls that can be replayed identically across models, emphasizing leakage-proof inputs and false acceptance. It should include: boundary-safe Oracle rows, issue variants with stale/mutated plan/review hashes, ineligible admission examples, rare/independent labels (including `no_action` handling), and expected misses so zero calls on unchanged snapshots are enforced. Separately, Oracle must still test boundary freshness and worker-staleness behavior (`prompt_id`/`session_id`, out-of-order completions), while XYZ must still test queue write invariants (`jog add`/park/rescore behavior, duplicate/concurrency safety, dependency freshness) and compare against stronger-model/local baselines on the same frozen manifest.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:48",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:55",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:28",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:33",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:75",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:73",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-12.json:56"
      ]
    },
    {
      "question": "Q6",
      "answer": "Use HOLD-to-narrow when untrusted admissions or parsing/ordering hazards remain (e.g., stale issue edits, ineligible acceptance, malformed multi-call output, out-of-order session writes), escalate to a stronger model only after deterministic gates are in place, and STOP if frozen-identity and writer-atomicity requirements cannot be closed. This review cannot claim production accuracy, latency, dollar cost, privacy posture, or race safety because no real queue writes, no native inference or remote API execution, and no live deployment were run here, and the provided scope is explicitly a synthetic/probing evidence packet.",
      "evidence": [
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:78",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:75",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/cases.json:70",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/sources.json:7",
        "TESTS-RESULTS/2026-09-09+GH-522-luna-needle/input/needle-13.json:1"
      ]
    }
  ],
  "limitations": [
    "Recommendation: gate Spark/luna to read-only advisory mode, run the shared tiny-falsification suite first (frozen IDs, zero-drift boundaries, stronger baseline comparisons, and stale-state tests), and only then consider local-vs-remote replacement or grouping rollout for production paths.",
    "This is an evidence-only review in a no-tool mode; no execution, CLI run, private corpus experiment, native Needle inference, or live queue mutation occurred."
  ]
}
```