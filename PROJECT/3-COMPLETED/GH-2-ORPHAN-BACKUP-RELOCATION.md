---
title: "GH-2: test-suite run relocated an untracked file into .tick/orphan-backups/"
status: Complete
created: 2026-08-22
updated: 2026-08-24
owner: orchestrator (Claude Code)
goal: reproduce the untracked-file relocation, then guard every mv/rm/find-delete on a derived path with a resolved-containment check at the use boundary
gh_issue: 2
source: https://github.com/HiQS-Labs/XYZ-forge/issues/2
branch: gh-2/orphan-backup-relocation
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#1 — same containment family (unguarded empty/derived path redirecting file ops onto real content); #1 owns require_fixture, this owns the mv/rm audit"
---

# GH-2 — untracked file relocated into .tick/orphan-backups/

## Status

| What was just completed | What's next |
|---|---|
| Parallel mktemp-failure reproducer implemented and registered; focused run passed 12/0 in both polarities; destructive-path audit recorded below. | Agy reviews the lane; the harness runs the full gate after the turn. |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: suite-containment class
(RADAR-class-suite-containment), data-loss polarity.

## Bug

A test-suite run moved an untracked file from a project docs directory into
`.tick/orphan-backups/`. Observed once, not yet reproduced. Same family as #1's sandbox
escape: an unguarded empty/derived path variable redirecting file operations onto real
content — silent data loss for anything not under version control. Known trigger condition:
`mktemp` failure under parallel load.

## Plan

1. Reproducer `test/gh2-orphan-backup-repro.sh`: force the mktemp-failure path under parallel
   load and assert no file outside the fixture moves (negative control: with the guard stubbed
   out, the relocation must be detected).
2. Audit every suite + harness script for `mv` / `find -delete` / `rm -rf` on derived paths;
   each call site gains a resolved-containment check at the use boundary (reusing #1's
   `require_fixture` helper where present — consuming it, not editing it).
3. Register the suite in validate.sh TESTS.

## Destructive-path audit (2026-08-24)

Method: `rg` over `test/**/*.sh` and `relay-automation/**/*.sh` found 232 suite-side and
40 harness-side literal `mv` / `find -delete` / recursive-`rm` matches. Each match was then
classified by its derived root, because fixed-file moves and fixed descendants of an already
pinned root cannot acquire the empty-root failure mode merely from an empty leaf. Literal sibling
calls sharing the same root derivation are kept together below; every matching harness line is
named in the `Calls` column.

The suite-side inventory is mechanically covered by the existing GH-1/GH-10 adoption gate:
`test/gh1-adoption-guard.sh` derives every `mktemp` + (`git -C` | `cd`) suite live and requires
direct `fixture_guard_init`, verified `_setup.sh` adoption, or a reason-bearing exemption. Its
committed ledger reports **Unaudited suites: 0**. The five destructive-fixture suites outside that
derivation were also read directly: `agent-chorus.sh`, `ballast-release.sh`,
`nightwatch-release.sh`, `registry-lock-concurrency.sh`, and `releases-skill.sh`; each refuses an
empty/invalid root before arming cleanup or confines every later operation to a fixed descendant
of that checked root. `test/gh2-orphan-backup-repro.sh` consumes the shared helper at the dangerous
use boundary and its guard-stub polarity proves the check is discriminating.

