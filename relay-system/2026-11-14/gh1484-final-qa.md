# RELAY · GH-1484 final QA
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
6. **Commit only the relay file** (`relay(gh1484-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation of GH-1484: `skills/3-weekly/connect-the-dots/SKILL.md` (new), the description change in `skills/3-weekly/dry/SKILL.md`, the new row in `ARCHITECTURE.md`, the plan `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`, and the evidence in `TESTS-RESULTS/2026-11-14+GH-1484/` (start with its `README.md`). Diff base: `5967bde25` (`git diff 5967bde25..HEAD`, read-only).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: one read-only, advisory markdown skill, one sentence in another skill's description, one index row. No code, script or runtime path. Grade against the stated requirements and commensurate complexity. Do not ask for scripts, new test suites (AGENTS.md *No new tests*, GH-831; a new test file in the diff would itself be a finding) or enterprise machinery.
- Out of scope: child-repo publishing, device deployment, automatic wiring into other skills.
- Definition of Done: the delivered skill does what the requirements and the approved plan say; the evidence supports the claims made for it; nothing outside the plan slipped in.

Requirements (operator's words): "I want to create a new weekly skill called 'connect-the-dots' that looks at a problem by actually looking at the existing codebase. Preferably it would take advantage of an existing codebase graph or index or code RAG first rather than grepping. If there's a certain new problem or feature, it should look for existing modules that can be adapted and re-used. … the AI systems never suggested looking at the existing tick kernel or ATE/fuzer. This is similar and complementary to the 'ponytail' skill but at a higher 30k feet level strategic perspective." Also: "related to 'sanity-check' as well."

Settled decisions: separate skill rather than a `recon` mode; tier `3-weekly` (operator's choice). Plan QA: `relay-system/2026-11-14/gh1484-plan-qa.md` (Approved, round 2).

One deviation after plan approval, for you to judge: the red/green prompt was replaced with the operator's original wording. Reason and evidence: the plan's "Deviation recorded" paragraph and `TESTS-RESULTS/2026-11-14+GH-1484/README.md`.

Questions (cite `file:line`):
1. Does the skill text satisfy each acceptance item in the plan's `## Acceptance`? Name any item that is unmet or only partly met.
2. Does the skill match the plan: capabilities before search; maps, then index/graph/RAG, then grep, with a stated mode; cited fit table with owner and limiting constraint; "not found in these searches"; no unread candidate; ladders cited from `swe-diagram` Step 1 and `recon` Step 2 rather than rewritten? Do its relative links resolve?
3. Is the prompt deviation sound? Does the recorded red (run 2) genuinely miss, does the green (run 3) genuinely meet the rubric, and are run 3's citations correct against the source at `5967bde25`? Does the evidence support the claims the README and the skill's opening section make, and no more?
4. Read the new sentence in `dry`'s description against both meanings of "is this already implemented somewhere". Does routing now come out right, without weakening `dry`?
5. Did a duplicate ladder, script, writer, test file or registry entry slip into the diff? Is anything in the diff outside the plan?
6. Is the persisted rating (`55/35/50/85`, plan `## Rating`) still consistent with the evidence?
7. Pre-existing defects in the touched files (`dry/SKILL.md`, the `ARCHITECTURE.md` weekly table): say explicitly if you find none.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
