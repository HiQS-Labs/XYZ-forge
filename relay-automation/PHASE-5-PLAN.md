---
title: relay-automation — Phase 5 plan (package as sibling skill + real-run metrics)
status: Draft (for review)
created: 2026-06-15
builds-on: Phases 1–4 + (a) shipped (validate 18/18, Codex-approved)
---

# relay-automation — Phase 5: package + prove

The last phase. Two halves: **(A) package** the proven runtime as its own
installable skill, and **(B) prove** it by running a real automated relay and
capturing metrics. The dogfood run below can start (B) immediately.

## Goal
A self-extracting **`skill/relay-automation/SKILL.md`** that materializes the
runtime (`poll.sh`, `runner.sh`, `watchdog.sh`, `relay-drive.sh`) + the Phase-1
handoff-exclusive `tick` change, with a self-extract test, so anyone can install
the automated relay into a repo. **Not** folded into `skill/xyz/` (sibling skill).

## The one sub-decision to settle first: how much `tick` does the skill embed?
| Option | Embeds | Pros | Cons |
|---|---|---|---|
| **E1 — depend on existing `bin/tick`** | just the 4 relay scripts + the Phase-1 src patch | small skill; one tick runtime | requires the target repo to already have `tick` |
| **E2 — embed the whole `tick` runtime** | tick `src/*` + `bin/tick` + relay scripts | self-contained install anywhere | duplicates tick; version-drift risk vs the xyz skill's tick |
| **E3 — hybrid: detect-or-extract** | relay scripts always; tick only if absent | works both ways | most install logic |

**Lean E1** (depend on `bin/tick`) for a first cut — relay-automation is
*tick-backed* by definition; a target without tick isn't a real host. Revisit E3
if a standalone install is wanted. **Decide in review before building 5a.**

## Sub-phases
- **5a — package (`skill/relay-automation/SKILL.md`).** Self-extracting block(s) that write the 4 scripts (+ Phase-1 patch per the chosen E-option). Mirror the xyz skill's self-extract structure. *Accept:* extract into a fresh dir → files present + `bash -n` clean.
- **5b — self-extract test.** A test that extracts the skill into a temp dir and runs the relay-automation suite green. *Accept:* `test/skill-extract.sh` (or similar) passes; `validate.sh` green (→ ~19).
- **5c — real automated-relay run + metrics (the dogfood below).** Run a live relay through the tooling; capture **rounds, time/turn, auto-recovered stalls, % turns auto-fired vs nudged**. *Accept:* a captured metrics block in `REAL-AGENT-OBSERVATIONS.md`.

## Non-goals / guards
- Don't fold into the xyz skill; keep it a sibling.
- Option A (headless CLI) still deferred.
- Hands-free poll stays all-Claude; cross-model stays nudge (document in the skill).

## Acceptance (project DoD)
`validate.sh` green incl. new tests; full self-extract re-verified; a real automated
relay run captured with metrics; installable as a sibling skill.

## Open questions for review
1. E1 vs E3 for tick embedding?
2. Is a Claude↔Codex semi-auto run sufficient to close the live-E2E item (196), or do we need a true two-Claude hands-free run for that box?
3. Which metrics matter most for "is this worth using daily"?
