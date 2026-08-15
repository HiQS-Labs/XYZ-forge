---
gh_issue: 382
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382
title: "GH-382 — a marathon's own telemetry carries tokens and wall-clock but zero memory signal"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. The issue has no `## Acceptance` section (verified 2026-08-10 by re-fetching); criteria are authored in a separate section below, not edited onto the issue (this capture was done read-only). Write-set includes `utils/py/marathon_drive.py`, the running phase driver — ships as a **direct PR**, never a marathon lane. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.6.0 Meter"
complexity: 3
risk: 2
effort: 3
phases: 2
ratings_provisional: true
roadmap_exempt: false
related:
  - "#392 — the STATIC counterpart: published hardware-sizing guidance in README, built from this issue's own measured crash profile. Documentation only, no code and no telemetry change (see its own non_goals: 'changing any default', 're-measuring'). 392 tells an operator what to expect BEFORE a run; 382 is about surfacing what actually happened DURING one. Neither substitutes for the other."
  - "#390 — the RUNTIME CONTAINMENT counterpart, and only PARTIALLY shipped. Its Phase 1 (PR #393) added a kernel CPU cap and an RSS watchdog over the pre-advance GATE's own process group (layers 2-3), plus the wall-clock bound from #383 (layer 1) — commit `94cafc9` is titled 'Phase 1 — layers 1-3 + gate-killed'. Layer 4, the host free-memory floor, is explicitly NOT shipped: `utils/py/marathon_drive.py:1320` reads verbatim '# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.' and no PR or capture doc delivers it today. Even the guard that DID ship only measures the gate (pytest) subprocess's RSS, and that number is logged and discarded (`marathon_drive.py:1397-1403`) — it never reaches `tick analyze` and never covers the builder or reviewer LLM subprocess. #382 is the general per-phase memory telemetry neither #390 nor #392 provides."
  - "#388 — run-log durability. The phase-5 kill in this issue's own crash destroyed the transcript; a related but distinct 'no signal survived the crash' gap in a different artifact."
  - "#379 — same class of defect (a signal the harness already computes but never surfaces to the operator), different data (a builder's own failure JSON vs. memory)."
non_goals:
  - "The host-pressure floor / pre-phase refusal the issue itself calls 'Optional, and a bigger ask... worth considering separately from the logging.' That is GH-390's undelivered layer 4. It is unclaimed by any capture doc today and belongs in its own lane, scoped against #390's acceptance criterion 3, not authored here."
  - "Any change to the pre-advance GATE's existing CPU/wall/RSS guard (GH-390 Phase 1, PR #393, and its coverage remainder GH-390-GATE-GUARD-COVERAGE.md). This lane surfaces memory; it does not add or change a kill/refusal path."
  - "Container isolation. Analyzed and explicitly deferred in #390; not raised by this issue and not revisited here."
  - "Re-measuring or re-diagnosing the panic. The issue states plainly 'Causation is not claimed' — the compressor/swap figures it reports are published once, as observed; this lane does not attempt to reproduce the crash."
goal: >
  `tick analyze`'s own `--- cost ---` block (`src/analyze.js:550-566`, fed by `computeCost()` at
  `:363-385`) reports run type, tokens, human-minutes and wall-clock — and, verified by grepping the
  whole file, ZERO memory fields: no match for memory, rss, swap, compressor, vm_stat, or meminfo
  anywhere in `src/analyze.js`. The one memory number the harness already computes — the pre-advance
  gate's peak process-group RSS (`utils/py/marathon_drive.py:1355-1403`) — is written with `log()` and
  nothing else; it never becomes a persisted event, never reaches `tick analyze`, and covers only the
  gate (pytest) subprocess, never the builder or reviewer LLM subprocess that runs for most of a
  phase's wall-clock. Sample compressor/swap at phase boundaries, capture builder/reviewer peak RSS
  separately, surface a warning line when swap runs low, and put the same numbers in the end-of-run
  summary beside tokens and wall-clock — so an operator reviewing a completed or crashed run can tell
  whether the host was comfortable or thrashing.
---

