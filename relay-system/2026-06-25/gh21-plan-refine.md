# RELAY · plan refinement — GH-21 Relay Quality Gate

NEXT: agy
STATUS: Approved
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first
You are **agy**, the Advisor, taking a **planning turn** in a file-based relay. Your task is to
**refine the GH-21 project plan** (Relay Quality Gate). This is an advisory turn — read the plan
and the related scripts, then append ONE analysis block to THIS relay file. Do **not** edit the
plan doc itself.

> ⏱️ **TIME-BUDGET — read first.** Do a **textual** review only. Do NOT run `./validate.sh` or
> any test suite — the harness is already green (22/22 agy-turn tests passed). Read the plan and
> the referenced scripts, then write your block. Cite code by absolute path:line.

1. **Read the project plan** (do NOT edit it):
   `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md`

2. **Read the implementation context** (read-only, skim what you need):
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh`
     (the supervisor — where Gap 1's quality gate would plug in)
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh`
     (the containment core — understand Gap 1's scope: scope-enforcement vs quality-enforcement)
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/runner.sh`
     (verdict-gated runner — see if Gap 1 belongs here instead)
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/consult.sh`
     (the advisory parallel consult — Gap 3's wiring point)

3. **Refine the plan** — answer these questions concisely in your block:

   **Gap 1 (structural block validator):**
   - Where exactly does the validator hook in? After the turn-taker appends its block but before
     `tick release` — is that in `relay-drive.sh` (supervisor layer) or `relay-turn-lib.sh`
     (`rtl_enforce`)? Cite the line where it would slot in.
   - What 4–5 fields should the deterministic check assert? (turn block present, `VERDICT:` line,
     `Basis:` line, no off-allowlist files, status line updated — which of these are load-bearing?)
   - Should it reuse `exit 6` (containment revert slot) or get a new exit code (e.g. `exit 8`)?

   **Gap 2 (self-sufficiency test):**
   - What is the minimal test? What does FAIL look like (wrong block shape, missing `Basis:`, wrong
     `tick` handoff command, or something else)?
   - Does it belong in `test/relay-self-sufficiency.sh` (new file) or alongside `test/agy-turn.sh`?
   - What fixture do you need — a minimal relay file template or the full baton-pattern.md?

   **Gap 3 (`consult.sh` wiring):**
   - Is `--consult-verify` on `relay-drive.sh` the right seam, or a post-turn hook in
     `relay-turn-lib.sh`'s `rtl_enforce`?
   - What does "surfaces divergent verdicts to the operator" look like operationally — a diff
     printed to stderr, a block appended to the relay file, or something else?

   **Triage:**
   - Which gap first? Why? (Justify in 1–2 sentences.)
   - Fold into **Part B Phase 2** (chaos suite, ADVERSARIAL-HARDENING.md) or standalone tooling
     track? Why?

   **GUIDING-PRINCIPLES.md implication:**
   - Do any of these three gaps expose a principle not yet named in
     `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/GUIDING-PRINCIPLES.md`?
     If yes, name it. If no, say so explicitly.

4. **Append ONE block** at the bottom of THIS relay file (above the `---` marker) using tags:
   `[Gap1]`, `[Gap2]`, `[Gap3]`, `[Triage]`, `[Principle]` — one bullet per finding.
   Log a `Basis:` line (textual only / behaviorally proven).

5. **Set the header:** `STATUS: Approved` (your refinement block is the complete output — no
   further turn needed unless you find a blocker); `STATUS: Changes requested` only if you need
   a follow-up Claude-a turn.

6. **Hand off the lock** (tick absolute path, do not shorten):
   ```
   TICK_REPO_ROOT="/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick" done RELAY-gh21-plan-refine --agent agy
   ```

7. **Stop.** One-line result to the operator.

## Setup
- Artifact: `PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md` (read-only — do NOT edit it)
- Definition of Done: agy appends a refinement block with architecture guidance + triage decision
- Reviewer: **agy** (this turn). Author: Claude-a (will apply findings to the plan doc)
- Lock: tick task **RELAY-gh21-plan-refine**
- Started: 2026-06-25

## Ground rules
1. This file is the single source of truth. Append one block at the bottom (above `---`); never edit earlier turns.
2. Do NOT edit `PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md` — advisory turn only.
3. Stay tight: bullets, not essays. Cite real code by absolute path:line when possible.
4. Evidence contract: log a `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run).

---
## Log

### Round 1 · Advisor · agy · 2026-06-25
**Verdict:** Approved
**Basis:** textual only (read plan doc + relay-drive.sh + relay-turn-lib.sh + runner.sh + consult.sh; did not run suite)

- **[Gap1]** The validator must slot into `relay-turn-lib.sh`'s `rtl_enforce` ([relay-turn-lib.sh:L322](relay-automation/relay-turn-lib.sh#L322)), before the file-scoped commit. However, since the agent executes `tick release` during its own execution block (before `rtl_enforce` runs), the token will have already released. To truly run *before* release, the validation must hook into `bin/tick`'s `release` and `done` verbs ([bin/tick:L220](bin/tick#L220) / [bin/tick:L236](bin/tick#L236)). Deterministic checks should assert: new log block present under `## Log`, header `STATUS:` updated, `VERDICT:` present and valid (`PASS|FAIL|PARKED`), `Basis:` line present and well-formed. Should use a new exit code `exit 8` to distinguish structural quality failures from containment violations (`exit 6`).
- **[Gap2]** Minimal test: drive a turn against a test relay file in a temporary git clone containing *only* the relay file and minimal coordination scripts. FAIL = agent fails to claim/release (path assumptions wrong), omits required log fields (`Basis:`, `VERDICT:`), or writes off-allowlist. Belongs in a new `test/relay-self-sufficiency.sh` using a minimal relay file template fixture (not `baton-pattern.md`) to avoid leaking ambient repo context.
- **[Gap3]** `--consult-verify` belongs as an opt-in flag on `relay-drive.sh` (not in `rtl_enforce`) to prevent expensive API calls on standard turns. Divergent verdicts: print conflicting verdicts + diff to stderr, append an advisory conflict-warning block to relay file log, halt driver by setting `STATUS: Escalated` (exit 4).
- **[Triage]** Gap 1 first — lowest cost, deterministic, immediately prevents malformed logs from advancing the relay. Standalone tooling track (quality gate in `validate.sh`), NOT folded into Part B Phase 2 — this is a compliance/correctness gate, not a liveness/concurrency failure handler like the chaos suite.
- **[Principle]** These gaps expose a new principle not yet in GUIDING-PRINCIPLES.md: **"Independent Verification (Separated Grading)"** — the agent that produces a turn must not be the sole grader of its quality; verification must be performed by an independent deterministic check or separate reviewing agent before the lock releases.

