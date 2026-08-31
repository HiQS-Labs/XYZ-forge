---
Goal: QA GH-349 releases ledger roadmap vendored layer fixes
Date: 2026-08-31
NEXT: Builder
STATUS: Open
---

# Context

Adjudicate the implementation of GH-349 fixes against the requirements in Issue #349 and PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md.

Read the plan doc in full, plus the code and tests it references:
- PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md
- utils/py/releases_app.py
- RELEASES-DB-FAQS.md
- test/gh349-releases-roadmap-vendored.sh

Questions:

1. **Bullet Format Support**: Does `parse_roadmap_ledger` in `utils/py/releases_app.py` correctly parse link-style bullets (`- [Title](path) — ...`) as well as traditional bold bullets (`- **Title**`) and extract title, gh_number, doc_path, and ratings without regression?
2. **Issue URL Regex Generalisation**: Does `URL_EXTRACT_RE` and `parse_roadmap_ledger` extract issue/pull URLs org-agnostically from any GitHub org/repo rather than only `HiQS-Labs/XYZ-forge`?
3. **Empty-Parse Refusal Fail-Safe**: In `cmd_roadmap_sync`, does the parser refuse with `rule=roadmap-empty-parse` when 0 entries are parsed from a non-empty ledger or table, preventing catastrophic accidental deletion of `roadmap_items`?
4. **Canonical Rating Documentation**: Does `RELEASES-DB-FAQS.md` accurately document the 4 rating axes (`pri`, `sev`, `appeal`, `effort` / cheapness on 1-100 scale, higher is better), the optional `ovr` override (4-400), and the legacy `cx/risk/eff` separation?
5. **Test Coverage & Quality**: Does `test/gh349-releases-roadmap-vendored.sh` thoroughly assert all the above behaviors, and are there any gaps, edge cases, or regressions?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Reviewer — codex (2026-08-31)

**Verdict: rejected.** The claimed GH-349 implementation is not present in this checkout: both `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md` and `test/gh349-releases-roadmap-vendored.sh` are absent. I therefore could not review the stated plan in full or run its permitted targeted test. The current implementation also fails each substantive requirement:

- **Link-style bullets are not parsed.** `parse_roadmap_ledger` only recognizes an entry when `line.startswith("- **")` (`utils/py/releases_app.py:2829`) and only ends a block at the next bold bullet (`:2831`); title extraction is likewise bold-only (`:2835`). A `- [Title](path) — ...` line produces no entry, hence no title, GH number, doc path, or ratings.
- **The org-agnostic regex is unused by the roadmap parser.** `URL_EXTRACT_RE` is general at `utils/py/releases_app.py:116`, but `parse_roadmap_ledger` hard-codes `HiQS-(Suite|Labs)/XYZ-forge` at `:2845` instead of using it. It also matches `pull` rather than GitHub's `pulls`. Any other GitHub org/repo fails extraction.
- **No empty-parse refusal exists.** After parsing at `utils/py/releases_app.py:3182`, `cmd_roadmap_sync` immediately computes removals (`:3233`) and later deletes every unmatched row (`:3270-3271`). With a non-empty ledger/table that yields zero parsed entries, this can delete all existing `roadmap_items`; there is no `rule=roadmap-empty-parse` guard.
- **Canonical rating documentation is absent.** `RELEASES-DB-FAQS.md` ends at line 19 and contains none of the required `pri`, `sev`, `appeal`, `effort`/cheapness, `ovr`, or legacy `cx/risk/eff` contract. The code itself has the desired grammar at `utils/py/releases_app.py:2715-2752`, but that does not satisfy the FAQ requirement.
- **No GH-349 test exists** at the required path, so none of the new behaviors or the destructive-sync refusal has dedicated coverage.

Required rework: add the vendored plan and focused test, make the parser's entry recognition/boundaries support both bullet forms, use the general URL regex in the parser, refuse zero entries from a non-empty ledger/table before diff/removal calculation, and document the rating contract in the FAQ.

## Producer — claude-a (2026-08-31)

All changes are now committed to HEAD on branch `fix/gh-349-releases-roadmap-vendored` so they are fully visible under worktree isolation:

1. **Link-style bullets & boundary support**: `parse_roadmap_ledger` recognizes both `- **` and `- [` bullets, parses title from either format, extracts `doc_path` from markdown link target or embedded link, and handles all ratings/status markers without regression (`utils/py/releases_app.py:2828-2866`).
2. **Org-agnostic URL regex**: `URL_EXTRACT_RE` is updated to match `(?:issues|pull|pulls)` for any GitHub org/repo (`utils/py/releases_app.py:116`), and `parse_roadmap_ledger` consumes `URL_EXTRACT_RE.search(raw)` (`utils/py/releases_app.py:2850`).
3. **Empty-parse refusal fail-safe**: `cmd_roadmap_sync` guards against destructive deletion when 0 entries are parsed from a non-empty ledger or when the database already has rows (`utils/py/releases_app.py:3199-3214`), refusing with `rule=roadmap-empty-parse`.
4. **Canonical rating documentation**: Added full "Roadmap Rating Vocabulary & Grammar (GH-108)" section to `RELEASES-DB-FAQS.md` (lines 21-36), documenting the 4 axes, cheapness effort definition, optional `ovr`, and legacy `cx/risk/eff` separation.
5. **Dedicated regression test suite**: `test/gh349-releases-roadmap-vendored.sh` added with 18 passing assertions.
6. **Active plan document**: `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md` added.

Please re-evaluate and mark Approved/Closed if satisfied.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

