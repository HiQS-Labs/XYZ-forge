---
title: "GH-710: releases-mode planner crashes on a gh_number-NULL row, and rows rated by --gid never count as rated"
status: active
created: 2026-09-18
updated: 2026-09-18
owner: unassigned
goal: the marathon planner (and therefore every consumer wave_reconcile) survives and correctly rates ledger rows that have no gh_number
gh_issue: 710
source: https://github.com/HiQS-Labs/XYZ-forge/issues/710
doc_type: bug
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/698
  - https://github.com/HiQS-Labs/XYZ-forge/issues/707
  - https://github.com/HiQS-Labs/XYZ-forge/issues/708
  - https://github.com/BinoidCBD/LTVera-Pandas/issues/551
context_tags: [marathon-plan, releases-ledger, wave-reconcile, consumer-repo]
non_goals:
  - Changing the rendered ledger grammar (roadmap_render) to carry rmi- ids
  - Touching the GH-698 F8 rollback emitter (owned by #707)
  - Backfilling or re-rating any consumer's rows
---

# GH-710 — planner crashes on a gh_number-NULL row; rows rated by `--gid` stay `unrated`

## Problem (observed, `2707ddb0`, LTVera-Pandas ledger with 7 `gh_number IS NULL` rows)

- **A — crash.** `utils/py/_marathon_plan.py:962` formats the `unrated` hint with
  `"… --issue-num %d …" % r["gh"]`; `r["gh"]` is `None` for a doc-only row, so
  `marathon_plan.py --dry-run` dies with `TypeError: %d format: a real number is required, not
  NoneType` before printing one flag (rc 1).
- **B — rated-by-gid rows hold as unrated.** `_load_ledger_from_db` (`:779-787`) keys `db_ranks` /
  `db_axes` by `gh_number` (`WHERE gh_number IS NOT NULL`), and `_gh_issue_of` (`:611`) derives
  `gh` from the rendered line, so a row scored with `releases roadmap rate --gid <rmi>` — the
  documented escape hatch for exactly these rows — never satisfies the `rated` gate.
- **C — blast radius.** `wave_reconcile.py` runs `marathon-plan.sh --dry-run` downstream; the crash
  rolls every consumer reconcile back with exit 6 (LTVera#551 Step 6). F8's rollback record is what
  made that visible; it stays as is (#707).

## Requirements

1. No `%d` on `None`: a NULL-`gh_number` unrated row prints an `unrated` flag whose hint names the
   row's real `rmi-` id (`rate via: releases roadmap rate --gid rmi-… --rated P/S/A/E (row has no
   gh_number)`); the run exits 4/5 like any other held plan, never 1.
2. A NULL-`gh_number` row whose four `rating_*` columns are set sequences as rated, with the DB rank
   (four-axis sum) as its score — the same precedence rule as gh-keyed rows ("DB rating wins over
   legacy frontmatter", `:842-848`, stays true and stays one comment).
3. `wave_reconcile.py --dry-run` gets past the planner step on such a ledger.

## Plan (smallest surface: one module, one suite)

1. `_load_ledger_from_db`: drop the `WHERE gh_number IS NOT NULL`, select `global_id`, `title` and
   `doc_path` alongside the four axes, and build a second index for rows with `gh_number IS NULL`
   and a `doc_path`: `db_by_doc[(doc_path, title)] = (global_id, rank|None, axes|None)` plus
   `db_by_doc[(doc_path, None)]` when the `doc_path` is unique among NULL-gh rows. Two rows that
   share BOTH doc and title are true duplicates: neither is indexed and the flag hint names both
   gids (r1 finding 2 — a `--gid`-rated row that merely shares a doc with another row is matched by
   its title and counts as rated). Return it as a fourth tuple element; the three callers
   (`:810-816`) unpack it.
   *Why doc_path + title:* the planner's own identity for a NULL-gh row is already
   `doc:<path>|title:<title>` (`:867`); the rendered line for a sparse row is
   `- **title** → [doc](doc_path)` and an HQ-intake line is `- **title** … [basename](doc_path)`
   (`releases_app.py roadmap_render`), so the item's title and link target are exactly the DB's
   `title` and `doc_path`. No renderer change.
2. Record build (`:834-860`): when `gh is None`, look up `(doc_rel, title)`, then `(doc_rel, None)`,
   then the same two keys for every other `.md` link target on the item (r1 finding 1 — do not
   depend on `_doc_of`'s pick alone); take `gid`, `db_rank`, `db_axes_item` from the first hit.
   Store `"gid"` on the record. Rows whose doc lives outside `PROJECT/` are not capture docs by the
   planner's existing rule (`_doc_of`, `:621-624`) and never reach the `unrated` branch — unchanged,
   and a non-goal here.
3. The hint (`:962`): one conditional expression — `--issue-num %d` when `r["gh"]` is set, else
   `--gid <gid> … (row has no gh_number)` using the record's `gid` (fallback literal `<rmi-…>` only
   if the row was not indexed).
4. `test/gh698-planner-db-ratings.sh`: two fixture rows with `PROJECT/2-WORKING/` docs (the
   planner's capture-doc rule; r1 finding 1) — `g104` (`gh_number NULL`, no rating) → its `unrated`
   flag carries `--gid g104` and `(row has no gh_number)`; `g105` (`gh_number NULL`, rated
   60/60/50/60) → listed in the plan, never under `unrated`. The suite records the planner's exit
   code and asserts it is 4 or 5, never 1 (r1 finding 4). Red control witnessed on the pre-fix
   planner (2026-09-18, task clone): one such row → `rc=1`, `TypeError: %d format: a real number is
   required, not NoneType`, no flag printed.
5. Verification (unsandboxed): `bash test/gh698-planner-db-ratings.sh`, `bash test/marathon-plan.sh`
   (70), `bash test/wave-reconcile.sh` (18); consumer proof on LTVera after re-vendor (see #551).

## Risks / rollback

Easy — one module + one suite; `git revert` of the landing restores the crash. A wrong match key
would rate the wrong row: guarded by the ambiguity rule (1) and by `g105` asserting the score that
sequences it is its own.

## Acceptance

- [ ] `gh698-planner-db-ratings.sh` green with the two new rows; red on the pre-fix planner.
- [ ] `marathon-plan.sh` 70/0, `wave-reconcile.sh` 18/0.
- [ ] Consumer: `python3 .xyz/utils/py/marathon_plan.py --dry-run` on LTVera exits 4/5 with
  `INFO [unrated]` = 0; `wave_reconcile.py --pr 535 --dry-run` passes the planner step.

## Rating (2026-09-18) — `rated 90/90/50/85`

- sev 90: a crash that blocks the planner and every consumer's post-merge reconcile (exit 6);
  recoverable, no data lost.
- pri 90: blocks LTVera#551 Steps 3–6 today; severity-led.
- appeal 50: neutral (no operator preference given).
- effort 85: ~25 lines in one module plus two fixture rows; clear repro.
- Recurrence: no earlier `%d`-on-`None` incident in the planner found in the last 28 days of issues;
  same-class "planner assumes a gh_number" appears once before (#698 F2 keyed ratings by gh_number,
  landed 2026-09-18) — this is its first consumer-side failure, not a repeat.

## Status

active — plan r1 reviewed by agy (`relay-system/2026-09-18/gh710-gh708-plan-qa.md`): findings 1, 2, 4 accepted and folded in above; r2 pending.

## Merge evidence

(filled at landing)

## Lessons Learned (For Future Agents)

(filled at landing)
