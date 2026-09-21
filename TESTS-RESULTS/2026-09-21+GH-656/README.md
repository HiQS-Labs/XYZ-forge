# GH-656 / GH-657 evidence — closeout evidence guards (re-delivery 2026-09-21)

Source: `fix/gh656-657-closeout-evidence` at the SHA in `provenance.jsonl`. The four file diffs
were ported from the never-pushed 2026-09-16 branch `fix/closeout-evidence-guards` (clone
`XYZ-forge-closeout-evidence-fixes`, zipped under `~/Documents/Backups/XYZ-forge-clones-2026-09-21/`)
and applied with `git apply --3way` onto `development@39bb1392` — all four applied cleanly.
Every run below was executed in a **disposable full clone** under the session scratchpad, never in
the task clone (AGENTS.md). No operator source, ledger, workflow run or deployed skill was touched.

## Red controls (source unpatched, test patches applied)

- `red-gh496-phase2-reconciliation-views.log` — exit 1, one FAIL: `GH-657 committed receipt
  outcomes` — the unfixed guard accepts contradictory / malformed outcomes (fail-open mutant).
- `red-gh280-jog-marathon-adapter.log` — exit 1, one FAIL: `L5 rc=6` — the real reconciler refuses
  to ship the owned dialed-in member because Jog's offline manifest carries no `mergeCommit`
  (omission mutant).

## Positive (all four patches)

- `green-gh496-phase2-reconciliation-views.log` — exit 0; 8 positive / 21 negative committed
  outcome shapes through `wave.validate_pre_merge_receipts`.
- `green-gh280-jog-marathon-adapter.log` — exit 0, 223 pass / 0 fail; L5 ships with evidence equal
  to the verified full merge SHA, L6/L7 replays duplicate nothing.
- `neighbour-gh425-gate-provenance-pr.log`, `neighbour-wave-reconcile.log` — exit 0; the
  post-merge attribution guard (`check_provenance_receipts`) is untouched and stays green.

The pre-push gate on the task clone is the full-suite receipt (see the PR).

## Independent review (`consult/`)

- `gh656-code-review.codex.md` — Codex (gpt-6-astra, read-only sandbox): **correct & minimal**; the
  predicate matched the contract across 4,096 outcome combinations it executed via AST; no
  legitimate producer (`express.py:285`, qualification receipts `wave_reconcile.py:612`, existing
  fixtures) emits a shape the guard now refuses; `check_provenance_receipts` untouched. One nit —
  pin `{"result":"pass","rc":null}` / `{"result":"pass","rc":""}` — adopted (matrix now 8/23).
- `agy-lane-failed-idle-timeout.md` — the agy lane failed twice (first: launched a suite and its
  turn ended; second, static-only prompt: killed at the idle threshold with an established backend
  connection). **The review is single-advisor**; stated, not hidden.
