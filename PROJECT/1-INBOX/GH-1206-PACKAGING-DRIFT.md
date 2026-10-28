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

- No predecessor package name remains in package/lock metadata and no missing `main` target remains.
- Node engine matches the README.
- Dry-run contents exclude evidence, state, ledgers, and transcripts.
- All 14 kernel unit tests pass; any declared CLI works from the packed artifact.
- No publish, version bump, or release-tag change occurs.
