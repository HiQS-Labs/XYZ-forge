---
title: Make wave reconciliation automatic post-merge — after fixing the ledger write it no-ops on
status: Proposed (1-INBOX — not yet active)
created: 2026-09-04
owner: noelsaw1
gh_issue: 421
source: https://github.com/HiQS-Labs/XYZ-forge/issues/421
doc_type: feature
complexity: 3
risk: 3
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - Any new script or module. utils/py/wave_reconcile.py exists and is already shaped for unattended use; this wires and corrects it.
  - Retiring ROADMAP.md or mode-gating the reconciler's markdown writes — GH-269.
  - Teaching the marathon planner to read the DB — GH-418, blocked on GH-423.
  - Reconciling any branch other than development.
  - A bot that opens PRs. The reconciled artifacts commit directly to development or the feature is not automatic.
related:
  - GH-165 (the reconciler itself — CLOSED, shipped operator-invoked)
  - GH-269 (retire ROADMAP.md — Phase 1 here is its writer half)
  - GH-418 (planner still reads the frozen file — the reader half)
  - GH-423 (roadmap render — GH-418's blocking dependency)
goal: >
  Fire utils/py/wave_reconcile.py automatically when a PR merges into development, but only after
  replacing its single ledger call — a `releases roadmap sync` that is a deliberate no-op in this
  repo — with the real DB writes it already computes. Ordering is the point: automating it first
  would write a confident, wrong record at machine speed and exit 0.
---

# GH-421: automate the reconciler, after making it write the ledger it claims to

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## The shape of this

Three phases that must land in order. Phase 2 without Phase 1 is actively worse than the status
quo, which is the whole reason this is one issue and not two.

## Phase 1 — the reconciler must write the DB

`wave_reconcile.py`'s **only** ledger call is `releases roadmap sync` at
`utils/py/wave_reconcile.py:715`. It never calls `manifest ship`, `roadmap repoint`, or any other
DB write. In a releases-mode repo that call returns immediately, and
`utils/py/releases_app.py:3374-3383` names this caller in its own comment:

> *"Skip cleanly (exit 0): wave_reconcile.py calls sync unconditionally post-merge and must stay
> green in both modes."*

The skip is correct — `sync` deletes rows absent from the markdown, which would destroy parked
intake. Nothing replaced what it used to carry. Meanwhile `wave_reconcile.py:459-560` still writes
the shipping badge and Completed-section move into `ROADMAP.md`, the file `.pdda-mode` froze.

So today a post-merge reconcile on this repo records shipping into legacy markdown, no-ops on the
source of truth, and exits 0. **That is §13's anti-pattern with a scheduler attached.**

The fix, using verbs that already exist:

| transition the reconciler already computes | DB write it must now make |
|---|---|
| a dialed-in manifest item whose PR merged | `manifest ship --gid <release> --evidence <merge sha / PR>` |
| an active doc moved `2-WORKING` → `3-COMPLETED` | `roadmap repoint --issue-num N --doc-path <new path>` |

Evidence is mandatory — `manifest ship` refuses an empty `--evidence`, which is the correct posture
and must not be worked around with a placeholder string. The evidence is the merge commit.

The `ROADMAP.md` writes stay untouched in this phase. Legacy-mode repos still depend on them, and
mode-gating that half belongs to GH-269.

## Phase 2 — the trigger

```yaml
on:
  pull_request:
    types: [closed]
```

guarded on `github.event.pull_request.merged == true` and `base.ref == 'development'`, invoking
`wave_reconcile.py --pr ${{ github.event.pull_request.number }} --gate`.

`pull_request: closed` is chosen over `push` deliberately: it does not fire on a plain push, so the
reconciler committing its own artifacts cannot retrigger it. That is a property of the trigger
shape, not a suppression hack — but it is pinned by a test rather than assumed, because "the
trigger cannot loop" is exactly the kind of claim that is true until someone adds a second `on:`.

## Phase 3 — the artifacts land

Moved docs, `releases.db`/`releases.sql`, and the regenerated dashboards have to reach
`development`. `contents: write` scoped to this job only, never workflow-wide — `ci.yml` is
`contents: read` today and must stay that way.

## Determinism requirements — these are acceptance criteria, not notes

1. **Idempotent.** Two runs over the same PR: the second writes nothing and the tree is
   byte-identical. Pinned by a test that runs it twice and diffs.
2. **Serialized.** `concurrency: {group: wave-reconcile, cancel-in-progress: false}` — queue, never
   cancel. A cancelled reconcile leaves a half-written ledger, so `cancel-in-progress: true` (the
   repo's default habit at `ci.yml:109`) is wrong here and the difference must be commented.
   The existing `fcntl` lock guards one host; it does not guard two runners.
3. **No trigger loop**, per Phase 2, pinned.
4. **Fails loudly, never partially.** The tool has DB rollback protection at
   `wave_reconcile.py:671`; the workflow must not swallow a non-zero exit.
5. **`--dry-run` on the open PR, apply on merge.** `--dry-run` already asserts zero mutations, so
   the PR gets a preview of what merging will reconcile — and the preview is itself a red control:
   if the dry run predicts nothing and the apply writes something, they disagree and the run fails.
6. **Least privilege**, per Phase 3.

## Proof — §13: a green gate with no witnessed red is not evidence

**Reds, recorded as transcripts in `test/baselines/`, observed failing before the fix:**

- a merged PR whose manifest item is `dialed_in` is left `dialed_in` — reproduce with **#420**,
  which merged 2026-09-03 and stayed `dialed_in` until marked by hand hours later
- a merged PR whose doc is in `2-WORKING` behind a CLOSED issue is left there — reproduce with
  **#409**, same day, where `pdda-check-issue-doc-sync` raised the warning and a human ran `git mv`
- a reconcile against a releases-mode repo exits 0 having written only `ROADMAP.md`

Those two PRs are the measurement, not an analogy: both are on `development` and both can be
replayed.

**Greens — these matter more than usual, because an over-eager reconciler is worse than none:**

- a PR closing no issue reconciles to "nothing to reconcile" and exits 0
- an issue still OPEN behind a merged PR is **not** promoted — the tool guards this at
  `wave_reconcile.py:925` and the automation must not bypass it
- a legacy-mode repo still gets its `ROADMAP.md` transitions unchanged
- a reconcile that fails mid-write leaves `releases check` clean

## Open question for review

`--gate` (provenance receipts) is already implemented. Should Phase 2 pass it unconditionally?
Passing it makes every merge require receipts, which is stricter than today's operator-invoked
default and may refuse merges that are legitimately receipt-less. Not resolved here.

Note its in-code citation `(GH-430)` is an **upstream** number — there is no #430 in this repo. See
ROUTER.md's two-repo numbering rule and `docs/ROADMAP-UPSTREAM-ARCHIVE.md`.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/wave_reconcile.py", "pattern": "manifest\", \"ship" } ],
  "artifacts":   [
    "utils/py/wave_reconcile.py",
    ".github/workflows/wave-reconcile.yml",
    "test/gh421-auto-wave-reconcile.sh",
    "test/baselines/GH-421-negative-control.md"
  ],
  "remediation": { "source": "issue#421", "criteria": "a PR merged into development reconciles without operator action: the manifest item is shipped with the merge sha as evidence, the active doc moves and its roadmap row is repointed, the dashboards regenerate, and the artifacts land on development; a second run over the same PR writes nothing; an OPEN issue behind a merged PR is not promoted; a failed reconcile leaves releases check clean" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
