---
title: "GH-672: fix(skills): one Pulse collection per device and consistent deployment SOP"
status: Active
created: 2026-09-17
updated: 2026-09-17
owner: operator (via /express)
gh_issue: 672
source: https://github.com/HiQS-Labs/XYZ-forge/issues/672
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): fix(skills): one Pulse collection per device and consistent deployment SOP
---

# GH-672 — fix(skills): one Pulse collection per device and consistent deployment SOP

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/skills-army-hq.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #672 closes |

## Acceptance Criteria

- [x] Regression suite test/skills-army-hq.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem deployment change qualifies for express with explicit bounds (8 core files / 300 insertions; ROUTER default-path correction included).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: One Pulse payload collection per device; device-local ignored receipts and direct app symlinks. Preserve the SOP in the manager bundle and publish the generated mini.

## Recon Map — existing collection adoption

Source baseline: `011113f64bf60da1c93ab97c37c70c760f2dbb56`. One bounded local lane;
graph generation was stale and lacked this package, so exact source reads were used.

- Entry: `intake.main` → `init` required an empty root and refused running from the installed
  manager inside the root. `catalog` and `sync.main` both required existing receipts via `load`.
- State: `transact` → `finish` owns receipts, targets, catalog, history, and the root README.
  Reuse it for adoption with no payload/link actions; ignore all machine state before writes.
- Links: `sync.reconcile` targets the one supplied root and protects foreign entries.
  Pulling new bytes changes app read-through without copying or retargeting existing links.
- Defaults: intake and sync independently selected Documents. Share the Pulse default resolver;
  explicit roots and environment overrides remain supported for legacy recovery/custom setups.
- Distribution: `xyz_mini_sync` maps the entire tracked skill folder onto the mini root.
  Whole-folder intake copies the same SOP into Pulse and refreshes its top-level README.
- Failure/rollback: adoption refuses dirty or unprotected transport and foreign local state;
  existing transaction recovery stays authoritative. Old device collections require preservation
  and explicit target withdrawal before retirement; this task migrates no unseen device.
- Verification: existing registered `test/skills-army-hq.sh` exercises two independent Git
  checkouts, preview non-mutation, distinct local identities, direct links and pull read-through.
  A pre-fix implementation must fail the new tests. No real second device is accessible here.

## Publication scope

Land Forge via express, then refresh only this manager through intake; publish the Pulse SOP and
machine-state exclusion correction without including unrelated skills. Publish the mini with the
existing parent-owned publisher, then verify source revision and file equality.
