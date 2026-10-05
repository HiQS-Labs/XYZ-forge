---
gh_issue: 970
source: https://github.com/HiQS-Labs/XYZ-forge/issues/970
title: "start-task + SOP: deterministic task-clone folder and branch names (<repo>-gh<id>-<desc>-<yyyy-mm-dd>, sibling of the primary)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-05
doc_type: feedback
---

# GH-970: deterministic task-clone names

## Ask

Task clones and branches follow one formula instead of each agent's choice:

- folder `<repo-name>-gh<issue>-<very-short-desc>-<yyyy-mm-dd>`, a sibling of the primary clone;
- branch `<type>/<folder>`, where `<type>` is `feat`, `fix`, `chore` or `docs`.

Edge cases: a multi-issue group uses its lowest issue number; `-gate`/`-verify` helper clones; look for an
existing `<repo-name>-gh<issue>-*` sibling (resume) before creating; never a numbered duplicate.

## Acceptance

`start-task` step 3 and the `SOP.md` fresh-clone example state the formula; `AGENTS.md`'s branch carve-out lists the
four types; docs gate green; Codex final QA approved; Skills Army deployed copy refreshed after merge.

## Rating (2026-10-05)

`rated 55/40/50/85`. Severity 40: no data loss, but inconsistent names hid 50 clones across three roots and broke
`--prefix` scans (merge-cleanup-deep, 2026-10-05). Priority 55: operator-requested, recurring every task. Appeal 50
neutral. Effort 85: three text edits.
