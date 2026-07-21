---
gh_issue: 261
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261
title: "marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip)"
status: "fixed 2026-07-21 — both real factors confirmed via direct instrumentation, not guessed"
created: 2026-07-21
updated: 2026-07-21
owner: noel
doc_type: bugfix
complexity: 4
risk: 5
effort: 3
phases: 1
ratings_provisional: false
non_goals:
  - Re-porting anything on the Python side — utils/py/marathon_drive.py is already at parity
    (112/0 under XYZ_PYTHON=1, landed via GH-255/PR #262) and is explicitly out of scope here.
  - A partial/half fix. The issue's own author reverted an earlier symlink-strip experiment
    specifically because a fix that greens only one of the two interacting factors below would be
    worse than leaving the gap clean — this is safety-critical containment code.
related:
  - "#255 — Python cutover parity ledger (the sibling issue this was split out of; already CLEARED)"
  - "#171 / #172 — vendored-chain resolution exit-6-where-4/0-expected (the two factors this closes)"
goal: >
  test/marathon-drive.sh is green under XYZ_PYTHON=0 (Bash) at the same commit where it's already
  green under XYZ_PYTHON=1 (Python, done). "Fixed" = the vendored .xyz/ + worktree-isolation +
  macOS $TMPDIR scenario's containment path (relay-turn-lib.sh) no longer wrongly exits 6 where the
  turn should exit 4/0, via a consistent physical/logical canonicalization of RTL_ROOT + the relay
  file path AND correct re-anchoring when TICK_REPO_ROOT is inherited pointing at a different repo.
---

# GH-261 — marathon-drive: Bash-side vendored-chain containment fix (last Phase-1 gate)

## Status
| What was just completed | What's next |
|---|---|
| Fixed 2026-07-21 by direct instrumentation (RTL_TRACE + a temporary CODEX_LOG override, reverted after diagnosis) against a standalone repro AND the real `test/marathon-drive.sh` fixture — not by trusting the issue's own hypothesis at face value. The actual root cause differs in its second half from the issue's original "inherited TICK_REPO_ROOT" theory (see Root cause below): that inheritance is real and does happen, but tracing showed it never actually flips the off-lane verdict on its own. The two real causes were (1) a bidirectional physical/logical symlink-form mismatch between `RTL_ROOT` and an absolute `RTL_ALLOW` entry (confirmed in BOTH directions — RTL_ROOT-physical/entry-logical in the Bash-vendored case, RTL_ROOT-logical/entry-physical in the XYZ_PYTHON=1-vendored case), and (2) `rtl_check()`'s transcript-log exemption only doing an exact-string match against `$RTL_LOG_REL`, missing the git-collapsed-directory form that GH-266 already fixed in `rtl_worktree_end` but never applied to `rtl_check()`. Both fixed together in `relay-automation/relay-turn-lib.sh`. `test/marathon-drive.sh`: 112/112 under both `XYZ_PYTHON=0` and `XYZ_PYTHON=1`, confirmed stable across repeated runs and on a real `ubuntu:latest` Docker container (not just macOS). `bash validate.sh`: 117/117 (after regenerating `skills/relay-automation/relay-pkg.tar.gz`). `utils/pdda/pdda.sh run`: clean. | Close #261 once merged. |

## Problem
`test/marathon-drive.sh` fails under Bash (`XYZ_PYTHON=0`) with assertions exiting 6 (containment
violation) where 4 or 0 is expected, in the vendored `.xyz/` + worktree-isolation + macOS `$TMPDIR`
scenario.

## Root cause (confirmed via direct RTL_TRACE instrumentation, not the issue's original hypothesis)
Two distinct, compounding bugs in `relay-automation/relay-turn-lib.sh` (the permanent Bash
containment boundary), each independently causing a false exit-6:

1. **Symlink-form strip mismatch (bidirectional).** `RTL_ROOT` and an absolute `RTL_ALLOW` entry
   (the relay file, typically) can each independently arrive in EITHER symlink form — e.g. `RTL_ROOT`
   via `git rev-parse --show-toplevel` (physical form) while the caller built the relay-file path
   from its own `$PWD` (logical, symlinked form — macOS's symlinked system dirs are the classic
   trigger), or the reverse depending on which
   code path ran. Confirmed BOTH directions live: the Bash-vendored fixture (GH-171) hit
   RTL_ROOT-physical/entry-logical; the `XYZ_PYTHON=1`-vendored fixture (GH-172) hit the opposite,
   RTL_ROOT-logical/entry-physical. Either direction leaves the repo-root-relative strip in
   `rtl_init` (`${a#"$RTL_ROOT"/}`) a silent no-op — the relay file survives absolute, fails its own
   off-lane match in `rtl_worktree_end`, and the whole turn is wrongly reverted (exit 6).
2. **`rtl_check()`'s transcript-log exemption doesn't handle the collapsed-directory form.** GH-266
   fixed exactly this class of false-positive in `rtl_worktree_end` (a brand-new, fully-untracked
   `relay-system/` directory collapses to one `git status` line, `relay-system/`, which never equals
   a specific transcript file path) — but `rtl_check()`, the sibling non-worktree containment path,
   still only did an exact-string match against `$RTL_LOG_REL` (a deep file path). In the vendored +
   worktree-isolation scenario, `rtl_enforce`'s post-copyback `rtl_check()` pass (running against
   ROOT, not the worktree) hit this exact gap once the transcript log's directory was genuinely new.

