# Marathon Phase gh273-phase3
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH273-PHASE3-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-273-marathon-closeout-automation

- Generated: 2026-07-22T03:39:52Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (development @ e31c6c8d3)
- Suggested branch: `marathon/gh-273-marathon-closeout-automation-2026-07-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: relay-automation/marathon-closeout.sh,test/marathon-closeout.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (sized to ≈ 0 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/marathon-closeout.sh,test/marathon-closeout.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-273-marathon-closeout-automation relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/marathon-closeout.sh,test/marathon-closeout.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-closeout.sh,test/marathon-closeout.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH273-PHASE3-TURN --agent codex --paths "phases/gh273-phase3/RELAY.md,relay-automation/marathon-closeout.sh,test/marathon-closeout.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH273-PHASE3-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE3-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh273-phase3/RELAY.md and relay-automation/marathon-closeout.sh,test/marathon-closeout.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-closeout.sh,test/marathon-closeout.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE3-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH273-PHASE3-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh273-phase3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Implemented the Phase 3 closeout extraction using the canonical GH-273 project contract because
the generated phase brief's acceptance-criteria section was empty.

- Files touched: `relay-automation/marathon-closeout.sh`, `test/marathon-closeout.sh`, and this relay.
- The closeout script stages all changes with `git add -A`, commits, pushes the current feature
  branch, creates a PR with operator-supplied title/notes, requires green checks and GitHub's
  `MERGEABLE` state, merges, switches to `development`, and pulls it with `--ff-only`.
- `--dry-run` requires an explicit `--head` and prints the complete command sequence without
  invoking either `git` or `gh`. Live runs auto-detect the head branch and refuse to close out the
  base branch. Exit codes are explicit: 2 usage/precondition, 3 command failure, 4 checks or
  mergeability refusal.
- The regression test PATH-shadows both `git` and `gh` inside a disposable scratch directory; it
  makes no real Git/GitHub call. It covers inert dry-run output, the green happy path, inclusion of
  pre-existing manual edits via `git add -A`, red checks, conflicting mergeability, and exit codes.
- Verification: `bash test/marathon-closeout.sh` → 18 passed, 0 failed (including `bash -n` for
  both scoped scripts). Per the phase scope, the full project gate was not run; the harness owns it.

### Round 1 · Reviewer · agy

The implementation successfully fulfills the acceptance criteria. The scripts accurately perform a safe push and pull request sequence with explicit status codes, proper checks, and comprehensive mocked regression tests. I successfully executed the `bash test/marathon-closeout.sh` test and all 18 test cases pass as expected.

**Verdict:** Approved
