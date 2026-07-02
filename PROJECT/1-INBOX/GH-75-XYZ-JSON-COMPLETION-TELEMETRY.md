---
gh_issue: 75
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/75
title: XYZ.json — final completion telemetry appended at relay/swarm/marathon session end
status: Proposed (1-INBOX — relay-reviewed by agy, Approved; not yet promoted to 2-WORKING)
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
| **Proposed 2026-07-01, relay-reviewed by agy → Approved (round 2).** Plan captured from an operator request; no code written yet. Round 1 found 1 Blocker (swarm invokes `marathon-drive.sh` directly, not `marathon.sh` — needed its own hook) + 3 Should + 2 Nit, all disposed as Implemented; round 2 re-verified each fix against the artifact and passed all 4 re-checks. Full thread: `relay-system/2026-07-01/gh75-xyz-json-telemetry-plan.md`. | File the GitHub issue → promote to `2-WORKING` → Phase 1 (relay hook + shared writer) is the first fireable slice. |

## Problem

None of the three harnesses (relay, swarm, marathon) currently emit a durable "this session finished, here's how it went" record. `utils/telemetry/extract-relay-telemetry.sh` (GH-24, closed 2026-06-30) is the closest prior art but is explicitly on-demand/batch — an operator runs it manually against a date range of `relay-system/*.md` files and gets a list. There is no live, automatic append at the moment a session actually completes, and no artifact that all three harness types write to.

## Design

### Where "session complete" actually happens (confirmed by code read)

- **Relay** → `relay-automation/relay-drive.sh:208-209` — the single point that has verified STATUS is terminal (`Approved`/`Closed`) **and** the tick token is no longer live (agreement check), immediately before `exit 0`. (Not `relay-turn-lib.sh`'s auto tick-done or `poll.sh`'s STATUS read — both check STATUS alone, more loosely, and would double-fire relative to the driver.) **Also hook the non-green exits** — `relay-drive.sh:214-217` (Escalated handback, `health:"orange"`) and the round-cap fallback at `relay-drive.sh:324-330` (`health:"red"` if the post-cap check fails, `"green"` if it happens to pass) — so a stalled or escalated standalone relay isn't silently absent from `XYZ.json` (agy r1 Should).
- **Marathon** → `relay-automation/marathon.sh:95` — `"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon`, emitted only after every phase in the plan was approved. This is the whole-run completion; per-phase completions (`marathon-drive.sh:344-346`) are internal and do not each get their own XYZ.json record for a `marathon.sh`-orchestrated run.
- **Swarm** → `swarm-preflight.sh` never executes anything itself — it only produces a packet and writes the operator-facing run command to `run-candidate.json`'s companion `marathon-invocation.txt` (`swarm-preflight.sh:541-547,589`), which invokes `marathon-drive.sh` **directly**, not through `marathon.sh`. This means a swarm-originated run's completion point is `marathon-drive.sh`'s own per-phase completion (`marathon-drive.sh:344-347`), not `marathon.sh:95` — the two are genuinely different code paths, not "the same path distinguished by origin" as an earlier draft of this doc claimed (agy r1 Blocker, corrected).

