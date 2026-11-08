# GH-1286 gates (commit d26b2845)

- **Route:** `git diff --name-only origin/development...HEAD | bash utils/ci-route.sh pull_request` →
  `route=docs`, `tier=1`, `docs_only=true`, `full_required=false`.
- **Where:** disposable full clone `XYZ-forge-gh1286-ceremony-audit-2026-10-31-gate`, checked out at
  `d26b2845`; worktree clean before and after.
- `bash utils/pdda/pdda.sh run` → exit 0, `no errors`. The only findings naming this change are two
  `pdda-check-issue-doc-sync` warnings that #1286's state was unavailable: the gate clone's origin is the
  local task clone, so `gh-refresh` cannot resolve the issue. Not evaluated, not failed.
- `bash test/gh589-skill-viewer.sh` → exit 0, `8 passed, 0 failed` (it inventories every Forge skill,
  including the new folder).
- **Not run, by design (plan QA round 1):** `test/gh620-skills-army-mini-sync.sh`,
  `test/gh589-consult-no-tick.sh`, `test/gh589-xyz-mini-sync.sh`. The publishers ship only explicitly
  listed paths (`utils/py/xyz_mini_sync.py:63-120`); `skills/1-hourly/ceremony-audit` is not listed, and
  `test/gh589-xyz-mini-sync.sh:128-130` asserts unlisted skills never ship.
