---
gh_issue: 203
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/203
title: "Swarm/tick sessions leave a stale git index.lock on unclean exit, blocking later git ops"
status: built 2026-07-16 (codex + agy, 2 turns, Approved cleanly)
created: 2026-07-16
updated: 2026-07-16
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not implementing "reap on scope teardown" (tick's release/done/reap/circuitBreak paths
    auto-clearing a stale lock) — that touches tick's coordination internals (src/project.js-adjacent),
    which this repo's own guidance treats as at-least-Costly by default; a live-mutating auto-clear of
    a git-native lock (not a tick lock) is also a meaningfully different trust boundary than anything
    tick's verbs touch today.
  - Not implementing "wrap git writes" (a trap in every agent git-write helper) — touches multiple
    turn-taker shims for a benefit a preflight warning already captures at lower risk.
  - Not auto-removing a detected stale lock — warn and point at the documented manual clear; removing
    a lock file automatically is exactly the kind of "destructive action without explicit
    authorization" this repo's own conventions avoid by default.
related:
  - utils/swarm-preflight.sh
  - test/swarm-preflight.sh
goal: >
  Add a non-destructive preflight check to swarm-preflight.sh that detects a stale .git/index.lock
  (present, no live git process holding it) before a marathon lane is deemed ready, and document the
  safe manual clear — the lowest-risk item on the issue's own "pick one/more" menu.
---

## Status

| What was just completed | What's next |
|---|---|
| Built via the marathon (phase `gh203`, codex builder + agy reviewer, 2 turns, clean Approve — no false positives, unlike gh213/gh209). `utils/swarm-preflight.sh` detects a stale lock via `lsof -t -- <lock-path>` (advisory-only; stays silent if `lsof` is unavailable rather than guessing from process names), threads `stale_index_lock`/`stale_index_lock_path`/`stale_index_lock_warning` through both the JSON and text reports, and never touches `VERDICT`/`CAND_STATE`. `test/swarm-preflight.sh` gained 7 new cases (T37a–c, T38, T39a–c: warn/JSON/clean-repo coverage) — 94/94 green. Doc note added to `relay-automation/README.md`. Full `validate.sh` green except the pre-existing tracked #208; rebuilt `relay-pkg.tar.gz` (README.md is part of the vendored bundle). | Done. All 3 lanes (gh213, gh209, gh203) complete. |

## Problem

A consuming repo was left with a stale `.git/index.lock` (0 bytes, no live git process holding it)
after an unclean swarm/marathon session exit, blocking `git pull` and any other index-writing git
operation until removed by hand. Nothing in the harness surfaces *why*, or that the manual removal is
safe.

## Decision — scope narrowing

The issue offers four fix options; three touch tick's coordination internals or agent git-write
helpers (real behavior changes to trust-sensitive paths). The remaining one — a preflight check that
warns before a run starts — is non-destructive, low-risk, and directly actionable by
`swarm-preflight.sh`, which already runs a battery of readiness checks (freshness, gate, artifacts)
before declaring a lane ready. This lane builds that check plus the doc/runbook note; the other three
options remain open for a future, more careful pass.

## Acceptance criteria

- [x] `swarm-preflight.sh` gains a check (alongside its existing Phase 3 freshness checks) that
      detects a stale `.git/index.lock` in `$TARGET_ROOT`: the lock file exists AND no live process
      currently holds it (best-effort: e.g. no running `git` process has it open — exact detection
      mechanism is the builder's call, but it must not produce a false positive against a git
      operation that is genuinely in flight).
- [x] On detection, the check surfaces a clear, visible warning in both the text and JSON report
      formats (matching the existing report's structure — e.g. alongside `freshness`), naming the
      lock path and the safe manual remediation (`rm .git/index.lock`, after confirming no live git
      process via `pgrep -fl git`). It does NOT delete the lock itself.
- [x] This check does not change swarm-preflight's exit code / verdict on its own (fail-open,
      advisory) — a stale lock is a warning, not a hard BLOCKED state, since the lock may be
      perfectly legitimate (a real in-progress git operation, briefly).
- [x] A short troubleshooting note is added documenting the safe manual clear (where an operator would
      look after seeing the warning — e.g. `relay-automation/README.md` or this repo's existing
      troubleshooting section).
- [x] `test/swarm-preflight.sh` gains regression cases: (a) a fixture repo with a stale, unheld
      `.git/index.lock` present triggers the warning; (b) an ordinary clean repo does not; (c) the
      check never turns a would-be-ready packet into a BLOCKED one on its own.
- [x] `bash test/swarm-preflight.sh` and full `validate.sh` green.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh",
  "fix_probes": [ { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "index.lock" } ],
  "artifacts": [ "utils/swarm-preflight.sh", "test/swarm-preflight.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Acceptance criteria checklist in this doc" },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```

## Scope lock
Edit only: `utils/swarm-preflight.sh`, `test/swarm-preflight.sh`, and (only if needed for the doc note)
`relay-automation/README.md`. Do NOT touch `bin/tick`, `src/project.js`, or any turn-taker shim.
