---
title: "Phase brief: GH-292 gh292-worktree-discovery (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-26
updated: 2026-07-26
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh292-worktree-discovery phase of
  MARATHON-2026-07-26-VENDORED-LANE-HARDENING — not itself an active-doc capture; the canonical
  capture doc is GH-292-WORKTREE-VENDORED-DISCOVERY.md one level up.
roadmap_exempt: true
---

# Phase gh292 — `find-harness.sh` must find a vendored `.xyz/` from a linked worktree

Issue: #292 · Capture doc: `PROJECT/2-WORKING/GH-292-WORKTREE-VENDORED-DISCOVERY.md`

## The defect
`.xyz/` is gitignored so it exists only in a repo's main checkout. Driven from a **linked git
worktree**, `find-harness.sh` misses it, silently falls back to the centralized harness, and takes
that clone's global driver lock — the contention vendoring exists to avoid. The error then names an
unrelated process, so the natural diagnosis is wrong.

## Do
1. After the CWD probe fails, probe the main working tree:
   `main_root="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")"`
   then check `"$main_root/.xyz"`. Keep `--path-format=absolute` (older git returns relative).
   Guard bare/absent repos.
2. Correct the readiness message: when the repo IS vendored but unreachable from here, say
   "vendored .xyz found in the main checkout at <path>" — not "no local .xyz/ in this repo",
   which tells the operator to re-vendor an already-vendored repo.
3. Warn when a vendored repo silently falls back to the centralized harness.
4. Add `test/gh292-worktree-vendored-discovery.sh` covering: resolution from a linked worktree,
   and a control asserting main-checkout behaviour is unchanged.
5. **Register the new test in `validate.sh`'s `TESTS=()` array** — validate.sh does not glob
   `test/`, so an unregistered test silently never runs.

## Do NOT
- Redesign the resolution order. Add ONE probe after the CWD probe; leave env → .xyz/ →
  current repo → script-relative otherwise intact.
- Make the centralized fallback an error. It stays the default; only silence and the wrong
  message are defects.

## Acceptance
- Test fails before the fix, passes after (verify with `git stash`).
- Resolution from the main checkout is byte-identical to today.
- A repo with no `.xyz/` still falls back, unchanged.
- `bash validate.sh` green, with the new test actually executing.
