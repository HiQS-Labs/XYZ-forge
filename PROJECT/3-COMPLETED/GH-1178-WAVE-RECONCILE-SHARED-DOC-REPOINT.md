---
gh_issue: 1178
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1178
title: "wave_reconcile: when several issues share one plan doc, only the doc's own issue gets its ledger doc_path repointed"
status: Complete
updated: 2026-10-27
owner: operator
goal: "Every ledger row that pointed at a doc moved during a reconcile run points at the doc's new location afterwards."
created: 2026-10-22
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-1178 — shared plan doc leaves sibling ledger rows dangling after reconcile

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved r1; fix verified (`TESTS-RESULTS/2026-10-22+GH-1178/SUMMARY.md`); final Codex QA Approved r2 (`relay-system/2026-10-22/gh1178-final-qa.md`). | PR open against development; awaiting merge. |

## Why

When one PR closes several issues that share one plan doc, `utils/py/wave_reconcile.py` moves the
doc to `PROJECT/3-COMPLETED/` but repoints only the ledger row of the issue the doc is named after.
Every other row keeps a `doc_path` to a file that no longer exists (observed in
HiQS-Labs/rebalanceOS#350 → #351 F1, repaired by hand).

## Recon (base `origin/development` @ `f243ccfbfb53`)

- `find_active_doc_for_issue` (`utils/py/wave_reconcile.py:1070`) matches a doc by **filename
  prefix** `GH-<n>-` (not frontmatter `gh_issue`, as the issue text says — same effect). A sharing
  issue's doc is named after another issue, so it is never found.
- Owning issue: `validate_and_update_doc` moves the doc, then `update_roadmap_entry(...,
  doc_path=relpath(dest))` (`:2386-2396`) repoints that row via `ledger_write(["roadmap",
  "repoint", "--gid", ...])` (`:1552`).
- Sharing issue: the `No active doc in 2-WORKING` branch (`:2400-2418`) calls
  `update_roadmap_entry` without `doc_path` — section moves to Completed, `doc_path` is untouched.
- Order-independent: whichever issue is processed first, the sharing row never sees the
  destination. So the fix must run **after** the landing loop, not inside the no-doc branch.
- Canonical writer: `releases_app.py roadmap repoint` (`cmd_roadmap_repoint`, `:3770`) rewrites
  `doc_path` **and** the embedded path in `raw_text`, refuses a destination that does not exist.
  `ledger_write` (`:1275`) is the only reconciler path to it; in `--dry-run` it prints the
  `TRANSITION` and does not call the CLI.
- Owned-row qualification lives in `update_roadmap_entry` (`resolve_roadmap_identity` +
  `repo_slug`); the new pass reuses the same check so a foreign row is never touched.
- Legacy `ROADMAP.md` is frozen in releases-mode — out of scope.

## Plan

**Outcome sought:** after `wave_reconcile.py --pr N`, no ledger row points at a doc this run moved.

**Smallest bet (issue option 1, exact path match):**

1. Before the landing loop, `moved_docs = {}`. In the doc branch, after `validate_and_update_doc`
   returns, record `moved_docs[relpath(doc_path)] = relpath(dest_path)` when they differ.
2. After the landing loop (before "Global roadmap cleanups"), call a small helper
   `repoint_moved_doc_rows(repo_root, moved_docs, repo_slug, dry_run, journal)`: if `releases.db`
   exists and `moved_docs` is non-empty, select rows whose `doc_path` is a moved source, keep only
   owned rows (same `resolve_roadmap_identity` check as `update_roadmap_entry`), and for each one
   `ledger_write(["roadmap", "repoint", "--gid", gid, "--doc-path", new])`.
3. The owning row was already repointed inside `update_roadmap_entry`, so its `doc_path` is no
   longer a moved source and gets no second write; a rerun finds nothing to move → no writes.

**Non-goals:** no basename guessing (option 2); no new ledger writer; no `ROADMAP.md` legacy edit;
no change to which issues are terminalized; no new test suite (`AGENTS.md` *No new tests*, GH-831).

**Alternative rejected:** fixing inside the no-doc branch — fails when the sharing issue is
processed before the owning one (the doc has not moved yet).

**Rollback / containment:** one helper + three lines in one file; revert the commit. Writes go
through `ledger_write`, so the run's journal rolls them back on failure like every other write.

**Risk:** a row of an OPEN issue sharing the moved doc is also repointed. That is correct — the file
moved; leaving a dangling path is the defect.

## Acceptance

- [ ] A1 Fixture (gh421 harness shape): PR closing #421 and #422, both rows on
  `PROJECT/2-WORKING/GH-421-fixture.md` → after reconcile both rows' `doc_path` (and `raw_text`)
  are at `3-COMPLETED`. Run both issue orders.
- [ ] A2 Red control: same fixture against `f243ccfbf` `wave_reconcile.py` (`GH421_WAVE=`) leaves
  #422 dangling.
- [ ] A3 A row whose doc was not moved this run keeps its `doc_path`.
- [ ] A4 Rerun is a no-op (no `roadmap repoint` transition).
- [ ] A5 No new writer: only `ledger_write(["roadmap","repoint",...])`. Existing suites
  `test/gh421-auto-wave-reconcile.sh`, `test/wave-reconcile.sh`, `test/gh202-*`, `test/gh232-*`
  stay green.

Verification is a manual check recorded under `TESTS-RESULTS/2026-10-22+GH-1178/` (no new suite).

## Rating (2026-10-22)

`rated 45/50/50/85` — sev 50: ledger integrity defect (dangling pointer), recoverable by one CLI
call, no data loss; trips pdda roadmap coverage. pri 45: one observed incident
(rebalanceOS, 2026-10-21); prior 14 days 0 same-class issues found — trend unknown. appeal 50
neutral. effort 85: one-file, ~25-line change on an existing writer.

## Implementation notes

- `repoint_moved_doc_rows` sits beside `update_roadmap_entry` in `utils/py/wave_reconcile.py`;
  `moved_docs` maps source → (destination, owning issue). The owning row is skipped: it was already
  repointed, and in `--dry-run` the ledger cannot show that, which previewed it twice (Codex plan-QA
  nit; `gh421 test_dry_run_transitions` pins the exact preview).
- `releases_app` is imported only once matching rows exist, as `update_roadmap_entry` does —
  `test/wave-reconcile.sh`'s fixture has an empty placeholder ledger and no `releases_app`.

## Lessons Learned

- Plan QA flagged the duplicate dry-run preview as a Nit; an existing suite pinned it exactly. Treat a
  "cosmetic" preview difference as a contract change when a suite asserts the transition list.
- A new helper in a shared module must keep the module's lazy-import shape: fixtures copy only part
  of `utils/py`.
