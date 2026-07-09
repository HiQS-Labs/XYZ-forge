# Marathon Phase gh186
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH186-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-186-aider-vendor-version-drift

- Generated: 2026-07-09T04:44:18Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-186-AIDER-VENDOR-VERSION-DRIFT.md 
- Target root: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm (claude/gh-173-178-beta-patches-ygfgc5 @ 775380c56)
- Suggested branch: `marathon/gh-186-aider-vendor-version-drift-2026-07-09` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh
- Auto-included covering tests/helpers: test/_setup.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 598 LOC across 3 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Add runtime detection (or an explicit version guard) for `--add-gitignore-files` support in
- [ ] Extend the GH-168 regression test (`test/aider-turn.sh` case 13) to assert correct behavior
- [ ] Confirm `bash test/aider-turn.sh` stays green with no behavior change for the common case.
- [ ] The fix makes the flag decision version-aware, not a re-hardcode in either direction.
- [ ] The regression test would have caught both GH-168 (flag missing, needed) and this issue
- [ ] No regression in `test/aider-turn.sh`'s existing cases.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/aider-turn.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-186-aider-vendor-version-drift relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH186-TURN --agent codex --paths "phases/gh186/RELAY.md,relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH186-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH186-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh186/RELAY.md and relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/aider-turn.sh,test/aider-turn.sh,test/_setup.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH186-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH186-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh186/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex
Files touched: `relay-automation/aider-turn.sh`, `test/aider-turn.sh`, `phases/gh186/RELAY.md`

Implemented runtime detection for `--add-gitignore-files` in `relay-automation/aider-turn.sh` by probing `"$AIDER_BIN" --help` and only appending the legacy flag when the installed aider advertises it. `--no-gitignore` remains unconditional, so current aider builds avoid the removed flag while older vendored installs can still receive it.

Extended `test/aider-turn.sh` case 13 so the stub now answers `--help` and simulates both surfaces: old aider with `--add-gitignore-files` support and current aider without it. The regression now asserts the gitignored relay file is still passed as `--file` in both cases, and that the legacy flag is present only for the old-aider path.

Verification: `bash -n relay-automation/aider-turn.sh test/aider-turn.sh test/_setup.sh`
