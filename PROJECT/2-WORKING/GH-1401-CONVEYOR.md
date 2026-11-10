---
title: "GH-1401 · Conveyor upstream issue preparation"
status: active
created: 2026-11-09
updated: 2026-11-09
owner: codex
goal: Prepare existing issues into grounded, published task packets using existing intake and preflight mechanisms.
gh_issue: 1401
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1401
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1401 · Conveyor upstream issue preparation

## Status

| What was just completed | What's next |
|---|---|
| PR #1404 published; Codex and additional Opus medium QA Approved; first-rating instruction corrected with red/green replay. | Publish reviewed follow-up receipts/fix through the documentation gate, then await merge approval. |

## Observed problem and solution-fit bet

Existing `/idea` creates new admission-ready issues but expressly excludes retrofitting existing issues (`skills/1-hourly/idea/SKILL.md`). #1401 requests that missing upstream preparation workflow. Existing `prior_art_recon`, PRS pickup, `swarm_preflight.extract_contract` and Jog probe linting already supply the mechanisms. A skill-only composition is the smallest viable bet: instructions perform grounded preparation and publish a task packet, while Jog retains admission and execution. Reversibility: Easy; revert the skill/index entry and any preparation PR separately. No runtime/schema changes or installed app links.

## Recon

See [Recon Map](recon-conveyor.md). Production paths are disjoint from #1400's downstream flywheel instructions. Shared task-local ledger/changelog changes use existing writers and reconciliation. No new source of truth: the capture doc and PRS remain canonical; a readiness label is a discoverability signal, never admission or approval.

## Requirements and boundaries

Deliver `skills/1-hourly/conveyor/SKILL.md` for existing issue IDs, `--prs-min` selection, bounded scheduled batches, and intake/refine event payloads. Reuse `/recon`, prior-art discovery, capture conventions and current JSON contract parser. Require concrete bug-polarity probes, bounded artifacts, current target ref, rating provenance, nonempty extraction, parser and Jog shape/lint checks, and actual preflight verdict. Preparation may write docs/PRS and publish a docs PR, comments and readiness label under invocation authorization, but never production code, execution admission, queue, builder, full gate, daemon or scheduler installation. Scheduler/event setup needs its own explicit request. Avoid claiming the preparation workflow is literally read-only: research is read-only, publication mutates docs/ledger/GitHub.

Conveyor selects work for preparation, so pickup may register a rated row per decision 6, but must not set `--accepted-start`. Preserve provisional PDDA ratings and leave execution review to start-task/Jog. Do not install global skills.

## Rating rationale (2026-11-09)

Proposed 80/65/85/45 is in #1401 authored by operator noelsaw1; retain explicit appeal 85. Use 80/65/85/65 for this bounded skill composition: high priority for observed starvation, severity 65 for preparation stalls without data loss, and cheapness 65 after recon shows no runtime code. Recent-window coverage: 2026-10-26–2026-11-09 versus 2026-10-12–2026-10-25. Concrete related reports include #1232 (Oct 27, parser handoff), #1353 (Nov 7, no-row discovery), and #1401 (Nov 9, intake bottleneck). Earlier #1093 and #1100 concern root pinning, not distinct intake-starvation incidents. Trend unknown: search is bounded and issue reports are not incident counts; no numerical recurrence multiplier. Read-back is the ledger, no competing rank algorithm or override.

## Ordered implementation and verification

1. Add the concise conveyor skill with bounded modes, dedupe/reuse, recon, capture synthesis, canonical PRS writer, probe semantics and publication/readiness handoff -> parser/linter can consume a worked contract; intentionally malformed contract is rejected with no label publication.
2. Add one ARCHITECTURE skills-index row -> linked skill exists; no downstream flywheel or runtime edits.
3. Smoke the consumer instructions with a valid missing-artifact contract at the pinned base and a malformed/empty contract using existing parser/linter in a disposable full clone; also exercise a grep_present probe against paired bug-present/fixed existing-file contents (expect unfixed/landed) and an intentionally inverted grep_absent red control (expect the wrong landed/unfixed pair to expose the mismatch); read the publication/rerun path -> record commands/output/provenance under TESTS-RESULTS/2026-11-09+GH-1401, no live issue labelling during smoke.
4. Run skill quick validation and classified documentation gate; independent final Codex relay QA; publish verified PR against development and issue closeout -> no new suites, registry entries or gate machinery. Retire only safely published owned checkouts through merge-cleanup.

## Acceptance

- [x] Existing issue retrofit reuses its canonical doc/row, with duplicate/already-fixed/ambiguous cases held honestly.
- [x] Contract uses current target/gate/probes/artifacts schema and records unfixed polarity, new-artifact markers, actual preflight result and pinned SHA. Empty/malformed input cannot publish readiness.
- [x] PRS values and operator overrides survive reruns; prep registration is not accepted execution start.
- [x] Readiness follows merged/published preparation availability at the integration ref, approved preparation review and passing applicable docs gate; label does not enqueue/admit and must be revalidated by consumer.
- [x] All three invocation modes reuse existing tools with bounded inputs and no new scheduler or daemon; no production edits or full gate from conveyor.

