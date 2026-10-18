# RELAY · GH-1157 plan QA: skills-army-hq hard rules first (prose-only SKILL.md)
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
6. **Commit only the relay file** (`relay(gh1157-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1157-SKILLS-ARMY-HARD-RULES.md` (the plan). Read with it:
  `skills/3-weekly/skills-army-hq/SKILL.md` (the file the plan changes, unchanged so far),
  `skills/3-weekly/skills-army-hq/scripts/intake.py` and `scripts/sync.py` (what the prose claims
  about them must be true), `utils/ci-route.sh` (gate routing claim), `AGENTS.md` → *No new tests*.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the plan's **Asks / acceptance criteria** section (items 1–7) is implementable
  as a prose-only, single-file change; every factual claim the new prose will make about the scripts
  is true of the code at this revision; the plan names the existing subsystem it extends, explicit
  non-goals, an Easy rollback, and a verification scope that adds no test (GH-831); the four-axis
  rating rationale is grounded.

## Review packet

**Goal.** Pre-implementation QA of the plan for GitHub issue #1157: put a "Hard rules (read first)"
block and a "Definition of done" at the top of the Skills Army HQ skill instructions so agents stop
hand-editing the deployment collection, stop forcing refusals through, run status first/last, resolve
the per-device root and canonical before acting, and apply renames/retirements per device.

**Operational envelope.** A documentation-only change to one `SKILL.md` in a local developer
toolkit. The deployment tool is two Python scripts run by hand or by an agent on a single Mac. Grade
against this envelope and the plan's stated non-goals; do not ask for enterprise fail-safes, new
scripts, hooks, device configuration, or tests (the repo forbids new tests — a request for one is a
finding against the request).

**Non-goals (already decided, out of scope here).** Script changes (receipt-stale detection, receipt
refresh — #1157 rung 4); Git Pulse Sync post-pull hook (rung 3); device config on any machine;
publisher policy (#961); status exit-code semantics (#958); downstream child publication; any device
repair.

**Questions — answer each with a grade and a citation:**

1. **Factual claims about the scripts.** The plan asserts: (a) `intake.py --apply update` copies and
   commits with no drift gate and app links expose the bytes immediately, so `sync.py`'s later drift
   refusal cannot roll a downgrade back; (b) there is no supported stale-receipt refresh — `catalog`
   only `setdefault`s and an identical `update` returns `Unchanged` before rewriting the receipt;
   (c) `sync.py --status` never compares a receipt digest with the deployed bytes; (d) a symlinked
   collection root is refused by `intake.py`. Are all four true at this revision? Cite `file:line`
   for each, or name the one that is false.
2. **Routing claim.** The plan says this `SKILL.md` is a docs surface, tier 1, because
   `utils/ci-route.sh`'s `is_docs_surface()` matches `*.md` before the subsystem mapping. True?
3. **Suites.** The plan says no suite pins this file's text (gh620 and `test_deploy_skills.py` assert
   existence only). Is there any suite, fixture or mini-sync check that this prose change would break?
4. **Contradictions.** Would any of the five rules or the Definition of done contradict an existing
   section of `SKILL.md` (notably "Immediate symlink read-through boundary", the GH-672 SOP, the
   drift-guard section, or the GH-1046 provenance prose)? Name the sentence pair if so.
5. **Over-reach.** Does any proposed rule overstate what the scripts enforce, or require an agent to
   manufacture a clean provenance report to finish a documentation-only task? (The plan deliberately
   says a stale receipt is a valid reported partial result.)
6. **DRY / smallest surface.** Is anything in the plan a parallel subsystem, duplicated prose, or
   avoidable scope? Is the fold-in of the existing line-45 sentence the right dedupe?
7. **Verification.** Is the stated verification (docs gate `pdda.sh run`, `releases check`, a
   read-only frontmatter parse with the tooling's own reader run with `python3 -B` from a scratch
   copy, and a red control that removes `name:`) sufficient and commensurate? Does it add a test?
8. **Rating.** Is `rated 60/55/50/90` grounded in the stated consequence and recurrence evidence,
   with appeal left neutral (no operator preference was given)?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Write graded findings with
`file:line` citations, declare `swept file: yes|no`, set a VERDICT and Basis, and set `STATUS: Approved`
if the plan passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
