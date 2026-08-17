---
gh_issue: 17
source: https://github.com/HiQS-Suite/XYZ-forge/issues/17
title: SOP for Evaluating New Agent Harnesses and Frontier Models
status: Proposed (1-INBOX — not yet active)
created: 2026-08-16
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 2
---

# GH-17: SOP for Evaluating New Agent Harnesses and Frontier Models

## Context & Purpose
Establish a repeatable Standard Operating Procedure (SOP) and template for evaluating, onboarding, and testing new agent harnesses (e.g., Command Code, OpenCode, Pi, Aider, Codex, Antigravity) and their supported model matrices.

Every new harness evaluation must open its own dedicated GitHub tracking issue that documents installation, authentication, capability matrix, model testing notes, and integration verdicts.

---

## SOP: New Harness & Model Evaluation Workflow

### 1. Harness Intake & Discovery
- Identify binary name, install method, version, and global PATH requirements.
- **Foreign App Isolation (GH-347)**: Ensure harness dependencies/binaries are not installed inside foreign application directories without explicit path management.
- **Python-Only Rails (GH-551)**: Any new driver or turn-taking code must be written in Python under `utils/py/`, adhering to the frozen Bash twin rule.
- Document authentication mechanism (API keys, session tokens, keychain/TTY requirements).
- Catalog CLI surface area:
  - Non-interactive / headless flags (`-p`, `--print`, `--non-interactive`)
  - Model selection flags (`-m`, `--model`, `--list-models`)
  - Autonomy / permission bypass flags (`--auto-accept`, `--yolo`, `-s`)
  - Output formatting (`text`, `json`, `ndjson`)
- **Role & Billing Taxonomy (GH-221)**: Classify target role (Default Builder, Explicit-Cost Builder, Consult Advisor, or Orchestrator) and billing model (Subscription/Cost-blind vs. API-metered).

### 2. Isolated Environment Setup (GH-564 & GH-567 Rails)
- **Separate Standalone Full Clone**: Never test harness turn scripts in the primary development clone. Cut a dedicated full clone in an isolated path.
- **Linked Worktrees Outlawed**: Do not use linked worktrees for harness evaluation (they share `.git/config` and `.git/hooks` with parent clone).
- **Pre/Post-Run Identity Checks (GH-567)**: Verify `core.bare=false`, `remote.origin.url`, local `user.email`, and `HEAD` before and after test turns. Any unexplained drift invalidates the evaluation.

### 3. Non-Interactive & Headless Execution Verification
- Test non-interactive invocation against a standardized evaluation fixture / review task.
- Test error modes and bounded exit codes (aligned with `relay-turn-lib.sh` / `rtl.py`):
  - Timeout handling → exit code 7
  - Authentication expiration / failure → exit code 5
  - Empty response / silent stall → exit code 5
  - Off-allowlist or off-lane modification → exit code 6
- Verify tool execution boundaries: ensure file writes remain strictly scoped to target paths and never escape the workspace root (`$WT`).

### 4. Cross-Model Matrix Evaluation
- Evaluate at least two model tiers per harness:
  - **Tier 1 (Fast / Agentic Workhorse)**: e.g., `qwen/qwen3.7-flash`, `gemini-3.7-flash`, `deepseek-v4-flash`
  - **Tier 2 (Frontier / Reasoning Flagship)**: e.g., `qwen/qwen3.8-max`, `claude-sonnet-5`, `gpt-5.6-sol`
- Measure latency, instruction following, reasoning depth, citation accuracy, and tool discipline.
- Test resistance to prompt-injection or instruction-drift in task context.

### 5. Relay & Multi-Agent Compatibility
- Assess turn-taker shim feasibility (`relay-turn-lib.sh` / `rtl.py` integration).
- Verify worktree containment, file-scoped git commits, and token handoff mechanisms (`tick claim`, `tick release`, `tick done`).

### 6. Documentation, Issue Logging & Roadmap Intake
- Create a dedicated GitHub tracking issue for the harness (referencing GH-17).
- Author an in-repo PDDA capture doc in `PROJECT/1-INBOX/GH-<num>-<SLUG>.md`.
- Include a formal Verdict Block (`accept | conditional | reject`).
- Park a one-line entry in `ROADMAP.md` queue.

---

## Acceptance Criteria
- [ ] Evaluation executed in a verified standalone full clone.
- [ ] Pre- and post-run identity checks verified zero git drift.
- [ ] Non-interactive execution verified with bounded exit codes.
- [ ] At least two model tiers tested and benchmarked.
- [ ] Dedicated GitHub tracking issue created and populated.
- [ ] In-repo PDDA capture doc committed and parked in `ROADMAP.md`.
