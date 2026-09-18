# RELAY · GH-700 final QA — Skills page + Model Catalog repoint (landed aa848504)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-700-final-qa-skills-page-model-catalog-repoint-landed-aa848504): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-700-PAGES-SKILLS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-700-PAGES-SKILLS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude
- Started: 2026-09-18
- Operational envelope: a static GitHub Pages site (`PAGES/`, hand-written HTML + one Python
  generator for two data pages). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/700. The plan
  (the seeded artifact) was approved in `relay-system/2026-09-18/gh700-plan-qa.md` round 3. Grade the
  **implementation on this tree** against that plan and commensurate complexity — a docs page and a
  link repoint, not a web app. Declared non-goals stand: no link checker, HTML validator, screenshot
  harness, JavaScript, or style change.
- Read on the seeded tree: the artifact (plan, esp. "Requirements → acceptance" R1–R5),
  `PAGES/skills.html` (new), the `<nav>` of each of `PAGES/{index,use-cases,how-it-works,faq,other-apps-tools,contact}.html`,
  `utils/py/site_build.py:36-47` (`NAV`), `PAGES/sitemap.xml`, the Model Catalog card in
  `PAGES/other-apps-tools.html`, and the top `CHANGELOG.md` entry. Content source for accuracy checks:
  `skills/{workhorse,unstuck,merge-cleanup,radar,whack-a-mole}/SKILL.md`.
- Definition of Done — the implementation passes if:
  1. **R1–R5 hold on this tree.** Re-run each acceptance probe from the plan (you may run them
     read-only; quote command + output). R5 (local render) is `[Unverified — needs clone run]` unless
     you can measure it read-only.
  2. **Content is accurate to the SKILL.md sources.** Spot-check at least: workhorse's 7 rungs
     (0–6), unstuck's 4 tripwires and 5 rungs, merge-cleanup's 7 phases and exit-code meanings
     (0 / 2 / 3), radar's 21-day window and "score below 5 on two consecutive runs", whack-a-mole's
     churn weights (reopens ×3, repeat fixes ×3, reverts ×4, size ×1, comments ÷5, days open ÷7).
     Cite `file:line` for any misstatement.
  3. **Nav parity and house style.** The Skills link sits after "How it Works" in every nav, including
     the two generated pages; `skills.html` uses only classes that exist in `assets/style.css`
     (`.card`, `.table-wrap`, `table`, `pre`, `.page-intro`); no CSS or JS was added.
  4. **No duplicate writer or scope creep.** Only `NAV` changed in `site_build.py`; the generated
     pages were regenerated, not hand-edited; nothing outside the plan's "Smallest affected surface"
     changed (CHANGELOG entry allowed).
  5. **Model Catalog card** links `https://resolve.hiqs.ai/` as the primary action with the GitHub
     repo as secondary; copy describes a resolver.
  PASS only when no [Blocker] remains. A [Should] that expands scope beyond the issue is out of
  envelope; the Producer may decline it with a disposition.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
