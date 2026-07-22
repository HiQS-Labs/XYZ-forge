---
title: rtl_worktree_end doesn't exempt relay-system/ (its own transcript dir) — false containment violation discards a fully in-scope turn
status: "promoted to 2-WORKING 2026-07-21 via /10days sweep with an auto-drafted contract"
created: 2026-07-21
updated: 2026-07-21
owner: noelsaw1
gh_issue: 266
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/266
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: false
reported_from: hyper-pandas-python-stack
harness_commit: 93f0934
non_goals:
  - Redesigning worktree isolation itself (the isolation mechanism is sound; only its containment
    exemption list is incomplete).
  - Implementing the XYZ_ARCHIVE_ROOT redirect (#30) as a substitute fix — that's a complementary,
    separate feature, not a fix for this symmetry gap.
related:
  - "#30 — Optional centralized transcript archive (redirect relay-system/ out of foreign repos)"
  - "#160 — codex CLI intermittently reports off-lane/unwritable target files inside isolated worktrees (a different false-positive mechanism, closed)"
  - "utils/py/rtl.py worktree_end() shells out to the same bash rtl_worktree_end — same bug, not a separate parity issue"
goal: >
  A Codex (or any) build turn driven with RELAY_WORKTREE_ISOLATION=1 (the default) does NOT get
  discarded merely because the harness's own relay-system/ transcript directory appears as an
  untracked path in the isolated worktree's git status. "Fixed" = rtl_worktree_end's off-lane loop
  intrinsically exempts relay-system/ (or rtl_transcript_root(ROOT)'s resolved path) the same way
  it already exempts .tick/, without requiring CONTAINMENT_IGNORE=relay-system on every call.
---

# GH-266 — rtl_worktree_end doesn't exempt relay-system/

## Status
| What was just completed | What's next |
|---|---|
| Fixed 2026-07-21: `rtl_worktree_end`'s off-lane loop now intrinsically exempts the transcript-log directory (resolved via `rtl_transcript_root`, matching both the collapsed bare-dir form and any path under it — same pattern already used for `.relay-artifacts`), mirroring `rtl_check()`'s `$RTL_LOG_REL` exemption. Two regression tests added to `test/worktree-isolation.sh` (cases 10-11): one proves a worktree-isolated turn writing only its own transcript log is no longer flagged off-lane (confirmed to fail without the fix via a stash/pop check), the other proves `CONTAINMENT_IGNORE=relay-system` still works as a manual override. `bash validate.sh` green (117/117); `utils/pdda/pdda.sh run` clean. | Close #266 once merged. |

## Symptom
A fully in-scope Codex build turn (every edit within the phase's artifact allowlist) is discarded
as a containment violation because the harness's own transcript-log directory (`relay-system/`) is
untracked in the isolated worktree and isn't exempted from the off-lane check.

## Environment
- **Observed from:** `hyper-pandas-python-stack`
- **Harness commit:** `93f0934`
- **Worker/CLI:** codex v0.144.6, driven via `marathon.sh --builder codex`, `RELAY_WORKTREE_ISOLATION` default (on)
- **Runtime:** Python (default path, `XYZ_PYTHON` unset) — `codex-turn.sh`/`marathon-drive.sh`
  reroute to `utils/py/codex-turn.py` per GH-112 (`${XYZ_PYTHON-1}` defaults to `1`). Note:
  `utils/py/rtl.py`'s `worktree_end()` does **not** reimplement containment in Python — it shells
  out directly to the same bash `rtl_worktree_end` in `relay-automation/relay-turn-lib.sh`, so this
  bug is shared/identical under both runtimes; fixing `relay-turn-lib.sh` fixes both entry points
  at once. (Corrected 2026-07-21 per ROUTER.md's new runtime-label rule — originally mislabeled
  `runtime:bash` before checking whether `XYZ_PYTHON` was actually set during reproduction; it
  wasn't, so the default — now Python — path is what ran.)
- **Sandbox:** Codex sandbox bypassed (`--dangerously-bypass-approvals-and-sandbox`); Claude Code Bash sandbox off

## Reproduction
1. Fire a phase via `marathon.sh --builder codex` with default worktree isolation on.
2. `codex-turn.sh` writes its own trace log under `<ROOT>/relay-system/logs/<date>/codex-turn-<task>-<pid>.log` **inside the isolated worktree**.
3. `relay-system/` is genuinely untracked/new in that worktree checkout, so `git status --porcelain` collapses it to one line `?? relay-system/`.
4. `rtl_worktree_end`'s off-lane loop (`relay-turn-lib.sh` ~495-537, invoked here via
   `utils/py/rtl.py`'s `worktree_end()` shell-out) checks this path against
   `rtl_in_allow` (not in the phase's artifact allowlist — it shouldn't need to be) and
   `rtl_is_containment_ignored` (built-in list is only `.codebase-memory`, `.aider*`,
   `node_modules/.cache` — `relay-system` isn't there).
5. Neither matches → `RTL_WT_OFFLANE=1` → the **entire turn** is discarded/reverted, even though
   every actual deliverable edit was in-scope.

**Expected:** the harness's own transcript-log directory is exempted from its own containment
check, the same way `.tick/` already is (`relay-turn-lib.sh:520`,
`case "$p" in .tick/*|.tick) continue ;; esac`).
**Observed:** `codex-turn: OFF-ALLOWLIST change: relay-system/ — reverting` →
`codex-turn: off-lane edits reverted; failing the turn` →
`marathon-drive: relay escalated: containment violation (exit 6)`.
**Frequency:** every time, under default (non-archived) `relay-system/` placement.

```text
codex-turn: OFF-ALLOWLIST change: relay-system/ — reverting
codex-turn: pre-revert copy of relay-system/ saved under .tick/orphan-backups/20260721T151848Z-75850
codex-turn: off-lane edits reverted; failing the turn
marathon-drive: relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)
```

## Root cause
`rtl_worktree_end` (the worktree-isolation containment path) has no exemption for `relay-system/`
or `$RTL_LOG_REL`. Its non-worktree sibling, `rtl_check()`, *does* have this exemption
(`relay-turn-lib.sh:683`: `if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f ...; return 0; fi`).
The two containment paths have drifted out of symmetry.

## Impact
Every `RELAY_WORKTREE_ISOLATION=1` (default) run risks a false-positive discard, wasting a full
build turn for reasons unrelated to the agent's actual work. **Workaround:**
`CONTAINMENT_IGNORE=relay-system` (the documented opt-in for exactly this class of tool-cache side
effect) resolves it — but this shouldn't be required on every invocation.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Reproduce it in the intake repo directly (not just via a consuming repo) — reproduced via direct `rtl_worktree_begin`/`rtl_worktree_end` calls, confirmed failing without the fix (stash/pop check)
- [x] Confirm `rtl_transcript_root(ROOT)` is the right anchor to exempt (vs. a hardcoded `relay-system/`) — used `basename "$(rtl_transcript_root "$RTL_ROOT")"`, skipped entirely when `XYZ_ARCHIVE_ROOT` redirects it outside RTL_ROOT
- [x] Add an intrinsic exemption in `rtl_worktree_end`'s off-lane loop mirroring the `.tick/` case
- [x] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [x] The repro is confirmed from the report, not assumed
- [x] A regression test covers a worktree-isolated turn that writes only its own transcript log
- [x] `rtl_check()` and `rtl_worktree_end()` stay in symmetry after the fix (same exemption set)
- [x] Verify `CONTAINMENT_IGNORE=relay-system` still works as a manual override (not removed)
- [x] Confirm a single fix in `relay-turn-lib.sh` resolves it under both entry points (bash
      `codex-turn.sh` direct, and Python `utils/py/codex-turn.py` via `rtl.py`'s shell-out) —
      no separate Python-side patch should be needed given the shared-core delegation

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "GH-266" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh", "test/worktree-isolation.sh" ],
  "remediation": {
    "source": "issue#266",
    "criteria": "rtl_worktree_end's off-lane loop intrinsically exempts relay-system/ (or rtl_transcript_root(ROOT)'s resolved path) the same way it already exempts .tick/, without requiring CONTAINMENT_IGNORE=relay-system. rtl_check() and rtl_worktree_end() stay in symmetry. CONTAINMENT_IGNORE=relay-system still works as a manual override. A regression test covers a worktree-isolated turn that writes only its own transcript log. bash validate.sh green."
  },
  "lanes": { "agy_safe": [ "relay-automation/relay-turn-lib.sh", "test/worktree-isolation.sh" ], "orchestrator_only": [] }
}
```
