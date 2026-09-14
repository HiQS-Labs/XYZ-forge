---
Goal: QA GH-620 implementation against its approved plan and issue
Date: 2026-09-14
NEXT: codex
STATUS: Open
---

# Context

Review the complete branch diff `origin/development...HEAD`, issue #620, and
`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md`. Important implementation paths are
`utils/py/xyz_mini_sync.py`, `test/gh620-skills-army-mini-sync.sh`,
`skills/skills-army-hq/README.md`, `mini/skills-army-*`,
`skills/push-to-skills-army-mini/SKILL.md`, and `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md`.

Operational envelope: manual, local publisher for one public generated child. Forge remains the
only authority. Apply commensurate MVP complexity: reject duplicate engines and speculative
frameworks, schedulers, recovery machinery, fuzzers, matrices, or mirrored child suites.

Producer evidence:

- Missing required manifest entry witnessed red: `rc=1`, literal-set and manifest assertions failed.
- Restored GH-620 suite: 15/15.
- Existing XYZ-mini publisher: 18/18.
- Existing Skills Army suite: 25 tests + 4 subtests passed.
- CI routing: 76/76; bidirectional test registry: 10/10.

Questions:

1. Does the fixed target profile preserve default XYZ-mini behavior and avoid a second publisher?
2. Does the live origin/main preflight refuse arbitrary wrong-branch/ahead/behind/divergent state before writes while permitting only unborn, exact, or exact retained-publisher retry state?
3. Is the generated Skills Army payload exactly closed and free of machine/operator state, with a child-valid init path?
4. Do the literal oracle, mutant, detached init/add/target/sync smoke, idempotence, provenance, and stale-remote case substantiate the issue without excess tests?
5. Does the playbook cover all seven reusable recipe phases while preserving one authority and rollback path?
6. Are any acceptance criteria missing, claims false, or changes unrelated? Sweep every changed implementation file.

Append a concise review with file:line citations. End with exactly `VERDICT: PASS`, `FAIL`, or
`PARKED` and a non-empty `Basis:`. Set `STATUS: Approved` only on PASS.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

