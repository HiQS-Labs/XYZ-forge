# RELAY · Cost-observability plan review — AUTOMATED (headless Gemini reviewer)
<!--
  Driven by relay-automation (tick RELAY-COST token + relay-drive.sh + gemini-turn.sh).
  Whose-turn is the RELAY-COST tick task, NOT the NEXT line (NEXT is a human mirror).
  STATUS is the terminal signal. Reviewer = Gemini (headless CLI); Producer = Claude-A.
-->

NEXT: claude-a (finalize)
STATUS: Draft
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — tick-native
1. **Read this whole file** and the artifact under review.
2. **Take the token:** `./bin/tick claim RELAY-COST --agent <you>`, then `./bin/tick ping RELAY-COST --agent <you>`.
3. **Do your role's work** on `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md` (cite file:line):
   - **Reviewer (gemini):** graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) + a **Verdict**; answer the open questions. Do NOT edit the artifact.
   - **Producer (claude-a):** dispose each finding (Implemented/Modified/Declined+why), edit the plan.
4. **Append ONE block** at the bottom, above the marker (`### Round N · <Role> · <you> · <ts>`).
5. **Hand off / close:**
   - continuing → `./bin/tick release RELAY-COST --to <other>`.
   - approving (Reviewer) → set `STATUS: Approved` here **and** `./bin/tick done RELAY-COST --agent <you>`.
6. Update the `NEXT:` mirror. Do NOT git push — the harness commits file-scoped for you.

## Setup
- Artifact under review: `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md`
- Definition of Done: the cost-observability plan is sound + buildable (the 3 cost signals are
  capturable deterministically; phases 1–3 + their QA checklists are adequate; the transcript-write
  step is robust) — or the Reviewer names gaps.
- Producer: **claude-a** (main window)   ·   Reviewer: **gemini** (headless CLI)
- Independence: Reviewer is a **different model (Gemini)** — this is a genuine cross-model review,
  not a same-model dogfood.
- Started: 2026-06-15

## Ground rules
1. Single source of truth. Whose-turn = the tick `RELAY-COST` token; `STATUS` here is the terminal signal.
2. One block appended at the bottom, above the marker. Never edit earlier turns.
3. Close requires agreement: `STATUS: Approved` **and** `tick done RELAY-COST`.
4. Reviewer does not edit the artifact; only the Producer edits.

## Roles
- **Producer (claude-a)** — presents the plan; disposes findings; edits.
- **Reviewer (gemini)** — graded findings + verdict; never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a · 2026-06-15
**Presenting `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md`** for review. Context: the
`FEEDBACK-2026-06-15.md` efficacy log measured coordination (concurrency, collisions) but **no cost**
(tokens, wall-clock, human-time), so xyz and relay can't be compared on cost-per-unit-of-work. This
plan adds three cost signals to the SAME deterministic analyzer (`src/analyze.js`) and produces one
honest xyz-vs-relay comparison.

**Review focus / open questions** (also listed in the plan's "Open questions" section):
1. Is the Gemini/Codex CLI's end-of-turn token report reliable enough to log verbatim, or do we need a counting wrapper?
2. Right denominator for cost-per-unit — `tasks done` vs `passing tests` vs `files touched`? (Hardest to game wins.)
3. Is a self-reported `tick cost --human-minutes` acceptable, or do we need an operator-window proxy?
4. Comparison on the existing (asymmetric) P3 run, or a fresh fixture where both systems run the SAME task?

Also flag anything that should block starting Phase 1.
**Handing the token to gemini for review.**

### Round 1 · Reviewer · gemini · 2026-06-15
**Verdict: [Pass] with comments.** The plan is robust and the "determinism litmus" is correctly applied.

**Answers to Open Questions:**
1. **Token Source:** Use the CLI report verbatim. API-reported tokens are the source of truth for billing and limits; internal counters are approximations that inevitably drift.
2. **Denominator:** `tasks done` is the best semantic unit. To prevent gaming, the orchestrator (Claude) must define task boundaries, not the agent. Secondary metric: `tokens / passing test` for throughput efficiency.
3. **Human-minutes:** Self-report (`tick cost --human-minutes`) is acceptable for this phase. Precision is less important than directionality here.
4. **Scope:** Fresh fixture is strongly recommended. The P3 run is too asymmetric to yield a "better system" conclusion; it only yields "different costs for different work".

**Findings:**
- **[Should] Phase 2 (Edge cases):** Ensure the `tokens: partial` warning is loud. If I am the producer and I see a cost report, I need to know if it's a floor or an exact sum.
- **[Pass] Phase 1 (Checklist):** Capturing `tokens_in` and `tokens_out` separately is vital for understanding model efficiency vs context bloat.
- **[Nit] Phase 3 (Apples-to-apples):** The "load-bearing" caveat about asymmetric work should also be in the JSON output as a `run_type: asymmetric | symmetric` flag to prevent downstream scripts from comparing them blindly.

**Next steps:** Handing back to **claude-a** to finalize the plan and start Phase 1.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
