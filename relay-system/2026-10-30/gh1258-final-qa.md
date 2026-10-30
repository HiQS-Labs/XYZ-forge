---
Goal: Final QA — #1258 Phase 1 (idea skill) on the committed implementation and evidence
Date: 2026-10-30
NEXT: codex
STATUS: Open
---

# Context

Final QA (start-task Step 8) for https://github.com/HiQS-Labs/XYZ-forge/issues/1258 Phase 1. Plan QA was Approved in `relay-system/2026-10-30/gh1258-plan-qa.md` (round 2, attest `6be3b534`). Branch `feat/XYZ-forge-gh1258-idea-skill-2026-10-30`, head `9d552e2c`, base `development@e305cbf3`. You cannot run git here; the changed set relative to the base is listed below and every file is in this tree.

Changed files (vs `origin/development`):
     ARCHITECTURE.md                                    |   3 +-
     PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md              | 245 +++++++++++++++++++++
     .../2026-10-30+GH-1258/hq-park-create.log          |   6 +
     TESTS-RESULTS/2026-10-30+GH-1258/intake-after.txt  |  24 ++
     TESTS-RESULTS/2026-10-30+GH-1258/intake-before.txt |  21 ++
     .../2026-10-30+GH-1258/intake-writeset.diff        |   4 +
     .../2026-10-30+GH-1258/preflight-dryrun-gh1263.log |  24 ++
     TESTS-RESULTS/2026-10-30+GH-1258/provenance.jsonl  |   9 +
     .../red-controls/GH-1263-NOTREADY.mutated.md       | 139 ++++++++++++
     .../red-controls/GH-1263-STALE.mutated.md          | 139 ++++++++++++
     .../red-controls/notready-exit5.log                |  15 ++
     .../red-controls/stale-exit4.log                   |  15 ++
     .../2026-10-30+GH-1258/roadmap-rate-readback.txt   |   1 +
     TESTS-RESULTS/2026-10-30+GH-1258/smoke.md          |  44 ++++
     relay-system/2026-10-30/gh1258-plan-qa.md          | 202 +++++++++++++++++
     releases.db                                        | Bin 1564672 -> 1564672 bytes
     releases.sql                                       |  11 +-
     skills/1-hourly/idea/SKILL.md                      | 164 ++++++++++++++
     18 files changed, 1063 insertions(+), 3 deletions(-)

Implementation (two files): `skills/1-hourly/idea/SKILL.md` (new, markdown only) and `ARCHITECTURE.md` (one Skills Index row after `handsfree`; `1-hourly` count 15 → 17). Intake: `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md` (capture; plan of record embedded verbatim under `## Idea`, Decisions D1–D3 settled, plan-QA amendments applied), `releases.db`/`releases.sql` (row `rmi-01M66S1Y01WM5BWJS9XCKBXRWG` parked, rated 80/55/50/65, admitted with `--accepted-start` after plan QA). Evidence: `TESTS-RESULTS/2026-10-30+GH-1258/` (`smoke.md`, `provenance.jsonl`, logs, red-control inputs). Relay threads under `relay-system/2026-10-30/` are review records.

Operational envelope: a markdown skill that composes existing writers; no code under `utils/`, no new flag/script/test/suite/gate (AGENTS.md *No new tests*, GH-831). Grade against the plan's `## Acceptance` and commensurate complexity. A new test file or `validate.sh` registry entry in the diff would be a finding; there should be none.

Read: the capture doc's embedded plan (`## Plan` Phase 1 and `## Acceptance`), `skills/1-hourly/idea/SKILL.md` in full, the `ARCHITECTURE.md` row, `TESTS-RESULTS/2026-10-30+GH-1258/smoke.md` and `provenance.jsonl`, and the code the skill cites: `utils/hq/hq.sh:214-369`, `utils/hq/hq-lib.sh:402-406,423-515,555-558`, `utils/py/releases_app.py:3325,3639,3738-3741`, `utils/py/swarm_preflight.py:101-147,1219-1238,1299-1379,1640-1645`, `utils/py/jog_run.py:505-556,1382,1398`, `skills/2-daily/file-xyz-bug/SKILL.md:25-123`, `skills/2-daily/hq/SKILL.md:25-70`, `skills/README.md`.

Questions:
1. Is every `## Acceptance` item of the plan satisfied by the diff plus the recorded evidence, with its red control witnessed? Name any item the evidence does not substantiate.
2. Does `skills/1-hourly/idea/SKILL.md` match the cited code? Check in particular: the hq locator variables (`HQ_SH`, `find-hq.sh --env`), the `HQ_PARK_*` names, that `hq park --create` prints `✓ issue: <url>`, the title rule (no `rated`/`ovr` token; `parse_rating` reads the whole ledger line), `roadmap rate` after park and its `--force`/`already-rated` semantics, the preflight invocation (`--project-doc` + `--target-root`, dirty tree recorded not judged), and the exit-code table (0/3/4/5/6/7).
3. Does the skill introduce any writer, locator, flag or parallel path beyond `hq park --create`, `releases roadmap rate`, `gh issue comment` and the existing `swarm-preflight.sh` dry-run? Does it ever write an approval/reviewed marker or clear `ratings_provisional`?
4. Is the body contract in the skill (headings, checkbox-only Acceptance, `artifacts_new` rule, footer with `models=` and hash) consistent with the plan's contract and with what `swarm_preflight.py`/`jog_run.py` read?
5. Is the persisted rating for #1258 (80/55/50/65, appeal 50, no ovr, `ratings_provisional: true` still set) consistent with the plan's PRS rationale and the evidence?
6. Does the smoke receipt substantiate its claims (issue #1263 filed through the skill, READY exit 0, STALE exit 4 and NOT-READY exit 5 on mutated copies, write-set delta of exactly three paths, acceptance 1 scratch control, gh660 7/7)? Is anything claimed that the logs do not show?
7. Anything in the diff outside Phase 1 scope, or any accidental file?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

