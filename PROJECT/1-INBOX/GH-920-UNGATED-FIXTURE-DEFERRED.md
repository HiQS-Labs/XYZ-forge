---
gh_issue: 920
source: https://github.com/HiQS-Labs/XYZ-forge/issues/920
title: "Deferred: ungated warning fixture copy failure"
status: "Proposed (1-INBOX — deferred by operator policy)"
created: 2026-10-02
doc_type: bugfix
---

# Deferred ungated warning fixture copy

Observed during #854 disposition publication at dc0d533b8489e555ee33c8795c58e0ec98001caf on 2026-10-02 05:51 UTC: gh4-ungated-clone-warning.sh failed before any product assertion: `could not create a scratch copy of this repo for isolation` (0 pass/1 fail). Full gate stopped immediately, identity intact, no retry or publication. Separate focused run passed 6/0; temporarily retaining cp stderr yielded an empty error log. Original suite restored byte-for-byte.

The suite recursively copies the live caller tree, including transient state, and suppresses cp stderr. Exact failing path/errno remains unknown; a disappearing-file race is only a hypothesis. Post-failure disk had 29 GiB available; that does not prove capacity during the failed copy.

Disposition under AGENTS/#853: this flaky suite is outside SUBSYSTEM_TESTS_small. Remove its TESTS entry, add explicit gh306 exemption, retain suite and warning/hook runtime unchanged. Implementation belongs to #854. This deliberately reduces automatic coverage of the first-run warning; it does not disable pre-push enforcement or resolve the historical setup failure.

DEFER investigation until a supported fresh-clone workflow actually loses its missing-hook warning, blocks validation unexpectedly, or hook installation fails. At that point capture the exact copy error or failing product assertion in isolation. Another universal-pool setup failure alone is not a reason to restart a broad campaign. Do not add new suites or machinery. Do not count this failed attempt toward stabilization.

Canonical list: https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783
Original implemented behavior remains tracked by closed #4; this is the distinct test-fixture follow-up. Searches for the suite name and scratch-copy error found no matching open defect.

Tracking-ID: ci-disposition-gh4-copy-20261002


## Intake rating
15/30/50/75; test setup failure, no product assertion failed; investigation deferred.
