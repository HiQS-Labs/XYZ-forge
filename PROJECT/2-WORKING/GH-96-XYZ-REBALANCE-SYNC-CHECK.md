---
gh_issue: 96
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/96
title: "XYZ⇄Rebalance integration (XYZ side, mirrors rebalance#102): xyz-sync check · XYZ.json emit contract · tick-lane consume"
status: Ready — promoted for Marathon Plan B Wave 1 (2026-07-04), scoped to Seam #2 only
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: feature
goal: >
  Ship Seam #2 of the XYZ<->Rebalance integration only: an `xyz-sync check` subcommand that diffs
  each registered install's recorded tick_version/source_commit (registry.tsv) against this
  harness's currently-shipped values and warns on drift -- the substrate rebalance-OS#102's
  Phase-0 collector code is explicitly blocked on, per the issue's own "ship first" ordering.
complexity: 2
risk: 1
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - "Seam #1 (XYZ.json emit contract / heartbeat hardening) is a separate seam, related to #75 --
    not built here. Track as its own future lane under this issue or a follow-up."
  - "Seam #3 (consume Rebalance -> XYZ lane seeding) is explicitly gated behind Seam #1 proving out
    per the issue's own text (\"Phase-2, gated... not yet actionable\") -- not built here."
  - "Correction to Marathon Plan B's write-set guess for this lane: src/take.js (the generic
    work-stealing next+claim verb, GH-4) has zero xyz-sync/rebalance relevance today and would
    only become relevant for Seam #3's tick-lane consumption -- which is explicitly out of scope
    above. This lane touches relay-automation/xyz-sync.sh only."
related:
  - relay-automation/xyz-sync.sh
  - relay-automation/xyz-vendor.sh
  - install.sh
  - test/xyz-vendor.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from GitHub issue capture, scoped to Seam #2 only (the "ship first" seam), grounded against the live `xyz-sync.sh` dispatcher and the existing `registry.tsv` schema (`relay-automation/xyz-vendor.sh:178-233`, `install.sh:225-307`). Not yet built. | Add the `check` subcommand, decide + document the pin/stamp comparison format, extend test coverage, `validate.sh` green, close the Seam #2 portion of #96 (issue stays open for Seams #1/#3 as separate future work). |

## Problem (grounded in the current code)

`relay-automation/xyz-sync.sh` currently ships two subcommands only — `list` and `delete`
(dispatch at line 265+; confirmed no `check` subcommand exists). `registry.tsv` already records,
per install row, `install_dir`, `last_install_utc`, `tick_version`, `source_commit`,
`coordinated_repo` (schema defined identically in both `install.sh:238,285` and
`relay-automation/xyz-vendor.sh:196`) — the columns this issue's ask needs already exist; nothing
in the registry format changes.

`tick_version()` (`relay-automation/xyz-vendor.sh:178-181`, mirrored in `install.sh:225`) reads
`SCHEMA_VERSION` out of `src/events.js` at install/vendor time; `source_commit` is
`git -C "$HARNESS_ROOT" rev-parse HEAD` at that same moment (`register_vendor()`,
`relay-automation/xyz-vendor.sh:213-233`). Both are **stamped once, at install time** — there is
currently no way to tell, after the fact, whether an installed/vendored copy has drifted from what
the harness repo currently ships. That's the gap rebalance-OS#102's Phase-0 collector is blocked on:
it needs a dependable, harness-side "is this install stale?" signal before its own code lands.

## Fix

Add `xyz-sync check [<install_dir>|--all]` to the existing dispatcher (`relay-automation/xyz-sync.sh`,
alongside `list`/`delete`):

1. For each selected registry row (reuse the existing `select_vendored_rows()` row-selection helper
   already used by `list`/`delete`, line 92+), read the recorded `tick_version`/`source_commit`.
