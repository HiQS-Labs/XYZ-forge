# RELAY · agy reliability-testing plan review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real file; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact file itself** (not this log) and confirm every prior `Implemented` fix is actually present — any missing/partial → `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line`. For a doc artifact this file check is the only backstop there is.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed** — cite the line. A claim you can't point to in the file is not done.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (this log): `git commit -m "relay(agy-reliability-plan): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push. *(The harness commits for you in headless mode.)*
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: `PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md`
- Definition of Done: The proposal is accurate, honest, and runnable — the **F1–F7 failure catalog** reflects real, observed agy behavior with correct evidence + containment (no overstatement); the **S1–S10 test matrix** is concretely runnable and each scenario maps to a catalogued failure; each phase carries a QA gate; it stays PDDA-compliant for `1-INBOX` and is graduation-ready; nothing claims more than the evidence supports.
- Producer: Claude (claude-a)   ·   Reviewer: agy (agy)
- Handoff: cli-driven (agy)   <!-- driven by relay-automation/relay-drive.sh + agy-turn.sh -->
- Started: 2026-06-21

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents are different tools (Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer decides each proposal and implements the approved ones — logging a disposition for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. To get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(agy-reliability-plan): <role> r<N>`. No push.
9. **One actor at a time, clean tree at every handoff.** The `RELAY-AGYPLAN` tick token is the lock. Never flip `NEXT` with uncommitted changes in the tree.
10. **Evidence contract.** The artifact is a non-executable doc, so the honest basis is `textual only`. The one backstop is reconciling claims against the file, not this log.

---
## Log

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE — do not write above it ↓↓↓ -->
