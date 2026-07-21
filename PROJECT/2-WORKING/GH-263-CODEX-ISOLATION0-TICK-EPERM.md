---
title: codex-turn.sh isolation=0 path lacks the GH-36 --add-dir .tick fix → EPERM on token claim in vendored installs
status: "promoted to 2-WORKING 2026-07-21 via /10days sweep with an auto-drafted contract"
created: 2026-07-20
owner: noelsaw1
gh_issue: 263
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/263
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
reported_from: hyper-pandas-python-stack
harness_commit: b0e15ee
non_goals:
  - Redesigning worktree isolation or the default isolation=1 driven path (that path already works).
  - Changing the relay-xyz skill's `cd $HARNESS` instruction (fix belongs in the shim, not the doc).
related:
  - "#36 — Headless Codex isolated-turn friction: .tick lock outside the workspace sandbox (the fix this follows up)"
  - "#248 — Turn shims root at the shim's own repo on non-vendored runs"
  - "#234 — find-harness.sh --env exports TICK_REPO_ROOT one directory too deep"
goal: >
  A Codex turn driven with RELAY_WORKTREE_ISOLATION=0 in a vendored .xyz/ install (from the
  documented `cd $HARNESS` CWD) can claim the parent-root .tick token and run its turn WITHOUT
  disabling Codex's own sandbox entirely. "Fixed" = the isolation=0 path grants Codex write access
  to $TICK_REPO_ROOT/.tick (or roots Codex at ROOT), and a regression test covers the claim path.
---

# GH-263 — codex-turn.sh isolation=0 path lacks the GH-36 --add-dir .tick fix

## Status
| What was just completed | What's next |
|---|---|
| Promoted from `1-INBOX` to `2-WORKING` 2026-07-21 by the `/10days` sweep; verified still open & reproducible — `relay-automation/codex-turn.sh:157` still sets `codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")` only inside the `RELAY_WORKTREE_ISOLATION=1` branch (~line 151-163); the `isolation=0` default path (falls through with `codex_extra_flags=()` from line 137) sets nothing. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |

## Symptom
In a vendored `.xyz/` install, driving a Codex turn with `RELAY_WORKTREE_ISOLATION=0` fails before
the turn starts: Codex hits `EPERM` creating the `.tick` lock and cannot claim the relay token.

## Environment
- **Observed from:** `hyper-pandas-python-stack` (vendored `.xyz/`, source_commit `52a94ef`, tick 0.2.0)
- **Harness commit:** `b0e15ee` (bug present in live, not only the stale vendored copy)
- **Worker/CLI:** codex v0.144.6
- **Sandbox:** Claude Code Bash sandbox OFF; **Codex's own `workspace-write` sandbox ON** (the relevant one)

## Reproduction
1. Vendored `.xyz/` install; `cd "$HARNESS"` (= `.xyz`) per the relay-xyz skill.
2. Drive a review with `RELAY_WORKTREE_ISOLATION=0` — required to review **uncommitted** files, since
   `isolation=1` runs in a `ROOT@HEAD` throwaway worktree that would not contain them.
3. Codex launches with `workdir=.xyz`; its `workspace-write` sandbox is scoped to `.xyz`, excluding
   the parent-root `.tick`.

**Expected:** Codex can claim the `.tick` token and run the review.
**Observed:** `EPERM: open <repo>/.tick/locks/claim.lock` → "Blocked before the turn… I made no file
changes." `relay-drive.sh` reports a genuine stall (exit 3).
**Frequency:** every time (deterministic — a path/sandbox scoping issue, not a race).

```text
OpenAI Codex v0.144.6
workdir: <repo>/.xyz
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
...
Blocked before the turn: the required claim command cannot create its lock outside the writable sandbox:
`EPERM: open <repo>/.tick/locks/claim.lock`
I made no file changes.
```

## Root cause
`relay-automation/codex-turn.sh` sets `codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")` — the
GH-36 fix — **only inside the `RELAY_WORKTREE_ISOLATION=1` branch** (~line 149/157). The `isolation=0`
branch adds nothing, assuming Codex's CWD *is* ROOT so `.tick` is inside its sandbox. For a vendored
install driven from `cd $HARNESS`, Codex's CWD is `.xyz`, so the parent-root `.tick` is out of scope
and no `--add-dir` rescues it.

## Impact
Non-blocking — workarounds exist:
- `CODEX_FLAGS=--dangerously-bypass-approvals-and-sandbox` (removes Codex's sandbox entirely — heavier than needed),
- drive from ROOT instead of `$HARNESS`, or
- commit the files and use the default `isolation=1`.

But it is a cryptic failure on a **documented** path (`cd $HARNESS` + the supported `isolation=0`
opt-out), and reviewing uncommitted work is a legitimate reason to opt out of isolation.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (vendored fixture or a `.xyz`-rooted CWD), not just in the reporting repo
- [ ] Confirm the `isolation=0` branch's Codex invocation CWD + sandbox scope vs `$TICK_REPO_ROOT/.tick`
- [ ] Decide fix shape: `--add-dir "$TICK_REPO_ROOT/.tick"` unconditionally vs `cd` Codex into ROOT for isolation=0 (`/ponytail` — reuse the existing GH-36 flag path)
- [ ] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test covers the isolation=0 claim path before the fix lands
- [ ] The fix composes with the existing GH-36 flag path rather than adding a parallel one
- [ ] Verify the default isolation=1 path is unchanged (byte-for-byte)

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/codex-turn.sh", "pattern": "GH-263" }
  ],
  "artifacts": [ "relay-automation/codex-turn.sh", "test/codex-turn.sh" ],
  "remediation": {
    "source": "issue#263",
    "criteria": "A Codex turn driven with RELAY_WORKTREE_ISOLATION=0 in a vendored .xyz/ install (CWD=$HARNESS) can claim $TICK_REPO_ROOT/.tick without EPERM and without disabling Codex's sandbox entirely; the isolation=1 path is unchanged (byte-for-byte); a regression test covers the isolation=0 claim path. bash validate.sh green."
  },
  "lanes": { "agy_safe": [ "relay-automation/codex-turn.sh", "test/codex-turn.sh" ], "orchestrator_only": [] }
}
```
