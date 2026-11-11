# GH-1414 focused documentation verification

## Current candidate checks

- `git diff --check`: passed.
- Existing skill-creator `quick_validate.py`, using `uv run --with pyyaml`: **start-task, file-xyz-bug and idea all passed**.
- Baseline observations: file-xyz-bug's old `<n>` description fails the validator's angle-bracket restriction; idea's plain description scalar fails YAML parsing at `phase: comment`. Commit f49972ed converts both descriptions to folded scalars and removes the placeholder's angle brackets. Both defects are corrected in this candidate.
- Earlier Codex wording approval (`relay-system/2026-11-10/gh1414-skills-wording.codex.md`) covers only the original two-skill diff, not idea or the description fixes.
- Claude Code Opus 5.5 reviewed all three skills at f49972ed. Its round-1 receipt (`relay-system/2026-11-10/gh1414-opus55-round1.md`) approves the skill intent but requests evidence correction (F1); final approval remains pending an exact-head re-check. This is T3 provider dispatch, not a relay-drive CLI attestation.
- F1 disposition: accepted; current checks and provenance distinguish the final three-skill scope from historical results. F2 disposition: accepted; idea Step 7 now says Plan/Non-goals clarifications occur during Step 6 before computing the review hash.
- Manual boundary review: initial document-only input separated from technical source reads; bug capture remains redacted, author-only, filing-only and single-confirmation. Idea preserves its existing consult seats, body section order, Acceptance parser, review hash and provisional admission boundary. No invented exclusions or extra approval gate.
- Full validate.sh and end-to-end skill invocation were not run. The earlier documentation push gate passed at 671faa3d; it does not qualify this later candidate. The final committed candidate must pass the documentation push gate and required hosted checks before merge.
- Managed deployment not performed. Existing deployment status reports unrelated skill drift and stale Pulse state; no override or incidental repair applied.

## Candidate identity

Three-skill diff SHA-256 (raw `git diff origin/development --` for the three paths): `423d8ae39784a98e806ff9d009a20d5b2309ca8199d1eaf894d2ddd396fb0b76`.
The final review receipt identifies the exact commit it reviews; this hash excludes receipts to avoid a self-referential digest.
