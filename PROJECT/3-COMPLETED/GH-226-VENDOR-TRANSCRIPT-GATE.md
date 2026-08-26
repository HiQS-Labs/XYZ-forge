---
title: "GH-226: xyz-vendor.sh transcript gate refuses repos that gitignore transcripts"
status: Complete
created: 2026-08-24
updated: 2026-08-24
owner: Antigravity / Gemini 3.7 Flash
goal: allow downstream repositories with gitignored transcript trees to vendor .xyz without bypassing marathon transcript safety
gh_issue: 226
source: https://github.com/HiQS-Labs/XYZ-forge/issues/226
branch: development
doc_type: bugfix
effort: 2
complexity: 1
risk: 2
related:
  - "#224 — Linux-RC release carrier"
  - "#514 — marathon runtime transcript write-set preflight"
---

# GH-226 — xyz-vendor transcript gate refusal downgrade

## Status

| What was just completed | What's next |
|---|---|
| Downgraded ensure_gitignore exit 6 refusal to advisory WARNING banner; refreshed relay-pkg.tar.gz (freshness 3/3 green); test/xyz-vendor.sh (65/65 green); Qwen 3.8 Max QA completed and all recommendations addressed | Closed |

## Plan

1. In `relay-automation/xyz-vendor.sh` (`ensure_gitignore`), replace the hard `exit 6` refusal when `phases/` or `relay-system/` is gitignored with an advisory `WARNING` banner explaining why transcripts should be committed.
2. Allow vendoring to continue safely, delegating runtime trackability enforcement to `marathon_drive.py`'s `preflight_write_set_trackable` (GH-514, exit 2).
3. Rebuild `skills/relay-automation/relay-pkg.tar.gz` via `make-pkg.sh` and verify with `test/relay-pkg-freshness.sh`.
4. Update `test/xyz-vendor.sh` to assert vendoring succeeds (exit 0) on ignored paths, emits the warning banner, preserves original gitignore rules, and adds `.xyz/` / `/.tick/`.
5. Review via `/review-xyz` with Alibaba Qwen 3.8 Max and incorporate feedback.

## Acceptance

- `bash test/xyz-vendor.sh` passes 65/65 green.
- `bash test/relay-pkg-freshness.sh` passes 3/3 green.
- `bash test/gh314-transcript-writeset.sh` passes 7/7 green.
- Issue #226 closed with commit citations.

## Lessons Learned (For Future Agents)

- Separation of concerns between install/vendor time and run/marathon time: static onboarding/vendoring should advise rather than hard-block downstream repos that intentionally withhold local transcript logs from public remotes, while runtime drivers (`marathon_drive.py`) enforce the hard trackability invariants when a marathon actually fires.
- Package tarballs (`skills/relay-automation/relay-pkg.tar.gz`) must be rebuilt via `make-pkg.sh` whenever `relay-automation/xyz-vendor.sh` is modified, verified by `test/relay-pkg-freshness.sh`.
