# RELAY · GH-700 plan QA — Skills page on the Pages site + Model Catalog repoint
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh-700-plan-qa-skills-page-on-the-pages-site-model-catalog-repoint): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-700-PAGES-SKILLS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-700-PAGES-SKILLS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy (Codex at usage limit until 2026-09-19 01:26)   ·   Producer: claude
- Started: 2026-09-18
- Operational envelope: a static GitHub Pages site (`PAGES/`, hand-written HTML + one Python
  generator for two data pages). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/700. Grade
  against the stated requirements and commensurate complexity — this is a docs page and a link
  repoint, not a web app. Do not ask for a link checker, HTML validator, screenshot harness, JS,
  or a test framework for static HTML; those are declared non-goals.
- Read on the seeded tree: the artifact (the plan), `SOP.md` → "The project website (GitHub Pages)",
  `utils/py/site_build.py:1-60` (docstring + `NAV`), `PAGES/other-apps-tools.html`,
  `PAGES/sitemap.xml`, `.github/workflows/pages.yml`, and one static page's `<nav>` (e.g.
  `PAGES/how-it-works.html:13-28`). The content source is `skills/{workhorse,unstuck,merge-cleanup,radar,whack-a-mole}/SKILL.md`.
- Definition of Done — the plan is sound if:
  1. **Recon is grounded.** Every claim in the plan's "Recon" section matches the seeded tree
     (static vs generated split, the two nav writers, sitemap not generated, the deploy trigger,
     no tests pinning `PAGES/` or `NAV`). Cite `file:line` for any claim you dispute.
  2. **Nothing is missed.** The requirements table R1–R5 covers the issue's scope; name any
     page, file, or step the issue asks for that the plan omits (e.g. a static page with a nav
     the plan does not list, or a sitemap/`lastmod` detail).
  3. **Existing subsystem, no duplicate writer.** Adding the nav tuple to `site_build.NAV` and
     hand-editing the static navs is the repo's documented convention; confirm the plan does not
     introduce a second nav source, a new generator responsibility, or a style change.
  4. **Acceptance checks are falsifiable.** Each R1–R5 check would actually fail today (red
     control) and pass only when the requirement is met; flag any check an empty or wrong
     output would satisfy.
  5. **Rating is grounded.** `rated 55/20/50/95` (pri/sev/appeal/effort — effort scores
     cheapness): severity and priority follow from a missing page + stale link with no defect;
     appeal is neutral (no operator preference stated); effort reflects hours of static HTML.
     Say if any axis is unsupported by the evidence.
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

### Reviewer (agy, Round 1)

swept file: yes

- [Blocker] Recon is not grounded (false claim about table styling).
  - The plan claims "No table styling exists — use `.card-grid` for the picker and `<ul>` for lists instead of `<table>`."
  - This contradicts `PAGES/assets/style.css:219` which defines `table { ... }` and `PAGES/how-it-works.html:134` which uses a natively styled `<table>`.
  - Fix: Update the Recon to acknowledge existing table styling, and allow the use of `<table>` for the picker if appropriate.
  - Observed input: `No table styling exists...` in Recon.
  - Affected scope: Implementation of the symptom->skill picker markup.
  - Falsifier: `grep 'table {' PAGES/assets/style.css` returns a match, proving the style exists.

- [Blocker] R2 acceptance check is not falsifiable / fails on red control.
  - The check `grep -L 'href="skills.html"' PAGES/*.html` is claimed to print "only `issues.html`".
  - However, `PAGES/googlea4ea1e510b018714.html` also lacks a nav and will be printed by this command, causing the check to falsely fail.
  - Fix: Update the R2 acceptance check to account for `googlea4ea1e510b018714.html` (e.g., state that it prints both `issues.html` and `googlea4ea1e510b018714.html`).
  - Observed input: `grep -L 'href="skills.html"' PAGES/*.html prints only issues.html`
  - Affected scope: R2 acceptance check.
  - Falsifier: Running the command today outputs both `PAGES/issues.html` and `PAGES/googlea4ea1e510b018714.html`.

- [Should] R3 acceptance check is incomplete.
  - Requirement R3 includes "other-apps-tools.html lastmod bumped", but the acceptance check `grep -c skills.html PAGES/sitemap.xml = 1` only verifies the new file insertion.
  - Fix: Add a check for the lastmod bump on `other-apps-tools.html` (e.g., verify its date changed in `PAGES/sitemap.xml` or use a `git diff` check).
  - Observed input: R3 acceptance check missing lastmod validation.
  - Affected scope: R3 acceptance check.
  - Falsifier: If the producer forgets to bump the lastmod of `other-apps-tools.html`, the current R3 check would still pass.

- [Nit] Incorrect line numbers in Recon.
  - The plan claims `NAV` is at `utils/py/site_build.py:44-54`.
  - It is actually at `utils/py/site_build.py:36-46`.
  - Fix: Update the line numbers in the Recon section.

- [Nit] R1 acceptance check could be more precise.
  - The check `grep -c 'skills/[a-z-]*/SKILL.md' PAGES/skills.html` matches relative paths, which would 404 on the live site since `skills/` is not in `PAGES/`.
  - Fix: Consider updating the regex to ensure it matches the absolute GitHub URL (e.g., `https://github.com/.*/skills/[a-z-]*/SKILL.md`).

- [Pass] Static vs generated split matches `SOP.md` and `utils/py/site_build.py:16-17`.
- [Pass] Nav parity requirement matches the repo's convention (two writers: `utils/py/site_build.py:36` and static html files like `PAGES/other-apps-tools.html:16`).
- [Pass] Sitemap is static (confirmed via `PAGES/sitemap.xml:2-3` having `lastmod` and no builder reference).
- [Pass] Deploy trigger matches `.github/workflows/pages.yml:5`.
- [Pass] R4 repoint of the Model Catalog card accurately targets the existing link at `PAGES/other-apps-tools.html:36` (`https://github.com/HiQS-Labs/Model-catalog`).
- [Unverified — no citation] Rating is grounded (Pri 55, Sev 20, Appeal 50, Effort 95).

VERDICT: PARKED
Basis: The plan correctly identifies the affected surface and implementation steps, but contains a grounded recon failure regarding table styling that restricts implementation options, and the R2 acceptance check is broken because it overlooks the Google verification HTML file.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
