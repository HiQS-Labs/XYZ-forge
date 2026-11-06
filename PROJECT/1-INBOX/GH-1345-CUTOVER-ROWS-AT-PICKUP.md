---
gh_issue: 1345
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1345
title: "GH-1340 item 2: the cutover, rows at pickup (Tasks 2, 3, 4, 6, 11, 5, 12)"
status: proposed
created: 2026-11-04
owner: unassigned
doc_type: feature
complexity: 5
risk: 4
effort: 5
phases: 1
non_goals:
  - no migration or deletion of the 69 grandfathered rows (D-a)
  - no new test or suite (GH-831)
related:
  - "#1340"
  - "#1344"
  - "#1298"
goal: >
  Ledger rows are created when work starts, with a real rating, and never at filing; discovery
  finds fully specified no-row issues; duplicate guards still hold (decision 6, G6, P3).
updated: 2026-11-04
---

# GH-1340 item 2: the cutover, rows at pickup

## Status

| What was just completed | What's next |
|---|---|
| Split out of #1340 as Jog item 2 (operator, 2026-11-04). Task text and citations are in #1340 Tasks 2, 3, 4, 6, 11, 5, 12. | Runs after #1344 lands; re-ground the plan on that base first. Stops for operator review before merge. |

## Plan

One PR (P3), in #1340's order. Re-check every citation at the base where #1344 has landed.

1. **Task 2.** Remove filing-time row writes (`utils/hq/hq.sh` `roadmap add` call around `:412`, `/file-xyz-bug`, `/idea`), keeping the maintenance writers #1340 lists. Change `roadmap-coverage` (`pdda.sh:404-422`) so a `1-INBOX` capture without a row passes and an active `2-WORKING` doc without one still fails. Update ROUTER.md, AGENTS.md and PDDA's intake contract.
2. **Task 3.** One idempotent pickup writer, reused by conversational Jog, `start-task`, `express` and selection in `start-marathon`/`10days`/`workhorse`. It creates the row once with a real rating, keeps an existing rating and `ovr`, and adopts D-a rows.
3. **Task 11.** One "real rating" definition used for the issue-body proposal and the stored rating; placeholders and legacy 1-5 values never count.
4. **Task 4.** Extend the factory's unregistered path (`utils/py/harness.py` around `:889-912`) and the planner so a fully specified no-row issue is discovered and admitted.
5. **Task 6.** Keep the issue-search, capture-reuse and `UNIQUE(repo_id, gh_number)` guards; reword PDDA's duplicate-guard sentence.
6. **Task 5.** Rewrite #1298's backlog step (issue text, doc, contract; no rows).
7. **Task 12.** `hq park --create` and `/file-xyz-bug` render `/idea`'s sections; add the `umbrella` label; add the monthly metric to the census (not a gate).
8. Witnesses under `TESTS-RESULTS/<date>+GH-1345/` with `provenance.jsonl`.

## Acceptance

- [ ] No filing path inserts a `roadmap_items` row (red/green), and an inbox capture with no row passes coverage while an active doc without one fails.
- [ ] A fresh pickup yields one genuinely rated row; a retried pickup changes nothing.
- [ ] An unstarted, fully specified no-row issue is found and admitted through the normal path, and its row appears only at pickup.
- [ ] A matching open issue is still surfaced before a new one is filed; repeated capture reuses the existing one; two pickups yield one row.
- [ ] A valid proposal admits a no-row issue and becomes its stored rating at pickup; placeholders stay held.
- [ ] #1298's supply step creates no rows.
- [ ] `hq park --create` and `/file-xyz-bug` emit the `/idea` sections.
- [ ] Existing suites pass on the final commit. No new test (GH-831).

## Risk and rollback

Risk: this changes the intake machinery Jog uses. Interim rules C1-C3 stay in force until it merges. Rollback: revert the PR; no schema change is planned (a schema change needs R3 approval).

## PRS proposal

pri 75 / sev 60 / appeal 50 / effort 20 (rationale on #1345).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/hq-park.sh && bash test/pdda-roadmap-coverage.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "utils/hq/hq.sh", "pattern": "roadmap add --issue-num",
      "note": "pre-fix: hq park writes a row at filing; landed when filing no longer calls roadmap add" }
  ],
  "artifacts": [ "utils/hq/hq.sh", "utils/pdda/pdda.sh", "utils/py/harness.py", "utils/py/_marathon_plan.py", "utils/py/releases_app.py" ],
  "remediation": {
    "source": "issue#1345",
    "criteria": "#1340 Tasks 2, 3, 4, 6, 11, 5, 12 as one cutover: no filing-time rows, one idempotent rated pickup writer, discovery of no-row issues via the existing unregistered path, duplicate guards kept. No schema change without approval; no new test (GH-831)."
  }
}
```

## Merge evidence

- PR #1350 merged 2026-11-06 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
