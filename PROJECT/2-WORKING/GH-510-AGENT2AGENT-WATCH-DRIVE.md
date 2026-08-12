---
gh_issue: 510
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510
title: "GH-510 — Agent2Agent read-only watch and opt-in drive"
status: "2-WORKING — implementation and all local gates complete; awaiting PR review."
created: 2026-08-11
updated: 2026-08-11
owner: noel
doc_type: feature
effort: 2
complexity: 2
risk: 3
phases: 2
ratings_provisional: false
roadmap_exempt: false
non_goals:
  - "Silently turning join or watch into command execution."
  - "Embedding a provider-specific Claude, Codex, or Agy CLI invocation."
  - "Changing Tick events, relay containment, the roster, or serialized NEXT routing."
goal: >
  Let a participant wait read-only on a 2–3 minute cadence or explicitly opt into a bounded turn
  command, without weakening the existing turn lock or making hands-free execution implicit.
---

# GH-510 — Agent2Agent read-only watch and opt-in drive

## Status

| What was just completed | What's next |
|---|---|
| Added byte-preserving `watch`, bounded `drive`, a crash-releasing single-owner drive lock, command handoff verification, process-group timeout cleanup, skill guidance, and 76/76 focused coverage; full local gate is 182/182. | Commit and push the intended files, open the follow-up PR to `development`, and review CI without merging. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510

## Reversibility and blast radius

**Costly** — the code is additive, but `drive` intentionally executes an operator-approved command
with the current process's authority. Rollback is to remove the `watch`/`drive` subcommands and skill
sections; `start`/`join`/`send`/`close` and every existing relay file remain compatible. Tick event
shape, relay containment, and the established relay drivers are unchanged.

## Acceptance

*Copied verbatim from [issue #510](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510), fetched 2026-08-11.*

- [x] Skill documentation distinguishes watch from drive and states their mutation boundaries.
- [x] Watch reports relevant discussion changes without modifying bytes.
- [x] Drive dispatches only on the named participant turn and cannot silently overlap another driver for that lane.
- [x] Drive does not itself bypass `send` turn/lock enforcement.
- [x] Closed discussions and process interruption terminate cleanly.
- [x] Deterministic tests cover read-only watch, delayed turn arrival, non-turn silence, driver contention, command failure, and 3+ participant routing.
- [x] Skill validation and focused Agent2Agent tests pass.

## Ordered implementation

1. Add a read-only polling primitive and expose `watch` with a 150-second default interval.
2. Add explicit `drive` with timeout/turn bounds, one process-owned lane, argv-only command launch,
   and post-command proof that the guarded helper advanced and handed off the turn.
3. Update the skill, UI metadata, README, regression suite, and PDDA evidence; run all gates.

## QA evidence

| Gate | Result |
|---|---|
| `bash test/agent2agent.sh` | **PASS — 76/76**, including read-only watch, delayed ownership, command/process-group timeout, contention, command failure, guarded advance, closure, interruption, and 3+ routing. |
| `python3 .../skill-creator/scripts/quick_validate.py skills/agent2agent` | **PASS — Skill is valid.** |
| `utils/pdda/pdda.sh run` | **PASS — 0 errors**; 15 pre-existing repository warnings. |
| `bash test/{security-scan,mktemp-trap-guard,roadmap-dashboard}.sh` | **PASS — 35/35, 1/1, and 9/9.** |
| `bash test/gh308-frozen-twin-guard.sh --check --staged` | **PASS — no frozen Bash twin changed.** |
| `RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh` | **PASS — 182/182**; live-agent API smoke deliberately skipped through its documented CI switch. |
