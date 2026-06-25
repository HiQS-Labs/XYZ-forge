---
title: relay protocol — independent post-generation quality gate
status: Parked — triage complete; Gap 1 next, standalone track
created: 2026-06-25
updated: 2026-06-25
owner: noelsaw1
branch: main
gh_issue: 21
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/21
track: standalone tooling (not Part B Phase 2)
priority: Gap 1 → Gap 2 → Gap 3
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

## Progress

| Most recently completed | What's next |
|---|---|
| Triage complete (agy advisory relay 2026-06-25). Gap 1 first; standalone tooling track, not Part B Phase 2. Architecture for all three gaps resolved. New principle identified for GUIDING-PRINCIPLES.md. | Promote to `2-WORKING`. Execute Gap 1: add structural block validator in `bin/tick`'s `release`/`done` verbs + new `exit 8`. |

---

## Table of Contents

- [Problem](#problem)
- [Phase 1 — Structural Block Validator (Gap 1)](#phase-1--structural-block-validator-gap-1)
- [Phase 2 — Self-Sufficiency Test (Gap 2)](#phase-2--self-sufficiency-test-gap-2)
- [Phase 3 — Adversarial Multi-Reviewer (Gap 3)](#phase-3--adversarial-multi-reviewer-gap-3)
- [Connection to Existing Tracks](#connection-to-existing-tracks)
- [Origin](#origin)

---

## Problem

The relay protocol has no quality gate independent of the producing agent. The agent that takes a turn writes its own `VERDICT: PASS|FAIL|PARKED` in `runner.sh`, and `relay-drive.sh`'s round-cap + no-progress escalation is a liveness check, not a quality check.

Three concrete gaps addressed in priority order as separate phases below.

---

## Phase 1 — Structural Block Validator (Gap 1)

**Goal:** A deterministic script validates relay block shape after the agent writes it and before the token releases. Independent of the turn-taker.

**Architecture:** Hook into `bin/tick`'s `release` and `done` verbs (~L220/L236 as of 2026-06-25), not into `rtl_enforce` — the agent calls `tick release` during its own execution block, before the shim runs post-turn enforcement, so a post-turn hook in the shim fires too late. Use a new `exit 8` to distinguish structural quality failures from containment violations (`exit 6`).

### Checklist

- [ ] Read `bin/tick` and locate `release` and `done` verb handlers (~L220/L236)
- [ ] Write `bin/validate-relay-block` deterministic validator script
  - [ ] Assert `## Log` section contains a new log entry for the current turn
  - [ ] Assert header `STATUS:` field is updated (not the prior value)
  - [ ] Assert `VERDICT:` line is present and value is one of `PASS`, `FAIL`, or `PARKED`
  - [ ] Assert `Basis:` line is present and non-empty
- [ ] Add `exit 8` constant and message to `bin/tick`'s error legend / docs
- [ ] Wire `bin/validate-relay-block` into `bin/tick release` before lock release
- [ ] Wire `bin/validate-relay-block` into `bin/tick done` before lock release
- [ ] Verify that a malformed relay block triggers `exit 8` and does NOT release the token
- [ ] Verify that a well-formed relay block passes and releases normally
- [ ] Add `bin/validate-relay-block` to allowlist in `relay-turn-lib.sh` if needed
- [ ] Update `bin/tick` help/usage text to document `exit 8`

### Phase 1 QA Checklist

- [ ] Run `bin/tick release` against a relay file missing `VERDICT:` — confirm `exit 8`, token not released
- [ ] Run `bin/tick release` against a relay file missing `Basis:` — confirm `exit 8`
- [ ] Run `bin/tick release` against a relay file with `VERDICT: INVALID` — confirm `exit 8`
- [ ] Run `bin/tick release` against a well-formed relay file — confirm `exit 0`, token released
- [ ] Confirm `exit 8` is distinct from `exit 6` (containment) in the exit code legend
- [ ] Run the existing Part A dogfood relay end-to-end — confirm no regression

---

## Phase 2 — Self-Sufficiency Test (Gap 2)

**Goal:** Formally verify that the embedded `▶ TAKE YOUR TURN` block is sufficient for a context-free agent operating on a fresh clone with no ambient repo context.

**Architecture:** New `test/relay-self-sufficiency.sh` drives a headless turn-taker against a minimal relay file template in a temporary git clone (not `baton-pattern.md`, to avoid leaking ambient repo context). Wire into `validate.sh` after manual validation.

### Checklist

- [ ] Author a minimal relay file template in `test/fixtures/minimal-relay.md` (no baton-pattern.md contents)
- [ ] Write `test/relay-self-sufficiency.sh`
  - [ ] Spin up a temporary `git clone` with only the minimal relay file
  - [ ] Drive a headless Codex turn against the clone
  - [ ] Capture output; assert no claim/release path errors
  - [ ] Assert `Basis:` field is present in the written block
  - [ ] Assert `VERDICT:` field is present and valid
  - [ ] Assert no off-allowlist files were written
- [ ] Define FAIL criteria explicitly in script header comments:
  - [ ] Agent fails to claim/release (path assumptions wrong)
  - [ ] Agent omits required log fields (`Basis:`, `VERDICT:`)
  - [ ] Agent writes off-allowlist files
- [ ] Run `test/relay-self-sufficiency.sh` manually against a real headless agent
- [ ] If FAIL: document which tacit knowledge leaked through ambient context; encode fix into relay file template
- [ ] Wire `test/relay-self-sufficiency.sh` into `validate.sh`

### Phase 2 QA Checklist

- [ ] Run test against clean temp clone — no ambient repo files present during the run
- [ ] Confirm FAIL path exits non-zero and prints a diagnostic message naming the missing field
- [ ] Confirm PASS path exits 0 and emits a summary of assertions checked
- [ ] Run `validate.sh` — confirm Phase 2 test is included and passes
- [ ] If any tacit-knowledge leak found: confirm the fix is encoded in the relay file template, not just noted

---

## Phase 3 — Adversarial Multi-Reviewer (Gap 3)

**Goal:** Wire `consult.sh` into the relay loop as an opt-in second opinion, so a self-reporting agent's verdict can be independently challenged.

**Architecture:** Add `--consult-verify` flag to `relay-drive.sh` (not in `rtl_enforce` — consult calls are expensive and must not fire on every standard turn). On divergent verdicts: print conflicting verdicts + diff to stderr, append an advisory conflict-warning block to the relay file log, set `STATUS: Escalated` (exit 4) to halt supervisor.

### Checklist

- [ ] Add `--consult-verify` flag parsing to `relay-drive.sh`
- [ ] After the turn-taker's `tick release`, invoke `consult.sh` when `--consult-verify` is set
  - [ ] Pass the relay file to both Codex and agy as read-only reviewers
  - [ ] Collect both verdicts
- [ ] Compare verdicts: if both agree with the turn-taker → continue
- [ ] On divergence:
  - [ ] Print conflicting verdicts + relevant diff to stderr
  - [ ] Append conflict-warning advisory block to relay file `## Log`
  - [ ] Set `STATUS: Escalated` in relay file header
  - [ ] Exit 4 to halt supervisor
- [ ] Document `--consult-verify` in `relay-drive.sh` help/usage text
- [ ] Add cost warning to `--consult-verify` help text (each consult is real API spend)

### Phase 3 QA Checklist

- [ ] Run `relay-drive.sh` without `--consult-verify` — confirm consult is never triggered (no extra API calls)
- [ ] Run with `--consult-verify` and a clean PASS turn — confirm all three verdicts agree, relay continues
- [ ] Simulate divergent verdict (stub one reviewer to return FAIL) — confirm exit 4, conflict block appended, `STATUS: Escalated`
- [ ] Confirm conflict-warning block in the log is parseable (does not break Phase 1 structural validator)
- [ ] Run Phase 1 validator on the escalated relay file — confirm it passes structural check (escalation is a valid state)
- [ ] Confirm GUIDING-PRINCIPLES.md updated with "Independent Verification (Separated Grading)" principle after Phase 1 ships

---

## Connection to Existing Tracks

- **Part B adversarial hardening** — closest sibling, but triage decision: standalone tooling track (not folded into Part B Phase 2). Gap 1 is a compliance/correctness gate; Part B Phase 2 is a liveness/concurrency chaos suite. Different threat models.
- **GUIDING-PRINCIPLES.md quality bar** — "Attested — carries its receipts: source, evidence, confidence. Never a bare verdict" and Principle 5 ("adversarially proven before commercially viable") are the normative hooks. New principle surfaced by triage (agy, 2026-06-25): "Independent Verification (Separated Grading)" — the agent that produces a turn must not be the sole grader of its quality; verification must be performed by an independent deterministic check or separate reviewing agent before the lock releases. Add to GUIDING-PRINCIPLES.md when this track ships Phase 1.
- **relay-turn-lib.sh containment hardening (GH-13, GH-14)** — scope enforcement, not quality enforcement; these are siblings, not the same problem.

---

## Origin

Surfaced from reviewing the article "The Rise of the Orchestrator IC" (Kursat Ozenc / Saeideh Bakhshi, Design Meets AI Substack). The article's observation that the bottleneck in multi-agent work shifts to post-generation quality control — independent of the producing agent — maps directly to the relay protocol gap above. The connection: Bakhshi's four-independent-agent-persona validation pattern and her "accountability boundary" framing (AI can't be a teammate because teams require accountability) are the same problem the relay protocol faces when an agent self-grades.
