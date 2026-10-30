---
gh_issue: 1264
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1264
title: "hq park: goal passthrough (HQ_PARK_GOAL), the one capture field a grounded filing still patches by hand"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - no other new fields
  - no YAML lib
  - no idea-skill change in this PR
related:
  - GH-164
  - #1258
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- hq_render_capture 17th optional param
- HQ_PARK_GOAL read in cmd_park
- empty keeps today's bytes
- hq skill field list

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# hq park: goal passthrough (HQ_PARK_GOAL), the one capture field a grounded filing still patches by hand

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| The capture's `goal:` is always a TODO stub | `sed -n 470,476p utils/hq/hq-lib.sh` | `goal: >` / `TODO: one-paragraph statement of what "done" looks like for this idea.` is hard-coded in `hq_render_capture`; the function takes 16 parameters and none is a goal (`hq-lib.sh:423-427`) |
| The front end cannot pass one | `sed -n 217,232p utils/hq/hq.sh` | `cmd_park` reads `HQ_PARK_WHY/KEY_CONCEPTS/NON_GOALS/RELATED/COMPLEXITY/RISK/EFFORT/PHASES`; no `HQ_PARK_GOAL` |
| It costs a hand edit on every grounded filing | #1258 Phase 1 intake commit `a5e03bf1` on `feat/XYZ-forge-gh1258-idea-skill-2026-10-30` (unmerged sibling PR; one observed instance) | the capture rendered for #1258 shipped `goal: TODO` and was patched by hand before commit, although the request already carried an `## Outcome` paragraph |
| The idea skill (#1258) has the text at filing time | `skills/1-hourly/idea/SKILL.md` Step 7 | it exports every `HQ_PARK_*` field from the recon; the goal paragraph is the one field with nowhere to go |

## Diagnosis / existing gap

GH-164 Phase 1 added the synthesis passthrough for why, key concepts, non-goals and related (`hq.sh:217-222`, `hq-lib.sh:415-418`) and left `goal` as a stub for the operator. Now that a front end exists, the stub is the only frontmatter field a grounded filing still has to patch by hand. One instance; the extension point is the existing optional-parameter tail of `hq_render_capture`.

## Plan

1. `utils/hq/hq-lib.sh` `hq_render_capture`: 17th optional parameter `goal` (`${17:-}` at the existing optional tail); when empty, emit the existing TODO stub byte for byte (`:473-474`), else `goal: >` followed by the text with **every line** indented two spaces (the folded-scalar rule the stub uses). Update the function's header comment (`:408-420`, "8 trailing params" → 9, add the field).
2. `utils/hq/hq.sh` `cmd_park`: read `HQ_PARK_GOAL` beside the other `HQ_PARK_*` reads (`:229-230`), pass it as the 17th argument in both the preview call (`:294`) and the create call (`:323`); add it to the comment block (`:217-222`) and to the `usage()` field list (`:41-42`).
3. `skills/2-daily/hq/SKILL.md:65-66`: add `HQ_PARK_GOAL` to the listed fields. `skills/1-hourly/idea/SKILL.md` Step 7 exports it once this lands (separate PR, after #1258 merges).

## Blast radius

| Seam | Where | What changes |
|---|---|---|
| `hq_render_capture` optional tail | `utils/hq/hq-lib.sh:423-427`, `:473-474` | one more optional parameter; empty keeps today's bytes |
| `cmd_park` env passthrough | `utils/hq/hq.sh:217-232`, `:294`, `:323` | one more read, two call sites |
| hq skill field list | `skills/2-daily/hq/SKILL.md:65-66` | one token |
| Other `hq_render_capture` callers | `grep -rn hq_render_capture` (cmd_park preview/create only, plus tests) | positional tail unchanged for them |

Recon `e305cbf3`; base `development@e305cbf3`. Write-set: `utils/hq/hq-lib.sh`, `utils/hq/hq.sh`, `skills/2-daily/hq/SKILL.md`, `TESTS-RESULTS/<date>+GH-<this>/`. Route: subsystem `hq` (`utils/ci-route.sh` `subsystem_of`), focused suite `test/hq-park-synthesis.sh`. Builder: Codex or agy headless; reviewer: Codex relay.

## Dependencies

None. Related: GH-164 (the passthrough this extends), #1258 (consumer).

## Acceptance

- [ ] `HQ_PARK_GOAL=$'Done means X.\nSecond line.' bash utils/hq/hq.sh park --title "probe" XYZ-forge "probe body"` (preview, exit 0, non-empty output) renders `goal: >` followed by `  Done means X.` and `  Second line.` (both lines indented) and no `TODO` in the goal field. Red control: the same command on the base renders the TODO stub (recorded).
- [ ] With `HQ_PARK_GOAL` unset, the preview output is byte-identical to the base's preview for the same arguments (both exit 0, both non-empty, `diff` empty; recorded). An empty pair does not pass.
- [ ] `bash test/hq-park-synthesis.sh` and `bash test/hq-park.sh` pass on the final commit.

## Verification

Existing suites `test/hq-park-synthesis.sh` and `test/hq-park.sh` (GH-831: no new tests). The two preview witnesses are manual checks recorded under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl` in the same PR.

## Non-goals

No other new frontmatter fields; no YAML library; no change to `hq promote`'s goal handling (`hq-lib.sh:526,537` already preserve an existing `goal:`); no change to the idea skill in this PR.

## Risk and rollback

Risk: a goal text containing a line that starts at column 0 would break the folded scalar; the stub's two-space indent is applied to every line of the value. Rollback: revert the commit; captures already rendered keep their text.

## PRS proposal

- pri 35: a hand edit per grounded filing, not a blocker; worth doing now that a front end exists.
- sev 25: cosmetic debt in the capture doc; nothing is lost or misrouted.
- appeal 50: operator did not set a preference.
- effort 95: one optional parameter, two call sites and two doc lines in an existing passthrough, covered by an existing suite.

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/hq-park-synthesis.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/hq/hq.sh", "pattern": "\\$\\{HQ_PARK_GOAL:-\\}",
      "note": "pre-fix: cmd_park has no ${HQ_PARK_GOAL:-} read; a bare mention in a comment does not satisfy it" }
  ],
  "artifacts": [ "utils/hq/hq.sh", "utils/hq/hq-lib.sh", "skills/2-daily/hq/SKILL.md" ],
  "remediation": {
    "source": "issue#<this>",
    "criteria": "17th optional goal parameter in hq_render_capture (empty keeps today's bytes), HQ_PARK_GOAL read in cmd_park and passed at both call sites, field listed in the hq skill. No new test (GH-831)."
  }
}
```

Recon: e305cbf3 · base: development@e305cbf3 · tier: standard · review: consult relay-system/2026-10-30/gh-idea-G-draft-114744 models=codex,agy hash bc888d9bba09b8a686cf5c6d0168f5f0e8213b22e8b4355b55ededafc910bfb8

## Why

GH-164's passthrough covers why/key concepts/non-goals/related but not goal, so every grounded filing (idea skill, #1258) ships goal: TODO and patches it by hand.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
