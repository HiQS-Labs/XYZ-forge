# Marathon Phase gh37f
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH37F-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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
- **Do NOT run ANY test or gate yourself — not `validate.sh`, and NOT `test/agy-turn.sh` / `test/shim-worktree.sh` either.** Those two tests create temporary git fixtures and files INSIDE your isolated worktree, which containment flags as off-lane edits and reverts — discarding your ENTIRE turn even when the build is correct (this is exactly what killed the prior attempt: codex's tests passed, but running them tripped containment → exit 6 → good work lost). Implement the edits to the 4 files, reason about correctness by READING the tests (don't execute them), then hand off. The harness runs the full gate (`validate.sh`) AFTER your turn, OUTSIDE your worktree — that is the verification; if anything fails it comes back to you with the failure.
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

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH37F-TURN --agent codex --paths "phases/gh37f/RELAY.md,relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH37F-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH37F-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh37f/RELAY.md and relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/consult.sh,relay-automation/agy-turn.sh,test/agy-turn.sh,test/shim-worktree.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH37F-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH37F-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh37f/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
