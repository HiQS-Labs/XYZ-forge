---
gh_issue: 1016
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
title: "releases ledger: bare repos.slug from the folder name never matches a differently named GitHub repo, so wave_reconcile silently skips every roadmap row"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-10
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1016: bare repos.slug never matches a differently named GitHub repo

## Ask

- `releases init` records the folder basename as `repos.slug`. `resolve_roadmap_identity`
  (`utils/py/releases_app.py`) accepts a bare slug only when it is byte-equal to the origin's repo
  name, so a ledger in a folder named `aegis-sleuth-slack-bot` with origin
  `HiQS-Labs/AEGIS-Sleuth-Slackbot` resolves `identity_valid False` for every row.
- `wave_reconcile.update_roadmap_entry` then logs "No qualified owned roadmap row" and skips every
  ledger move, while the reconcile reports success for doc moves.
- Proposed in the issue: (1) record the owner/name slug at init from origin; (2) a receipted repair for
  existing ledgers; (3) optionally a case/separator-tolerant bare match when exactly one repo row exists.

## Acceptance (from the issue)

- An AEGIS-shaped ledger (bare `aegis-sleuth-slack-bot`, origin `HiQS-Labs/AEGIS-Sleuth-Slackbot`)
  resolves its own rows `identity_valid True`.
- A foreign-repo row stays invalid.

## Rating (2026-10-10)

`rated 70/60/50/70` (pri/sev/appeal/effort; calc 250; no `ovr`), written with `roadmap rate` and read back
from `releases.db`.

- **Severity 60.** Every ledger move is skipped silently in any repo whose `repos.slug` is a bare name
  that differs from its GitHub repo name. No data is lost, and rows can be fixed by hand with
  `roadmap update` / `roadmap repoint` (done for AEGIS GH-221 and GH-225). Silent failure and a
  downstream `marathon-plan` exit 6 push it above a cosmetic defect, but it stays below the crash and
  corruption band.
- **Priority 70.** It blocks the post-merge reconcile in HiQS-Labs/AEGIS-Sleuth-Slackbot today:
  GH-215 and GH-217 are still "In progress" after closing. XYZ-forge and LTVera-Pandas are
  unaffected only because their folder names equal their repo names.
- **Appeal 50.** Neutral; the operator gave no preference.
- **Effort 70.** Recon shows one resolver line and one `cmd_init` default (plus the onboard script's
  slug default), with no schema change and no rewrite of stored rows.
- **Recurrence.** Window 2026-09-26..2026-10-10 compared with 2026-09-12..2026-09-25. One distinct
  incident (#1016, AEGIS). `gh search` for "No qualified owned roadmap row" and "identity_valid"
  found no earlier report. The bare-slug guard dates from the GH-646 identity work, so the defect
  may have been latent since then. Trend unknown: this is the first report.
