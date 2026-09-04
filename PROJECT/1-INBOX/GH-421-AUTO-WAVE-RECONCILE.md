---
title: Make wave reconciliation automatic post-merge — after giving it a lifecycle write it does not have
status: Proposed (1-INBOX — not yet active)
created: 2026-09-04
updated: 2026-09-04
owner: noelsaw1
gh_issue: 421
source: https://github.com/HiQS-Labs/XYZ-forge/issues/421
doc_type: feature
complexity: 3
risk: 4
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - A new runtime script or module. utils/py/wave_reconcile.py exists and is already shaped for unattended use; this wires and corrects it. (A privileged workflow IS a new subsystem — see Phase 2 — and is counted as one.)
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
  Fire utils/py/wave_reconcile.py automatically when a PR merges into development — but only after
  giving it a supported atomic lifecycle write, which the ledger CLI does not currently expose.
  Ordering is the point: automating it first would write a confident wrong record at machine speed
  and exit 0.
---

# GH-421: automate the reconciler, after giving it a lifecycle write it does not have

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

Three phases that must land in order. Phase 2 without Phase 1 is actively worse than the status
quo, which is why this is one issue and not two.

## Phase 1 — the reconciler must write the DB, and one verb to do it with does not exist

`wave_reconcile.py` makes exactly two ledger CLI calls: `releases roadmap sync` and `releases check`
(`utils/py/wave_reconcile.py:714-727`). `check` is read-only, so **`sync` is the tool's only ledger
*write attempt*** — and in a releases-mode repo it returns success without writing.
`utils/py/releases_app.py:3374-3385` names this caller in its own comment:

> *"Skip cleanly (exit 0): wave_reconcile.py calls sync unconditionally post-merge and must stay
> green in both modes."*

The skip is correct — `sync` deletes rows absent from the markdown, which would destroy parked
intake. Nothing replaced what it used to carry. Meanwhile `wave_reconcile.py:926-957` still writes
the shipping badge and Completed-section move into `ROADMAP.md`, the file `.pdda-mode` froze.

So today a post-merge reconcile moves the doc, mutates legacy markdown, leaves the canonical DB
untouched, and exits 0. **That is §13's anti-pattern with a scheduler attached.**

### The write set — and the gap that makes this more than plumbing

| transition | verb | status |
|---|---|---|
| dialed-in manifest item whose PR merged | `manifest ship --gid <release> <issue> --evidence <merge-sha>` | exists (`releases_app.py:2248-2267`) — note the **positional `<issue>`**; an earlier draft of this plan omitted it |
| doc moved `2-WORKING` → `3-COMPLETED` | `roadmap repoint --issue-num N --doc-path <new>` | exists, but writes **only** `doc_path` and `raw_text` (`releases_app.py:3277-3289`) |
| row's section → Completed | `roadmap update --section` | exists (`releases_app.py:3322-3368`) |
| **row's `status_marker` → ✅** | — | **NO CLI VERB EXISTS** |

That last row is the finding that changes this plan's shape. In releases-mode the old `sync` was the
only thing that set `status_marker` (it updated every roadmap field from the legacy transition,
`releases_app.py:3475-3534`), and `roadmap update` exposes `--raw-text` and `--section` but **not**
`--status-marker` (`releases_app.py:4984-4989`). So a completed row keeps its `🆕` marker forever.

**An earlier draft of this plan claimed Phase 1 uses "verbs that already exist." That was false.**
Phase 1 must first add a supported atomic lifecycle write — either extend `roadmap update` to derive
and set the marker from the new raw text, or add a purpose-built verb — plus a policy for
section, raw-text, and position on completion. That is real scope this plan did not count.

Evidence on `manifest ship` is mandatory; the CLI refuses an empty `--evidence`, which is correct
and must not be worked around with a placeholder.

### Manifest lookup is also missing

The reconciler derives only closing issue numbers (`wave_reconcile.py:897-906`). It has no
manifest-member or release-GID lookup, and `--marathon` is parsed but otherwise unused
(`:796-798`, `:873-999`). Phase 1 must specify that lookup **and** the behavior when a merged PR's
issue belongs to no manifest — which is the common case, so "skip quietly" is probably right and
must be stated rather than left to fall out of a `KeyError`.

### Rollback must move earlier

