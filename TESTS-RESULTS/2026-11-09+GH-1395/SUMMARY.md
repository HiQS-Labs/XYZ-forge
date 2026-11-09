# GH-1395 reconciliation REST reduction

Source baseline: `e0037c82658f27ce8fdcdd3d09af3c53049b54fe`.

## Measured evidence and limits

Retained real workflow logs contain five ledger-gate outcomes: three green and two HTTP-403
refusals across initial readiness, resumed readiness and the current landing. Their sanitized
stage extraction is `retained-workflow-stages.json`, with original artifact hashes. These establish
repeated real gate execution; they do **not** enumerate internal HTTP requests or quota units.
The current invocation hash and stage facts are in `workflow-observation.json`.
The owner supplied the terminal result, retained as `completed-workflow.json`: the workflow
completed successfully in 541.347 seconds. This includes local planner/reconciliation work and
is not an API latency measurement; nested HTTP counts remain unknown.

A separate read-only readiness observation was interrupted once the owner supplied the active
workflow logs, to avoid duplicate reads. It completed 27 native CLI calls and 27 closure CLI calls;
`interrupted-cli-observation.jsonl` retains duration, endpoint and exit. No HTTP headers were
captured, no complete sweep is claimed, and no principal-client attribution follows.

`manual-counts.py` executes the actual AST-extracted reconciliation functions against an in-memory
ledger and stubbed CLI, without network or disk writes. Paired baseline/candidate outputs record:
90 dense rows: 90 -> 3 native CLI calls; 220 rows: 220 -> 22; 90 sparse rows: 90 -> 91.
Closure observation counts are unchanged. These are fixture results, **not live REST savings**.
Run with a source path argument. The same assertions distinguish baseline from candidate by the
presence of the inventory function. Baseline output is retained, not inferred from source.

## Decision and blast radius

Root cause: each required sweep independently reads each candidate through a singleton REST call.
Fix site: the reconciliation command's native observation acquisition. Upstream cross-stage reuse
would replace required fresh remote observations; downstream closure-call removal would not reduce
these REST reads and would remove two-observation disagreement detection.

At least ten rows per repository enables up to two pages of open issues, sorted by creation.
Valid misses use the existing singleton reader, including closed issues and entries beyond the cap.
This is a bounded partial inventory, never evidence of absence: no Link traversal or complete-list
claim is required. An exactly full page can cause one extra page request; two is the hard cap.
A sparse repository can spend up to two additional native calls. The density threshold is a modest
heuristic, not an empirically universal optimum. The later authorized required candidate gate measured page hits as described below; historical wire savings remain unmeasured.

The native observation can precede the closure observation by longer. Disagreement still refuses;
there is no re-read that overrides disagreement, no persistence, and no reuse across commands.
Errors, malformed pages, duplicate numbers, wrong repositories and requested PRs refuse before
writes. Existing row identity, local transaction/recheck and event emission remain intact.
The shared validator is extracted without changing singleton behavior.

Reversibility: Easy for the isolated code patch; restore the prior function via a reviewed revert.
No remote state or schema migration is introduced. Consumers are reconcile-state and its merge
readiness caller; singleton readers retain the same validator contract.

## Plan consult reconciliation

Two independent advisors inspected current source (native Codex and Antigravity Gemini).
Both supported preserving independent observations and warned about sparse inventory and skew.
The native advisor found no demonstrated reusable sweep in the current caller path. The other
advisor proposed cross-stage reuse and claimed wave reconciliation/issue-doc-sync called the
reconciliation command; direct source search disproved those caller claims. Source accuracy wins:
no cross-stage cache. Its suggested error fallback and mismatch re-probe are also rejected because
they weaken fail-closed behavior. Existing fixtures are not a reason to fallback after API errors.
Bounded valid misses may use the existing singleton path, without treating absence as open.

Independent final QA approved the full-gate step (receipt in relay-system/2026-11-09/gh1395-final.codex.md). GH492 passed; native-label coverage passed 42 tests; GH436 passed 227 tests in a separate full clone. Full `validate.sh` passed 408/408 in 623.056 seconds on `273700069754f22d1ddebf274f33fd775207d58d`; normal pre-push reused that exact-SHA receipt without bypass. This is not ci-local promotion qualification. Clone identity was verified after the gate. Subsequent commits contain evidence/docs only; runtime SHA256 remains the reviewed value. Parent outer review and hosted checks remain separate; no production performance claim.

## Actual optimized workflow after conflict repair

Development advanced during the first qualification. The supported ledger resolver classified the
conflict as disjoint, kept development's ledger and replayed only GH-1395 through the writer.
Its merge commit is `58658c66074d914510fc1148ab92bb3067b7c1d4`; the reviewed reconciliation file
is byte-identical. Integration also brings the independently landed upstream runtime changes;
the prior exact-SHA full-gate receipt does not qualify this new whole head.

One required `pre_merge_ledger_gate` after that repair ran against the candidate in a disposable
full clone, after checking no peer live sweep was running. It passed in **67.517 seconds**:
**35 native CLI invocations = 2 inventory pages + 33 singleton misses**, and **92 closure CLI
invocations**. Pages had 100 entries each and matched 32 + 27 = **59 candidate issues**. All calls
exited zero. Existing warnings and four proposed terminal moves remained diagnostics only.
No writes were applied. Sanitized endpoints, durations and page-hit counts are retained in
`candidate-cli.jsonl`; `candidate-readiness.json` binds the stage and candidate SHA.

The singleton baseline source would read each of these 92 valid candidates once: 92 native calls.
The difference of 57 is a **source-based counterfactual**, not a measured historical wire delta.
Actual HTTP request totals/resource headers were not observed. No principal client attribution
is established. The earlier incomplete 27+27 observation is not substituted for a baseline sweep.
The required actual optimized workflow/page-hit observation is now complete; exact historical
HTTP savings remain unknowable from the retained baseline logs.
