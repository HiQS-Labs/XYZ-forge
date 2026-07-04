---
gh_issue: 48
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48
title: Generalize marathon-plan's zone model for true cross-repo pre-pre-flight
status: Designed — awaiting /consult (Agy + Codex) before build
created: 2026-06-29
updated: 2026-07-04
owner: noel
doc_type: feature
goal: >
  Replace utils/marathon-plan.sh's hardcoded kernel/shim zone classifier with a configurable,
  declarative zone-rules layer (path prefixes/regex + max-per-wave + inference-conservatism per
  zone), defaulting to xyz's current rules byte-for-byte, so marathon-plan can compute a correct
  swarm/serialize wave plan for an external repo (validated against the live rebalance-OS 3-lane
  queue) without xyz-specific keyword coupling.
non_goals:
  - No foreign ledger/queue-format reader (park-and-discuss idea #3 from the original issue) — the
    near-term path (per-lane swarm-preflight contracts) already works today per ROADMAP.md's
    existing guidance; revisit only if the rebalance dogfood proves that insufficient.
  - No change to swarm-preflight.sh itself — its write-set disjointness engine is already generic.
  - No change to xyz's own planning output — the default zone config is xyz's current
    KERNEL_PATHS/SHIM_RE values verbatim, so test/marathon-plan.sh must stay byte-identical.
complexity: 3
risk: 2
effort: 3
phases: 2
roadmap_exempt: false
related:
  - utils/marathon-plan.sh
  - utils/swarm-preflight.sh
  - test/marathon-plan.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Design committed (this doc) — replaces the three park-and-discuss ideas with one decided approach (Option 1, configurable zone rules) grounded in the actual `zoneOf()`/wave-packing code (`utils/marathon-plan.sh:148-153`, `:350-373`, `:643-690`). Not yet built. | Run `/consult` (Agy + Codex) to review this design before writing code — see [Consult ask](#consult-ask). If Approved (or Approved-with-fixes), promote to a marathon lane with the contract below; this lane is explicitly **excluded** from the current Plan B firing round. |

## Problem (grounded in the current code)

`utils/marathon-plan.sh`'s `zoneOf(contract, item)` (line 350) labels every item `kernel | shim |
independent` using two **hardcoded, xyz-specific** constants:

```js
const KERNEL_PATHS = [
  "relay-automation/relay-turn-lib.sh",
  "bin/tick",
  "relay-automation/relay-drive.sh",
];
const SHIM_RE = /relay-automation\/[a-z0-9-]+-turn\.sh$|relay-automation\/consult\.sh$/i;
```

The important detail the original issue capture under-specified: **this hardcoding applies even
when an item has a real swarm-preflight contract.** `zoneOf`'s "proven zone" branch (line
359-365) still runs the contract's `artifacts[]` write-set through `KERNEL_PATHS`/`SHIM_RE` —
so a foreign repo's contract naming `scripts/apple_reminders_helper_app.swift` as its write-set
matches neither, and falls through to `independent` **even with a fully-specified contract**. The
gap isn't "missing contracts" (park-and-discuss idea #2 assumed that) — it's that the
classification *rules themselves* are xyz's filenames, contract or no contract. Idea #2 alone
would not fix the rebalance case.

The wave-packing loop (line 643, 672-690) has the same hardcoding one level up: `ZONE_PEN`,
`kernelTaken` (max-1-kernel-per-wave), and `inferredShimClash` (shim items without a proven
write-set can't share a wave) all key off the literal strings `"kernel"`/`"shim"`.

`swarm-preflight.sh`'s write-set disjointness is already fully generic (confirmed, not
re-litigated here) — this doc scopes strictly to the `marathon-plan.sh` ranker/classifier gap.

## Decision: build Option 1 (configurable zone rules), not idea #2 or #3

- **Option 1 — configurable zone rules.** Committed. Replaces `KERNEL_PATHS`/`SHIM_RE` and the
  wave-packing constants with a data-driven zone-rules list, loaded from a config file, with xyz's
  current values shipped as the built-in default (zero behavior change for xyz itself).
- **Option 2 — contract-only mode.** Not a separate deliverable — proven-vs-inferred priority
  already exists in `zoneOf` today; the real fix is making the *proven* path's matching rules
  configurable (which Option 1 does). Superseded by Option 1, not built alongside it.
- **Option 3 — foreign ledger/queue-format adapter.** Explicitly deferred. ROADMAP.md's existing
  near-term note already recommends per-lane `swarm-preflight` contracts as today's workable path
  for cross-repo work; a foreign-ledger reader is a bigger, more speculative lift (every foreign
  repo's queue format differs) that isn't required to unblock the rebalance dogfood. If the live
  validation in Phase 2 below proves this genuinely needed, it becomes its own follow-up issue —
  not silently folded into this one.

## Design

### Zone-rules schema

```json
{
  "zones": [
    {
      "name": "kernel",
      "pathPrefixes": ["relay-automation/relay-turn-lib.sh", "bin/tick", "relay-automation/relay-drive.sh"],
      "inferKeywordRegex": "relay-turn-lib|containment kernel|bin/tick|relay-drive|commit semantics|epoch fenc",
      "maxPerWave": 1,
      "penalty": 2
    },
    {
      "name": "shim",
      "pathRegex": "relay-automation/[a-z0-9-]+-turn\\.sh$|relay-automation/consult\\.sh$",
      "inferKeywordRegex": "-turn\\.sh|consult\\.sh|\\bshim\\b",
      "conservativeWhenInferred": true,
      "penalty": 1
    }
  ],
  "defaultZone": { "name": "independent", "penalty": 0 }
}
```

This is xyz's **exact current behavior** re-expressed as data — the default config `utils/marathon-plan-zones.default.json` ships this verbatim, so nothing about xyz's own planning changes.

A foreign repo's override, e.g. `rebalance-os-zones.json`:

```json
{
  "zones": [
    {
      "name": "signed-helper",
      "pathPrefixes": ["scripts/apple_reminders_helper_app.swift"],
      "maxPerWave": 1,
      "penalty": 2
    }
  ],
  "defaultZone": { "name": "independent", "penalty": 0 }
}
```

### Resolution order (first match wins)

1. `--zones-config <path>` CLI flag (explicit override).
2. `QP_ZONES_FILE` env var — hermetic test seam, mirroring the existing `QP_BASE_FILES_FILE` /
   `QP_GH_STATE_FILE` / `QP_BRANCHES_FILE` pattern already in `utils/marathon-plan.sh`.
3. `<target-root>/.marathon-plan-zones.json` — repo-local convention, analogous to how
   `swarm-preflight` already treats `--target-root` as "the repo this plan is about."
4. Built-in xyz default (`utils/marathon-plan-zones.default.json`) — always available, never
   requires a flag for xyz's own repo.

### Code changes (Phase 1)

- `zoneOf(contract, item)`: iterate the loaded zone list in order; for the proven-contract path,
  match `artifacts[]` against each zone's `pathPrefixes`/`pathRegex`; for the inferred path (no
  contract), match title+body text against each zone's `inferKeywordRegex`. First match wins;
  falls through to `defaultZone`. Same two-tier proven-vs-inferred priority as today — only the
  matching rules move from hardcoded consts to config data.
- Wave-packing (`ZONE_PEN`, `kernelTaken`, `inferredShimClash`): generalize to read `penalty` /
  `maxPerWave` / `conservativeWhenInferred` off the matched zone object instead of string-comparing
  `"kernel"`/`"shim"`. A zone with no `maxPerWave` behaves like today's `independent`/`shim` (no cap
  beyond write-set disjointness); `conservativeWhenInferred` generalizes the shim-specific rule to
  any zone that opts in.
- Collision-map rendering (~line 810): iterate the configured zone list instead of the hardcoded
  `["kernel", "shim", "independent"]` array.

### Phase 2 — live acceptance validation (not a code change)

Run `marathon-plan.sh --target-root <rebalance-OS clone> --zones-config rebalance-os-zones.json`
against the **real** rebalance-OS 3-lane queue (`PROJECT/4-MISC/QUEUE-2026-06-27.md` in that repo),
with each lane carrying a swarm-preflight contract (per ROADMAP's existing near-term
recommendation — this was already the intended path regardless of this issue). Confirms the
shared-helper lane lands alone in its own wave (`maxPerWave: 1` enforced) while the other two lanes
wave together. This is the acceptance gate, not a nice-to-have — "done" means this actually ran
against the live repo, not a synthetic fixture standing in for it.

## Acceptance criteria

- [ ] `test/marathon-plan.sh` fully green with **zero** output diff versus today — the default zone
  config reproduces xyz's current classification and wave-packing exactly.
- [ ] New test coverage (extend `test/marathon-plan.sh` or add `test/marathon-plan-zones.sh`): a
  synthetic foreign zone-config correctly reclassifies a write-set the hardcoded regexes would have
  missed, and correctly enforces `maxPerWave`/`conservativeWhenInferred`.
- [ ] Resolution-order precedence tested: `--zones-config` > `QP_ZONES_FILE` > `<target-root>/.marathon-plan-zones.json` > built-in default.
- [ ] Live validation (Phase 2): the actual rebalance-OS 3-lane queue produces the correct wave
  split, run against the real repo, output captured in this doc's Status table.
- [ ] Schema documented in `utils/marathon-plan.sh`'s header comment and `relay-automation/README.md`.

## Reversibility & blast radius

**Medium-low.** Pure refactor of one internal classification function + wave-packing constants,
behind a new optional config layer whose default is provably identical to today's hardcoded
behavior (acceptance criterion 1 is the regression guard). Touches `utils/marathon-plan.sh`, one of
Plan B's own contended shared-file zones (collision map: `#86 → #48`, serialize, never run
together) — this lane must run **after** #86 lands, exactly as Plan B's existing wave ordering
already requires. No kernel (`relay-turn-lib.sh`/`bin/tick`) surface touched.

## Consult ask

Before writing code: `/consult` Agy + Codex on this design specifically —
1. Does the zone-rules schema (path prefixes/regex + `maxPerWave` + `conservativeWhenInferred` +
   `penalty`) actually generalize the current kernel/shim semantics without losing any existing
   behavior?
2. Is deferring Option 3 (foreign ledger/queue-format adapter) the right call, or does the
   rebalance dogfood specifically need it sooner than "revisit if Phase 2 proves it necessary"?
3. Any gap in the resolution-order precedence (flag > env seam > repo-local file > built-in
   default) that would surprise an operator running this against a real foreign repo?

## Swarm Preflight Contract (draft — for after /consult Approves)

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-plan.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "utils/marathon-plan-zones.default.json" }
  ],
  "artifacts": [
    "utils/marathon-plan.sh",
    "utils/marathon-plan-zones.default.json",
    "test/marathon-plan.sh"
  ],
  "remediation": "Replace utils/marathon-plan.sh's hardcoded KERNEL_PATHS/SHIM_RE and the ZONE_PEN/kernelTaken/inferredShimClash wave-packing constants with a zone-rules list loaded per the resolution order (--zones-config flag > QP_ZONES_FILE env seam > <target-root>/.marathon-plan-zones.json > built-in utils/marathon-plan-zones.default.json, which ships xyz's current values verbatim). zoneOf() and the wave-packing loop key off the matched zone object's pathPrefixes/pathRegex/inferKeywordRegex/maxPerWave/conservativeWhenInferred/penalty fields instead of literal 'kernel'/'shim' strings. test/marathon-plan.sh must show zero output diff for xyz's own default config; add coverage for a foreign zone-config fixture and the resolution-order precedence.",
  "lanes": {
    "agy_safe": ["utils/marathon-plan.sh", "utils/marathon-plan-zones.default.json", "test/marathon-plan.sh"],
    "orchestrator_only": [],
    "note": "Shares utils/marathon-plan.sh with #86 — collision map requires #86 land first (serialize, never run together). Not part of the current Plan B firing round; queued for after /consult review."
  }
}
```

## Provenance

Filed 2026-06-29 while planning the rebalance-OS cross-repo marathon dogfood (the ROADMAP queue
entry). The swarm-vs-relay compute was found to be **generic in `swarm-preflight`** (write-set
disjointness, `--target-root`) but **xyz-coupled in `marathon-plan`** (ledger format + kernel/shim
keywords). Design committed 2026-07-04 after re-reading the actual `zoneOf()`/wave-packing code
(see Problem section above) — the original issue's idea #2 turned out not to fix the rebalance case
on its own, which is why this doc commits to idea #1 instead. Relates to the rebalance dogfood
ROADMAP entry and GH-33 / #46 (the marathon path itself).
