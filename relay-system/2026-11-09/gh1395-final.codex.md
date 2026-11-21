# GH-1395 independent final QA

Verdict: Approved for the requested full-gate step. No blocking code findings. This is not full-gate qualification or proof of live REST savings.

Reviewed working-source SHA256 for `utils/py/releases_app.py`:
`a5f3dacd2d910b343fdf6e3d25a6aeffa516287f89efcf0114f7b3d77e1b383d`.
Baseline commit: `e0037c82658f27ce8fdcdd3d09af3c53049b54fe`.
Independent reviewer: native Codex QA agent; no network, production writes, or mutation-heavy suites run.

Evidence inspected: runtime diff, actual identity resolver and reconciliation transaction, manual-counts.py, before/after evidence and SUMMARY.md. Independently executed `python3 TESTS-RESULTS/2026-11-09+GH-1395/manual-counts.py utils/py/releases_app.py`; exit 0.

## Preserved controls

- `utils/py/releases_app.py:4297–4325`: inventory is command-local and per owned repository. Existing row identity skip remains; hits use the same extracted native validator, misses use the existing native singleton read.
- `:5704–5711`: shared validator extraction is predicate-identical to the baseline. Requested PRs, wrong issue URLs/numbers, invalid state and missing label lists still refuse.
- `:5721–5742`: no more than two page requests. Short-page stop and absent Link handling do not assert inventory completeness: every requested miss is independently read. Missing entries, entries beyond the cap, and moving pagination boundaries cannot silently turn a closed issue into an assumed open issue. Duplicate numbers and malformed/wrong-repository entries refuse.
- `:4330–4347`: independent closure observations and both state-mismatch refusals remain unchanged. No mismatch re-probe weakens refusal. The wider observation interval is explicitly documented.
- `:4362–4383`: write phase remains after all remote reads. Transactional full-row concurrency comparison and batch event ownership are unchanged. Early inventory errors cannot reach writes.

Manual evidence covers dense 90/220 rows, sparse misses, 9/10-row threshold, exact 100/200 inventory-entry boundaries, malformed/duplicate/missing-number/wrong-repository/requested-PR payloads, both state-change directions, unknown closure reason and first/second-page errors. The second-page error stops before closure calls. Existing GH492 controls remain necessary for apply/rollback behavior; this manual probe is dry-run-only.

## Limits and small optional correction

- Live page-hit rate and actual REST savings remain unmeasured. The retained real logs establish repeated gates, not internal HTTP totals. Fixture results must remain labeled as such.
- Sparse sweeps may spend two extra calls; the recorded sparse example spends one. The threshold is heuristic. These are disclosed tradeoffs, not hidden regressions.
- The manual script's opening docstring still says “three unmodified” functions, while it now supports baseline three and candidate five. Correct that wording before publication; it does not affect the checks.
- The full gate and final committed-state/provenance binding remain the implementation parent's responsibility.
