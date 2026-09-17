---
title: "GH-672: fix(skills): one Pulse collection per device and consistent deployment SOP"
status: Complete
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
| Express hotfix landed; 33 tests passed; Pulse and mini published and verified; scoped reconciliation completed | Other devices follow the bundled in-place adoption/migration SOP |

## Acceptance Criteria

- [x] Regression suite test/skills-army-hq.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem deployment change qualifies for express with explicit bounds (8 core files / 300 insertions; ROUTER default-path correction included).

## Merge evidence

- Forge landing: `6402944968cff1d2231aacbdbfe5604ba5d818e2`; express receipt committed by `6d91ed8ff4fe71164b1bdef070161a90dc713f07`.
- Pulse publication: `ad3a275adcadb548c3a4f2aabec5c3a5e8556899`; local catalog/history preserved and untracked.
- Skills Army mini: `bbf9a92a381048eda05e199338408a6d49888494`; generated from landed Forge `6d91ed8ff4fe71164b1bdef070161a90dc713f07`.
- Both projection payloads match all six package files and executable modes; six managed manager links resolve directly into Pulse. The existing mini publisher/detached-package suite passed 28 checks.
- Hosted reconciliation run `35250738446` was already running on pre-hotfix `011113f6` for over an hour. Its one fast-forward push cannot overwrite the new head. Used the documented `--force-local-reconcile` fallback scoped to this landing, with its committed express receipt; no hosted job was canceled.
- Evidence: `TESTS-RESULTS/2026-09-17+GH-672/provenance.jsonl` and `TESTS-RESULTS/2026-09-17+GH-672-express/provenance.jsonl`. Full validation was not run; qualification used the express suite.

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the committed TESTS-RESULTS receipts for the
  qualification and the scoped reconciliation evidence above. Operator-supplied summary: One Pulse payload collection per device; device-local ignored receipts and direct app symlinks. Preserve the SOP in the manager bundle and publish the generated mini.

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
