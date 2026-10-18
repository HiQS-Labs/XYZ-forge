# RELAY · GH-1139 Plan QA — todo-list daily skill delegating 10x10m wake loop to handsfree
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh-1139-plan-qa-todo-list-daily-skill-delegating-10x10m-wake-loop-to-handsfree): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md** in the committed checkout; also inspect `skills/1-hourly/handsfree/SKILL.md` and `ARCHITECTURE.md` (`### 2-daily`).
- Reviewer: codex   ·   Producer: agy-producer
- Started: 2026-10-18
- Definition of Done: Surgical, DRY plan for the Markdown-only `todo-list` daily skill (`skills/2-daily/todo-list/SKILL.md`) that extracts the preceding assistant list into an ordered checklist and delegates the 10x10m watchdog wake loop to `handsfree` via a small subroutine-override clause, with grounded ratings (`65/20/50/85`), bounded docs-tier verification (`pdda.sh run` + `gh778`/`gh798` index checks), and no new CI tests (`AGENTS.md` GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer (agy-producer) · Plan QA Request

Review `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md` alongside `skills/1-hourly/handsfree/SKILL.md` and `ARCHITECTURE.md:72-98`.

**Operational Envelope (Commensurate Complexity):**
This is a lightweight, Markdown-only daily skill (`skills/2-daily/todo-list/SKILL.md`) plus a 1-paragraph caller-override clause in `skills/1-hourly/handsfree/SKILL.md` and a 1-row index addition in `ARCHITECTURE.md`. Grade strictly against the stated operator requirements and commensurate complexity — do not demand scripts, daemons, new CI test files (forbidden by `AGENTS.md` GH-831), or enterprise multi-tenant machinery.

Please evaluate:
1. Are the recon claims grounded in the actual repo paths (`skills/1-hourly/handsfree/SKILL.md`, `ARCHITECTURE.md`, `utils/ci-route.sh`, `test/gh778-review-code-skill.sh`)?
2. Are all operator requirements covered (numbered todo list from the list above, remembered in chat/native task tool + gitignored `temp/todo-list-YYYY-MM-DD-<session-token>.md`, executed in recommended order immediately, `10 x 10 minutes` = 100-minute / 10-iteration watchdog timer delegated to `handsfree` with early cancel on completion/blocker, PR-only without local deployment)?
3. Does the plan cleanly extend the existing `handsfree` skill rather than duplicating per-harness scheduler instructions?
4. Are blast radius, rollback, falsifiable verification checks (including a witnessed red control on `test/gh778-review-code-skill.sh` and the `pdda.sh run` docs gate), and the `65/20/50/85` RELEASES rating + recurrence check sufficient?

Do not run `validate.sh`, `pytest`, or mutating git commands. Append one reviewer block with `swept file: yes`, cited findings, `VERDICT: PASS|FAIL|PARKED`, and `Basis:`. If approved, set header `STATUS: Approved` and `NEXT: —`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
