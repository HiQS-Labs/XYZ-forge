---
title: "GH-700: pages — add a Skills page to the project site; repoint the Model Catalog card to resolve.hiqs.ai"
status: "Proposed (1-INBOX — in execution on feat/gh700-pages-skills)"
created: 2026-09-18
updated: 2026-09-18
owner: unassigned
goal: publish the agent-driving skills (workhorse, unstuck, merge-cleanup, radar, whack-a-mole) on the GitHub Pages site with a nav entry on every page, and point the Model Catalog card at the hosted resolver
gh_issue: 700
source: https://github.com/HiQS-Labs/XYZ-forge/issues/700
doc_type: feedback
related:
  - https://github.com/HiQS-Labs/XYZ-forge/wiki/Skills-for-Driving-Stalled-Agents
  - https://github.com/HiQS-Labs/XYZ-forge/issues/461
context_tags: [pages, site, skills, docs]
non_goals:
  - No change to assets/style.css unless an element has no existing style
  - No changes to roadmap or models-harnesses data; only the NAV list in the generator
  - No new build step, JavaScript, or test framework for static HTML
  - Wiki page stays as-is; the site page is the outward copy
effort: 1
complexity: 1
risk: 1
---

# GH-700 — Skills page on the project site + Model Catalog card repoint

## Observed problem

