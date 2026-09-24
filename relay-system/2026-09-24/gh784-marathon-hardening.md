# RELAY · PR 765 & Issue 784 Codex QA: Marathon wave QA checklist contract and mechanical receipt gate
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-24.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.**
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding, make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer (codex) — r1` or `### Reviewer — Round N (codex)`; follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh784-marathon-hardening): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifact under review: PR #765 and GH-784 marathon hardening; inspect `skills/2-daily/start-marathon/SKILL.md`, `AGENTS.md`, `PROJECT/PDDA.md`, `ROUTER.md`, `utils/pdda/check_marathon_qa.py`, `utils/pdda/pdda.sh`, `test/gh784-marathon-qa-gate.sh`, `relay-automation/hooks/skill-nudge.sh`, `test/xyz-harness-hooks.sh`, `validate.sh`, and `CHANGELOG.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: local developer CLI & repo governance; no runaway abstraction or unrequested enterprise multi-tenant machinery. Read-only review; no `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree. Use narrow static inspection and committed evidence. Keep any scratch under `.relay-scratch/` after setting `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` there.
- Definition of Done: decide whether the GH-784 hardening improvements and CodeRabbit comment resolutions are content-ready and architecturally sound. Explicitly answer:
  1. Does `skills/2-daily/start-marathon/SKILL.md` properly mandate Step 6 (Wave Plan QA) and Step 8 (Post-Build Codex QA Relay) parity per wave, and enforce the Acceptance & Quality Checklist contract?
  2. Does `AGENTS.md` clearly codify Orchestrator vs Review Protocol Separation (prohibiting orchestrators from self-attesting review by only observing passing tests)?
  3. Is `utils/pdda/check_marathon_qa.py` surgical, DRY, and robust against false positives on non-marathon docs while strictly flagging missing wave items, missing/unexpanded transcripts, and unverified checklist items on PR readiness?
  4. Are `PROJECT/PDDA.md`, `ROUTER.md`, and `utils/pdda/pdda.sh` properly updated in lockstep, and does `test/gh784-marathon-qa-gate.sh` provide falsifiable verification?
  5. Are CodeRabbit review feedback items properly addressed (skill-nudge pattern and marathon-plan.sh --check)?
  Give `VERDICT: PASS` or `FAIL` with `Basis:` and cited findings. `STATUS: Approved` only for PASS; otherwise hand back specific repairs.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
