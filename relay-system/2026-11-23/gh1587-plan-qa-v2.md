# RELAY · GH-1587 Plan QA v2 (Operator Option 1 — GH-681 Prose-Pin Scope)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-plan-qa-v2): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: Following operator authorization of **Option 1 (Ponytail / GH-681 precedent)** after `relay-system/2026-11-23/gh1587-plan-qa.md` escalated solely on skill-prose behavioral A/B testing, verify that `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` honestly scopes skill-prose additions (`review-code-xyz`, `review-pr-xyz`, `start-task`) to Layer A deterministic red-on-base/green-on-candidate pin suites (making NO unproven behavioral LLM detection claim for prose, per `test/gh681-reviewer-probe-rules.sh:17`), keeps Layer B live execution focused on GH-836 `test/relay-self-sufficiency.sh` + one `new-relay.sh`-scaffolded Form 2 `Clone probe:` Reviewer+Producer turn (working + errored/unavailable probe paths), and preserves all previously passed controls (final-head ordering before Final QA, 4-field `WORKTREE-SAFETY.md:504-505` clone identity, persisted `85/80/50/70` rating, GH-831, GH-308, and merge-parent rollback).
- Operational Envelope: Local XYZ-forge skill docs, relay turn prompts, marathon brief, packaged tarball, and in-place existing pin suites. Operator explicitly rejected a multi-class LLM A/B harness as disproportionate machinery (`/ponytail`); do not request one.
- Paraphrase-First Step (GH-1414): Before reading source files, write 2–5 sentences each under `**What this proposes**`, `**How the existing system works, per this document**`, and `**What it's not**` (input boundary: plan artifact only), then provide `**Source-backed technical validation**`.
- Plan QA v2 Questions:
  1. Does the Acceptance Map cleanly and honestly separate Layer A prose-pin verification (with zero behavioral LLM claim for prose) from Layer B live relay/harness execution (`relay-self-sufficiency.sh` + scaffolded Form 2 `Clone probe:` Reviewer+Producer turn)?
  2. Are all previously passed gates intact (final-head ordering before Final QA, 4-field clone identity, persisted row `rmi-01M859AVNYRXE06BH6A6QH6F5E` `85/80/50/70`, Form 1/Form 2 closure rules, GH-831, GH-308, merge-parent rollback)?
  3. Is the plan ready for `STATUS: Approved` so implementation can begin after `--accepted-start`?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
