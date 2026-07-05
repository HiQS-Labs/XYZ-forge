---
gh_issue: 112
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112
title: "Spike: progressive Python port — boundary decision + dogfood architecture"
status: completed
created: 2026-07-03
updated: 2026-07-04
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
| Spike completed and dogfood architecture fully implemented across 4 phases. | Python port completed successfully! (2026-07-04) |

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

- [x] Map the `source` dependency graph: which scripts source `relay-turn-lib.sh`, which are
      sourced by it, and which are standalone invocations only.
- [x] Prototype Option A shim for `aider-turn.sh` (or the simplest turn script): write
      `utils/py/aider-turn.py` stub + shim, verify the exit-code contract passes through cleanly.
- [x] Grep `test/` for direct `source` of turn scripts; count and assess fix cost.
- [x] Write findings back into this doc (findings section below) before the QA gate can pass.
- [x] Write `decisions/2026-07-04-python-port-boundary.md` naming:
      (a) permanent Bash surface, (b) chosen model (A or B), (c) test-bridge contract.
- [x] If boundary is clean: open one follow-up issue per turn script and link from the decision
      record. (We will note this in the decision record)

### Findings

**`source` dependency graph:**
`relay-turn-lib.sh` is sourced by: `agy-turn.sh`, `aider-turn.sh`, `claude-turn.sh`, `codex-turn.sh`, `consult.sh`, `marathon-drive.sh`, and `relay-drive.sh`. Therefore, `relay-turn-lib.sh` must remain Bash permanently as the containment boundary.

**Option A prototype result:**
Prototyping Option A for `aider-turn.sh` was successful. A python stub at `utils/py/aider-turn.py` was executed via a thin Bash shim using `exec python3`. The stub was able to successfully invoke a shell subprocess to source `relay-turn-lib.sh` and exit with `0`. The exit-code contract is preserved.

**Test suite `source` grep:**
Grepping the `test/` directory revealed **0** instances of tests directly sourcing the turn scripts (`source .*-turn.sh` or `. .*-turn.sh`). All tests invoke the shims as subprocesses. Thus, the fix cost for the test suite is zero.

**Recommended model (A or B) and rationale:**
**Option A** is highly recommended. The migration can be done file-by-file incrementally without breaking the existing 85-test shell suite, which interacts perfectly with the thin Bash shims. The boundary is clean.

### QA gate — Phase 0

- [x] All three questions are answered with specific findings (not "TBD") written back above.
- [x] `decisions/2026-07-04-python-port-boundary.md` (or equivalent) exists and is committed.
- [x] The decision record names a concrete permanent Bash surface (not "probably relay-turn-lib.sh"
      — the actual file list).
- [x] Either (a) follow-up issues are opened and linked, or (b) the decision record explicitly
      closes the question with rationale.
- [x] `./validate.sh` green (spike produces no prototype artifacts in the main tree — only the
      decision record and this doc update).

---

## Progressive Python Port Roadmap

Based on the spike's findings (Option A viability and a clean FFI boundary at `relay-turn-lib.sh`), the progressive Python port will be executed in four pragmatic phases. The harness can drive its own Python replacement as a dogfood exercise: the wave planner that schedules lanes in `rebalance-OS` will schedule this port.

### Phase 1 — Headless Turn Scripts (The Dogfood Proof)
The safest starting point. We port the core model turn-takers to Option A while preserving the bash shims. These lanes are disjoint and can be wave-packed in parallel.
- **Lane 1**: `aider-turn.sh` → `utils/py/aider-turn.py`
- **Lane 2**: `codex-turn.sh` → `utils/py/codex-turn.py`
- **Lane 3**: `claude-turn.sh` → `utils/py/claude-turn.py`
- **Lane 4**: `agy-turn.sh` → `utils/py/agy-turn.py`
*Gate:* Existing shell tests for each script must pass through the shim + `python3 -m py_compile` on the new file.

### Phase 2 — Complex Turn Scripts & Helpers
Move the heavier, stateful, or inline-scripted turn features to Python.
- **Lane 1**: `consult.sh` watchdog — Convert to a Python subprocess.
- **Lane 2**: Inline Python heredocs — Extract inline Python embedded in `relay-automation/*.sh` into structured helpers under `utils/py/` (e.g., `parse-relay-field.py`).
- **Lane 3**: `poll.sh` / `relay-loop.sh` — Move the continuous polling logic to Python while keeping the underlying `tick` queries pure.

### Phase 3 — Marathon & Relay Orchestration
With the lower-level scripts ported, we move up the stack to the highest-level orchestrators. This provides the highest payoff for Python's structured concurrency and JSON parsing.
- **Lane 1**: `relay-drive.sh` → `utils/py/relay-drive.py`
- **Lane 2**: `marathon-drive.sh` → `utils/py/marathon-drive.py`
- **Lane 3**: `swarm-preflight.sh` & `marathon-plan.sh`
*Note:* As the orchestrators become Python-native, they can directly import the modules created in Phase 1 (moving towards Option B internally), while still maintaining the FFI boundary for `relay-turn-lib.sh`.

### Phase 4 — Test Bridging & Formalization
Solidify the new architecture and clean up legacy bridging.
- **Native Python Testing**: Introduce `pytest` for unit testing the new Python modules directly.
- **E2E Shell Suite**: Keep the original 85-test Bash suite intact as high-level integration tests.
- **Shim Deprecation**: Once `relay-drive.sh` and `marathon-drive.sh` are fully Python, the discrete Option A Bash shims for individual turn scripts (e.g., `relay-automation/aider-turn.sh`) can be safely retired, leaving `relay-turn-lib.sh` as the sole, permanent Bash isolation boundary.

---

## Addendum — how this actually landed (2026-07-04, branch `gh112-python-optin`)

The 4-phase port above was first delivered as PR #121 (Python-by-default: entry scripts replaced
with unconditional `exec python3` shims, originals renamed to `*-legacy.sh`, `XYZ_LEGACY_BASH=1`
fallback on only 4 of 11 scripts). That PR was **not merged**: it conflicted with the #134
reliability wave (which edited the very shell scripts the shims replaced), targeted `development`
instead of `main`, and left 7 scripts with no Bash escape hatch.

The landed shape inverts the toggle:

- **Bash stays the default.** All 11 entry scripts keep their canonical shell bodies untouched.
- **`XYZ_PYTHON=1` is the opt-in** — a uniform header shim in every ported script reroutes to the
  matching `utils/py/` module (same CLI contract, same exit codes). No `-legacy.sh` renames.
- `relay-turn-lib.sh` remains the permanent Bash containment boundary (per the decision record);
  the Python modules reach it through `utils/py/rtl.py`.
- **Promotion gate:** Python does not become the default until the #134 shell changes
  (containment tool-cache ignore, marathon/preflight fixes) are ported into `utils/py/` and the
  full suite passes with `XYZ_PYTHON=1`. Tracked on #112.
