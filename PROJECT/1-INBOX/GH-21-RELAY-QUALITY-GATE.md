---
title: relay protocol — independent post-generation quality gate
status: Parked — triage complete; Gap 1 next, standalone track
created: 2026-06-25
updated: 2026-06-25
owner: noelsaw1
branch: main
gh_issue: 21
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/21
goal: >
  Add an independent quality gate to the relay protocol so that the producing agent's
  self-reported verdict is not the only check before the token releases. Three concrete
  testable gaps: (1) no structural block validator independent of the turn-taker, (2) no
  formal test of TAKE YOUR TURN instruction self-sufficiency on a fresh clone, (3)
  consult.sh not wired into the loop for adversarial diversity. Outcome may also inform
  updates to GUIDING-PRINCIPLES.md, but that is a result of test findings, not a prior
  commitment.
related:
  - relay-automation/runner.sh
  - relay-automation/relay-turn-lib.sh
  - relay-automation/consult.sh
  - relay-automation/relay-drive.sh
  - PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md
non_goals:
  - Replacing the containment guard in relay-turn-lib.sh (scope-enforcement stays separate from quality-enforcement)
  - A full LLM-judge pipeline per turn (too expensive; start with deterministic structural checks)
  - Blocking the current active tracks (Part A dogfood, Part B adversarial hardening Phase 2)
---

## Status

| What was just completed | What's next |
|---|---|
| Triage complete (agy advisory relay 2026-06-25). Gap 1 first; standalone tooling track, not Part B Phase 2. Architecture for all three gaps resolved — see refinements below. New principle identified for GUIDING-PRINCIPLES.md. | Promote to 2-WORKING when ready to execute Gap 1: add structural block validator in `bin/tick`'s `release`/`done` verbs + new `exit 8`. |

## Problem

The relay protocol has no quality gate independent of the producing agent. The agent that takes a turn writes its own `VERDICT: PASS|FAIL|PARKED` in `runner.sh`, and `relay-drive.sh`'s round-cap + no-progress escalation is a liveness check, not a quality check.

Three concrete gaps, in priority order:

### Gap 1 — No structural quality check independent of the producing agent

The `VERDICT:` block is written by the same agent that took the turn. A second structural pass before `tick release` should check: turn block present, verdict line present, claims cited, no off-allowlist files remaining. Currently `relay-turn-lib.sh`'s containment guard checks *scope* (allowlist, commit-bypass) but not *quality* (was the turn actually well-formed?).

**What done looks like:** a deterministic script that validates relay block shape after the agent writes it and before the token releases. `exit 6` (containment revert) has a model; **use a new `exit 8`** to distinguish structural quality failures from containment violations.

**Architecture (from agy triage, 2026-06-25):** Hook into `bin/tick`'s `release` and `done` verbs (~L220/L236 as of 2026-06-25), not into `rtl_enforce` — the agent calls `tick release` *during* its own execution block, before the shim runs post-turn enforcement, so a post-turn hook in the shim fires too late. The validator should assert four load-bearing fields: (1) a new log block present under `## Log`, (2) header `STATUS:` updated, (3) `VERDICT:` line present and a valid value (`PASS|FAIL|PARKED`), (4) `Basis:` line present and well-formed.

### Gap 2 — No formal test of TAKE YOUR TURN instruction self-sufficiency

The relay protocol assumes the embedded `▶ TAKE YOUR TURN` block is sufficient for a context-free agent. This is untested: give a headless Codex a fresh clone with only the relay file (no ambient repo context), and check whether it produces a well-formed block. If it fails, tacit knowledge is leaking through ambient context, which should be documented or encoded into the relay file template.

**What done looks like:** a new `test/relay-self-sufficiency.sh` that drives a headless turn-taker against a minimal relay file template in a temporary git clone (not `baton-pattern.md`, to avoid leaking ambient repo context). FAIL is defined as: agent fails to claim/release (path assumptions wrong), omits required log fields (`Basis:`, `VERDICT:`), or writes off-allowlist. Run manually first, then wire into `validate.sh`.

### Gap 3 — No multi-reviewer adversarial pass wired into relay

`consult.sh` exists for parallel read-only consults (Codex + agy independently) but is never wired into the relay loop. An independent second opinion could catch failures a self-reporting agent misses. This is the most expensive gap (each consult is real API spend) and the least urgent — address after Gaps 1 and 2.

**What done looks like:** an opt-in `--consult-verify` flag on `relay-drive.sh` (not in `rtl_enforce` — consult calls are expensive and must not fire on every standard turn). On divergent verdicts: print conflicting verdicts + diff to stderr, append an advisory conflict-warning block to the relay file log, and set `STATUS: Escalated` (exit 4) to halt the supervisor and surface to the operator.

## Connection to existing tracks

- **Part B adversarial hardening** — closest sibling, but **triage decision: standalone tooling track** (not folded into Part B Phase 2). Gap 1 is a compliance/correctness gate; Part B Phase 2 is a liveness/concurrency chaos suite. Different threat models.
- **GUIDING-PRINCIPLES.md quality bar** — "Attested — carries its receipts: source, evidence, confidence. Never a bare verdict" and Principle 5 ("adversarially proven before commercially viable") are the normative hooks. **New principle surfaced by triage (agy, 2026-06-25): "Independent Verification (Separated Grading)"** — the agent that produces a turn must not be the sole grader of its quality; verification must be performed by an independent deterministic check or separate reviewing agent before the lock releases. Add to GUIDING-PRINCIPLES.md when this track ships Gap 1.
- **relay-turn-lib.sh containment hardening (GH-13, GH-14)** — scope enforcement, not quality enforcement; these are siblings, not the same problem.

## Origin

Surfaced from reviewing the article "The Rise of the Orchestrator IC" (Kursat Ozenc / Saeideh Bakhshi, Design Meets AI Substack). The article's observation that the bottleneck in multi-agent work shifts to post-generation quality control — independent of the producing agent — maps directly to the relay protocol gap above. The connection: Bakhshi's four-independent-agent-persona validation pattern and her "accountability boundary" framing (AI can't be a teammate because teams require accountability) are the same problem the relay protocol faces when an agent self-grades.
