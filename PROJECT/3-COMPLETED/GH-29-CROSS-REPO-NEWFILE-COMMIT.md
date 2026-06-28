---
title: Cross-repo (--target-root) build doesn't commit NEW untracked files
status: Completed
created: 2026-06-27
updated: 2026-06-27
owner: noelsaw1
branch: main
gh_issue: 29
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29
parent: GH-16 (same-device cross-repo swarm readiness)
goal: >
  A cross-repo (--target-root) builder turn that CREATES new files must commit them — not report
  "no tracked changes" and silently drop the build. Unblocks unattended cross-repo dogfooding.
doc_type: project
---

## Status

| What was just completed | What's next |
|---|---|
| **Fixed + regression-locked 2026-06-27.** Root cause found and corrected in the relay containment kernel; `validate.sh` **54/54**; issue #29 closed. The first-wave dogfood blocker is cleared. | Re-run a cross-repo marathon that ADDS files (e.g. the WPCC `ts-type-suppression` v2/v3 path, or the Apple Reminders Phase 2 candidate) to confirm end-to-end commit under `--target-root` without hand-commit. |

## Symptom (first real marathon dogfood, 2026-06-26)
`marathon-drive --target-root WP-Code-Check` built a correct, gate-passing, reviewer-Approved
detector — but the shim reported `claude/codex/agy turn produced no tracked changes (token-only
move?)` and **committed nothing**. The new `dist/patterns/*.json` + fixture sat **untracked**, and
the modified registry files were left `M`. Recovered only by a manual `git add` + commit.
`RELAY_WORKTREE_ISOLATION=0` did **not** help (v3 gapped identically).

## Root cause
The file-scoped commit in `rtl_enforce` ([relay-automation/relay-turn-lib.sh](../../relay-automation/relay-turn-lib.sh))
batched the whole allowlist in one command:

```sh
git -C "$RTL_ROOT" add -- "${RTL_ALLOW[@]}" 2>/dev/null || true
```

`git add` is **atomic over its pathspecs**: if *any* one matches nothing, it aborts with
`fatal: pathspec '…' did not match any files` and stages **NOTHING**. A build allowlist routinely
lists paths the turn is *permitted* to create but doesn't (optional outputs, alternative file names).
One such non-matching entry dropped the entire commit — which is why even the **modified** tracked
files were left uncommitted, not just the new ones (the tell that it was a whole-batch abort, not a
new-file-only miss). Same-repo runs happened to have fully-matching allowlists, so they committed
cleanly and the gap stayed invisible until the first `--target-root` add-files build.

## Fix
Stage each allowlisted path **independently**, tolerating a non-match:

```sh
local _ap
for _ap in "${RTL_ALLOW[@]}"; do
  git -C "$RTL_ROOT" add -A -- "$_ap" 2>/dev/null || true
done
```

`-A` per path stages additions, modifications, AND deletions; `|| true` lets a non-matching entry
fall through so the rest still stage. New untracked files are added safely because they already
passed `rtl_enforce`'s exact-match allowlist check above (they are on-lane). The worktree-isolation
copy-back (`rtl_worktree_end`) already propagates new allowlisted files from the throwaway worktree
into `RTL_ROOT`, so the fix completes the path for both isolation ON and OFF.

## Verification
- **Isolated proof:** batched `git add -- existing newfile never-created` → aborts, stages nothing;
  per-path `git add -A` → stages `existing` + `newfile`, tolerates `never-created`.
- **Regression test:** [test/relay-target-root-newfile.sh](../../test/relay-target-root-newfile.sh)
  (6 assertions) drives a real cross-repo turn whose allowlist includes a never-created path, and
  asserts the new file + the modified file both commit in the foreign repo while the harness repo
  stays clean. Registered in `validate.sh` → **54/54**.

## Sibling
GH-22 fixed the same-repo relay-file copy-back; this fixes the cross-repo new-file commit path. Both
are children of GH-16 (same-device cross-repo swarm readiness).
