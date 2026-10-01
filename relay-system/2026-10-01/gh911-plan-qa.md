# RELAY · GH-911 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
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
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh911-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-911-WORKHORSE-DIRECT-REENTRY.md` (the plan). Read it in full,
  plus the code it changes: `skills/2-daily/workhorse/SKILL.md` (whole file), and for context
  `test/gh609-sdlc-agent-gaps.sh` (pins workhorse strings) and `AGENTS.md` "No new tests" (GH-831).
  Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/911
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- **Operational envelope:** a skill text edit plus one ~30-line local Claude Code Stop-hook script for a single
  operator's sessions. Grade against the five approved asks and commensurate complexity. Do NOT ask for a
  governor role, progress fingerprints, budget counters, a JSON run schema, new test suites, or multi-tenant
  threat models — those are explicit non-goals.
- **Definition of Done (plan QA):** the plan, if implemented as written, delivers the five asks; every claim
  about current code is grounded in the cited `file:line`; it extends existing text/subsystems rather than
  duplicating them; verification is falsifiable (red + green controls) within GH-831.

**Questions:**
1. Are the plan's `SKILL.md:line` claims accurate (L66, L68, L164, L242, L250-256, L262-267)? Cite any mismatch.
2. Does moving "Report & Close" to end-of-run plus the run-checklist re-entry clause actually remove the
   per-item stop point, without weakening the #626 orchestrator `--resume` contract?
3. Is the Stop hook design sound for its envelope? Specifically: session-scoped filename, fail-open on
   every error, block only on `- [ ]` lines, `[!]`/`[-]` escape, reliance on the documented 8-continuation cap.
   Can it ever trap a session or fire in a session that never ran `/workhorse`?
4. The frontmatter hook command tries `$CLAUDE_PROJECT_DIR/.claude/skills/workhorse/stop-hook.sh` then
   `$HOME/.claude/skills/workhorse/stop-hook.sh` (docs: `${CLAUDE_SKILL_DIR}` is not substituted in hook
   commands). Is that resolution correct for this repo's install paths (`install.sh`, Skills Army deploy)?
5. Is the widened Rung 4 skip bounded tightly enough (still mandatory for architecture, contracts, state,
   dependencies, Costly/One-way-door)? Is the Rung 5 sentence consistent with the rest of Rung 5?
6. Is anything missing from the verification matrix, or anything there that violates GH-831?
7. Is anything over-engineered for the envelope? Flag it.

Cite `file:line` for every disagreement. Set STATUS: Approved if the plan passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
