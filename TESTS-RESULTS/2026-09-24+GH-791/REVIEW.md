# Code Review Report — GH-791 merge sequence

Verdict: **Changes requested on the original batch; repair verified and approved for review.**
Target: `a2312944..337813e0` (five listed PRs plus preceding #761/#783).
Review mode: direct source recon, baseline differential probes, negative controls, and disposable-clone validation.
The runtime/skill diff under review was +1,327 / -136 lines across 19 files, excluding tests and receipts.

| Category | Count | Status |
|---|---:|---|
| Blocker | 4 | Repaired; full macOS gate 419/419 |
| Should | 1 | Unrelated parallel-test failure filed as GH-793 and held |
| Nit | 0 | No polish scope added |

## Findings and attribution

1. **P1: unrelated workflow success skips reconciliation.** #753 broadened hosted lookup but
   adopted active runs with foreign SHAs. A run for another PR could return success for this landing;
   an adopted run could also override a newly visible exact match. Before repair: all four new
   identity assertions fail. After repair: matching PR/merge SHAs take precedence; only a verified
   SHA attests success. Unknown activity may delay the writer, never attest it.
   Site: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:459` and `:486`.
2. **P2: duplicate UNKNOWN polling.** #787 and #753 independently added the same behavior.
   Combined `land_prs` slept twelve times instead of six. The negative control sees twelve sleeps
   and thirteen refreshes, then fails the six-sleep assertion. The repair retains `_await_mergeable`
   at `merge_cleanup.py:858` and removes the duplicate helper, constants, and exclusion pass.
   Bare numbers and `#N` exclusions remain accepted.
3. **P1: inventory gate rejects the landed connector.** #783 froze the inventory before #723
   added `github_labels.py`. The baseline is reconciled with that one already-landed module at
   `utils/pdda/inventory_ratchet_baseline.json:106`. Normal growth rejection remains intact.
4. **P2: new hosted-lookup test cannot import in a fresh clone.** #753's test used the local-only
   `skills/merge-cleanup` alias. It now imports the tracked canonical package via
   `test/gh674-merge-cleanup-hosted-lookup.sh:5`. The fresh-clone failure is retained separately
   from the behavioral negative controls, which used an explicit source path.

## Recon map and blast radius

Cleanup CLI -> one bounded live mergeability refresh -> landing simulation/gate -> merge ->
post-merge reconciliation -> hosted workflow identity check or guarded local writer.
No real PR merge, branch deletion, or teardown was invoked by the repair tests.
The local reconciliation concurrency guard remains unchanged. No schema or event-shape changes.

Independent read-only reviews inspected cleanup/GID remint, roadmap state and label projection,
express, reconciliation rollback, vendor, HQ, bridge readiness, and governance additions.
No additional concrete regression was confirmed in those reviewed paths. The baseline run also
passed the status-label and RSS-watchdog suites before it was stopped.

Graph mode: Verify attempted against project `XYZ-forge`, generation `2026-09-01T15:54:30Z`.
Coverage was stale or untracked for affected paths, so all material findings use current source;
this is not an exhaustive graph-based completeness claim.

## Verification and retained evidence

- `hosted-red.log`: four identity failures against batch code.
- `poll-red.log`: six-poll assertion fails against batch code (twelve sleeps).
- `inventory-red.log`: landed connector rejected by the batch baseline.
- `fresh-clone-import-red.log`: original test import fails without the local alias.
- `hosted-green.log`: six tests pass, including delayed identity, foreign/missing rejection,
  matching priority, timeout protection, and no forced local fallback.
- `poll-green.log`: six existing unit/integration tests pass, covering bounded UNKNOWN and settling.
- `inventory-green.log`: live baseline and rogue-script/database negative controls pass.
- `frozen-guard.log`: 38 pass / 0 fail.
- `validate-batch.log`: **incomplete**, intentionally terminated after confirmed failures (exit 143).
  Its passing worker lines are observations, not a whole-gate success claim.
- `cleanup-green.log`: 180 merge-cleanup integration tests pass.
- `push-gate.log`: full macOS pre-push gate **419/419**, exit 0, 1,262 seconds, at
  `14640c757a9c24e99c32e06e3ca413644d058e00`; no bypass, no failed worker.
  Post-run HEAD, origin, core.bare, local identity, and clean working tree match expectations.
- `docs-green.log`: six targeted PDDA checks pass; ledger check has zero failures.
- The follow-up commit changes only documentation and receipts; runtime/test sources remain
  identical to the full-gated revision. This is local verification, not release-promotion evidence.

Every retained run has an entry in `provenance.jsonl` with source revision, command, exit status,
artifact path, and SHA-256. These receipts are committed with the repair.

## Unrelated finding — held

GH-793 records the unchanged idle-kill suite's parallel failure (14 pass / 2 fail) and passing
isolated run. The suite and diagnostics implementation are identical before/after the batch.
Root cause is unverified; no idle/runtime repair is included here.

## Limits

Hosted eventual consistency is simulated with controlled responses, not a live merge. This review
covers the named batch and touched paths; it does not certify every runtime path or external
connector configuration. No production issue-label projection was invoked for test purposes.
