# Marathon Phase gh33p4
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH33P4-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-33-loop-skill-integration

- Generated: 2026-06-29T06:29:48Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-33-LOOP-SKILL-INTEGRATION.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ 952444b9d)
- Verdict: ready
- Gate: `bash validate.sh`
- Artifacts: relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (artifacts ≈ 935 LOC; large files need more than the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [x] Open a GitHub issue describing the `/loop` integration (issue-first SOP). → [#33](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33)
- [x] Name this doc `PROJECT/1-INBOX/GH-33-LOOP-SKILL-INTEGRATION.md` and set `gh_issue` in frontmatter.
- [x] Park a one-line queue pointer in `ROADMAP.md` linking this inbox doc.
- [x] Decide the shipping shape: **chose (A)** — a new thin wrapper `relay-automation/relay-loop.sh` that maps `poll.sh` decisions to act / background-dispatch / reschedule, over (B) a `--driver loop` mode inside `relay-drive.sh`. Rationale: keeps the deterministic supervisor untouched (smaller blast radius), composes with the existing `--dry-run`/`--emit-delay` oracle, and is fully removable. (CHANGELOG entry lands when Phase 2 promotes to `2-WORKING`.)
- [x] Confirm scope ordering: **Phase 2 (adaptive cadence) first**, then Phases 3–4 (the unification) behind an explicit operator GO — they touch containment (Costly).
- [x] GH issue exists and is linked from both the doc frontmatter and `ROADMAP.md`.
- [x] `utils/pdda-check-roadmap-coverage.sh` passes (inbox doc is parked).
- [x] Shipping-shape decision (A or B) is written down, not implicit.
- [x] No code changed in this phase. (Code begins in Phase 1, below.)
- [x] Added `--emit-delay` so each `poll.sh` run prints a `DELAY: <seconds> (<reason>)` line alongside its `DECISION`, derived from the same state it already computes: `run-runner`/`run-watchdog`/`stop`→0, idle-dirty→`POLL_DELAY_DIRTY` (30), waiting-for-peer-commit→`POLL_DELAY_WAIT_COMMIT` (90), `nudge-cross-model`→`POLL_DELAY_NUDGE` (120), idle-backoff→`POLL_DELAY_IDLE` (300), then **clamped** so the next wake never overshoots `--deadline`.
- [x] Purely additive: the existing `DECISION:` line is unchanged; callers that ignore the new line behave exactly as today (flag is opt-in, default off).
- [x] Unit-covered the delay mapping for each decision + the env override + the near-deadline clamp (8 new assertions in `test/poll-driver.sh`).
- [x] Existing `poll.sh` callers (incl. the current `/loop 60s` recipe) are unaffected when they ignore the new output.
- [x] Delay suggestion is a pure function of state (only wall-clock read is the deadline clamp, matching the existing `--deadline` behaviour).
- [x] New tests pass under `./validate.sh` — **50/50**, skill tarball repackaged so `skill-extract.sh` parity holds.
- [x] Built `relay-automation/relay-loop.sh` (the Phase-0 thin wrapper): default = one tick that prints `NEXT-POLL: <seconds>` and exits `poll.sh`'s code, for a `/loop` dynamic-mode tick to read and `ScheduleWakeup` from. Documented the dynamic-mode `/loop` recipe in the `relay-xyz` SKILL.
- [x] Respected the prompt-cache window economics: idle backoff is 300s (crosses the 5-min TTL by design — the win is tokens), active states (dirty 30 / wait-commit 90 / nudge 120) stay sub-cache-window. Encoded in the Phase 1 delay defaults.
- [x] Added the `relay-xyz` SKILL note ("Path B cadence — fixed interval (today) vs adaptive") describing the tradeoff + the dynamic-mode recipe; **kept the reschedule pluggable** — `relay-loop.sh --sleep-loop` self-paces in pure bash and the `NEXT-POLL`/`DELAY` output is consumable by cron/systemd, so `/loop` is one option, not a dependency (addresses the lock-in FAQ).
- [x] Idle relays back off (NEXT-POLL 300) while a live turn still advances promptly (NEXT-POLL 0) — asserted in `test/relay-loop.sh`.
- [x] The fixed-`60s` recipe still works unchanged (dynamic mode is opt-in; `--emit-delay` is additive, `DECISION:` line untouched).
- [x] `tick` claim/heartbeat cadence is unchanged — only the *poll* cadence adapts (wrapper touches no token logic).
- [x] `validate.sh` green with the new `relay-loop.sh` test registered + the script packaged (`skill-extract.sh` 15 files).
- [x] Document/support running a turn shim (`codex-turn.sh` / `agy-turn.sh` / the Claude turn) as a **background** process so the session is freed during the turn and the harness re-invokes on completion (no polling for harness-tracked work). → `relay-loop.sh --background` (nohup-detached launch; `poll.sh` left a pure oracle via `--dry-run`).
- [x] Verify the turn shim's safety boundary (path-allowlist, commit-bypass guard, no-push, worktree isolation) holds identically when launched in the background. → **inherited by construction** (backgrounding via `&` changes only when the parent returns, not the child's code path); asserted by the fg/bg execution-parity test + the kernel's own containment tests (`test/relay-target-root-newfile.sh`).
- [x] On completion, the resuming session reads `STATUS:` / token state and decides hand-off vs stop. → stale pidfile cleared on the next tick, which then acts on the fresh `poll.sh` decision (stop/idle/handoff).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Implementation guidance (Phase 4 — this is the ONLY phase to build)

Phases 0–3 are already shipped; build **only** Phase 4 (the `[ ]` items). Concretely, in
`relay-automation/relay-loop.sh` (the `--background` path Phase 3 added):

1. Add a `--cross-model-cmd CMD` flag (mirror the existing `--runner-cmd` peek): the command to
   run for a cross-model turn. Wrapper-only — do NOT forward it to `poll.sh`.
2. In the `--background` block, on `DECISION: nudge-cross-model`: if `--cross-model-cmd` is set
   **and** reachable, launch it DETACHED via the existing `bg_launch` + pidfile lock (exactly like
   the `run-runner` path) and print `BG-DISPATCH: pid=N`. Otherwise **degrade to the human nudge**
   (print the same nudge `poll.sh` emits today) — never a silent stall. This preserves
   `--claude-agents` semantics (a Claude turn is never cross-model; a non-Claude turn with no
   reachable CLI still nudges).
3. The single-turn pidfile lock already prevents double-dispatch — reuse it; a cross-model turn in
   flight → `BG-RUNNING`, no second dispatch.
4. Keep `poll.sh` a PURE oracle — no dispatch logic there (you may read its `DECISION`).
5. `relay-turn-lib.sh` and `bin/tick` are OUT OF SCOPE — do not edit them. Containment must stay
   byte-identical (the backgrounded shim already enforces the path-allowlist / no-push boundary).

Extend `test/relay-loop.sh` with two cases (keep the existing 11 green):
- (a) `nudge-cross-model` + `--background` + `--cross-model-cmd <stub>` → prints `BG-DISPATCH`,
  writes the pidfile, runner-stub runs exactly once (no double-dispatch on a second tick).
- (b) `nudge-cross-model` + `--background` with **no** `--cross-model-cmd` (or an unreachable one)
  → degrades to the nudge, no dispatch, pidfile not written.

Add a one-line note to the `relay-loop.sh` row in `relay-automation/README.md`. Verify with
`bash test/relay-loop.sh` ONLY.

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
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH33P4-TURN --agent codex --paths "phases/gh33p4/RELAY.md,relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH33P4-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH33P4-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh33p4/RELAY.md and relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-loop.sh,relay-automation/poll.sh,test/relay-loop.sh,relay-automation/README.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH33P4-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH33P4-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh33p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
