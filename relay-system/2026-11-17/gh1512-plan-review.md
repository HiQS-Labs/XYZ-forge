# RELAY · GH-1512 whack-a-mole connect-the-dots and debug-mantra recon plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268).
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.**
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
     Every `[Blocker]` or `[Should]` requesting a behaviour change MUST carry three lines:
     `Observed input:` (the failing input you saw), `Affected scope:` (the input predicate the change would govern),
     `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected result).
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1512-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-1512-WHACK-A-MOLE-CONNECT-THE-DOTS.md**
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Definition of Done:
  (a) Plan correctly captures the two documentation edits:
      1. skills/3-weekly/whack-a-mole/SKILL.md §5: after root cause / invariant is found, run /connect-the-dots (../connect-the-dots/SKILL.md) on the invariant before proposing a new mechanism, and name any existing enforcer in the umbrella issue. Exactly one sentence plus a hand-off line; no new section.
      2. skills/1-hourly/debug-mantra/SKILL.md §2: in second mantra ("trace the fail path"), add recon (../recon/SKILL.md) as an escalation when fail path spans unread modules before forming hypothesis. Exactly one sentence in explanatory text, without altering the recited mantra block.
  (b) Strictly complies with AGENTS.md "No new tests" (GH-831) — no new test files or registry entries.
  (c) Verifies route via utils/ci-route.sh (docs-only / tier 1), runs deterministic docs gate utils/pdda/pdda.sh run, and specifies publisher suites (gh620/gh589) in a disposable -gate clone.
  (d) Commensurate complexity respected; no speculative abstractions or enterprise machinery.
  (e) Paraphrase-first comprehension (GH-1414): Reviewer begins with 2-5 sentences each under:
      - **What this proposes**
      - **How the existing system works, per this document**
      - **What it's not**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
