> **XYZ Forge’s locally maintained guidance for selecting PDDA’s enforcement mode.**

# PDDA mode guide — when to stay in observe/light mode

Maintained here from the [XYZ predecessor’s version](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/PDDA-MODE-GUIDE.md).
PDDA itself is a separate project: [Hypercart-Dev-Tools/pdda](https://github.com/Hypercart-Dev-Tools/pdda).

This is the short operator guide the Phase 2 hardening pass (GH-144) calls for: concrete triggers for
staying in `observe` or `light` mode, and for graduating to `full`. It does not restate the mode
mechanics — those are canonical in [`PROJECT/PDDA.md`](PDDA.md) → "Enforcement modes" (the
`PDDA_MODE` env / `.pdda-mode` file / default-`observe` precedence rule) and the enforcement-mode
default is ratified as policy in [`PROJECT/CONSTITUTION.md`](CONSTITUTION.md) → "Enforcement-mode
default". This document only answers *when* an operator should choose which rung.

## The three rungs, in one line each

- **`observe`** — findings are reported, nothing ever blocks. The default. Use this whenever PDDA is
  new to a repo, or when the doc backlog is large enough that turning on blocking would just produce a
  wall of red for pre-existing debt instead of new drift.
- **`light`** — findings are reported (loudly), still nothing blocks. Use this once the backlog is
  mostly clear and you want the team to *feel* the noise of new violations before those violations can
  fail a build.
- **`full`** — `error`-severity findings block (non-zero exit). Use this only once a repo has
  deliberately committed to the contract and cleared its debt; declared by committing `.pdda-mode`
  with `full`.

## Concrete triggers for staying in `observe` or `light`

Stay below `full` — do not flip `.pdda-mode` to `full` yet — when any of these are true:

- **Fresh install.** PDDA was just added to this repo (or a new repo entirely) and no doc has ever
  been checked against the contract. Blocking on day one punishes pre-existing debt, not new mistakes.
- **Known backlog, not yet triaged.** `pdda.sh run` in `observe` already reports more than a handful of
  `error`-severity findings across `PROJECT/2-WORKING`. Flipping to `full` here blocks unrelated work
  the moment someone touches any doc in the backlog, not just the doc they're actually changing.
- **Active migration or bulk rename in flight.** A repo-wide rename, folder restructure, or lifecycle-
  bucket migration (`1-INBOX` ↔ `2-WORKING` ↔ `3-COMPLETED`) is underway and will trip
  `hardcoded-paths` / `roadmap-coverage` transiently. Land the migration in `observe`, confirm clean,
  then graduate.
- **Experimenting with a new check or a rubric change.** A check was just added or its severity
  thresholds just changed (e.g. the triage-rating validation in `pdda.sh frontmatter`). Run one full
  cycle in `observe` first to see the finding volume before it can block anyone.
- **Cost/friction outweighs the caught drift.** If `light`-mode noise has run for a while and the
  findings are consistently either false positives or trivial ("forgot to update one date field"), that
  is itself a signal to either fix the check (open an issue, do not silently mute it) or accept staying
  in `light` rather than escalate friction for low-value catches — the same calibration principle behind
  the [individual check contracts](PDDA.md#1-deterministic-hygiene-checks) in PDDA.md.
- **Single-operator or low-traffic repo.** When one person owns all doc edits and already reads every
  `observe` report, the marginal safety value of `full`'s hard block is small relative to the friction
  of a build failing on a doc typo mid-flow.

## Concrete triggers for graduating toward `full`

Move up a rung when:

- `pdda.sh run` in `observe`/`light` has reported **zero `error` findings** for a sustained stretch
  (e.g. several consecutive days of real usage, not one clean run right after a cleanup pass).
- Multiple contributors (or multiple agents) are editing `PROJECT/**` concurrently, so a human is no
  longer reliably reading every `observe` report — the hard block becomes cheaper than a missed drift.
- The repo has just shipped a consequential migration and wants a hard guarantee it does not silently
  regress (lock in the clean state).

## What never blocks, regardless of mode

The [individual deterministic check contracts](PDDA.md#1-deterministic-hygiene-checks) and
[LLM readiness contract](PDDA.md#2-llm-assisted-doc-readiness-review) describe which findings
remain advisory even in `full`. The LLM
readiness layer, the stale-doc flag, the changelog nudge, and the issue-doc-sync drift flag are all
warn-only/flag-only. Choosing `full` mode governs only the deterministic structural checks
(frontmatter, status table, hardcoded paths, roadmap leak/coverage) — it does not turn any advisory
signal into a blocker.

## Sources

- [`PROJECT/PDDA.md` — Enforcement modes](PDDA.md#enforcement-modes) (mechanics),
  [deterministic checks](PDDA.md#1-deterministic-hygiene-checks) and
  [LLM readiness](PDDA.md#2-llm-assisted-doc-readiness-review) (individual check contracts).
- [`PROJECT/CONSTITUTION.md`](CONSTITUTION.md) — "Enforcement-mode default" (why `observe` is the
  ratified default).
- [`predecessor PROJECT/4-MISC/GH-144-PDDA-FEEDBACK-SYNTHESIS.md`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/67dd324487c1fc470b2c539f1cebe2a9c3fb3651/PROJECT/4-MISC/GH-144-PDDA-FEEDBACK-SYNTHESIS.md)
  — Phase 2 checklist item that called for this guide.
