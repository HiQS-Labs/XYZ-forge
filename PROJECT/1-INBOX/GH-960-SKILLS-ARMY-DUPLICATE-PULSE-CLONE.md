---
gh_issue: 960
source: https://github.com/HiQS-Labs/XYZ-forge/issues/960
title: "skills-army-hq: normal sync run should flag a duplicate Git Pulse Sync clone (git-pulse writes one, skill links read another)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-03
doc_type: bugfix
---

# GH-960: flag a duplicate Git Pulse Sync clone (returned from XYZ-skills-army-mini#6)

**Provenance.** Opened as #837 on 2026-09-26, transferred to XYZ-skills-army-mini#6 on 2026-10-01
(#882), and transferred back as #960 on 2026-10-03 (#955).

## Problem

One device had two clones of the Pulse repo: the hourly git-pulse job kept `~/.config/git-pulse/repo`
current, while every skill link read `~/git-pulse-sync`, 628 commits behind. `sync.py --status`
reported both as healthy because its drift check compares against the local XYZ-forge checkout, not
the Pulse remote.

## Ask

A read-only check in the normal `sync.py` run (preview and `--status`), reported as a named warning
the way drift reports `DRIFTED`: resolve the git-pulse write clone and flag when the collection root
the links read is a different clone, or is behind its remote. Full detail is in the issue.

## Merge evidence

- PR #962 merged 2026-10-04 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
