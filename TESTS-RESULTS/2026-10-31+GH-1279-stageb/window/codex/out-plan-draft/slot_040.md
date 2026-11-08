# Plan draft: #1264 hq park: goal passthrough (HQ_PARK_GOAL), the one capture field a grounded filing still patches by hand

> draft; preflight and independent plan QA outstanding

- Request: `gh-1264-97036ab7714a` (tick `slot_040`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 35/25/50/95
- Capture doc: PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md (sha256 425c08e43d6e622c97c993021b4eff410b23e6efcec48fa59a7bc573be9fbfc1)
- Issue sha256: 97036ab7714a5bf66a3488d9d7af6358ebb0808a2cc4e4f77aff8e47f1fc5530 (updated 2026-10-30T16:52:54Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:L35 (hq park: goal passthrough (HQ_PARK_GOAL), the one capture field a grounded filing still patches by hand)_

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

## Diagnosis / ex

_Source: PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:L128 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:L21 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

_Source: codex-authored (codex-authored)_

Verify the current issue and implementation state before identifying remaining work.

_Source: codex-authored (codex-authored)_

Add optional goal passthrough to hq park preview and creation, and document the field in the hq skill.

_Source: codex-authored (codex-authored)_

Keep the idea skill change outside this work.

## Acceptance criteria

_Source: issue#1264:L35 (Acceptance)_

- [ ] `HQ_PARK_GOAL=$'Done means X.\nSecond line.' bash utils/hq/hq.sh park --title "probe" XYZ-forge "probe body"` (preview, exit 0, non-empty output) renders `goal: >` followed by `  Done means X.` and `  Second line.` (both lines indented) and no `TODO` in the goal field. Red control: the same command on the base renders the TODO stub (recorded).
- [ ] With `HQ_PARK_GOAL` unset, the preview output is byte-identical to the base's preview for the same arguments (both exit 0, both non-empty, `diff` empty; recorded). An empty pair does not pass.
- [ ] `bash test/hq-park-synthesis.sh` and `bash test/hq-park.sh` pass on the final commit.

_Source: PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:L79 (Acceptance)_

- [ ] `HQ_PARK_GOAL=$'Done means X.\nSecond line.' bash utils/hq/hq.sh park --title "probe" XYZ-forge "probe body"` (preview, exit 0, non-empty output) renders `goal: >` followed by `  Done means X.` and `  Second line.` (both lines indented) and no `TODO` in the goal field. Red control: the same command on the base renders the TODO stub (recorded).
- [ ] With `HQ_PARK_GOAL` unset, the preview output is byte-identical to the base's preview for the same arguments (both exit 0, both non-empty, `diff` empty; recorded). An empty pair does not pass.
- [ ] `bash test/hq-park-synthesis.sh` and `bash test/hq-park.sh` pass on the final commit.

_Source: codex-authored (codex-authored)_

A multiline HQ_PARK_GOAL renders as a folded scalar with every line indented two spaces.

_Source: codex-authored (codex-authored)_

With HQ_PARK_GOAL unset, a nonempty preview is byte-identical to the base preview; record both preview witnesses and their provenance.

_Source: codex-authored (codex-authored)_

The existing hq park synthesis and hq park suites pass on the final commit.

## Open questions

_Source: codex-authored (codex-authored)_

Have the goal passthrough or related changes landed since the recorded development commit?

## Write set

- `utils/hq/hq.sh` (PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:preflight-contract)
- `utils/hq/hq-lib.sh` (PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:preflight-contract)
- `skills/2-daily/hq/SKILL.md` (PROJECT/1-INBOX/GH-1264-HQ-PARK-GOAL-PASSTHROUGH.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_absent `utils/hq/hq.sh`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/hq/hq.sh",
    "utils/hq/hq-lib.sh",
    "skills/2-daily/hq/SKILL.md"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: cmd_park has no ${HQ_PARK_GOAL:-} read; a bare mention in a comment does not satisfy it",
      "path": "utils/hq/hq.sh",
      "pattern": "\\$\\{HQ_PARK_GOAL:-\\}",
      "type": "grep_absent"
    }
  ],
  "gate": "bash test/hq-park-synthesis.sh",
  "remediation": {
    "criteria": "17th optional goal parameter in hq_render_capture (empty keeps today's bytes), HQ_PARK_GOAL read in cmd_park and passed at both call sites, field listed in the hq skill. No new test (GH-831).",
    "source": "issue#<this>"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
