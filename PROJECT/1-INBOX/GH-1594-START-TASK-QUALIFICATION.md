---
gh_issue: 1594
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1594
title: Start-task qualification follows the target repository
status: Proposed (1-INBOX — not yet active)
created: 2026-11-24
doc_type: bugfix
---

# Start-task qualification follows the target repository

Forge's mandatory hook check was applied to Layout Engine after it vendored Forge.
The consumer had valid project gates and no root Forge hook installer.

- Use one target qualification policy for provisioning, verification and publication.
- Require Forge's installed hook in Forge and the documented project gates in consumers.
- Ask for a gate decision when a consumer has no documented applicable gate.
- For changes at this boundary, exercise Forge and one representative consumer in the existing smoke step.
