---
title: Recon — Agy model-validation probe
status: Reference
created: 2026-09-17
updated: 2026-09-17
owner: noel
goal: Trace the existing probe before narrowing the repair.
roadmap_exempt: true
quad_exempt: true
---

# Recon Map — Agy model-validation probe

Commit: 74daa7d251ac4070c75575d139edc41657cc06ef. Mode: rg/read;
one local lane covering entry/state/contracts/failure. No graph installed.

## Subject and current radius

Local developer CLI preflight execution location, not a new authority/source of truth.
Only Python Agy model validation changes; normal turns and shared RTL stay intact.

## Seams and state

| Seam | Location | Contract |
|---|---|---|
| Runtime dispatch | relay-automation/agy-turn.sh:9–24 | Python default; frozen fallback untouched |
| Preflight sequence | utils/py/agy-turn.py:350–360,404 | auth then model validation precede RTL and snapshot |
| Existing safe pattern | utils/py/agy-turn.py:133–143,222–234 | temporary auth CWD, cleanup on returns |
| Unsafe probe | utils/py/agy-turn.py:250–318 | AGY_MODEL unset bypasses; otherwise models inherits CWD |
| Model contract | utils/py/agy-turn.py:299–317,397–398 | ID/display/full-line accepted, explicit model forwarded |
| Regression consumer | test/agy-turn.sh:157–182 | unavailable blocks turn; listed proceeds and forwards model |
| Gate registration | validate.sh:94 | Agy shim suite registered; independent new probe suite will register adjacent |

Writes: models stdout/stderr goes to a temporary log; relative child writes currently
go to caller CWD. Successful parser and exception branches remove logs. No ledger,
queue or Git state writer is added. Temp directory ownership will cover all return paths.
Timeout uses AGY_AUTH_TIMEOUT_S; nonzero, timeout and launch errors return False.
main exits5 on False before token/turn mutation. Existing model-selection semantics remain.

## Observed and falsified

Controlled models stub plus actual imported validator: True, caller marker exists,
porcelain status empty → untracked marker. This rules out RTL snapshot/worktree cleanup
as protection for this call. Unset-model control will prove no binary invocation;
removing only subprocess cwd will be the load-bearing ablation.

## Failure and rollback

Stdlib temporary folder creation must fail closed before invocation. Reuse existing
probe ownership, no process-group/OS-sandbox redesign. Focused revert restores old
behavior, so stop on any caller-preservation/model-routing regression before landing.

## Unknowns

No observed write by the real CLI. Absolute writes and detached child lifetimes are
not solved by cwd; existing timeout-family GH-648 remains separate. Existing base
path/PDDA failures observed during GH-661 may block full publication; run the real
gate and report, do not bundle unrelated pending repairs or bypass it silently.
