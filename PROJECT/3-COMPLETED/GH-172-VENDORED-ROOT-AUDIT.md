---
gh_issue: 172
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172
title: Vendored harness root-semantics audit before Python-default cutover
status: Closed — Phase 0 root/claim parity fixes landed and verified; Phase 1-4 marathon plan authored 2026-07-16, not yet fired
created: 2026-07-07
updated: 2026-07-17
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
| Recreated the missing GH-172 doc that `ROADMAP.md` already linked, then landed the first audit slice from a clean `origin/main` worktree: shared Python tick resolution/claim helpers, claim-before-launch in `utils/py/agy-turn.py` and Bash/Python `claude-turn`, vendored/root-split Claude cost capture, Python `poll.py` harness-tick fallback, and vendored regressions for both Bash and `XYZ_PYTHON=1`. Verified by `test/agy-turn.sh` 36/0, `test/claude-turn.sh` 34/0, `test/poll-driver.sh` 38/0, `test/marathon-drive.sh` 65/0, `test/relay-turn-timeout.sh` 9/0, `test/relay-pkg-freshness.sh` 3/0, plus `python3 -m py_compile` clean. Moved this doc from `1-INBOX` to `2-WORKING` and authored a 4-phase marathon plan (Phases 1-4 below) covering the remainder of the issue's Bash/Python/test/cutover checklists. | Fire the marathon (`PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/MARATHON.yaml`) once `swarm-preflight.sh --gh-issue 172` reports ready. |

## Phases (marathon 2026-07-16)

Agy-turn.py/claude-turn (Bash+Python)/poll.py/codex-turn are already audited and fixed in Phase 0
above — excluded from the phases below.

- **Phase 1 — `gh172-bash-audit`**: audit remaining Bash entry points (`marathon-drive.sh`,
  `relay-drive.sh`, `marathon-agent.sh`, `relay-turn-lib.sh`, `aider-turn.sh`, `consult.sh`,
  `relay-loop.sh`, `watchdog.sh`, `runner.sh`, `swarm-preflight.sh`) against the root contract; fix
  any real gap found. Findings written to `GH-172-BASH-AUDIT-FINDINGS.md` in the marathon folder.
- **Phase 2 — `gh172-python-audit`** (depends on Phase 1): audit remaining Python paths
  (`marathon_drive.py`, `relay_drive.py`, `rtl.py`, `aider-turn.py`, `consult.py`) for parity with the
  hardened Bash behavior. Findings written to `GH-172-PYTHON-AUDIT-FINDINGS.md` in the marathon folder.
- **Phase 3 — `gh172-vendored-e2e`** (depends on Phase 2): extend vendored `.xyz` E2E regression
  coverage for the real `marathon-drive → relay-drive → shim` chain, both builder and reviewer legs,
  in both Bash and `XYZ_PYTHON=1` modes.
- **Phase 4 — `gh172-cutover-doc`** (depends on Phase 3): write the final root contract into durable
  docs, list any remaining parity gap, and state explicitly whether it's safe to cut a stable Bash
  branch and/or switch `main` to Python-default mode. Output: `GH-172-CUTOVER-RECOMMENDATION.md`.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md" },
    { "type": "path_absent", "path": "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md" },
    { "type": "path_absent", "path": "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md" }
  ],
  "artifacts": [
    "relay-automation/marathon-drive.sh",
    "relay-automation/relay-drive.sh",
    "relay-automation/marathon-agent.sh",
    "relay-automation/relay-turn-lib.sh",
    "relay-automation/aider-turn.sh",
    "relay-automation/consult.sh",
    "relay-automation/relay-loop.sh",
    "relay-automation/watchdog.sh",
    "relay-automation/runner.sh",
    "utils/swarm-preflight.sh",
    "utils/py/marathon_drive.py",
    "utils/py/relay_drive.py",
    "utils/py/rtl.py",
    "utils/py/aider-turn.py",
    "utils/py/consult.py",
    "test/marathon-drive.sh",
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md",
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md",
    "PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md",
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md"
  ],
  "artifacts_new": [
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md",
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md",
    "PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md"
  ],
  "remediation": { "source": "self#phases", "criteria": "Phases 1-4 in this doc's 'Phases (marathon 2026-07-16)' section" },
  "lanes": { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh", "relay-automation/marathon-drive.sh", "utils/py/rtl.py", "utils/py/marathon_drive.py" ] }
}
```

## Root contract

In a vendored consumer repo, three roots are distinct and must stay distinct:

1. **Harness install root**: where `.xyz/relay-automation`, `.xyz/bin/tick`, and `.xyz/utils/py` live.
2. **Coordination root**: where `.tick/` lives; this is `TICK_REPO_ROOT`.
3. **Target/work root**: where the editable repo and any throwaway worktrees live.

The audit rule is simple: **never re-derive one of these from another when the orchestrator already
handed the right one in.** In particular, the tick binary path and the tick repo root are separate.

## Root contract (final)

This is the durable GH-172 contract for vendored relay and marathon runs:

1. **Harness install root** is the only place that owns harness-shipped executables and helpers such
   as `.xyz/bin/tick`, `.xyz/relay-automation/*`, and `.xyz/utils/py/*`.
2. **Coordination root** is the only place that owns `.tick/`, and every token, ping, cost, and
   handoff event must resolve through `TICK_REPO_ROOT` to that shared event log.
3. **Target/work root** is the editable repo surface, including any worktree-isolated checkout that a
   driven turn mutates.

Operational rules:

- Resolve the tick binary independently from the coordination root. A correct `TICK_REPO_ROOT` does
  not imply `bin/tick` lives there, and a correct harness tick path does not imply `.tick/` lives
  beside it.
- When the orchestrator already passed `TICK_BIN`, `TICK_REPO_ROOT`, or the target/work root, do not
  silently substitute a derived value from another root.
- Worktree isolation may swap the editable checkout under the target/work root, but it does not move
  the shared coordination log out of `TICK_REPO_ROOT`.
- A vendored consumer repo is correct only when all relay/marathon token and cost events land in the
  consumer repo's pinned `.tick`, never in a stray `.xyz/.tick` or a consulted target repo.

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
