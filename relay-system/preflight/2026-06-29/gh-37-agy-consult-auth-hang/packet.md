# Marathon preflight packet — gh-37-agy-consult-auth-hang

- Generated: 2026-06-29T22:33:40Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-37-AGY-CONSULT-AUTH-HANG.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ 2ae0584eb)
- Verdict: ready
- Gate: `bash validate.sh`
- Artifacts: relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (artifacts ≈ 335 LOC + their tests; the fast-fail probe adds an `agy` invocation the test stubs must account for — needs well above the 300s default to build AND self-verify)

> **Re-fire note (operator-corrected 2026-06-29):** the first fire used the auto-suggested budget (300s,
> below its own warning) and a too-narrow artifact list, so codex was killed mid-self-verify, then — on a
> 900s retry — was contained (exit 6) trying to update `test/agy-turn.sh` (off the allowlist). The auth
> pre-flight adds one `agy` call before the real turn, which the test stubs don't expect. The test files
> are now in scope so the builder can reconcile them. See the hardened scope lock below.

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Fast pre-flight auth probe (e.g. a short-timeout `agy whoami`/token check) in the agy shim /
- [ ] Alternatively force non-interactive failure so an expired token exits non-zero immediately.
- [ ] Document the `agy login` re-auth step where the agy harness is described.
- [ ] Re-verify: valid auth → agy lane answers; expired auth → consult degrades fast with the real cause.
- [ ] `bash validate.sh` green; Codex lane behavior unchanged.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/consult.sh`, `relay-automation/agy-turn.sh`, `test/agy-turn.sh`, `test/shim-worktree.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- **CONTAINMENT IS LOAD-BEARING — do NOT weaken it.** The auth pre-flight you add must NOT change the existing containment guarantees. When you update `test/agy-turn.sh`, you may ONLY adjust the stub/setup so it accounts for the one extra `agy` invocation the pre-flight makes — you must NOT relax any assertion. Specifically, the off-lane-edit scenario (STUB_MODE=bad), the commit-bypass scenario, and the spaced-path scenario MUST still assert **exit 6** with the off-lane file reverted/removed. If your pre-flight causes any of those to no longer exit 6, that is a BUG IN YOUR IMPLEMENTATION (the pre-flight is bypassing the off-lane revert) — fix the implementation, do NOT change the expected exit code. Same for `test/shim-worktree.sh`: GH-22 relay-block preservation and worktree isolation must still hold.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY `bash test/agy-turn.sh` and `bash test/shim-worktree.sh`; the harness runs the full gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/consult.sh,relay-automation/agy-turn.sh \
  --target-root . \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
