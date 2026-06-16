# RELAY · portability fixes + ROADMAP review (live Gemini CLI turn)
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN
You are the Reviewer (agent id `gemini`). Everything you need is in this file.
1. Read this whole file and the artifacts in Setup (read the real files; cite `file:line`).
2. Review against the Definition of Done. List graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`),
   each with a concrete fix.
3. Append ONE block at the very bottom, above the marker line, headed
   `### Round 1 · Reviewer · gemini`. Set a **Verdict:** (Approved | Changes requested | Blocked).
4. Review ONLY — do NOT edit the artifacts. Edit ONLY this relay file.
5. Update the header: set NEXT: Producer, and STATUS (Approved closes, else Open).

## Setup
- **Artifacts under review:**
  1. `relay-automation/relay-turn-lib.sh` — shared safety core. New: **[1]** `rtl_before` snapshots the
     pre-turn dirty set (`RTL_BEFORE`) and `rtl_enforce` skips entries that were already dirty, so the
     guard touches only the agent's OWN changes (never pre-existing ambient WIP). **[2]** `.tick/` paths
     are exempt from enforcement intrinsically (`case ... .tick/*`), independent of host `.gitignore`.
  2. `relay-automation/codex-turn.sh` — **[3]** passes `CODEX_FLAGS` (default `-s workspace-write`) to
     `codex exec` so a fresh device can actually write.
  3. `ROADMAP.md` — commercial-viability gaps G1–G5 + hardening R1–R4.
- **Definition of Done:**
  - The 3 fixes are correct and introduce **no new bypass**. Specifically scrutinize: can the
    pre-existing-dirty skip ([1]) be *abused* to evade the allowlist? (An agent makes a file look
    "already dirty" → enforcement skips it.) Is the `.tick/` exemption ([2]) safe (could an agent hide
    an off-lane write under a `.tick/`-prefixed path)? Is `-s workspace-write` ([3]) the right default?
  - ROADMAP: is the gap analysis sound and complete for commercial proof? Is **G3 (stale-writer
    fencing)** correctly called the keystone? Anything missing?
- Reviewer: `gemini`   ·   Producer: `claude-a`

---
## Log

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE  ↓↓↓ -->
