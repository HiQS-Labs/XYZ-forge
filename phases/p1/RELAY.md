# Marathon Phase p1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH59-P1 builder=codex reviewer=agy round-cap=6 -->

## Phase Brief

# Marathon preflight packet — gh-59-offlane-untracked-dir

- Generated: 2026-07-02T19:01:33Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/1-INBOX/GH-59-OFFLANE-UNTRACKED-DIR.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (marathon/gh-59-offlane-2026-07-02 @ 29a86639a)
- Suggested branch: `marathon/gh-59-offlane-untracked-dir-2026-07-02` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash test/worktree-isolation.sh`
- Artifacts: relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 667 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] `rtl_in_allow` (or the `rtl_worktree_end` off-lane loop) treats a git-collapsed untracked-directory prefix as allowed WHEN it is an ancestor of an allowlisted **file** entry — mirroring the existing `.relay-artifacts` special-case, but generalized.
- [ ] A greenfield-artifact-in-a-new-dir turn (allowlisted file in an otherwise-untracked dir) commits file-scoped with **no** spurious exit 6.
- [ ] A genuinely off-lane change (a new file NOT under any allowlisted ancestor) STILL trips exit 6 (strictness preserved — match only true ancestors of a concrete allowlist file, never a bare prefix).
- [ ] The change carries a `GH-59` marker comment at the generalization site in `relay-automation/relay-turn-lib.sh`.
- [ ] A regression case is added to `test/worktree-isolation.sh` covering both the fixed greenfield case AND the still-rejected genuine off-lane case; it fails without the fix and passes with it.
- [ ] `bash test/worktree-isolation.sh` passes; no edit outside `relay-automation/relay-turn-lib.sh` + `test/worktree-isolation.sh`.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash test/worktree-isolation.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-59-offlane-untracked-dir relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh \
  --pre-advance-cmd 'bash test/worktree-isolation.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH59-P1 --agent codex --paths "phases/p1/RELAY.md,relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH59-P1 --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH59-P1 --agent codex --to agy
4. Edit ONLY these paths: phases/p1/RELAY.md and relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH59-P1 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH59-P1 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
