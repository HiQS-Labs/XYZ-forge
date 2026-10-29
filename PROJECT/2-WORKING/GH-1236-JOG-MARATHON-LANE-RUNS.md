---
gh_issue: 1236
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1236
title: "pre-push reuses a passing full-gate receipt for the exact pushed commit"
status: Active
created: 2026-10-27
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
goal: "A Jog/Marathon lane push whose exact commit already passed the full validate.sh gate does not run the full gate a second time; every other push gates exactly as today."
non_goals:
  - Reusing receipts across different commits, trees, or ranges ("same diff" heuristics).
  - Changing the docs or tier-2 routes, validate.sh, or what counts as promotion evidence.
related:
  - "Marathon umbrella #1250 (lane L3)"
  - "GH-1175 Phase 0: TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-jog-retry-build.log (pre-advance 787 s, then pre-push 634 s on 80a11644)"
---

# GH-1236: pre-push reuses a passing full-gate receipt for the exact pushed commit

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L3) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (GH-1175 Phase 0, gh416-exec2, 2026-10-26)

- Marathon's pre-advance gate, `bash validate.sh --auto development` (tier 3, 409/409, 787 s), ran on `80a11644`.
- The lane PR push (`marathon-closeout.sh`, `git push`) then ran the full gate again in the pre-push hook (634 s).
- The pushed head was that same `80a11644`: PR #1225's first push. Jog's receipt commit `b8733346` came later.
- 23m41s of the 28m07s run were gates; agent turns took 2m54s.

## Current state (93f41cb8)

- `validate.sh:1589-1594` writes `.xyz/receipts/<sha>.json` with `gate: "validate.sh"`, `mode: "parallel"` and `exit_code: 0`, but **only** after a passing tier-3 run with no `--subsystem` on a clean tree. That is exactly the full gate.
- `utils/py/marathon_drive.py:2820-2830` then writes its own receipt to the **same path** for the approved candidate (`gate: <pre-advance cmd>`, `mode: "marathon"`), overwriting validate.sh's.
- `utils/py/gate_receipt.py` `check` (`:59-89`) accepts any `exit_code: 0` receipt for the SHA, whatever wrote it. `marathon-closeout.sh:149-160` already uses it before pushing.
- `githooks/pre-push` collects the pushed local SHAs (`:64-76`, `_real_ref_pairs`). Its full-gate arm (`:288-305`) runs `validate.sh` unconditionally.

## Plan (one phase)

1. `utils/py/gate_receipt.py`: add an optional repeatable `--gate NAME` to `check`. When given, a receipt counts only if its `gate` is one of the names. Default behaviour is unchanged, so closeout's check is unaffected.
2. `utils/py/marathon_drive.py` (`:2820-2830`): write the marathon receipt only when no receipt file exists for that SHA. A validate.sh full-gate receipt is never overwritten.
3. `githooks/pre-push`, full-gate arm only: before running `validate.sh`, check every entry in `_real_ref_pairs` with `gate_receipt.py check --repo "$REPO" --sha <local sha> --gate validate.sh`.
   - If **all** pass, print `pre-push: reusing the passing full-gate receipt for <sha8> (validate.sh) — the full gate already ran on this exact commit.` and exit 0.
   - Any miss, error or missing tool falls through to the full gate as today. The docs and tier-2 arms, and the delete-only and skip paths, are untouched.

Write-set: `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py`. Full route.

## Acceptance

- [ ] pre-push skips the full gate only when a passing full-gate receipt written by `validate.sh` (tier 3, unfiltered, clean tree) exists for the exact local SHA being pushed, and it says so in its output.
- [ ] Marathon's pre-advance receipt no longer overwrites a `validate.sh` full-gate receipt for the same SHA.
- [ ] Every other case (no receipt, a marathon-only receipt, a different SHA, a docs or tier-2 route, a deleted ref) gates exactly as today.
- [ ] A manual smoke receipt under `TESTS-RESULTS/` shows the fix and a base red control; no new tests (GH-831).

## Verification

- **Existing suites:** `test/gh544-pre-push-gate.sh`, `test/gh591-prepush-commit-boundary.sh`, `test/gh509-gate-evidence.sh`, `test/synthetic/gh124-closeout-suite.sh` (gate_receipt + closeout), `test/gh290-ate-variation-grid.sh`, `test/gh280-jog-marathon-adapter.sh`, and the routed full gate, in a disposable full clone.
- **Manual smoke** (`TESTS-RESULTS/<date>+GH-1236/`): in a disposable fixture clone, feed the hook a stdin line for a SHA.
  - **Fix:** with a validate.sh receipt present, the hook prints the reuse line and does not start validate.sh (shown with a stub `validate.sh` that records invocation).
  - **Base red control:** at base, the hook runs the gate.
  - **Adjacent:** a marathon-only receipt, a receipt for another SHA, and no receipt each still invoke the gate.
  - The marathon-receipt no-overwrite is shown directly.

Rollback: revert one commit. Without the hook change every push gates fully, as today.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {"type": "grep_absent", "path": "githooks/pre-push", "pattern": "reusing the passing full-gate receipt"}
  ],
  "artifacts": ["githooks/pre-push", "utils/py/gate_receipt.py", "utils/py/marathon_drive.py"],
  "remediation": {"source": "issue#1236", "criteria": "pre-push full-gate arm reuses a validate.sh receipt for the exact pushed SHA; gate_receipt check --gate filter; marathon receipt never overwrites a validate.sh receipt."},
  "lanes": {"agy_safe": ["githooks/pre-push", "utils/py/gate_receipt.py", "utils/py/marathon_drive.py"], "orchestrator_only": []}
}
```