## Risks and rollback

The label could overstate readiness if published before capture/PRS changes are available to the consumer. Require final integration-ref preflight before label and disclose PR-pending as prepared/pending-publication. Remove stale readiness on a failed refresh only within invocation scope; never rewrite issue body or close issue. Probe commands may execute during preflight, so inspect and use read-only probes; mutating/expensive probes are held for execution verification. Revert the skill/index for workflow rollback; existing schema and readers remain compatible.

## Test non-scope

No new tests, gates, runners, frameworks or registry entries (GH-831). Existing parser/linter manual checks and PDDA gate cover this documentation composition. No manufacturing a factory run or relabelling a live backlog merely to demonstrate the new skill.

## Lessons Learned

NO_ENTRY pending observed evidence; adoption alone does not support a lesson.

## Verification evidence

[Manual checks and provenance](../../TESTS-RESULTS/2026-11-09+GH-1401/SUMMARY.md): parser/Jog shape valid; empty-probe red control exit 3; BUG/FIXED pair and inversion control passed; main preflight READY exit 0 at pinned base, adjacent already-delivered STALE exit 4 at implementation SHA. Skill quick_validate passed. Plan relay [Approved round 2](../../relay-system/2026-11-09/gh1401-plan.codex.md). Classified docs/tier 1; full suite intentionally not run for this route.

Documentation gate `PDDA_ISSUE_SYNC_SOURCE=cache bash utils/pdda/pdda.sh run` exited 0 with no errors and 656 cache/governance/marathon warnings; [summary](../../TESTS-RESULTS/2026-11-09+GH-1401/docs-gate.txt). Final normal push repeats the classified docs gate at the published head.

Final relay [Approved round 2](../../relay-system/2026-11-09/gh1401-final.codex.md), driver exit 0. Round 1 text was invalidated by caller interference (author appended a gate receipt during review); the guard reverted it and the author committed the receipt before the clean recheck. No skill production text changed between final review rounds.

## Publication handoff

[PR #1404](https://github.com/HiQS-Labs/XYZ-forge/pull/1404) targets development. Development advanced during work; existing B1 resolved only the disjoint ledger conflict through canonical verbs in a disposable full clone, preserving current integration Jog state. [Repair receipt](../../TESTS-RESULTS/2026-11-09+GH-1401/ledger-resolution.json). Final QA recheck Approved round 3, driver exit 0. The routine LEADERBOARD.md regeneration from that helper was removed by restoring the exact integration version under parent direction; skill/index bytes remain reviewed and unchanged. Metadata-only verification: leaderboard bytes equal origin/development, diff check clean and PRS check clean.

NO_ENTRY: skill/index and contract checks show no observed production outcome; a lesson based only on this single preparation run would be confounded. Clone retained for the user-requested parent Claude review/follow-up, overriding automatic retirement. Awaiting merge only after that additional review is resolved; no merge performed.

## Additional parent Opus QA

User-requested Claude Code CLI Opus medium review ran serially after PR1403. Round 1 requested explicit first-rating handling for existing unrated rows; parent reproduced pickup leaving NULL axes, then verified canonical rate fills them without force and a rated rerun refuses unchanged. Parent corrected conveyor Step 4, including explicit retained operator override and holds for writer refusals. [Replay](../../TESTS-RESULTS/2026-11-09+GH-1401/opus-qa/unrated-row-replay.json). Optional dry-run repoint Nit declined because exact read-back is already required. [Opus Round 2 Approved, driver exit 0](../../relay-system/2026-11-09/gh1401-opus-medium.md). No runtime changes or new tests/gates.

## Opus-reviewed publication refresh

Development advanced to `995af060`. B1 preview refused because its higher-generation choice would replay two integration Jog changes outside its supported table set. Under the parent-authorized narrow resolution, the disposable gate clone retained the complete integration DB/dump and replayed only GH1401 through existing roadmap verbs, then passed the existing resolver/check. All 37 integration Jog rows match by stable global ID and every non-ID field; owned row semantics and Opus-reviewed skill bytes are unchanged. Generation 2514 meets both parents' floor 2511. Routine leaderboard output equals integration bytes. [Receipt](../../TESTS-RESULTS/2026-11-09+GH-1401/opus-qa/opus-publication-ledger-repair.json).

Accounting remains two repairs total: the earlier actual B1 repair was retrospectively recorded without an advance-reservation claim, and this second/final slot was reserved before mutation. An initial assertion compared derived integer SQLite IDs and stopped after replay; read-only diagnosis proved only documented ID renumbering, and the coordinator authorized completing the same attempt with the stable-ID invariant. Original assertion and refusal receipts are retained, not rewritten. No source edits or further independent round were added during publication refresh.
