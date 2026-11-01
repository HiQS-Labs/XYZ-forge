---
gh_issue: 1314
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1314
title: "Explore independent verification loops: manual GH-1284 calibration"
status: Queue
created: 2026-11-01
updated: 2026-11-01
owner: Mac Mini session / parent review
doc_type: research
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
goal: >
  Calibrate an independently specified manual verifier against historical GH-1284
  revisions, then propose a bounded extension of existing Forge verification seams.
non_goals:
  - Production code changes, actor repair, tick execution or paid model calls
  - New CI tests, assertions, parametrizations, suites, gates or runners
  - Full-suite reruns, automatic merge, deployment or production actions
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1284
  - https://github.com/HiQS-Labs/XYZ-forge/issues/831
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1131
---

## Status

| What was just completed | What's next |
|---|---|
| Approved run stopped inconclusive during preconditions (0/8 candidate commands); evidence retained. | Parent reviews the draft evidence/proposal; any replacement run needs new approval. |

## Scope and hold

This is a manual, supervised historical calibration, not an immutable sandbox or
implementation of autonomous verification. The parent approved exact helper/protocol hashes before the single run. It stopped
inconclusive on the empty HOME/TMPDIR precondition; no candidate command executed.
Evidence: [summary](../../TESTS-RESULTS/2026-11-01+GH-1314/SUMMARY.md).
Existing checkout remains untouched. No retry is authorized.

Known bad: `b78df4b93049498b19dd47fe6a90d006f9c42700`.
Known good: `47deab48b8c749d699c6b6c77c38dfdaa5682025`.
Two fresh roots per candidate, status then init, eight CLI invocations total;
reverse candidate order on replay. Observe actual output, exit and filesystem state.
No tick, actor repair, model, live backlog or production access.

Ten-minute ceiling including disposable-clone setup; thirty seconds per candidate
command; final four minutes reserved for replay/evidence/shutdown; zero model spend.
No retry, budget increase or weakening expectations after observations start.

## Acceptance and evidence

- Both rounds distinguish bad status creating state (subsequent init refuses) from
  good status refusing without state (subsequent init succeeds).
- Pin source/fixtures and freeze protocol/helper hashes before observations.
- Capture full output, command outcomes, expected nonempty JSON and runtime effects,
  and before/after inventories of candidate trees, owned HOME/TMPDIR and evidence.
- Stop on drift, unexpected effects, invalid evidence or uncertain owned-child
  termination. Retain inconclusive outcomes without retry.
- Retain raw evidence and provenance under `TESTS-RESULTS/<date>+GH-1314/`.
- Parent independently reviews raw evidence; a later draft PR is not merge approval.

## Ownership and limitations

Use exclusively owned standalone full clones; do not launch a shared gate. Same-user
filesystem separation is supervised, not an adversarial write boundary. Inventory
claims cover declared paths only. Process inventory was denied; do not retry or
bypass it, and do not claim host-wide idleness.

## Intended delivery

Documentation/evidence draft PR into development with this pointer and normal queue
bookkeeping. Preserve useful unit/integration tests and GH-831/GH-1131. No reusable
executable runner or CI gate. Follow current publication hooks and documented WIP
draft conditions; no silent gate bypass.
