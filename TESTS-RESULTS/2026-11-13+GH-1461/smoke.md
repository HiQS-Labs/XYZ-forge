# Smoke Test Receipt: GH-1461 Simplify Idea Skill

## Test Scope
Verification of simplified `skills/1-hourly/idea/SKILL.md` and updated `ARCHITECTURE.md`:
1. Documentation gate verification: `bash utils/pdda/pdda.sh run`
2. Skill deploy tests: `python3 -m unittest test/test_deploy_skills.py`
3. CI Route verification: `git diff --name-only origin/development | bash utils/ci-route.sh pull_request`
4. Skill instruction smoke verification:
   - Verify frontmatter syntax and fields.
   - Verify that all HQ tools, ledger commands (`releases roadmap rate`), and `PROJECT/1-INBOX/` capture file writes are removed.
   - Verify EGM paraphrase-first comprehension lens (What this proposes, How it works, What it's not) is present.
   - Verify 4-part issue structure.

## Observed Results
| Check | Command | Observed Output | Verdict |
|---|---|---|---|
| CI Route | `git diff --name-only origin/development \| bash utils/ci-route.sh pull_request` | `route=docs`, `tier=1`, `tier_reason=docs-only` | PASS |
| PDDA Gate | `bash utils/pdda/pdda.sh run` | `PDDA run complete: no errors, 105 warning(s) to review` (exit 0) | PASS |
| Deploy Tests | `python3 -m unittest test/test_deploy_skills.py` | `Ran 34 tests in 20.235s - OK` | PASS |
| Clean Disk Write Check | `grep -E "hq park|roadmap rate|1-INBOX" skills/1-hourly/idea/SKILL.md` | No occurrences found in execution paths | PASS |
| EGM Lens Check | `grep -E "What this proposes|How the existing system works|What it's not" skills/1-hourly/idea/SKILL.md` | All 3 EGM comprehension headings present | PASS |