**Consequence: `marathon-drive.sh` needs its own completion hook**, independent of `marathon.sh`'s. `marathon.sh` already calls `marathon-drive.sh` per phase, so `marathon-drive.sh`'s hook must stay silent when `XYZ_HARNESS_CONTEXT=marathon-phase` (set by `marathon.sh` around each phase call) and fire when `XYZ_HARNESS_CONTEXT=swarm` (set by `swarm-preflight.sh`'s generated invocation) or when invoked directly with neither flag set (bare single-phase `marathon-drive.sh`, its own `harness:"marathon"` case). Three call shapes, one hook, gated by context:

| Invoker | `XYZ_HARNESS_CONTEXT` | `marathon-drive.sh` hook fires? | `harness` tag |
|---|---|---|---|
| `marathon.sh` (multi-phase) | `marathon-phase` | no — `marathon.sh:95` fires instead, once, at the end | `marathon` |
| `swarm-preflight.sh` → generated invocation | `swarm` | yes, per swarm-preflight-initiated run | `swarm` |
| bare `marathon-drive.sh` (no wrapper) | unset | yes | `marathon` |

### Avoiding double-emission — two nested levels, one flag

`XYZ_HARNESS_CONTEXT` gates emission at both levels a marathon run nests through, so a `marathon.sh`-orchestrated N-phase run always produces exactly one record, never N or N+1:
1. **relay-drive.sh level:** `marathon-drive.sh` internally drives a relay loop per phase, so `relay-drive.sh:208-209` fires once per phase *inside* a marathon run. `marathon-drive.sh` sets `XYZ_HARNESS_CONTEXT=marathon-phase` before invoking that relay loop; the relay-drive.sh hook only appends to `XYZ.json` when the flag is unset/`relay` (a standalone `/relay` session), so nested per-phase relay completions never emit their own record.
2. **marathon-drive.sh level:** per the table above, `marathon-drive.sh`'s own hook (`:344-347`) reads the *same* `XYZ_HARNESS_CONTEXT` to decide whether to emit at all — silent when `marathon.sh` set it to `marathon-phase` (that whole-run summary comes from `marathon.sh:95` instead), firing when it's `swarm` or unset (a swarm-originated or bare `marathon-drive.sh` run, where `marathon-drive.sh`'s own completion *is* the whole run).

### Swarm vs. marathon tagging

Per operator decision: swarm-originated runs get `harness: "swarm"`, not folded into `"marathon"`. Concretely, `swarm-preflight.sh` prefixes the `INVOCATION` string it builds (`swarm-preflight.sh:541-547`) with `XYZ_HARNESS_CONTEXT=swarm `, so the exact line it writes to `marathon-invocation.txt` (`swarm-preflight.sh:589`) is self-contained — the operator runs it verbatim and the tag propagates with no extra step (agy r1 Should: this must be explicit in the generated command, not left as a "the operator sets it" assumption).

### Title/description for marathon and swarm records

Unlike relay (which extracts `title`/`description` from a single markdown file's header — GH-24's existing logic), a marathon or swarm run has no single file to read (agy r1 Should). Source these instead from data `marathon-drive.sh`/`marathon.sh` already have in hand:
- `title`: the phase-brief/packet name (`--phase-brief <packet>/packet.md`'s basename) for a single-phase/swarm run; the `MARATHON.yaml` plan name for a `marathon.sh`-orchestrated run.
- `description`: `"N of M phase(s) approved"` on success; `"halted at phase K of M — <gate/exit failure reason>"` on the halt path. `marathon-drive.sh` already logs a phase-complete message with this shape (`marathon-drive.sh:346`) — reuse its wording rather than inventing new copy.

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

`health`/`title`/`description`/`updatedAt` reuse GH-24's STATUS/VERDICT-derived health mapping (`extract-relay-telemetry.sh:92-133`) — factor that block out of the extractor into a shared shell function (`utils/telemetry/health-lib.sh` or similar) so both the on-demand extractor and the new live hook call the same logic instead of forking it. Marathon/swarm health: `green` on all-phases-approved, `red` on the halt-on-first-failure path. No `orange` case for marathon/swarm — confirmed correct to defer (agy r1: binary green/red matches the halt-on-first-failure design; there's no "escalated mid-chain" state distinct from halt).

### Write mechanics — "append to the top" of `XYZ.json`

`XYZ.json` holds a JSON array, newest-first (mirrors `CHANGELOG.md`'s newest-first convention). Each hook does a read-modify-write: parse existing array (or `[]` if absent/missing), unshift the new record, and write back via **atomic replacement** — write the full array to a temp file in the same directory, then `os.replace()` it over `XYZ.json` (agy r1 Nit: a bare overwrite risks truncating the file to empty/partial JSON if the writer is killed mid-write; temp-file + rename is atomic at the filesystem level and self-heals that failure mode). Still needs the `mkdir`-based advisory lock (reused from GH-72) around the read-modify-write-replace sequence, since two sessions can finish within the same second and a lock prevents them from both reading the same pre-append array and one clobbering the other's record — atomic replacement alone only prevents *corruption*, not *lost updates*. Python3 (already a dependency per GH-24) for safe JSON read/write, consistent with the extractor.

### Location + git tracking

`XYZ.json` always lives at the **harness repo root** (the clone that ships `relay-automation/` and drives the run), never at a `--target-root` foreign repo — telemetry describes the harness's own session history, not the target repo's tree (agy r1 Nit: this needed to be explicit, since most other harness output *does* route to `--target-root`). Added to `.gitignore` (operator decision: local-only, avoids merge-conflict churn on a file every session prepends to). No git write beyond the ignore-file entry.

## Phases

**Phase 1 — shared writer + relay hook**
- [ ] Factor GH-24's STATUS/VERDICT→health mapping into a shared lib function, reused by both `extract-relay-telemetry.sh` (unchanged behavior) and the new writer
- [ ] `utils/telemetry/append-xyz-completion.sh <harness> <sessionId> <health> <title> <description>` — locked, atomic (temp-file + `os.replace`) read-modify-write-prepend to `XYZ.json` at the harness repo root
- [ ] Wire into `relay-drive.sh`'s three terminal exits: `:208-209` (`health:"green"`), `:214-217` Escalated handback (`health:"orange"`), `:324-330` round-cap fallback (`health:"red"`/`"green"` per its own pass/fail check) — gated on `XYZ_HARNESS_CONTEXT` being unset/`relay`
- [ ] Add `XYZ.json` to `.gitignore`
- [ ] `test/relay-drive.sh` (or equivalent): a terminal relay run produces exactly one well-formed `XYZ.json` record for each of the three exit paths; re-running twice prepends, doesn't clobber

**Phase 2 — marathon-drive.sh hook + swarm tagging**
- [ ] Wire the completion hook into `marathon-drive.sh:344-347` (its own per-phase/per-run completion point) — this is the ONE hook shared by bare `marathon-drive.sh` runs and swarm-originated runs (agy r1 Blocker: `marathon.sh:95` alone misses swarm entirely, since swarm invokes `marathon-drive.sh` directly)
- [ ] `marathon.sh` sets `XYZ_HARNESS_CONTEXT=marathon-phase` around each `marathon-drive.sh` phase call, so the hook stays silent per-phase; `marathon.sh:95` fires its own single `harness:"marathon"` record at whole-run completion instead
- [ ] `swarm-preflight.sh` prefixes its generated `INVOCATION` (`swarm-preflight.sh:541-547`, written to `marathon-invocation.txt` at line 589) with `XYZ_HARNESS_CONTEXT=swarm `, so the operator-run command self-propagates the tag with no manual step
- [ ] Title/description sourcing for marathon-drive.sh's hook: phase-brief/packet basename + `"N of M phase(s) approved"` / `"halted at phase K of M — <reason>"` (reusing `marathon-drive.sh:346`'s existing wording)
- [ ] `test/marathon-plan.sh` / `test/swarm-preflight.sh`: a swarm-originated run produces `harness:"swarm"`; a bare `marathon-drive.sh` run produces `harness:"marathon"`; a `marathon.sh`-orchestrated N-phase run produces exactly 1 record, not N+1

**Phase 3 — QA + docs**
- [ ] `validate.sh` green with the new tests included
- [ ] `ROUTER.md` routing hint (mirrors the existing GH-24 telemetry hint) pointing at this doc + `XYZ.json`'s location/schema
- [ ] Confirm concurrent-write safety: two harness sessions completing within the same second don't corrupt `XYZ.json` (reuse GH-72's lock-concurrency test pattern) and don't lose either record (atomic replacement prevents corruption but not a lost update without the lock)

## QA gate

- [ ] A standalone `/relay` session reaching STATUS Approved/Closed appends exactly one `harness:"relay"` `health:"green"` record
- [ ] A standalone `/relay` session that escalates or hits the round cap appends exactly one `harness:"relay"` record with `health:"orange"`/`"red"` (not silently absent)
- [ ] A `marathon.sh`-orchestrated multi-phase run appends exactly one `harness:"marathon"` record (not one per phase)
- [ ] A bare `marathon-drive.sh` run (no `marathon.sh` wrapper) appends one `harness:"marathon"` record
- [ ] A swarm-preflight-initiated run (via its generated `marathon-invocation.txt` command) appends `harness:"swarm"`, not `"marathon"`
- [ ] `XYZ.json` stays valid JSON after N sequential appends, after concurrent appends, and after a simulated kill mid-write (atomic replacement leaves the prior valid array intact)
- [ ] `XYZ.json` is written to the harness repo root even when the run used `--target-root <foreign repo>`
- [ ] `XYZ.json` is gitignored; `git status` stays clean after a session completes
- [ ] `extract-relay-telemetry.sh`'s existing output is byte-identical before/after the health-mapping refactor into a shared lib (no regression to GH-24)
