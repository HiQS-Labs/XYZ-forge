---
title: "validate.sh can be green while CI tier1 is red — the local suite tests the PDDA checker, not the repo's own docs"
status: "Active (2-WORKING) — promoted 2026-07-27 by the /10days sweep. Gap re-verified live: validate.sh registers only pdda-roadmap-coverage.sh and never invokes pdda.sh run. Preflight contract below is LIVE."
created: 2026-07-27
updated: 2026-07-27
owner: unassigned
gh_issue: 311
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/311
doc_type: bugfix
complexity: 1
risk: 3
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Changing utils/pdda/pdda.sh itself, or any of its individual checks.
  - Changing .github/workflows/ci.yml — the CI side is already correct; the LOCAL gate is the gap.
  - Turning PDDA findings into hard blockers where they are currently advisory.
related:
  - validate.sh (TESTS array)
  - .github/workflows/ci.yml (tier1 runs `utils/pdda/pdda.sh run` directly)
goal: >
  `bash validate.sh` — the documented local gate, and the default `--pre-advance-cmd` for a
  marathon phase — is a superset of what CI tier1 enforces for the PDDA doc contract, so a
  green local run cannot be followed by a red tier1 on deterministic doc errors.
---

# GH-311 — `validate.sh` green while CI tier1 red

## Status
| What was just completed | What's next |
|---|---|
| Selected by the 2026-07-27 `/10days` sweep. Gap **re-verified in live source**: `validate.sh:101` registers only `pdda-roadmap-coverage.sh`, which builds synthetic fixture `PROJECT/` trees under `$WORK` and runs the checker against *those* — never against this repo's real `PROJECT/` + `ROADMAP.md`. `grep -n 'pdda.sh run' validate.sh` → 0 matches, while `.github/workflows/ci.yml:74` runs `utils/pdda/pdda.sh run` directly. | Fire the contract below. The issue's own "simplest" direction is to register `utils/pdda/pdda.sh run` in `validate.sh`'s `TESTS`; a thin named `test/pdda-repo-contract.sh` wrapper is preferred so a failure attributes to a named test rather than a bare script. |

## Symptom

`bash validate.sh` reports a full green (e.g. 126/126) while CI tier1 fails with deterministic PDDA
doc-contract errors against the repo's actual content. Observed concretely on PR #309: **7 real
errors** (missing `## Status` tables, working docs with no ROADMAP pointer) that `validate.sh`
never saw.

## Mechanism

The two gates are structurally different, not merely differently configured:

- **Local:** `validate.sh` → `test/pdda-roadmap-coverage.sh` → runs the checker against **synthetic
  fixtures** it constructs in a temp dir. It verifies *the checker works*.
- **CI tier1:** `utils/pdda/pdda.sh run` → runs the checker against **this repo's real
  `PROJECT/`/`ROADMAP.md`**. It verifies *the repo's docs comply*.

Passing the first says nothing about the second.

## Why this is worth fixing despite being "just docs"

`validate.sh` is the default gate a marathon phase advances on (`--pre-advance-cmd`). A lane gated
on it will **advance and report success** on work whose PR is then red in CI — a false-positive
local signal. This repo's own skills (`marathon-triage`, `10days`, `pdda-eod`) all treat
"validate.sh green" as a trustworthy proxy for "safe to advance," so the gap silently weakens every
one of them. Same failure shape as GH-307.

**Sequencing note:** this lane is scheduled FIRST in the marathon precisely because every later
lane's gate is only as trustworthy as this fix makes it.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "validate.sh", "pattern": "pdda-repo-contract|pdda\\.sh run" },
    { "type": "path_absent", "path": "test/pdda-repo-contract.sh" }
  ],
  "artifacts":   [
    "validate.sh",
    "test/pdda-repo-contract.sh"
  ],
  "artifacts_new": [ "test/pdda-repo-contract.sh" ],
  "remediation": {
    "source":   "issue#311",
    "criteria": "bash validate.sh exercises utils/pdda/pdda.sh run against the repo's REAL PROJECT/ + ROADMAP.md content, so the deterministic PDDA doc-contract errors CI tier1 catches are caught locally first. Failures attribute to a named test. The existing synthetic-fixture test (test/pdda-roadmap-coverage.sh) is retained unchanged — it tests the checker, which is still worth testing. Verified by deliberately introducing a doc-contract violation and confirming validate.sh goes red."
  },
  "lanes":       {
    "agy_safe":          [ "test/pdda-repo-contract.sh" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

## Phase 1 — Make the local gate a superset

### Checklist

- [ ] Confirm the current divergence by running both gates and diffing their verdicts
- [ ] Add `test/pdda-repo-contract.sh` wrapping `utils/pdda/pdda.sh run`
- [ ] Register it in `validate.sh`'s `TESTS` array
- [ ] Prove it: introduce a deliberate doc-contract violation, confirm `validate.sh` goes red, revert

### QA checklist — Phase 1

- [ ] `test/pdda-roadmap-coverage.sh` is retained and still passes (it tests a different thing)
- [ ] A red PDDA contract now fails `validate.sh` locally, verified by deliberate violation — not assumed
- [ ] The new test does not mutate the repo's real `PROJECT/` content when it runs
- [ ] Advisory-vs-blocking semantics of PDDA findings are unchanged (non-goal respected)
