---
gh_issue: 1206
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1206
title: "Audit E: correct package identity entrypoint and contents"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: plan
effort: 1
complexity: 2
risk: 1
phases: 4
rating: "pri/sev/appeal/effort 50/30/65/90 · calc 235"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1201
goal: Align npm metadata with XYZ Forge and explicitly bound package contents without publishing or changing the release version.
---

# GH-1206 — Package metadata and contents

## Quad Concepts

- Package identity and entry point drifted from the product → correct package/lock metadata and remove the nonexistent library entry.
- Implicit npm contents include historical artifacts → explicit minimal package allowlist and dry-run verification.

## Verified drift

`package.json` and `package-lock.json` still use `xyz-3-agents-swarm`; `main` names a nonexistent root `index.js`; the documented Node 18+ baseline is absent from `engines`. `npm pack --dry-run --json` reports 35.6 MB compressed / 150.4 MB unpacked, including historical artifacts because no explicit package allowlist exists.

## Phases

1. Declare the supported package purpose and remove the nonexistent library `main` rather than redirecting it arbitrarily.
2. Rename package and lock metadata to `xyz-forge` and declare the documented Node engine; do not change the version.
3. Add a minimal explicit package allowlist. Declare `bin/tick` only if npm CLI installation is intentionally supported and tested.
4. Verify with unit tests and package dry-run; if declaring a CLI, install the artifact in a temporary directory and exercise it. Do not publish.

## Acceptance

- [ ] No stale predecessor package name remains in package/lock metadata.
- [ ] No `main` entry references a missing file.
- [ ] Metadata declares the same Node baseline as the README.
- [ ] The dry-run package contains only intentional assets and excludes evidence, runtime state, ledgers, and transcripts.
- [ ] The 14 kernel unit tests still pass, and any declared CLI works from the packed artifact.
- [ ] No npm publish, version bump, or release-tag change occurs.
- [ ] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Acceptance — deviations from the issue

- [added] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only. — reason: operator-authorized bounded trial constraints.
- [added] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths. — reason: operator-authorized bounded trial constraints.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Trial execution scope

Correct package identity, missing main, Node baseline and intentional package contents without publishing, installing, version bump or new tests. Preserve unrelated files. Two builder attempts maximum. Capture baseline/final controls, no new test suite.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "package.json",
      "pattern": "xyz-3-agents-swarm"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1206/manual.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl"
    }
  ],
  "artifacts": [
    "package.json",
    "package-lock.json",
    "TESTS-RESULTS/2026-11-10+GH-1206/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-10+GH-1206/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1206",
    "criteria": "Correct package identity, missing main, Node baseline and intentional package contents without publishing, installing, version bump or new tests."
  },
  "lanes": {
    "agy_safe": [
      "package.json",
      "package-lock.json",
      "TESTS-RESULTS/2026-11-10+GH-1206/manual.md",
      "TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl"
    ],
    "orchestrator_only": []
  },
  "round_cap": 1
}
```

## Merge evidence

- PR #1402 merged 2026-11-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
