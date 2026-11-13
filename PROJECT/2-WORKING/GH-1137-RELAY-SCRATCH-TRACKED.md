---
gh_issue: 1137
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1137
title: "relay: end-of-turn .relay-scratch sweep deletes host-tracked files (rm -rf in rtl_enforce/rtl_check)"
status: "Active (fix implemented and manually verified; full gate pending)"
updated: 2026-11-12
goal: "Relay turns discard only the scratch they created; host-tracked files under .relay-scratch/ are kept"
owner: Claude Code
created: 2026-11-12
doc_type: bugfix
reversibility: "Easy — two lines in relay-automation/relay-turn-lib.sh; revert restores the blanket sweep."
---

# GH-1137 · `.relay-scratch` sweep deletes host-tracked files

Capture of [#1137](https://github.com/HiQS-Labs/XYZ-forge/issues/1137). The live issue holds the
original report (2026-10-18) and the 2026-11-12 recurrence with a deterministic repro.

## Status

| What was just completed | What's next |
|---|---|
| Plan consulted (Codex + Kimi; agy quota-exhausted). Full gate 406/408 then both failures resolved (package refreshed; live suite 4/4 with codex). Fix in `relay-turn-lib.sh` (`git clean -ffdxq` at both sweep sites; tracked paths fall through to normal containment). Existing suites gh91/gh113/gh184/gh654 pass; manual checks A–F in `TESTS-RESULTS/2026-11-12+GH-1137/`. | PR to `development`; awaiting review and merge. |

## Observed

`relay-automation/relay-turn-lib.sh` at `edcb39a6e` removes the whole scratch directory in the real tree:

- `:1318-1320` `rtl_check`: any porcelain path under `.relay-scratch` → `rm -rf "${RTL_ROOT:?}/.relay-scratch"`, exempt.
- `:1550` `rtl_enforce`: unconditional `rm -rf "${RTL_ROOT:?}/.relay-scratch"` after the porcelain loop (GH-91 / PR #93 review: sweep even when the host gitignores scratch).

A host repo that tracks files under `.relay-scratch/` loses them after every turn of every lane that
sources the lib (codex, kimi, agy, …). Observed on HiQS-Labs/XYZ-layout-engine in four turns on
2026-10-17 and four on 2026-11-12. GH-184's guard (`test/gh184-no-tracked-scratch.sh`) keeps Forge
itself from tracking scratch, but nothing protects host repos.

Repro (no model call): a repo with a committed `.relay-scratch/pdf/tracked.json`; source the lib, set
`RTL_ROOT`, call `rtl_check ".relay-scratch/pdf/tracked.json"` → `rc=0`, then `git status` shows
` D .relay-scratch/pdf/tracked.json`.

## Plan

**Outcome.** Relay turns discard only the scratch a turn created (untracked or ignored files under
`.relay-scratch/`); files the host repository tracks there are host content and get normal containment.

**Smallest bet (two edits in `relay-turn-lib.sh`, nothing else):**
1. `rtl_check`: the `.relay-scratch` exemption applies only when the path is not tracked
   (`git -C "$RTL_ROOT" ls-files --error-unmatch -- "$p"` fails). A tracked path falls through to the
   existing off-allowlist handling (orphan backup, `git checkout -- "$p"` restore, `RTL_VIOLATION=1`),
   exactly as for any other host file. For the exempt case, replace `rm -rf` with
   `git -C "$RTL_ROOT" clean -fdxq -- .relay-scratch` (removes untracked and ignored files and empty
   untracked directories; leaves tracked files).
2. `rtl_enforce` end-of-loop sweep: same `git clean -fdxq -- .relay-scratch` in place of `rm -rf`,
   still unconditional and still independent of porcelain visibility (keeps the GH-91 / PR #93
   ignored-scratch behaviour).

**Not changed.** The worktree path (`rtl_worktree_end` `:898`, scratch never copied back) already cannot
touch ROOT's tracked files. No change to prompts, GH-184's guard, or `.relay-artifacts`.

**Not built.** No new test suite or `validate.sh` entry (GH-831). No host-side refusal or warning for
tracked scratch.

**Alternatives rejected.**
- Refuse to run when a host tracks `.relay-scratch/`: blocks relays in repos that did nothing harmful.
- Leave the code and tell hosts not to track there: the harness silently deletes data until someone reads the docs.

**Consult (2026-11-12).** Codex and Kimi (agy quota-exhausted, re-fired with Kimi) both approved the
design. Split: nested repo created inside scratch — Codex accepted it lingering with single `-f`;
Kimi asked for `-ff`. Adopted `-ff`: today's `rm -rf` removes such a repo, so single `-f` would add a
new lingering case, and `git clean` never removes tracked files at any force level. Inherited limits
both noted, not changed here: `git checkout -- "$p"` restores from the index, so a staged rename or
staged edit under scratch is not fully undone; a deleted tracked file gets no orphan backup (the
restore comes from git). Transcripts: `relay-system/2026-11-12/gh1137-plan-181819/`,
`relay-system/2026-11-12/gh1137-plan-kimi-181957/`.

**Rollback.** Revert the commit; behaviour returns to the blanket sweep. Easy.

**Acceptance.**
- The #1137 repro leaves `git status` clean and the tracked file present (red control: same repro on `edcb39a6e` shows ` D`).
- Turn-created scratch still disappears, folder included: existing `test/gh91-relay-scratch.sh` (sections 1 and 6) passes unchanged.
- A turn that modifies or deletes a tracked `.relay-scratch` file is reverted and flagged like any other off-lane edit (manual check).
- Existing suites `gh91-relay-scratch.sh`, `gh113-headless-scratch.sh`, `gh184-no-tracked-scratch.sh`, `gh654-offlane-log.sh`; the routed tier-3 gate (`validate.sh`) once on the final commit in a disposable full clone.

## Rating (2026-11-12)

`rated 60/60/50/85` — sev 60: silently deletes tracked host files after every relay turn; recoverable
with `git checkout`, but a `git add -A` after a turn commits the loss, and it recurs every turn;
pri 60: operator asked for the fix now, recurring across lanes for a month; appeal 50: neutral, no
operator score; effort 85: two lines plus manual verification. Recurrence: 8 deleting turns observed
across two dates (2026-10-17, 2026-11-12) in one host repo; trend in other hosts unknown.
