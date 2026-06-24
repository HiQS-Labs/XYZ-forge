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

**Decision (relay review 2026-06-15, Claude-B Blocker): E3 — detect-or-extract.**
The dependency is the tick **version**, not its mere presence — a host with
pre-handoff-exclusive tick silently breaks the relay (the `run-runner` guard rides
`handoff-to` routing from `src/claim.js`/`src/take.js`). So: ship the 4 relay
scripts always; **provision tick only if absent**, and **gate on a
handoff-exclusive capability check** (verify the host tick rejects a
wrong-`handoff_to` claim with **zero** events) — apply/verify the Phase-1 patch if
the host tick predates it. E3 also unblocks 5b's self-extract test, which needs a
tick present in its temp dir regardless of production assumptions.

## Sub-phases
- **5a — package (`skill/relay-automation/SKILL.md`).** Self-extracting block(s) that write the 4 scripts; **E3**: detect the host tick and extract+patch tick only if absent or lacking the handoff-exclusive capability. Mirror the xyz skill's self-extract structure. *Accept:* extract into a fresh dir → 4 scripts present + `bash -n` clean; **the chosen E-option (E3) + the capability gate are recorded in the SKILL.md header.**
- **5b — self-extract test.** Extract the skill into a temp dir, **provision tick there via E3 (detect-or-extract)**, run the relay-automation suite green. *Accept:* `test/skill-extract.sh` passes; `validate.sh` green at **19** (adds `skill-extract.sh`).
- **5c — real automated-relay run + metrics (the dogfood below).** Run a live relay through the tooling; capture **rounds-to-approve, wall-time/turn, auto-recovered stalls, and human interventions required (target 0 — the real hands-free proof)**. *(Dropped "% auto-fired vs nudged": for an all-Claude run it's ~100/0 by construction — meaningful only in a mixed/cross-model run.)* *Accept:* a captured metrics block in `REAL-AGENT-OBSERVATIONS.md`.

## Non-goals / guards
- Don't fold into the xyz skill; keep it a sibling.
- Option A (headless CLI) still deferred.
- Hands-free poll stays all-Claude; cross-model stays nudge (document in the skill).

## Acceptance (project DoD)
`validate.sh` green at **19**; full self-extract re-verified; **chosen E-option (E3) recorded in 5a**; a real automated relay run captured with metrics; installable as a sibling skill.

## Resolved by relay review (Claude-B, 2026-06-15)
1. **Tick embedding → E3** (detect-or-extract + handoff-exclusive capability gate). E1 was unsafe (version, not presence, is the dependency).
2. **Item 196 scope:** an all-Claude hands-free run closes a **transport-E2E** box (token/poll/watchdog loop works end-to-end, shared-model caveat noted); it does **not** prove cross-model coordination. **Action:** disambiguate 196's wording; if it implies cross-model, keep it open and add a Claude↔Codex semi-auto run as separate evidence (now feasible — Codex CLI installed).
3. **Metrics:** rounds-to-approve, wall-time/turn, auto-recovered stalls, **human-interventions=0**; dropped auto-fired/nudged for all-Claude runs.