# GH-382 · a marathon's own telemetry carries tokens and wall-clock but zero memory signal

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. Verified against the tree, not the issue's prose: `src/analyze.js`'s cost block and `marathon_drive.py`'s gate-guard RSS poll both confirmed to carry no memory telemetry outside one discarded log line. Found and corrected a stale claim in a sibling doc (`GH-390-GATE-GUARD-COVERAGE.md:99`) that the host-pressure floor already shipped — it did not. Acceptance criteria authored in a separate section below (issue has none). | Preflight, then ship as a **direct PR against `development`** — never a marathon lane, since the natural implementation site is `utils/py/marathon_drive.py` itself, the running phase driver (see Reversibility & blast radius). |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382

## The defect

**The telemetry path reports zero memory fields — confirmed, not assumed.**

- `src/analyze.js:363-385` — `computeCost()` returns `{ run_type, tokens: {...}, walltime: {...},
  human_minutes_total, per_unit: {...} }`. No memory key anywhere in the shape.
- `src/analyze.js:550-566` — `renderHuman()`'s `--- cost ---` block prints run type, tokens, human
  minutes, wall-clock, per-done-task. `/usr/bin/grep -in "memory\|rss\|swap\|compressor\|vm_stat\|meminfo" src/analyze.js`
  returns **zero matches** in the entire 637-line file. This is exactly what the issue's captured
  `tick analyze` output shows (`--- cost ---` with tokens/human-minutes/wall-clock and nothing else) —
  that part of the issue is accurate as written.

**One memory number IS computed today, but it never leaves the log line it's printed on:**

- `utils/py/marathon_drive.py:313` — `GATE_RSS_MB_DEFAULT = 8192`; `:349-366` —
  `_gate_group_rss_mb(pgid)` sums the pre-advance gate's process-group RSS via `ps -axo pgid=,rss=`.
  This is GH-390's RSS watchdog (layer 3), scoped **only to the gate subprocess** (i.e., `pytest`),
  never to the builder or reviewer subprocess.
- `utils/py/marathon_drive.py:1355-1403` — the poll loop tracks `peak_rss_mb` and at `:1397-1403`
  writes it with `log(f"gate-guard: gate exit {rc} after {...}s — peak group RSS {peak_rss_mb}MB ...")`
  — `log()` only. It is never passed to `tick log`, never becomes a `cost.*` event, and therefore
  never reaches `tick analyze`. It is lost as soon as the terminal/log scrolls — precisely the failure
  mode #388 already tracks for the run transcript itself.

**Where token telemetry — the thing that DOES work — is emitted, for comparison:**

- `relay-automation/claude-turn.sh:254` — "Best-effort cost capture: parse the claude CLI's JSON token
  stats and emit a cost.tokens event." Token-only; no memory analog exists at this layer either.
- `utils/py/relay_drive.py:479-482` — this is where the builder/reviewer turn subprocess is actually
  spawned (`subprocess.run([args.agent_cmd])` / `subprocess.run(args.agent_cmd, shell=True)`), a plain
  `run()` with no RSS polling — unlike the gate's `Popen(...) + poll loop` pattern the guard already
  uses at `marathon_drive.py:1352-1373`. The pattern needed for "peak RSS of the turn subprocess
  (builder and reviewer separately)" already exists in the tree for the gate; it has not been applied
  here.

**The issue's "bigger ask" (a pre-phase ceiling) overlaps with GH-390's undelivered layer 4, not with
anything shipped:**

- `utils/py/marathon_drive.py:1320` — verbatim: `# Layer 4 (host free-memory floor) and packet-driven
  per-phase overrides are Phase 2.` Confirmed unshipped by `/usr/bin/grep` for
  `host_free|host_pressure|memory_pressure|HOST_FREE` across `utils/py/*.py` and
  `relay-automation/*.sh`: zero matches outside that one comment.
- The shipping commit's own title says as much: `94cafc9 feat(GH-390): resource-guard the pre-advance
  gate (Phase 1 — layers 1-3 + gate-killed)` — layers 1-3, not 4.
- **A sibling doc contradicts this and is wrong.** `PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md:99`
  lists as a dropped (already-satisfied) criterion: "A kernel-enforced CPU cap, an RSS watchdog over
  the gate's process group, and a host-pressure floor all ship... reason: all three shipped in PR
  #393." The host-pressure floor did **not** ship in PR #393 — contradicted directly by the code
  comment above and by that same PR's own commit title. Flagged here because a preflight or drafter
  reading that doc in isolation could wrongly conclude #382's "ceiling" ask is already satisfied. GH-390
  issue #390 itself remains **OPEN** on GitHub, consistent with layer 4 being outstanding.

## Acceptance

*Issue #382 has no `## Acceptance` section — confirmed by re-fetching the issue body on 2026-08-10 (`gh issue view 382 --json body`). Every criterion below was derived from the issue's own "Suggested instrumentation" bullets, scoped to the telemetry the issue marks as its core ask. The "ceiling" bullet is deliberately excluded — see non_goals above and the issue's own "worth considering separately" framing.*

