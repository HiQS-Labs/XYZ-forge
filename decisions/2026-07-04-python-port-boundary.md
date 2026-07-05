# 2026-07-04 Python Port Boundary Decision

## Context
GH-112 spiked a progressive Python port of the relay/marathon turn takers. The goal was to determine the boundary between Bash (required for BSD/macOS portability and containment) and Python (better for orchestration and JSON parsing), and choose an architecture for the port.

## Decision
We will proceed with **Option A (Discrete Python CLIs behind Bash shims)**.

1. **Permanent Bash Surface:** `relay-turn-lib.sh` remains Bash permanently. It is the core containment library sourced by:
   - `agy-turn.sh`
   - `aider-turn.sh`
   - `claude-turn.sh`
   - `codex-turn.sh`
   - `consult.sh`
   - `marathon-drive.sh`
   - `relay-drive.sh`

   Because Python cannot `source` a Bash library, the FFI boundary will sit between the thin Bash shim (which sources `relay-turn-lib.sh`) and the Python script (which is executed by it).

2. **Chosen Model (Option A):** Each turn script will be ported to `utils/py/<script>.py`. A thin Bash shim will replace the original script (e.g., `relay-automation/aider-turn.sh`) and execute the Python script using `exec python3`.

3. **Test-Bridge Contract:** The 85-test shell suite requires **zero changes**. Grepping the `test/` directory confirmed that no tests directly `source` the turn scripts; they are all invoked as subprocesses. The Bash shims will preserve the exact CLI interface and exit-code contract.

## Follow-up Action
As the boundary is clean and Option A is viable, we will open one follow-up issue per turn script to track the progressive porting (e.g. `aider-turn.sh` -> Python, `codex-turn.sh` -> Python, etc.) as individual marathon targets, as outlined in the dogfood architecture section of the GH-112 spike.

**Status:** Accepted
