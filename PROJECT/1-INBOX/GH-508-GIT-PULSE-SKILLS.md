---
gh_issue: 508
source: https://github.com/HiQS-Labs/XYZ-forge/issues/508
title: "Git Sync Pulse as a portable Skills Army HQ projection"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-09-08
doc_type: feedback
effort: 2
complexity: 3
risk: 2
phases: 1
ratings_provisional: true
---

# GH-508 — Git Sync Pulse skills projection

## Quad Concepts

- Manual second-device reconstruction → carry only a portable skill projection through the existing private remote.
- Shared live-checkout authority risk → retain device-local HQ authority and use an isolated explicit-import checkout.

## Verdict

Explore the existing private Git Sync Pulse remote only as an optional read projection / transport.
Keep every device's local Skills Army HQ collection authoritative. Do not relocate the collection
into the scheduled live pulse checkout and do not introduce another background writer.

Reversibility is **Easy** for this projection: deleting the isolated consumer checkout leaves the
local collection and deployed app links intact. Promoting the pulse checkout to deployment authority
would instead be **Costly** and is outside this capture.

## Actionable scope

1. Use a separate clean checkout of the existing private remote, not the checkout used by scheduled
   pulse writers.
2. Project three portable `skills/<name>/` payloads plus one generated manifest; exclude collection
   identity, targets, ownership receipts, locks, staging, backups, and history.
3. Import explicitly through the existing Skills Army HQ `add` / `update` and `sync` paths.
4. Designate one publisher for the spike; add no merge automation, daemon, watcher, database, new
   repository, or Git implementation.
5. If manual import remains cumbersome, route the smallest export/import improvement to GH-506.

## Acceptance criteria

- [ ] Two simulated device homes with different absolute paths import identical payload digests for
      three skills while retaining distinct local targets and link-ownership receipts.
- [ ] A conflicting update follows the initial single-publisher rule.
- [ ] The scheduled live Git Pulse checkout remains clean and unchanged.
- [ ] Removing the projection leaves both local collections and their deployed links functional.
- [ ] The spike records whether payload bytes or source-repo-plus-commit references are lighter and
      whether offline import is a real requirement.
- [ ] If operator-managed content is incompatible with the generated-data remote's contract, stop.

## Recon

The deep end-to-end trace, authority classification, failure paths, rollback, and Ponytail reduction
are recorded in [RECON-GH-508-GIT-PULSE-SKILLS.md](RECON-GH-508-GIT-PULSE-SKILLS.md).

Related: GH-506 (replication/import UX) and GH-484 (original local deployment system).
