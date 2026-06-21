# RELAY · PDDA design + implementation review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (READ the real files listed; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings to THIS relay file.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Commit only the files you touched** (this relay log): `git commit -m "relay(pdda-review): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review — Noel's **PDDA (Project-Driven Doc Automation)** design + its first implementation. READ all of these:
  - **Design doc:** `PROJECT/PDDA.md` (the contract: lifecycle folders, required frontmatter, the exact two-column `## Status` table, QA-gate requirement, hardcoded-path ban, hourly schedule, output contract).
  - **Implementation (deterministic checks):** `utils/pdda-lib.sh` (shared helpers), `utils/pdda-run.sh` (aggregate runner), `utils/pdda-check-frontmatter.sh`, `utils/pdda-check-status-table.sh`, `utils/pdda-check-hardcoded-paths.sh`, `utils/pdda-stale-working-docs.sh`.
  - **Activity log sample:** `PROJECT/PDDA-ACTIVITY.jsonl` (the append-only artifact the scripts emit).
- Definition of Done: (a) **Design↔implementation fidelity** — each shipped script actually implements the "Minimum behavior" its section in `PDDA.md` specifies; (b) **script correctness/robustness** — bash hygiene (`set -euo pipefail`/quoting), and the tricky cases: exact `## Status` header matching incl. the alias compatibility window (ends `2026-07-31`), hardcoded-path detection without false-positives on quoted/transcript blocks, stale-doc move (4-day, dry-run/`pdda_hold` override), empty/edge inputs; (c) **gaps** — call out anything specified in `PDDA.md` but NOT implemented (e.g. the LLM `pdda-doc-ready.sh` layer, the activity-log fields, JSON-lines output contract, non-zero exit on blocking); (d) **design-doc quality** — internal contradictions, unresolved open questions that block automation, anything that would let plan rot through.
- Producer: Noel (human author of PDDA) — represented here by the orchestrator   ·   Reviewer: **agy (Antigravity CLI)**
- Handoff: cli-driven (agy)   <!-- driven by relay-automation/relay-drive.sh + agy-turn.sh -->
- Started: 2026-06-20

## Ground rules
1. This file is the single source of truth. The agents are different tools (Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`/`STATUS` at the top.
4. Stay tight. Findings are graded bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes; it appends them to THIS file only.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. The Reviewer posts a Verdict. Relay ends on **Approved**; else the orchestrator carries the findings back to Noel.
8. End your turn by committing it: `relay(pdda-review): <role> r<N>`. No push.
9. **One actor at a time.** The `PDDA-TURN` tick token is the lock.
10. **Evidence:** the scripts ARE runnable — prefer `behaviorally proven` (you ran a script against a fixture) over `textual only` where you can; otherwise say `textual only`.

## Roles
- **Producer** — Noel (author of the PDDA design + scripts).
- **Reviewer** — agy. Reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · noel (via orchestrator) · 2026-06-20 21:40 PDT
**Did:** Drafted the PDDA design doc (`PROJECT/PDDA.md`) and a first cut of the deterministic hygiene layer under `utils/`: `pdda-lib.sh` (shared helpers), `pdda-run.sh` (aggregate runner), and the four checks — `pdda-check-frontmatter.sh`, `pdda-check-status-table.sh`, `pdda-check-hardcoded-paths.sh`, `pdda-stale-working-docs.sh`. Activity is logged to `PROJECT/PDDA-ACTIVITY.jsonl`.
**Review this:** Does the implementation faithfully deliver what `PDDA.md` promises, and is each script correct and robust? Specifically: (1) does the status-table check enforce the EXACT headers + the alias window correctly? (2) is the hardcoded-path check resistant to false-positives on quoted/transcript blocks? (3) does the stale-doc mover honor a dry-run + `pdda_hold` override, and is the 4-day cutoff right? (4) is the JSON-lines/output + non-zero-exit contract from `PDDA.md` actually implemented? (5) what's specified but NOT yet built (e.g. the LLM `pdda-doc-ready.sh` layer)? (6) any design-doc contradictions or open questions that block reliable automation?
**Verification:** N/A from the producer side this round — this is a review request; the reviewer should run the scripts where feasible.
**Open questions:** The 4 "Open questions" at the bottom of `PDDA.md` (gh_issue requiredness, compat-window length, activity-log rotation, project-local roadmap) — flag which ones actually block a stable v1.
**Commit:** (artifact files are Noel's working tree, uncommitted by design — review them on disk)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
