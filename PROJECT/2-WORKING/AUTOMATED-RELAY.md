---
title: Automated Relay — project hub (focused)
status: ACTIVE — Phases 1–4 shipped (baton model); converting relay turns to tick-native (a)
created: 2026-06-15
north_star: a fully automated, self-healing /relay loop I can use every day
---

# Automated Relay — project hub

**Why this is the focus (operator decision 2026-06-15):** between the two efforts,
the **fully automated relay** is the higher-daily-use tool, so XYZ-swarm progress
is **deferred** in favor of finishing this. This doc is the single focused tracker;
deep specs live in the linked canonical docs.

## North star
A `/relay` Producer↔Reviewer loop that runs **hands-free** (all-Claude) or one-line-nudge
(cross-model), **recovers from stalls** (watchdog), and terminates cleanly on `Approved`.

## Status snapshot
| Phase | What | State |
|---|---|---|
| 1 | Turn-token core (handoff-exclusive `tick` rule) | ✅ shipped |
| 2 | Liveness & self-healing (`watchdog.sh`) | ✅ shipped |
| 3 | Termination & verdict gating (`runner.sh`) | ✅ shipped |
| 4 | Hands-free poll (`poll.sh`, `relay-drive.sh`) | ✅ shipped (baton model) |
| **(a)** | **Relay turns → tick-native `RELAY-TURN`** (uses Phase-1 rule + watchdog-visible) | ✅ **DONE + Codex-approved** 2026-06-15 (close-mismatch Blocker caught+fixed) |
| 5 | Package as sibling `skill/relay-automation/` | ✅ **SHIPPED** 2026-06-15 (SKILL.md + tarball + self-extract test) |

**✅ PROJECT COMPLETE (Phases 1–5).** `validate.sh` 20/20. Automated, self-healing relay shipped + packaged; cross-model + Option-A headless proven.

`validate.sh`: **18/18** (added `watchdog-relay.sh`; `poll-driver`/`poll-relay` converted to tick-native). Phase-4 QA: 10/12 (open: live two-window E2E + race hammer-test).

## Deferred (explicitly, with triggers)
- **XYZ swarm further progress** — paused; lower daily use. Resume if parallel builds become routine.
- **Option A (headless CLI) + cross-model relay — ✅ SHIPPED 2026-06-15.** `codex-turn.sh` drives a Codex relay turn via `codex exec` behind a path-allowlist (no push); live X2 proved a real headless Codex turn end-to-end. Cross-model coordination demonstrated. (Unattended *full-loop* + a tighter Codex sandbox are future polish.) See `relay-automation/CROSSMODEL-OPTIONA-PLAN.md`.

## In progress
- **Phase 5** plan drafted (`relay-automation/PHASE-5-PLAN.md`); **automated-relay dogfood running** (`relay-system/2026-06-15/phase5-plan-autorelay.md`) — all-Claude hands-free run reviewing the Phase-5 plan, which is also Phase-5's 5c "real run + metrics" step and the live two-Claude E2E (QA item 196).

## Canonical docs (don't duplicate — link)
- Plan: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` (Phases 0–5 + QA checklists)
- Phase-2 detail: `PROJECT/2-WORKING/EXP-AUTOMATION/PHASE-2-PLAN.md`
- Phase-2 build brief: `PROJECT/2-WORKING/EXP-AUTOMATION/PHASE-2-BUILD-BRIEF.md`
- Phase-4 build: `relay-automation/PHASE-4-PLAN.md`
- (a) scope/estimate: `relay-automation/PHASE-4A-SCOPE.md`
- Operator usage: `relay-automation/README.md`
- Decisions: `decisions/` (graduate-phase-2, relay-turns-tick-native)
- Running log: `CHANGELOG.md` · narrative: `RECAP.md` · observations: `REAL-AGENT-OBSERVATIONS.md`

## Definition of done (project)
Phases 1–5 shipped, relay turns tick-native (a), `validate.sh` green, a real automated
relay run captured end-to-end, and the whole thing installable as a sibling skill.
