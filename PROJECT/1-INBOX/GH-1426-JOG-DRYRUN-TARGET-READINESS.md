---
title: jog run --dry-run ignores --target-root readiness; preflight park misreported as landing halt
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
owner: Noel Saw
gh_issue: 1426
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1426
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 046b41538
non_goals:
  - Bootstrapping .venv in target clones (operator clone-setup responsibility)
  - Changing swarm_preflight readiness rules
goal: >
  `jog run --dry-run --target-root <clone>` surfaces each pending item's preflight verdict and
  readiness reason without mutating anything, and a live preflight park prints the real reason
  instead of "advancing halted at landing boundary".
---

# GH-1426 — jog dry-run ignores target readiness; preflight park misreported

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `046b41538`
- **Worker/CLI:** jog → marathon executor, builder `claude-builder`, reviewer `claude-reviewer`
- **Runtime:** Python (default)
- **Sandbox:** off

## Symptom

`jog run --dry-run --target-root <clone>` reported "would process 4 pending item(s)". The live `jog run` with the same flags then parked the first item at preflight (`exit 5 NOT-READY: gate program not found under target_root …: .venv/bin/pytest`). The disposable clone had no `.venv`. Dry-run never evaluates target readiness, so the gap only showed up after the live run took the lease and lock. The live run's console output also misreported what happened.

## Observed

| Claim | Command | Observed |
|---|---|---|
| Dry-run passes with a clone that is not ready | `releases_app.py jog run --dry-run --target-root <clone> --builder claude-builder --reviewer claude-reviewer` | `would process 4 pending item(s)`, exit 0 |
| Live run refuses at preflight | same command without `--dry-run` | row parked: `preflight-refused (exit 5): No packet written — candidate is not preflight-ready (NOT-READY).` |
| Cause is visible only by re-running preflight by hand | `swarm-preflight.sh --gh-issue 993 --dry-run` in the clone | `readiness: ready=0 — next: gate program not found under target_root <clone>: .venv/bin/pytest`, `dirty=0`, ref matches |
| Dry-run path skips the target | `utils/py/jog_run.py:2221-2238` | lists pending rows only; no preflight or target probe |
| Misleading console text | `utils/py/jog_run.py:2394` | any `parked` action prints `jog: advancing halted at landing boundary.` (including preflight-refused) |
| Misleading console text | `utils/py/jog_run.py:595` | prints `jog: marathon execution <id> …` before preflight runs; no Marathon execution happened |
| Cause swallowed | `utils/py/jog_run.py:597-600` | preflight runs with `capture_output=True`; its `readiness … next:` line is not echoed |

Live run console output, complete:

```text
jog: processing GH-993 (attempt 1) at position 1
jog: preflight script resolved outside this root (<clone>/.xyz/utils/py/swarm_preflight.py); SWARM_PREFLIGHT_ROOT pins evaluation to <clone>
jog: marathon execution gh993-exec1 for GH-993 (packet: <primary>/.tick/jog/<gid>/gh993-exec1/preflight)
jog: advancing halted at landing boundary.
```

Frequency: every time (deterministic: a target clone without the gate program).

## Root cause

Root cause: `jog run --dry-run` is hermetic toward the ledger, and it also does not inspect `--target-root`, so target readiness is not checked until a live run has already taken the lease and lock. Fix site: the dry-run branch of `jog_run_main` plus the park-message/echo path. Why not downstream: preflight already detects the condition correctly, so the defect is that Jog neither surfaces it early nor reports it accurately.

## Acceptance

- [ ] `jog run --dry-run --target-root <clone>` runs read-only `swarm_preflight --dry-run` per pending item against the clone and prints each item's verdict and `readiness next:` reason. Red control: with a clone lacking `.venv/bin/pytest`, dry-run currently prints `would process N`; fixed, it names the missing gate program per item. Still zero ledger writes, zero locks.
- [ ] Without `--target-root`, dry-run keeps its current queue-only output (no regression for read-only listing).
- [ ] When a live item parks at preflight, the console prints the preflight verdict and its `next:` reason, not `advancing halted at landing boundary.` Red control: the console output above.
- [ ] The `marathon execution <id>` line is printed only after preflight returns ready, or is reworded to say preflight is starting.
- [ ] Existing Jog suites (gh280 / Jog adapter) still pass; evidence recorded under `TESTS-RESULTS/` (no new suites, GH-831).

## Preflight Contract

```json
{
  "target": "utils/py/jog_run.py",
  "gate": "existing Jog adapter + gh280 suites",
  "fix_probes": [
    {"type": "grep", "path": "utils/py/jog_run.py", "pattern": "advancing halted at landing boundary"}
  ],
  "artifacts": ["utils/py/jog_run.py"]
}
```

## PRS proposal

pri 55: an unattended scheduled Jog fire wasted its slot on a setup gap a dry-run should have caught.
sev 45: recoverable (row parks, no data loss), but the console misreports the cause, so the operator has to debug by hand.
appeal 50: makes dry-run trustworthy as the pre-fire check operators already rely on.
effort 70: small; reuses the existing preflight `--dry-run` and its output, in one file.

## Non-goals

- Bootstrapping `.venv` in target clones (operator/clone-setup responsibility; could be a separate follow-up).
- Changing preflight's readiness rules.

## Phase 0 — Diagnose & scope

### Checklist
- [ ] Reproduce in the intake repo with a target clone lacking its gate program
- [ ] Confirm write-set: `utils/py/jog_run.py` (dry-run branch ~2221, preflight call ~595-600, park message ~2394)
- [ ] Reuse `swarm_preflight --dry-run`; no new probe path (`/ponytail`)
- [ ] Set real ratings; clear `ratings_provisional`

### QA checklist — Phase 0
- [ ] Repro confirmed from the report, not assumed
- [ ] Existing suite or recorded manual check covers the failure path before the fix lands (GH-831)
- [ ] Fix composes with the existing harness rather than adding a parallel path
