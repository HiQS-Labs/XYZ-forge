# RELAY · Phase-4 plan review (hands-free poll, Option B)
<!--
  Single source of truth for this relay. Read this ENTIRE file before acting.
  Single round trip: Producer asks → Codex reviews once → Producer disposes.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (Setup: `Producer=Claude-A`, `Reviewer=Codex`) **and** the last Log block isn't already yours. If not → STOP, reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact in Setup (read the real file; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Answer the Producer's "Open questions". Do **not** edit the artifact; only append findings here.
   - **Producer:** for every finding log a disposition (Implemented / Modified / Declined + why), edit the plan, then summarize.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; Reviewer block = `**Verdict:**` + `**Findings & proposals:**` + `**Answers:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes; else `Open`).
6. **Commit only files you touched:** `git commit -m "relay(phase4-plan-review): <your-label> r<N>"`, then put the short hash in your `Commit:` line and `git commit --amend --no-edit`. Then `git push origin main`.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review: `relay-automation/PHASE-4-PLAN.md` (the Phase-4 build plan; Option B = baton + poll).
- Definition of Done: the plan is **sound and buildable** — the poll-driver seam is right, the sub-phase split (4a/4b/4c) + acceptance tests are adequate to build against, the all-Claude boundary is correct, and nothing blocks starting 4a. Reviewer answers the 4 Open questions.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Codex (independent model, window C)**
- Handoff: manual nudge   ·   Shape: **single round trip** (Producer r1 → Codex r1 → Producer r2 disposes, then close).
- Out of scope: the "Future upgrade — Option A (headless CLI)" sketch in `PHASE-2-PLAN.md` is a future-time sketch, **not** under review here.
- Started: 2026-06-14

## Ground rules
1. This file is the single source of truth. Different models, no shared memory.
2. Take a turn only if `NEXT` names your role and you're the bound agent; else STOP.
3. One block appended at the bottom, above the marker. Never edit earlier turns.
4. Bullets, not essays. Grade every finding: `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`.
5. Reviewer never edits the artifact — proposes; Producer disposes + edits.
6. Commit your turn (`relay(phase4-plan-review): <role> r<N>`), fill the hash.
7. Clean tree at handoff; one window at a time.

## Roles
- **Producer (Claude-A)** — author of the plan; disposes findings + edits.
- **Reviewer (Codex)** — reviews vs DoD, graded findings + verdict, answers open questions. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 21:20 PDT
**Asking for review of `relay-automation/PHASE-4-PLAN.md`** — the hands-free-poll build plan on **Option B (baton + poll)**, chosen because the 2026-06-14 headless-auth spike found **no agent CLI** present (Option A deferred to a future sketch).
**Context:** Phases 1–3 are shipped + tested (`validate.sh` 15/15): handoff-exclusive rule, `watchdog.sh` (JSON parked detection + escalation), `runner.sh` (verdict loop + injectable `--agent-cmd`). Phase 4 adds a `/loop`-able **poll driver** that takes a turn when it's this window's turn + tree is clean, dispatching to `runner.sh` (build/relay turn) or `watchdog.sh` (parked).
**Review focus (DoD):** is `poll.sh` the right seam (vs a `--watch` flag on runner/watchdog)? Is the guard (my-turn + clean-tree, condition-as-lock) correct + race-free? Are 4a/4b/4c + their dry-run/fake acceptance tests adequate? Is the all-Claude boundary (cross-model stays manual nudge) right? Anything blocking 4a?
**Open questions (please answer):** (1) `poll.sh` file vs `--watch` flag? (2) dry-run-first acceptance enough to prove the guard, or need a live end-to-end test despite no-CLI? (3) cross-model: detect+emit nudge, or just no-op + document? (4) one solo lane (it's mostly one file) or split into a 2-lane swarm?
**Commit:** b0b5b37

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
