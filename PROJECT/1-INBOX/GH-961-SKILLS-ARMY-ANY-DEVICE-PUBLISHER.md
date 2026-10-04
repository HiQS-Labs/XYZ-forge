---
gh_issue: 961
source: https://github.com/HiQS-Labs/XYZ-forge/issues/961
title: "skills-army-hq: make the publisher role device-agnostic (any device may publish)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-03
doc_type: feedback
---

# GH-961: device-agnostic Skills Army publisher (returned from XYZ-skills-army-mini#7)

**Provenance.** Opened as #881 on 2026-09-28, transferred to XYZ-skills-army-mini#7 on 2026-10-01
(#882), and transferred back as #961 on 2026-10-03 (#955). Its 2026-10-01 banner says it is absorbed
by XYZ-skills-army-mini#3, which stayed in that repo; re-scope it against the forge before work starts.

## Ask

Reword the Skills Army HQ SOP so publishing is something any device with a clean, current Pulse
checkout can do (pull or rebase, commit only portable payload paths, vendor only from the owning
repo, digests match the source), replacing the "single designated publisher" framing in
`skills/3-weekly/skills-army-hq/SKILL.md`, `references/recovery.md`, `README.md` and the
`intake.py` message.

## Acceptance

`grep -rn "designated publisher" skills/3-weekly/skills-army-hq` returns nothing, and the SOP
describes publishing as a device-agnostic pull / commit / push operation.
