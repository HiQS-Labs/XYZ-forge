# RELAY · GH-21 Phase 2 QA — relay-self-sufficiency test

NEXT: agy
STATUS: In Progress
ROUND: 0 / 1

## ▶ TAKE YOUR TURN — read this first

You are **agy**, the **Reviewer**, taking a **QA turn** in a file-based relay. Your task is to
independently review Phase 2 of GH-21 — `test/relay-self-sufficiency.sh` and
`test/fixtures/minimal-relay.md` — which were implemented directly by claude-a (without a
relay Producer turn). This is the adversarial post-build QA that should have happened before
Phase 2 was marked complete.

> ⏱️ **TIME-BUDGET — read first.** QA review only. Do NOT edit any source files. Read the
> implementation, run the test suite, then write your block.
>
> ⚠️ **NO BACKGROUND TASKS.** Run ALL shell commands synchronously (inline) and wait for
> each to complete before continuing. Do NOT use background processes, `&`, or any "wait
> for output" pattern — this is a headless session and background tasks will never complete.

### Step 1 — Read the Phase 2 spec

Read `PROJECT/2-WORKING/GH-21-RELAY-QUALITY-GATE.md`, sections:
- Phase 2 goal and Architecture paragraph
- Phase 2 Checklist (all items)
- Phase 2 QA Checklist (all items)

### Step 2 — Read the implementation

Read both files in full:
- `test/fixtures/minimal-relay.md` — the minimal relay template
- `test/relay-self-sufficiency.sh` — the test script

### Step 3 — Run the test suite

```bash
RELAY_SELF_SUFFICIENCY_SKIP=1 bash "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/validate.sh"
```

Confirm 0 failures across all tests.

### Step 4 — Verify the FAIL path

The test script must print named diagnostics when assertions fail. Verify this by running the
test with a synthetic broken relay file (missing VERDICT:). You can do this by:

1. Creating a temp relay file that lacks `VERDICT:` in the log section
2. Running the B1 grep pattern manually against it to confirm the diagnostic would fire

You do NOT need to run a live agy call for this — just verify the diagnostic logic is correct.

### Step 5 — QA dimensions to assess

**A. Spec compliance:** does the implementation match every item in the Phase 2 Checklist?

**B. FAIL path correctness:** do the diagnostic messages name the specific missing field?
Check all three FAIL criteria:
- (A) relay file not modified — does the diagnostic name the cause?
- (B1) VERDICT: missing — does the diagnostic name the field?
- (B2) Basis: missing — does the diagnostic name the field?

**C. CI gate:** is `RELAY_SELF_SUFFICIENCY_SKIP=1` correctly documented and enforced in both
the script and validate.sh?

**D. Fixture quality:** does `test/fixtures/minimal-relay.md` contain any tacit-knowledge
dependency on this repo's ambient files (CLAUDE.md, AGENTS.md, baton-pattern.md)?
If any instruction in the TAKE YOUR TURN block would require the agent to read an
external file to succeed, that is a tacit-knowledge leak.

**E. Tick wrapper correctness:** the test creates `$REPO/bin/tick` as a wrapper shell script.
Does this wrapper correctly isolate tick events to the temp repo (not the harness)?
Is there any scenario where events could leak into the harness `.tick/`?

**F. Overall verdict:** is Phase 2 shippable as-is, or are there findings that require fixes?

### Step 6 — Append your block and release

Append ONE block at the BOTTOM of this relay file (after the `## Log` header):

```
### agy QA review — 2026-06-25

VERDICT: PASS | FAIL | PARKED

**[A-Spec]** ...
**[B-Fail-Path]** ...
**[C-CI-Gate]** ...
**[D-Fixture]** ...
**[E-Tick-Wrapper]** ...
**[F-Verdict]** ...

Basis: behaviorally proven | textual only
```

Set `STATUS: Approved` if no blockers. Set `STATUS: Changes requested` if any [Blocker]
findings require fixes before Phase 2 can be called done.

Then release the token:

```bash
TICK_REPO_ROOT="/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm" \
  "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick" \
  done RELAY-gh21-phase2-qa --agent agy
```

**Stop.** One-line result to the operator.

## Setup

- Artifact: `test/relay-self-sufficiency.sh`, `test/fixtures/minimal-relay.md` (read-only — do NOT edit)
- Spec: `PROJECT/2-WORKING/GH-21-RELAY-QUALITY-GATE.md` → Phase 2 Checklist + Phase 2 QA Checklist
- Definition of Done: agy appends a graded QA block with VERDICT on Phase 2 readiness.
- Reviewer: **agy** (this turn). Author: claude-a (will apply any remaining findings).
- Lock: tick task **RELAY-gh21-phase2-qa**
- Started: 2026-06-25

## Ground rules

1. This file is the single source of truth. Append one block at the bottom (after `## Log`); never edit earlier turns.
2. Do NOT edit source files — QA review turn only.
3. Evidence contract: `Basis: behaviorally proven` (ran commands and observed) or `textual only` (read, not run).
4. RELAY_WORKTREE_ISOLATION=0 for this run (GH-22 workaround).

## Log
