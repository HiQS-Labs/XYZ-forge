---
title: "GH-482: relay-drive.sh --artifact-file silently seeds nothing — the reviewer completes a turn without ever seeing the artifact"
status: Parked
created: 2026-09-07
updated: 2026-09-07
owner: unassigned
goal: --artifact-file either places the artifact where the turn-taker will read it, or fails the run — never completes a turn having seeded nothing
gh_issue: 482
source: https://github.com/HiQS-Labs/XYZ-forge/issues/482
doc_type: bug
---

# GH-482 — `--artifact-file` seeded nothing and the relay ran anyway

## What happened

A one-round `/relay-xyz` review was launched with `--artifact-file` pointing at a plan document, and
the relay thread told the reviewer to read it at `.relay-artifacts/gh474-plan-comment.md`.

The reviewer's own turn opens:

> **Note:** The artifact `.relay-artifacts/gh474-plan-comment.md` was absent in this worktree.
> Following instructions, I treated this worktree as authoritative and reviewed the plan using the
> one-line summary provided in this file.

The file was never placed. The run completed, reported `STATUS: Rejected`, and looked like a
successful review of the plan — of which the reviewer had read one sentence.

See `relay-system/2026-09-07/gh474-plan-review.md:70`.

## Why it matters

The failure is silent in both directions. The driver does not warn that it seeded nothing, and the
thread still *claims* the artifact is there, so the prompt actively misleads the reviewer about what
it should have in front of it. A reviewer that is honest about the gap (as this one was) still
produces an answer graded against the wrong input; one that is not says nothing at all.

The review happened to reach a defensible verdict from the summary line, which is the dangerous
case: nothing about the output signalled that the input was missing.

## What would fix it

Not yet designed. The minimum is that `--artifact-file` fails the run when the destination does not
exist after seeding — an artifact the prompt promises and the worktree lacks is a broken run, not a
degraded one. A second, cheaper guard: do not emit the "seeded read-only at `<path>`" sentence into
the thread unless the file is actually there.

## Related

- [[GH-481]] — the other way an advisor answered without the input it was supposed to read
