---
title: agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed
status: Proposed (1-INBOX — not yet active)
created: 2026-08-24
owner: noel
gh_issue: 221
source: https://github.com/HiQS-Labs/XYZ-forge/issues/221
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
reported_from: aegis-sleuth-slack-bot
harness_commit: b1566b8a
non_goals:
  - Auditing or fixing the separate TTY-based whoami-false-pass issue (#375)
  - Adding a general CLI-version-compatibility layer beyond this one probe
related:
  - "#375 (whoami falsely exits 0 on a TTY error — a false PASS; this issue is the opposite: a hard FAIL from an unrecognized argument)"
goal: >
  agy-turn.sh's auth pre-flight works against current agy CLI versions (including >=1.1.19, which
  dropped the `whoami` subcommand) without hard-failing an otherwise-healthy, authenticated run.
---

# GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
`relay-automation/agy-turn.sh`'s auth pre-flight (`agy_check_auth`, calling `"$AGY_BIN" whoami`)
hard-fails on agy CLI v1.1.19, which has removed the `whoami` subcommand entirely. `agy --help`
lists only `-p/--print`, `-i/--prompt-interactive`, `--continue`, `--conversation`, etc. — no
`whoami`. The bare word is parsed as a positional prompt argument and rejected outside
print/interactive/stdin mode, so the pre-flight fails on every run and is misreported as an auth
problem ("Run `agy login`") when auth is actually fine.

## Environment
- **Observed from:** aegis-sleuth-slack-bot (vendored `.xyz/`, later re-resolved to the centralized
  `.harness-dev` clone after running `xyz-sync.sh update`)
- **Harness commit:** `b1566b8a`
- **Worker/CLI:** agy v1.1.19
- **Runtime:** not confirmed which twin (Python vs Bash) drives `relay-drive.sh` in this install;
  `agy-turn.sh` is a plain bash shim regardless — no `runtime:*` label applied (avoided guessing).
- **Sandbox:** off (`dangerouslyDisableSandbox: true`) — ruled out the known sandboxed-agy
  false-auth-failure pattern first; the failure is unchanged un-sandboxed.

## Reproduction
1. Set up a relay thread, hand the turn to `agy` via `tick release --to agy`.
2. Run:
   ```
   AGY_AGENT=agy ALLOW_PATHS="" AGY_LOG="<tmp log>" \
   relay-automation/relay-drive.sh \
     --relay-file <relay-file> \
     --relay-task <task-id> \
     --agent-cmd  relay-automation/agy-turn.sh \
     --round-cap  4 \
     --review-once
   ```
3. Separately confirm `agy --help` on the same machine shows no `whoami` subcommand.

**Expected:** an authenticated agy CLI lets the turn proceed regardless of whether it still exposes
a `whoami` subcommand — the pre-flight exists to catch bad auth, not CLI version drift.

**Observed:** driver exits 5 immediately:
```text
agy-turn: agy auth pre-flight failed (exit 2). Run `agy login` in a normal terminal, then retry.
agy-turn: auth pre-flight: Error: unexpected argument "whoami".
agy-turn: auth pre-flight: Prompts are read only from -p/--print, -i/--prompt-interactive, or stdin, so this argument would have been ignored.
```

**Frequency:** every time, deterministic. Verified unchanged after `xyz-sync.sh update` to the
latest harness commit — the `whoami` call in `agy-turn.sh` is untouched by that sync.

## Impact
Blocks every headless `agy-turn.sh` run (Path A automated relay reviews/builds using agy) on any
machine with agy CLI >=1.1.19. Workaround available: use Codex instead of agy for automated relays,
or run `agy` attended/manually (bypassing the shim's pre-flight). Not a data-loss or correctness
risk — the shim fails closed rather than proceeding on bad auth.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce in the intake repo directly (this capture reproduced it from a caller repo, not
      yet re-verified inside `xyz-3-agents-swarm`/`XYZ-forge` itself)
- [ ] Confirm exact agy CLI versions affected (only v1.1.19 checked here) and whether older
      versions that DO support `whoami` still need to keep working
- [ ] Decide fix shape: version-aware probe (detect `whoami` support via `agy --help` first) vs.
      replacing the probe entirely with a version-agnostic call (e.g. short-timeout `agy -p`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test (or a fixture pinning the current `agy --help` output shape) covers the
      failure path before the fix lands
- [ ] The fix composes with the existing pre-flight contract (short wall-clock cap, fails closed on
      genuine auth problems) rather than adding a parallel probe path
