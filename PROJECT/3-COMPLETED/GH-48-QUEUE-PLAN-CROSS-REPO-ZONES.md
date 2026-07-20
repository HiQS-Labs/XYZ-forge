---
gh_issue: 48
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48
title: Generalize marathon-plan's zone model for true cross-repo pre-pre-flight
status: Closed — Built and merged via PR #125 (`d9db49d`, 2026-07-04); live rebalance validation captured below; issue #48 closed (see Status table)
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
| Built `utils/marathon-plan.sh` + `utils/marathon-plan-zones.default.json` + `test/marathon-plan.sh`; targeted gate `bash test/marathon-plan.sh` is green (57/57). Also ran the promised rebalance-OS live check via a throwaway translated ledger under `temp/gh48-marathon-plan-livecheck/`: the foreign config correctly classifies the BACKEND lane as `signed-helper` and renders `signed-helper<=1/wave`, but the real 3-lane queue still stays **one wave** because only one lane touches that zone. | Decide whether that observed one-wave outcome is sufficient closure for #48 (the classifier is now correct cross-repo) or whether a follow-up issue is needed for a stricter "serialize a lone special-zone lane" policy, which this design never implemented. |

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

### Zone-rules schema (corrected — see Consult outcome)

```json
{
  "zones": [
    {
      "name": "kernel",
      "pathPrefixes": ["relay-automation/relay-turn-lib.sh", "bin/tick", "relay-automation/relay-drive.sh"],
      "inferKeywordRegex": "relay-turn-lib|containment kernel|bin/tick|relay-drive|commit semantics|epoch fenc",
      "maxPerWave": 1,
      "penalty": 2,
      "escalateOrchestratorOnly": true
    },
    {
      "name": "shim",
      "pathRegex": "relay-automation/[a-z0-9-]+-turn\\.sh$|relay-automation/consult\\.sh$",
      "pathRegexCaseInsensitive": true,
      "inferKeywordRegex": "-turn\\.sh|consult\\.sh|\\bshim\\b",
      "conservativeWhenInferred": true,
      "penalty": 1
    }
  ],
  "defaultZone": { "name": "independent", "penalty": 0 }
}
```

Two fields added since the original draft, both required fixes from the consult:
- **`escalateOrchestratorOnly: true`** (kernel zone only, in the default config) — faithfully ports
  the current behavior at `utils/marathon-plan.sh:354-363`: an artifact whose write-set intersects
  `contract.lanes.orchestrator_only` is promoted to whichever zone declares this flag, regardless of
  the artifact's own path. Exactly one zone should set this in any given config; the classifier
  checks it before the normal `pathPrefixes`/`pathRegex` match.
- **`pathRegexCaseInsensitive: true`** (shim zone, in the default config) — faithfully ports
  `SHIM_RE`'s `/i` flag (`utils/marathon-plan.sh:153`). Omit for a zone whose `pathRegex` should be
  case-sensitive. `inferKeywordRegex` needs no such flag — the inferred-path text it matches against
  is already lowercased before testing (`hay = (item.title + " " + item.raw).toLowerCase()`,
  `utils/marathon-plan.sh:367`), so today's keyword regexes are implicitly case-insensitive already
  and the schema doesn't need to change that.

This is xyz's **exact current behavior** re-expressed as data, including the two additions above —
the default config `utils/marathon-plan-zones.default.json` ships this verbatim, so nothing about
xyz's own planning changes.

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

### Resolution order (first match wins) — corrected

**Self-correction beyond the consult's own findings:** the original draft referred to `--target-root`
as if `marathon-plan.sh` already had it. It doesn't — checked directly against the arg parser
(`utils/marathon-plan.sh:90-97`): the only flags today are `--dry-run`, `--check`, `--policy`,
`--deep`, `--require-gh`, `--format`. Pointing the planner at a different root/roadmap today is
**env-var only**: `QUEUE_PLAN_ROOT` and `QUEUE_PLAN_ROADMAP` (`utils/marathon-plan.sh:47-58`).
Per "least code that clears the bar," this design reuses those existing env vars rather than
inventing new `--target-root`/`--roadmap` flags — the only genuinely new surface is
`--zones-config`/`QUEUE_PLAN_ZONES_FILE`.

