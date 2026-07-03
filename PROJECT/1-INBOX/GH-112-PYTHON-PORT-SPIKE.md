---
gh_issue: 112
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112
title: "Spike: progressive Python port — boundary decision + dogfood architecture"
status: parked
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: spike
complexity: 3
risk: 3
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not writing any production Python code during the spike
  - Not porting the tick kernel or relay-turn-lib.sh (these likely stay Bash permanently)
  - Not changing the 85-test shell suite structure
  - Not deciding a delivery timeline — this spike gates whether port lanes are queued at all
related:
  - PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md
  - relay-automation/relay-turn-lib.sh
  - relay-automation/codex-turn.sh
  - relay-automation/aider-turn.sh
  - relay-automation/claude-turn.sh
  - relay-automation/consult.sh
  - relay-automation/relay-xyz-guard.sh
  - src/
  - test/
roadmap_exempt: false
---

# GH-112 · Spike: progressive Python port — boundary decision + dogfood architecture

**Why:** Gemini 3.1 (GH-109) observed that the harness performs Python-appropriate work in Bash:
process orchestration, JSON parsing, watchdog timers, and structured concurrency. A full rewrite
was declined (BSD/macOS Bash 3.2 portability is a hard constraint; relay-turn-lib.sh sourcing has
no Python analog). But a **progressive port driven by the harness itself as a dogfood exercise**
is worth evaluating — if the Bash/Python boundary is clean, each turn script becomes a natural
marathon lane and the harness self-improving is the most ambitious self-proof it could run.

This is a **spike only.** Its deliverable is a decision record, not shipped code. If the boundary
is clean enough to queue lanes, a follow-up issue is opened per turn script. If it is messy, the
spike documents why and closes the question.

## Status

| What was just completed | What's next |
|---|---|
| GH-112 opened 2026-07-03; spike doc created. | Phase 0: answer the three boundary questions and write the decision record. |

## Table of contents

