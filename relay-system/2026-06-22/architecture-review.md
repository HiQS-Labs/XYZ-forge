# RELAY · ARCHITECTURE.md — accuracy & clarity review (agy reviewer)
<!--
  Single source of truth for this review relay. Read this ENTIRE file before doing anything.
  Act only on your turn. Driven headless via /relay-xyz
  (relay-automation/relay-drive.sh + relay-automation/agy-turn.sh).
-->

NEXT: Reviewer
STATUS: In Progress
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent)
Everything you need is **in this file**.
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it
   (see Setup) and the last Log block isn't already yours. If not → STOP and say "not my turn."
3. **Do your role's work:**
   - **Reviewer (agy):** review the artifact named in Setup for **accuracy** (does every claim match the
     real code in `relay-automation/*.sh` and `bin/tick`?) and **clarity** (is it well-structured,
     unambiguous, free of misleading or dead statements?). Read the artifact AND the source files it
     cites before grading. **You do NOT edit the artifact** — you only write findings into THIS file.
     Cite each finding by `ARCHITECTURE.md` section/line and, where it's an accuracy claim, by the code
     file/line that confirms or contradicts it. Grade every finding (see rule 6). End with a one-line
     **Verdict**. Then hand off to the Producer (or `done` + `STATUS: Approved` if it's clean).
   - **Producer (claude-a):** disposition each `[Blocker]`/`[Should]` (Implemented / Modified / Declined +
     why), edit `ARCHITECTURE.md` accordingly, append your block with a `Verification:` line, hand back
     to the Reviewer.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; bump `ROUND` when the Reviewer opens a new cycle; set `STATUS`
   (`Approved` ends the relay).
6. **Hand off the lock** with the repo-root `tick`: `./bin/tick release ARCH-REVIEW-0622 --agent <you> --to <other>`
   (or `./bin/tick done ARCH-REVIEW-0622` on approve). The harness commits your turn file-scoped; do not push.
7. **Stop.** State your one-line result.

## Setup
- **Artifact under review:** `ARCHITECTURE.md` (absolute: `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/ARCHITECTURE.md`) — the relay-architecture reference doc.
- **Source of truth to check accuracy against:** `relay-automation/relay-drive.sh`, `relay-automation/relay-turn-lib.sh`, `relay-automation/claude-turn.sh`, `relay-automation/codex-turn.sh`, `relay-automation/agy-turn.sh`, `relay-automation/poll.sh`, `bin/tick`.
- **Focus:** ACCURACY (claims match the real code) + CLARITY (structure, wording, no ambiguous/dead statements). Flag anything aspirational stated as current, any exit code / flag / env-var that doesn't match the code, and any section a new reader would misread.
- **Definition of Done:** every `[Blocker]`/`[Should]` finding is dispositioned by the Producer; the Reviewer sets `STATUS: Approved` when satisfied.
- **Reviewer:** agy (cross-model; reviews, never edits the artifact).
- **Producer:** claude-a (the doc's author; dispositions findings and edits `ARCHITECTURE.md`).
- **Lock:** `tick` task **ARCH-REVIEW-0622** (fresh token for this run; a `done` token can't be reopened).
- **Started:** 2026-06-22

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise say "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight. Findings are bullets with evidence, not essays.
5. **The Reviewer never edits the artifact.** It reports; the Producer fixes.
6. Grade findings: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound.
7. **Evidence contract.** Each accuracy finding cites the artifact location AND the code that proves it. The Reviewer's verdict states what it read (artifact + which source files).
8. **Reconcile against the code, not assumptions.** Before grading an accuracy claim, open the cited source file and confirm.

## Roles
- **Reviewer (agy)** — checks `ARCHITECTURE.md` against the real harness code; files graded findings here; never edits the artifact.
- **Producer (claude-a)** — dispositions findings, edits `ARCHITECTURE.md`, hands back for re-review.

---
## Log

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
