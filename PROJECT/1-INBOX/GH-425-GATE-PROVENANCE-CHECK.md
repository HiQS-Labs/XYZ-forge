---
title: --gate's provenance check never compares the PR number — it proves TESTS-RESULTS/ is non-empty
status: Proposed (1-INBOX — not yet active)
created: 2026-09-04
owner: noelsaw1
gh_issue: 425
source: https://github.com/HiQS-Labs/XYZ-forge/issues/425
doc_type: bug
complexity: 1
risk: 3
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Automating the reconciler — GH-421, which this gates.
  - Redesigning provenance receipts. Either match the PR, or remove the flag.
related:
  - GH-421 (Phase 2 may not pass --gate until this lands)
  - GH-406 (the external review that catalogued this defect class)
  - GH-414 (nothing deterministic checks whether a claim in a comment is still true)
goal: >
  Make --gate verify what its message claims — that a provenance receipt exists for THIS PR — or
  remove the flag. A gate that cannot fail is worse than no gate, because it gets cited as evidence.
---

# GH-425: a gate that cannot fail

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## The defect

`check_provenance_receipts` (`wave_reconcile.py:281-298`) reads `pr_num` on its first line, walks
`TESTS-RESULTS/`, sets `found = True` on the **first** file named `provenance.jsonl` or
`error_log.jsonl` **anywhere** in the tree, never compares `pr_num` to anything, and then
interpolates it into the success message:

```
Provenance receipts verified for PR #{pr_num} (GH-430 compliant)
```

It proves a directory is non-empty and reports that as receipts verified for a specific PR. This
repo has such files committed, so **the gate currently cannot fail.** There is no test coverage and
no red control anywhere proving it can reject.

## Why it matters beyond itself

This is the shape GH-406 catalogued from Russ K.'s external review — *a doc states a guarantee, the
mechanism covers a narrower path, and nothing compares the two* — five of eight findings were this
pattern. Here it sits inside the flag whose entire purpose is to be the safety catch. Per AGENTS.md
§13, a check that cannot fail is not evidence.

**Severity, stated precisely:** `--gate` does not gate *merging*. By the time the reconciler runs the
PR is already merged; the flag gates marathon closeout and reconciliation. The exposure is a false
provenance record, not unproven code reaching `development`. It was described as the former in
review; correcting it here so the fix is not over-scoped.

## Scope

Match the claim to the check, cheapest first:

1. match a receipt whose path or contents names the PR number or its merge SHA, or
2. read `provenance.jsonl` and require an entry whose recorded PR/commit matches `pr_meta`.

The success line prints only what actually matched. **If per-PR receipts do not exist in a usable
form, remove the flag** rather than keep a vacuous one.

Also correct the in-code `(GH-430)` citation — an **upstream** number with no counterpart here (see
ROUTER.md's two-repo numbering rule).

## Proof — §13

**Red first, and it is the whole point:** a merged PR with **no** receipt of its own, in a tree
containing someone else's receipt, must be refused. The pre-fix transcript showing it accepted is
the artifact this issue exists to produce; it goes in `test/baselines/`.

**Greens:**

- a PR whose receipt is present passes, and the success line names what matched
- `TESTS-RESULTS/` missing entirely still fails with the existing exit 6 — unchanged
- the reconciler without `--gate` is unaffected

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "test", "pattern": "gh425-gate-provenance" } ],
  "artifacts":   [
    "utils/py/wave_reconcile.py",
    "test/gh425-gate-provenance.sh",
    "test/baselines/GH-425-negative-control.md"
  ],
  "remediation": { "source": "issue#425", "criteria": "--gate refuses a merged PR that has no receipt of its own even when other receipts exist in TESTS-RESULTS/; the success line names the receipt that matched; a missing TESTS-RESULTS/ still exits 6; a run without --gate is unaffected — or the flag is removed outright and its documentation with it" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
