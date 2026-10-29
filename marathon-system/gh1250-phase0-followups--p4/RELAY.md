# Marathon Phase p4
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): validate.sh, githooks/pre-push, utils/py/gate_receipt.py, utils/py/marathon_drive.py, TESTS-RESULTS/2026-10-29+GH-1236/smoke.md, TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick claim MARATHON-P4-TURN --agent agy --paths "marathon-system/gh1250-phase0-followups--p4/RELAY.md,validate.sh, githooks/pre-push, utils/py/gate_receipt.py, utils/py/marathon_drive.py, TESTS-RESULTS/2026-10-29+GH-1236/smoke.md, TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick ping MARATHON-P4-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P4-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1250-phase0-followups--p4/RELAY.md and validate.sh, githooks/pre-push, utils/py/gate_receipt.py, utils/py/marathon_drive.py, TESTS-RESULTS/2026-10-29+GH-1236/smoke.md, TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh, githooks/pre-push, utils/py/gate_receipt.py, utils/py/marathon_drive.py, TESTS-RESULTS/2026-10-29+GH-1236/smoke.md, TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P4-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick done MARATHON-P4-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   Edit ONLY marathon-system/gh1250-phase0-followups--p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

---

### Round 1 · Builder · agy

Implemented GH-1236 so `githooks/pre-push` reuses an eligible `validate.sh` full-gate receipt (`scope: full`) for the exact pushed commit SHA without re-running `validate.sh`, while failing closed to the existing gate routes in every other case.

#### Files touched
- `validate.sh` (`:1589-1595`): restricted `.xyz/receipts/<sha>.json` writing to tier-3, empty `SUBSYSTEM`, zero `SKIPPED_SUITES` (`--skip` or skipped pytest), empty `XYZ_ENV_FAULTS`, and a verified clean tree (`git -C "$HERE" status --porcelain`), passing `--scope full` to `gate_receipt.py write`.
- `utils/py/gate_receipt.py`:
  - Added optional `--scope` to `write` / `write_receipt` (persisted as `scope` when provided).
  - Added `is_full_gate_receipt(data, sha)` requiring `valid_pass_receipt(data, sha)` (`exit_code == 0` as non-bool int and matching `sha`), `gate == "validate.sh"`, `mode != "marathon"`, and `scope == "full"`.
  - Added `--require-full-gate` to `check` / `check_receipt`, enforcing `is_full_gate_receipt` and declining the legacy `.gate-evidence/<sha>.txt` fallback when `--require-full-gate` is set. Plain `check` (without `--require-full-gate`) is unchanged for `marathon-closeout.sh`.
- `utils/py/marathon_drive.py` (`_write_marathon_gate_receipt`, `:2844-2850`): before writing the `mode: "marathon"` pre-advance receipt, loads any pre-existing `.xyz/receipts/<head_sha>.json` and preserves it when `gate_receipt.is_full_gate_receipt(existing, head_sha)` is true; otherwise writes the marathon receipt as today (repairing absent, corrupt, failed, wrong-SHA, or weaker files so closeout's plain `check` passes).
- `githooks/pre-push` (`:288-309`): in the full-gate `else` arm (after `docs` and `tier 2` routes have declined), checks that `_real_ref_pairs` has at least one non-delete entry and that every pushed local SHA passes `gate_receipt.py check --repo "$REPO" --sha "$_lsha" --require-full-gate`. When satisfied, prints `pre-push: reusing the passing full-gate receipt for <sha8> (validate.sh, scope full) — the full gate already ran on this exact commit.` and exits `0`; any miss or error falls through to `validate.sh`.
- `TESTS-RESULTS/2026-10-29+GH-1236/smoke.md` & `TESTS-RESULTS/2026-10-29+GH-1236/provenance.jsonl`: recorded hermetic manual smoke recipe, base red controls (`93f41cb8`), all 7 adjacent negative cases, marathon writer preservation/repair checks, and disposable-clone suite results.

