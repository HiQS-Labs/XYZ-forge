---
gh_issue: 1295
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1295
title: "factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-31
owner: noelsaw1
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no model-based classifier
  - no new tests (GH-831)
related:
  - #1279
  - #1248
  - #1294
goal: >
  Issue text reaches briefs and launch packets only as quoted data that a builder prompt cannot read as an instruction; a recorded manual round trip on the injection canaries shows it.
---

## Key concepts

- text from issue bodies is copied into briefs
- decide fence-as-data versus strip
- human approval is the only barrier today

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Instruction text injected in an issue body is carried verbatim into plan-draft briefs and launch packets. See the issue for evidence and the proposed fix.

## Why

Found by the #1279 window: injection-canary lanes passed the structure and Marathon dry runs. Nothing executes automatically, but the text reaches future builder prompts and a human approves launch by copying a folder.

## Phase 0 — Explore & scope

### Checklist

- [ ] Inspect `_sections` and `render_brief` in `utils/py/harness.py`.
- [ ] Evaluate fencing options: wrap sourced scope in explicit Markdown code fence or quote block with untrusted data disclaimer.
- [ ] Evaluate pattern filter for common override strings (`IGNORE ALL PREVIOUS INSTRUCTIONS`, `SYSTEM OVERRIDE`).

### QA checklist — Phase 0

- [ ] Sourced issue body instructions cannot be read as instructions by builder prompts in generated briefs.
- [ ] Normal issue bodies render unchanged without regression.
- [ ] No new test files (GH-831).

## Ratings rationale

pri 60 / sev 60 / appeal 50 / effort 70 (deferred by operator until factory-primitive generated packets are run live; preparation unblocks evaluation).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "untrusted_issue_text|sanitize_brief_scope",
      "note": "pre-fix: harness.py does not fence untrusted scope text in briefs" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1295",
    "criteria": "Render sourced issue scope inside explicit untrusted fences or hold brief when instruction patterns match; no new tests (GH-831)."
  }
}
```

## Merge evidence

- PR #1302 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1304 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1324 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
