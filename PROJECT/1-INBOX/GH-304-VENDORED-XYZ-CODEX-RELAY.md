---
title: Vendored .xyz relay lane is broken for Codex but works for agy
status: Proposed (1-INBOX — not yet active)
created: 2026-07-26
owner: noel
gh_issue: 304
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/304
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: true
reported_from: rebalance-OS
harness_commit: e8cd951
non_goals:
  - Changing where new-relay.sh writes threads by default (behaviour change, separate call)
  - Fixing #296's EPERM-on-tick-lock, which shares the environment but not the mechanism
related:
  - https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/292
  - https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/296
  - https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272
goal: >
  A Codex relay driven from a repo with a vendored .xyz/ either completes normally, or
  fails with a message that names the real cause and the fix. Today it fails 100% of the
  time while the identical lane driven with agy succeeds, so the breakage is invisible to
  anyone who validates with agy.
---

# GH-304 — Vendored `.xyz` relay lane is broken for Codex but works for agy

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward.

This capture is a **second, independent reproduction** of #304, filed from a different repo at a
newer harness commit. The original diagnosis in #304 is correct; this doc exists to park the new
finding (worker-dependent failure) and the corroborating evidence.

## Symptom

A relay thread stored under a vendored `.xyz/relay-system/` cannot be driven with Codex. Isolation
ON: the file is outside Codex's project boundary and the write is rejected. Isolation OFF: the
CWD-relative path is unreachable. Both fail 100% of the time. **The identical lane driven with agy
succeeds.**

## Environment

- **Observed from:** `rebalance-OS` (vendored `.xyz/` at repo root, no `.xyz/.git`)
- **Harness commit:** `e8cd951` — current HEAD, newer than #304's `efdb394c54ed`
- **Vendored:** `source_commit=e8cd95154830`, `tick_version=0.2.0`, `vendored_utc=2026-07-26T16:01:18Z`
- **Worker/CLI:** Codex CLI (failing) and agy CLI (succeeding), same session, same config
- **Runtime:** Python (default — `XYZ_PYTHON` unset)
- **Sandbox:** off (per the relay-xyz skill's guidance; failure reproduces regardless)

## Reproduction

1. Repo has `.xyz/` vendored at root via `xyz-vendor.sh`.
2. Follow the relay-xyz Preconditions verbatim: `eval "$(find-harness.sh --env)"; cd "$HARNESS"`.
3. `relay-automation/new-relay.sh --title T --reviewer codex --artifact-file <abs> --embed --slug S`
   → writes `.xyz/relay-system/<date>/S.md`.
4. Seed the token: `tick log task.created` / `tick claim` / `tick release --to codex`.
5. Drive it:
   ```bash
   CODEX_AGENT=codex ALLOW_PATHS="" RELAY_PEER=claude-a \
   relay-automation/relay-drive.sh --relay-file relay-system/<date>/S.md \
     --relay-task RELAY-S --agent-cmd relay-automation/codex-turn.sh \
     --artifact-file <abs> --review-once
   ```

**Expected:** Codex appends a review block and hands the token back — as agy does in step 5 when
`--reviewer agy` / `agy-turn.sh` are substituted.

**Observed:** `DRIVE_EXIT=3` (genuine stall), no review content. With
`RELAY_WORKTREE_ISOLATION=0`, also `DRIVE_EXIT=3`, different message.

**Frequency:** every time — 3 attempts across 2 isolation configurations.

```text
# isolation ON
ERROR codex_core::tools::router: error=patch rejected: writing outside of the project;
      rejected by user approval settings
codex: The requested relay file is only present in the pinned coordination checkout, which this
       session may read but is not permitted to modify; the worktree has no copy.

# isolation OFF
codex: The claimed relay file and designated artifact are absent from this workspace, so I can't
       perform or record the review without violating the file-scope constraint.
relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact;
             with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.
```

## Impact

`xyz-vendor.sh` is documented as *the* path to concurrent per-repo relays, and Codex is one of the
two documented builders — so that combination is unusable. Severity is raised by the fact that it
is **silent**: agy passes the same lane, so a smoke test with agy reports green.

Workaround (confirmed working, exit 5 with real findings): scaffold **and** drive from the live
harness clone, with the artifact `--embed`ed so no cross-repo path needs resolving. Costs the
per-repo driver lock that vendoring exists to provide.

## Phase 0 — Diagnose & scope

### Checklist
- [ ] Reproduce in the intake repo with a vendored `.xyz/` (both isolation modes)
- [ ] Decide the fix shape: seed the relay file into the worktree, or resolve `--relay-file`
      against `$HARNESS` in the turn prompt, or refuse early with a named cause
- [ ] Whichever is chosen, the write target must land **inside** Codex's project boundary —
      seeding for read alone does not fix isolation-ON
- [ ] Add a `find-harness.sh --check` warning for vendored `.xyz` + Codex until fixed
- [ ] Distinguish "relay content unchanged" from "changed but untracked" in the driver message
      (#304 secondary finding, corroborated here — gitignored `relay-system/` makes pass and fail
      print identically)

### QA checklist — Phase 0
- [ ] Repro confirmed in-repo, not assumed from the two external reports
- [ ] A regression test drives a vendored-`.xyz` relay with **both** workers and asserts parity
- [ ] The fix composes with the existing worktree-seeding step rather than adding a parallel path
