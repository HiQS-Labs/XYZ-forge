---
gh_issue: 96
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/96
title: "XYZ⇄Rebalance integration — Seam #1: XYZ.json emit contract (schema doc + heartbeat)"
status: Active (2-WORKING)
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: feature
goal: >
  Ship Seam #1 of the XYZ<->Rebalance integration only: make XYZ.json a dependable external
  signal by (a) documenting its schema + emit cadence (rebalance-OS#102 Phase-0's explicit
  dependency) and (b) adding a heartbeat so a hung/dead run goes STALE to a freshness-checking
  consumer instead of silently presenting the last-completed record as if it were current.
complexity: 3
risk: 1
effort: 3
phases: 1
roadmap_exempt: false
non_goals:
  - "Seam #2 (xyz-sync check) already shipped (`21d9d79`) — see GH-96-XYZ-REBALANCE-SYNC-CHECK.md
    in 3-COMPLETED. Not touched here."
  - "Seam #3 (consume Rebalance -> XYZ lane seeding) is explicitly gated behind this seam proving
    out, per the issue's own text (\"Phase-2, gated... not yet actionable\") -- not built here."
  - "Not the cross-repo aggregation UI itself. Rebalance-OS owns the collector/signal-quality
    plumbing (their #101/#102) that actually reads XYZ.json across installs; XYZ's obligation
    here is only to be a dependable, well-documented, freshness-aware emitter."
  - "Not a change to XYZ.json's existing array schema/consumers (GH-75, shipped). The heartbeat is
    a separate, disposable companion file so the already-shipped completion-record contract is
    never touched -- avoids a breaking migration for a signal-quality add-on."
  - "No new staleness *policy* (a numeric timeout, a UI badge) -- that threshold is Rebalance's own
    GH-101 freshness/degraded-check decision. XYZ's job stops at keeping the heartbeat honest."
related:
  - utils/telemetry/append-xyz-completion.sh
  - relay-automation/relay-drive.sh
  - relay-automation/marathon-drive.sh
  - test/xyz-completion.sh
  - PROJECT/3-COMPLETED/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md
  - PROJECT/3-COMPLETED/GH-96-XYZ-REBALANCE-SYNC-CHECK.md
---

# GH-96 Seam #1 · XYZ.json emit contract — schema doc + heartbeat

## Status

| What was just completed | What's next |
|---|---|
| Promoted 2026-07-05 from the still-open GH-96 issue text (Seam #1 was never its own capture doc — only Seam #2 was split out and shipped). Not yet built. | Run `utils/swarm-preflight.sh` against this doc; if READY, fire a marathon lane scoped to the artifacts below. |

## Problem (grounded in the current code)

`utils/telemetry/append-xyz-completion.sh` (GH-75, shipped) only ever fires at a **terminal** point
of each harness — `relay-drive.sh`'s three exits, `marathon-drive.sh`'s own per-phase/per-run
completion, `marathon.sh`'s whole-run completion (confirmed: `grep -n append-xyz-completion` across
all three scripts shows zero calls anywhere else). There is **no mid-run heartbeat**: while a marathon
phase or a relay round is in progress, nothing touches `XYZ.json`. A consumer reading `XYZ.json`
(rebalance-OS's planned collector, rebalance-OS#102) therefore cannot distinguish:

- "no run has happened in a while, the last completed one was green" (genuinely idle/healthy), from
- "a run started and hung/crashed mid-phase" (the last record is however-old, from the *previous*
  completed run, and presents as if it were still current).

`marathon-drive.sh:437` already emits `"$TICK_BIN" log marathon.phase.start ...` at the exact moment a
phase begins — the event exists in `.tick/events/`, it just never reaches `XYZ.json`. Likewise
`relay-drive.sh`'s round loop (`:272` `while ((round < ROUND_CAP))`) has a clear per-round start point.
Neither is wired to any freshness signal today.

Separately, `XYZ.json`'s schema (the record shape GH-75 shipped) and emit cadence (when exactly a
record lands — one per phase vs. one per whole run, see GH-75's own invoker table) are **not
documented anywhere** — confirmed via `grep -rn "XYZ.json" README.md relay-automation/README.md`
(zero hits). rebalance-OS#102 Phase-0's collector code needs this contract in writing, not just
correct-by-implementation.

## Fix

**1. Document the contract.** Add a "XYZ.json — completion telemetry" section to
`relay-automation/README.md` (mirroring the Seam #2 Components-table row convention): the record
schema (the 6 fields from GH-75), the emit cadence table (relay: one record per terminal
Approved/Escalated/round-cap exit; marathon.sh-orchestrated run: exactly one record for the whole
run; bare marathon-drive.sh / swarm-originated run: one record per invocation), and the new heartbeat
contract from point 2. This is the "confirm + document" half of Seam #1.

**2. Add a heartbeat companion file, not a schema change.** `XYZ.json` stays exactly the array GH-75
shipped (no wrapper object, no new field) — its consumers are already being built against that shape.
Instead, add `XYZ.heartbeat.json` at the harness repo root (same location rule as `XYZ.json`: always
the harness root, never `--target-root`; gitignored alongside it) holding a single mutable object
(overwritten in place, not appended):

```json
{ "harness": "marathon", "sessionId": "gh96-seam1", "updatedAt": "2026-07-05T00:00:00Z" }
```

- **Write points:** `marathon-drive.sh:437` (right after the existing `marathon.phase.start` tick log)
  and `relay-drive.sh`'s round-loop top (`:272`) for a standalone `/relay` session — same
  `XYZ_HARNESS_CONTEXT` gating GH-75 already uses, so a marathon-nested relay round doesn't
  double-write against the marathon-level heartbeat.
- **Clear on completion:** immediately before each harness's existing `append-xyz-completion.sh` call,
  delete `XYZ.heartbeat.json` if it names the same `sessionId` — a finished run leaves no stale
  in-progress marker behind. A crash leaves the heartbeat file in place with its last `updatedAt`,
  which is precisely the desired signal (a consumer can see "last heartbeat was N minutes ago, no
  matching completion record appeared").
- **Mechanics:** reuse `append-xyz-completion.sh`'s existing atomic temp-file + `os.replace()` pattern
  (a single small helper, `utils/telemetry/write-xyz-heartbeat.sh <harness> <sessionId>`) — no new
  locking primitive needed since a heartbeat overwrite (not a read-modify-write-array) has no lost-update
  risk to guard against.
- **Reversibility:** trivial — a consumer that ignores `XYZ.heartbeat.json` sees no behavior change;
  deleting the file has no effect on `XYZ.json` or any harness's control flow.

## Definition of done

- [ ] `relay-automation/README.md` gains a documented `XYZ.json` schema + emit-cadence section
- [ ] `utils/telemetry/write-xyz-heartbeat.sh <harness> <sessionId>` — atomic overwrite of
      `XYZ.heartbeat.json` at the harness repo root
- [ ] `marathon-drive.sh:437` calls the heartbeat writer right after `marathon.phase.start`
- [ ] `relay-drive.sh`'s round-loop top calls the heartbeat writer once per round, gated by
      `XYZ_HARNESS_CONTEXT` the same way GH-75's completion hook already is (no double-write when
      nested inside a marathon phase)
- [ ] Each harness's existing terminal `append-xyz-completion.sh` call also clears
      `XYZ.heartbeat.json` when its `sessionId` matches
- [ ] `XYZ.heartbeat.json` (+ its lock artifact, if any) added to `.gitignore` alongside `XYZ.json`
- [ ] `test/xyz-completion.sh` extended (already covers `append-xyz-completion.sh`/health-lib; add the
      heartbeat writer to the same file rather than a new one): writer overwrites (not appends), a
      mid-run heartbeat exists while `XYZ.json` shows only the prior completed record, heartbeat is
      cleared on matching completion, a crashed/killed run leaves the heartbeat in place (simulated),
      concurrent writers don't corrupt the file
- [ ] `bash validate.sh` green

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/xyz-completion.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "utils/telemetry/write-xyz-heartbeat.sh" }
  ],
  "artifacts_new": [
    "utils/telemetry/write-xyz-heartbeat.sh"
  ],
  "artifacts": [
    "utils/telemetry/write-xyz-heartbeat.sh",
    "relay-automation/relay-drive.sh",
    "relay-automation/marathon-drive.sh",
    "relay-automation/README.md",
    ".gitignore",
    "test/xyz-completion.sh"
  ],
  "remediation": "Add utils/telemetry/write-xyz-heartbeat.sh (atomic overwrite of XYZ.heartbeat.json at the harness repo root, reusing append-xyz-completion.sh's temp-file+os.replace pattern; no read-modify-write lock needed since overwrite has no lost-update risk). Call it from marathon-drive.sh right after the existing marathon.phase.start tick log (~line 437), and from relay-drive.sh's round-loop top, gated by the same XYZ_HARNESS_CONTEXT convention GH-75's completion hook already uses so a marathon-nested relay round doesn't double-write. Each harness's existing terminal append-xyz-completion.sh call site should also delete XYZ.heartbeat.json when its sessionId matches (a finished run leaves no stale in-progress marker). Add XYZ.heartbeat.json to .gitignore alongside the existing XYZ.json entry. Extend the existing test/xyz-completion.sh (already covers append-xyz-completion.sh/health-lib) with heartbeat coverage rather than adding a new test file -- it's already registered in validate.sh's TESTS array, so no registration step is needed. Document the XYZ.json schema + emit cadence + the new heartbeat contract in relay-automation/README.md. Do not change XYZ.json's existing array shape or any of its shipped consumers (GH-75) -- the heartbeat is a separate file. GH-96-SEAM1 marker comment near the fix.",
  "lanes": {
    "agy_safe": [
      "utils/telemetry/write-xyz-heartbeat.sh",
      "relay-automation/relay-drive.sh",
      "relay-automation/marathon-drive.sh",
      "relay-automation/README.md",
      ".gitignore",
      "test/xyz-completion.sh"
    ],
    "orchestrator_only": [],
    "note": "Touches relay-drive.sh and marathon-drive.sh (containment-core-adjacent, not the kernel itself — relay-turn-lib.sh is untouched). Single lane, not parallel-split: the heartbeat write points in both harness scripts and their shared test are one cohesive change, not independent files."
  }
}
```

## Provenance

Filed as the XYZ-side mirror of rebalance-OS#102 (2026-07-02 dueling-Claudes brainstorm,
`relay-system/2026-07-02/xyz-rebalance-integration.md` in the rebalance-OS repo, Closed/converged).
Seam #2 (`xyz-sync check`) shipped 2026-07-04 (`21d9d79`) as its own capture doc + marathon lane —
see [GH-96-XYZ-REBALANCE-SYNC-CHECK.md](../3-COMPLETED/GH-96-XYZ-REBALANCE-SYNC-CHECK.md). This doc splits out Seam
#1 the same way, promoted to `2-WORKING` 2026-07-05 in response to an operator question about whether
a single cross-repo telemetry location was ever finished — it wasn't; this is the buildable, unblocked
next slice (Seam #3 stays explicitly gated on this one proving out).
