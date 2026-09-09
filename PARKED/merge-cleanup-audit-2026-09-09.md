# merge-cleanup audit — 2026-09-09 (read-only, nothing executed)

## Phase 1-3: checkout inventory (8 standalone clones + 1 primary; ZERO linked worktrees)

| Checkout | Branch | Dirty | Unlanded commits vs origin/development | Verdict |
|---|---|---|---|---|
| **primary** `GH Repos/XYZ-forge` | feat/gh518-muse-harness-route | 6 M + 4 ?? | (PR 520 pushed) | PRIMARY — dirty, blocks ff-merge |
| ~~marathon-clones/gh271-waveA~~ | plan/gh-271-subtraction-marathon | 0 | **29** (no upstream) | **OUT OF SCOPE** — origin is `Hypercart-Dev-Tools/rebalance-OS`, not XYZ-forge |
| marathon-clones/marathon-gh-299-gen4-ate | feat/gh299-gen4-ate | 10 | 12 (ahead of origin/development) | PRESERVE_DIRTY+UNPUSHED |
| marathon-clones/marathon-gh-462-planner-core | marathon/10days-gh462-planner-core | 0 | **83** (no upstream) | PRESERVE_UNPUSHED |
| marathon-clones/marathon-gh-490-roadmap-db-flip | marathon/gh-490-prep | 0 | prep branch fully pushed; local `development` holds **6** commits absent from BOTH origin/development and origin/marathon/gh-490-prep | PRESERVE_UNPUSHED — also PR 495 source |
| GH Repos/XYZ-forge-gh516-express-v2 | feat/gh516-express-v2 | 0 | fully pushed | HOLD until PR 519 lands, then disposable |
| GH Repos/XYZ-forge-issue-admission-sketch-20260908 | feat/issue-admission-sketch | 4 M + 2 ?? | 0 | PRESERVE_DIRTY (untracked GH-522-ISSUE-ADMISSION.md, recon-issue-admission.md) |
| GH Repos/XYZ-forge-luna-needle-spike-20260909 | feat/luna-needle-spike | 0 | **17** (no upstream) | PRESERVE_UNPUSHED |
| GH Repos/XYZ-forge-merge-cleanup-docs | fix/merge-cleanup-docs | 0 | 1 | PRESERVE_UNPUSHED |

No `relay-driver.lock` held anywhere. No `lsof` handles on marathon-clones. `.tick/` claim
dirs present in gh271 (7), gh299 (4), gh462 (10), gh490 (9) — stale claims, no live PIDs.

**Teardown eligibility: 0 of 7 in-scope clones.** Every one holds unpushed commits, uncommitted
work, or both. Nothing can be deleted this pass without first landing or explicitly abandoning
that work. (`gh271-waveA` is an eighth checkout under `marathon-clones/` but belongs to a
different repository entirely — see the struck row above. It is not this skill's business.)

None of the clones shares the primary's object store: every one has its own `.git` with no
`objects/info/alternates`, and each fetches from GitHub directly. Branch operations in the
primary checkout are therefore invisible to all of them.

## Phase 4: PR matrix + topological order

Open PRs: 520, 519, 495. No explicit `depends on #N` markers — order derived from file collisions.

| PR | Title | Merge state | Source clone |
|---|---|---|---|
| 520 | GH-518 muse-turn shim + fail-closed model policy | **CLEAN / MERGEABLE** | primary (current branch) |
| 519 | GH-516 express v2 hotfix fast lane | **DIRTY / CONFLICTING** | XYZ-forge-gh516-express-v2 |
| 495 | GH-490 marathon prep, six ledger-flip lanes | **DIRTY / CONFLICTING** | marathon-gh-490-roadmap-db-flip |

File collisions:
- 520 ∩ 495 → `harnesses.db`, `harnesses.sql`
- 519 ∩ 495 → `ROADMAP-DASHBOARD.md`
- 519 ∩ 520 → none

**Topological merge order: 520 → 519 → 495.**
520 first because it is the only clean head and it seeds the `harnesses.db` state 495 must rebase onto.
519 second: smaller conflict surface (7 files, ledger + one skill), independent of 520.
495 last: 40+ files, both collisions land on it, so it rebases once against a settled base.

## Phase 5 blocker (before any merge)

Primary working tree is dirty and will refuse `git merge --ff-only origin/development`:
- Modified generated ledger: `LEADERBOARD.md`, `ROADMAP-DASHBOARD.md`, `harnesses.db`, `harnesses.sql`, `releases.db`, `releases.sql`
- Untracked real work: `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md`, `PROJECT/1-INBOX/GH-510-JOG-MERGE-FALSE-SUCCESS.md`
- Untracked junk: `.playwright-mcp/`, `flightdeck-live-layout-a.png`

The two GH-505/GH-510 intake docs are unfiled captures, not artifacts of PR 520 — they need their
own commit or a park, not to ride along in the muse-harness PR.

## Conflict-repair plan for 519 and 495 (per skill Phase 5, not yet executed)

Both conflicts are ledger/generated-artifact conflicts, which the skill says to resolve rather
than escalate: in a disposable full clone, refresh `development`, preserve both sides' intended
rows via `utils/py/releases_app.py` / `harness_app.py`, regenerate `ROADMAP-DASHBOARD.md` and
`LEADERBOARD.md`, renumber only unpublished CHANGELOG entries, run the gate, push. Per the
recorded session trap, the gate must run in a throwaway clone — the primary goes RED because the
Antigravity language server holds `.git` handles the Gen4 oracle calls leak.