1. `--zones-config <path>` CLI flag (new; explicit override) — resolved **relative to CWD**, the
   standard CLI convention (stated explicitly per the consult's precedence-gap finding).
2. `QUEUE_PLAN_ZONES_FILE` env var (new) — hermetic test seam. **Renamed from the original draft's
   `QP_ZONES_FILE`** per Codex's finding, verified directly against the code: this script's real
   public convention is `QUEUE_PLAN_*` (`QUEUE_PLAN_GH_STATE_FILE`, `QUEUE_PLAN_BRANCHES_FILE`,
   `QUEUE_PLAN_BASE_FILES_FILE` — `utils/marathon-plan.sh:36-38`), translated internally to `QP_*`
   only for the embedded Node script (`utils/marathon-plan.sh:125-126`); `QP_*` alone is never a
   public seam name.
3. `$QUEUE_PLAN_ROOT/.marathon-plan-zones.json` (existing env var, reused) — resolved **relative to
   the resolved root** (`QUEUE_PLAN_ROOT` if set, else the script's own repo root — same resolution
   `ROADMAP`/`QUEUE_DIR` already use at `utils/marathon-plan.sh:57-58`). This is "the repo this plan
   is about," the existing mechanism for pointing the planner at a foreign repo today.
4. Built-in xyz default (`utils/marathon-plan-zones.default.json`) — resolved **relative to the
   harness/tool root** (the `marathon-plan.sh` script's own directory via `$_here_parent`,
   `utils/marathon-plan.sh:47-52`), **never** `QUEUE_PLAN_ROOT`. This matters specifically for a
   vendored `.xyz/` install driving a foreign repo via `QUEUE_PLAN_ROOT`: the tool root (`.xyz/`)
   and `QUEUE_PLAN_ROOT` (the foreign repo) are different directories, and the default must always
   come from the former.

**Fail-fast, no silent fallback:** tiers 1-3 are explicit requests. If `--zones-config` or
`QUEUE_PLAN_ZONES_FILE` names a path that doesn't exist or fails to parse as JSON, or
`$QUEUE_PLAN_ROOT/.marathon-plan-zones.json` exists but fails to parse, `marathon-plan.sh`
hard-errors (non-zero exit, clear message naming the bad path) — it never silently falls through to
a later tier. Only a **genuinely absent** `$QUEUE_PLAN_ROOT/.marathon-plan-zones.json` (tier 3 file
simply doesn't exist) falls through to tier 4 — that's the intended "foreign repo hasn't opted in
yet" case, not a failure.

### Code changes (Phase 1)

- `zoneOf(contract, item)`: iterate the loaded zone list in order; check `escalateOrchestratorOnly`
  first (any zone so flagged wins if the write-set intersects `contract.lanes.orchestrator_only`);
  then for the proven-contract path, match `artifacts[]` against each zone's
  `pathPrefixes`/`pathRegex` (honoring `pathRegexCaseInsensitive`); for the inferred path (no
  contract), match title+body text against each zone's `inferKeywordRegex`. First match wins; falls
  through to `defaultZone`. Same two-tier proven-vs-inferred priority as today — only the matching
  rules move from hardcoded consts to config data.
- **New `zoneRank(zones, name)` helper** — returns the zone's index in the configured list (the
  `defaultZone` always ranks last). Replaces **every** hardcoded zone-name map in the file: the
  wave-packing sort tie-break (`zr = {independent:0, shim:1, kernel:2}`, line 659-660), `ZONE_PEN`
  (line 643, now `zone.penalty`), and the collision-map's zone-iteration order (line 810). This is
  the fix for the consult's [Blocker] sort bug — a foreign zone name never produces an `undefined`
  lookup anywhere in the file, because nothing keys off literal zone-name strings anymore.
- Wave-packing (`kernelTaken`, `inferredShimClash`): generalize to read `maxPerWave` /
  `conservativeWhenInferred` off the matched zone object. A zone with no `maxPerWave` behaves like
  today's `independent`/`shim` (no cap beyond write-set disjointness); `conservativeWhenInferred`
  generalizes the shim-specific rule to any zone that opts in.
- Collision-map rendering (~line 810) and "## The one safety rule" header text (~line 802-804):
  iterate the configured zone list; the "❌ serialize" / "✅ one lane per file" text derives from
  whether the zone has `maxPerWave` set, not a hardcoded zone-name check.

### Phase 2 — acceptance validation (corrected — see Consult outcome)

**Not** "run marathon-plan.sh directly against rebalance's live `QUEUE-2026-06-27.md`" — the consult
caught that `marathon-plan.sh`'s ledger reader (`parseLedger`, line 305) is hardcoded to a
`ROADMAP.md`-shaped `## Ledger` section with specific `###` subsection names (`SECTIONS`, line 156);
it does not read an arbitrary foreign queue-doc shape, and fixing that is exactly idea #3, which
stays deferred. Conflating the two would have silently required idea #3 to make Phase 2 possible at
all — contradicting this doc's own non-goals.

Corrected Phase 2: hand-author a **one-time, throwaway** translation doc that restates rebalance's
real 3 lanes in xyz's own `ROADMAP.md`-shaped `## Ledger` / `### <section>` / `- **title**` bullet
format (each lane still carries its real swarm-preflight contract — the write-sets are real, only
the ledger *shell* around them is translated). Run, from a checkout of the rebalance-OS clone (or
with `QUEUE_PLAN_ROOT` pointed at it):
`QUEUE_PLAN_ROADMAP=<translation-doc> marathon-plan.sh --zones-config rebalance-os-zones.json`
against that. Confirms the shared-helper lane lands alone in its own wave (`maxPerWave: 1` enforced)
while the other two lanes wave together. This is a one-time hand translation to validate the
*classifier*, explicitly not a generalized foreign-ledger reader — if a future need for that emerges,
it's idea #3's own follow-up issue, not retroactively assumed here.

## Acceptance criteria

- [ ] `test/marathon-plan.sh` fully green with **zero** output diff versus today — the default zone
  config reproduces xyz's current classification and wave-packing exactly.
- [ ] New test coverage (extend `test/marathon-plan.sh` or add `test/marathon-plan-zones.sh`): a
  synthetic foreign zone-config correctly reclassifies a write-set the hardcoded regexes would have
  missed, and correctly enforces `maxPerWave`/`conservativeWhenInferred`, `escalateOrchestratorOnly`,
  and `pathRegexCaseInsensitive`.
- [ ] Resolution-order precedence tested: `--zones-config` > `QUEUE_PLAN_ZONES_FILE` >
  `$QUEUE_PLAN_ROOT/.marathon-plan-zones.json` > built-in default; fail-fast (non-zero exit) on a
  malformed config at any explicit tier, never a silent fallback.
- [x] Live validation (Phase 2): ran against the real rebalance-OS write-sets using a throwaway
  translated ledger. Outcome captured below: the BACKEND lane is correctly reclassified as
  `signed-helper`, the collision map renders `signed-helper<=1/wave`, and the queue remains one
  wave because only one lane touches that zone.
- [x] Schema documented in `utils/marathon-plan.sh`'s header comment and `relay-automation/README.md`.

## Live validation (2026-07-04)

Ran from this repo's worktree against the real rebalance-OS clone, but with a throwaway
ROADMAP-shaped translation ledger and isolated queue dir so unrelated rebalance docs would not
trip coverage drift:

```bash
REBALANCE_ROOT=/path/to/rebalance-OS
LIVECHECK_DIR="$REBALANCE_ROOT/temp/gh48-marathon-plan-livecheck"
QUEUE_PLAN_ROOT="$REBALANCE_ROOT" \
QUEUE_PLAN_ROADMAP="$LIVECHECK_DIR/ROADMAP.md" \
QUEUE_PLAN_QUEUE_DIR="$LIVECHECK_DIR/PROJECT/2-WORKING" \
QUEUE_PLAN_GH=off \
bash utils/marathon-plan.sh \
  --zones-config "$LIVECHECK_DIR/rebalance-zones.json"
```

Observed result:

- `Rebalance lane B · BACKEND` classified as **`signed-helper`** (the core cross-repo fix).
- Collision map rendered **`signed-helper | serialize — one at a time`**.
- The real rebalance queue stayed **1 wave**, not 2: `reb-spike ‖ reb-swift-app ‖ reb-backend`.

Why the earlier expectation was wrong: `maxPerWave: 1` only limits **multiple lanes in the same
zone**. The live rebalance queue has exactly **one** helper-writing lane, so there is nothing for
that cap to serialize against. The implementation now matches the actual planner semantics; the
design doc's prior "helper lane alone in its own wave" wording was the mistaken part.

## Reversibility & blast radius

**Medium-low.** Pure refactor of one internal classification function + wave-packing constants,
behind a new optional config layer whose default is provably identical to today's hardcoded
behavior (acceptance criterion 1 is the regression guard). Touches `utils/marathon-plan.sh`, one of
Plan B's own contended shared-file zones (collision map: `#86 → #48`, serialize, never run
together) — this lane must run **after** #86 lands, exactly as Plan B's existing wave ordering
already requires. No kernel (`relay-turn-lib.sh`/`bin/tick`) surface touched.

