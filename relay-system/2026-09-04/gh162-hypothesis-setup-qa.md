---
Goal: QA GH-162 Hypothesis Setup and md_parser Property Testing in RebalanceOS
Date: 2026-09-04
NEXT: codex
STATUS: Open
---

# Context

Adjudicate the implementation of GH-162 (Test suite gaps & Hypothesis adoption) in `rebalanceOS-gh162-hypothesis`.

Target Repo: `/Users/noelsaw/Documents/GH Repos/rebalanceOS-gh162-hypothesis`
Branch: `feat/gh162-hypothesis-setup`
Commit: `6e478df` (latest commit)

Files to inspect:
- `pyproject.toml`
- `.gitignore`
- `tests/conftest.py`
- `src/rebalance/ingest/md_parser.py`
- `tests/test_md_parser_property.py`
- `PROJECT/2-WORKING/GH-162-TEST-SUITE-GAPS-HYPOTHESIS.md`
- `ROADMAP.md`

# Questions for Reviewer (Codex)

1. **Pytest & Hypothesis Configuration:**
   Does `pyproject.toml` correctly add `"hypothesis>=6.100.0"` to `dev` optional-dependencies and declare `[tool.pytest.ini_options]` with `minversion`, `testpaths`, `pythonpath`, and `--strict-markers`? Does `.gitignore` properly exclude `.hypothesis/`?
2. **Conftest Profile Registration:**
   Does `tests/conftest.py` safely register `ci`, `dev`, and `debug` profiles with `suppress_health_check` and `deadline=None` without crashing if `hypothesis` is imported in an environment where it is absent?
3. **Property Test Battery Robustness (`tests/test_md_parser_property.py`):**
   Do the Hypothesis property tests rigorously assert:
   - Crash-freedom over arbitrary unicode strings?
   - Roundtrip & non-dict fallback for frontmatter?
   - Tag extraction excluding code blocks?
   - Wikilink & embed separation and alias stripping?
   - Heading chunking structural invariants (index sequence, level bounds 1-6)?
4. **Parser Regex Hardening (`src/rebalance/ingest/md_parser.py`):**
   Are the regex updates (`_FRONTMATTER_RE`, `_HEADING_RE`, `_title_from_body`) using `[ \t]+` / `[ \t]*` horizontal whitespace rather than `\s+` / `\s*` to prevent multiline newlines from bleeding across line boundaries?
5. **Suitability for PR:**
   Is this PR ready to be opened against `origin/development`?

Flag anything wrong, missing, or incorrectly scoped. Be concrete and cite file:line where applicable.

Write your verdict below and update STATUS to `Approved/Closed` if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
