---
title: "p4 brief — drift-brief path-existence filter (#374)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  Stop prepending stale cross-repo drift-registry entries into builder prompts.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/374
---

# p4 — drift filter

Read the capture doc first:
`PROJECT/2-WORKING/GH-374-DRIFT-REGISTRY-CROSS-REPO-NOISE.md`.

`rtl_drift_brief` (in `relay-automation/relay-turn-lib.sh`, mirrored in
`utils/py/rtl.py`) prepends unread dependency-drift heads-ups into the builder's prompt.
Observed 2026-09-01 in an LTVera-Pandas run: repeated
`dependency.drift — agy changed src/project.js (0 lines)` for a file that does not exist
in the driven repo — leftovers from another repo's registry.

Fix: at read time, keep only entries whose path exists in the driven repo
(`git cat-file -e HEAD:<path>` or a filesystem check against the turn root — pick one,
document it in a comment). Namespacing the registry per repo is the deeper fix; the
path-existence filter is the small one this phase ships — if the registry format makes
namespacing trivial, do that instead and say so in the relay block.

Test: `test/gh374-drift-path-filter.sh` — seed a fixture registry with one entry whose
path exists and one whose path does not; assert the brief includes only the former
(`test/relay-dep-drift.sh` is the existing drift test to extend or sit beside).

## Constraints

- Leave a `GH-374` marker in relay-turn-lib.sh at the change site (the preflight probe
  keys on it). Bash/Python lanes stay behaviorally identical.
- Gate: `bash validate.sh`. In-turn, run only the new test plus files you edit.
