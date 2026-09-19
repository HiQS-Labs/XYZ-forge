# Final QA packet — GH-710 + GH-708 (consumer re-vendor fixes)

Reviewer: grade the committed implementation against the approved plans (relay
`relay-system/2026-09-18/gh710-gh708-plan-qa.md`, Approved r3) and their acceptance criteria — two
small bug fixes in a bash/python test harness, commensurate complexity, no enterprise machinery.

## What to read

- Plans + acceptance (now with results): `PROJECT/1-INBOX/GH-710-PLANNER-NULL-GH-NUMBER.md`,
  `PROJECT/1-INBOX/GH-708-VENDORED-SUITES-FORGE-ROOT.md`
- GH-710 diff: `git show ca2f66bd` — `utils/py/_marathon_plan.py` (`_load_ledger_from_db`, record
  build, the `unrated` hint), `test/gh698-planner-db-ratings.sh`
- GH-708 diff: `git show 201313ca` — `test/lib/fixture-guard.sh::require_forge_root`, 62 one-line
  call sites, 8 `_setup.sh` cwd fixes, new `test/gh708-vendored-suite-skips.sh`, `validate.sh`
  registration
- Evidence: `relay-system/2026-09-18/gh708-vendored-run.txt` (397 vendored suites: 323 pass /
  60 skip / 14 fail — the leftovers are #715); forge-side: every touched suite run individually,
  green and unskipped; gh698 16/16 with red control (pre-fix planner: rc 1, 13 failures);
  gh708 17/17 with red control (no VERSION → exit 2 REFUSING).

## Questions

1. GH-710: does the record build match the approved key order — `(doc_rel, title)` → unique
   `doc_rel` → the same two keys over every other `.md` link — and does a true duplicate (same doc
   AND title) resolve to gids only, never to a rating? Cite the lines.
2. GH-710: is the "DB rating wins over legacy frontmatter" precedence still one rule for gh rows
   and NULL-gh rows alike? Any path where a NULL-gh row with legacy frontmatter is scored by the
   frontmatter?
3. GH-710 test: the fixture docs moved to `PROJECT/2-WORKING/` — confirm the pre-existing
   assertions are now real (GH-102 reaches the `unrated` branch, not `needs-doc`) and that the
   suite reads lanes/ranks from the written plan doc rather than the dry-run report. Is the rc
   assertion (4 or 5, never 1) placed so a crash cannot pass?
4. GH-708 helper: is the vendored marker (`$HERE/../VERSION` with `source_commit=`) safe against a
   false skip in the forge, and is exit 2 on a non-vendored tree with a missing path the right
   failure? Is `BASH_SOURCE[1]` the correct anchor for the calling suite in every call shape used
   (top-level call; call after `_setup.sh`)?
5. GH-708 call sites: spot-check five suites of your choosing for (a) the call at top level, before
   the first use of the path, (b) no second `. fixture-guard.sh` after `_setup.sh` (it resets the
   guard root — the gh365-tier-fail-closed incident), (c) the named path is one the suite actually
   reads. Name any suite where the placement is wrong.
6. GH-708 acceptance: is "62 skip in a vendored copy, all run unskipped in the forge, 11 leftovers
   tracked in #715" a complete answer to the issue's two questions, and is the vendor decision
   (skip, never vendor githooks/) still right given the diff?
7. Anything in either capture doc that is now false, and are the ratings (710 → 90/90/50/85,
   708 → 65/55/50/80) still grounded by the evidence?

## Verdict format

`VERDICT: PASS` or `VERDICT: FAIL`, then `STATUS: Approved` / `STATUS: Changes requested`, numbered
findings each `Blocking` or `Advisory` with a file:line. Keep `NEXT: Producer` on handback.
