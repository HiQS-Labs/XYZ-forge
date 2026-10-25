---
gh_issue: 1208
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1208
title: "jog land requires a green hosted wave-reconcile run per landed head; since GH-1127 that lane is dispatch-only — accept the local reconcile evidence"
status: active
created: 2026-10-24
updated: 2026-10-24
owner: claude-fable-5-1 (start-task, 2026-10-24)
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: false
rating: 78/75/50/85
non_goals:
  - Re-enabling per-merge hosted reconciliation (decision #1131 retired it).
  - A new receipt file, schema, state store or second ledger reader.
  - Changing `_landing_tail_proof`, `_merge_reviewed_pr`, `jog_verify_pr_before_merge` or any pre-merge check.
  - Changing how `wave_reconcile.py` writes the landed row (`SHIPPED <date> (PR #N)`) or merge-cleanup's Phase 5 order.
  - New tests, suites or registry entries (GH-831).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1127 and #1131 (local reconcile by default; full suite only at promotion)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1200 (factory flywheel; this is prerequisite P2, landing lifecycle step 6)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1108 and PR #1116 (committed-receipt landing; introduced the hosted check)
  - utils/py/jog_run.py:1189-1201 (hosted check), skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:651-820 (Phase 5 order), utils/py/wave_reconcile.py:1516-1581 (landed-row badge)
goal: >
  `jog land GH-N --pr M` completes an ordinary development landing under the GH-1127 default: it accepts
  either a green hosted wave-reconcile run for the landed head (unchanged) or the local reconciler's own
  ledger evidence for that PR (written, committed or about to be committed by merge-cleanup Phase 5),
  and still refuses when neither exists.
---

# GH-1208 · `jog land` accepts the local reconcile evidence

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved r2 (`94542fbb`; r1 blocker: landing marker crashed on an empty hosted list — folded in as item 4). Row admitted (`--accepted-start`). | Implement the one hunk, run the gh280 suite + the two disposable-copy manual checks, tier-3 gate, final Codex QA, ready PR against development (do not merge). |

## Observed (ground truth, development @ 80e67677)

`jog_land` (`utils/py/jog_run.py:1137-1210`) verifies PR identity, merge reachability, the post-merge tail
(`_landing_tail_proof`), `releases check`, and then **requires** a hosted run:

```python
hosted_cmd = ["gh", "run", "list", "--workflow", "wave-reconcile.yml", "--commit", head, ...]
...
if not matching or matching[0].get("status") != "completed" or matching[0].get("conclusion") != "success":
    raise ContractError("hosted wave-reconcile is not green for the landed PR head")
```

`.github/workflows/wave-reconcile.yml` is `workflow_dispatch` only (decision #1131: development merges
reconcile **locally**; the hosted full suite runs once at development → main promotion). So after an
ordinary merge no run exists for the PR head and `jog land` refuses every time. The #1192 landing on
2026-10-24 reconciled locally (commit 86476497) with no hosted run; `jog land` would have refused.

Call-site fact that shapes the fix: merge-cleanup Phase 5 (`merge_cleanup.py:651-805`) runs
`wave_reconcile.py --pr N` → `releases check` → `pdda issue-doc-sync` → **`run_jog_post_merge_land`** →
and only then `commit_and_push_phase5_writes` (`:807-820`, subject `chore: reconcile after PR #N`). When
`jog land` runs there, the reconcile commit does **not exist yet**; its writes sit uncommitted in the
primary's tree. A "reconcile commit on development" check would therefore refuse at the one call site
that matters. The evidence has to be the reconciler's write itself.

What the local reconciler writes for a landed PR (`wave_reconcile.py:1516-1581`): the issue's
`roadmap_items` row moves to section `Completed` with the badge `✅ **SHIPPED <date> (PR #N)**` in its
`raw_text` (and `status_marker` `✅`), and the capture doc moves to `PROJECT/3-COMPLETED/`. Read back
today for GH-1020 / GH-763: `section=Completed`, `raw_text … SHIPPED 2026-10-24 (PR #1192)`.

The gh280 adapter suite's L5 case passes today only because its `gh` stub answers `run list` with a
synthetic green run (`test/gh280-jog-marathon-adapter.sh:46-49`); it does not exercise the GH-1127 state.

## Smallest fix (one function, existing reader, no new state)

In `jog_land`, replace the unconditional hosted requirement with **either/or evidence**:

1. **Hosted (unchanged):** the existing `gh run list --workflow wave-reconcile.yml --commit <head>` query;
   accepted when a matching run is `completed`/`success` (existing error handling unchanged; see below).
2. **Local:** the landed issue's own `roadmap_items` row in `<root>/releases.db`, read through the same
   read-only `connect()` the function already uses for `jog_queue`: `section == "Completed"` and
   `raw_text` contains `(PR #<pr_number>)` (the badge `wave_reconcile.py:1521` writes). This is the
   reconciler's committed-or-about-to-be-committed effect for exactly this PR; `releases check` (already
   required two lines above) guards ledger integrity.
