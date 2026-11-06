---
gh_issue: 1348
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1348
title: "feat(express): admit non-execution-authority skills/**/SKILL.md under --docs-only with relay attestation"
status: Active
created: 2026-11-05
updated: 2026-11-05
owner: Antigravity
goal: "Admit non-execution-authority SKILL.md under express --docs-only when backed by validated relay attestation"
branch: feat/XYZ-forge-gh1348-express-skill-docs-2026-11-05
doc_type: feature
effort: 2
complexity: 2
risk: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Implemented driver changes in `express.py`, policy in `express/SKILL.md`, and added regression controls in `test/gh267-express-skill.sh` (126/126 pass) | Final Codex Relay QA (`relay-system/2026-11-05/gh1348-final-qa.md`), smoke test receipt, push, PR, and clone retirement |

## Observed problem and bet

- **Observed problem:** `skills/2-daily/express/SKILL.md` (lines 73–93) documents a risk-based review policy allowing bounded documentation-only skill edits to use `/express --docs-only` when appropriately reviewed, while keeping execution-authority and gate-bypass changes outside `--docs-only`. However, `utils/py/express.py` (`is_documentation_update()`, line 109) still hard-blocks every `SKILL.md` path unconditionally under `--docs-only`, forcing even reviewed markdown-only skill updates through full PR/merge/reconcile ceremony.
- **Outcome sought:** Allow non-execution-authority `skills/**/SKILL.md` files to be landed directly and safely via `/express --docs-only` from a fresh task clone off `origin/<base>`, provided the update is attested by an approved `relay-drive` review (`.git/relay-attest/*.json`), while maintaining strict hard refusals for execution-authority skills, scripts, and unstaged/post-review drift.
- **Smallest viable bet:**
  1. Update `is_documentation_update()` in `utils/py/express.py` to recognize `skills/**/SKILL.md` and `relay-system/*.md` as documentation, while strictly excluding `EXECUTION_AUTHORITY_SKILLS` (`express`, `merge-cleanup`, `merge-cleanup-deep`, `start-marathon`, `marathon-cleanup`, `start-task`, `relay`, `relay-xyz`, `relay-automation`, `jog`) and any non-`SKILL.md` file under `skills/`.
  2. In `cmd_check`, when `docs_only` is true and core paths include `skills/**/SKILL.md`, verify a valid `relay_attest` record (`.git/relay-attest/*.json`) using unpacked `record, error = relay_attest.load(...)` (asserting `record is not None` and `record["status"] == "Approved"`) and unpacked `ok, reason = relay_attest.candidate_ok(record, head_sha, root)` (asserting `ok is True`), plus clean working tree diff on the skill path vs `HEAD`. Refuse with `rule=skill-unattested` if absent, malformed, unapproved, or drifted.
  3. Exempt `relay-system/*.md` transcripts from insertion and file bounds in `insertions()` and `is_doc_path()`.
  4. Update `skills/2-daily/express/SKILL.md` to reflect that the driver now admits attested skill documentation.
  5. Add test coverage in `test/gh267-express-skill.sh` exercising both positive admission and negative refusals.
- **Alternatives rejected:**
  1. *Blanket exemption of all SKILL.md without review:* Rejected because skill instructions serve as autonomous agent control flow; unreviewed direct landings could compromise safety or introduce loops.
  2. *Adding synthetic test suites for skills:* Rejected by repo rail `No new tests` (GH-831).
- **Rollback / containment:** Reverting the changes in `utils/py/express.py` and `skills/2-daily/express/SKILL.md` immediately restores the prior strict refusal behavior.

## Implementation Plan

1. **Extend path classifiers in `utils/py/express.py`:**
   - Define `EXECUTION_AUTHORITY_SKILLS` and helpers `is_skill_path(path)`, `skill_name(path)`, and `is_execution_authority_skill(path)`.
   - Update `is_documentation_update()` to admit non-execution-authority `SKILL.md` and `relay-system/*.md`.
   - Update `is_doc_path()` to treat `relay-system/*.md` as paperwork exempt from product size bounds.
   -> expect non-execution-authority skill files and transcripts to pass docs-only path qualification, and execution-authority skills to refuse docs-only.

2. **Add attestation verification in `utils/py/express.py`:**
   - Implement `find_valid_skill_attestation(root, skill_paths)` using `relay_attest.git_common_dir`, unpacking `record, error = relay_attest.load(...)` and explicitly requiring non-null record and `record["status"] == "Approved"`, and unpacking `ok, reason = relay_attest.candidate_ok(record, head_sha, root)` and explicitly requiring `ok is True`. Also assert clean working-tree diff on each skill path vs `HEAD`.
   - In `cmd_check()`, if `docs_only` and any `skill_paths` are present, invoke `find_valid_skill_attestation()` and fail closed with `refuse(root, "skill-unattested", ...)` on any failure.
   -> expect unreviewed, malformed, or post-review drifted skill edits to refuse with `skill-unattested`, and approved reviewed edits to pass.

3. **Update documentation in `skills/2-daily/express/SKILL.md`:**
   - Update the "Current driver compatibility" section to document the active support for non-execution-authority skill updates backed by relay attestation.
   -> expect policy and driver behavior to be fully aligned.

4. **Add regression controls in `test/gh267-express-skill.sh`:**
   - Add negative control: unattested skill edit under `--docs-only` refuses `skill-unattested`.
   - Add negative control: execution-authority skill edit under `--docs-only` refuses `docs-only`.
   - Add negative control: skill edit modified after attested revision refuses `skill-unattested`.
   - Add positive control: non-execution-authority skill edit committed to branch, reviewed via isolated target-tree review without seeded `--artifact`, within the 2-commit budget, with a valid `Approved` attestation record passing `check --docs-only`.
   -> expect all controls in `bash test/gh267-express-skill.sh` to pass.

## Acceptance Criteria

- [x] `utils/py/express.py` refuses `skills/2-daily/express/SKILL.md` and other execution-authority skills under `--docs-only` with `rule=docs-only`.
- [x] `utils/py/express.py` refuses non-execution-authority `skills/**/SKILL.md` under `--docs-only` when no valid Approved `relay_attest` receipt exists with `rule=skill-unattested`.
- [x] `utils/py/express.py` refuses non-execution-authority `skills/**/SKILL.md` under `--docs-only` when the skill file has drifted from the attested revision with `rule=skill-unattested`.
- [x] `utils/py/express.py` passes `check --docs-only` when a non-execution-authority `skills/**/SKILL.md` is committed to branch within the 2-commit budget and accompanied by a valid Approved target-tree `relay_attest` receipt for `HEAD` (without seeded `--artifact`).
- [x] `test/gh267-express-skill.sh` passes green with zero regressions.
- [x] `skills/2-daily/express/SKILL.md` accurately documents the verified driver behavior.

## Lessons Learned (For Future Agents)

- When verifying attestation records in `find_valid_skill_attestation`, `relay_attest.candidate_ok` returns a `(bool, reason)` tuple rather than a boolean scalar; always unpack the tuple and explicitly verify `ok is True`.
- `relay_attest.load` accepts terminal statuses including `Closed`; the driver must explicitly enforce `record["status"] == "Approved"`.
- `candidate_ok` excludes `relay-system/` paths by contract, allowing relay transcript commits to follow the reviewed code revision without invalidating candidate fitness.
- For tests in `test/gh267-express-skill.sh`, creating `$FX/test/pdda-repo-contract.sh` and adding it to `$FX/validate.sh` `TESTS` ensures `--docs-only` check tests pass in hermetic fixtures.
