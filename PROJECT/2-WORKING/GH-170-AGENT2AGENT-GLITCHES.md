---
title: Agent2Agent transcript glitches and standalone publishing
status: Active
created: 2026-08-22
updated: 2026-08-22
owner: Codex
goal: Make scope changes, closure, verification handoffs, doorbell liveness, and one-way publishing explicit and mechanically verifiable.
gh_issue: 170
source: https://github.com/HiQS-Labs/XYZ-forge/issues/170
doc_type: bugfix
branch: gh-170-agent2agent-glitches
effort: 3
complexity: 4
risk: 3
phases: 3
context_tags: [agent2agent, protocol, transcripts, publishing]
---

# GH-170 — Agent2Agent transcript glitches and standalone publishing

## Status

| What was just completed | What's next |
|---|---|
| Implemented helper-owned scope extension, structured close, verified Git handoff, heartbeat-aware status, the external canonical session store, and a manifest/parity publisher. Focused suites pass 88/88 and 129/129; isolated publisher positive and negative controls pass. | Commit the final state, run the complete gate in a second full clone, open the XYZ PR, then publish and verify standalone `main`. |

## Table of contents

- [Problem](#problem)
- [Phase 1 — Protocol state and validation](#phase-1--protocol-state-and-validation)
- [Phase 2 — Publishing contract](#phase-2--publishing-contract)
- [Phase 3 — Verification and publication](#phase-3--verification-and-publication)
- [Rollback](#rollback)

## Problem

Live discussions exposed four recoverable glitches: an operator follow-up has no formal scope state,
terminal consensus can degrade into an unstructured blob, a turn can claim an asynchronous action
before it completes, and old heartbeat timestamps are reported as stale even while the seat owns the
active turn. The downstream Gen-2 umbrella also calls for a one-way manifest-driven publisher, but
the current local helper overlays a directory without a declared surface or destination-drift guard.

Canonical reports: [standalone #1](https://github.com/HiQS-Labs/Agent2Agent-Skill/issues/1),
[#2](https://github.com/HiQS-Labs/Agent2Agent-Skill/issues/2),
[#3](https://github.com/HiQS-Labs/Agent2Agent-Skill/issues/3),
[#4](https://github.com/HiQS-Labs/Agent2Agent-Skill/issues/4), and
[#5](https://github.com/HiQS-Labs/Agent2Agent-Skill/issues/5).

## Phase 1 — Protocol state and validation

- Add a serialized `extend` operation and durable extension count.
- Validate structured close synthesis by default, with an explicit trivial/administrative escape.
- Add opt-in clean/upstream parity verification before a handoff.
- Add transcript-neutral heartbeat refresh and context-aware/configurable doorbell reporting.
- Pin every acceptance/refusal path in the standalone smoke suite, including witnessed-red controls.

QA gate: `skills/agent2agent/test-standalone.sh` passes and each new refusal is paired with a valid
operation proving the gate is discriminating.

## Phase 2 — Publishing contract

- Declare every canonical source → standalone destination mapping and expected executable mode.
- Preview by default; require explicit apply; refuse unexpected tracked destination files.
- Record the canonical XYZ revision and verify byte parity after copy.
- Ship standalone CI that checks the recorded canonical revision and runs the smoke suite.

QA gate: a disposable standalone fixture proves unexpected drift is refused, a declared copy reaches
byte parity, and a subsequent `--check` reports clean.

Observed: apply/check reached byte and mode parity; deliberate executable-mode drift and an
undeclared tracked file were both refused.

## Phase 3 — Verification and publication

- Commit the complete change in the implementation clone.
- Run the full XYZ gate from a second separate full clone against that exact commit.
- Push and open a PR into `development`; verify base, diff size, and final-state gate evidence.
- Publish the exact manifest to standalone `main`, run standalone verification, commit, and push.

QA gate: remote SHAs match the locally verified commits and both repository worktrees are clean.

## Rollback

Revert the GH-170 commit/PR in XYZ, then publish that reverted canonical package as a new standalone
commit. Do not rewrite either repository's shared history.
