# RELAY · GH-927 sanity-check independent GLM QA
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
6. **Commit only the relay file** (`relay(gh-927-sanity-check-independent-glm-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/sanity-check/SKILL.md`, `skills/3-weekly/whack-a-mole/SKILL.md`, `skills/3-weekly/radar/SKILL.md`
- Reviewer: commandcode   ·   Producer: codex-producer
- Started: 2026-10-02
- Definition of Done: The operator requirements and review questions below are satisfied by the current Markdown instructions.

## Operator requirements and review questions

Provide an independent QA assessment of the current three skill files. Read them
in full; compare their diff to origin/development. Do not use the prior reviewer
verdict as evidence. The user selected Command Code, zai-org/glm-5.3, max effort.

Operational envelope: Markdown-only instructions for local coding agents. No new
scripts, suites, runners, or gates. This review is static behavioral QA, not a
request to run the skills, repair a live incident, file issues, or publish reports.
Only this relay file is writable. Do not run mutation-heavy suites, executable
fixtures, other agents, or broad audits from the review worktree.

Requirements: sanity-check assesses the first blocker, deepens on stalled
progress, asks about a core/user-facing capability's importance only when unclear,
and separates the reality of a failure from its necessity and urgency. Reuse
recon, debug-mantra, and ponytail. It may defer demonstrated low-risk work with
PRS-rated GitHub intake; feature retirement or weakening a required gate needs a
concrete operator decision. After two investigation attempts yield no new
evidence, reassess before another retry. Recommend whack-a-mole/radar when their
scope fits and add reciprocal operator-facing pointers without recursive audits
or inherited publication authority.

Read the relevant reference sections in recon, debug-mantra, ponytail,
triangulate, ci-suite-audit and start-task's rating policy as needed; do not
execute those workflows. Apply commensurate complexity: ask only for concrete,
material corrections, not speculative enterprise controls or extra machinery.

1. Does the decision ladder distinguish real failure, requirement value, current
   blocker, severity, and priority without masking an integrity/security risk?
2. Is the two-attempt reassessment rule actionable and bounded? Can it become an
   excuse to abandon a necessary repair or repeat the same assessment forever?
3. Are uncertainty, operator importance questions, residual risk, existing gates,
   reversible containment and retirement decisions handled consistently?
4. Does deferred-work intake reuse PRS correctly (four axes, cheapness direction,
   neutral appeal, preserved overrides, deduplication, redaction), without
   lowering severity to justify scheduling?
5. Are the recommendations and reciprocal pointers consistent with the full
   whack-a-mole/radar instructions, including priority and approval rules? Does
   an assessment of one cluster member improperly govern a wider cluster?
6. Walk through: a wording-only required gate after an authorized prose change;
   the sole transaction-integrity guard failing; an advisory unsupported-platform
   canary; two inconclusive probes of credible exposure; a low-risk member of a
   broader recurring cluster; and a Radar handoff on unchanged evidence. State
   disposition, any operator question, and allowed next action. Label these as
   static walkthroughs, not executed tests.

Cite exact file:line or quoted text. Each behavior-change finding needs Observed
input, Affected scope and Falsifier; a Blocker must cite an observed failure.
Report all material findings, distinguish pre-existing unrelated limitations,
and give PASS/FAIL/PARKED. A missing citation is not a verified finding. Existing
metadata validation reports Radar's unchanged 1336-character description above
the validator's 1024-character maximum; this limit predates the added pointer.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