The issue's own comment hypothesized a third factor — inherited `TICK_REPO_ROOT` (from
`_setup.sh:97`, unset by neither the GH-171 test's subshell) independently causing exit-6. That
inheritance is real (confirmed via trace: `.tick` claims do land in the wrong repo when it leaks in),
but direct testing showed it does NOT by itself flip the off-lane verdict — reproducing it in
isolation (correct RTL_ROOT symlink form, TICK_REPO_ROOT deliberately leaked) still exited 4 (correct)
until the two real causes above were also present. It's a real, separate bug (wrong `.tick` location)
worth tracking, but not what was gating this issue's own `test/marathon-drive.sh` exit-6 failures.

A prior fix attempt (symlink-strip only, addressing factor 1 in one direction) was deliberately
reverted by the operator — a reasonable call given the diagnosis available at the time predicted a
second, different unresolved factor (TICK_REPO_ROOT). The actual second factor turned out to be
elsewhere (rtl_check's collapsed-directory gap), which is why a from-scratch re-diagnosis (rather
than resuming the prior attempt) was the right call here.

## Fix direction
Canonicalize both `RTL_ROOT` and each absolute `RTL_ALLOW` entry to their physical form before
stripping (covers both mismatch directions), and give `rtl_check()` the same collapsed-directory-aware
transcript-log exemption `rtl_worktree_end` already has (GH-266) so the two containment paths stay in
symmetry.

## Definition of done
- [x] `test/marathon-drive.sh` is green under **both** `XYZ_PYTHON=0` and `XYZ_PYTHON=1` at the same commit — 112/112 each, confirmed stable across repeated runs and on a real `ubuntu:latest` container.
- [x] Factor 1 (bidirectional symlink-form strip mismatch) fixed: both `RTL_ROOT` and each absolute `RTL_ALLOW` entry canonicalized to physical form before the strip.
- [x] Factor 2 (as actually found — `rtl_check()`'s missing collapsed-directory transcript exemption) fixed, mirroring GH-266's `rtl_worktree_end` fix.
- [x] The inherited-`TICK_REPO_ROOT` behavior from the issue's original hypothesis was independently tested and confirmed NOT to be a live cause of this issue's exit-6 failures — documented above rather than fixed, since it's a different (real but separate) concern.
- [x] Regression coverage: `test/marathon-drive.sh`'s existing GH-171 (Bash vendored full chain) and GH-172 (XYZ_PYTHON=1 vendored full chain) cases already exercise the full combined scenario end-to-end (vendored `.xyz/` + worktree isolation + macOS symlinked tmp + real multi-turn chain) — no new test needed; both now pass where they previously failed.
- [x] `bash validate.sh` green in both runtime modes, no worse than baseline — 117/117.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "GH-261" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh", "test/marathon-drive.sh" ],
  "remediation": {
    "source": "issue#261",
    "criteria": "test/marathon-drive.sh is green under both XYZ_PYTHON=0 and XYZ_PYTHON=1 at the same commit. Both compounding factors (symlink-form strip mismatch; inherited TICK_REPO_ROOT re-anchoring) are fixed together, not just one in isolation. bash validate.sh green in both modes."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh", "test/marathon-drive.sh" ] }
}
```
