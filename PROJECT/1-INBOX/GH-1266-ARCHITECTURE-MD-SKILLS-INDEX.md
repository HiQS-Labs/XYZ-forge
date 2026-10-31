---
gh_issue: 1266
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1266
title: "ARCHITECTURE.md Skills Index drift: weekly-planner has no row and the hand-typed tier counts are stale"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no generator
  - no new suite or gate
  - no re-enabling retired suites
  - no README edit
related:
  - GH-744
  - GH-660
  - #1258
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- add the weekly-planner row before weekly-shipped
- delete the four (N) counts
- ARCHITECTURE.md only

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# ARCHITECTURE.md Skills Index drift: weekly-planner has no row and the hand-typed tier counts are stale

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| A skill folder has no Skills Index row | `for d in skills/3-weekly/*/; do grep -q "(skills/3-weekly/$(basename $d)/SKILL.md)" ARCHITECTURE.md \|\| echo $d; done` | `skills/3-weekly/weekly-planner/` (has `SKILL.md` and `scripts/`) has no row |
| The hand-maintained tier counts are stale | headers at `ARCHITECTURE.md:49,72,102,124` vs `ls -d skills/<tier>/*/ \| wc -l` | `1-hourly` says 15, has 16 folders; `3-weekly` says 15, has 16 folders and 15 rows; `2-daily` 23/23 and `4-occasional` 20/20 agree |
| No active check catches either | `test/gh660-skill-drift.sh:10-19`; `skills/README.md:21-24`; `test/gh778-review-code-skill.sh:46`, `test/gh798-status-skill.sh:42` (both disabled, `test/gh306-registry-bidirectional.sh:59-60`) | gh660 runs on synthetic fixtures; two retired suites grep the `2-daily` count but are turned off; the only live catch is the review checklist line "The Skills Index row is part of the change" (witnessed on #1258: a scratch copy with a row deleted is flagged by nothing) |

## Diagnosis / existing gap

The Skills Index row is required on every skill add or move (`skills/README.md:21-24`); the per-tier counts are typed by hand with no rule asking for them anywhere. A count is a second copy of a fact the directory listing already holds, so it drifts the moment one PR forgets it, and a missing row is invisible until someone looks for the skill. One instance each (one missing row, two stale counts).

## Plan

1. `ARCHITECTURE.md`: add the `weekly-planner` row in the `3-weekly` table, alphabetical (before `weekly-shipped`, `:120`), with its one-line purpose taken from `skills/3-weekly/weekly-planner/SKILL.md:3`.
2. `ARCHITECTURE.md:49,72,102,124`: delete the `(N)` counts from the four tier headers. A number nobody computes is not worth keeping in sync; the listing is the count. (#1258's PR corrects the `1-hourly` count to 17 in passing; this change removes it along with the other three, so land this after #1258 or rebase over it.)

## Blast radius

| Seam | Where | What changes |
|---|---|---|
| Skills Index | `ARCHITECTURE.md:49-140` | one row added, four header counts removed |
| Consumers of the index | `skills/README.md:13` (points here); Skills Army HQ reads folders, not the index | none |

Recon `e305cbf3`; base `development@e305cbf3`. Write-set: `ARCHITECTURE.md`, `TESTS-RESULTS/<date>+GH-<this>/` (`skills/README.md` says nothing about counts; no edit). Route: docs (`utils/pdda/pdda.sh run`). Builder: any; reviewer: Codex relay.

## Dependencies

Land after #1258's Phase 1 PR (it edits the `1-hourly` header line) or rebase over it. Related: GH-744 (tier folders), GH-660 (drift suite on fixtures).

## Acceptance

- [ ] For every tier, `ls -d skills/<tier>/*/ | wc -l` is positive and equals `grep -c "(skills/<tier>/" ARCHITECTURE.md` (recorded for all four with the actual numbers; a 0 = 0 pair does not pass). Red control: on the base, `3-weekly` gives 16 vs 15 (recorded).
- [ ] `grep -c '(skills/3-weekly/weekly-planner/SKILL.md)' ARCHITECTURE.md` is 1. Red control: base gives 0.
- [ ] `grep -cE '^### `[0-9]-[a-z]+`.*\([0-9]+\)$' ARCHITECTURE.md` is 0 (no counts left) **and** `grep -cE '^### `[0-9]-[a-z]+` — [^(]+$' ARCHITECTURE.md` is 4 (the four count-free headings are present, so an empty file cannot pass). Red control: base gives 4 and 0 respectively (recorded).
- [ ] `bash utils/pdda/pdda.sh run` passes on the final commit.

## Verification

Docs route: `bash utils/pdda/pdda.sh run` (existing). The greps are manual checks recorded under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl` in the same PR. No new test (GH-831): the counts are removed rather than guarded.

## Non-goals

No generator for the index; no new suite or gate; no re-enabling of the two retired suites; no re-tiering of any skill; no description edits beyond the one new row; no `skills/README.md` edit.

## Risk and rollback

Risk: none beyond a merge conflict with #1258 on the `1-hourly` header line (one-line resolution). Rollback: revert the commit.

## PRS proposal

- pri 30: a discoverability defect in the canonical index, not a runtime one.
- sev 20: one skill is invisible in the index; nothing fails.
- appeal 50: operator did not set a preference.
- effort 95: one row, four deletions, one doc touch.

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash utils/pdda/pdda.sh run",
  "fix_probes": [
    { "type": "grep_absent", "path": "ARCHITECTURE.md", "pattern": "skills/3-weekly/weekly-planner/SKILL.md",
      "note": "pre-fix: no weekly-planner row; landed when the row exists" }
  ],
  "artifacts": [ "ARCHITECTURE.md" ],
  "remediation": {
    "source": "issue#<this>",
    "criteria": "Add the weekly-planner row before weekly-shipped; delete the four hand-maintained tier counts; ARCHITECTURE.md only; no generator, no new test (GH-831). Land after #1258 Phase 1 or rebase over it."
  }
}
```

Recon: e305cbf3 · base: development@e305cbf3 · tier: standard · review: consult relay-system/2026-10-30/gh-idea-E-draft-114323 models=codex,agy hash 3327df73324bab063cf0a22d828aed1ccee9d692da66a6c3aee6c5cf67128016

## Why

One skill folder is invisible in the canonical index and two of four tier counts are wrong; nothing active catches either, only the review checklist.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

## Merge evidence

- PR #1268 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
