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
| **(a)** | **Relay turns → tick-native `RELAY-TURN`** (uses Phase-1 rule + watchdog-visible) | 🔨 **in progress** (~3.5 passes / 4–5h, Codex-estimated) |
| 5 | Package as sibling `skill/relay-automation/` | ⏳ next after (a) |

`validate.sh`: **17/17** today (→ ~19 after (a)'s 2 new tests).

## Deferred (explicitly, with triggers)
- **XYZ swarm further progress** — paused; lower daily use. Resume if parallel builds become routine.
- **Option A (headless CLI, unattended runs)** — future upgrade; trigger = a real need for no-window-open runs + a CLI/auth/budget. Easier once (a) lands. See `relay-automation/PHASE-2-PLAN.md` → "Future upgrade".

## Canonical docs (don't duplicate — link)
- Plan: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` (Phases 0–5 + QA checklists)
- Phase-4 build: `relay-automation/PHASE-4-PLAN.md`
- (a) scope/estimate: `relay-automation/PHASE-4A-SCOPE.md`
- Operator usage: `relay-automation/README.md`
- Decisions: `decisions/` (graduate-phase-2, relay-turns-tick-native)
- Running log: `CHANGELOG.md` · narrative: `RECAP.md` · observations: `REAL-AGENT-OBSERVATIONS.md`

## Definition of done (project)
Phases 1–5 shipped, relay turns tick-native (a), `validate.sh` green, a real automated
relay run captured end-to-end, and the whole thing installable as a sibling skill.
