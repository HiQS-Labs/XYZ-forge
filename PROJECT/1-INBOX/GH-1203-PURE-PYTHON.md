---
gh_issue: 1203
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1203
title: "Audit B: evaluate and stage a pure-Python production runtime"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: plan
effort: 5
complexity: 5
risk: 3
phases: 5
rating: "pri/sev/appeal/effort 60/60/85/20 · calc 225"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1201
  - https://github.com/HiQS-Labs/XYZ-forge/issues/308
goal: Determine and execute a compatibility-preserving path to Python-only production coordination, containment, automation, ledger, and tick runtime.
---

# GH-1203 — Pure-Python production runtime

## Quad Concepts

- Python-default still invokes Bash and Node → inventory and migrate production dependencies in compatibility stages.
- Kernel and containment rewrites are Costly → stable contracts, negative controls, and rollback at every stage.

## Finding

Pure Python is feasible but not a flag flip. Python-default Tier-A entry points retain Bash fallbacks; `rtl.py` still invokes `relay-turn-lib.sh` for containment; production orchestration includes many shell files; and `tick` is Node.js. Removing frozen twins alone would not meet the goal.

External Git, GitHub CLI, and agent CLIs remain subprocess dependencies. Historical shell tests may migrate separately.

## Phases

1. Publish a production dependency inventory separating Bash-free from strict Python-only milestones, including callers, vendoring, contracts, and suites.
2. Port remaining containment bridge operations behind `rtl.py`, preserving allowlists, worktrees, commit guards, timeouts, copy-back, and exit codes.
3. Retire Bash production fallbacks only after Python no longer calls production Bash; update frozen-twin governance, vendoring, and docs together.
4. Port `tick` behind a compatible facade, proving event replay, fold/epoch behavior, claims, path overlap, CLI output, and exit codes against existing fixtures.
5. Remove Node from production requirements only after parity evidence; retain any independent Node test-tooling decision separately.

## Acceptance

- Supported production paths execute no Bash or Node.
- Existing logs, machine contracts, CLI behavior, and exit codes remain compatible.
- Containment, concurrency, stale-writer, timeout, and wrong-root negative controls still fire correctly.
- Source and vendored installs pass existing coverage, with rollback possible without rewriting history.

## Non-goals and risk

No big-bang kernel/containment rewrite and no removal of external agent/Git subprocesses. This is Costly; strict Python-only remains an explicit decision after the inventory and containment stages quantify cost.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
