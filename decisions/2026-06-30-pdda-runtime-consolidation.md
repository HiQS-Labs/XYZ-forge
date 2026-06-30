---
status: Decided
date: 2026-06-30
reversibility: Costly
revisit: "the next upstream pdda install.sh run — does re-running it cleanly upgrade utils/pdda/ without re-introducing the flat layout or clobbering repo-specific tooling? Also revisit if the integer 1–5 ratings prove too coarse for marathon-plan sequencing, or if the dropped ratings_provisional confirm-nudge is missed in practice."
related: ["2026-06-29-self-improvement-loop.md", "2026-06-30-auto-reap-authority.md"]
decider: "@noelsaw1"
---

# PDDA runtime consolidation — adopt the upstream single-dispatcher layout + integer triage ratings

**Decision:** Migrate this repo off its old split PDDA implementation (a `utils/pdda-run.sh` entry point
driving 11 flat `utils/pdda-check-*.sh` scripts + `utils/pdda-lib.sh`) and onto the canonical
consolidated runtime the upstream `pdda` repo now ships: a single `utils/pdda/pdda.sh` dispatcher with
bundled checks, installed by `pdda/install.sh`. As part of the cutover, switch the triage-ratings
contract from words (`low|medium|high`) to the upstream **integer `1`–`5`** scale.

This repo is the *divergent ancestor* of PDDA, so the migration was not a layout swap — it reconciled
real semantic drift and rewired every consumer (agent hooks, the gate test, the operator docs).

## What was decided (the three open questions)

- **D1 — ratings format → integers `1`–`5` (option a).** Rewrote `effort`/`complexity`/`risk` in all 25
  rated `PROJECT/**` docs with a uniform, order-preserving map: `low→2, medium→3, high→4` (conservative
  mid-band; `1` and `5` left as operator headroom for genuinely-trivial / one-way-door items). Updated
  `utils/marathon-plan.sh` (`L()` now passes through `1`–`5`; `ratingWord`→`ratingNum` renders the
  number) and `test/marathon-plan.sh` fixtures. Ranking order is unchanged (the map is monotonic), so
  the planner's wave logic is preserved.
- **D2 — drop `utils/pdda-check-ratings.sh`.** Keeping it would have forced either a fork of the
  vendored `utils/pdda/pdda.sh` or a duplicated run-invocation everywhere — the exact second-source
  drift PDDA exists to prevent — to preserve one nudge. Its enforcement is now covered: the bundled
  `pdda.sh frontmatter` check **errors** on any out-of-range rating, and `marathon-plan.sh` already
  detects and holds `unrated` items. The single dropped capability is the `ratings_provisional`
  confirm-nudge (cheap to re-add to `marathon-plan.sh` later if missed).
- **D3 — keep the refreshed `PROJECT/PDDA.md`.** The installer's overwrite was a clean superset (it
  carries a *better* integer-ratings contract and dropped no repo-specific governance), so once the
  wiring was cut over, the contract and the runtime agree — no mismatch to reconcile.

## The bet

The upstream single-dispatcher surface is worth adopting wholesale (vs. keeping the local fork) because
it ends the install/steady-state drift: one manifest, one entry point, `pdda/install.sh` upgrades in
place. The cost paid now — integerizing every doc + rewiring ~10 consumers — buys a runtime that tracks
upstream with no per-upgrade reconciliation. The risk is that future upstream changes to bundled-check
*semantics* (as the ratings words→integers split already showed) land silently on the next install; the
revisit trigger above watches for exactly that.

## Blast radius / what changed

- **Removed (12 flat files):** `utils/pdda-run.sh`, `utils/pdda-lib.sh`, `utils/pdda-doc-ready.sh`,
  the 8 `utils/pdda-check-*.sh` (incl. `pdda-check-ratings.sh`), `utils/pdda-stale-working-docs.sh`,
  `utils/PDDA-INSTALL.md`.
- **Kept (repo-specific, untouched):** `utils/marathon-plan.sh`, `swarm-preflight.sh`,
  `roadmap-dashboard.sh`, `validate-agy.sh`, `utils/telemetry/`.
- **Rewired to `utils/pdda/pdda.sh`:** `.claude/settings.json` allowlist, `test/pdda-roadmap-coverage.sh`,
  `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `FRONTDOOR.md`, `ROADMAP.md` banner + ledger,
  `PROJECT/4-MISC/AGENTS-DOCS.md`, active `PROJECT` docs (GH-30, GH-25).
- **Left as dated history (not rewritten):** `CHANGELOG.md`, `relay-system/**`, `PROJECT/3-COMPLETED/**`
  verification notes, the verbatim `FEEDBACK-*.md` quotes, `PROJECT/4-MISC/RECAP.md`.

## Verification

- `utils/pdda/pdda.sh run` green in **full** mode (the repo's `.pdda-mode`): 0 errors across all 9
  checks (only pre-existing warn-level findings: 1 stale-changelog, 5 issue-doc-sync).
- `test/marathon-plan.sh` **31/31** on integer fixtures (ordering + policy-flip preserved).
- `test/pdda-roadmap-coverage.sh` **3/3** against the new dispatcher subcommand.
- `./validate.sh` green (exit 0) both before the cutover (baseline) and after.