The journal snapshots `releases.db` and `releases.sql` only inside `run_subprocesses`
(`wave_reconcile.py:670-710`, `:987-993`) — **after** the per-issue DB writes proposed above would
run. Snapshot before the first new mutation, or wrap the whole lifecycle in one transaction.
`releases check` returning clean is not sufficient acceptance: a partial write can be internally
consistent and still wrong. Acceptance is byte-for-byte restoration under failure injected
*between* the manifest write and the roadmap write.

The `ROADMAP.md` writes stay untouched in this phase. Legacy-mode repos still depend on them, and
mode-gating that half belongs to GH-269.

## Phase 2 — the trigger

```yaml
on:
  pull_request:
    types: [closed]
concurrency:
  group: wave-reconcile
  cancel-in-progress: false
  queue: max
```

guarded on `merged == true` and `base.ref == 'development'`, invoking
`wave_reconcile.py --pr <number>`.

**`queue: max` is load-bearing, not decoration.** `cancel-in-progress: false` protects a *running*
job only. By default a concurrency group holds **one** pending run, and a newer pending run
*replaces* (cancels) the older one — so two PRs merging while a reconcile is in flight silently
loses one. `queue: max` raises the pending queue to 100 (shipped 2026-05-07) and is incompatible
with `cancel-in-progress: true`, which is why the pair above is the only valid combination.
Beyond 100 pending, runs are still cancelled, so a **catch-up scan** — reconcile any merged-but-
unreconciled PR, not only the event's — is the backstop that makes a lost event harmless by
construction. Design it in Phase 2 rather than discovering it at 101.

**The checkout contract is explicit, not assumed.** The tool requires a clean checked-out
`development` and then runs `git pull --ff-only` (`wave_reconcile.py:849-854`). The job must check
out `development` as a **local branch** with enough history for a fast-forward — a default detached
or shallow checkout makes the reconciler refuse before doing any useful work.

`pull_request: closed` cannot be caused by the reconciler's own push, so the shape does not
self-retrigger. Pinned by asserting this workflow has **no `push` trigger** — the bot push may still
run `ci.yml`, which is not a reconcile loop.

## Phase 3 — the artifacts land

Moved docs, `releases.db`/`releases.sql`, and the regenerated dashboards reach `development`.
`contents: write` at **job level only**; `ci.yml` is workflow-wide `contents: read`
(`.github/workflows/ci.yml:105-112`) and a test must prove it stays that way.

Also specify, because none of it falls out for free: the bot's commit identity; a no-diff path that
exits cleanly rather than committing nothing; a **staging allowlist** limited to the declared changed
paths, so a future downstream generator cannot silently widen the bot's commit
(`wave_reconcile.py:681-709`, `:729-735` already generate dashboards and plan documents); push
retry/conflict behavior; and whether `development`'s protection ruleset permits the Actions token to
push at all. If it requires a PR with no bot bypass, direct automation simply fails after doing all
the local work — that is a blocking prerequisite to discover now, not in CI.

## Determinism requirements — each one falsifiable, or it does not belong here

1. **Idempotent.** Two applies over the same PR leave a byte-identical tree.
   **Not achievable as first written:** every apply runs `export_timeline.py --preview`
   (`wave_reconcile.py:729-735`), whose payload embeds `datetime.now(timezone.utc)` as
   `generatedAtDisplay` (`utils/timeline/export_timeline.py:519`). Test under a **frozen clock**, or
   digest the tree with the generated-at field excluded. Pick one and say which.
2. **Serialized, with nothing dropped.** `queue: max` + `cancel-in-progress: false`, plus a config
   red asserting the pair is present and a three-close-event integration red asserting all three
   reconcile. Testing that the YAML field exists is not testing the behavior.
3. **No trigger loop.** Assert this workflow has no `push` trigger.
4. **Fails loudly, never partially.** Failure injection after **every** mutation boundary, comparing
   the complete pre/post set — DB, dump, docs, generated artifacts — not just `releases check`.
5. **Dry-run predicts apply.** Not comparable as a raw file diff: the dry run deliberately omits the
   dashboard/timeline exports (`wave_reconcile.py:721-738`). Emit a stable **planned-transition
   manifest** from both paths and compare those, while separately asserting the dry run mutates
   nothing.
6. **Least privilege.** Parse the workflow: job-scoped `contents: write`, and `ci.yml` still
   workflow-wide read.

## `--gate` — resolved: do not use it in Phase 2, and fix it separately

