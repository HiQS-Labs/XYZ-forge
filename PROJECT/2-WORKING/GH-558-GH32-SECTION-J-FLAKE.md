---
gh_issue: 558
source: https://github.com/HiQS-Labs/XYZ-forge/issues/558
title: "gh32-releases-app section J is ~24% flaky: merge rebuild intermittently leaves a generation-trio mismatch"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-21
owner: unassigned
doc_type: capture
complexity: 2
risk: 1
effort: 1
rating: "pri/sev/appeal/effort 90/60/90/90 · calc 330"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  Section J of test/gh32-releases-app.sh stops flaking: the cause is stated, the fixture no longer
  unions two dumps that carry conflicting `generation` rows, and the post-rebuild check output is
  visible on failure.
---

# GH-558 — gh32-releases-app section J is ~24% flaky: merge rebuild intermittently leaves a generation-trio mismatch

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`test/gh32-releases-app.sh:334` builds the merged dump by a byte-level union (`awk '!seen[$0]++'`)
of two dumps that each carry a `generation` settings row; when the two sides straddle a second the
rows differ, the rebuild refuses the duplicate setting, and `:337` swallows the `check --rebuild`
output through `rout`. GH-686 fixed the identical class in the gh53 sibling
(PROJECT/3-COMPLETED/GH-686-GH53-FIXTURE-FLAKE.md) and left section J untouched. No fix commit or PR
references #558.

## Suggested acceptance criteria

- [ ] The cause is identified as fixture or product, and stated.
- [ ] `bash test/gh32-releases-app.sh` passes 25 consecutive runs on `development`.
- [ ] If the cause is (2), a dedicated regression test pins the generation stamp through `check --rebuild` on a merged dump, with a red control that removes the stamp and observes the failure.
- [ ] The post-rebuild `check` output is no longer swallowed by `rout` in the failure path, so the next person does not have to instrument the suite to see the error.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "test/gh32-releases-app.sh",
      "pattern": "j-b/releases\\.sql\" \\| awk '!seen\\[\\$0\\]\\+\\+'"
    }
  ],
  "artifacts": [
    "test/gh32-releases-app.sh"
  ],
  "remediation": {
    "source": "issue#558",
    "criteria": "Fix the section-J fixture union so the generation trio stays consistent, surface check output on failure, prove 25 green runs"
  },
  "lanes": {
    "agy_safe": [
      "test/gh32-releases-app.sh"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
