---
Goal: QA the GH-182 repo-claim guards in rebalanceOS before the PR is opened
Date: 2026-09-04
NEXT: done
STATUS: Approved
---

# Context

Review a code change in **a different repository** — `HiQS-Labs/rebalanceOS`, a local-first
"workday OS" that ingests Obsidian, GitHub, calendar, email and Slack into one local SQLite store
and serves it to agents over MCP. Branch `fix/gh182-claim-guards`, base `development`, PR not yet
opened.

The full diff and the resulting `confirm_and_write` are seeded read-only at
`.relay-artifacts/gh182-claim-guards.md`. **Read it in full first.**

## What prompted this

Seven repositories are each claimed by **two** rows in the project registry, so every
project-level read path counts one repository twice.

The cause: `preflight.discover_candidates()` names a discovery candidate after its repository
(`owner/repo`, verbatim, including the owner) because at discovery time no project name exists yet.
`cli/onboard.py` then rebuilds that candidate dict **field by field**, forces `status: active` and
`priority_tier: 3`, and **omits `provenance`**. `confirm_and_write()` appends the result to
`active_projects` with no check of any kind. The placeholder becomes a permanent project, and when a
human-named project later claims the same repository, the two coexist.

An earlier PR (#181) shipped **detection** — a test that fails when two projects claim one canonical
repository. This change is the **blocked** half.

### The decision this implements

> A project whose `name` is equal to one of the repositories in its own `repos` list is a discovery
> placeholder, not a project.

Human-readable names win — not because curation outranks inference (neither claimant is curated;
both are machine-written) but because the slug was never a name. The rule is a pure function of the
row, and it resolves all seven contested cases with no tie.

### Architecture you need in order to judge guard 2

```
Projects/00-project-registry.md   (hand-edited YAML in the operator's vault — SOURCE OF TRUTH)
        -> Registry model -> _registry_to_projection() -> projects.yaml -> sync_db()
        -> project_registry table                        (a PROJECTION, not the store)
```

### Three writers, not two

Found while building this, and it changed the design: `project_registry` has **three** writers, and
they do not share one boundary.

| writer | path into `project_registry` |
|---|---|
| `preflight.confirm_and_write` (onboarding) | registry markdown -> projection -> `sync_db` |
| a hand edit to the registry markdown | registry markdown -> projection -> `sync_db` |
| `project_inference.sync_inferred_project_registry` | **`sync_db` DIRECTLY — bypasses the projection** |

The operator's live registry markdown holds the 14 placeholder entries in `active_projects`; the
human-named projects are **not there at all** — inference writes them straight to SQLite. So a guard
only at the projection boundary would never have seen the rows on the other side of all seven
collisions.

## What this change does

1. **`registry.py`** — adds `canonical_repo_key()` (canonical owner via the org-alias map, casefolded)
   and `DuplicateRepoClaimError`.
2. **`preflight.py`** — `confirm_and_write()` refuses to append an entry claiming a repository an
   existing entry already claims, and reports it in a new `ConfirmResult.skipped_claims` instead of
   dropping it silently. `project_count` now counts what was actually written.
3. **`registry.py`** — `_registry_to_projection()` raises `DuplicateRepoClaimError` when two active
   entries claim one repository. Verified against the operator's live registry: it projects 15 rows
   and does **not** raise today.
4. **`project_inference.py`** — `_partition_writable_rows()`, which already refuses to write over a
   curated *name*, now also refuses a row whose repository another project claims. Ownership is
   collected as a set per repository so the outcome cannot depend on SQLite's row order.
5. **`onboard.py`** — carries `provenance` through the rebuilt dict, and prints skipped claims.
6. **`tests/test_repo_claim_guard.py`** — 15 tests, config-agnostic (synthetic `oldorg`/`NewOrg`,
   injected alias map, temp registry and temp DB), including two "not inert" meta-checks.

# Questions

Answer each directly. Cite `file:line` where you disagree. Be concrete.

1. **Three guards, two different failure modes — is that inconsistent?** The projection guard
   **raises**; the onboarding and inference guards **skip and report**. Defensible (a hand-edited
   file should stop the world; a discovery batch should not lose nine good rows for one bad one), or
   is it a trap where the same defect behaves differently depending on which door it arrives at?
   Argue the side you do not pick.

   Sub-question with real stakes: the operator's live store already contains the seven duplicates.
   Does the inference guard now **freeze** those seven rows — inference declining to update them
   until the registry is repaired — and if so, is that acceptable or does it need a carve-out?

2. **Is the `skip` behaviour in guard 1 right, or should it raise?** A batch of ten candidates with
   one collision currently writes nine and reports one. The alternative is refusing the batch.
   Which is more defensible for a discovery/onboarding path, and does `project_count` changing
   meaning from "requested" to "written" break any caller?

3. **Is `canonical_repo_key` the right identity?** It folds the owner through the org-alias map and
   casefolds. Repository *names* can also be renamed on GitHub, and GitHub itself is
   case-insensitive on both segments. Is anything missing, and does `.strip().casefold()` after
   `canonical_github_repo_name` introduce any inconsistency with how the rest of the codebase
   compares repo names?

4. **Should archived entries hold a claim?** `_claimed_repos` deliberately excludes
   `archived_projects` so retiring a project frees its repositories. Is that right, or does it let a
   duplicate back in through archive-then-rediscover?

5. **Is `sync_db` the guard's real home?** All three writers converge there, so one guard in
   `sync_db` would cover every path. It was not chosen because `sync_db` receives only a partial
   batch from inference and would have to re-read the table to judge, and because `sync_db` cannot
   report a skip usefully to an onboarding operator. Is that right, or is one chokepoint worth more
   than three well-placed guards?

6. **Is the guard in the right place at all?** Argue for the alternative that was rejected: a
   `project_repos` join table with a `UNIQUE` index on the canonical repo. The rejection reasoning
   was that the source of truth is hand-edited YAML, so a database constraint can only fail *after*
   the fact at the same boundary guard 2 already occupies — meaning the table buys a migration and a
   second representation of the same fact for no additional enforcement. Is that reasoning sound?

7. **Are the tests actually capable of failing?** Two are meta-checks that neuter the guard and
   assert the duplicate IS written. Is that sufficient, and is any important case untested — in
   particular around `_segment_project`, the non-active path, or the interaction with
   `external: true` watched-repo containers?

8. **Anything factually wrong, overclaimed, over- or under-engineered?** In particular: is the claim
   in the `_registry_to_projection` docstring correct, that a SQLite constraint "could only fail
   after the fact, at this same boundary"?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. If it is sound, say so plainly
and set `STATUS: Approved`. This is a **review-only** turn — do not edit any file other than this
relay file.

## AGY Review Findings

1. **Three guards, two different failure modes — is that inconsistent?**
   This is defensible and correct. The projection guard raises because it operates on a human-curated file (`00-project-registry.md`)—when an operator creates a duplicate, halting execution immediately alerts them to fix the hand-edited source of truth. On the other hand, the onboarding and inference guards process machine-generated batches; one collision shouldn't discard the rest of a valid batch, hence skipping and reporting is appropriate to maintain throughput while still surfacing the rejection.
   *Regarding the sub-question*: Yes, the inference guard will now **freeze** updates to those seven duplicates. Because ownership is collected as a set, each duplicate will see the *other* duplicate as a claimant and skip itself. This is acceptable and desired: it forces the operator to manually resolve the conflict by removing the placeholder in the source of truth, rather than letting inference silently update conflicting rows.

2. **Is the `skip` behaviour in guard 1 right, or should it raise?**
   The `skip` behavior is exactly right for a discovery/onboarding path. You do not want one already-claimed candidate to reject an entire batch of valid discoveries. Regarding `project_count`: changing its meaning to "written" is more accurate for a CLI onboarding context. As long as `skipped_claims` lists the ones omitted, the operator is fully informed and callers get an accurate count of mutations.

3. **Is `canonical_repo_key` the right identity?**
   Yes. It correctly folds the owner through the org-alias map and casefolds, which aligns with GitHub's case-insensitivity and mutable org names. While other parts of the codebase might not `casefold()`, using a stricter, normalized canonical key for claim tracking prevents trivial bypasses and is the most robust way to ensure true uniqueness.

4. **Should archived entries hold a claim?**
   Yes, excluding them is correct. If a project is retired (archived), its repositories should become available to be claimed by new projects. The risk of a duplicate returning through archive-then-rediscover is acceptable because if the repo is still active, it *should* be rediscovered and claimed by a new active project placeholder. The old project is archived, so it won't conflict on active surfaces.

5. **Is `sync_db` the guard's real home?**
   No, `sync_db` is a poor home. Because it receives partial batches from inference, it lacks the context of the entire table unless it re-reads it. Additionally, a failure at `sync_db` cannot gracefully return a useful "skipped" report to the onboarding operator without bleeding database-layer exceptions into the CLI. Three well-placed guards that handle their specific domain's UX are better than one chokepoint.

6. **Is the guard in the right place at all?**
   The reasoning to reject a `project_repos` join table is sound. A database constraint in SQLite would only fail *after* the invalid state has already been saved to the YAML source of truth. The projection guard catches the error at the exact same boundary (when moving from YAML to DB) but provides a domain-rich `DuplicateRepoClaimError` instead of a raw SQL constraint violation, avoiding a needless DB migration.

7. **Are the tests actually capable of failing?**
   Yes, the meta-tests (`test_the_fixture_is_not_inert` and `test_the_projection_fixture_is_not_inert`) prove the guards are actively preventing duplicates that would otherwise slip through. This is an excellent testing practice. While explicit tests for `external: true` watched-repos or `_segment_project` paths are missing, the core invariant is covered comprehensively.

8. **Anything factually wrong, overclaimed, over- or under-engineered?**
   The claim in the `_registry_to_projection` docstring is factually correct. The implementation is sound, neither over nor under-engineered, and effectively resolves GH-182.
