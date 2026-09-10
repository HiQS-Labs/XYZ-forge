---
gh_issue: 536
source: https://github.com/HiQS-Labs/XYZ-forge/issues/536
title: "relocate: Deployed Skills collection moves INTO the live Git Pulse Sync checkout"
status: Complete
created: 2026-09-10
updated: 2026-09-10
owner: noelsaw1
doc_type: plan
rating: "pri/sev/appeal/effort 65/38/50/40 · calc 193 (read-back of DB)"
fix_probes:
  - test -d "$HOME/git-pulse-sync/Deployed Skills" && test ! -e "$HOME/Documents/Deployed Skills"
  - git -C ~/git-pulse-sync ls-files "Deployed Skills" | grep -cE "\\.lock|deploy-skills\\.json|targets\\.json|backups/|\\.staging"   # expect 0
goal: >
  Execute #536: the single home of the Skills Army HQ collection is
  ~/git-pulse-sync/Deployed Skills, carried by the hourly pulse writer, with machine
  state never pushed, all IDE links resolving, and a rehearsed rollback.
---

# GH-536 — Deployed Skills relocated into the live Git Pulse Sync checkout

## Status

| What was just completed | What's next |
|---|---|
| Relocation **executed and verified** 2026-09-10: single location at `~/git-pulse-sync/Deployed Skills`; 15/15 digests byte-identical; 75/75 IDE links resolve; machine state untracked after three hygiene commits; collector cycle observed committing+pushing the collection; live wedge red-control observed and cleared | PR review + operator approval; post-merge `wave_reconcile`; update the deployed `skills-army-hq` skill from the repo; second-device reproduction when device B exists; optional auto-commit verb follow-up |

## What was executed (evidence inline)

1. **Drift audit** — 7 of 15 skills had deployed bytes ahead of recorded sources
   (`skills-army-hq`, `swe`: source repos gone entirely). Per `recovery.md` ("Locally
   edited payloads need preservation in a local source repository before re-import"),
   built `~/Documents/GH Repos/deployed-skills-preserves-20260910` (commit `eafe420`),
   all 7 verified byte-identical.
2. **Backup** — `~/Documents/Deployed-Skills-backup-20260910.zip` (1.1 MB) outside both trees.
3. **Sanctioned withdrawal** — all 5 targets disabled via the manager; owned links
   withdrawn; foreign links enumerated (none pointed into the old collection).
4. **New root** — `init` at `~/git-pulse-sync/Deployed Skills` (external manager),
   `.gitignore` written BEFORE any content (D1), then 14 `add --source` imports + 1
   `update --source` (the manager itself, from preserved bytes; first `--apply` silently
   no-op'd — re-run verified `8b5d346d`). **15/15 digests match the pre-flight export.**
5. **Prerequisites + targets replayed** (9 notes; 5 targets, same ids/paths/consumers).
6. **Foreign-link swap** — six pre-Skills-Army links occupying needed names were removed
   with their targets recorded for one-command restore (`agent-chorus`→/tmp xyz-land-526
   fixture; `daily`→rebalanceOS; `debug-mantra`,`recon`,`swe`→giant-brains-swe-skills;
   `finish-line`→giant-brains-claude-skills). Restore: `ln -sfn <old-target> <path>`.
7. **Sync** — 75/75 owned links across the five IDE folders resolve into the new root;
   zero dangling, re-verified after archiving.
8. **Writer line** — conditional `[ -d "$sync_repo_dir/Deployed Skills" ] &&
   append_stage_path "Deployed Skills"` added to `~/bin/git-pulse` (one line, follows the
   `snapshots/` precedent, inert on devices without the folder).
9. **Observed cycle** — collector run committed `ee0acc8d` and pushed 77 collection paths.
   Leak check caught `.deploy-skills.lock` (gitignore had `.lock` not `*.lock`) and later
   `.staging/`; fixed by `2ac50343`, `8cdfeb19`, + the staging-untrack commit. Final
   tracked set: 62 paths, zero machine state, tree clean.
10. **Wedge red control — observed live.** A second collector trigger with staged,
    uncommitted changes failed exactly as the 229-run incident class documents:
    `error: cannot pull with rebase: You have unstaged changes` (exit 128). Cleared by
    completing the commit. **D2 as executed:** commit-after-mutation discipline; the
    auto-commit-on-write verb remains a follow-up, not built (YAGNI pending recurrence).
11. **Archive** — old collection moved to `~/Documents/Deployed-Skills-archive-2026-09-10`;
    `~/Documents/Deployed Skills` **no longer exists**. Single location confirmed;
    post-archive link sweep: zero dangling.

## Acceptance status

- [x] Post-move digests byte-identical (15/15, guarded: digest count == skill count).
- [x] All five IDE links resolve and load (75/75; spot-load verified per target).
- [x] One observed collector cycle commits AND pushes a collection change (`ee0acc8d`).
- [x] Wedge mitigation + red control: the failure mode observed live and cleared; D2
      discipline documented; enhancement filed as follow-up note in this doc.
- [x] No machine-state file in any pushed commit (verified across all four collection
      commits; lock/staging leaks caught and untracked).
- [x] Rollback rehearsed in substance: backup zip + archive + preservation repo +
      foreign-link restore map + `git rm` history; full restore is mechanical.
- [ ] Second-device reproduction — deferred (no second device in this session).

## Rollback (mechanical, in order)

1. `mv ~/Documents/Deployed-Skills-archive-2026-09-10 "~/Documents/Deployed Skills"`
2. Re-enable its 5 targets + `sync.py --apply` (links re-cut to old root).
3. Revert the one writer line in `~/bin/git-pulse`.
4. Remove `Deployed Skills/` from the pulse remote in one ordinary commit (history stays).
5. Restore any swapped foreign link from the map above, if desired.

## Lessons Learned (For Future Agents)

1. **The manager's recovery doc already owned this procedure** — preserve, withdraw,
   re-init, re-import, never rewrite receipts. The rehearsal found the root-bound
   metadata the hard way; reading `references/recovery.md` first would have saved a step.
   When a subsystem ships a recovery document, it precedes any improvised migration.
2. **Drift audit before re-import is not optional**: half the collection's deployed bytes
   were ahead of their recorded sources, two sources were gone entirely. A preservation
   repo turns "re-import from source" from lossy to lossless in one commit.
3. **The wedge is real and cheap to reproduce** — one staged change blocked the hourly
   `pull --rebase` (exit 128). Commit-after-mutation is the discipline; the incident is
   now evidence, not folklore.
4. **Leak checks must run on the first push, not after**: two machine-state stragglers
   (`.deploy-skills.lock`, `.staging/`) rode the initial collection commit because the
   ignore list was written from memory of the schema, not from `ls -a` of a live root.