| Surface / derived root | Calls | Resolved-containment check at the use boundary |
|---|---|---|
| `claude-turn.sh` shadow root | 219, 234 recursive removal | `set -e` makes failed `mktemp -d` terminal; both uses additionally require non-empty `shadow_dir`. |
| `consult.sh` throwaway worktree | 144 recursive fallback removal | `WT` is a fixed basename under `${TMPDIR:-/tmp}` and cleanup is armed only around a successful `git worktree add`; the Git removal is attempted first. |
| `consult.sh` atomic output siblings | 212, 344, 390 `mv` | Each source is constructed beside its already-open destination (`$out.tmp`, `$out.stamped`, `$survivor_out.stamped`); no independently derived root. |
| `marathon-drive.sh` driver lock | 224, 241 recursive removal | `_lock` comes from the resolved Git common dir or the non-empty `ROOT`; removal occurs only after the lock exists and dead-holder/ownership flow selects it. |
| `relay-drive.sh` driver lock | 174, 189 recursive removal | Same shared-common-dir derivation and live-holder refusal as marathon-drive; cleanup targets the acquired lock. |
| `relay-drive.sh` control-verdict prompt | 525 file removal | File-only removal of a non-empty path returned by the prompt-file creation branch; recursive/root deletion is impossible. |
| `relay-turn-lib.sh` worktree root | 701, 703, 869 recursive removal | `mktemp -d ... || return 1` proves non-empty existing `$wt`; worktree creation must then succeed. Cleanup tries `git worktree remove` before the fallback. |
| `relay-turn-lib.sh` seeded allowlist descendants | 723 recursive removal | `$wt` passed the worktree-root proof above; `$a` is a normalized repo-relative allowlist member from `rtl_init`. |
| `relay-turn-lib.sh` copyback temp | 849 recursive removal; 855, 859 `mv` | `_tmp` is built as a fixed sibling beneath canonicalized non-empty `RTL_ROOT` and normalized `$a`; it is created by the immediately preceding `cp -R` before rename. |
| `relay-turn-lib.sh` copyback destination | 854, 863 recursive removal | `RTL_ROOT` is canonicalized in `rtl_init`; `$a` must be an allowlisted repo-relative path, and the operations run only after worktree containment reports no off-lane path. |
| `relay-turn-lib.sh` sidecars | 868 file removal | Fixed suffixes of the proven `$wt`; non-recursive. |
| `relay-turn-lib.sh` relay scratch | 1001, 1227 recursive removal | Both use `${RTL_ROOT:?}/.relay-scratch`; the `:?` expansion is the use-boundary empty-root refusal and the leaf is fixed. |
| `relay-turn-lib.sh` transcript log | 1005 file removal | Non-empty `RTL_LOG_REL` exact-match gate before a non-recursive removal beneath canonicalized `RTL_ROOT`. |
| `relay-turn-lib.sh` off-lane revert / orphan-backup trigger | 1022 recursive fallback removal | Normal harness entry goes through canonicalized `rtl_init`; suite callers must prove their derived fixture before invoking it. The new suite is the executable proof: active guard preserves all six sentinels; stubbing the guard relocates all six through this exact call. |
| `relay-turn-lib.sh` citation rewrite | 1083 `mv` | `$tmp` is a fixed sibling of an existing regular `$f`; `[[ -n "$f" && -f "$f" ]]` gates the function. |
| `xyz-sync.sh` registry rewrite | 232 `mv` | `$tmp` is a fixed sibling of the validated registry path and is renamed only after a successful complete write. |
| `xyz-sync.sh` selected install deletion | 359 recursive removal | `safe_registered_xyz_dir` immediately precedes each use and refuses a selected path that is not a registered `.xyz` directory. |
| `xyz-vendor.sh` advisory locks | 70, 136, 148, 159 recursive removal | Every `lockdir` is derived beside a validated target file; removal additionally requires dead/empty or current-process ownership. |
| `xyz-vendor.sh` stage root | 76, 331 recursive removal; 344 `find -delete`; 375 recursive removal | `TARGET_REPO` is type-checked then physically resolved; `STAGE_DIR` is its fixed `.xyz.tmp.$$` child. Every use stays under that resolved target. |
| `xyz-vendor.sh` registry atomic rewrite | 202 `mv` | `$tmp` is a fixed sibling of `$reg`, written completely while holding the advisory lock before rename. |
| `xyz-vendor.sh` vendor destination | 380 recursive removal; 381 `mv` | `VENDOR_DIR` is the fixed `.xyz` child of physically resolved `TARGET_REPO`; the populated checked stage is renamed into exactly that location. |

No production call site needed a behavior edit in this lane: the uncovered failure was the
suite-side missing use-boundary check before a real harness function was invoked with the caller's
repo as its accidentally derived root. The active/control pair pins that boundary without weakening
`rtl_check`'s intentional off-allowlist removal behavior.

## Acceptance

- [x] Reproducer green with the guard active: nothing outside the fixture moves under simulated `mktemp` failure.
- [x] Reproducer green with the guard stubbed out: the relocation is detected (negative control).
- [x] Audit table of every `mv`/`find -delete`/`rm -rf` call site on a derived path recorded in the capture doc, each carrying a resolved-containment check.
- [x] `test/gh2-orphan-backup-repro.sh` green (12 passed, 0 failed) and registered in validate.sh.

Focused verification: `bash -n test/gh2-orphan-backup-repro.sh validate.sh` and
`bash test/gh2-orphan-backup-repro.sh` both exited 0. Per the relay lane rail, the builder did not
run the full project gate; the harness owns that post-turn run.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh2-orphan-backup-repro.sh" } ],
  "artifacts":     [ "test/gh2-orphan-backup-repro.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh2-orphan-backup-repro.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "reproducer green in both polarities; every audited mv/rm/find-delete call site on a derived path carries a resolved-containment check" },
  "lanes":         { "agy_safe": [ "test/gh2-orphan-backup-repro.sh" ], "orchestrator_only": [ ".tick/" ] }
}
```

## Lessons Learned (For Future Agents)

- The trigger is `mktemp` failing under PARALLEL load — a serial re-run reproduces nothing and must
  not be read as an all-clear (same family as GH-177/GH-1).
- The fix belongs at the USE boundary: every `mv`/`find -delete`/`rm -rf` on a derived path gets a
  resolved-containment check (`require_fixture`), recorded as an audit table in this doc. Guarding
  only the assignment site leaves later derivations unguarded.
- The reproducer's negative control (guard stubbed out → relocation must be DETECTED) is what makes
  the suite falsifiable; without it a green run proves only that the test ran.
