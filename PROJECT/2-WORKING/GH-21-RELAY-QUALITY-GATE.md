---
title: relay protocol — independent post-generation quality gate
status: Active — promoted to 2-WORKING 2026-06-25; execute Phase 1
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
| **Phase 2 complete 2026-06-25** — `test/fixtures/minimal-relay.md` + `test/relay-self-sufficiency.sh` written and wired into `validate.sh`. Live agy run passed 4/4 assertions: shim exit 0, relay file committed, VERDICT: present, Basis: present. Root cause found during iteration: fixture `---` separator before `## Log` caused agy to write above the wrong anchor — fixed by removing separator and clarifying instruction to "append after the `## Log` header." CI-gate: `RELAY_SELF_SUFFICIENCY_SKIP=1`. Full validate.sh 0 failures. | Execute Phase 3: wire `consult.sh` into `relay-drive.sh` as `--consult-verify`. |

---

## Table of Contents

- [Problem](#problem)
- [Dogfood Execution Plan — Phase 1](#dogfood-execution-plan-phase-1)
- [Phase 1 — Structural Block Validator (Gap 1)](#phase-1--structural-block-validator-gap-1)
- [Phase 2 — Self-Sufficiency Test (Gap 2)](#phase-2--self-sufficiency-test-gap-2)
- [Phase 3 — Adversarial Multi-Reviewer (Gap 3)](#phase-3--adversarial-multi-reviewer-gap-3)
- [Connection to Existing Tracks](#connection-to-existing-tracks)
- [Origin](#origin)

---

## Dogfood Execution Plan — Phase 1

Phase 1 is a strong relay dogfood candidate. The checklist decomposes into two turns with a clean handoff — the relay protocol building its own quality gate by running on itself.

**Why it fits:**
- Scope is bounded and files are fully specified: `bin/validate-relay-block` (new), `bin/tick` (~L220/L236 wire points), `relay-turn-lib.sh` allowlist, and docs
- Two separable turns — impl then QA — with no cross-turn context dependency
- Bootstrapping is explicit and safe: Phase 1 runs *without* the gate it is building; the Reviewer turn is the manual equivalent of what Phase 1 will automate

**Turn decomposition:**

| Turn | Agent | Work | Done signal |
|---|---|---|---|
| Producer | agy (or Codex) | Impl checklist: write validator, wire `bin/tick`, update allowlist + docs | `tick release`, `validate.sh` green |
| Reviewer | claude-b (or agy) | Phase 1 QA checklist — run assertions against synthetic fixture files in a temp dir | `VERDICT: PASS` on all 6 QA items |

**Fixture approach for the Reviewer turn:** Run `bin/tick release` against synthetic relay files in a temp worktree — not against live relay state. Three fixture files cover the three `exit 8` cases (missing `VERDICT:`, missing `Basis:`, `VERDICT: INVALID`) plus one well-formed control. This avoids disturbing the live relay token lock.

**Multi-agent lane fit:**
- Part A Phase 6 pattern (Producer↔Reviewer on this repo, not an external target) applies directly
- Producer write-scope is small and well-bounded — agy or Codex both fit
- Reviewer scope is assertion-heavy, deterministic — any capable reviewer works; claude-b is natural continuation of the planning-phase QA relay already run on this doc

**To launch:** Create a `relay-system/<date>/gh-21-phase1.md` relay thread, then `relay-drive.sh --relay-file relay-system/<date>/gh-21-phase1.md` with the standard two-agent `--agent-cmd` pair. The relay thread's `▶ TAKE YOUR TURN` block should hand the Producer the impl checklist directly (copy from Phase 1 below).

---

## Problem

The relay protocol has no quality gate independent of the producing agent. The agent that takes a turn writes its own `VERDICT: PASS|FAIL|PARKED` in `runner.sh`, and `relay-drive.sh`'s round-cap + no-progress escalation is a liveness check, not a quality check.

Three concrete gaps addressed in priority order as separate phases below.

---

## Phase 1 — Structural Block Validator (Gap 1)

**Goal:** A deterministic script validates relay block shape after the agent writes it and before the token releases. Independent of the turn-taker.

**Architecture:** Hook into `bin/tick`'s `release` and `done` verbs (~L220/L236 as of 2026-06-25), not into `rtl_enforce` — the agent calls `tick release` during its own execution block, before the shim runs post-turn enforcement, so a post-turn hook in the shim fires too late. Use a new `exit 8` to distinguish structural quality failures from containment violations (`exit 6`).

### Checklist

- [x] Read `bin/tick` and locate `release` and `done` verb handlers (~L220/L236)
- [x] Write `bin/validate-relay-block` deterministic validator script
  - [x] Assert `## Log` section contains a new log entry for the current turn
  - [x] Assert header `STATUS:` field is updated (not the prior value)
  - [x] Assert `VERDICT:` line is present and value is one of `PASS`, `FAIL`, or `PARKED`
  - [x] Assert `Basis:` line is present and non-empty
- [x] Add `exit 8` handling to `bin/tick`'s `main()` — the `release`/`done` case blocks must propagate `process.exit(8)` when the validator returns non-zero (code change, not just docs)
- [x] Add `exit 8` to `bin/tick`'s error legend / help text
- [x] Wire `bin/validate-relay-block` into `bin/tick release` — insert AFTER arg validation guard, BEFORE the `release(root, …)` call (~L220)
- [x] Wire `bin/validate-relay-block` into `bin/tick done` — insert AFTER arg validation guard, BEFORE the `done(root, …)` call (~L236)
- [x] Verify that a malformed relay block triggers `exit 8` and does NOT release the token
- [x] Verify that a well-formed relay block passes and releases normally
- [x] Add `bin/validate-relay-block` to allowlist in `relay-turn-lib.sh` if needed — skipped (internal subprocess call from bin/tick, not an agent file write; no allowlist restriction applies)
- [x] Update `bin/tick` help/usage text to document `exit 8`
- [x] Update relay protocol docs and any agent reference docs to mention `bin/validate-relay-block` and `exit 8` so operators know the validator exists
- [x] Update `GUIDING-PRINCIPLES.md` with the "Independent Verification (Separated Grading)" principle (do not defer to Phase 3 — this gate owns the principle's first proof)

### Phase 1 QA Checklist

> **Pre-condition:** all QA items below are POST-implementation tests. Run only after the Phase 1 implementation checklist is complete (validator wired into `bin/tick release`/`done`).

- [x] Run `bin/tick release` against a relay file missing `VERDICT:` — confirm `exit 8`, token not released
- [x] Run `bin/tick release` against a relay file missing `Basis:` — confirm `exit 8`, token not released
- [x] Run `bin/tick release` against a relay file with `VERDICT: INVALID` — confirm `exit 8`, token not released
- [x] Run `bin/tick release` against a well-formed relay file — confirm `exit 0`, token released
- [x] Confirm `exit 8` is distinct from `exit 6` (containment) in the exit code legend
- [x] Run the existing Part A dogfood relay end-to-end — confirm relay terminates `STATUS: Approved` and `relay-drive.sh` exits `0` (no regression) — covered by validate.sh suite (all 25 suites, 0 failures post-impl, including agy-turn and claude-turn suites)

---

## Phase 2 — Self-Sufficiency Test (Gap 2)

**Goal:** Formally verify that the embedded `▶ TAKE YOUR TURN` block is sufficient for a context-free agent operating on a fresh clone with no ambient repo context.

**Architecture:** New `test/relay-self-sufficiency.sh` drives a headless turn-taker against a minimal relay file template in a temporary git clone (not `baton-pattern.md`, to avoid leaking ambient repo context). Wire into `validate.sh` after manual validation.

### Checklist

- [x] Author a minimal relay file template in `test/fixtures/minimal-relay.md` (no baton-pattern.md contents)
- [x] Write `test/relay-self-sufficiency.sh`
  - [x] Spin up a temporary `git clone` with only the minimal relay file
  - [x] Drive a headless agy turn against the clone (agy available; codex fallback wired)
  - [x] Capture output; assert no claim/release path errors
  - [x] Assert `Basis:` field is present in the written block
  - [x] Assert `VERDICT:` field is present and valid
  - [x] Assert no off-allowlist files were written
- [x] Define FAIL criteria explicitly in script header comments:
  - [x] Agent fails to claim/release (path assumptions wrong)
  - [x] Agent omits required log fields (`Basis:`, `VERDICT:`)
  - [x] Agent writes off-allowlist files
- [x] Run `test/relay-self-sufficiency.sh` manually against a real headless agent — confirm exit 0 and a summary line enumerating each assertion checked (4/4 pass after fixture fix)
- [x] If FAIL: the script must print a diagnostic naming the missing field; encode the fix as a committed diff to the relay file template — fixture iterated: removed `---` separator that caused agy to write above the wrong anchor
- [x] Wire `test/relay-self-sufficiency.sh` into `validate.sh` — CI-gate note added; `RELAY_SELF_SUFFICIENCY_SKIP=1` skips when no live agent

### Phase 2 QA Checklist

- [x] Run test against clean temp clone — no ambient repo files present during the run (isolated temp git repo with only relay.md + .gitignore)
- [x] Confirm FAIL path exits non-zero and prints a diagnostic message naming the missing field (tested during iteration: "VERDICT: field missing", "Basis: field missing")
- [x] Confirm PASS path exits 0 and emits a summary of assertions checked (4 pass, 0 fail with summary line)
- [x] Run `validate.sh` — confirm Phase 2 test is included and passes (0 failures, self-sufficiency skipped in CI mode)
- [x] If any tacit-knowledge leak found: confirm the fix is encoded in the relay file template — fixture `---` separator issue found and fixed in template (committed diff)

---

## Phase 3 — Adversarial Multi-Reviewer (Gap 3)

**Goal:** Wire `consult.sh` into the relay loop as an opt-in second opinion, so a self-reporting agent's verdict can be independently challenged.

**Architecture:** Add `--consult-verify` flag to `relay-drive.sh` (not in `rtl_enforce` — consult calls are expensive and must not fire on every standard turn). Insert the consult call AFTER `round=$((round + 1))` (~L160) and BEFORE the no-progress guard (~L163). On divergent verdicts: print conflicting verdicts + diff to stderr, append an advisory conflict-warning block to the relay file log, set `STATUS: Escalated` (exit 4) to halt supervisor.

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
- [ ] Run Phase 1 validator (`bin/validate-relay-block`) on the escalated relay file — confirm it exits `0` (escalation is a valid state; conflict-warning block does not break structural check)
- [ ] Confirm GUIDING-PRINCIPLES.md updated with "Independent Verification (Separated Grading)" principle after Phase 1 ships

---

## Connection to Existing Tracks

- **Part B adversarial hardening** — closest sibling, but triage decision: standalone tooling track (not folded into Part B Phase 2). Gap 1 is a compliance/correctness gate; Part B Phase 2 is a liveness/concurrency chaos suite. Different threat models.
- **GUIDING-PRINCIPLES.md quality bar** — "Attested — carries its receipts: source, evidence, confidence. Never a bare verdict" and Principle 5 ("adversarially proven before commercially viable") are the normative hooks. New principle surfaced by triage (agy, 2026-06-25): "Independent Verification (Separated Grading)" — the agent that produces a turn must not be the sole grader of its quality; verification must be performed by an independent deterministic check or separate reviewing agent before the lock releases. Update is gated on Phase 1 shipping (see Phase 1 checklist — not Phase 3).
- **relay-turn-lib.sh containment hardening (GH-13, GH-14)** — scope enforcement, not quality enforcement; these are siblings, not the same problem.

---

## Origin

Surfaced from reviewing the article "The Rise of the Orchestrator IC" (Kursat Ozenc / Saeideh Bakhshi, Design Meets AI Substack). The article's observation that the bottleneck in multi-agent work shifts to post-generation quality control — independent of the producing agent — maps directly to the relay protocol gap above. The connection: Bakhshi's four-independent-agent-persona validation pattern and her "accountability boundary" framing (AI can't be a teammate because teams require accountability) are the same problem the relay protocol faces when an agent self-grades.
