---
title: Same-device cross-repo swarm readiness — drive XYZ/marathon against an external target repo
status: Active — Phase 1 in progress
created: 2026-06-24
updated: 2026-06-24
owner: noelsaw1
branch: main
gh_issue: 16
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/16
goal: >
  An agent whose VS Code workspace is the target repo (e.g. sleuth-app) can run a multi-lane swarm on
  macOS, same-device, without the harness reverting its own output. Umbrella epic: one NEW bug (Phase 1)
  plus existing issues sequenced toward that goal.
scope: Same device only; target repo lives OUTSIDE xyz-3-agents-swarm's VS Code workspace. Not cloud.
tracks: "#11, #13, #15, #12 (closed), #3, #4, #5"
related:
  - relay-automation/relay-turn-lib.sh
  - relay-automation/relay-drive.sh
non_goals:
  - Cloud / cross-machine swarm (this epic is same-device only)
  - Harness-clone-as-workspace (already supported today)
---

## Status

| What was just completed | What's next |
|---|---|
| Epic filed (#16) + Phase 1 bug (#17); local tracking doc + ROADMAP pointer landed | **Phase 1 — fix the macOS case-sensitivity revert in `rtl_in_allow` + regression test** |

## Problem

Driving a swarm against an external repo on the same machine fails on macOS: a reviewer turn's edit to
the allowlisted relay file is reverted with **exit 6**. The cause is a case mismatch — `git status`
emits the path in the case the index tracks (`RELAY-SYSTEM/…`) while the harness allowlist holds the
literal lowercase invocation arg (`relay-system/…`), and the comparison
([relay-turn-lib.sh:77](../../relay-automation/relay-turn-lib.sh#L77)) is case-sensitive. Cross-repo
routing (#11) and isolation (#15/#13) are already underway; this epic adds the missing case fix and a
same-device quickstart, and verifies the rest on macOS against a foreign target.

## Phase 1 — macOS case-sensitivity revert (NEW — bug #17)

**Exact mechanism (verified):**
- `rtl_in_allow()` ([relay-turn-lib.sh:77](../../relay-automation/relay-turn-lib.sh#L77)): `for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] ...` — case-sensitive.
- `rtl_init` ([relay-turn-lib.sh:52-75](../../relay-automation/relay-turn-lib.sh#L52-L75)) builds `RTL_ALLOW` from the literal `RELAY_FILE` arg, normalizing only to repo-root-relative (not case).
- `rtl_check` ([relay-turn-lib.sh:239-242](../../relay-automation/relay-turn-lib.sh#L239-L242)) reverts off-allowlist paths via `git -C "$RTL_ROOT" checkout -- "$p"` then sets the violation → `rtl_enforce` `exit 6`.

**Fix (chosen approach):**
- [ ] In `rtl_init`, set `RTL_IGNORECASE` from `git -C "$RTL_ROOT" config --get core.ignorecase`.
- [ ] In `rtl_in_allow`, when `RTL_IGNORECASE=true`, compare both sides lowercased; otherwise exact compare (Linux byte-for-byte unchanged).
- [ ] Regression test with a mixed-case tracked path against a case-insensitive repo.
- [ ] Document recovery for in-flight runs: the agent's review survives in the codex transcript at the real `$TMPDIR/<CODEX_LOG>` (not the sandbox tmp).

**QA**
- [ ] A reviewer turn that appends to the relay file is accepted (no exit-6, no revert) on default macOS APFS, even with a mixed-case tracked path.
- [ ] Test fails before the fix, passes after.
- [ ] Case-sensitive filesystem (Linux CI) behaves byte-for-byte as before.

**Anti-goals (Phase 1)**
- Do not change the reviewer-scoping or commit-bypass guards; this phase only touches the allowlist-path comparison.

## Phase 2 — Cross-repo target-root routing (tracks #11)

- [ ] Confirm `RELAY_TARGET_ROOT` / `--target-root` routes worktree base, allowlist copyback, file-scoped commit, and enforce from the foreign root.
- [ ] `.tick` coordination stays at `TICK_REPO_ROOT` (harness clone); only the artifact side moves.
- [ ] Foreign-CWD / nested-dir / spaces-in-path matrix passes on macOS.

**QA**
- [ ] Swarm launches with workspace = target repo, harness elsewhere on the same device; no harness files in the target's `git status` unless scoped.

## Phase 3 — Worktree isolation for cross-repo artifacts (tracks #15, #13)

- [ ] Read-only seed set lets an isolated reviewer READ an uncommitted/cross-repo artifact (#15).
- [ ] Commit-bypass guard no longer orphans a peer's concurrent commit (#13).

**QA**
- [ ] An isolated reviewer reads the target artifact without it landing on the writable allowlist; concurrent peer commits are preserved.

## Phase 4 — Concurrency on a foreign repo (tracks #3, #4, #5; verify #12)

- [ ] Re-verify foreign-CWD `tick` (#12, closed) holds when claimed paths live in the target repo.
- [ ] Lane imbalance / no work-stealing (#4) and coupled-lane warnings (#5) behave when lanes are scoped to target-repo paths.
- [ ] Parked-claim threshold (#3) doesn't false-positive on long atomic tool calls.

**QA**
- [ ] Two lanes claiming non-overlapping target-repo paths run concurrently, zero collisions; honest concurrency metric reflects it; a coupled-lane pair warns.

## Phase 5 — Install path + end-to-end smoke (NEW)

- [ ] Documented way for a target repo to reach the harness on the same device (PATH shim / vendored / brew-npm — pick one).
- [ ] E2E smoke: a 2-lane swarm against an external repo on macOS, both lanes committing non-conflicting changes.
- [ ] Quickstart README for driving a swarm on a foreign repo.

**QA**
- [ ] Smoke run green on a clean macOS machine following only the README; no exit-6; escalation + events land outside the target tree.