An earlier draft left this open. It should not be.

`check_provenance_receipts` (`wave_reconcile.py:281-298`) walks `TESTS-RESULTS/` and sets
`found = True` on the first file named `provenance.jsonl` or `error_log.jsonl` **anywhere in the
tree**. `pr_num` is read, never compared, and then interpolated into the success line:

```
Provenance receipts verified for PR #{pr_num} (GH-430 compliant)
```

It proves a directory is non-empty and reports that as receipts verified for a specific PR. That is
the same defect class as the GH-406 arc — a check whose message claims more than its logic tests —
sitting inside the flag meant to be the safety catch. Phase 2 must **not** pass `--gate` until that
is fixed or removed; automating it would make a vacuous check mandatory on every merge, and it would
also block receipt-less historical merges on evidence it never actually reads.

Its in-code citation `(GH-430)` is an **upstream** number; there is no #430 in this repo. See
ROUTER.md's two-repo numbering rule.

## Proof — §13

**The reds cannot be replayed from live history.** An earlier draft proposed reproducing PRs #420
and #409. That does not work: both were repaired by hand, so today's checkout and GitHub state are
no longer the pre-fix state, and replaying a merged PR number cannot recreate the former active doc,
dialed-in member, or DB row. **They stay as historical evidence, not as controls.**

Falsifiable reds, from a committed minimal fixture plus `--offline` metadata:

- **(a)** a MERGED closing PR with a dialed-in manifest item, a CLOSED issue, an active doc, and an
  active roadmap row — assert pre-fix code leaves the DB unchanged, and fixed code ships, repoints,
  and marks the row completed
- **(b)** an OPEN linked issue behind a merged PR — assert **no** lifecycle move (the tool guards
  this at `wave_reconcile.py:925`; automation must not bypass it)
- **(c)** failure injected after each mutation boundary — assert exact rollback
- **(d)** two applies under a frozen clock — byte-identical; plus a config red for the three-event
  queue

**Greens** — an over-eager reconciler is worse than none:

- a PR closing no issue reconciles to "nothing to reconcile" and exits 0
- a merged PR whose issue is in no manifest skips quietly rather than erroring
- a legacy-mode repo still gets its `ROADMAP.md` transitions unchanged

## Review history

**Codex (`gpt-5.6-terra`), 2026-09-04** — REVISE, verdict *"not implementable as written."*
Transcript: `relay-system/2026-09-04/gh421-auto-reconcile-plan-qa.md`. Seven findings, all seven
independently verified against the code and adopted in full:

1. ordering blocker **upheld**, with the wording corrected (`check` is a ledger call too; `sync` is
   the only ledger *write*)
2. `manifest ship`'s positional `<issue>` was missing from the write table
3. **`status_marker` has no CLI writer** — the "verbs that already exist" claim was false
4. manifest-member/release-GID lookup does not exist in the reconciler
5. rollback snapshots land after the proposed writes
6. idempotency unachievable while `generatedAtDisplay` embeds `now()`
7. `cancel-in-progress: false` does not queue; `queue: max` is required — verified against GitHub's
   2026-05-07 changelog rather than taken on trust
8. reds are not replayable from repaired history

It also corrected this plan's YAGNI framing: a separate `wave-reconcile.yml` **is** justified
(folding `closed` into `ci.yml` would run unrelated jobs on every close and inherit CI's cancelling
concurrency and workflow-wide read permission), but a privileged workflow is a new subsystem and the
non-goal now says "no new runtime script/module" instead of pretending otherwise.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/wave_reconcile.py", "pattern": "manifest\", \"ship" } ],
  "artifacts":   [
    "utils/py/wave_reconcile.py",
    "utils/py/releases_app.py",
    ".github/workflows/wave-reconcile.yml",
    "test/gh421-auto-wave-reconcile.sh",
    "test/baselines/GH-421-negative-control.md"
  ],
  "remediation": { "source": "issue#421", "criteria": "a PR merged into development reconciles without operator action: the manifest item is shipped with the merge sha as evidence, the active doc moves, its roadmap row is repointed AND marked completed through a supported CLI verb, the dashboards regenerate, and the artifacts land on development under a staging allowlist; three close events during one run all reconcile; a second apply under a frozen clock is byte-identical; an OPEN issue behind a merged PR is not promoted; failure injected at any mutation boundary restores the DB and dump byte-for-byte" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
