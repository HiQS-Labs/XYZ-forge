# GH-1395 reconciliation REST reduction

Source baseline: `e0037c82658f27ce8fdcdd3d09af3c53049b54fe`.

## Measured evidence and limits

Retained real workflow logs contain five ledger-gate outcomes: three green and two HTTP-403
refusals across initial readiness, resumed readiness and the current landing. Their sanitized
stage extraction is `retained-workflow-stages.json`, with original artifact hashes. These establish
repeated real gate execution; they do **not** enumerate internal HTTP requests or quota units.
The current invocation hash and stage facts are in `workflow-observation.json`.

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
heuristic, not an empirically universal optimum. Live page-hit/savings measurement remains missing
because the owner prohibited additional live queries while the authorized workflow runs.

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

Independent final QA approved the full-gate step (receipt in relay-system/2026-11-09/gh1395-final.codex.md). GH492 passed; native-label coverage passed 42 tests; GH436 passed 227 tests in a separate full clone. Full gate remains pending; no production performance claim or merge readiness yet.
