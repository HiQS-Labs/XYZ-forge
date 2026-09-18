# Plan review packet — GH-710 + GH-708 (consumer re-vendor fixes)

Reviewer: grade the two plans against their stated requirements and commensurate complexity
(two small bug fixes in a bash/python test harness — not an enterprise threat model). Read the
plans in full; they carry the observed evidence, line references and the ordered steps:

- `PROJECT/1-INBOX/GH-710-PLANNER-NULL-GH-NUMBER.md` — planner crash + `--gid`-rated rows
- `PROJECT/1-INBOX/GH-708-VENDORED-SUITES-FORGE-ROOT.md` — witnessed skips for forge-root-only suites
- `relay-system/2026-09-18/gh708-sweep.txt` — the raw sweep the GH-708 table was classified from

Code under change (read before answering): `utils/py/_marathon_plan.py` `:611` (`_gh_issue_of`),
`:766-787` (`_load_ledger_from_db`), `:834-860` (record build, precedence comment `:842-848`),
`:867` (identity key), `:962` (the crash); `utils/py/releases_app.py` `roadmap_render` (sparse-row
grammar `- **title** → [doc](doc_path)`); `test/gh698-planner-db-ratings.sh`;
`test/lib/fixture-guard.sh`; `test/gh267-express-skill.sh:110`; `relay-automation/xyz-vendor.sh:416-475`
(VENDOR_DIRS, VERSION stamp); `utils/py/express.py:320-330,455-462` (githooks resolution);
`githooks/pre-push:50-56`.

## Questions (answer each with a file:line or a stated reason)

1. GH-710 match key: is `doc_path` the right fallback identity for a `gh_number IS NULL` row, given
   `:867` already keys such rows by `doc:<path>|title:<title>` and the sparse render links exactly
   `doc_path`? Name any row shape where `_doc_of` would NOT return the DB's `doc_path` (e.g. a
   `raw_text` that carries a different link, a `PROJECT/` path filtered by `_doc_of`'s
   `relay-system/` exclusion).
2. GH-710 ambiguity rule: two NULL-gh rows sharing one `doc_path` → neither is rated from the DB.
   Is silently holding both as `unrated` acceptable, or must the flag say "ambiguous"?
3. GH-710 precedence: does the fallback keep the `:842-848` comment true for a NULL-gh row that also
   carries legacy `complexity/risk/effort` frontmatter (DB wins)?
4. GH-710 tests: is the red control real — on the pre-fix planner does the TypeError leave the
   output empty so `assert_present` fails, or does the fixture need an explicit rc assertion?
5. GH-708 decision: any reason to vendor `githooks/` instead of skipping, given `express.py`
   resolves `<repo-root>/githooks/install.sh` and `pre-push` refuses without `<root>/validate.sh`?
6. GH-708 marker: `$HERE/../VERSION` with a `source_commit=` line as the vendored-install signal —
   any forge checkout or fixture where that file exists and would cause a false skip? Any vendored
   install where it is absent (older `xyz-vendor.sh`) and the suite would then REFUSE (exit 2)
   instead of skipping — is that the right failure?
7. GH-708 sweep: name any suite in the 19 that should NOT skip (its forge-root path is created by
   the suite, or the reference is dead), and any suite missed (a forge-root reference the anchor
   rule would not catch).
8. Ratings: `710 → 90/90/50/85`, `708 → 65/55/50/80` — grounded? appeal neutral, no user override.

## Verdict format

`STATUS: Approved` or `STATUS: Changes requested` with numbered findings, each `Blocking` or
`Advisory`, each tied to a requirement or a file:line. Keep `NEXT: Producer` on handback.
