---
gh_issue: 916
source: https://github.com/HiQS-Labs/XYZ-forge/issues/916
title: "Deferred: attribute live relay-self-sufficiency failure only when the live skill path is blocked"
status: "Proposed (1-INBOX — deferred by operator)"
created: 2026-10-01
doc_type: bugfix
---

# Deferred: attribute live relay-self-sufficiency failure only when the live skill path is blocked

Observed twice in normal 4-wide development pools on September 30; reruns alone passed. Retained normal run2 evidence05c8ab424fe43b75e4abe368ae4e77d0c7a15eb9: shim exit6, two pass/two fail. Exact guard/path is unobserved; exit6 alone does not prove an off-allowlist edit.

**Operator disposition (October1): deferred.** Keep this as targeted real CLI/model/prompt compatibility testing. Existing #836 D2 defaults skip it in pre-push, ci-local and hosted wrappers. Qualification should use that declared scope, not silently require a live turn on every unrelated change. Preserve the file and deterministic core containment/token/attestation coverage.

**Why it exists:** catches real model/CLI prompt-execution failures that stubs cannot. It invokes one shim on a fixed minimal fixture, disables worktree isolation, and does not exercise the generated relay scaffold, full supervisor, consult or marathon resume. Its handoff assertion is weaker than its label (the original agent already released before the check).

**Resume only when:** a requested real relay/consult/marathon is blocked by a matching failure, or a change to the turn shim/shared prompt/fixture requires the existing policy's live evidence and fails. Capture exact shim/guard output then; retain no speculative locking fix or repeat full-gate diagnosis now.

**Do not re-litigate:** a retry pass is not resolution; a live skip is not executed coverage; model compatibility is not universal execution proof. Further diagnostic work remains paused until a named trigger and user impact are linked here.

Canonical disposition/implementation: https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783
Source assessment: https://github.com/HiQS-Labs/XYZ-forge/blob/9ecb344f126c613d7fcc8a0f5d22145a954c6d31/test/relay-self-sufficiency.sh

Tracking-ID: ci-disposition-relay-20261001


## Intake rating
30/55/50/50 (priority/severity/appeal/effort cheapness). Priority reduced by the explicit operator deferral; severity reflects bounded potential effect, not a proven core workflow failure. Neutral appeal50; effort uncertain while original failure attribution is missing. No override.

## Merge evidence

- PR #925 merged 2026-10-02 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
