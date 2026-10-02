# RELAY · GH-927 sanity-check skill and sibling logic QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
6. **Commit only the relay file** (`relay(gh-927-sanity-check-skill-and-sibling-logic-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/sanity-check/SKILL.md`, `skills/3-weekly/whack-a-mole/SKILL.md`, `skills/3-weekly/radar/SKILL.md`
- Reviewer: claude-fable   ·   Producer: codex-producer
- Started: 2026-10-02
- Definition of Done: The operator requirements and QA questions below are satisfied without new runtime machinery or unauthorized side effects.

## Operator requirements and QA scope

Review the entire sanity-check skill and the entire two sibling files, including the inserted pointers (compare with origin/development). Reference skills: recon, debug-mantra, ponytail, triangulate and start-task rating policy. Do not invoke their workflows. This is static behavioral QA of Markdown instructions for local coding agents, not a runtime incident or a request to execute any repair or audit.

Operator decisions: activate at the first blocker and deepen on stalled progress; ask about core/user-facing importance only when unclear; defer low-risk work with PRS-rated GitHub intake; propose removals or weakening of required gates. Explicitly reassess after two investigation attempts yield no new evidence before another retry. Recommend whack-a-mole and radar with appropriate scope and add reciprocal pointers. User requested Claude Code Fable at high effort for this QA.

Commensurate scope: three Markdown skill files only. No new scripts, suites, gates, or enterprise architecture. Preserve safety and the sibling skills' existing approval boundaries. Do not file issues or publish reports. Your only writable artifact is this relay thread. Do not run validation suites, fixtures or executable tests in the worktree. Do not run other agents or audits.

Questions:
1. Does the ladder distinguish a real failure, requirement value, actual dependency, and urgency without excusing necessary correctness/security/integrity controls?
2. Is the two-attempt trigger unambiguous and bounded without abandoning high-risk unknowns or allowing endless ritual reassessment?
3. Are PRS axes, uncertain severity, operator overrides, deduplicated issue intake and public-issue redaction coherent with existing policy?
4. Are whack-a-mole/radar recommendations specific, proportionate, nonrecursive, and consistent with their independent authorization boundaries? Identify any pre-existing text in those files that defeats the new pointers.
5. Work through these scenarios as written and report the disposition, question (if needed), and allowed next action: a wording-only CI assertion after a prose edit; the sole transaction-integrity guard failing; an advisory unsupported-platform canary; two inconclusive probes of a credible exposure; recurring fixes across distinct issues; and a broad repair-churn report that sends a previously assessed blocker back to sanity-check. Do not actually perform those actions.
6. Are instructions overly long, contradictory, missing a material step, or likely to launch irrelevant work? Recommend only concrete corrections justified by this scope.

Cite file:line for findings. Give observed instruction/input, affected scope and falsifier for each behavior-change finding. Distinguish static scenario walkthroughs from executed tests. Report whether pre-existing contradictions affect this change, without expanding into an unrelated rewrite.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
