---
gh_issue: 1016
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1016
title: "releases ledger: bare repos.slug from the folder name never matches a differently named GitHub repo, so wave_reconcile silently skips every roadmap row"
status: "Working — final QA"
created: 2026-10-10
updated: 2026-10-10
owner: Claude
goal: "Rows in a ledger whose bare repos.slug differs from the GitHub repo name only by case or separators resolve as owned, and new ledgers record the GitHub owner/name"
branch: fix/XYZ-forge-gh1016-repo-slug-identity-2026-10-10
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Implemented and gated: manual check 15/15 (red 9/15 at base), focused suites green, full pre-push gate GREEN 406/406 in a disposable clone; branch pushed. | Codex final QA (`relay-system/2026-10-10/gh1016-final-qa.md`), then PR against development. |

## Table of contents

- [Ask](#ask)
- [Rating (2026-10-10)](#rating-2026-10-10)
- [Recon](#recon)
- [Plan](#plan)
- [Acceptance map](#acceptance-map)
- [Plan QA dispositions](#plan-qa-dispositions)
- [Implementation evidence](#implementation-evidence)

## Ask

- `releases init` records the folder basename as `repos.slug`. `resolve_roadmap_identity`
  (`utils/py/releases_app.py`) accepts a bare slug only when it is byte-equal to the origin's repo
  name, so a ledger in a folder named `aegis-sleuth-slack-bot` with origin
  `HiQS-Labs/AEGIS-Sleuth-Slackbot` resolves `identity_valid False` for every row.
- `wave_reconcile.update_roadmap_entry` then logs "No qualified owned roadmap row" and skips every
  ledger move, while the reconcile reports success for doc moves.
- Proposed in the issue: (1) record the owner/name slug at init from origin; (2) a receipted repair for
  existing ledgers; (3) optionally a case/separator-tolerant bare match when exactly one repo row exists.

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

## Recon

Base: `origin/development` @ `9a923f3c`. Line numbers are at that SHA.

**Where `repos.slug` is written.**

- `cmd_init` (`releases_app.py:2171-2205`) is the only place a slug value is created:
  `slug = args.slug or os.path.basename(os.path.normpath(root))`. It writes that one value to
  `repos(slug)` (`:2185/:2188`) and `settings.repo_slug` (`:2192/:2196`).
- `load_dump` (`:6059/:6062`) copies the slug from the dump when it rebuilds. It creates no value.
- No `UPDATE repos` exists in `releases_app.py`. `settings set` refuses `repo_slug` as identity
  (`:158`, `:3821`). So no verb can rewrite a stored slug today.
- Callers of `init`: `utils/pdda/pdda-install.sh:774` (no `--slug`, so the basename default) and
  `relay-automation/xyz-releases-onboard.sh:99-101`. The onboard script passes
  `--slug "${SLUG:-$(basename "$TARGET_REPO")}"` into a staged temp repo that has no origin. It parses
  the target's GitHub origin only later (`:106-111`, `GH_BASE`).

**Where `repos.slug` is read.**

- Every ownership decision goes through one function, `resolve_roadmap_identity` (`:5397-5406`).
  Its callers are `roadmap update` (`:3944`), `--accepted-start` (`:4067`), `:5112`, the work-state
  report (`:5493`), `utils/py/express.py:665-677`, `utils/py/work_connectors/__init__.py:144-164`, and
  `utils/py/wave_reconcile.py:1481-1492` (`update_roadmap_entry`, the reported symptom).
- A slug containing `/` is used verbatim as the row's repo. A bare slug becomes the origin
  `owner/name` only when it is byte-equal to the origin's name. A row is valid only when
  `url_repo == source` exactly and the number matches.
- Other readers: `tracking_token_to_url` (`:2102`) already prefers an org/repo-shaped slug and
  otherwise falls back to `_github_slug_from_origin`. `releases_cycle.py:207` uses
  `settings.repo_slug` only as a display label. The dump at `:1128` serialises it.
- **Digests.** `repos.slug` is business state, so it is part of `business_digest`, and every
  `op_receipts` row hashes it. Rewriting a stored slug would therefore need a new receipted writer.
  A resolver-side change rewrites nothing: no digest, receipt, generation or dump changes.

**Two origin parsers already exist.** `_origin_repo_identity` (`:5385`) accepts any host, so a
local-path origin such as `../GH Repos/XYZ-forge` parses as `GH Repos/XYZ-forge`.
`_github_slug_from_origin` (`:2082`) accepts github.com only and returns None otherwise. The
github-only helper is the right source for a stored slug: issue URLs are github.com URLs, and a
disposable clone made from a local path (SOP Step 2) must not record a bogus `owner/name`.

**Measured.** In the AEGIS ledger (read-only), `repos` holds `1|aegis-sleuth-slack-bot`, origin is
`HiQS-Labs/AEGIS-Sleuth-Slackbot`, the schema is v7, and 14 rows carry
`https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/N` (71 have no URL). Red control: the
recorded manual check `TESTS-RESULTS/2026-10-10+GH-1016/identity_check.py`, run on the `9a923f3c`
tree (`utils/py` and `relay-automation` from `git archive 9a923f3c`), scores **9/15 and exits 1**.
The six target cases fail: the own row, the qualified dry-run wave move, the init slug, the fresh-init
row, the onboard default slug and the onboard dotted repo name. The nine controls pass: foreign rows
invalid, wave skips the foreign row, multi-repo exact, local-path/no-origin/explicit init, and
explicit/no-origin onboard. The command, source SHA, exit status, hashes, AEGIS observations and
recurrence searches are in `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl`. The `marathon-plan`
exit-6 symptom and the missing GH-201/211/219 rows are author-reported from the issue body; they were
not re-measured here. Wave case 4 is a qualified dry-run (`update_roadmap_entry(..., dry_run=True)`
returns True and does not log the skip); it is not proof of a persisted move. The onboard script's
own GitHub parse (`xyz-releases-onboard.sh:108`, `([^/.]+)`) also refuses dotted repo names:
`https://github.com/test-org/foo.js.git` does not match (Codex plan QA r1 probe).

**Existing suites covering the seam.** `test/gh646-status-label.sh` (`gh646_status_label.py`: wave
foreign-row and owned-row identity, express identity, all on `init --slug owner/project` with a
GitHub origin). `test/gh605-work-state.sh` and `test/gh605-board-policy.sh` (identity_valid
reporting, multi-repo rows with `/` slugs). `test/gh32-releases-app.sh` (init and tracking-issue
expansion). `test/gh197-vendor-tier-split.sh` (onboard happy path with `test-org/*` GitHub origins:
the slug changes from bare to owner/name there, and no assertion pins it). `test/gh238`, `gh269`,
`gh290` and `gh291` call `init` without `--slug` in fixtures that have no origin, so the basename
fallback leaves them unchanged.

**Prior art.** `prior_art_recon.py --query "repos slug"` matched no roadmap rows or helpers. Open PRs
#1017 (marathon receipts, also touches `releases.db/.sql`: expect a dump conflict on merge order,
resolved by `utils/releases-merge-resolve.sh`), #954 and #930 are unrelated seams. Closed #429 added
the github-only origin parser to `harness_paths.py`.

## Plan

**Bet.** Two surgical changes fix the reported failure and stop new ledgers from recurring, with no
schema change, no new verb and no rewrite of stored data. One assumption is load-bearing: a legacy
bare slug that differs from the GitHub name *only by case or `-`/`_`* is the same repo when the ledger
has exactly one `repos` row. If that assumption is wrong, the cost is that one wrongly bound
single-repo ledger accepts rows whose issue URL already names this clone's own origin. That
condition is itself evidence of ownership.

**Outcome sought.** `wave_reconcile`, `roadmap update`, `--accepted-start`, express and the work
connectors treat AEGIS's own rows as owned without a hand repair. Foreign rows stay refused.

**Smallest change (one ordered list).**

1. `resolve_roadmap_identity` (`releases_app.py:5401-5402`): keep today's exact branch. Add one
   tolerant branch for a bare slug when `len(repo_rows) == 1`, using
   `key(s) = s.casefold().replace("-", "").replace("_", "")` on both the slug and the origin's
   repo name.
   `aegis-sleuth-slack-bot` → `aegissleuthslackbot` == `AEGIS-Sleuth-Slackbot` →
   `aegissleuthslackbot`. Validity is unchanged: `url_repo == origin_repo` exactly, and the number
   matches.
   -> expect manual check cases `legacy-bare-own-row-valid`, `wave-reconcile-moves-own-row` and
   `multi-repo-ledger-keeps-exact-match` to pass; `bash test/gh646-status-label.sh` and
   `bash test/gh605-work-state.sh` to stay green.
2. `cmd_init` (`:2176`): `slug = args.slug or _github_slug_from_origin(root) or basename`. The same
   value goes to `settings.repo_slug`, as today. An explicit `--slug` still wins.
   -> expect the five `init-*` manual check cases to pass; `bash test/gh32-releases-app.sh` to
   stay green.
3. `relay-automation/xyz-releases-onboard.sh`: before Step 1, compute
   `ORIGIN_SLUG` once by calling the same `releases_app._github_slug_from_origin` the init default
   uses. The call is a `python3 -c` import from the already-resolved `$RELEASES_APP` directory,
   against `$TARGET_REPO`. Then:
   - `EFFECTIVE_SLUG="${SLUG:-${ORIGIN_SLUG:-$(basename "$TARGET_REPO")}}"`;
   - `GH_BASE="${ORIGIN_SLUG:+https://github.com/$ORIGIN_SLUG}"` replaces the script's own regex at
     `:106-111`, and the existing `--slug owner/name` fallback at `:112-116` stays.

   One parser serves init and onboard. Dotted names (`foo.js`) now parse, which fixes the r1
   finding.
   -> expect the four `onboard-*` manual check cases to pass (onboard default, dotted name, explicit
   slug, no-origin basename); `bash test/gh197-vendor-tier-split.sh` to stay green.
4. Record the manual check: run `identity_check.py` on the committed fix tree (expect 15/15,
   exit 0). The red control (9/15, exit 1) is already recorded. Append the green run to
   `provenance.jsonl` under `TESTS-RESULTS/2026-10-10+GH-1016/`. The check writes only temp dirs; it
   is re-run in the disposable gate clone for the final receipt. Add a CHANGELOG entry.
5. Final gate: `ci-local.sh` or full `validate.sh`, once, in a separate disposable full clone of the
   committed branch. The route is full, because `relay-automation/` is a full-gate surface.

**Why the foreign repo cannot match (proof).** The tolerant branch only decides whether the ledger's
single `repos` row *is* the origin. It never makes the row's URL agree. A row is valid only when
`_repo_from_issue_url(row.issue_url)` equals `origin_repo` byte for byte. So for a foreign repo:

- a row naming another owner's same-named repo (`Other-Org/AEGIS-Sleuth-Slackbot`) is refused;
- a row naming another repo (`HiQS-Labs/XYZ-forge`) is refused;
- a ledger with a second `repos` row falls back to the exact-only match.

Manual check cases 2, 3, 5 and 6 pin these. Slugs that already contain `/` never take the bare
branch. The normalisation removes only case and `-`/`_`, not `.`, digits or letters: `foo.js` versus
`foojs` stays distinct.

**Legacy ledgers (decision).** The resolver-side tolerant match (issue option 3) is chosen over a
repair verb (option 2):

- it repairs AEGIS on re-vendor with zero stored-state change;
- it keeps one writer and adds no verb;
- it changes no receipt or digest.

A repair verb would be a new receipted write path for an identity field that `settings set` deliberately
refuses.

**Non-goals.**

- No new tests (GH-831): verification is the existing suites plus the recorded manual check.
- No schema change.
- No new verb or migration step.
- No change to `issue_url` validation or `_origin_repo_identity`.
- No edits to any consumer ledger.
- No rewrite of XYZ-forge's own `XYZ-forge` slug.
- A legacy ledger whose folder name differs by more than case or separators (for example `aegis`
  versus `AEGIS-Sleuth-Slackbot`) is out of scope. No instance has been observed, and those rows are
  still recoverable by hand. Park it if one appears.

**Alternatives rejected.**

- *Repair verb* (above).
- *Owner-less case-insensitive URL match*: it would widen validity itself, which is exactly what
  makes foreign rows dangerous.
- *Using `_origin_repo_identity` in `cmd_init`*: it parses local-path origins into a bogus
  `owner/name`.

**Risks / blast radius.**

- Changing `repos.slug` affects new ledgers only: `pdda-install` installs and onboard.
- `tracking_token_to_url` benefits, because it already prefers an org/repo slug.
- `releases_cycle` shows `owner/name` as its label.
- The resolver change can only turn invalid rows valid, and only for single-repo ledgers whose rows
  already carry this origin's own URL.
- The one-row guard keeps multi-repo test fixtures (gh605) on today's exact behaviour.

**Reversibility: Easy.** Revert the commits. Ledgers created in the meantime keep an `owner/name`
slug, which the pre-fix resolver already accepts (the `/` branch), so a revert strands nothing.

**Rollback.** `git revert` the `fix(GH-1016)` commits.

**After merge (AEGIS operator).**

1. Re-vendor `.xyz/` from forge.
2. Re-run the post-merge reconcile (`python3 .xyz/utils/py/wave_reconcile.py --pr <N>`, or the
   catch-up path for the PRs that closed GH-215 and GH-217).

The stale rows then resolve as owned and move. No ledger repair command is needed.

## Acceptance map

| Requirement | Check |
|---|---|
| AEGIS-shaped bare slug resolves own rows `identity_valid True` | manual check cases 1, 4 (fix tree) |
| Foreign-repo rows stay invalid | manual check cases 2, 3, 5 |
| Multi-repo ledgers unchanged | manual check case 6; gh605 suites |
| New ledgers record GitHub owner/name; non-GitHub origins keep basename | five `init-*` cases; gh32 |
| Onboarding records the same slug, including dotted names; explicit/no-origin unchanged | four `onboard-*` cases (red on base); gh197 |
| Red control: pre-fix code fails the same check | `identity_check.py` on `9a923f3c` → 9/15, exit 1 (`provenance.jsonl`) |
| No regression | gh646, gh605-work-state, gh605-board-policy, gh32, gh197 focused; full gate in a disposable clone |

## Plan QA dispositions

Round 1 (Codex, FAIL, `relay-system/2026-10-10/gh1016-plan-qa.md`):

- **[Should] Onboard dotted-name parse gap. Modified.** Onboard now reuses
  `releases_app._github_slug_from_origin` for both its slug and `GH_BASE`, in place of its own bash
  regex. That fixes dotted names with one parser and no second implementation (plan step 3).
- **[Should] Provenance and rating claims. Implemented.** The red-control receipt, hashes, AEGIS
  observations and both recurrence searches are now in `provenance.jsonl`. The exit-6 and missing-row
  claims are labelled author-reported.
- **[Should] Falsifiable onboard acceptance. Implemented.** Four `onboard-*` cases were added to the
  existing manual check (not a suite). They are red on base (default and dotted fail) and read
  `repos.slug` and `settings.repo_slug`.
- **[Nit] Control count. Implemented.** The count now reads nine controls of 15. Wave case 4 is
  described as a qualified dry-run.

Round 2 (Codex, PASS, Approved; attested at reviewed head `80f43a32`): four Pass findings.

- **[Nit] Name debug-mantra. Implemented.** If an execution check fails, apply debug-mantra before
  changing the fix.

## Implementation evidence

Commits:

- `198a56b6` resolver plus `cmd_init` default;
- `128d7ddf` onboard through the shared parser;
- `1cb42805` CHANGELOG plus green receipt.

The diff against `9a923f3c` touches `utils/py/releases_app.py` (+11/−3) and
`relay-automation/xyz-releases-onboard.sh` (+7/−8). It adds no new suite, registry entry, verb or
schema.

- **Manual check.** 15/15, exit 0, in the task clone at `128d7ddf` and in the disposable gate clone at
  `1cb42805`. The red control is 9/15, exit 1, at `9a923f3c`.
- **Focused existing suites** (task clone, `128d7ddf`), all rc=0:
  - gh646-status-label;
  - gh605-work-state;
  - gh605-board-policy;
  - gh32-releases-app: 145/0;
  - gh197-vendor-tier-split: 73/0;
  - relay-pkg-freshness: 3/0;
  - gh238-hq-releases-mode.
- **Full gate.** The pre-push hook took route full (tier 3) in the disposable full clone
  `XYZ-forge-gh1016-repo-slug-identity-2026-10-10-gate` at `1cb42805`: GREEN in 871s, 406/406 suites
  rc=0. Clone identity was intact after the run, and the branch was pushed by that hook.
- **Records.** Log and receipts are in `TESTS-RESULTS/2026-10-10+GH-1016/provenance.jsonl`.
