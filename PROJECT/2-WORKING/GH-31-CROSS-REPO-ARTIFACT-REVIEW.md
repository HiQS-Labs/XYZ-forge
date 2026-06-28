---
ratings_exempt: true
title: Cross-repo external-artifact review flow (--artifact-file / scaffolder)
status: Active (2-WORKING)
created: 2026-06-27
updated: 2026-06-27
owner: noel
gh_issue: 31
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/31
goal: >
  Give the harness a first-class way to review an artifact (a PR/diff) that lives in
  ANOTHER repo, without manually embedding the diff into the relay markdown — copy the
  artifact into the worktree, expose it to the reviewer, and scaffold the thread.
doc_type: project
non_goals:
  - Not the single-turn exit-code / warn work (that is GH-32)
  - Not changing transcript storage location (that is GH-30)
related:
  - PROJECT/2-WORKING/GH-32-SINGLE-TURN-REVIEW-ERGONOMICS.md
  - PROJECT/1-INBOX/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md
  - relay-automation/CONSUMING.md
roadmap_exempt: false
---

## Status

| What was just completed | What's next |
|---|---|
| **All 4 phases shipped.** Phase 3+4: `relay-automation/new-relay.sh` scaffolds a single-artifact review thread (reference mode points at the `.relay-artifacts/` seed path; `--embed` inlines the artifact in a fence chosen longer than any backtick run inside — fence-collision safe). Test `test/new-relay.sh` (14 assertions); `./validate.sh` **52/52**. | Open the PR completing GH-31; close #31 after merge. Doc → `3-COMPLETED` once #31 closes. |

## Table of Contents

