---
gh_issue: 918
source: https://github.com/HiQS-Labs/XYZ-forge/issues/918
title: "Deferred: Gen4 domain-oracle shared-root zero-state failure \u2014 retire universal gate blocker"
status: "Proposed (1-INBOX — deferred by operator)"
created: 2026-10-01
doc_type: bugfix
---

# Deferred: Gen4 domain-oracle shared-root zero-state failure — retire universal gate blocker

Post-#910 local run at9ecb344f126c613d7fcc8a0f5d22145a954c6d31 stopped on gh-gen4-phase1-domain-oracles.sh:16pass/1fail. Failure text: zero-state validate.sh --print-mode mutated the clone or leaked a handle. Local-only evidencebee70aaa43333f4ccf9b1b426e9e4ce67cd0910c; no retry and no subsequent run launched.

**Operator disposition (October1): deferred investigation; execute unregister/exempt under #854.** Preserve the file and domain_oracles.py module for focused ATE use. Gen4 campaign imports the module; do not delete it. No new tests or gates.

**Why it exists:** positive/negative self-tests of optional ATE diagnostic tooling. Its crash-recovery controls use test-written toy programs, not marathon recovery. The final check hashes the shared clone while other pooled suites can run, then suppresses detailed stdout/stderr. Exact changed path/holder and historical cause remain unknown; this is not proof of broken marathon containment.

**Resume only when:** required ATE Gen4 work is blocked by an attributable oracle defect, or a real supported read-only harness command mutates an isolated clone and causes user harm. First retain exact reason, before/after change and responsible process. A generic shared-root pool failure is insufficient to restart broad diagnosis.

**Do not re-litigate:** retain core worktree/allowlist safety, attestation, token, resume and escalation coverage. This targeted suite retirement does not weaken those runtime controls, resolve the historical failure or turn excluded evidence into a clean run. October8 full-suite audit #879 remains separate.

Canonical disposition/implementation: https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783
Source assessment: https://github.com/HiQS-Labs/XYZ-forge/blob/9ecb344f126c613d7fcc8a0f5d22145a954c6d31/test/gh-gen4-phase1-domain-oracles.sh

Tracking-ID: ci-disposition-oracle-20261001


## Intake rating
15/30/50/75 (priority/severity/appeal/effort cheapness). Priority reduced by the explicit operator deferral; severity reflects bounded potential effect, not a proven core workflow failure. Neutral appeal50; effort uncertain while original failure attribution is missing. No override.