- [ ] Compressor size and swap free are sampled at phase boundaries (before and after each phase) on
      macOS (`vm_stat` / `sysctl`) and Linux (`/proc/meminfo`), and both numbers are recorded — not
      just the delta.
- [ ] Peak RSS of the turn subprocess is captured for the builder and the reviewer **separately**, not
      summed into one figure, so an expensive lane is identifiable after the fact by which side spent
      it.
- [ ] A warning line appears **in the run's own output** (not only written to a file) when free swap
      drops below a threshold, so an operator watching an unattended run sees it at the point they
      could still intervene.
- [ ] The same memory numbers (compressor, swap, builder RSS, reviewer RSS) appear in the end-of-run
      summary beside the existing tokens and wall-clock figures — i.e., `tick analyze`'s `--- cost ---`
      block gains a memory section, not a separate report an operator has to know to ask for.
- [ ] None of the above requires a new dependency (the issue's own constraint) — `vm_stat`/`sysctl` on
      macOS and `/proc/meminfo` on Linux are used, matching the pattern GH-390's gate guard already
      established with `ps -axo pgid=,rss=`.
- [ ] Ships as a direct PR against `development`. Never dispatched as a marathon or relay lane — see
      Reversibility & blast radius for why.

## Litmus tests

- **A log line is not telemetry.** The exact failure this lane exists to fix already has one
  counter-example in the tree: the gate's peak RSS is computed and then thrown away via `log()`
  (`marathon_drive.py:1397-1403`). A "fix" that adds another `log()`-only line for compressor/swap
  reproduces the defect under a new name; the criterion is that the numbers reach `tick analyze`'s
  persisted report, not stdout.
- **Builder and reviewer RSS must stay separate.** A single combined "phase peak RSS" number would
  satisfy a sloppy reading of "peak RSS of the turn subprocess" but not the issue's explicit "builder
  and reviewer separately" — which is the whole point (identifying which side is expensive).
- **The warning threshold must fire in the run output a human is watching**, not only in a file
  reviewed after the fact — the issue is explicit that the point of the warning is "the point at which
  an operator would want to stop," which requires it to be visible during an unattended-but-monitored
  run, not just forensically after a panic destroys the log.
- **This lane must not quietly grow into the host-pressure floor.** Any refusal-to-advance behavior
  gated on the new memory numbers is out of scope (see non_goals) — a builder who adds one has
  implemented #390's undelivered layer 4 under this issue's number, which conflates two different
  proposals and two different risk profiles (observability vs. a new failure mode: refusing to
  advance).

## Reversibility & blast radius

**Medium. This lane touches the running phase driver and cannot be a marathon lane.**

The natural implementation site for "sampled at phase boundaries" and "the same numbers in the
end-of-run summary" is `utils/py/marathon_drive.py` — it is the file that already owns the phase loop
(`run_pre_advance_gate()`, the `_run_relay_drive()` call, and the `tick analyze` cost-summary print at
`:969-995`) and the only place that knows where a phase boundary is. That file is named explicitly in
this drafting batch's self-modification rule as **the running driver** — a lane whose write-set
includes it cannot be a marathon lane, because a marathon dispatching this fix would be asking the
running process to gate a change to its own phase-boundary logic mid-run. This holds regardless of
which specific sub-feature triggers it: even scoping down to "compressor/swap sampling only" still
needs a hook in the phase loop.

Two further complications widen, not narrow, this conclusion:

- **Per-subprocess builder/reviewer RSS most likely also touches `utils/py/relay_drive.py`** — the
  file that actually spawns the turn subprocess (`:479-482`). `relay_drive.py` is not literally named
  in the brief's disqualifying file list (only `marathon_drive.py`/`marathon.sh` and
  `rtl.py`/`relay-turn-lib.sh` are), but it is the same class of file: a running per-phase driver
  invoked from inside `marathon_drive.py`'s own loop. Its inclusion is not needed to reach the
  direct-PR conclusion above (marathon_drive.py alone is sufficient) but reinforces it.
