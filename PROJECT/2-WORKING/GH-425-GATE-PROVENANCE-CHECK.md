---
gh_issue: 425
source: https://github.com/HiQS-Labs/XYZ-forge/issues/425
title: "GH-425: the --gate provenance check never compares the PR number"
status: 2-WORKING
created: 2026-09-04
updated: 2026-09-08
owner: unassigned
goal: "--gate verifies receipts by PR number, not just directory non-emptiness"
doc_type: bugfix
complexity: 1
risk: 3
effort: 2
phases: 1
marathon: gh-490
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/490 — marathon umbrella"
---


## Status

| What was just completed | What's next |
| --- | --- |
| Promoted from 1-INBOX with a swarm-preflight contract; lane of marathon gh-490 | Implement per the contract; lane brief in PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md |

# GH-425: a gate that cannot fail


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
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/wave_reconcile.py",
      "pattern": "os.walk\\(results_dir\\)",
      "note": "bug evidence \u2014 must fire unfixed at pre-work time"
    },
    {
      "type": "path_absent",
      "path": "test/gh425-gate-provenance-pr.sh",
      "note": "new lane artifact \u2014 must not exist yet"
    },
    {
      "type": "path_absent",
      "path": "test/baselines/GH-425-negative-control.md",
      "note": "new lane artifact \u2014 must not exist yet"
    }
  ],
  "artifacts": [
    "utils/py/wave_reconcile.py",
    "test/gh425-gate-provenance-pr.sh",
    "test/baselines/GH-425-negative-control.md"
  ],
  "remediation": {
    "source": "issue#425",
    "criteria": "--gate fails a PR whose TESTS-RESULTS receipts belong to a different PR number; pinned red-first"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/",
      "utils/timeline/",
      "test/"
    ],
    "orchestrator_only": []
  },
  "artifacts_new": [
    "test/baselines/GH-425-negative-control.md",
    "test/gh425-gate-provenance-pr.sh"
  ]
}
```

## Acceptance

- `--gate` fails when a merged PR's receipts carry a different PR number than the one being closed out.
- `--gate` passes when receipts match the PR number.
- Pinned red-first in a new suite.

## Merge evidence

- PR #495 merged 2026-09-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
