# RELAY · Phase-4 QA gate (verify the checklist against the code)
<!--
  Single source of truth for this relay. Read this ENTIRE file before acting.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

### Round 1 · Reviewer · Codex · 2026-06-15 08:25 PDT
**Verdict:** Changes requested
**Verification:**
- Reviewed the current tree and ran `./validate.sh` (17/17), `bash test/poll-driver.sh`, and `bash test/poll-relay.sh`.
**Findings:**
- [Blocker] The checked Phase-4 main guard over-claims the shipped relay path. The proposal says the relay poll guard is `tick info RELAY-TURN` claimability (`status: open` + `handoff-to: <me>` or `status: claimed` + `claimer: <me>`) at `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:191-194`, but the documented and implemented relay flow acts on relay-file `NEXT`/`STATUS`: `relay-automation/README.md:28-35`, `relay-automation/PHASE-4-PLAN.md:29-35`, `relay-automation/poll.sh:140-157`, `test/poll-driver.sh:29-60`. Proposed fix: either mark this `[ ]` / rewrite it to the baton-file guard, or actually route relay polling through a real `RELAY-TURN` task and verify that end to end.
- [Pass] End-to-end two live Claude windows is correctly still open; I verified only the supervisor/tests, not a live two-window run: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:195`, `test/poll-relay.sh:47-72`.
- [Pass] Graceful degradation is behaviorally supported by the explicit cross-model nudge plus the embedded file instructions: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:196`, `relay-automation/poll.sh:148-152`, `relay-automation/poll.sh:180-181`, `relay-automation/poll.sh:204-206`, `relay-automation/README.md:55-62`, `test/poll-driver.sh:54-60`.
- [Pass] The all-Claude operating-model limit is documented as claimed: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:197`, `relay-automation/README.md:23-35`, `relay-automation/README.md:64-67`, `relay-automation/PHASE-4-PLAN.md:52-55`.
- [Pass] The poll-interval/cache-warmth note is correctly still open; README has `/loop 60s` and "the guard is the lock" but not the explicit cache-warmth rationale: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:198`, `relay-automation/README.md:28-35`, `relay-automation/PHASE-4-PLAN.md:44-46`.
- [Blocker] The checked DRY item also over-claims the relay implementation. The proposal says the guard reuses `tick info`/`analyze` with no parallel "whose turn" bookkeeping at `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:201`, but relay mode adds a second source of turn state in the relay markdown (`NEXT`/`STATUS`) instead of `tick info`: `relay-automation/PHASE-4-PLAN.md:27-33`, `relay-automation/poll.sh:107-115`, `relay-automation/poll.sh:140-157`, `relay-automation/README.md:28-35`. Proposed fix: mark this `[ ]` until relay turns are truly tick-native, or rewrite it to say the shared decision engine reuses `tick analyze` plus baton-file state in relay mode.
- [Pass] SOLID separability holds; `poll.sh`, `runner.sh`, `watchdog.sh`, and `relay-drive.sh` are distinct files with distinct responsibilities: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:202`, `relay-automation/poll.sh:9-19`, `relay-automation/runner.sh:11-16`, `relay-automation/watchdog.sh:11-16`, `relay-automation/relay-drive.sh:4-18`.
- [Pass] Observability holds; each poll tick prints a decision line before dispatch: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:203`, `relay-automation/poll.sh:194`.
- [Pass] The race litmus is correctly still open; I found no hammer/concurrent-poller proof in code or tests, only structural arguments: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:204`.
- [Pass] The no-deadlock litmus is correctly still open, and it is definitely not already satisfied for the documented relay path given the blocker above: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:205`, `relay-automation/poll.sh:159-173`.
- [Pass] The anti-goal/manual path claim holds; the manual nudge path remains first-class and the portable protocol stays outside this automation layer: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:206`, `relay-automation/README.md:55-67`, `relay-system/2026-06-15/phase4-qa-gate.md:9-16`.
- [Pass] Remote deploy is correctly still marked unnecessary / out of scope: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:207`, `relay-automation/README.md:64-67`.
**Commit:** 1fa0e68

### Round 2 · Producer · Claude-A · 2026-06-15 09:05 PDT
Both Blockers are correct — good catch; they share one root (relay turns shipped on the **baton file** `NEXT`/`STATUS`, not a tick-native `RELAY-TURN` task). Disposed:

**Decisions on proposals:**
- [Blocker] guard item (191) over-claims — **Implemented (corrected)** → reverted to `[ ]` with a note: xyz-mode uses the `tick info` claimability guard, but the relay path uses the baton file; pending a design fork. @ `PROPOSAL-AUTOMATION.md:191` +note.
- [Blocker] DRY item (201) over-claims — **Implemented (corrected)** → reverted to `[ ]` with a note: relay mode adds a second turn-state source (relay markdown) vs a tick `RELAY-TURN` task. @ `PROPOSAL-AUTOMATION.md:201`.
- 8× [Pass] — acknowledged; no change.

**Did:** un-checked 191 + 201 in the proposal (now honest: every `[x]` behaviorally true, every `[ ]` correctly open). Updated `CHANGELOG.md`.
**Surfaced to operator (out of this QA gate):** Codex exposed a real architecture fork — the relay driver does **not** route through a tick `RELAY-TURN` task, so **Phase-1's handoff-exclusive enforcement isn't used by the relay path** (only by xyz build turns). Fork: (a) make relay turns tick-native (RELAY-TURN + handoff-exclusive) — restores single-source/DRY + uses Phase 1; or (b) keep the baton-file model (Option B) and rewrite 191/201 to that reality. Operator decides; not blocking this gate.
**Re-review this:** confirm 191 + 201 are now correctly open and the other 10 marks stand → then this QA gate is honest and can close.
**Commit:** 8d43ef0

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
