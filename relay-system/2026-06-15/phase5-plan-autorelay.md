# RELAY · Phase-5 plan review — AUTOMATED (hands-free, all-Claude dogfood)
<!--
  DOGFOOD: this relay is driven by the relay-automation tooling (tick RELAY-TURN
  token + poll.sh under /loop). Whose-turn is the RELAY-TURN tick task, NOT the
  NEXT line below (NEXT is a human-readable mirror). STATUS is the terminal signal.
-->

NEXT: Claude-B (mirror; authority = tick RELAY-TURN)
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — tick-native (any Claude window under /loop)
Your `/loop` runs `poll.sh`; if it prints `DECISION: run-runner`, it's your turn. Then:
1. **Read this whole file.**
2. **Take the token:** `./bin/tick claim RELAY-TURN --agent <you>` (you can claim it because it's handed to you), then `./bin/tick ping RELAY-TURN --agent <you>`.
3. **Do your role's work** on `relay-automation/PHASE-5-PLAN.md` (cite file:line):
   - **Reviewer (Claude-B):** graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) + a **Verdict**; answer the open questions. Don't edit the artifact.
   - **Producer (Claude-A):** dispose each finding (Implemented/Modified/Declined+why), edit the plan.
4. **Append ONE block** at the bottom, above the marker (`### Round N · <Role> · <you> · <ts>`).
5. **Hand off / close:**
   - continuing → `./bin/tick release RELAY-TURN --to <other>` (re-opens, routes the token).
   - approving (Reviewer) → set `STATUS: Approved` here **and** `./bin/tick done RELAY-TURN --agent <you>` (close agreement — both, or the supervisor escalates).
6. Update the `NEXT:` mirror. **Commit** (`relay(phase5-plan-autorelay): <you> r<N>`) + `git push origin main`.
7. Stop (your loop continues; it idles until the token returns or STATUS is terminal).

## Setup
- Artifact under review: `relay-automation/PHASE-5-PLAN.md`
- Definition of Done: the Phase-5 plan is sound + buildable (tick-embedding option chosen; sub-phases 5a/5b/5c + acceptance adequate) — or Reviewer names gaps.
- Producer: **Claude-A** (this/main window)   ·   Reviewer: **Claude-B** (second Claude window)
- Handoff: **hands-free poll (all-Claude)** — both windows `/loop` `poll.sh`; turn-token = tick `RELAY-TURN`.
- Independence caveat: two Claude windows share a model — this run is primarily a **dogfood of the automation**, not a max-independence review.
- Started: 2026-06-15

## Ground rules
1. Single source of truth. Whose-turn = the tick `RELAY-TURN` token (poll.sh guards on it); `STATUS` here is the terminal signal.
2. Act only when `poll.sh` says `run-runner` for your agent. Else idle.
3. One block appended at the bottom, above the marker. Never edit earlier turns.
4. Close requires agreement: `STATUS: Approved` **and** `tick done RELAY-TURN` (else the supervisor escalates).
5. Clean tree at handoff: commit + push before releasing the token.

## Roles
- **Producer (Claude-A)** — presents the plan; disposes findings; edits.
- **Reviewer (Claude-B)** — graded findings + verdict; never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-15 14:00 PDT
**Presenting `relay-automation/PHASE-5-PLAN.md`** for review — the final phase (package as a sibling skill + a real-run metrics step). This relay is itself the **dogfood**: we're driving it through the relay-automation tooling (RELAY-TURN token + `poll.sh`/`/loop`), so it also exercises the thing it reviews.
**Review focus / open questions:**
1. **Tick embedding** — E1 (depend on `bin/tick`) vs E3 (detect-or-extract)? I lean E1 for a first cut.
2. **Does a Claude↔Claude hands-free run close the live-E2E QA item (196)**, or does that box need something more?
3. **Which metrics** make "is this worth using daily" answerable (rounds, time/turn, % turns auto-fired vs nudged, auto-recovered stalls)?
**Also flag** anything that should block starting 5a.
**Handing the token to Claude-B for review.**
**Commit:** fdb81c9

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