- [Phase 0 — Spike: boundary + architecture decision](#phase-0--spike-boundary--architecture-decision)

---

## Phase 0 — Spike: boundary + architecture decision

One relay or solo lane. One agent. Three questions answered, one decision record written.

### The three questions

#### Q1 — What stays Bash permanently?

Candidates for permanent Bash surface:

- **`relay-turn-lib.sh`** — the containment library is `source`d by all turn scripts and every
  relay driver. Python cannot `source` a Bash library. This is the hardest constraint: if the
  Python layer needs containment functions, they must either (a) be re-implemented in Python
  (fork risk) or (b) invoked as subprocess shell calls (fragile). Most likely outcome: this file
  stays Bash and becomes the permanent FFI boundary.
- **`bin/tick` and `src/`** — the tick kernel is Node.js/JS, not Bash, and is already separate.
  Not in scope.
- **Containment guards** (`relay-xyz-guard.sh`, `validate-relay-block`) — these run as hooks or
  standalone checks. If they stay Bash, the Python layer calls them as subprocesses. Fine.
- **`poll.sh`** — file-watching + shell signals; could move to Python's `watchdog` library or
  `inotify` but probably not worth it.
- **Marathon/swarm scripts** (`marathon-drive.sh`, `swarm-preflight.sh`) — heaviest orchestration;
  highest Python benefit; but also deepest `relay-turn-lib.sh` integration. Move last, not first.

**Spike task:** read the `source` dependency graph. Any file that `source`s `relay-turn-lib.sh`
or is `source`d by it is in the Bash-permanent or Bash-first zone unless the lib is also ported.

#### Q2 — What is the Python entry-point model?

Two options with very different migration shapes:

**Option A — Discrete Python CLIs behind Bash shims:**
Each ported script becomes `utils/py/codex-turn.py` (or similar). A thin Bash shim
`relay-automation/codex-turn.sh` remains and does:
```bash
exec python3 "$XYZ_ROOT/utils/py/codex-turn.py" "$@"
```
The rest of the harness never knows. Migration is file-by-file; the 85-test suite keeps running
against the same shell entry points. **Safest migration path.**

**Option B — Python orchestrator with Bash FFI:**
A Python top-level orchestrator (`relay-automation/relay-drive.py`) calls the Bash layer only for
primitives that must be shell (tick ops, containment functions). Turn scripts become Python modules
imported by the orchestrator. **Higher payoff if we get there; harder to do incrementally because
the orchestrator must exist before any turn script can move.**

**Spike task:** prototype Option A for exactly one turn script (e.g., `aider-turn.sh`) — not
production-ready, just enough to verify the shim/invoke/exit-code contract works end-to-end.
Compare against the cost of Option B's orchestrator bootstrapping.

#### Q3 — How does the test suite bridge?

The 85 shell tests run against shell entry points. Under Option A, the shim keeps the entry point
name identical — tests pass with zero changes. Under Option B, a bridge is needed (either a
compatibility shim or a Python test runner that replaces the shell suite).

Additional sub-questions:
- Do any tests `source` a turn script directly (not just call it as a subprocess)? If yes, those
  tests break under Option A shims too and need fixing first.
- Does the Python layer need its own test suite? (Probably yes — but it can be additive, not
  replacing the shell suite.)

**Spike task:** grep the test suite for direct `source` of turn scripts. If found, count them and
assess the fix cost.

### Checklist

- [ ] Map the `source` dependency graph: which scripts source `relay-turn-lib.sh`, which are
      sourced by it, and which are standalone invocations only.
- [ ] Prototype Option A shim for `aider-turn.sh` (or the simplest turn script): write
      `utils/py/aider-turn.py` stub + shim, verify the exit-code contract passes through cleanly.
- [ ] Grep `test/` for direct `source` of turn scripts; count and assess fix cost.
- [ ] Write findings back into this doc (findings section below) before the QA gate can pass.
- [ ] Write `decisions/2026-07-03-python-port-boundary.md` (or date of completion) naming:
      (a) permanent Bash surface, (b) chosen model (A or B), (c) test-bridge contract.
- [ ] If boundary is clean: open one follow-up issue per turn script and link from the decision
      record. If messy: document why and close this question in the decision record.

### Findings

*(To be written back here before the QA gate passes.)*

**`source` dependency graph:**

**Option A prototype result:**

**Test suite `source` grep:**

**Recommended model (A or B) and rationale:**

### QA gate — Phase 0

- [ ] All three questions are answered with specific findings (not "TBD") written back above.
- [ ] `decisions/2026-07-03-python-port-boundary.md` (or equivalent) exists and is committed.
- [ ] The decision record names a concrete permanent Bash surface (not "probably relay-turn-lib.sh"
      — the actual file list).
- [ ] Either (a) follow-up issues are opened and linked, or (b) the decision record explicitly
      closes the question with rationale.
- [ ] `./validate.sh` green (spike produces no prototype artifacts in the main tree — only the
      decision record and this doc update).

---

## Dogfood architecture (if boundary is clean)

If the spike concludes Option A is viable, the port becomes a standard marathon target:

| Lane | Script | Write-glob | Dep |
|---|---|---|---|
| Lane 1 | `aider-turn.sh` → `utils/py/aider-turn.py` | `utils/py/aider-turn.py`, `relay-automation/aider-turn.sh` | none |
| Lane 2 | `codex-turn.sh` → `utils/py/codex-turn.py` | `utils/py/codex-turn.py`, `relay-automation/codex-turn.sh` | none |
| Lane 3 | `claude-turn.sh` → `utils/py/claude-turn.py` | `utils/py/claude-turn.py`, `relay-automation/claude-turn.sh` | none |
| Lane 4 | `consult.sh` watchdog → Python subprocess | `relay-automation/consult.sh` | GH-109 P1 done first |
| Lane 5 | Inline Python heredocs → `utils/py/` helpers | `utils/py/parse-relay-field.py`, callers | GH-109 P2 done first |

Write-globs are disjoint (each lane owns its own files) — wave-packable in parallel. Each lane's
gate: the existing shell test for that script still passes through the shim, plus `python3 -m py_compile` on the new file.

The harness driving its own Python replacement is the dogfood proof: the same wave planner that
schedules lanes in `rebalance-OS` would schedule this port. Lanes 1–3 are the cleanest proof —
identical structure, no shared state, easy to wave together.
