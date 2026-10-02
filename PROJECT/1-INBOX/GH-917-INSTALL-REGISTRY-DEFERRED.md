---
gh_issue: 917
source: https://github.com/HiQS-Labs/XYZ-forge/issues/917
title: "Deferred: registry-lock-concurrency missing install row \u2014 retain installer scope, retire universal gate blocker"
status: "Proposed (1-INBOX — deferred by operator)"
created: 2026-10-01
doc_type: bugfix
---

# Deferred: registry-lock-concurrency missing install row — retain installer scope, retire universal gate blocker

An instrumented pooled diagnostic observed registry-lock-concurrency first round15/16, followed by retry green. Local-only evidencebd698b86b0e2a7783bd9a3d90821fcb9e2e81ccc; later captured32 writers exited0 with all rows, which does not explain the original failure.

**Operator disposition (October1): deferred investigation; execute removal from mandatory registry under #854.** Preserve the suite file and installer implementation; add the existing gh306 exemption. No new runner or suite. Prior failed attempts remain excluded.

**Why it exists:** sixteen simultaneous install.sh calls (twice) update installation inventory. Lost rows can hide an install from bulk updates, marathon-ls, transcript collection or HQ discovery. This is real maintenance risk, but normal relay/consult/marathon startup uses explicit/local/self paths; registration is intentionally best effort and --no-register is supported.

**Limits:** the suite suppresses writer output and ignores exit statuses, so fifteen rows cannot distinguish process failure, supported lock timeout or lost update. It does not test the separate xyz-vendor registry writer. Do not infer the completion writer's #909 cause applies here. Historical GH72 in the file is migrated numbering, not the public repo's unrelated current issue72.

**Resume only when:** a real installation disappears from required sync/discovery and blocks requested work, or a change to install registration/concurrency needs this targeted check and produces an attributable failure. Preserve exact target/PID/exit/log and registry then.

**Do not re-litigate:** universal gate retirement is a deliberate coverage tradeoff, not proof of a fix. No further speculative lock work or broad CI reruns without that trigger.

Canonical disposition/implementation: https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783
Source assessment: https://github.com/HiQS-Labs/XYZ-forge/blob/9ecb344f126c613d7fcc8a0f5d22145a954c6d31/test/registry-lock-concurrency.sh

Tracking-ID: ci-disposition-registry-20261001


## Intake rating
20/40/50/60 (priority/severity/appeal/effort cheapness). Priority reduced by the explicit operator deferral; severity reflects bounded potential effect, not a proven core workflow failure. Neutral appeal50; effort uncertain while original failure attribution is missing. No override.
