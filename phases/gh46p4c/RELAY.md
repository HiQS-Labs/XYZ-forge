# Marathon Phase gh46p4c
STATUS: Approved
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH46P4C-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-46-phase4-swarm-preflight

- Generated: 2026-06-29T15:09:38Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-46-PHASE4-SWARM-PREFLIGHT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ 39c9f30fa)
- Verdict: ready
- Gate: `bash validate.sh`
- Artifacts: relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (artifacts ≈ 935 LOC; large files need more than the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] `swarm-preflight --gh-issue 46` reaches `ready` (or `BLOCKED` only on a dirty tree), never `contract missing/invalid`.
- [ ] `relay-loop.sh --background --cross-model-cmd …` dispatches the cross-model shim on `DECISION: nudge-cross-model`; the pidfile single-turn lock holds (no double-dispatch).
- [ ] Cross-model CLI absent → degrades to the existing human nudge, no dispatch (never a silent stall); `--claude-agents` semantics preserved.
- [ ] Containment + token correctness identical to Path A: `relay-turn-lib.sh` untouched, no widened allowlist, no orphaned cross-repo commit (GH-29 hazard). `poll.sh` stays a pure oracle. `relay-drive.sh` (deterministic mode) unchanged.
- [ ] `test/relay-loop.sh` extended: (a) `nudge-cross-model` + `--background` + `--cross-model-cmd` → BG-DISPATCH of the shim, single-dispatch lock holds; (b) cross-model CLI absent → degrades to nudge, no dispatch.
- [ ] `relay-automation/README.md` row updated; `bash validate.sh` green.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.
- **Do NOT run git at all** (no `git add` / `commit` / `push`) — the harness commits for you. A commit made during your turn is a containment violation and DISCARDS your whole turn.

## Implementation guidance (concrete steps)

All edits are in `relay-automation/relay-loop.sh` (the `--background` path Phase 3 added) + its test:

1. Add a `--cross-model-cmd CMD` flag — peek it like the existing `--runner-cmd` peek (record into a
   local; wrapper-only, do NOT forward to `poll.sh`).
2. In the `--background` block, after the `bg_alive` / stale-pidfile handling, extend the `case
   "$DECISION"`: add a `nudge-cross-model)` arm. If `--cross-model-cmd` is set **and** reachable
   (`command -v` the first token, or `-x` the path), `bg_launch "$CROSS_MODEL_CMD"` + print
   `BG-DISPATCH: pid=N` (identical to the `run-runner` arm — reuse `bg_launch` + the pidfile lock).
   Otherwise print the human nudge (same text `poll.sh` emits) and `NEXT-POLL: $DELAY` — never a
   silent stall.
3. The pidfile lock already gives you no-double-dispatch (`BG-RUNNING`) for free — don't reinvent it.
4. `poll.sh` stays a PURE oracle — read its `DECISION`, add no dispatch logic there.
5. OUT OF SCOPE — do not touch: `relay-turn-lib.sh`, `bin/tick`. Containment must stay byte-identical.

Test (`test/relay-loop.sh`, keep the existing 11 green): (a) a relay whose `NEXT:` is a non-Claude
agent + `--background --cross-model-cmd <stub>` → `BG-DISPATCH`, stub runs once, second tick →
`BG-RUNNING`; (b) same but no `--cross-model-cmd` → the nudge line prints, no pidfile, no dispatch.
Verify with `bash test/relay-loop.sh` ONLY.

## Suggested marathon-drive.sh invocation

```bash
relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH46P4C-TURN --agent codex --paths "phases/gh46p4c/RELAY.md,relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH46P4C-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH46P4C-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh46p4c/RELAY.md and relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH46P4C-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH46P4C-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh46p4c/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Files touched: `relay-automation/relay-loop.sh`, `test/relay-loop.sh`, `relay-automation/README.md`, `phases/gh46p4c/RELAY.md`
- Kept `poll.sh` unchanged so the decision engine remains a pure oracle; Phase 4 dispatch lives only in the wrapper.
- Added wrapper-only `--cross-model-cmd` handling in `relay-loop.sh`: `--background` now reuses `bg_launch` + the existing pidfile lock for `DECISION: nudge-cross-model` when the command is configured and reachable, and otherwise prints the same manual nudge text as `poll.sh` plus `NEXT-POLL`.
- Extended `test/relay-loop.sh` with both required Phase 4 cases: detached cross-model dispatch with `BG-RUNNING` on the second tick, and the no-command degrade path with no pidfile/dispatch.
- Updated `relay-automation/README.md` to document the new `relay-loop.sh --background --cross-model-cmd <shim>` behavior and the unchanged manual fallback.
- Verification: `bash test/relay-loop.sh` → `15 pass, 0 fail`.

### Round 1 · Reviewer · agy

- Verified changes in `relay-automation/relay-loop.sh`, `test/relay-loop.sh`, and `relay-automation/README.md`.
- Confirmed that `--cross-model-cmd` is correctly registered, checks for reachability, and background-dispatches when appropriate.
- Confirmed fallback to manual nudge when the command is unset/unreachable is working properly.
- Ran the specific test suite: `bash test/relay-loop.sh` is fully green (15 pass, 0 fail).
- **Verdict:** Approved
