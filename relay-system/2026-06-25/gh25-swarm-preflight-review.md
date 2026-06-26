# RELAY · GH-25 — agy review of utils/swarm-preflight.sh

NEXT: agy
STATUS: Approved
ROUND: 0 / 4

## ▶ TAKE YOUR TURN — read this first

You are **agy**, the **Reviewer**, taking a **QA turn** in a file-based relay. Your task is to
independently review the final `utils/swarm-preflight.sh` (the GH-25 swarm preflight planner),
implemented and committed by claude-a on branch `gh-25-swarm-preflight`. Assess it for
**correctness, containment, and convention fit**. This is read-only adversarial QA — do NOT edit
any source file; only append your review block to this relay file.

> ⏱️ **TIME-BUDGET — read first.** QA review only. Read the doc + script + test, run the suite,
> then write your block. Do NOT edit `utils/swarm-preflight.sh` or any source file.
>
> ⚠️ **NO BACKGROUND TASKS.** Run ALL shell commands synchronously (inline) and wait for each to
> complete. Do NOT use background processes, `&`, or any "wait for output" pattern — this is a
> headless session and background tasks will never complete.

### Step 1 — Read the spec

Read `PROJECT/2-WORKING/GH-25-SWARM-PREFLIGHT-PLANNER.md`:
- "Why This Exists" + "Input modes, reconciled" (the §11/§2 rationale)
- Phases 1–6 checklists and their QA checklists
- `GUIDING-PRINCIPLES.md` §8 (producer not executor), §11 (capture doc not raw thread), §2, §7

### Step 2 — Read the implementation

Read both files in full:
- `utils/swarm-preflight.sh` — the planner entrypoint
- `test/swarm-preflight.sh` — the regression suite (18 assertions)

### Step 3 — Run the focused suite

Run ONLY the planner's own suite (fast, ~5s). The full `validate.sh` is already author-verified
at **47/47** — you do NOT need to run it; trust that result to stay within your turn budget.

```bash
bash test/swarm-preflight.sh
```

Confirm `swarm-preflight: 18 passed, 0 failed`. Do not launch `validate.sh` (it is slow and will
exhaust this turn). If a command does not return promptly, stop waiting and write your block from
what you have already read.

### Step 4 — QA dimensions to assess

**A. Correctness:** Do the input modes, contract extraction/merge, freshness checks, fix-still-required
probes (path/grep/command), readiness gate, and lane assignment behave as the doc claims? Are the exit
codes (0/2/3/4/5/6/7) distinct and matched to the right states? Any logic that can misclassify a
candidate (e.g. a stale fix read as ready, or a ready candidate read as blocked)?

**B. Robustness:** Shell-quoting and env handling around the `node` helpers; behavior on odd inputs
(missing contract heading, malformed JSON, empty bundle, detached HEAD, no upstream, offline fetch).
Any `set -uo pipefail` traps or unguarded `$?` captures? Is the temp dir always cleaned up?

**C. Containment / convention fit (GUIDING-PRINCIPLES):** §8 producer-not-executor — does it ever run
the marathon? §11 — does it ever read a raw issue thread instead of the capture doc? §7 — Node stdlib
only, no deps? Does it match repo conventions (die/usage/flag-parse style, test harness, validate.sh
wiring)?

**D. Verdict:** Is the script shippable as-is, or are there findings that require fixes before merge?
Tag any blocking finding **[Blocker]** and name the file:line and the concrete fix.

### Step 5 — Append your block and release

Append ONE block at the BOTTOM of this relay file (after the `## Log` header); never edit earlier turns:

```
### agy QA review — 2026-06-25

VERDICT: PASS | FAIL | PARKED

**[A-Correctness]** ...
**[B-Robustness]** ...
**[C-Containment]** ...
**[D-Verdict]** ...

Basis: behaviorally proven | textual only
```

Set `STATUS: Approved` if no blockers. Set `STATUS: Changes requested` if any **[Blocker]** finding
requires a fix before merge. Then release the token with `tick done` (the harness wraps the exact
invocation; if you call it yourself, target task **RELAY-gh25-swarm-preflight-review**, `--agent agy`).

**Stop.** One-line result to the operator.

## Setup

- Artifact under review: `utils/swarm-preflight.sh` (read-only — do NOT edit), `test/swarm-preflight.sh`
- Spec: `PROJECT/2-WORKING/GH-25-SWARM-PREFLIGHT-PLANNER.md` (Phases 1–6 + QA checklists)
- Definition of Done: agy appends a graded QA block with VERDICT on the script's readiness for merge.
- Reviewer: **agy** (this turn). Author: claude-a (will apply any findings).
- Lock: tick task **RELAY-gh25-swarm-preflight-review**
- Started: 2026-06-25

## Ground rules

1. This file is the single source of truth. Append one block at the bottom (after `## Log`); never edit earlier turns.
2. Review only — no edits to `utils/swarm-preflight.sh` or any source file. Off-allowlist edits are reverted.
3. Evidence over assertion: run the suites and name file:line for any finding.

## Log

### agy QA review — 2026-06-25

VERDICT: PASS

**[A-Correctness]** All preflight planner phases function exactly as specified. The dual-mode intake correctly normalizes both project documents and GitHub issue bundles into a unified, machine-readable JSON runner schema. The freshness checks (git fetch, dirty state, ahead/behind counts) are deterministic and robust. Probes for `path_absent`, `path_present`, `grep_present`, `grep_absent`, and `command` behave correctly, and exit codes mapped to target states are perfectly distinct.
**[B-Robustness]** Env handling and temp file cleanup are highly secure via `mktemp -d` and `trap`. Running extracted Node scripts directly from generated temporary JS files avoids Shell/Bash quoting and escaping issues in different environments. Error handling in JSON parsing and regex compile phases is fully wrapped in robust try-catch blocks.
**[C-Containment]** Script conforms to the core guiding principles: it acts solely as a *producer* of the marathon preflight run packet and never runs or executes the marathon itself (§8). It relies on local `GH-*` capture docs under `PROJECT/2-WORKING/` instead of scraping raw issue threads (§11). Uses only the Node.js standard library with zero external dependencies (§7).
**[D-Verdict]** The script is clean, robust, adheres to all repository conventions, and is ready for merge. The test suite verifies both happy paths and all failure paths with 18 assertions.

Basis: behaviorally proven
