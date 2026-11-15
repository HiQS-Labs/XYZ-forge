# RELAY · GH-1484 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1484-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`. This is a **plan review**: the skill file has not been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: one new markdown skill file (`skills/3-weekly/connect-the-dots/SKILL.md`), one sentence added to `skills/3-weekly/dry/SKILL.md`'s description, one `ARCHITECTURE.md` row. Read-only, advisory skill; no code, no script, no runtime path. Grade against the stated requirements and commensurate complexity; do not ask for scripts, new test suites (AGENTS.md *No new tests*, GH-831) or enterprise machinery.
- Out of scope: child-repo publishing, device deployment, automatic wiring into other skills.
- Definition of Done: the plan's claims are grounded in the cited paths; it meets `skills/README.md` "Mode before skill"; the planned skill would do what the requirements ask; and each acceptance check would fail on an unchanged or wrongly built candidate.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc (`PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`). Do not open source files, the requirements below or the issue yet. Then, at the top of your review block, write:
- **What this proposes** (2-5 sentences)
- **How the existing system works, per this document** (2-5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections, separate excluded from deferred work, and label any inference)
- **Input boundary:** list what you had read when you wrote the paraphrase.

### Step B: source-backed validation. Now read the requirements and the sources.
Requirements (operator's words): "I want to create a new weekly skill called 'connect-the-dots' that looks at a problem by actually looking at the existing codebase. Preferably it would take advantage of an existing codebase graph or index or code RAG first rather than grepping. If there's a certain new problem or feature, it should look for existing modules that can be adapted and re-used. … I've been struggling with trying to figure out how to get the outer loop for the software flywheel outer loop going and the AI systems never suggested looking at the existing tick kernel or ATE/fuzer. This is similar and complementary to the 'ponytail' skill but at a higher 30k feet level strategic perspective." Also: "related to 'sanity-check' as well."

Recorded decisions (settled unless you bring new evidence): a separate skill rather than a `recon` mode (reason in the plan's "Mode before skill" table; a prior consult's dissent is recorded on issue #1484); tier `3-weekly` is the operator's stated choice.

Sources: `skills/README.md`, `skills/1-hourly/recon/SKILL.md`, `skills/1-hourly/ponytail/SKILL.md`, `skills/1-hourly/sanity-check/SKILL.md`, `skills/1-hourly/triangulate/SKILL.md`, `skills/1-hourly/better-options/SKILL.md`, `skills/3-weekly/dry/SKILL.md`, `skills/4-occasional/swe-diagram/SKILL.md`, `ARCHITECTURE.md` (Skills Index), `ROUTER.md` (Routing hints), `test/gh589-skill-viewer.sh`, `mini/skills/skill-viewer/scripts/list_skills.py`, `utils/ci-route.sh`, `AGENTS.md` (sections 6 and *No new tests*).

Questions (cite `file:line`; label this part **source-backed**):
1. Are the plan's Recon claims accurate against the cited paths? Name any that are wrong.
2. Is any operator requirement missing from the plan, or narrowed by it?
3. For each plan step, what prevents an unchanged or wrongly written candidate from being reported as delivered, and which acceptance check observes the rejection? Is the manual red/green pair plus rubric control a sound red control here, and what artifact does each check observe?
4. Does the plan extend what exists (cited ladders, existing index row, existing suite) without a duplicate ladder, script or writer?
5. Is the one-sentence edit to `dry`'s description enough to settle the shared phrase "is this already implemented somewhere", or does it leave both skills firing?
6. Is the rating (`55/35/50/85`) grounded, with appeal neutral and no invented recurrence claim?
7. Anything over- or under-built for a single markdown skill?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
