# Marathon Phase gh198-relay-drive-artifact-preflight
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "Phase brief: GH-198 relay-drive.sh artifact preflight gap (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh198-relay-drive-artifact-preflight phase — not itself an active-doc capture; the canonical
  capture doc is GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon. |

## Phase: gh198-relay-drive-artifact-preflight — fail fast on a missing Setup-referenced artifact

Full context: [GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md](../GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198

### Already fixed — do NOT re-touch

Bug 1 of #198 (file-scoped commit ignoring pathspec, sweeping pre-existing staged changes) is
**already fixed** — commit `bee1abf` in `relay-automation/relay-turn-lib.sh`, with its own
regression test `test/relay-commit-pathspec.sh` (9/9). Do not touch that commit-scoping logic. This
phase is Bug 2 only, a separate remaining gap in `relay-automation/relay-drive.sh`.

### The gap (Bug 2)

`relay-drive.sh` already fails fast when `--artifact-file` (a CLI flag) points at a missing path
(line ~270: `[[ -f "$ARTIFACT_FILE" ]] || die ...`). There is no equivalent check for the more
common case: a relay thread's own `Setup` section naming a path the reviewer is meant to open
directly from the target repo/worktree. When that path is missing, the failure currently surfaces
opaquely deep inside the reviewer's own turn instead of at dispatch time.

### What to do

1. In `relay-automation/relay-drive.sh`, before dispatching a turn, add a preflight check that
   resolves any artifact path referenced in the relay file's `Setup` section against the worktree.
2. If the path doesn't resolve, fail fast with a message containing the literal string
   `artifact path not found in worktree`.
3. Extend `test/relay-artifact-file.sh` with a new, additive case exercising this: a
   Setup-referenced path that doesn't exist should fail fast with the clear message, not fail
   opaquely mid-turn.
4. Do not touch the existing `--artifact-file` check (line ~270) or Bug 1's already-fixed
   commit-scoping logic.

### Acceptance / done means

- A relay file whose Setup section references a missing artifact path now fails at dispatch time
  with a message containing `artifact path not found in worktree`.
- Full `bash test/relay-artifact-file.sh` green, including the new case.
- Leave a one-line status update in `GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md`'s Status table.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-drive.sh,test/relay-artifact-file.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh198-relay-drive-artifact-preflight/RELAY.md,relay-automation/relay-drive.sh,test/relay-artifact-file.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh208-154-149-198-issue-sweep--gh198-relay-drive-artifact-preflight/RELAY.md and relay-automation/relay-drive.sh,test/relay-artifact-file.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-drive.sh,test/relay-artifact-file.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH198-RELAY-DRIVE-ARTIFACT-PREFLIGHT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh208-154-149-198-issue-sweep--gh198-relay-drive-artifact-preflight/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Touched `relay-automation/relay-drive.sh` and `test/relay-artifact-file.sh`.
- Added a dispatch-time Setup preflight in `relay-drive.sh` that scans the relay's `## Setup` section for repo/worktree-style markdown paths on `Artifact under review:` lines, skips embedded and `.relay-artifacts/...` cases, resolves candidates against the effective worktree root, and fails fast with `artifact path not found in worktree: ...` before the agent command runs.
- Left the existing `--artifact-file` preflight untouched.
- Extended `test/relay-artifact-file.sh` with a GH-198 regression that seeds a relay whose Setup points at `missing/artifact.txt`, asserts exit `2`, asserts the clear message, and asserts the agent never dispatches.
- Verification: `bash test/relay-artifact-file.sh` -> `13 pass, 0 fail`.
- Note: the phase brief also asks for a one-line status update in `GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md`, but this relay turn explicitly restricted edits to `RELAY.md`, `relay-automation/relay-drive.sh`, and `test/relay-artifact-file.sh`, so I did not touch the capture doc.