- [Status](#status)
- [Background](#background)
- [Phase 1 — Design the artifact-delivery contract](#phase-1--design-the-artifact-delivery-contract)
- [Phase 2 — Implement `--artifact-file` copy-into-worktree](#phase-2--implement---artifact-file-copy-into-worktree)
- [Phase 3 — Fence-safe embedding fallback](#phase-3--fence-safe-embedding-fallback)
- [Phase 4 — `new-relay.sh` scaffolder](#phase-4--new-relaysh-scaffolder)

## Background

The harness assumes the review subject is a repo-relative path inside the harness clone; an
external PR/diff has no path there. The reporter had to `git diff` and embed 66 KB into the relay
md as the only delivery channel. Same root assumption as GH-30 (the transcript side). Worktree
isolation defaults to `ROOT@HEAD` (`relay-drive.sh:90`), so any artifact must be reachable from
that worktree.

## Phase 1 — Design the artifact-delivery contract

**Key finding:** `relay-turn-lib.sh:134-144` already documents this exact gap and names the fix — a
**read-only seed set distinct from the writable allowlist**, tracked as open issue
[#15](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/15). So `--artifact-file`
is the *user-facing surface* of #15; GH-31 and #15 should be implemented together (cross-linked).

Design decisions (the Phase 1 outcome):

- [x] **Delivery = copy as a read-only seed.** The artifact is copied INTO the isolated worktree at a
  stable location (`.relay-artifacts/<basename>`), NOT referenced by an absolute external path (which
  collides with `ROOT@HEAD` isolation — the documented trap). The reviewer addresses it by that
  worktree-relative path, which the relay thread's TARGET/Review line points at.
- [x] **Option surface = `--artifact-file <path>` on `relay-drive.sh`** (repeatable for >1 artifact in a
  later pass; v1 single). Accepts an absolute path or a path resolved against CWD — a diff file, or any
  file from another repo. No `--external-diff` alias (one surface; a diff is just a file).
- [x] **Containment = a new read-only seed set, separate from `RTL_ALLOW` (the writable allowlist):**
  1. seed it into the worktree in `rtl_worktree_begin` (like the relay file is seeded),
  2. **exempt it from the off-lane detector** in `rtl_worktree_end` (alongside the relay file + `.tick`),
     so its presence as an untracked file does not fail the turn,
  3. **never copy it back to `RTL_ROOT`** — so the artifact cannot leak into the target repo's tree, and
     any reviewer edit to it is discarded with the worktree (effectively read-only).
  This widens neither the writable allowlist nor the foreign-repo write scope: it is a READ surface only.
- [x] **Bet recorded in `CHANGELOG.md`** (2026-06-27): Costly — touches the containment core
  (`rtl_worktree_begin/end`); additive + default-off, so reversibility is Easy.

> Phase 2 implements this against `rtl_worktree_begin/end` and is **Costly (containment core)** — it
> pauses for operator confirmation of the concrete diff plan before any code lands.

### QA checklist — Phase 1

- [ ] Contract names exactly where the artifact lands and how the reviewer addresses it.
- [ ] Isolation interaction is explicit (no absolute-path-in-isolated-worktree trap).
- [ ] No code changed in this phase.

## Phase 2 — Implement `--artifact-file` copy-into-worktree

- [x] Added `--artifact-file <path>` to `relay-drive.sh` (absolutizes + validates + exports `RELAY_ARTIFACT_FILE`; warns if isolation is off). `relay-turn-lib.sh` seeds it into the worktree at `.relay-artifacts/<basename>` (`rtl_init` → `RTL_ARTIFACT`; `rtl_worktree_begin` copy + signature snapshot).
- [x] Exposed the in-worktree path to the reviewer via `rtl_turn_prompt` ("the artifact under review is at `.relay-artifacts/…` — read-only").
- [x] Embedding path untouched — callers who still want to embed inline can.
- [x] **Strict-fail (operator call):** the read-only seed is exempt from off-lane detection ONLY while unchanged; a reviewer edit changes the `.relay-artifacts` dir signature → off-lane → exit 6. Never added to `RTL_ALLOW`, so never copied back to ROOT.

### QA checklist — Phase 2

- [x] A cross-repo PR diff passed via `--artifact-file` is readable by the reviewer with no manual embedding (test case 1).
- [x] The artifact does not leak into the target repo's tracked tree (test cases 1 + 2 assert no `.relay-artifacts` in ROOT).
- [x] `./validate.sh` green with a regression test — `test/relay-artifact-file.sh` (10 assertions), suite **51/51**.
- [x] Edit-the-artifact → strict-fail exit 6 verified (test case 2); default-off path unchanged (test case 3).

## Phase 3 — Fence-safe embedding fallback

- [x] `new-relay.sh --embed` auto-selects a fence longer than the longest backtick run inside the artifact (`fence_for`: `max(3, longest_run + 1)`).
- [x] Covered an artifact that itself contains fenced markdown / nested code blocks (test cases 3 + 4).

### QA checklist — Phase 3

- [x] An embedded artifact containing a 3-backtick block gets a ≥4-backtick outer fence (no collision); a 5-backtick run scales the fence to ≥6 (test cases 3 + 4).
- [x] Test asserts the chosen fence length exceeds the max inner run.

## Phase 4 — `new-relay.sh` scaffolder

- [x] Added `relay-automation/new-relay.sh --title --reviewer [--artifact-file] [--embed] [--producer] [--round-cap] [--out|--print]` — emits a thread with `NEXT:`/`STATUS:`/`ROUND:` + the "▶ TAKE YOUR TURN" block + Setup + Ground rules + Log marker. Reference mode points at the `.relay-artifacts/<basename>` seed path (ties Phase 4 to Phase 2).
- [x] Documented in the relay-xyz skill (see Phase 5 wrap); the scaffolder only WRITES a thread — it does not drive the harness, so the relay-xyz guard is not engaged.

### QA checklist — Phase 4

- [x] Scaffolder produces a thread with the fields the driver reads (`NEXT:`/`STATUS:`) — `test/new-relay.sh` asserts them.
- [x] Documented in the relay-xyz skill; the scaffolder writes-only (no guard bypass — it never invokes a driver).
- [x] `./validate.sh` green — **52/52** (`test/new-relay.sh`, 14 assertions).
</content>
