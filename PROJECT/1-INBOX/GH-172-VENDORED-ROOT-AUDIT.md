---
gh_issue: 172
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172
title: Vendored harness root-semantics audit before Python-default cutover
status: Active audit in fresh origin/main worktree — Phase 0 root/claim parity fixes landed and verified
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: bugfix
complexity: 4
risk: 4
effort: 4
phases: 3
ratings_provisional: false
non_goals:
  - Not switching main to Python-default in this issue itself
  - Not deleting the Bash path in this issue
  - Not treating vendoring as the cause without checking the actual root contract at each call site
related:
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
  - relay-automation/claude-turn.sh
  - relay-automation/agy-turn.sh
  - utils/py/marathon_drive.py
  - utils/py/relay_drive.py
  - utils/py/claude-turn.py
  - utils/py/agy-turn.py
  - utils/py/poll.py
  - test/marathon-drive.sh
  - test/claude-turn.sh
  - test/agy-turn.sh
  - test/poll-driver.sh
goal: >
  Audit and harden vendored .xyz root semantics before any Python-default cutover: keep harness-install
  root, coordination root, and target/work root distinct; resolve the tick binary independently of
  TICK_REPO_ROOT; and prove both Bash and XYZ_PYTHON=1 driven runs keep all token/cost events in the
  consumer repo's .tick rather than a stray .xyz/.tick.
roadmap_exempt: false
---

# GH-172 · Vendored harness root-semantics audit

Reversibility: **Costly.** The touched surface spans the shared relay/marathon drivers, multiple
worker shims, and regression coverage for vendored consumers. Rollback is straightforward in git, but
the blast radius is cross-lane: a wrong root contract can stall real relay runs or silently split the
event log.

## Status

| What was just completed | What's next |
|---|---|
| Recreated the missing GH-172 doc that `ROADMAP.md` already linked, then landed the first audit slice from a clean `origin/main` worktree: shared Python tick resolution/claim helpers, claim-before-launch in `utils/py/agy-turn.py` and Bash/Python `claude-turn`, vendored/root-split Claude cost capture, Python `poll.py` harness-tick fallback, and vendored regressions for both Bash and `XYZ_PYTHON=1`. Verified by `test/agy-turn.sh` 36/0, `test/claude-turn.sh` 34/0, `test/poll-driver.sh` 38/0, `test/marathon-drive.sh` 65/0, `test/relay-turn-timeout.sh` 9/0, `test/relay-pkg-freshness.sh` 3/0, plus `python3 -m py_compile` clean. | Finish the remaining audit/reporting pass: write the root contract into the durable consumer-facing docs if the current issue doc is not enough, then enumerate any remaining Bash/Python parity gaps and make the stable-Bash / Python-default cutover recommendation. |

## Root contract

In a vendored consumer repo, three roots are distinct and must stay distinct:

1. **Harness install root**: where `.xyz/relay-automation`, `.xyz/bin/tick`, and `.xyz/utils/py` live.
2. **Coordination root**: where `.tick/` lives; this is `TICK_REPO_ROOT`.
3. **Target/work root**: where the editable repo and any throwaway worktrees live.

The audit rule is simple: **never re-derive one of these from another when the orchestrator already
handed the right one in.** In particular, the tick binary path and the tick repo root are separate.

## Findings written back from the audit

### 1. Python agy still missed GH-171's ownership fix

- `relay-automation/agy-turn.sh` already claims and proves ownership before launch.
- `utils/py/agy-turn.py` still launched agy without that check, so `XYZ_PYTHON=1` reviewer turns could
  still edit/commit while the token stayed open under the old owner.

### 2. Claude still had a root-split tick-binary bug

- Bash `relay-automation/claude-turn.sh` captured cost with `${TICK_BIN:-$ROOT/bin/tick}`.
- Python `utils/py/claude-turn.py` captured cost with `os.path.join(root, "bin", "tick")`.
- In a vendored/root-split run, `root` is the target/work repo, not the harness install root, so both
  ports could skip or misroute `cost.tokens` even when `TICK_REPO_ROOT` was pinned correctly.

### 3. Claude builder shims were behind the other workers on ownership proof

- Codex, Aider, and Bash agy already proved token ownership before launch.
- Bash/Python Claude still relied on the model turn to do the right thing, leaving the same
  no-progress family exposed for a driven builder lane.

### 4. Python poll still depended on ambient PATH for tick

- Bash `relay-automation/poll.sh` defaults `TICK_BIN` to the harness-local binary.
- Python `utils/py/poll.py` still defaulted to bare `tick`, which is wrong in a vendored consumer repo
  unless the caller also exports `TICK_BIN`.

## Phase 0 — Root/claim parity fixes + regression coverage

### Checklist

- [x] Share Python tick-binary resolution / ownership-proof logic instead of keeping it duplicated in
      each shim.
- [x] Port the claim-before-launch guard into `utils/py/agy-turn.py`.
- [x] Add the same ownership proof to Bash/Python `claude-turn`.
- [x] Fix Bash/Python `claude-turn` cost capture to resolve the harness tick binary separately from
      `TICK_REPO_ROOT`.
- [x] Fix Python `poll.py` to resolve the harness tick binary without requiring ambient `PATH` or
      `TICK_BIN`.
- [x] Extend the vendored marathon regression to run the full chain under `XYZ_PYTHON=1`.
- [x] Add targeted shell regressions for the Python agy guard, Claude vendored/root-split behavior,
      and Python poll fallback.

### QA checklist — Phase 0

- [x] Bash and `XYZ_PYTHON=1` vendored runs keep all claim/handoff events in the consumer repo's
      `.tick`.
- [x] No stray `.xyz/.tick` event log appears in the vendored regressions.
- [x] A driven worker with an unowned token fails before any relay/artifact mutation.
- [x] Relevant suites pass (`test/agy-turn.sh`, `test/claude-turn.sh`, `test/poll-driver.sh`,
      `test/marathon-drive.sh`), then wider validation is re-checked.
      Current wider state: `./validate.sh` initially reproduced 3 reds (`worktree-isolation.sh`,
      `relay-pkg-freshness.sh`, `relay-turn-timeout.sh`); the last two were fixed in this slice and
      re-run green, leaving the pre-existing `worktree-isolation.sh` moved-ROOT-HEAD failure.
