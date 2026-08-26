# Question: Should GH-234 be built, or is it superseded by the GH-32/#53 design?

GitHub issue #234 ("Scaffold a dedicated SQLite Git merge driver for releases.db") asks for:

1. A new `releases merge-db %O %A %B` verb in `utils/py/releases_app.py` conforming to Git's custom merge driver spec.
2. Schema-aware merging: logically merge INSERTs into `roadmap_items` / `manifest_items` from both branches into the ancestor.
3. Setup script to wire `.git/config` + `.gitattributes` to route `releases.db` conflicts to the driver.
4. Graceful failure on same-row conflicting edits.

Its stated premise: releases.db is the canonical source of truth (per #169's transition away from ROADMAP.md), SQLite is binary, so Git merges fail and operators cannot hand-edit a .db.

However, the repo appears to have already decided AGAINST a merge driver, by design:

- `.gitattributes` (lines 3-36) says `releases.db` is GENERATED from `releases.sql` — a canonical GID-keyed text dump — rebuilt via `releases check --rebuild`, marked `-diff linguist-generated=true`, and that it "conflicts on every concurrent ledger write, ON PURPOSE — see .gitattributes for why we did not paper over that with a merge driver."
- `utils/releases-merge-resolve.sh` (GH-32 / #53) is the sanctioned one-command resolution: merge the text `releases.sql`, regenerate the DB from the merged dump, verify `releases check` comes back clean.

Please read for yourself before answering:
- The issue text is reproduced above (issue #234 in HiQS-Labs/XYZ-forge; you may not have network — the summary above is faithful).
- `.gitattributes`
- `utils/releases-merge-resolve.sh`
- `utils/py/releases_app.py` (skim the merge/check/rebuild-related verbs; it is ~3700 lines)
- `releases.sql` (skim structure: how mergeable is the text dump really — INSERT ordering, autoincrement ids, position-UNIQUE tables like doc_lines/legacy_lines, append-only trigger tables like op_receipts)

## What "good" looks like

An advisory answer (no writes) that makes a clear call among:
(a) Build #234 as specified (binary three-way merge driver on the .db);
(b) Close #234 as superseded — the GH-32/#53 releases.sql text-dump path already solves it, possibly with small hardening;
(c) A middle path — e.g. a merge driver on `releases.sql` (text) rather than the .db, or wiring releases-merge-resolve.sh in as the driver.

Address specifically:
- Does the #234 premise ("operators cannot resolve the conflict") still hold given releases-merge-resolve.sh exists?
- Are there failure modes the text-dump merge path does NOT cover that a schema-aware driver would (e.g. both branches INSERT rows that textually conflict in releases.sql, autoincrement id collisions, position-UNIQUE collisions)?
- What is the smallest change that makes concurrent-branch ledger writes safe and low-friction?

Advisory only. Do not modify any files.
