---
gh_issue: 75
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/75
title: XYZ.json — final completion telemetry appended at relay/swarm/marathon session end
status: Proposed (1-INBOX — pre-issue draft, under relay review; GH-75 is provisional until filed)
created: 2026-07-01
updated: 2026-07-01
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
roadmap_exempt: false
non_goals:
  - Not a replacement for GH-24's extract-relay-telemetry.sh (on-demand batch ETL over relay-system/*.md stays as-is; this is a live per-session append hook, different trigger and different artifact)
  - Not committed to git — XYZ.json is a local, gitignored, machine-specific artifact (avoids prepend/merge-conflict churn on a file every session writes to)
  - Not a Claude Code Stop hook — wired directly into the three harness scripts at their proven terminal points, so it fires in headless/CI runs too, not just interactive sessions
  - No rotation/pruning in Phase 1 — full history accumulates; a size cap is a follow-on if XYZ.json grows unwieldy
related:
  - relay-automation/relay-drive.sh
  - relay-automation/marathon.sh
  - relay-automation/marathon-drive.sh
  - utils/swarm-preflight.sh
  - utils/telemetry/extract-relay-telemetry.sh
---

# GH-75 · XYZ.json — final completion telemetry at harness session end

## Status

| Most recently completed | What's next |
|---|---|
| **Proposed 2026-07-01.** Plan captured from an operator request; no code written yet. Under relay review with Agy before the GitHub issue is filed. | Agy review round 1 → dispose of findings → file the GitHub issue → promote to `2-WORKING` → Phase 1 (relay hook + shared writer) is the first fireable slice. |

## Problem

None of the three harnesses (relay, swarm, marathon) currently emit a durable "this session finished, here's how it went" record. `utils/telemetry/extract-relay-telemetry.sh` (GH-24, closed 2026-06-30) is the closest prior art but is explicitly on-demand/batch — an operator runs it manually against a date range of `relay-system/*.md` files and gets a list. There is no live, automatic append at the moment a session actually completes, and no artifact that all three harness types write to.

## Design

### Where "session complete" actually happens (confirmed by code read)

- **Relay** → `relay-automation/relay-drive.sh:208-209` — the single point that has verified STATUS is terminal (`Approved`/`Closed`) **and** the tick token is no longer live (agreement check), immediately before `exit 0`. (Not `relay-turn-lib.sh`'s auto tick-done or `poll.sh`'s STATUS read — both check STATUS alone, more loosely, and would double-fire relative to the driver.)
- **Marathon** → `relay-automation/marathon.sh:95` — `"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon`, emitted only after every phase in the plan was approved. This is the whole-run completion; per-phase completions (`marathon-drive.sh:344-346`) are internal and do not each get their own XYZ.json record.
- **Swarm** → `swarm-preflight.sh` never executes anything itself (it only produces a packet and hands the run to `marathon-drive.sh`). A swarm-originated run therefore completes at the *same* code path as marathon, distinguished only by origin.

### Avoiding double-emission (open design point, resolved here)

`marathon-drive.sh` internally drives a relay loop per phase, so `relay-drive.sh:208-209` fires once per phase *inside* a marathon run — if left unconditional, a 3-phase marathon would emit 3 `harness:"relay"` records plus 1 `harness:"marathon"` summary record, which is noisy and not what "final completion telemetry" means. Fix: thread a context flag (`XYZ_HARNESS_CONTEXT` env var, unset by default) that `marathon-drive.sh` sets to `marathon-phase` before invoking the relay loop. The relay-drive.sh hook only appends to XYZ.json when this flag is unset (i.e., a standalone `/relay` session) or explicitly `relay`. Marathon and swarm each get exactly one record, from their own hook, not from the nested relay loop.

### Swarm vs. marathon tagging

Per operator decision: swarm-originated runs get `harness: "swarm"`, not folded into `"marathon"`. `swarm-preflight.sh` sets `XYZ_HARNESS_CONTEXT=swarm` (or writes it into the packet, consumed by `marathon-drive.sh`/`marathon.sh`) before handing off; the completion hook reads that context to pick the tag. A directly-invoked `marathon.sh` run (no swarm packet) defaults to `harness: "marathon"`.

### Record schema (extends GH-24's shape)