- `PAGES/` (the live site at https://hiqs-labs.github.io/XYZ-forge/) has no page about the skills
  that drive a stalled agent; the only write-up is the repo wiki, which the site never links.
- `PAGES/other-apps-tools.html` → "Model Catalog" card links the GitHub repo; the operator wants it
  to point at the hosted resolver https://resolve.hiqs.ai/.

## Recon (base `91353ee0`, `origin/development`)

- **Static vs generated.** `SOP.md` → "The project website" and the docstring of
  `utils/py/site_build.py:1-20`: static pages are hand-edited; `roadmap.html` and
  `models-harnesses.html` are baked by `site_build.py` at deploy time and must never be hand-edited.
- **Nav has two writers today.** Static pages carry a literal `<nav>` block (9 links, e.g.
  `PAGES/other-apps-tools.html:16-26`); the generated pages get theirs from `NAV` in
  `utils/py/site_build.py:36-46`. Adding a page means editing both, or the two drift.
  `issues.html` is a redirect stub with no nav (deliberate, per SOP) — untouched.
- **Sitemap is static** (`PAGES/sitemap.xml`, 8 `<url>` rows, hand-maintained `lastmod`);
  `site_build.py` does not write it (`grep sitemap utils/py/site_build.py` → 0).
- **Deploy trigger.** `.github/workflows/pages.yml` fires on `PAGES/**` and `utils/py/site_build.py`
  pushes to `development`/`main`; it re-runs the builder, so the committed generated copies are a
  convenience snapshot.
- **House style.** `assets/style.css` styles `.card-grid`/`.card`, `pre`/`code`, `main h2/h3`,
  `.page-intro`, and `table`/`th`/`td` (`assets/style.css:219-242`, used by
  `how-it-works.html:133`); `how-it-works.html` uses `<ul>` + `<strong>` lead-ins, `use-cases.html`
  uses `.card` with `<h3>`. Use `<table>` for the symptom→skill picker and the related-skills list,
  `.card` for the five skill summaries, `<pre>` for ladders and the receipt.
- **No tests pin `PAGES/` or `site_build.NAV`** (`grep -rl site_build test/` → 0). `--check` is
  the only existing verifier and is informational.
- **No open PR touches `PAGES/`** (checked 2026-09-18); no existing issue covers a skills page.
- Content source of truth: `skills/{workhorse,unstuck,merge-cleanup,radar,whack-a-mole}/SKILL.md`
  on `development`, already distilled on the wiki page linked above.

## Requirements → acceptance

| # | Requirement | Acceptance check (falsifiable) |
|---|---|---|
| R1 | New `PAGES/skills.html` covering the five skills, a symptom→skill picker, how they chain, and a related-skills list, each linking `skills/<name>/SKILL.md` on `development` | File exists; `grep -c 'https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/[a-z0-9-]*/SKILL.md' PAGES/skills.html` ≥ 14 (5 + 9 related; absolute URLs, since `skills/` is not under `PAGES/`); page opens with the site header and `aria-current="page"` on its own nav link |
| R2 | Nav parity: **Skills** link on every static page with a nav and on both generated pages | `for f in PAGES/*.html; do grep -q 'href="skills.html"' "$f" \|\| echo "$f"; done` prints exactly `PAGES/issues.html` and `PAGES/googlea4ea1e510b018714.html` (the two nav-less files: redirect stub and Google verification token); `python3 utils/py/site_build.py --check` reports no drift after regeneration. Red control: at base the loop lists all 10 pages |
| R3 | `sitemap.xml` lists `skills.html`; `other-apps-tools.html` `lastmod` bumped | `grep -c skills.html PAGES/sitemap.xml` = 1 **and** `grep 'other-apps-tools.html' PAGES/sitemap.xml` shows `<lastmod>2026-09-18</lastmod>` (red control: `2026-09-06` at base) |
| R4 | Model Catalog card → https://resolve.hiqs.ai/ | `grep -c 'resolve.hiqs.ai' PAGES/other-apps-tools.html` = 1 (red control: 0 at base) |
| R5 | Renders locally | `python3 -m http.server --bind 127.0.0.1` from `PAGES/`; page loads, relative links resolve |

## Smallest affected surface

- `PAGES/skills.html` (new, static)
- `PAGES/{index,use-cases,how-it-works,faq,other-apps-tools,contact}.html` — one `<a>` each in `<nav>`
- `utils/py/site_build.py` — one tuple in `NAV`
- `PAGES/{roadmap,models-harnesses}.html` — regenerated by the builder (not hand-edited)
- `PAGES/sitemap.xml` — one `<url>` row + one `lastmod`
- `PAGES/other-apps-tools.html` — one card's link and copy
- `CHANGELOG.md` — iteration entry

Existing subsystem extended: the static-page convention + `site_build.NAV` (its canonical writer for
generated nav). No new writer, no new generator responsibility.

## Ordered implementation

1. Write `PAGES/skills.html` from the wiki content in house markup (`<table>` for the picker and
   related-skills list, `.card` per skill, `<pre>` for the ladders and receipt). Verify R1.
2. Insert `<a href="skills.html">Skills</a>` after "How it Works" in each static nav; add
   `("skills.html", "Skills")` at the same position in `site_build.NAV`; run
   `python3 utils/py/site_build.py` and `--check`. Verify R2.
3. Update `sitemap.xml` (R3) and the Model Catalog card (R4).
4. Serve `PAGES/` on loopback and click through (R5).
5. CHANGELOG entry; commit; relay QA; push through the pre-push gate; open PR against `development`.

## Risks / rollback

- Risk: a hand-edited nav on one static page missed → R2 grep catches it.
- Risk: regenerated pages pick up unrelated ledger drift → inspect `git diff --stat PAGES/roadmap.html
  PAGES/models-harnesses.html`; if the diff exceeds the nav line, note it in the PR (it is the deploy's
  behaviour anyway).
- Rollback: revert the single commit; the deploy workflow republishes from the previous tree.

## Test scope

- Deterministic: the grep checks in the acceptance table and `site_build.py --check`.
- Non-scope: no HTML validator, link checker, or screenshot harness is added for a static page.
- Gate: `./validate.sh --auto` in this task clone (docs-class diff); the qualifying gate is the
  pre-push hook on the final commit.

## Rating (RELEASES, 2026-09-18)

`rated 55/20/50/95` — pri 55: operator-requested, unblocks outward discoverability of the skills,
nothing depends on it; sev 20: absence causes no defect, only a missing page and a stale link;
appeal 50: neutral (no operator preference stated); effort 95: static HTML plus one generator tuple,
hours not days. Recurrence: no prior same-class issue in the last 28 days (site work: GH-461 was a
copy clarification). Uncertainty: none material.
