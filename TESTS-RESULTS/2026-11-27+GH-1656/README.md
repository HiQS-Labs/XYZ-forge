# GH-1656 — verification receipts

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1656 · plan: `PROJECT/2-WORKING/GH-1656-NON-LEDGER-CONFLICT.md`

| File | What it shows |
|---|---|
| `red-base.log` | `TestGh1656NonLedgerConflict` (13 cases) on base `52813e56f` + the new tests only: 11 failures / 4 errors. The clean CONFLICTING case reaches the stub's GitHub-style refusal `is not mergeable: the merge commit cannot be cleanly created` (the #1651 symptom). The dry run prints `Would merge PR #1`. The dirty case lacks the non-ledger message. The UNKNOWN control passes. (Three of the four errors were a subtest fixture-name collision that was fixed later; the corrected cases also fail on base by construction, because they need the rung.) |
| `green-focused.log` | The same class on the candidate: 13/13 OK. |
| `focused-suites.log` | All merge-cleanup suites in a disposable verify clone at `c620786b7`, plus the mutation control for the `merged_head` hand-off. |
| `smoke.py` / `smoke.log` | Manual check (GH-1088, no suite). It drives the real `merge_cleanup.py` CLI as a subprocess against a bare origin, with the phase-B gh stub and a minimal real `githooks/install.sh`. **Main path:** a GitHub-CONFLICTING but locally clean PR. The dry run previews the local-merge rung, not "Would merge". `--execute --strategy merge` lands it as a merge commit with parents (gated base, pin), with no `gh pr merge` call. The pre-push hook ran with `XYZ_SKIP_PREPUSH` stripped (the caller had set it to 1). **Adjacent path:** the dry run re-run on the landed state makes no second landing, and origin is unchanged. Verdict: PASS. |

| `real-hook-probe.sh` + `real-hook-detached.log` / `real-hook-branch.log` | Final QA r1 clone probe against Forge's **real** `githooks/install.sh` pre-push stub (attempt admission + gate). **Detached** (the r1 publication shape): `gate-attempt: REFUSED — task qualification has no attempt reservation`, origin unchanged (red). **Branch** (the fix: local `development` at the candidate, push `refs/heads/development`): admitted as an administrative publication, `pre-push: full gate GREEN in 1438s — pushing.`, and origin lands on the exact candidate. |

The smoke at `c901c5f9f` also checks that the published tree equals the gated merge tree, that the hook ran once with the override stripped, and that origin is the same before and after the adjacent re-run.

Provenance: `provenance.jsonl`.
