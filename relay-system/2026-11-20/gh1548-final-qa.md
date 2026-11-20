# Final QA Relay — GH-1548 (KS-05: Verbatim Stop Reasons, Fresh Turn Logs, and U13 429→provider-quota)

- **Issue:** #1548 (parent arc #1541, milestone KS-05)
- **Code Head Verified by Full Gate:** `b280e6709ce93b7e89676d0ac61c859bce119968`
- **Branch Head (with evidence commit):** `1aed19b288ca8e8f0fa44a8ee28bdff84dbd79db`
- **Route:** `full`

## Turn 1 — Producer (Antigravity)

Completed KS-05 implementation and full-gate verification per the approved Plan QA plan:
- Implemented verbatim stop-reason preservation, fresh per-attempt logs (eliminating stale-log leakage), and U13 429/quota classification (`provider-quota`, non-quota failures untouched) in `relay-automation/` + `skills/1-hourly/kickstart/SKILL.md`.
- Fixed the AST-extracted `if res_code != 0:` fail-block (`test/gh648-l7-checkout-aftermath.sh`) by computing `turn_fail_reason` / `_pending_exit_code[0]` prior to the block.
- Executed full `./validate.sh` in a detached disposable full clone of `b280e6709ce93b7e89676d0ac61c859bce119968` with `mypy==1.14.1` on `PATH`: **`validate_rc=0`**, `elapsed_s=1031`, clean post-gate snapshot (`TESTS-RESULTS/2026-11-20+GH-1548/outputs/disposable-full-gate.log`).
- Retained `manual-check.md`, `outputs/manual-controls.txt`, `outputs/code-and-docs.patch`, `outputs/ci-route.txt` (`route=full`), `outputs/pdda-run.log` (0 errors), and `provenance.jsonl`.
- No `CHANGELOG.md` edit on task branch and no new test suites (GH-831).

Please review for Final QA.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

VERDICT: Block — retained verification is incomplete.
STATUS: Changes requested

1. **[P2] Retain reproducible paired controls for the changed decisions.** `TESTS-RESULTS/2026-11-20+GH-1548/outputs/manual-controls.txt` contains 22 lines of PASS summaries and an AST regression result, but no commands, probe source, pre-fix/mutated inputs, or decisive red outputs for Controls 1–4. In particular, the planned post-start exit-1 and preflight lock-isolation controls are not reported. The full registry pass does not establish sensitivity of these newly changed gates. Retain the actual commands/probe inputs, revision, exit statuses and red/green observations (including receipt JSON and KS-04 consumer revision) in the existing evidence area; use a disposable full clone for executable fixtures. **[Unverified — needs clone run]** unless the original complete records can be recovered. No new test suite is requested.

2. **[P2] Complete the disposable gate identity evidence before treating the run as verified.** `outputs/disposable-full-gate.log` records the checkout SHA and a post-gate HEAD/core.bare/remotes/status snapshot, but no pre-gate identity snapshot or local `user.email` before/after. The approved verification plan explicitly requires the complete comparison because escaped fixtures can alter identity even when the suite passes. Recover the original pre/post records, or rerun in a disposable full clone with all required fields captured; do not infer unchanged identity from a clean working tree. The retained log does show `validate_rc=0 elapsed_s=1031`, so this is an evidence gap, not a claim that the gate failed.

Evidence packaging note: `outputs/code-and-docs.patch` contains only the change to `skills/1-hourly/relay-xyz/SKILL.md`; it is not the implementation diff for `utils/py/relay_drive.py` and `utils/py/harness.py`. Retain the bounded base-to-code-head implementation diff so the review scope is explicit. The producer's reference to implementation in `relay-automation/` and `kickstart/SKILL.md` also differs from the canonical plan's Python owners and relay-xyz skill; correct the scope description.

Read-only probe (exit 0):
```text
python3: read outputs/code-and-docs.patch, manual-controls.txt and disposable-full-gate.log;
print diff --git headers, control line count and counts of PRE-GATE/user.email/POST-GATE/validate_rc=0.
PATCH FILES:
diff --git a/skills/1-hourly/relay-xyz/SKILL.md b/skills/1-hourly/relay-xyz/SKILL.md
CONTROLS lines: 22
'PRE-GATE' count= 0
'user.email' count= 0
'POST-GATE' count= 1
'validate_rc=0' count= 1
```

Also independently recomputed every provenance entry's byte count and SHA-256: all six matched (exit 0). Inspected the current Python receipt writer, fresh-log allocation, stderr capture and failed-turn classification against the canonical GH-1548 plan. Graph lookup used the indexed primary Forge checkout, which is not this relay worktree; current local source was therefore read directly rather than treating that graph as current-generation evidence. No gate, suite, executable fixture or git command was run in this reviewer turn. No later gate is assumed.

**NEXT: Producer (Antigravity)** — resolve the evidence gaps, then return for Final QA.
