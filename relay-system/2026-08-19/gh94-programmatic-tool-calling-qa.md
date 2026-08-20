# RELAY · GH-94 Programmatic Tool Calling Plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-19.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh94-programmatic-tool-calling-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-94-PROGRAMMATIC-TOOL-CALLING.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-19

### Artifact — GH-94-PROGRAMMATIC-TOOL-CALLING.md
```
---
gh_issue: 94
source: https://github.com/HiQS-Suite/XYZ-forge/issues/94
title: "GH-94: Programmatic Tool Calling & Code-Mode Execution for Harnesses, Telemetry, and Containment"
status: Active
created: 2026-08-19
updated: 2026-08-19
owner: orchestrator
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 4
goal: >
  Evaluate the architectural transition from structured JSON tool calling to programmatic code-mode
  execution: benchmark the "26 tool" tipping point in custom runner adapters, add deterministic synthetic
  containment fuzzing via fuzz-loop.sh, instrument ATE with token/latency metrics, and define the
  telemetry and model registry evidence standards.
---

# GH-94: Programmatic Tool Calling & Code-Mode Execution for Harnesses, Telemetry, and Containment

## Status

| What was just completed | What's next |
|---|---|
| Initial intake, GitHub issue #94 filed with detailed 4-area research scope, dual-track fuzzing/variation strategy evaluated and posted to issue #94. Standalone clone `XYZ-forge-gh94` provisioned for isolated execution. | **Phase 1:** Author deterministic synthetic test suite `test/synthetic/gh94-script-serialization.sh` covering multiline string escaping, syntax errors, and timeout handling under `utils/fuzzing/fuzz-loop.sh`. |

## Table of contents
- [Phase 1: Deterministic Script Serialization & Timeout Fuzzing](#phase-1-deterministic-script-serialization--timeout-fuzzing)
- [Phase 2: Worktree Containment & Sandbox Boundary Invariants](#phase-2-worktree-containment--sandbox-boundary-invariants)
- [Phase 3: ATE Metrics Instrumentation (Tokens, Latency & Chaining)](#phase-3-ate-metrics-instrumentation-tokens-latency--chaining)
- [Phase 4: Matrix Benchmarks, Telemetry & Registry Integration](#phase-4-matrix-benchmarks-telemetry--registry-integration)

---

## Phase 1: Deterministic Script Serialization & Timeout Fuzzing

### Objectives
- Add synthetic test coverage to `test/synthetic/` exercising script serialization quirks (literal `\n` escaping vs newline interpolation, nested shell quoting, and syntax error traps).
- Verify that execution timeouts correctly terminate runaway scripts without wedging the harness.

### QA Gate 1
- `bash utils/fuzzing/fuzz-loop.sh` executes all synthetic tests cleanly with `FUZZ_SUMMARY|status=PASS`.

---

## Phase 2: Worktree Containment & Sandbox Boundary Invariants

### Objectives
- Verify that code executed in programmatic script-mode is strictly confined within `$WORK` / worktree boundaries at the use boundary (GH-177, GH-564, GH-1).
- Add synthetic assertions confirming that unconstrained Python/Bash execution cannot mutate `.git/config` or delete untracked parent files.

### QA Gate 2
- Run synthetic containment tests through `utils/fuzzing/fuzz-loop.sh` and verify 0 sandbox escapes.

---

## Phase 3: ATE Metrics Instrumentation (Tokens, Latency & Chaining)

### Objectives
- Extend `utils/ate/scripts/run_variations.py` to record:
  - `duration_ms` (wall-clock latency)
  - `prompt_tokens` and `completion_tokens` (when available via provider metadata)
  - `turn_count` (chain depth)
- Ensure all metrics are append-logged to `error_log.jsonl`.

### QA Gate 3
- Run a trial variation pass with `run_variations.py --minutes 1` on a dry-run grid and assert all 4 metric fields are present in `error_log.jsonl`.

---

## Phase 4: Matrix Benchmarks, Telemetry & Registry Integration

### Objectives
- Author `utils/ate/variations.tool-calling.yaml` sweeping tool count density (5 to 100 tools) vs execution mode (`json` vs `python_script`) across target models.
- Synthesize benchmark findings and architectural recommendations into `HARNESS-MODELS-REGISTRY.md`.

### QA Gate 4
- Documented benchmarks with verifiable receipts in `HARNESS-MODELS-REGISTRY.md` and passing `./validate.sh`.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1

swept file: yes

- [Blocker] The Definition of Done is still a placeholder, so the four gates cannot be graded as an acceptance contract. Fix: replace it with measurable completion criteria covering the named test files, containment invariants, JSONL schema/absence semantics, benchmark receipt fields, and the exact commands plus expected outcomes. (`relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:130`)
- [Blocker] The containment objective asserts that “unconstrained” Python/Bash cannot mutate parent state, but supplies no execution boundary, sentinel design, or safe isolated-clone procedure; that is both technically untestable as written and dangerous to exercise. Fix: specify the constrained runner boundary, a full-clone fixture with parent/config sentinels, use-boundary path assertions, and post-run invariant checks (including expected failure handling) before adding the synthetic test. (`relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:98-103`)
- [Should] Timeout coverage has no timeout value, child-process cleanup criterion, or bounded test invocation; `FUZZ_SUMMARY|status=PASS` alone cannot establish that a runaway did not wedge the harness. Fix: define deterministic fixture inputs, timeout/grace values, expected exit/status, and assertions that the process group is gone and subsequent test execution succeeds. (`relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:87-92`)
- [Should] The telemetry gate only checks four field names. It omits a schema for unavailable provider usage, units/source-of-truth, run/model/variation identifiers, and a concrete JSONL record selector, so an unrelated or malformed record could satisfy it. Fix: define a versioned per-variation record schema (including nullable token fields and run identifiers) and make the dry-run gate validate the newly written record against it. (`relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:109-117`)
- [Should] The benchmark plan does not say how the claimed 26-tool tipping point will be determined: the range lacks fixed scenarios, repetitions, model/provider versions, success/latency/cost metrics, comparison rule, and receipt location. Fix: add a reproducible matrix and decision rule, then require registry receipts that link each recommendation to raw, committed run evidence. (`relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:62-66; relay-system/2026-08-19/gh94-programmatic-tool-calling-qa.md:123-128`)

Verdict: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
