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
effort: 3
phases: 1
goal: "A Jog/Marathon lane push whose exact commit already passed the full validate.sh gate does not run the full gate a second time; every other push gates exactly as today."
non_goals:
  - Reusing receipts across different commits, trees, or ranges ("same diff" heuristics).
  - Changing the docs or tier-2 routes, or what counts as promotion evidence; validate.sh changes only in which runs write an eligible receipt.
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
- `validate.sh:1589-1594` writes `.xyz/receipts/<sha>.json` (`gate: "validate.sh"`, `mode: "parallel"`, `exit_code: 0`) after a passing tier-3 run with no `--subsystem` on a clean tree. **But** a `--skip` run (`:1182-1204`) removes suites into `SKIPPED_SUITES` without changing tier or subsystem. It announces itself as "NOT promotion evidence", yet it still writes the same receipt (plan QA r1 blocker). `passed == total` cannot detect it, because skipped suites are already gone from the run list.
- `utils/py/marathon_drive.py:2820-2830` then writes its own receipt to the **same path** for the approved candidate (`gate: <pre-advance cmd>`, `mode: "marathon"`), overwriting validate.sh's. Its `gate` string is an arbitrary command, which may itself be "validate.sh".
- `utils/py/gate_receipt.py` `check` (`:59-89`) accepts any `exit_code: 0` receipt for the SHA, and falls back to legacy `.gate-evidence/<sha>.txt` (`:77-84`). `marathon-closeout.sh:149-160` uses it before pushing. A corrupt, failed or wrong-SHA receipt fails that check.
- `githooks/pre-push` collects the pushed local SHAs (`:64-76`, `_real_ref_pairs`). Empty stdin deliberately gates (`:58-80`). Its full-gate arm (`:288-305`) runs `validate.sh` unconditionally.

## Plan (one phase)
Producer and consumer ship together. Old receipts fail closed.

1. **`validate.sh` (producer, `:1589-1594`):** write the receipt only when `TIER` is 3, `SUBSYSTEM` is empty, the tree is clean (all as today), **and** `SKIPPED_SUITES` is empty and `XYZ_ENV_FAULTS` is empty. Add `--scope full` to the write.
2. **`utils/py/gate_receipt.py`:**
   - `write` gains an optional `--scope`, recorded as `scope`.
   - `check` gains `--require-full-gate`. A receipt then counts only when `exit_code == 0`, `sha` matches, `gate == "validate.sh"`, `mode != "marathon"` and `scope == "full"`.
   - The legacy `.gate-evidence` fallback never satisfies `--require-full-gate`.
   - Expose the same predicate as a function (`is_full_gate_receipt`) for step 3.
   - Without the flag, `check` behaves exactly as today, so closeout is unaffected.
3. **`utils/py/marathon_drive.py` (`:2820-2830`):** before writing, load any existing receipt for that SHA. If it satisfies `is_full_gate_receipt`, keep it. Otherwise (absent, corrupt, failed, wrong-SHA, or weaker), write the marathon receipt as today, which repairs the invalid file closeout would reject.
4. **`githooks/pre-push`, full-gate arm only, after the docs and tier-2 routes have declined:**
   - Reuse only when `_real_ref_pairs` holds **at least one** non-delete entry and **every** local SHA passes `gate_receipt.py check --repo "$REPO" --sha <sha> --require-full-gate`.
   - Then print `pre-push: reusing the passing full-gate receipt for <sha8> (validate.sh, scope full) — the full gate already ran on this exact commit.` and exit 0.
   - Any miss, empty input, missing tool, malformed receipt or error falls through to the full gate as today.

Write-set:
- `validate.sh`, `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py`;
- the lane's evidence bundle, `TESTS-RESULTS/2026-10-29+GH-1236/smoke.md` and `provenance.jsonl`.

This doc's Status row is updated by the orchestrator, not the lane.

Full route.

## Acceptance

- [ ] pre-push skips the full gate only when a passing full-gate receipt written by `validate.sh` (tier 3, unfiltered, clean tree) exists for the exact local SHA being pushed, and it says so in its output.
- [ ] Marathon's pre-advance receipt no longer overwrites a `validate.sh` full-gate receipt for the same SHA.
- [ ] Every other case (no receipt, a marathon-only receipt, a different SHA, a docs or tier-2 route, a deleted ref) gates exactly as today.
- [ ] A manual smoke receipt under `TESTS-RESULTS/` shows the fix and a base red control; no new tests (GH-831).

## Verification
- **Existing suites:** `test/gh544-pre-push-gate.sh`, `test/gh591-prepush-commit-boundary.sh`, `test/gh509-gate-evidence.sh`, `test/synthetic/gh124-closeout-suite.sh` (gate_receipt and closeout), `test/gh290-ate-variation-grid.sh` and `test/gh280-jog-marathon-adapter.sh`, plus the routed full gate, in a disposable full clone.
- **Manual smoke** (`TESTS-RESULTS/2026-10-29+GH-1236/`), in a disposable fixture clone with a stub `validate.sh` that records invocation, feeding the hook stdin lines:
  - **Fix:** an eligible receipt (`scope: full`) for the exact SHA prints the reuse line and does not invoke the gate. **Base red control:** at base, the gate runs.
  - **Adjacent, all still invoking the gate:**
    - a receipt without `scope` (old producer);
    - a `--skip` producer run (no receipt written);
    - a `mode: marathon` receipt whose gate is "validate.sh";
    - a receipt for another SHA;
    - a second pushed ref without a receipt;
    - empty stdin;
    - a legacy `.gate-evidence` file.
  - **Marathon writer:** a valid eligible receipt is preserved; a corrupt, failed or wrong-SHA pre-existing file is replaced, and closeout's plain `check` then passes.

Rollback: revert one commit. Without the hook change every push gates fully, as today.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "githooks/pre-push",
      "pattern": "reusing the passing full-gate receipt"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1236/smoke.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl"
    }
  ],
  "artifacts": [
    "validate.sh",
    "githooks/pre-push",
    "utils/py/gate_receipt.py",
    "utils/py/marathon_drive.py",
    "TESTS-RESULTS/2026-10-29+GH-1236/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-29+GH-1236/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1236",
    "criteria": "validate.sh writes scope=full receipts only for unskipped tier-3 runs; gate_receipt check --require-full-gate; marathon preserves only an eligible receipt; pre-push full arm reuses only for every pushed SHA."
  },
  "lanes": {
    "agy_safe": [
      "validate.sh",
      "githooks/pre-push",
      "utils/py/gate_receipt.py",
      "utils/py/marathon_drive.py",
      "TESTS-RESULTS/2026-10-29+GH-1236/smoke.md",
      "TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```
