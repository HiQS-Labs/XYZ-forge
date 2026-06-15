# RELAY · Phase-4 QA gate (verify the checklist against the code)
<!--
  Single source of truth for this relay. Read this ENTIRE file before acting.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (Setup: `Producer=Claude-A`, `Reviewer=Codex`) **and** the last Log block isn't already yours. If not → STOP, reply "wrong window — nudge the <other> window."
3. **Do your role's work** (cite `file:line`):
   - **Reviewer:** independently **verify each QA item against the actual code/tests** — confirm every claimed-DONE `[x]` is *behaviorally true*, and every `[ ]` is *correctly still open* (not under-claimed). Grade: `[Blocker]` = a checked item that is NOT truly satisfied (over-claim) · `[Should]`/`[Nit]` = weaker issues · `[Pass]` = verified sound. Set a **Verdict**. Do **not** edit the artifact.
   - **Producer:** dispose each finding (Implemented/Modified/Declined+why), correct any over-claimed checkbox, then summarize.
4. **Append ONE block** at the bottom, above the marker. Never edit earlier turns. Header `### Round N · <Role> · <your-label> · <date time>`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes; else `Open`).
6. **Commit only files you touched:** `git commit -m "relay(phase4-qa-gate): <your-label> r<N>"`, fill the hash, `git commit --amend --no-edit`, then `git push origin main`.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review: the **Phase-4 QA checklist** in `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` (Phase 4 section + "QA checklist — Phase 4"), as marked at commit `da80f51`, **verified against the implementation**: `relay-automation/{poll.sh,relay-drive.sh,watchdog.sh,runner.sh,README.md}`, `test/{poll-driver.sh,poll-relay.sh}`.
- Definition of Done: every `[x]` is **behaviorally true** against the code/tests (no over-claim), and every `[ ]` is **correctly open** (no under-claim). Reviewer confirms or flags each.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Codex (independent model, window C)**
- Handoff: manual nudge.
- Started: 2026-06-15

## Ground rules
1. Single source of truth; different models, no shared memory.
2. Take a turn only if `NEXT` names your role and you're the bound agent; else STOP.
3. One block at the bottom, above the marker. Never edit earlier turns.
4. Bullets, not essays. Grade every finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`.
5. Reviewer verifies against code; never edits the artifact. Producer disposes + edits.
6. Commit your turn (`relay(phase4-qa-gate): <role> r<N>`), fill the hash.
7. Clean tree at handoff; one window at a time.

## Roles
- **Producer (Claude-A)** — marked the checklist; disposes findings + corrects checkboxes.
- **Reviewer (Codex)** — independently verifies each item against the code; graded findings + verdict.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-15 09:30 PDT
**Verify my Phase-4 QA marks against the code.** I marked 9/12 done, 4 open. Please confirm each is honestly classified (over-claim = Blocker; under-claim = Nit). Evidence per item:

**Main checkboxes**
- `[x]` per-window guard keyed on claimability-for-me — `poll.sh` xyz: `status:open && (handoff empty|=me)→my-turn`; `status:claimed && claimer=me→my-turn` (poll.sh ~xyz block); relay mode: `NEXT==my-role`.
- `[ ]` end-to-end two live Claude windows, zero nudges — **open**: mechanism built + unit-tested (`relay-drive.sh`, `poll-relay.sh` 8/8), no live two-window run.
- `[x]` graceful degradation (non-Claude via file + manual nudge) — embedded `▶ TAKE YOUR TURN` block + `poll.sh` cross-model nudge; used live with Codex this week.
- `[x]` operating-model note (all-Claude limit) — `relay-automation/README.md` Boundary + PHASE-4-PLAN.md.
- `[ ]` poll interval cache-warmth note — **partial**: README shows `/loop 60s` + "guard is the lock"; explicit cache-warmth rationale still TODO.

**QA checklist**
- `[x]` DRY (reuses `tick info`/`analyze`) — `poll.sh` reads `tick info` + `tick analyze --format json`, no parallel bookkeeping.
- `[x]` SOLID (poll/runner/watchdog separable) — 4 distinct scripts/concerns.
- `[x]` Observability (each tick logs decision) — `poll.sh` prints `DECISION: <x> (<reason>)`.
- `[ ]` Litmus race (two pollers never both act; hammer-test) — **open**: structurally serialized by tick claim-lock + per-role NEXT, but not hammer-tested.
- `[ ]` Litmus no-deadlock (routed-to window wakes, claims open token) — **open**: implemented in `poll.sh` xyz guard; not verified E2E live.
- `[x]` anti-goal (manual path works, no hard tick dep in protocol) — portable `/relay` skill stays dependency-free.
- `[x]` remote-deploy needed? No — same-session shared tree.

**Verify this:** is anything marked `[x]` not actually true against the code (over-claim)? Is anything `[ ]` actually already satisfied (under-claim)? Are the 3 "needs live two-window run" items the right call to leave open?
**Commit:** f908560

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
