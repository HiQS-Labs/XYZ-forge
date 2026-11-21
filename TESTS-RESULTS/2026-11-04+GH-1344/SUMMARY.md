# GH-1344: finishing work — readers by issue number, completion sweep, delivered-but-open report, close at merge

Evidence for the six Acceptance items of #1344, taken 2026-11-06 on branch `review/gh1344-claude-2026-11-06`.
The code was built by Codex and reviewed by Claude (`claude-fable-5-1`, high effort). The relay
(`relay-system/2026-11-06/gh1344-claude-review.md`) was approved and attested at `42cedac8`, after an Agy round-1 review
in the marathon relay. The orchestrator's adapt commits `d5434fad` and `949d090a` came after that approval and were reviewed separately by
Codex (FAIL, then PASS); see item 6.

Disposable state only: the sweep ran in a throwaway full clone of this branch, with its origin pointed at
`HiQS-Labs/XYZ-forge` for read-only `gh` calls. Nothing here wrote the primary ledger, and no GitHub issue was changed.

| # | Acceptance item | Result | Evidence |
|---|---|---|---|
| 1 | A moved doc breaks no Task 10 reader (red on base, green on PR) | **Partly met.** Red/green for the readers this change routes; three readers are still outside it | `readers-and-close-witness.json`, `pdda-resolver-1292.txt` |
| 2 | One sweep clears stranded docs and stale `doc_path`; a closed never-started capture moves without gaining a row | **Met** | `sweep-preview.txt`, `sweep-fix.txt`, `sweep-before-after.txt`, `issue-doc-sync-after.txt` |
| 3 | A Jog landing still finds its `SHIPPED … (PR #N)` badge after the sweep | **Met** | `sweep-before-after.txt` (badge count), landed-item check below |
| 4 | The sweep lists delivered-but-open candidates and closes nothing | **Met** | `sweep-preview.txt` (`delivered-but-open: GH-1340 PRs [1343]`) |
| 5 | Partial delivery with neither proof stays open with one reason comment; either proof closes it | **Met** (mocked `gh`) | `readers-and-close-witness.json` `acceptance_5` |
| 6 | Existing suites covering pdda, wave-reconcile and jog pass on the final commit; no new test | **Met** after adapt `d5434fad` | `covering-suites.txt` |

## 1. Readers (red/green)

Fixture: a copy of this branch's `PROJECT/` and `releases.db`. The GH-1292 capture, whose only identity is
`gh_issue: <issue URL>` in its frontmatter, is renamed to `PROJECT/2-WORKING/harness-recap-hooks.md`.

| Reader | Base `3a563a9f` | HEAD |
|---|---|---|
| `jog_run.find_issue_doc` (Jog prepare/land) | `None` | `PROJECT/2-WORKING/harness-recap-hooks.md` |
| `wave_reconcile.find_active_doc_for_issue` (reconciler, census) | `None` | same doc |
| `pdda.sh _pdda_find_doc_for_issue` (roadmap-coverage, issue-doc-sync) | no resolver | same doc |
| ledger `doc_path` | (stale pointers) | repointed by the sweep (item 2) |

**Not routed yet, outside the four reviewed files:**
- the planner (`_marathon_plan.py`);
- start-marathon preflight, which still globs `PROJECT/2-WORKING/GH-{n}-*.md` at `utils/py/swarm_preflight.py:1232`;
- path-integrity.

All three are named in #1340 Task 10, so item 1 is not fully met and #1344 stays open for them.

## 2–4. Sweep on a disposable clone (real `gh` reads)

`wave_reconcile.py --issue-doc-sweep --census {"delivered":{"1340":[1343],"1344":[1350]}}`, preview, then `--fix`:

- **Changes:** 24 docs filed (22 to `3-COMPLETED`, 2 to `4-MISC`) and 70 `roadmap repoint`s. No other ledger write, and no
  `gh issue close` or comment. The only GitHub call is the closure-state read.
- **Ledger before and after:** 457 rows; 265 rows with `SHIPPED … (PR #N)`; 360 rows in Completed. All three counts are
  unchanged after the sweep, so it neither creates rows nor moves sections.
- **Stale pointers:** `issue-doc-sync` after `--fix` reports 0 stale `doc_path` and 0 ambiguous. The remaining
  warnings are closed issues whose section is still open, which `roadmap reconcile-state` owns per the plan, and recon
  docs, which the sweep skips on purpose.
- **Never-started capture:** `PROJECT/1-INBOX/GH-1250-WITNESS-NEVER-STARTED.md` was added for issue #1250, which is
  closed as completed and has no row and no doc. A second `--fix` moved it to `3-COMPLETED` and the row count stayed 457
  (`rows for #1250 = 0`). The 8 real inbox captures the first run filed all already had rows, and each still has
  exactly one.
- **Landed Jog items keep their badges after the sweep:**

  | Issue | PR | Badge |
  |---|---|---|
  | #1263 | #1335 | `Completed`, badge present |
  | #1265 | #1336 | `Completed`, badge present |
  | #1266 | #1337 | `Completed`, badge present |
  | #1264 | #1338 | `Completed`, badge present |
  | #1267 | #1331 | `Completed`, badge present |

- **Delivered-but-open report:** `delivered-but-open: GH-1340 PRs [1343]; report only` and the same for GH-1344. Nothing
  was closed.

## 5. Close at merge (mocked `gh`)

The `_close_delivered_issue` cases, with the `gh` calls each made:

| Case | Closed | `gh` calls |
|---|---|---|
| Partial checklist, no proof | `false` | `view`, `comment` |
| Partial checklist, marker comment already present | `false` | `view` only |
| Checklist complete | `true` | `view`, `close` |
| Partial checklist, independent whole-issue coverage proof | `true` | `view`, `close` |

Base `3a563a9f` closed the issue through the PR instead (`jog_run.py:508-509` appended `--lane-closes-issue`).

## 6. Suites

There are 62 covering suites: the lane's allowlisted `test/*.sh`. 61 passed. `gh280-jog-marathon-adapter` L5 failed
because the close-at-merge path missed markdown-roadmap repos: the fixture ships into `ROADMAP.md`, and `jog land`
looked only in `roadmap_items`. Adapt `d5434fad` does two things:
- `jog land` also accepts the `ROADMAP.md` `SHIPPED … PR #N` badge;
- the suite's `gh` stub answers the landing's `issue view/close/comment` calls.

Codex's one-shot review of `d5434fad` returned FAIL with three Should findings:
- the fallback also ran in releases-mode repos;
- the check after the closeout stayed ledger-only;
- the regex did not tie the PR number to the badge.

`949d090a` adds one helper, `_markdown_shipped`, which fixes all three: it is skipped when `.pdda-mode` sets
`ROADMAP_SOURCE=releases`, it matches the reconciler's own `SHIPPED <date> (PR #N)` badge, and both checks use it.
Codex re-checked it and passed it.

After that commit: gh280 223/0, `jog-queue` 34/0, `wave-reconcile` 23/0, `gh257-roadmap-ledger-fixes` all passed. No new
test was added (GH-831).