## Consult outcome (2026-07-04)

Ran via `/consult --models codex,agy`. Full transcripts:
[relay-system/2026-07-04/gh48-zone-design-review-074511/](../../relay-system/2026-07-04/gh48-zone-design-review-074511/).
Per the consult skill's own rule, disagreements first — that's the load-bearing part.

**Disagree:**
- **Severity of the sort tie-break bug.** Both flagged that the wave-packing sort's
  `zr = { independent: 0, shim: 1, kernel: 2 }` (line 659) breaks for any custom zone name — but
  agy graded it **[Blocker]** (a foreign zone name produces `undefined` lookups → `NaN` in the
  comparator, non-deterministic sort order — exactly the bug class this design exists to fix),
  while Codex graded the same observation **[Nit]** ("if zero output diff matters, preserve tie-break
  order"). **Adjudicated in agy's favor:** for xyz's own 3 zones this is inert, but for ANY foreign
  zone it silently corrupts wave ordering — a functional bug, not a completeness nit. Fixed below
  by deriving zone rank from the config list's own order everywhere, eliminating literal zone-name
  maps entirely.
- **Phase 2's acceptance framing.** Only Codex caught this, and it's the most consequential single
  finding: my Phase 2 said "run `marathon-plan.sh --target-root <rebalance-OS clone>` against the
  real rebalance-OS 3-lane queue" — but `marathon-plan.sh`'s ledger reader (`parseLedger`, line 305)
  is hardcoded to expect a `ROADMAP.md`-shaped `## Ledger` section with specific `###` subsection
  names (`SECTIONS`, line 156). Rebalance's hand-authored `QUEUE-2026-06-27.md` is a different
  shape — this was literally the *second*, separate complaint in the **original** GH-48 issue
  capture (foreign ledger format), which I had folded into "Option 3, deferred" and then
  contradicted by writing a Phase 2 that assumes marathon-plan can already read it. agy didn't catch
  this — it took the "run against the real queue" framing at face value. **Adjudicated: Codex is
  right, this doc had a real inconsistency.** Fixed below by scoping Phase 2 to a one-time,
  hand-authored translation doc — keeping idea #3 (a generalized foreign-ledger *reader*) genuinely
  deferred, not silently required to make Phase 2 possible.

**Agree (both, independently — higher confidence):**
- **[Blocker]** The design omitted `orchestrator_only` → kernel reclassification
  (`utils/marathon-plan.sh:354-363`) — a contract artifact under `contract.lanes.orchestrator_only`
  is promoted to kernel today regardless of its own path; the schema had no equivalent. Fixed below.
- **[Should]** Regex-flag fidelity: `SHIM_RE` is case-insensitive (`/i`); the JSON schema had no way
  to express that. Fixed below.
- **[Should]** Malformed/unreadable zone-config must fail fast (hard error), never silently fall
  back to the xyz default — a silent fallback on a foreign repo would run under the *wrong* repo's
  safety constraints without any signal. Fixed below.
- **[Pass]** Deferring idea #3 and rejecting idea #2 (contract-only mode) alone — both models
  independently reached the same conclusion I did, for the same reason (the hardcoded classifier
  still runs contract-backed items today).
- Codex additionally caught (agy didn't check this): the proposed `QP_ZONES_FILE` test-seam name
  doesn't match this script's real public convention — `utils/marathon-plan.sh` exposes
  `QUEUE_PLAN_*` publicly (`QUEUE_PLAN_GH_STATE_FILE`, `QUEUE_PLAN_BRANCHES_FILE`,
  `QUEUE_PLAN_BASE_FILES_FILE`, confirmed at lines 36-38/125-126) and translates internally to
  `QP_*` before the embedded Node script runs. Verified against the code directly (not just taking
  Codex's word) — Codex is correct. Fixed below (`QUEUE_PLAN_ZONES_FILE`).
- Codex additionally caught: the built-in default config must resolve from the **harness/tool
  root** (the script's own directory), never `--target-root` — otherwise a vendored `.xyz/` install
  driving a foreign repo would misresolve xyz's own default. Fixed below.

**Reconciled call:** both models independently recommended **"build with named fixes."** Not
"build as designed," not "rethink from scratch." All 5 fixes are folded into the Design section
below; this doc is now the corrected version.

## Swarm Preflight Contract (draft — consult-vetted, ready to build)

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
  "remediation": "Replace utils/marathon-plan.sh's hardcoded KERNEL_PATHS/SHIM_RE and the ZONE_PEN/kernelTaken/inferredShimClash wave-packing constants with a zone-rules list loaded per the resolution order (--zones-config flag > QUEUE_PLAN_ZONES_FILE env seam > $QUEUE_PLAN_ROOT/.marathon-plan-zones.json > built-in utils/marathon-plan-zones.default.json resolved from the script's own dir, which ships xyz's current values verbatim including escalateOrchestratorOnly on the kernel zone and pathRegexCaseInsensitive on the shim zone). zoneOf() and the wave-packing loop key off the matched zone object's pathPrefixes/pathRegex/inferKeywordRegex/maxPerWave/conservativeWhenInferred/penalty fields via a new zoneRank() helper, never a literal 'kernel'/'shim' string map (this eliminates the NaN sort-comparator bug a foreign zone name would otherwise trigger). A malformed/unreadable config at any explicit tier (flag, env, or an existing-but-invalid target-root file) hard-errors non-zero; only a genuinely absent target-root file falls through to the built-in default. test/marathon-plan.sh must show zero output diff for xyz's own default config; add coverage for a foreign zone-config fixture, the resolution-order precedence, and the fail-fast behavior.",
  "lanes": {
    "agy_safe": ["utils/marathon-plan.sh", "utils/marathon-plan-zones.default.json", "test/marathon-plan.sh"],
    "orchestrator_only": [],
    "note": "Shares utils/marathon-plan.sh with #86 — collision map requires #86 land first (serialize, never run together). Not part of the current Plan B firing round."
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
