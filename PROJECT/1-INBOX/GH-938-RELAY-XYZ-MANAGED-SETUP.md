---
gh_issue: 938
source: https://github.com/HiQS-Labs/XYZ-forge/issues/938
title: "relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-10-02
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-938: relay-xyz first-time setup on Skills Army-managed Macs

Captured from [#938](https://github.com/HiQS-Labs/XYZ-forge/issues/938).

- `skills/1-hourly/relay-xyz/SKILL.md` → "First-time setup on a new clone or machine" tells every
  machine to run `install.sh`, with no exception for a machine whose app link already resolves into a
  Skills Army HQ `Deployed Skills` collection. Skills Army HQ says not to run copied `install.sh` files.
- On such a machine the step is unnecessary, exits 1 on the live links (GH-678 guard), and creates
  links Skills Army HQ does not own in roots the collection does not target.
- Asks: say to skip `install.sh` when managed (with a `readlink` check); point managed machines to
  `find-harness.sh --check` and the per-device config it proposes; optional `install.sh` managed
  detection; verification through existing suites or a recorded manual check (GH-831).
