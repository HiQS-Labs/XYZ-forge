# GH-1508 smoke — governance doc list extension (manual check, GH-831)

Fixture (in a disposable clone of this branch): `docs/agents/rules.md` containing a dead link
`[missing](missing-file.md)`, with a pointer added to `ROUTER.md`. Command:
`PDDA_ACTIVITY_LOG=/dev/null bash utils/pdda/pdda.sh governance`, counting lines that name `missing-file.md`.

| Case | Script | Observed |
|---|---|---|
| No `.pdda-mode` extra line | pre-fix (`origin/development`) | 0 |
| `PDDA_GOVERNANCE_DOCS_EXTRA=docs/agents/rules.md` in `.pdda-mode` | pre-fix (red control: line ignored) | 0 |
| Same extra line | this branch | 1 — `WARN [pdda-check-governance] docs/agents/rules.md:3 dead reference 'missing-file.md'` |
| Extra line removed | this branch | 0 (default set unchanged) |
| Extra line present + `PDDA_GOVERNANCE_DOCS=README.md` | this branch | 0 (the variable still replaces the whole set) |
- Existing suite: `bash test/gh365-pdda-gov-scan.sh` → == gh365-pdda-gov-scan: 22 passed, 0 failed ==
| CRLF line ending + quoted value `"docs/agents/rules.md"` | this branch (after final QA round 1) | 1 (CR and quotes stripped) |
