---
gh_issue: 959
source: https://github.com/HiQS-Labs/XYZ-forge/issues/959
title: "Link-drift reporting: name dangling/foreign/retargeted app links as DRIFT and list unmanaged app skill dirs"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-03
doc_type: feedback
---

# GH-959: link-drift reporting (returned from XYZ-skills-army-mini#5)

**Provenance.** Opened as #676 on 2026-09-17, transferred to XYZ-skills-army-mini#5 on 2026-10-01
(#882), and transferred back as #959 on 2026-10-03 (#955). The 2026-10-01 amendment narrowed it to
link-drift reporting only; that scope is unchanged by the return.

## Asks

1. In an enabled target, report a dangling, foreign or retargeted app link as `DRIFT` with the exact
   remedy from `skills/3-weekly/skills-army-hq/references/recovery.md`. Never replace it silently.
2. List app skill directories that bundled installers write but no target manages (for example
   `~/.gemini/antigravity/skills`, `~/.gemini/antigravity-cli/skills`) so the operator can bring
   them under `targets.json`.

## Open question from the return

The issue's amendment sequences it after XYZ-skills-army-mini#3 (source-agnostic intake), which
stayed in that repo. Decide whether that dependency still holds now that the forge is upstream.

## Merge evidence

- PR #962 merged 2026-10-04 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
