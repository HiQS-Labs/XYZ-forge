---
gh_issue: 89
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/89
title: "swarm-preflight: no ready path for greenfield (new-file) lanes — GH-39 A2 artifact-existence check assumes edit-existing-file lanes"
status: Ready — promoted for Marathon Plan B Wave 1 (2026-07-04)
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Add an opt-in artifacts_new declaration to the swarm-preflight contract schema so a genuinely
  new-file (greenfield) lane's artifacts don't trip the GH-39 A2 existence check, while requiring a
  matching fix_probes path_absent entry on the same path so the exemption can't be used to dodge
  the check on an artifact that should already exist.
complexity: 2
risk: 1
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - Not changing the strict-by-default behavior for anything not explicitly marked new — every
    existing contract in the repo keeps working identically.
  - Not adopting the per-artifact {"path":..., "new": true} object shape the issue also offered —
    a sibling top-level artifacts_new: string[] list needs no change to the existing artifacts[]
    schema (stays string[] everywhere it's parsed/merged today), which is the smaller diff.
related:
  - utils/swarm-preflight.sh
  - test/swarm-preflight.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from GitHub issue capture, root cause + fix grounded against the live contract-parsing/merge/GH-39-A2 code (`utils/swarm-preflight.sh:145-185`, `:421-433`, `:508-511`). Not yet built. | Add `artifacts_new` schema support + the matching-`path_absent`-probe safety check, extend `test/swarm-preflight.sh`, `validate.sh` green, close #89. |

## Problem (grounded in the current code)

The GH-39 A2 check (`utils/swarm-preflight.sh:421-433`) requires **every** path in a contract's
`artifacts[]` to already exist at the evaluated `target.ref`, checked in a detached worktree of that
ref (`REF_WT`):

```bash
for _gh39_a in "${_gh39_arts[@]}"; do
  read -r _gh39_a <<<"$_gh39_a"
  [[ -z "$_gh39_a" ]] && continue
  [[ -e "$REF_WT/$_gh39_a" ]] || { GH39_ART_MISSING="$_gh39_a"; break; }
done
```

`READY=0` follows unconditionally on any miss (line 508-511). There is no way today to declare an
artifact as intentionally net-new — the contract schema's own parse-time validation
(`utils/swarm-preflight.sh:156-157`) and the multi-issue bundle merge logic (`:169-184`) both treat
`artifacts` as a flat `string[]` with no per-entry metadata and no sibling exemption list.
Reproduced live on two genuinely valid, otherwise-complete contracts (GH-87, GH-88 — both pure
new-file builds) before either was promoted: both returned `NOT-READY (exit 5)` purely because their
artifacts didn't exist yet, which is the entire point of a greenfield lane.

## Fix

Add an optional, opt-in top-level `artifacts_new: string[]` field to the contract schema — every
path listed must also appear in `artifacts[]` (a subset marker, not a separate path list):

1. **Parse-time validation** (`utils/swarm-preflight.sh`'s contract-parsing script, ~line 145-157):
   accept `artifacts_new` when present; if present, every entry must also be in `artifacts[]`
   (contract error, exit 3, if not — catches a typo'd path early rather than silently no-op'ing).
2. **Bundle merge** (`merge-contracts.mjs`, ~line 169-184): union `artifacts_new` the same way
   `artifacts`/`lanes.agy_safe`/`lanes.orchestrator_only` already union across a multi-issue bundle.
3. **GH-39 A2 check** (~line 421-433): read `artifacts_new` via the existing generic `field()` helper
   (`field "$TMP/contract.json" artifacts_new` — no helper change needed, it already comma-joins any
   array field) and skip the existence check for any `artifacts[]` entry also present in that set.
4. **The safety constraint from the issue itself** — an `artifacts_new` exemption must not become a
   way to dodge the check on a path that should already exist. Require, for every `artifacts_new`
   entry, a `fix_probes` entry of type `path_absent` on that exact same path (proving the lane
   author is asserting, in a form the harness can check, that the path is genuinely unbuilt — both
   GH-87 and GH-88's contracts already have this). Missing that pairing is a **contract error**
   (exit 3, same severity as a missing required field), not a silent pass — this needs its own small
   check reading `fix_probes` (an array of `{type, path}` objects `field()`'s scalar-join can't
   usefully flatten), following the same inline-`.mjs`-via-heredoc convention `eval-probes.mjs` and
   `merge-contracts.mjs` already use in this file.

## Definition of done

- [ ] `artifacts_new: string[]` accepted in the contract schema; every entry must also be in
  `artifacts[]`, else contract error (exit 3).
- [ ] Bundle merge unions `artifacts_new` across a multi-issue `--gh-issue` bundle, same as the
  other array fields.
- [ ] GH-39 A2 skips the existence check only for `artifacts[]` entries also in `artifacts_new`.
- [ ] An `artifacts_new` entry with no matching `fix_probes` `path_absent` entry on the same path is
  a contract error (exit 3), not a silent pass.
- [ ] Everything not marked `artifacts_new` keeps today's strict-by-default existence check exactly.
- [ ] `test/swarm-preflight.sh` gets cases: a genuine greenfield contract (artifacts_new + matching
  path_absent probe) reads READY where it previously read NOT-READY; an artifacts_new entry missing
  its path_absent probe is rejected; an artifacts_new entry not present in artifacts[] is rejected;
  an existing (non-greenfield) contract's behavior is unchanged.
- [ ] Re-run swarm-preflight against GH-87's and GH-88's actual historical contracts (or fixtures
  mirroring them) as a live regression check — both should now read READY.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** Purely additive schema field + an additional opt-in exemption path through an existing
check; nothing about the default (unmarked) path changes. Touches `utils/swarm-preflight.sh`, one of
Plan B's own contended shared-file zones (collision map: `#89 → #55`, serialize, never run
together) — this lane runs **first** in that zone, exactly as Plan B's wave ordering already
requires (#55 depends on #89 landing).

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-89" }
  ],
  "artifacts": [
    "utils/swarm-preflight.sh",
    "test/swarm-preflight.sh"
  ],
  "remediation": "Add an optional top-level artifacts_new: string[] field to the swarm-preflight contract schema (every entry must also appear in artifacts[]). Accept it in the contract-parsing validation and union it across a multi-issue bundle in merge-contracts.mjs, same as the other array fields. In the GH-39 A2 existence check, skip the existence test for any artifacts[] entry also present in artifacts_new. Require every artifacts_new entry to have a matching fix_probes entry of type path_absent on the exact same path -- an artifacts_new entry lacking that pairing is a contract error (exit 3), never a silent pass. Everything not marked artifacts_new keeps today's strict-by-default existence check unchanged. Add test/swarm-preflight.sh coverage for: a genuine greenfield contract reading READY, an artifacts_new entry missing its path_absent probe being rejected, an artifacts_new entry not present in artifacts[] being rejected, and existing non-greenfield contract behavior staying unchanged. GH-89 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["utils/swarm-preflight.sh", "test/swarm-preflight.sh"],
    "orchestrator_only": [],
    "note": "First lane of the swarm-preflight.sh shared-file zone (collision map: #89 -> #55, serialize) -- #55 must land after this. Parallel-safe with any other Wave 1 lane that doesn't touch utils/swarm-preflight.sh."
  }
}
```

## Provenance

Reproduced live on GH-87 (deep-research.mjs) and GH-88 (cross-repo marathon monitor), both pure
new-file builds with otherwise-valid contracts, before either lane was promoted — both returned
`NOT-READY (exit 5)` purely on the artifact-existence check. Names the same edit-existing-file
assumption GH-85 already flagged on the `marathon-plan.sh` side, as the inverse gap on the
`swarm-preflight.sh` side. Promoted to `2-WORKING` 2026-07-04 as part of Marathon Plan B Wave 1 (the
5 lanes cleared for firing after #23/#61 removal and Plan A confirmation — see
[MARATHON-PLAN-2026-07-03-B-PARALLEL.md](MARATHON-PLAN-2026-07-03-B-PARALLEL.md)).
