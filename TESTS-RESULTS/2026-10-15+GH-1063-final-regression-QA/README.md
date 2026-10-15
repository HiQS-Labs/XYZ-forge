# Final implementation regression QA — GH1063

Tested exact final implementation merge: **5c46c49b6580711300fc141c6896c1946028e4ab**, after1054→1065→1058→1061 merged. Fresh full Mac Studio clone; no original-primary testing, runtime edit, CI assertion/case, suite, registry or gate addition. Root HEAD/tree/origin/bare/config match before/after.

**Overall disposition: QUALIFIED — unresolved native replay finding. Do not call the whole QA clean/PASS.**

| Observation | Actual result | Evidence |
|---|---|---|
| Unchanged existing recovery input |34/34 PASS,64.06s | recovery34.log/results and per-case logs |
| Original unchanged recorded native48 input | FAIL at exact query-disposition predicate,14.6s; actual returned object not logged | native48.log; original input retained |
| Instrumented same48 predicates, first followup |48/48 PASS, no runtime/assertion change | native-replay-investigation/ |
| Instrumented same48 predicates, second followup |48/48 PASS, no runtime/assertion change | native-replay-investigation/ |
| Existing full local validator |409/409 PASS,1314.53s; one initial pooled PermissionError passed built-in sequential retry | full-validation.log, validation.jsonl, full-validator-investigation/ |

Recovery34 scope: the count reports the recorded exit expectations and the manual script's assertions; it is not a claim of complete terminal-receipt contract coverage. `two-phase-later-retry` intentionally records expected exit7, dispatch and `result: null`. Its shell invocation has no progress flags or `--result-file`; it removes the earlier p1 root receipt before traversal. `MACHINE-CONTRACTS.md` says the writer is armed by `--result-file`, `marathon_drive.py` does nothing when unarmed, and `marathon.sh` adds result flags only for opted-in progress. No p2 `marathon-drive/result@1` receipt is retained, so this observation does not qualify p2 receipt fields or attempt count. The raw null is preserved; no receipt is fabricated. See `recovery34-receipt-scope.json` for the exact invocation and source references.

The runner's aggregate process exits1 because it retains the original nativeFAIL. Passing diagnostics do not establish that initial event's cause. No unsafe admission or real-checkout loss was observed, but the original actual disposition is unknown. Existing source has earlier legitimate preservation returns; this is a possible explanation, not observed attribution. Stop broad reruns after two instrumented confirmations. Logged input now captures every actual inspection result without changing predicates for a future recurrence. The finding remains unchecked in GH1063.

The full-suite pooled failure occurred in unchanged process-group fixture/adapters. Its exact PermissionError and passing retry are both retained. Framework “contended” is a classification by alone verdict, not a root-cause claim.

These are local parallel/full and manual fixture results, not hosted sequential destination qualification, stable-main proof or live retirement. Native metadata/API is stubbed; fixture Git/Trash/native operations are real isolated operations. Recovery uses stubbed agents/receipts. Only synthetic task-owned fixtures were removed. Hosted wave38677715889 qualification remains independently required. No deployment, installation or live Marathon/Jog activation.

OriginalPR1061 final3/3FAIL and operator-authorized extension2/2 PASS/counters remain in history; this report does not open another native formal review or reset its cap. The separate evidence-report review grades truthful attribution/limits, not a fresh native runtime approval.
