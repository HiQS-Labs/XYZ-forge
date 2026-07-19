---
gh_issue: 132
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/132
title: "HQ resolution/dispatch hardening — 4 findings from the GH-128 Codex review"
status: Closed — all 4 fixes built + regression-tested on a worktree branch → PR
created: 2026-07-04
updated: 2026-07-04
owner: noel
goal: >
  Close the four resolution/dispatch hardening gaps a headless Codex cross-model review found in the
  shipped HQ feature (GH-128): (1) basename-only resolution could pick the wrong repo, (2) a stale XYZ
  path could arm `fire` at a dead target, (3) an unescaped `park --title` produced invalid YAML while
  still reporting success, (4) a glob-metachar token resolved via the `find` fallback. Each fix is
  proven by a regression test that first reproduces the old failure mode.
doc_type: project
effort: 2
complexity: 3
risk: 2
phases: 1
related:
  - PROJECT/3-COMPLETED/GH-128-HQ-COMMAND-CENTER.md
  - utils/hq/hq-lib.sh
  - utils/hq/hq.sh
  - test/hq-hardening.sh
  - relay-system/2026-07-04/hq-gh-128-code-review.md
non_goals:
  - "No new HQ features — this is hardening only. `fire` still never drives the harness (§8)."
  - "Rebalance stays read-only in HQ's direction (mirrors the #96 seam discipline)."
  - "Owner/repo disambiguation is identity-preserving, not fuzzy: a collision it can't uniquely
    resolve by real git slug returns AMBIGUOUS, it does not pick one."
---

# HQ resolution/dispatch hardening (GH-132)

Follow-up to the shipped HQ command center (GH-128). A headless **Codex** review (relay thread
[`relay-system/2026-07-04/hq-gh-128-code-review.md`](../../relay-system/2026-07-04/hq-gh-128-code-review.md),
verdict *Changes requested*) surfaced four untested edge cases — the full HQ suite was green, so these
are hardening gaps, not regressions. Issue [#132].

## Status

| What was just completed | What's next |
|---|---|
| **All 4 findings fixed + regression-tested on `worktree-hq-gh132-hardening`.** **Blocker 1** (`hq_xyz_lookup`/`hq_repo_resolve`/`hq_resolve`): resolution now preserves `owner/repo` identity — an XYZ basename collision is disambiguated by each candidate's real git origin slug, and if it still can't uniquely resolve it returns **AMBIGUOUS** (`rc=2` + `CANDIDATES`) instead of guessing. **Blocker 2** (`hq_xyz_lookup`): a registry row whose coord no longer exists on disk is skipped, so a stale path can't count as an install or arm Tier A / `fire`. **Should 3** (`hq_yaml_dq` + `hq_render_capture` + `cmd_park`): `park --title` is YAML-escaped, and `park --create` now **fails hard** (rc≠0) when the post-write frontmatter check fails. **Should 4** (`hq_fs_find`): a glob-metachar token is refused before the `find` fallback. New `test/hq-hardening.sh` **11/11** (in `validate.sh`); full HQ suite `hq`/`park`/`dispatch`/`next`/`locator`/`hardening` = 90 checks green; shellcheck (`-S warning`) + `pdda.sh run` clean. | Open the PR against `main`; on merge, PDDA-sweep this doc to `3-COMPLETED` and close #132. |

## The four fixes

1. **Blocker — owner/repo identity (wrong-repo resolution).** `hq_xyz_lookup <repo> [<slug_hint>]`
   collects *all* live basename matches; on a collision it keeps only candidates whose real
   `owner/repo` (from `git config remote.origin.url`, via `hq_target_slug`) equals the slug hint
   (an owner-carrying query, or the Rebalance project name). Unique → resolve; else emit
   `XYZ_AMBIGUOUS` and let `hq_resolve` return `rc=2`. Honors the "never guess a path" contract.
2. **Blocker — stale XYZ path arms `fire`.** `hq_xyz_lookup` now skips any registry row whose coord
   is not an existing directory (`[ -d "$coord" ]`). A stale install no longer emits `XYZ_PATH`, so
   `has_xyz=0` → not Tier A → `fire` refuses (and `REPO_PATH` falls back to the filesystem/empty).
3. **Should — `park --title` YAML injection + false success.** `hq_yaml_dq` escapes `\` and `"` for
   the double-quoted frontmatter scalar; `cmd_park --create` now returns non-zero (with a clear
   message) when the target's `pdda.sh frontmatter` check fails, instead of warning and exiting 0.
4. **Should — `find -name` glob.** `hq_fs_find` refuses a token containing `* ? [` before the
   filesystem fallback, so `resolve '*'` is UNRESOLVED rather than silently matching the first repo.

## QA gate — GH-132

- [x] Blocker 1: `FooOrg/api` vs `BarOrg/api` resolve to the correct install; bare `api` and an
      unknown owner return `rc=2` AMBIGUOUS (never a wrong path). `test/hq-hardening.sh`.
- [x] Blocker 2: a stale XYZ coord → `resolve` UNRESOLVED (no `XYZ_PATH`) and `fire` refuses
      (no `GATES PASS`). `test/hq-hardening.sh`.
- [x] Should 3: `hq_render_capture` emits valid YAML for a quoted/backslash title; `park --create`
      succeeds on the escaped doc and fails hard when the frontmatter check fails. `test/hq-hardening.sh`.
- [x] Should 4: `resolve '*'` is UNRESOLVED; a literal name still resolves via `find`. `test/hq-hardening.sh`.
- [x] No regressions: full HQ suite 90 checks green; shellcheck `-S warning` clean; `pdda.sh run` clean.