3. **Neither:** `ContractError("no reconciliation evidence for PR #N: hosted wave-reconcile is not green
   for the landed head and the GH-N roadmap row is not SHIPPED (PR #N) — run wave_reconcile.py --pr N
   locally (GH-1127) or dispatch the hosted lane")`.

Order: hosted first (keeps today's behaviour byte-identical when a run exists), then local.

4. **Landing marker (plan QA r1 blocker).** `jog_land` serialises `"hosted_reconcile": matching[0]` into
   the existing `landing.json` (`jog_run.py:1221`) **after** `jog_set_status(..., "completed")`; with no
   hosted run `matching` is `[]` and that line raises `IndexError` after the queue row is already
   completed. The marker therefore changes with the gate, in the same hunk: `"hosted_reconcile":
   matching[0] if matching else None` (hosted success keeps today's object), plus one sibling key
   `"local_reconcile": {"roadmap_gid": <row global_id>, "raw_text": <row raw_text>}` when the local
   branch supplied the evidence, else `None`. Same file, same writer, no new receipt or schema version;
   the existing `landing.json` consumers (`test/gh280…:1019,1042`) read `merged_sha` and file presence only.

Existing error handling, described accurately: a nonzero `gh` exit already maps to `[]`
(`jog_run.py:1196`), malformed JSON reaches the outer `ValueError` handler and refuses, and a non-list
answer raises `invalid hosted reconciliation evidence`. None of that changes. `_landing_tail_proof`
remains the post-merge moved-head authority. ~20 lines in one function.

Alternatives rejected: (a) require the `chore: reconcile after PR #N` commit on origin/development — wrong
at merge-cleanup's call site (above) and brittle on subject text (today's hand reconcile used a different
subject); (b) have the local reconcile write a new receipt file — a second artefact for the same fact the
ledger row already states, and a new consumer contract (#1175: no second authority); (c) drop the hosted
branch — promotion runs still produce hosted evidence and it is free to keep.

Rollback: revert the one hunk.

## Verification (GH-831: no new tests; receipts under `TESTS-RESULTS/2026-10-24+GH-1208/` with `provenance.jsonl`)

1. **Existing suite, unchanged:** `XYZ_WORK_CONNECTORS=0 RELAY_SELF_SUFFICIENCY_SKIP=1 bash
   test/gh280-jog-marathon-adapter.sh` stays 223/223 (hosted-green path, L5).
2. **Manual check 1 — GH-1127 state (red → green).** A *copy* of that suite in a disposable clone with two
   edits: the stub's `run list` answers `[]` (no hosted run), and a `roadmap add --issue-num 901` row is
   seeded before L5 (the fixture is legacy-ROADMAP at that point and has no `roadmap_items` row; the same
   seeding the suite itself performs later at `:1089`), so the fixture's own `wave_reconcile.py --pr 42
   --offline` writes the `SHIPPED (PR #42)` badge into `releases.db`. Reverted code: L5 `jog land` refuses
   with `hosted wave-reconcile is not green for the landed PR head` (the live defect). Fixed code: L5
   completes (`completed|landed via PR #42`), `landing.json` parses with `hosted_reconcile == null` and a
   `local_reconcile` object naming the GH-901 row, and L6/L7 replay stay green. Record both logs; the copy
   lives under the clone's gitignored `temp/` and is deleted with the clone — not a registered suite.
3. **Manual check 2 — neither evidence refuses.** Same copy, additionally skipping the fixture's
   `wave_reconcile.py` step (or resetting the row's section) before L5: fixed code refuses with the new
   combined message; the row stays untouched. This is the red control for the local branch.
4. **Manual check 3 — replay.** After the fixed L5 landing, `jog reconcile GH-901` (idempotent entry)
   returns the same completed state with no DB byte change (`releases.db` sha256 before/after).
5. Final gate by `utils/ci-route.sh` on the changed paths (`utils/py/jog_run.py` → tier 3), run once on
   the final code commit in a disposable `-gate` clone with identity checked before and after.

## Limit

The local branch reads `roadmap_items`; a consumer repo still in legacy ROADMAP.md mode with no ledger row
for the issue gets no local evidence and keeps today's hosted-only behaviour. XYZ-forge is releases-mode
(DB is roadmap truth), so this does not bite here; it is stated, not solved.

## Rating rationale (2026-10-24)

`rated 78/75/50/85`. Severity 75: under the GH-1127 default every `jog land` of an ordinary development
landing refuses, so no Jog row can complete without an operator dispatching the hosted workflow by hand;
no data is lost (the row parks `awaiting-landing`), but the unattended landing lifecycle that #1200
depends on cannot close. Priority 78: it blocks #1200 prerequisite P2 and merge-cleanup's own Phase 5
`run_jog_post_merge_land` on any repo with a live Jog queue. Recurrence: structural since #1131
(2026-10-17); first observed as a blocker in the #1200 independent review (2026-10-24); #1192's landing
would have hit it had GH-1020 been a Jog item. Appeal 50 neutral. Effort 85: one hunk in one function,
reusing an existing reader, with the gh280 fixture as the harness.