- **If a builder instead adds the RSS-poll pattern once, shared, inside `relay-turn-lib.sh`** (the file
  every `*-turn.sh` sources, e.g. `claude-turn.sh:78`) so it covers every builder/reviewer CLI
  uniformly, that directly hits the turn kernel the brief names explicitly
  (`relay-automation/relay-turn-lib.sh` / `utils/py/rtl.py`) — a second, independent reason the same
  lane cannot be dispatched as a marathon phase, on top of the first.

**Frozen twins.** `test/gh308-frozen-twin-guard.sh` (`TWINS` array, `check_changes()`) only flags edits
to the **Bash side** of each pair — `relay-automation/marathon-drive.sh:utils/py/marathon_drive.py`
(pair 10) and `relay-automation/relay-drive.sh:utils/py/relay_drive.py` (pair 8) are both in that list.
The write-set identified above (`marathon_drive.py`, possibly `relay_drive.py`) sits on the **Python,
authoritative side** of both pairs, so **no `Frozen-twin-exception:` trailer is required** as scoped —
confirmed by reading `check_changes()` itself, which diffs only the left-hand (Bash) paths. That
changes only if the implementation also edits `marathon-drive.sh`, `relay-drive.sh`, or a `*-turn.sh`
script (the Bash sides), which this doc's acceptance criteria do not require.

**What breaks if the implementation is wrong:** nothing in the pass/fail gate path — this is additive
telemetry, not a new refusal. A broken sampler could throw and abort a phase early (blast radius:
availability, not correctness) if not wrapped defensively, or could silently report zero/garbage
numbers (blast radius: back to today's status quo — no signal — rather than a false signal that misleads
an operator, provided the render path treats absence as absence rather than inventing a zero).
**How hard to undo:** fully revertible by reverting the PR; the new event type (if one is added, e.g.
`cost.memory`) is purely additive to the event log schema and ignored by any `tick analyze` build that
predates it, so no migration is needed either direction.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "src/analyze.js", "pattern": "swap_free_mb" },
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "_phase_memory_sample" }
  ],
  "artifacts":     ["utils/py/marathon_drive.py", "src/analyze.js", "src/cost.js", "src/events.js"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #382", "criteria": "sample compressor/swap at phase boundaries, capture builder/reviewer peak RSS separately, surface a low-swap warning in run output, and add the same numbers to tick analyze's end-of-run summary — ranking summary only, NOT the definition of done (that is the authored ## Acceptance block above, since the issue itself has none)" },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```

**This contract exists for structural completeness and future reference, not as an instruction to
fire it.** Per Reversibility & blast radius, `utils/py/marathon_drive.py` — the running phase driver —
is in the write-set, so this lane **cannot** be dispatched via `marathon.sh --plan` or
`swarm-preflight.sh`'s automated path; `lanes.agy_safe` and `lanes.orchestrator_only` are both
deliberately empty rather than populated, unlike an ordinary fireable lane. It ships as a direct PR.

**Probe polarity** (probes detect the **bug**, not the fix, and both probes here are `grep_absent`):
`swap_free_mb` (or whatever field name the implementation lands on for the memory block — this is a
placeholder marker, not a mandated identifier) is a marker string the fix will introduce into
`src/analyze.js`'s cost render; while it is absent, the probe reports the fix as still required — which
is the case today (confirmed zero matches, see The defect). `_phase_memory_sample(` is a marker for the
phase-boundary sampling hook the fix will add to `marathon_drive.py`; its absence today is exactly
what makes phase-boundary compressor/swap numbers unavailable now. Once both markers exist, the probes
stop reporting and the lane reads as satisfied — the intended behavior, not a defect. A builder is free
to choose different concrete names; a preflight author re-authoring this contract before firing should
update the patterns to match, since a probe testing for the wrong literal string would never clear even
after a correct fix landed.

## Provenance

Filed from the same measured crash (2026-08-07/08, Darwin 24.6, M1 Max, 32 GB) that produced #390's
proof-of-concept and #392's sizing table — this issue is the third sibling lane built on that one
incident. Captured read-only 2026-08-10 against the `development` tree, cross-referencing
`src/analyze.js`, `utils/py/marathon_drive.py`, `utils/py/relay_drive.py`, `relay-automation/claude-turn.sh`,
`test/gh308-frozen-twin-guard.sh`, and the shipped state of #390 (PR #393, commit `94cafc9`) rather
than trusting the issue's or a sibling doc's prose.
