---
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
| Issue [#31](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/31) filed; gap confirmed — no `--artifact-file`/`--external-diff` exists in `relay-automation/`, worktree isolation is `ROOT@HEAD` (`relay-drive.sh:90`). | Phase 1 — design the `--artifact-file` contract (copy-into-worktree vs reference) before touching containment. Sequenced AFTER GH-32's cheap wins. |

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

- [ ] Decide delivery: **copy** the artifact into the worktree (reviewer reads a repo-relative path) vs **reference** an absolute external path (collides with isolation).
- [ ] Define the option surface: `--artifact-file <path>` and/or `--external-diff <path>`; how it maps to the relay thread's TARGET/Review section.
- [ ] Specify containment: the copied artifact lands inside the worktree allowlist; no widening of the foreign-repo write scope.
- [ ] Record the bet in `CHANGELOG.md` (touches worktree/containment ⇒ Costly).

### QA checklist — Phase 1

- [ ] Contract names exactly where the artifact lands and how the reviewer addresses it.
- [ ] Isolation interaction is explicit (no absolute-path-in-isolated-worktree trap).
- [ ] No code changed in this phase.

## Phase 2 — Implement `--artifact-file` copy-into-worktree

- [ ] Add the option to the driver; copy the artifact into the isolated worktree before the reviewer turn.
- [ ] Expose its in-worktree path to the reviewer via the relay thread (replace manual embedding).
- [ ] Keep the explicit-embed path working for callers who still want it.

### QA checklist — Phase 2

- [ ] A cross-repo PR diff passed via `--artifact-file` is readable by the reviewer with no manual embedding.
- [ ] The artifact does not leak into the target repo's tracked tree.
- [ ] `./validate.sh` green with a regression test.

## Phase 3 — Fence-safe embedding fallback

- [ ] When embedding IS used, auto-select a fence longer than the longest backtick run inside the artifact.
- [ ] Cover an artifact that itself contains fenced markdown / nested code blocks.

### QA checklist — Phase 3

- [ ] An embedded artifact containing ```` ```diff ```` blocks renders without fence collision.
- [ ] Test asserts the chosen fence length exceeds the max inner run.

## Phase 4 — `new-relay.sh` scaffolder

- [ ] Add a lightweight `new-relay.sh --title --reviewer --artifact-file` that emits a thread with the STATUS/NEXT + "▶ TAKE YOUR TURN" + "### Review —" skeleton.
- [ ] Route it through the relay-xyz skill so it is not a hand-rolled handoff.

### QA checklist — Phase 4

- [ ] Scaffolder produces a valid thread the driver can drive end-to-end.
- [ ] Invoking it is documented in the relay-xyz skill; no guard bypass.
- [ ] `./validate.sh` green.
</content>
