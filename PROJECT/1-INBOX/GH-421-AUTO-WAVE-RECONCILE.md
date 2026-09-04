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
depends_on:
  - GH-424 (status_marker CLI writer + journal snapshot fix — hard prerequisite)
  - GH-425 (--gate's provenance check is vacuous — prerequisite for Phase 2 only)
related:
  - GH-165 (the reconciler itself — CLOSED, shipped operator-invoked)
  - GH-269 (retire ROADMAP.md — this is its writer half)
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

Phases that must land in order. Automating before the ledger writes are real is actively worse
than the status quo — that ordering is the plan's whole thesis, and it survived two review rounds.

## Phase 0 — prerequisites, split out after review

Both reviewers independently concluded the original Phase 1 was too big to be a phase. It had grown
a CLI verb, a manifest lookup, and a rollback-boundary change — none of which are automation. Split
on the same line #423 was split out of #418: **a dependency that does not exist is not a decision,
it is a prerequisite.**

**[GH-424](https://github.com/HiQS-Labs/XYZ-forge/issues/424) — hard prerequisite.** In
releases-mode nothing can mark a roadmap row complete: `status_marker` has no CLI writer, and the
`roadmap sync` that used to set it is a no-op here. It also carries the journal-snapshot fix below.

**[GH-425](https://github.com/HiQS-Labs/XYZ-forge/issues/425) — prerequisite for Phase 2 only.**
`--gate`'s provenance check never compares the PR number.

### Why the split was necessary, kept here as the record

`wave_reconcile.py` makes exactly two ledger CLI calls: `releases roadmap sync` and `releases check`
(`utils/py/wave_reconcile.py:714-727`). `check` is read-only, so **`sync` is the tool's only ledger
*write attempt*** — and in releases-mode it returns success without writing
(`releases_app.py:3374-3385`, whose comment names this caller). Meanwhile `wave_reconcile.py:926-957`
still writes the shipping badge and Completed-section move into `ROADMAP.md`, the file `.pdda-mode`
froze.

So today a post-merge reconcile moves the doc, mutates legacy markdown, leaves the canonical DB
untouched, and exits 0. **§13's anti-pattern with a scheduler attached** — which is why no trigger
gets wired until the writes are real.

### What #421 still owns in the reconciler

Once GH-424 lands, this issue wires the transitions the reconciler already computes to the verbs
that will then exist:

| transition | verb |
|---|---|
| dialed-in manifest item whose PR merged | `manifest ship --gid <release> <issue> --evidence <merge-sha>` — note the **positional `<issue>`**, omitted in this plan's first draft |
| doc moved `2-WORKING` → `3-COMPLETED` | `roadmap repoint --issue-num N --doc-path <new>` |
| row's section → Completed | `roadmap update --section` |
| row's marker → ✅ | `roadmap update --status-marker` — **arrives with GH-424** |

Evidence on `manifest ship` is mandatory; the CLI refuses an empty `--evidence`, and that must not
be worked around with a placeholder.

**The manifest lookup is still missing and belongs here.** The reconciler derives only closing issue
numbers (`wave_reconcile.py:897-906`); it has no manifest-member or release-GID lookup, and
`--marathon` is parsed but unused (`:796-798`, `:873-999`). Specify the lookup **and** the behavior
when a merged PR's issue belongs to no manifest — the common case, so "skip quietly" is almost
certainly right and must be stated rather than fall out of a `KeyError`.

The `ROADMAP.md` writes stay untouched. Legacy-mode repos still depend on them; mode-gating that half
is GH-269's.

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
Beyond 100 pending, runs are still cancelled, so a **catch-up scan** is the backstop that makes a
lost event harmless by construction.

agy objected that a catch-up scan needs a persisted "reconciled" marker, which would contradict this
plan's own non-goal, since nothing indexes reconciliations by PR number. **Correct about PR numbers,
wrong about needing new state** — and the way out is to stop asking the PR-shaped question. The scan
should not ask *"which PRs were reconciled?"* but *"what is currently un-reconciled?"*, which the
ledger can already answer: a `manifest_items` row in state `dialed_in` whose issue is CLOSED, or a
`PROJECT/2-WORKING/GH-*.md` whose issue is CLOSED — the second is a check
`pdda-check-issue-doc-sync` already performs. Both are exactly the drift the reconciler exists to
remove, both are derivable from committed state, and neither needs a new file, label, or index.
Phase 2 specifies the scan in those terms.

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
push at all.

**The allowlist and the replan step collide, and the plan created that collision itself.**
`marathon-plan.sh` drops a dated `MARATHON-PLAN-<date>.md`, so a strict path allowlist leaves it
untracked and silently drops it from the bot's commit — one requirement of this plan defeating
another. The allowlist must include the dated plan-doc glob, and a green must assert the plan doc
actually lands. If it requires a PR with no bot bypass, direct automation simply fails after doing all
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

## `--gate` — filed as GH-425, and a prerequisite for Phase 2

`check_provenance_receipts` (`wave_reconcile.py:281-298`) walks `TESTS-RESULTS/`, sets `found = True`
on the first file named `provenance.jsonl` or `error_log.jsonl` **anywhere** in the tree, never
compares `pr_num`, and then interpolates it into the success line: *"Provenance receipts verified for
PR #{pr_num}"*. It proves a directory is non-empty and reports that as receipts verified for a
specific PR. This repo has such files committed, so **the gate currently cannot fail.**

An earlier draft deferred this as "fix separately." agy argued deferral is wrong and it must be a
blocking prerequisite. **Adopted** — it is now
[GH-425](https://github.com/HiQS-Labs/XYZ-forge/issues/425), and Phase 2 may not pass `--gate` until
it lands.

**One correction to agy's framing, because it changes the severity:** `--gate` does not gate
*merging*. By the time the reconciler runs the PR is already merged; the flag gates marathon closeout
and reconciliation. So the exposure is a false provenance record, not unproven code reaching
`development`. Still a prerequisite — a gate that cannot fail gets cited as evidence — but not the
merge-time hole it was described as.

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

### agy (round 2), 2026-09-04 — REVISE

Transcript: `relay-system/2026-09-04/gh421-auto-reconcile-plan-sharpen.md`. Asked explicitly to find
what Codex and the author both missed, and to push back where round 1 over-corrected. It did both.

**Adopted:**

1. **Split Phase 1 out.** Both reviewers reached this independently → GH-424 / GH-425.
2. **The journal misses `RELEASES.generated.md`.** Verified: the snapshot set is `releases.db`,
   `releases.sql`, and four views (`wave_reconcile.py:679-696`) — that file is not among them, yet
   `releases check` verifies its generation marker against the DB (`releases_app.py:4129-4137`;
   live tree confirms DB 398, marker 398, `OK: … matches (398)`). Roll the DB back and leave the
   view at the newer generation and the next check fails `generation-mismatch` — **after** a
   rollback the tool reported as successful. Carried into GH-424.
3. **`--gate` deferral was wrong** → GH-425 as a Phase 2 prerequisite.
4. **The allowlist defeats the replan step** — the dated `MARATHON-PLAN-*.md` would be dropped from
   the bot's commit. One of this plan's own requirements defeating another.

**agy over Codex, and agy is right.** Codex proposed extending `roadmap update` to *derive* the
marker from the new `raw_text`. agy rejected it: deriving a DB column by re-parsing a markdown
bullet reintroduces the markdown-as-schema coupling releases-mode exists to remove. An explicit
enum-validated `--status-marker` ships instead. **This is the one place round 1 was adopted in full
and should not have been** — recorded here rather than quietly corrected.

**Where I broke it against agy:** the catch-up scan (see Phase 2 — reframe the question, no new
state) and `--gate`'s severity (it gates closeout, not merging).

**Not adopted, with reason:** agy's operational walk said the 8 standing `mig-ref-stale` warnings
and 24 grandfather entries do not break an unattended run. Correct — `releases check` exits 0 on
warnings — and no change follows, but it is worth having asked, because a check that warns forever
is one policy change away from failing every automated run.

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