```json
{
  "harness": "relay|marathon|swarm",
  "sessionId": "<relay thread slug, or marathon plan/run id>",
  "health": "green|orange|red",
  "title": "...",
  "description": "...",
  "updatedAt": "2026-07-01T00:00:00Z"
}
```

`health`/`title`/`description`/`updatedAt` reuse GH-24's STATUS/VERDICT-derived health mapping (`extract-relay-telemetry.sh:92-133`) — factor that block out of the extractor into a shared shell function (`utils/telemetry/health-lib.sh` or similar) so both the on-demand extractor and the new live hook call the same logic instead of forking it. Marathon/swarm health: `green` on `marathon.complete`, `red` on `marathon.sh:83-88`'s halt-on-first-failure path (needs a hook there too), no `orange` case identified yet (a marathon run either completes clean or halts — flag as open item, not blocking).

### Write mechanics — "append to the top" of `XYZ.json`

`XYZ.json` holds a JSON array, newest-first (mirrors `CHANGELOG.md`'s newest-first convention). Each hook does a read-modify-write: parse existing array (or `[]` if absent/missing), unshift the new record, write back. Needs a lock (reuse the existing `mkdir`-based advisory lock pattern hardened in GH-72, since relay/marathon/swarm can run concurrently across repos and all write to the same file) to avoid a torn write when two sessions complete close together. Python3 (already a dependency per GH-24) for safe JSON read/write, consistent with the extractor.

### Location + git tracking

`XYZ.json` at repo root, added to `.gitignore` (operator decision: local-only, avoids merge-conflict churn on a file every session prepends to). No git write beyond the ignore-file entry.

## Phases

**Phase 1 — shared writer + relay hook**
- [ ] Factor GH-24's STATUS/VERDICT→health mapping into a shared lib function, reused by both `extract-relay-telemetry.sh` (unchanged behavior) and the new writer
- [ ] `utils/telemetry/append-xyz-completion.sh <harness> <sessionId> <health> <title> <description>` — locked read-modify-write-prepend to `XYZ.json`
- [ ] Wire into `relay-drive.sh:208-209`, gated on `XYZ_HARNESS_CONTEXT` being unset/`relay`
- [ ] Add `XYZ.json` to `.gitignore`
- [ ] `test/relay-drive.sh` (or equivalent): a terminal relay run produces exactly one well-formed `XYZ.json` record; re-running twice prepends, doesn't clobber

**Phase 2 — marathon hook + swarm tagging**
- [ ] Wire into `marathon.sh:95` (`harness: "marathon"`, `health: "green"`) and the halt path (`marathon.sh:83-88`, `health: "red"`)
- [ ] `marathon-drive.sh` sets `XYZ_HARNESS_CONTEXT=marathon-phase` around its internal relay loop so per-phase relay completions don't double-emit
- [ ] `swarm-preflight.sh` sets `XYZ_HARNESS_CONTEXT=swarm`, propagated through `marathon-drive.sh`/`marathon.sh` to the completion hook
- [ ] `test/marathon-plan.sh` / `test/swarm-preflight.sh`: a swarm-originated run produces `harness:"swarm"`; a direct marathon run produces `harness:"marathon"`; a 3-phase marathon produces exactly 1 record, not 3+1

**Phase 3 — QA + docs**
- [ ] `validate.sh` green with the new tests included
- [ ] `ROUTER.md` routing hint (mirrors the existing GH-24 telemetry hint) pointing at this doc + `XYZ.json`'s location/schema
- [ ] Confirm concurrent-write safety: two harness sessions completing within the same second don't corrupt `XYZ.json` (reuse GH-72's lock-concurrency test pattern)

## QA gate

- [ ] A standalone `/relay` session reaching STATUS Approved/Closed appends exactly one `harness:"relay"` record
- [ ] A multi-phase marathon run appends exactly one `harness:"marathon"` record (not one per phase)
- [ ] A swarm-preflight-initiated run appends `harness:"swarm"`, not `"marathon"`
- [ ] `XYZ.json` stays valid JSON after N sequential appends and after concurrent appends
- [ ] `XYZ.json` is gitignored; `git status` stays clean after a session completes
- [ ] `extract-relay-telemetry.sh`'s existing output is byte-identical before/after the health-mapping refactor into a shared lib (no regression to GH-24)
