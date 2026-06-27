---
title: relay-xyz skill-skip durability — PreToolUse guard + ROUTER rail
status: Active — guard hook + ROUTER rail + test shipped + verified live; GH issue #19 filed
created: 2026-06-24
updated: 2026-06-24
owner: noelsaw1
branch: main
gh_issue: 19
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/19
goal: >
  Stop the recurring failure where a Claude Code session improvises its own relay handoff
  instead of invoking the relay-xyz skill. Twice in one day a session ran `ls relay-automation/`,
  assumed it understood the harness, and built a parallel harness — admitting afterward
  "I didn't read it." This is a behavioral skip, not a discovery gap (the symlink exists and the
  skill loads), so the fix must be deterministic: a hook the harness executes, not a doc the model
  can skip.
scope: >
  A PreToolUse guard (relay-automation/hooks/relay-xyz-guard.sh) wired in .claude/settings.json,
  a ROUTER.md routing rail, and a regression test. No change to the skill body or find-harness.sh.
related:
  - relay-automation/hooks/relay-xyz-guard.sh
  - .claude/settings.json
  - ROUTER.md
  - skills/relay-xyz/SKILL.md
  - test/relay-xyz-skill-guard.sh
non_goals:
  - Catching a fully hand-rolled relay that never touches a relay-automation/ driver script
    (the guard is high-precision on the driver entrypoints, not a sandbox of every model CLI).
  - Cross-machine / cloud enforcement (the marker is per-session, local).
---

## Status

| What was just completed | What's next |
|---|---|
| **Built, verified live, issue filed.** Diagnosed the failure as a behavioral skip (skill loads, agent never opens it). Shipped a deterministic `PreToolUse` guard ([relay-automation/hooks/relay-xyz-guard.sh](../../relay-automation/hooks/relay-xyz-guard.sh)) wired via [.claude/settings.json](../../.claude/settings.json) on `Bash\|Skill`; added a ROUTER routing rail; added [test/relay-xyz-skill-guard.sh](../../test/relay-xyz-skill-guard.sh) (11 assertions) to the suite — **`validate.sh` 44→45/45**. Guard confirmed **live in-session** (blocked a real `relay-drive.sh` call, exit 2). [#19](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/19) filed (gh auth was a sandbox artifact, not a real expiry). | Promote to `2-WORKING` or close once a fresh session confirms the guard catches an organic skip. Commit the staged changes. |

## Problem

The `/relay-xyz` skill is fully wired — symlinked at `~/.claude/skills/relay-xyz`, body loads, description
is in every session's system-reminder. The June 21 "relay-xyz durability" work fixed *discovery*
(symlink + `find-harness.sh` locator). What still fails is one layer up: a session sees
`ls relay-automation/`, forms a conclusion ("I understand this"), and **never invokes the Skill tool**
to read the body, then improvises a parallel harness. Better skill content can't fix this because the
agent never opens it. Per the repo's own principle: a confident agent will skip a doc; it cannot skip a hook.

## Approach (shipped)

1. **PreToolUse guard (load-bearing).** The skill's Preconditions make the agent run `find-harness.sh`
   *first*; an improviser runs `relay-drive.sh` / `poll.sh` / a turn shim cold. The hook watches the
   `PreToolUse` event stream:
   - **Proof-of-load → record the session as loaded:** the `Skill` tool invoked with `relay-xyz`, or a
     Bash command running `find-harness.sh`.
   - **Block (exit 2) →** a Bash command that *executes* a `relay-automation/<driver>.sh` entrypoint
     (`relay-drive.sh`, `marathon-drive.sh`, `marathon.sh`, `poll.sh`, `codex-turn.sh`, `agy-turn.sh`)
     when the session has not loaded the skill. Exit 2 cancels the call and feeds the redirect message
     back to the model.
   - Session-scoped via the event's `session_id`, so one session's marker never suppresses another.
   - Fail-open and high-precision: only `relay-automation/` driver paths block — `test/<driver>.sh`,
     reads (`cat`/`head`/`bash -n`), and unrelated commands are exempt, so `validate.sh` and the shim
     tests never trip it.
2. **ROUTER.md routing rail.** Agents are *instructed* to read ROUTER at startup, which previously said
   nothing about relay-xyz. Added a rail under "Routing hints" pointing relay/harness work at the skill
   first and naming the guard.
3. **Regression test.** `test/relay-xyz-skill-guard.sh` — cold-block, post-skill allow, post-locator
   allow, session-scoping, no-false-positive (test paths / reads / unrelated), malformed-event fail-open.

**Reversibility: Easy.** The guard is one hook script + one settings block; the ROUTER line and test are
additive. Removing the `hooks` block in `.claude/settings.json` fully disables it.

## Issue body (file this verbatim once `gh auth` is restored)

```
Title: relay-xyz skill-skip: sessions improvise a harness instead of reading the skill

Twice in one day a Claude Code session drove a relay by hand instead of invoking the
relay-xyz skill — running `ls relay-automation/`, assuming it understood the harness, and
building a parallel handoff. One admitted afterward: "I didn't read it. I assumed from
`ls relay-automation` and jumped to a conclusion."

Root cause: this is a behavioral skip, not a discovery gap. The skill is symlinked into
~/.claude/skills, its body loads, and its description is in every session's system-reminder.
The agent simply never opens it. Skill content can't fix what the agent never reads.

Fix (shipped, pending issue number):
- PreToolUse guard `relay-automation/hooks/relay-xyz-guard.sh`, wired in `.claude/settings.json`
  on `Bash|Skill`. Blocks (exit 2) executing a `relay-automation/` driver entrypoint before the
  session has loaded the relay-xyz skill; records proof-of-load from a `Skill` invocation or a
  `find-harness.sh` run; session-scoped; fail-open; high-precision (test/ paths and reads exempt).
- ROUTER.md routing rail pointing relay/harness work at the skill first.
- Regression test `test/relay-xyz-skill-guard.sh` (11 assertions); `validate.sh` 44→45/45.

Non-goals: catching a fully hand-rolled relay that never touches a driver script; cross-machine
enforcement (marker is per-session/local).
```