2. Compute the **current** values the exact same way `register_vendor()` does today: current
   `tick_version()` (re-read `SCHEMA_VERSION` from *this* harness's `src/events.js`) and current
   `git rev-parse HEAD` of the harness root.
3. Compare recorded vs current. Match → silent/`ok`. Mismatch on either field → a warning naming
   the install, the field(s) that drifted, and both values (recorded vs current) — never a hard
   error and never an auto-pull; per the issue, this is **pinned + manual** (updates land via a
   normal `install.sh`/`xyz-vendor.sh` re-run, this subcommand only reports).
4. **Pin/stamp format decision** (rebalance#102 Phase-0's explicit dependency): the comparison key
   is the pair `(tick_version, source_commit)` — a mismatch in *either* counts as drift, since a
   `tick_version` bump without a fresh `source_commit` (or vice versa, a `source_commit` change that
   didn't bump `SCHEMA_VERSION`) both indicate the installed copy no longer matches what's
   canonically shipped. Document this pairing explicitly in `xyz-sync.sh`'s header comment and
   `relay-automation/README.md`, since rebalance's own collector code needs to know the exact
   contract, not just "there's a check command."

## Definition of done

- [ ] `xyz-sync check [<install_dir>|--all]` added to the dispatcher, reusing the existing row-selection
  helper.
- [ ] Drift detection compares both `tick_version` and `source_commit`, warns (not errors) on
  mismatch, names the specific field(s) and both values.
- [ ] No installs registered / target not found → the same graceful no-op behavior `list`/`delete`
  already have for that case (no new failure mode).
- [ ] Pin/stamp comparison contract documented in `xyz-sync.sh`'s header comment and
  `relay-automation/README.md`.
- [ ] `test/xyz-vendor.sh` (or a new `test/xyz-sync-check.sh`) covers: exact match → ok/no warning,
  `tick_version` drift only, `source_commit` drift only, both drifted, `--all` over multiple
  installs, no-match/not-found graceful behavior.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** New subcommand, reusing existing row-selection and registry-read code (`select_vendored_rows`,
already exercised by `list`/`delete`) — no change to the registry schema, no change to how rows are
written, no auto-mutation (report-only, pinned+manual by design). Fully additive to
`relay-automation/xyz-sync.sh`; no other file in this lane.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/xyz-vendor.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/xyz-sync.sh", "pattern": "GH-96" }
  ],
  "artifacts": [
    "relay-automation/xyz-sync.sh",
    "test/xyz-vendor.sh"
  ],
  "remediation": "Add an `xyz-sync check [<install_dir>|--all]` subcommand to relay-automation/xyz-sync.sh's existing dispatcher (alongside list/delete), reusing the existing select_vendored_rows() row-selection helper. For each selected row, compare its recorded tick_version/source_commit against the current values computed the same way register_vendor() in xyz-vendor.sh does (tick_version() re-reads SCHEMA_VERSION from this harness's src/events.js; source_commit is git rev-parse HEAD of the harness root). Warn (never hard-error, never auto-pull -- pinned + manual by design) on a mismatch in either field, naming the drifted field(s) and both values. Document the (tick_version, source_commit) pairing as the drift-detection contract in xyz-sync.sh's header comment and relay-automation/README.md. Add test coverage for exact match, tick_version-only drift, source_commit-only drift, both drifted, --all over multiple installs, and the no-installs-registered graceful no-op. GH-96 marker comment near the fix. Scope note: this lane covers Seam #2 only (xyz-sync check) -- Seams #1 and #3 from the GH-96 issue are explicitly out of scope, see the doc's non_goals.",
  "lanes": {
    "agy_safe": ["relay-automation/xyz-sync.sh", "test/xyz-vendor.sh"],
    "orchestrator_only": [],
    "note": "Independent leaf lane. Corrects Marathon Plan B's original write-set guess (src/take.js dropped -- zero relevance to Seam #2, only plausibly relevant to the explicitly out-of-scope Seam #3). Parallel-safe with any other Wave 1 lane; shares no file with #93 (src/analyze.js, a different src/*.js file)."
  }
}
```

## Provenance

Filed as the XYZ-side mirror of rebalance-OS#102, captured from the 2026-07-02 "dueling Claudes"
brainstorm (`claude-xyz` ⇄ `claude-reb`, converged; duel thread lives in the rebalance-OS repo).
Seam #2 (`xyz-sync check`) is the issue's own explicitly stated "ship first" unblocker for
rebalance's Phase-0 collector work. Promoted to `2-WORKING` 2026-07-04, scoped to Seam #2 only, as
part of Marathon Plan B Wave 1 (the 5 lanes cleared for firing after #23/#61 removal and Plan A
confirmation — see [MARATHON-PLAN-2026-07-03-B-PARALLEL.md](MARATHON-PLAN-2026-07-03-B-PARALLEL.md)).
