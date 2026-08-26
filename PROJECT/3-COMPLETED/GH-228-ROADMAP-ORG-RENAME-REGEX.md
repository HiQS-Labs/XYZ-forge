---
title: "GH-228: Org rename HiQS-Suite -> HiQS-Labs regex widening in roadmap sync and script defaults"
status: Complete
created: 2026-08-24
updated: 2026-08-24
owner: Antigravity / Gemini 3.7 Flash
goal: support HiQS-Labs URLs in roadmap sync without dropping issue links while maintaining legacy backward compatibility
gh_issue: 228
source: https://github.com/HiQS-Labs/XYZ-forge/issues/228
branch: development
doc_type: bugfix
effort: 1
complexity: 1
risk: 2
related:
  - "#224 — Linux-RC release carrier"
  - "#69 — ROADMAP shadow in releases.db"
---

# GH-228 — Roadmap Org Rename Regex Widening and Defaults

## Status

| What was just completed | What's next |
|---|---|
| Widened issue/pull URL regex in releases_app.py to HiQS-(?:Suite|Labs); updated fix-gh-default.sh and build-launch-artifact.sh; added regression assertions in test/gh69-roadmap-shadow.sh (55/55 green); Qwen 3.8 Max QA Approved | Closed |

## Plan

1. In `utils/py/releases_app.py` (`parse_roadmap_ledger`), widen the issue regex from `HiQS-Suite` to `HiQS-(?:Suite|Labs)` so both legacy and new org URLs parse cleanly into `issue_url`.
2. In `evidence/_env/fix-gh-default.sh`, update target repository to `HiQS-Labs/XYZ-forge`.
3. In `utils/build-launch-artifact.sh`, update `DEFAULT_REMOTE` to `https://github.com/HiQS-Labs/XYZ-forge.git`.
4. In `test/gh69-roadmap-shadow.sh`, add test fixtures and assertions validating both legacy `HiQS-Suite` and new `HiQS-Labs` issue and PR URLs.
5. Review via `/review-xyz` with Alibaba Qwen 3.8 Max.

## Acceptance

- `bash test/gh69-roadmap-shadow.sh` passes 55/55 green.
- `bash test/wave-reconcile.sh` passes 11/11 green.
- `bash test/gh103-timeline-exporter.sh` passes 38/38 green.
- Issue #228 closed with commit citations.

## Lessons Learned (For Future Agents)

- Git redirects handle remotes during an organization rename, but hardcoded string matches and regexes in code will silently fail or drop extracted fields without raising explicit errors unless tested with both old and new org patterns.
- Always use non-capturing groups `(?:...)` when widening alternations in regexes where positional capture group indexing is used downstream.
