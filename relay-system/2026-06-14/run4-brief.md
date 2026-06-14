# RELAY · Run-4 meta-exercise brief — review

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 5

## Setup
- Artifact under review: `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md`
- Definition of Done: The brief is **runnable as-is** by a fresh coordinator window — the lane split is correct against how `tick` actually routes (in-half overlap → sequential; cross-half disjoint → concurrent), the dual acceptance is objectively measurable, the rabbit-hole guards are sufficient, and the runtime-context section gives the executor everything it needs without guessing.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Claude-B (reviewer, window B)**   <!-- IDENTITY LOCK: both windows are Claude, so we bind DISTINCT labels. Each holds ONE role for the whole relay; stamp your label in every turn header. A nudge for the other label is not yours (ground rule 2). -->
- Handoff: manual nudge
- Started: 2026-06-14
- Post-relay: on **Approved**, the **Reviewer (Claude-B)** window executes the brief (it's the run coordinator). The runtime-context section of the artifact is written for that handoff.

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents never share memory.
2. **Wrong-window guard — take a turn only if ALL hold, else STOP and write nothing:** (a) `NEXT` names the role you were asked to take; (b) **you are the agent bound to that role** — Setup names it (`Claude-A`=Producer, `Claude-B`=Reviewer) and prior `Round N · <Role> · <agent>` headers show that role authored by *you*; (c) you have **not** authored the *other* role's turns; (d) the most recent turn block is **not** your own role. On any mismatch reply `STOP — wrong window: <which check failed>. Nudge the <correct role> window.` (Both windows are Claude — `NEXT` alone can't tell you apart; the bound label does.)
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes. The Producer decides each (with the operator) and implements — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — to get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(run4-brief): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start while the other window may be editing; never flip `NEXT` with uncommitted changes — commit or stash first.

## Roles
- **Producer (Claude-A)** — the only writer of the artifact: builds it, requests review, decides+implements proposals, updates.
- **Reviewer (Claude-B)** — reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact. **Executes the brief after Approved.**

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 14:27 PDT
**Did:** Brief is at `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md` (committed `e753798`) — the Run-4 meta-exercise: two build agents construct the relay-automation Phase-1 slice in balanced disjoint lanes, and that build *is* Run 4. Just added a **Runtime context** section so a fresh coordinator window can run it. Lane split: Enforcement half (A1/A2 → `tick` handoff-exclusive rule + test, scope `src/**,test/**,validate.sh`) ‖ Automation half (B1/B2 → runner + watchdog skeletons, scope `relay-automation/**`).
**Review this (against the DoD) — you (Claude-B) will run this after approving, so review for runnability:**
1. **Lane mechanics** — is the in-half-overlap → sequential, cross-half-disjoint → concurrent model correct against `bin/tick` + `src/take.js` (incl. the Run-3 own-overlap exclusion)? Will the seed scopes actually force two separated agents, each doing its 2 tasks sequentially?
2. **Acceptance measurability** — are both bars objectively checkable at wrap-up (validate ≥13; work-bounded % from `.tick/events/`)?
3. **Executor sufficiency** — does the Runtime context section give you (the coordinator) everything to run it without guessing? Name anything missing.
4. **Guards** — do the rabbit-hole guards actually bound the session (one slice, timebox, sub-50%=datapoint)?
**Open questions:** (a) Should B1/B2 (skeletons) carry a minimal parse/lint acceptance, or is "exists + documented stubs" enough for a skeleton? (b) Build agents = Codex + Gemini, or two Claudes?
**Commit:** c6d153d (relay log; brief at e753798)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
