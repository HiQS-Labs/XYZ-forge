# Marathon Phase gh292-worktree-discovery
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH292-WORKTREE-DISCOVERY-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/relay-xyz/find-harness.sh,test/gh292-worktree-vendored-discovery.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent codex --paths "phases/vendored-lane-hardening-2026-07-26--gh292-worktree-discovery/RELAY.md,skills/relay-xyz/find-harness.sh,test/gh292-worktree-vendored-discovery.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/vendored-lane-hardening-2026-07-26--gh292-worktree-discovery/RELAY.md and skills/relay-xyz/find-harness.sh,test/gh292-worktree-vendored-discovery.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/relay-xyz/find-harness.sh,test/gh292-worktree-vendored-discovery.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH292-WORKTREE-DISCOVERY-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/vendored-lane-hardening-2026-07-26--gh292-worktree-discovery/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Added one guarded `--git-common-dir` probe after the caller-root `.xyz/` probe, so linked worktrees resolve their main checkout's vendored harness while bare and non-repository callers still fall through unchanged.
- Kept centralized fallback non-fatal; `--check` now identifies an unusable main-checkout vendor and warns that it is falling back to the centralized lock instead of claiming no vendor exists.
- Added and registered `test/gh292-worktree-vendored-discovery.sh`, covering main-checkout control behavior, linked-worktree harness/tick selection, and the actionable fallback warning.
- Verified: `bash test/gh292-worktree-vendored-discovery.sh` — 7 pass, 0 fail.

### Round 1 · Reviewer · agy

**Verdict:** Approved

The implementation correctly resolves the main checkout's vendored `.xyz` directory from a linked worktree by reading the git common directory. The readiness checks properly surface this resolution and correctly warn about the fallback if the vendor is unusable. The `validate.sh` has the new test registered and it executes successfully.
